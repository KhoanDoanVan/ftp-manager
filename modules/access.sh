#!/usr/bin/env bash

access_menu_items() {
    printf '%s\n' \
        "  1) Xem ma tran quyen FTP" \
        "  2) Bat anonymous chi doc" \
        "  3) Bat anonymous upload an toan" \
        "  4) Tat anonymous" \
        "  5) Dat local user chi doc" \
        "  6) Dat local user doc/ghi" \
        "  7) Kiem tra quyen mot local user" \
        "  8) Xem trang thai khoa cua user" \
        "  0) Quay lai"
}

show_access_matrix() {
    section "MA TRAN QUYEN"
    printf '%-18s %-10s %-12s %s\n' "Vai tro" "Dang nhap" "Truyen file" "Pham vi"
    printf '%-18s %-10s %-12s %s\n' "root/sudo admin" "He thong" "Quan ly" "Toan server"
    printf '%-18s %-10s %-12s %s\n' "local read-only" "Password" "Download" "Home da chroot"
    printf '%-18s %-10s %-12s %s\n' "local read-write" "Password" "Up/Download" "ftp/upload"
    printf '%-18s %-10s %-12s %s\n' "anonymous" "Khong/Email" "Theo config" "/var/ftp"
    printf '%-18s %-10s %-12s %s\n' "locked/blocked" "Tu choi" "Khong" "Khong truy cap"
    printf '\nAdmin khong nen dang nhap FTP bang tai khoan root.\n'
}

prepare_anonymous_root() {
    as_root mkdir -p /var/ftp/pub
    as_root chown root:root /var/ftp /var/ftp/pub
    as_root chmod 755 /var/ftp /var/ftp/pub
}

enable_anonymous_read_only() {
    prepare_anonymous_root || return 1
    set_config_value anonymous_enable YES \
        && set_config_value no_anon_password YES \
        && set_config_value anon_upload_enable NO \
        && set_config_value anon_mkdir_write_enable NO \
        || return 1
    success "Anonymous chi duoc doc tai /var/ftp/pub. Restart vsftpd de ap dung."
}

enable_anonymous_upload() {
    confirm "Anonymous upload co rui ro. Tiep tuc tao /var/ftp/upload?" || { info "Da huy."; return; }
    id ftp >/dev/null 2>&1 || { error "Tai khoan he thong 'ftp' chua ton tai; hay cai vsftpd truoc."; return 1; }
    prepare_anonymous_root || return 1
    as_root mkdir -p /var/ftp/upload
    as_root chown ftp:ftp /var/ftp/upload
    as_root chmod 733 /var/ftp/upload
    set_config_value anonymous_enable YES \
        && set_config_value no_anon_password YES \
        && set_config_value write_enable YES \
        && set_config_value anon_upload_enable YES \
        && set_config_value anon_mkdir_write_enable NO \
        && set_config_value anon_world_readable_only YES \
        && set_config_value anon_umask 077 \
        || return 1
    warn "Anonymous co the upload vao /upload nhung khong doc lai file mode 600."
    info "Restart vsftpd de ap dung."
}

disable_anonymous_access() {
    set_config_value anonymous_enable NO && success "Da tat anonymous. Restart vsftpd de ap dung."
}

require_local_user() {
    read_username || return 1
    id "$FTP_INPUT_USERNAME" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
}

set_local_user_read_only() {
    require_local_user || return 1
    local username="$FTP_INPUT_USERNAME" directory="/home/$FTP_INPUT_USERNAME/ftp"
    [[ -d "$directory" ]] || { error "Khong tim thay $directory"; return 1; }
    confirm "Doi owner toan bo $directory thanh root va bo quyen ghi cua $username?" || { info "Da huy."; return; }
    as_root chown -R root:root "$directory" || return 1
    as_root chmod -R u=rwX,go=rX "$directory" || return 1
    success "$username da o che do chi doc trong FTP home."
}

set_local_user_read_write() {
    require_local_user || return 1
    local username="$FTP_INPUT_USERNAME" root_dir="/home/$FTP_INPUT_USERNAME/ftp" upload_dir
    upload_dir="$root_dir/upload"
    as_root mkdir -p "$upload_dir" || return 1
    as_root chown root:root "$root_dir" && as_root chmod 755 "$root_dir" || return 1
    as_root chown -R "$username:$username" "$upload_dir" || return 1
    as_root chmod -R u=rwX,go-rwx "$upload_dir" || return 1
    success "$username duoc doc/ghi trong $upload_dir; goc chroot van thuoc root."
}

inspect_local_access() {
    require_local_user || return 1
    local username="$FTP_INPUT_USERNAME" path
    section "ACCOUNT"
    as_root passwd -S "$username" 2>/dev/null || true
    section "PATH PERMISSIONS"
    for path in "/home/$username" "/home/$username/ftp" "/home/$username/ftp/upload"; do
        if [[ -e "$path" ]]; then
            as_root find "$path" -maxdepth 0 -printf '%M  %u:%g  %p\n' 2>/dev/null || as_root ls -ld "$path"
        else
            warn "Khong ton tai: $path"
        fi
    done
}

show_user_lock_status() {
    require_local_user || return 1
    as_root passwd -S "$FTP_INPUT_USERNAME"
    printf 'P = co password, L = bi khoa, NP = khong co password.\n'
}

handle_access_choice() {
    case "$1" in
        1) show_access_matrix ;;
        2) enable_anonymous_read_only ;;
        3) enable_anonymous_upload ;;
        4) disable_anonymous_access ;;
        5) set_local_user_read_only ;;
        6) set_local_user_read_write ;;
        7) inspect_local_access ;;
        8) show_user_lock_status ;;
        *) error "Lua chon khong hop le." ;;
    esac
}

access_menu() { run_submenu "QUYEN TRUY CAP FTP" access_menu_items handle_access_choice; }
