#!/usr/bin/env bash

security_menu_items() {
    printf '%s\n' "  1) Xem firewall" "  2) Mo FTP service" "  3) Dong FTP service" \
        "  4) Mo passive port range" "  5) Xem SELinux" "  6) Bat SELinux FTP home dir" \
        "  7) Chan user dang nhap FTP" "  8) Bo chan user" "  9) Xem danh sach bi chan" "  0) Quay lai"
}
require_firewalld() { require_command firewall-cmd && systemctl is-active --quiet firewalld || { error "firewalld chua chay."; return 1; }; }
show_firewall() { require_firewalld && as_root firewall-cmd --list-all; }
set_ftp_firewall() {
    local mode="$1"; require_firewalld || return 1
    as_root firewall-cmd --permanent "$mode"-service=ftp && as_root firewall-cmd --reload && success "Da cap nhat firewall."
}
open_passive_firewall() {
    local minimum maximum
    minimum=$(config_value pasv_min_port); maximum=$(config_value pasv_max_port)
    read -r -p "Port dau [${minimum:-30000}]: " input; minimum=${input:-${minimum:-30000}}
    read -r -p "Port cuoi [${maximum:-31000}]: " input; maximum=${input:-${maximum:-31000}}
    valid_passive_range "$minimum" "$maximum" || { error "Khoang port khong hop le."; return 1; }
    require_firewalld || return 1
    as_root firewall-cmd --permanent --add-port="${minimum}-${maximum}/tcp" && as_root firewall-cmd --reload
    success "Da mo ${minimum}-${maximum}/tcp."
}
show_selinux() { command_exists getenforce && getenforce || warn "SELinux tools khong co san."; command_exists getsebool && getsebool -a | grep -E 'ftp|ftpd' || true; }
enable_ftp_home_selinux() {
    require_command setsebool || return 1
    as_root setsebool -P ftpd_full_access on && success "Da bat ftpd_full_access."
    warn "Day la quyen rong; chi dung khi can upload vao home directory."
}
manage_blocked_user() {
    local action="$1" username temporary
    read_username || return 1; username="$FTP_INPUT_USERNAME"
    as_root touch "$FTP_USER_LIST"
    if [[ "$action" == add ]]; then
        grep -Fxq "$username" "$FTP_USER_LIST" || printf '%s\n' "$username" | as_root tee -a "$FTP_USER_LIST" >/dev/null
        success "Da them $username vao danh sach chan."
    else
        temporary=$(mktemp) || return 1
        awk -v username="$username" '$0 != username' "$FTP_USER_LIST" > "$temporary"
        as_root cp "$temporary" "$FTP_USER_LIST" || { rm -f "$temporary"; return 1; }
        rm -f "$temporary"
        success "Da bo chan $username."
    fi
}
show_blocked_users() { [[ -r "$FTP_USER_LIST" ]] && grep -Ev '^[[:space:]]*($|#)' "$FTP_USER_LIST" || warn "Chua co danh sach."; }
handle_security_choice() {
    case "$1" in
        1) show_firewall ;; 2) set_ftp_firewall --add ;; 3) set_ftp_firewall --remove ;;
        4) open_passive_firewall ;; 5) show_selinux ;; 6) enable_ftp_home_selinux ;;
        7) manage_blocked_user add ;; 8) manage_blocked_user remove ;; 9) show_blocked_users ;; *) error "Lua chon khong hop le." ;;
    esac
}
security_menu() { run_submenu "FIREWALL & BAO MAT" security_menu_items handle_security_choice; }
