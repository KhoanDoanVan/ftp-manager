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
set_user_lock() {
    local mode="$1"; read_username || return 1
    id "$FTP_INPUT_USERNAME" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
    as_root usermod "$mode" "$FTP_INPUT_USERNAME" && success "Da cap nhat $FTP_INPUT_USERNAME."
}
show_user_ftp_dir() {
    read_username || return 1; id "$FTP_INPUT_USERNAME" >/dev/null 2>&1 || { error "User khong ton tai."; return 1; }
    as_root ls -lah "/home/$FTP_INPUT_USERNAME/ftp" 2>/dev/null || warn "User chua co thu muc ftp."
}
handle_users_choice() {
    case "$1" in
        1) add_ftp_user ;; 2) delete_ftp_user ;; 3) list_ftp_users ;; 4) change_ftp_password ;;
        5) set_user_lock -L ;; 6) set_user_lock -U ;; 7) show_user_ftp_dir ;; *) error "Lua chon khong hop le." ;;
    esac
}
users_menu() { run_submenu "QUAN LY NGUOI DUNG" users_menu_items handle_users_choice; }
