#!/usr/bin/env bash

service_menu_items() {
    printf '%s\n' "  1) Cai dat vsftpd" "  2) Khoi dong" "  3) Dung" \
        "  4) Khoi dong lai" "  5) Bat tu khoi dong cung may" \
        "  6) Xem trang thai" "  7) Xem phien ban goi" "  0) Quay lai"
}
install_ftp_server() {
    local package_manager
    if command_exists dnf; then package_manager=dnf; elif command_exists yum; then package_manager=yum
    else error "Chi ho tro dnf/yum tren CentOS, RHEL, Rocky, AlmaLinux."; return 1; fi
    as_root "$package_manager" install -y vsftpd || return 1
    as_root systemctl enable --now "$FTP_SERVICE" || return 1
    success "Da cai dat va khoi dong $FTP_SERVICE."
    if command_exists firewall-cmd && systemctl is-active --quiet firewalld; then
        as_root firewall-cmd --permanent --add-service=ftp && as_root firewall-cmd --reload
        success "Da mo dich vu FTP tren firewalld."
    fi
}
control_ftp_service() {
    local action="$1"; require_command systemctl || return 1
    as_root systemctl "$action" "$FTP_SERVICE" && success "systemctl $action $FTP_SERVICE thanh cong."
}
show_service_status() { systemctl status "$FTP_SERVICE" --no-pager || true; }
show_package_version() { if command_exists rpm; then rpm -q vsftpd; else "$FTP_SERVICE" -v 2>&1 | head -1; fi; }
handle_service_choice() {
    case "$1" in
        1) install_ftp_server ;; 2) control_ftp_service start ;; 3) control_ftp_service stop ;;
        4) control_ftp_service restart ;; 5) control_ftp_service enable ;;
        6) show_service_status ;; 7) show_package_version ;; *) error "Lua chon khong hop le." ;;
    esac
}
service_menu() { run_submenu "DICH VU & CAI DAT" service_menu_items handle_service_choice; }
