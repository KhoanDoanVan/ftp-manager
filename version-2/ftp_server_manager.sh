#!/usr/bin/env bash

set -u

readonly VSFTPD_CONF="/etc/vsftpd/vsftpd.conf"
readonly STATE_DIR="/etc/ftp-manager-v2"
readonly SHARE_REGISTRY="$STATE_DIR/shares.tsv"
readonly BACKUP_DIR="/var/backups/ftp-manager-v2"

info() { printf '[INFO] %s\n' "$*"; }
ok() { printf '[OK] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
fail() { printf '[ERROR] %s\n' "$*" >&2; return 1; }
pause() { read -r -p "Nhan Enter de tiep tuc..." _; }

require_root() {
    if (( EUID != 0 )); then
        fail "Hay chay: sudo ./ftp_server_manager.sh"
        exit 1
    fi
}

valid_name() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,31}$ ]]; }
valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; }

confirm() {
    local answer
    read -r -p "$1 [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

ensure_state() {
    install -d -m 700 "$STATE_DIR" "$BACKUP_DIR"
    touch "$SHARE_REGISTRY"
    chmod 600 "$SHARE_REGISTRY"
}

set_vsftpd_value() {
    local key="$1" value="$2"
    [[ -f "$VSFTPD_CONF" ]] || return 1
    if grep -qE "^[[:space:]]*${key}=" "$VSFTPD_CONF"; then
        sed -i -E "s|^[[:space:]]*${key}=.*|${key}=${value}|" "$VSFTPD_CONF"
    else
        printf '%s=%s\n' "$key" "$value" >> "$VSFTPD_CONF"
    fi
}

configure_baseline() {
    [[ -f "$VSFTPD_CONF" ]] || { fail "Khong tim thay $VSFTPD_CONF"; return 1; }
    [[ -f "$VSFTPD_CONF.ftp-manager-v2.bak" ]] || \
        cp -a "$VSFTPD_CONF" "$VSFTPD_CONF.ftp-manager-v2.bak"

    set_vsftpd_value listen YES
    set_vsftpd_value listen_ipv6 NO
    set_vsftpd_value local_enable YES
    set_vsftpd_value write_enable YES
    set_vsftpd_value chroot_local_user YES
    set_vsftpd_value allow_writeable_chroot YES
    set_vsftpd_value anonymous_enable NO
    set_vsftpd_value no_anon_password YES
    set_vsftpd_value anon_upload_enable NO
    set_vsftpd_value anon_mkdir_write_enable NO
    set_vsftpd_value pasv_enable YES
    set_vsftpd_value pasv_min_port 30000
    set_vsftpd_value pasv_max_port 31000
}

install_ftp_server() {
    local package_manager
    if command -v dnf >/dev/null 2>&1; then package_manager=dnf
    elif command -v yum >/dev/null 2>&1; then package_manager=yum
    else fail "Khong tim thay dnf/yum."; return 1
    fi

    "$package_manager" install -y vsftpd || return 1
    ensure_state
    configure_baseline || return 1

    if systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --add-service=ftp
        firewall-cmd --permanent --add-port=30000-31000/tcp
        firewall-cmd --reload
    else
        warn "firewalld khong hoat dong; chua mo port tu dong."
    fi

    if command -v setsebool >/dev/null 2>&1; then
        setsebool -P ftpd_full_access on || warn "Khong bat duoc SELinux ftpd_full_access."
    fi

    systemctl enable --now vsftpd && ok "Da cai dat va khoi dong vsftpd."
}

service_control() {
    local choice
    printf '%s\n' "1) Bat FTP" "2) Tat FTP" "3) Restart FTP" "4) Xem trang thai"
    read -r -p "Lua chon: " choice
    case "$choice" in
        1) systemctl enable --now vsftpd && ok "FTP dang chay." ;;
        2) systemctl stop vsftpd && ok "FTP da dung." ;;
        3) systemctl restart vsftpd && ok "FTP da restart." ;;
        4) systemctl status vsftpd --no-pager ;;
        *) fail "Lua chon khong hop le." ;;
    esac
}

share_exists() {
    local share_name="$1"
    awk -F '\t' -v wanted="$share_name" '$2 == wanted {found=1} END {exit !found}' \
        "$SHARE_REGISTRY"
}

register_share() {
    printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$SHARE_REGISTRY"
}

add_anonymous_share() {
    local share_name="$1" path="/var/ftp/$1"
    mkdir -p "$path"
    chown root:root /var/ftp "$path"
    chmod 755 /var/ftp "$path"
    command -v restorecon >/dev/null 2>&1 && restorecon -RF "$path" >/dev/null 2>&1 || true

    set_vsftpd_value anonymous_enable YES
    set_vsftpd_value no_anon_password YES
    set_vsftpd_value anon_upload_enable NO
    set_vsftpd_value anon_mkdir_write_enable NO
    register_share anonymous "$share_name" "$path" "-"
    systemctl restart vsftpd
    ok "Da tao anonymous share: $path (FileZilla: /$share_name, chi doc)."
}

ensure_local_user() {
    local username="$1"
    if id "$username" >/dev/null 2>&1; then return 0; fi
    confirm "User '$username' chua ton tai. Tao user va dat password?" || return 1
    useradd -m "$username" || return 1
    passwd "$username"
}

add_user_share() {
    local share_name="$1" username path ftp_root
    read -r -p "Linux/FTP username: " username
    valid_username "$username" || { fail "Username khong hop le."; return 1; }
    ensure_local_user "$username" || return 1

    ftp_root="/home/$username/ftp"
    path="$ftp_root/$share_name"
    mkdir -p "$path"
    chown root:root "$ftp_root"
    chmod 755 "$ftp_root"
    chown -R "$username:$username" "$path"
    chmod 700 "$path"
    command -v restorecon >/dev/null 2>&1 && restorecon -RF "$ftp_root" >/dev/null 2>&1 || true

    set_vsftpd_value local_enable YES
    set_vsftpd_value write_enable YES
    register_share user "$share_name" "$path" "$username"
    systemctl restart vsftpd
    ok "Da tao user share: $path (FileZilla: /ftp/$share_name, doc/ghi)."
}

add_ftp_share() {
    local share_name access_type
    command -v vsftpd >/dev/null 2>&1 || { fail "Hay chon muc 1 de cai FTP truoc."; return 1; }
    ensure_state
    read -r -p "Ten thu muc/share: " share_name
    valid_name "$share_name" || { fail "Chi dung chu, so, _, -; toi da 32 ky tu."; return 1; }
    share_exists "$share_name" && { fail "Share '$share_name' da ton tai."; return 1; }

    printf '%s\n' "1) Anonymous truy cap (chi doc)" "2) Local user truy cap (doc/ghi)"
    read -r -p "Doi tuong truy cap: " access_type
    case "$access_type" in
        1) add_anonymous_share "$share_name" ;;
        2) add_user_share "$share_name" ;;
        *) fail "Lua chon khong hop le." ;;
    esac
}

list_registered_shares() {
    local number=0 type name path username
    [[ -s "$SHARE_REGISTRY" ]] || { warn "Chua co share nao do tool quan ly."; return 1; }
    printf '%-4s %-10s %-20s %-16s %s\n' "STT" "LOAI" "TEN" "USER" "PATH"
    while IFS=$'\t' read -r type name path username; do
        ((number += 1))
        printf '%-4s %-10s %-20s %-16s %s\n' "$number" "$type" "$name" "$username" "$path"
    done < "$SHARE_REGISTRY"
}

refresh_anonymous_setting() {
    if awk -F '\t' '$1 == "anonymous" {found=1} END {exit !found}' "$SHARE_REGISTRY"; then
        set_vsftpd_value anonymous_enable YES
    else
        set_vsftpd_value anonymous_enable NO
    fi
}

delete_ftp_share() {
    local index total record type name path username archive temp line_number=0
    ensure_state
    list_registered_shares || return 1
    total=$(wc -l < "$SHARE_REGISTRY")
    read -r -p "STT share can xoa: " index
    [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= total )) || \
        { fail "STT khong hop le."; return 1; }

    record=$(sed -n "${index}p" "$SHARE_REGISTRY")
    IFS=$'\t' read -r type name path username <<< "$record"
    confirm "Go share '$name' va chuyen du lieu vao backup?" || return 0

    archive="$BACKUP_DIR/${name}-$(date +%Y%m%d-%H%M%S)"
    [[ -e "$path" ]] && mv "$path" "$archive"

    temp=$(mktemp)
    while IFS= read -r record; do
        ((line_number += 1))
        (( line_number == index )) || printf '%s\n' "$record" >> "$temp"
    done < "$SHARE_REGISTRY"
    install -m 600 "$temp" "$SHARE_REGISTRY"
    rm -f "$temp"

    refresh_anonymous_setting
    systemctl restart vsftpd
    ok "Da go share '$name'. Backup: $archive"
    [[ "$type" == user ]] && info "Linux user '$username' van duoc giu lai."
}

print_check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then printf '[OK]   %s\n' "$label"
    else printf '[FAIL] %s\n' "$label"
    fi
}

check_server() {
    local type name path username
    ensure_state
    printf '\n== KIEM TRA FTP SERVER ==\n'
    print_check "Da cai vsftpd" command -v vsftpd
    print_check "vsftpd dang chay" systemctl is-active --quiet vsftpd
    print_check "vsftpd tu khoi dong" systemctl is-enabled --quiet vsftpd
    print_check "Port TCP/21 dang listen" bash -c "ss -ltn | grep -qE '[:.]21[[:space:]]'"

    if systemctl is-active --quiet firewalld; then
        print_check "Firewall mo dich vu FTP" firewall-cmd --quiet --query-service=ftp
        print_check "Firewall mo passive ports" firewall-cmd --quiet --query-port=30000-31000/tcp
    else
        warn "firewalld khong chay."
    fi

    if command -v getenforce >/dev/null 2>&1; then
        info "SELinux: $(getenforce)"
        command -v getsebool >/dev/null 2>&1 && getsebool ftpd_full_access || true
    fi

    printf '\n== SHARE DO TOOL QUAN LY ==\n'
    list_registered_shares || true
    while IFS=$'\t' read -r type name path username; do
        [[ -e "$path" ]] || { warn "Thieu thu muc: $path"; continue; }
        stat -c '%A %U:%G %n' "$path"
        if [[ "$username" != "-" ]]; then
            if runuser -u "$username" -- test -r "$path"; then printf '  READ(%s): YES\n' "$username"
            else printf '  READ(%s): NO\n' "$username"; fi
            if runuser -u "$username" -- test -w "$path"; then printf '  WRITE(%s): YES\n' "$username"
            else printf '  WRITE(%s): NO\n' "$username"; fi
        fi
    done < "$SHARE_REGISTRY"
}

show_menu() {
    printf '\n%s\n' \
        "========================================" \
        " FTP SERVER MANAGER - PHUONG AN 2" \
        "========================================" \
        "1) Cai dat FTP Server" \
        "2) Bat/tat FTP Server" \
        "3) Them FTP share" \
        "4) Xoa FTP share" \
        "5) Kiem tra FTP Server" \
        "0) Thoat"
}

main() {
    local choice
    require_root
    ensure_state
    while true; do
        show_menu
        read -r -p "Lua chon: " choice
        case "$choice" in
            1) install_ftp_server; pause ;;
            2) service_control; pause ;;
            3) add_ftp_share; pause ;;
            4) delete_ftp_share; pause ;;
            5) check_server; pause ;;
            0) exit 0 ;;
            *) fail "Lua chon khong hop le."; pause ;;
        esac
    done
}

main "$@"
