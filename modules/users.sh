#!/usr/bin/env bash

users_menu_items() {
    printf '%s\n' "  1) Them FTP user" "  2) Xoa FTP user" "  3) Liet ke user thuong" \
        "  4) Doi mat khau" "  5) Khoa tai khoan" "  6) Mo khoa tai khoan" \
        "  7) Xem thu muc FTP cua user" "  0) Quay lai"
}
read_username() {
    read -r -p "Username: " FTP_INPUT_USERNAME
    valid_username "$FTP_INPUT_USERNAME" || { error "Username khong hop le (toi da 32 ky tu thuong)."; return 1; }
}
add_ftp_user() {
    read_username || return 1; local username="$FTP_INPUT_USERNAME"
    id "$username" >/dev/null 2>&1 && { error "User '$username' da ton tai."; return 1; }
    as_root useradd -m "$username" || return 1
    as_root mkdir -p "/home/$username/ftp/upload"
    as_root chown root:root "/home/$username/ftp"; as_root chmod 755 "/home/$username/ftp"
    as_root chown "$username:$username" "/home/$username/ftp/upload"
    info "Dat mat khau cho $username:"; as_root passwd "$username" || return 1
    success "Da tao $username; upload tai /home/$username/ftp/upload."
}
delete_ftp_user() {
    read_username || return 1; local username="$FTP_INPUT_USERNAME"
    id "$username" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
    confirm "Xoa '$username' va toan bo home directory?" || { info "Da huy."; return; }
    as_root userdel -r "$username" && success "Da xoa $username."
}
list_ftp_users() {
    section "User co UID >= UID_MIN"; local uid_min
    uid_min=$(awk '/^[[:space:]]*UID_MIN/{print $2}' /etc/login.defs 2>/dev/null); uid_min=${uid_min:-1000}
    awk -F: -v min="$uid_min" '$3 >= min && $1 != "nobody" {printf "%-20s %-7s %s\n", $1, $3, $6}' /etc/passwd
}
change_ftp_password() {
    read_username || return 1; id "$FTP_INPUT_USERNAME" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
    as_root passwd "$FTP_INPUT_USERNAME"
}
require_existing_ftp_user() {
    read_username || return 1
    id "$FTP_INPUT_USERNAME" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
}
get_user_password_status() {
    as_root passwd -S "$1" 2>/dev/null | awk '{print $2}'
}
lock_ftp_user() {
    require_existing_ftp_user || return 1
    local username="$FTP_INPUT_USERNAME" status
    as_root usermod -L "$username" || return 1
    status=$(get_user_password_status "$username")
    if [[ "$status" == L* ]]; then
        success "Da khoa $username (trang thai: $status)."
    else
        error "Lenh khoa da chay nhung trang thai hien tai la '$status'."
        return 1
    fi
}
unlock_ftp_user() {
    require_existing_ftp_user || return 1
    local username="$FTP_INPUT_USERNAME" status
    as_root usermod -U "$username" || true
    status=$(get_user_password_status "$username")

    if [[ "$status" == P* ]]; then
        success "Da mo khoa $username (trang thai: $status)."
        return 0
    fi

    if [[ "$status" == L* ]]; then
        warn "usermod -U chua go het khoa; dang thu passwd -u."
        as_root passwd -u "$username" || true
        status=$(get_user_password_status "$username")
    fi

    if [[ "$status" == P* ]]; then
        success "Da mo khoa $username (trang thai: $status)."
        return 0
    fi

    warn "Tai khoan van o trang thai '$status'. Can dat lai password de mo khoa an toan."
    confirm "Dat password moi cho $username ngay bay gio?" || return 1
    as_root passwd "$username" || return 1
    status=$(get_user_password_status "$username")
    [[ "$status" == P* ]] || { error "Mo khoa that bai; trang thai: $status"; return 1; }
    success "Da dat password va mo khoa $username (trang thai: $status)."
}
show_user_ftp_dir() {
    read_username || return 1; id "$FTP_INPUT_USERNAME" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
    as_root ls -lah "/home/$FTP_INPUT_USERNAME/ftp" 2>/dev/null || warn "User chua co thu muc ftp."
}
handle_users_choice() {
    case "$1" in
        1) add_ftp_user ;; 2) delete_ftp_user ;; 3) list_ftp_users ;; 4) change_ftp_password ;;
        5) lock_ftp_user ;; 6) unlock_ftp_user ;; 7) show_user_ftp_dir ;; *) error "Lua chon khong hop le." ;;
    esac
}
users_menu() { run_submenu "QUAN LY NGUOI DUNG" users_menu_items handle_users_choice; }
