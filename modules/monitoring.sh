#!/usr/bin/env bash

monitoring_menu_items() {
    printf '%s\n' "  1) Tong quan nhanh" "  2) Trang thai chi tiet" "  3) Port dang lang nghe" \
        "  4) Ket noi FTP hien tai" "  5) Systemd log (50 dong)" "  6) Transfer log" \
        "  7) Dung luong cac FTP home" "  8) Theo doi log truc tiep" "  0) Quay lai"
}
quick_overview() {
    section "TONG QUAN"
    printf 'Hostname       : %s\n' "$(hostname)"
    printf 'IP             : %s\n' "$(hostname -I 2>/dev/null | xargs || echo N/A)"
    if service_is_active; then printf 'Dich vu        : %sactive%s\n' "$C_GREEN" "$C_RESET"; else printf 'Dich vu        : %sinactive%s\n' "$C_RED" "$C_RESET"; fi
    printf 'Control port   : %s\n' "$(config_value listen_port 2>/dev/null || true)" | sed 's/: $/: 21 (default)/'
    printf 'Passive range  : %s - %s\n' "$(config_value pasv_min_port 2>/dev/null || echo N/A)" "$(config_value pasv_max_port 2>/dev/null || echo N/A)"
    printf 'Config         : %s\n' "$FTP_CONFIG"
}
show_listening_ports() { require_command ss && as_root ss -ltnp | awk 'NR==1 || /:21 |vsftpd/'; }
show_ftp_connections() { require_command ss && as_root ss -tnp | awk 'NR==1 || /:21 |vsftpd/'; }
show_system_logs() { as_root journalctl -u "$FTP_SERVICE" -n 50 --no-pager; }
show_transfer_log() { [[ -f "$FTP_LOG" ]] && as_root tail -n 50 "$FTP_LOG" || warn "Khong tim thay $FTP_LOG."; }
show_ftp_disk_usage() { as_root du -sh /home/*/ftp 2>/dev/null || warn "Chua co FTP home."; }
follow_ftp_logs() {
    warn "Nhan Ctrl+C de dung theo doi."
    as_root journalctl -u "$FTP_SERVICE" -f
}
handle_monitoring_choice() {
    case "$1" in
        1) quick_overview ;; 2) show_service_status ;; 3) show_listening_ports ;; 4) show_ftp_connections ;;
        5) show_system_logs ;; 6) show_transfer_log ;; 7) show_ftp_disk_usage ;; 8) follow_ftp_logs ;; *) error "Lua chon khong hop le." ;;
    esac
}
monitoring_menu() { run_submenu "GIAM SAT & NHAT KY" monitoring_menu_items handle_monitoring_choice; }
