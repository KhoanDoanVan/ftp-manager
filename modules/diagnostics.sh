#!/usr/bin/env bash

diagnostics_menu_items() {
    printf '%s\n' "  1) Chay health check day du" "  2) Kiem tra package/lenh" \
        "  3) Kiem tra config co ban" "  4) Kiem tra port 21" "  5) Kiem tra FTP localhost" \
        "  6) Hien thi dia chi mang" "  7) Kiem tra quyen thu muc users" "  0) Quay lai"
}
check_dependencies() {
    local item missing=0
    for item in systemctl ss awk sed tar; do
        if command_exists "$item"; then success "$item"; else error "$item: thieu"; missing=1; fi
    done
    if command_exists rpm && rpm -q vsftpd >/dev/null 2>&1; then success "vsftpd package da cai"; else warn "Khong xac nhan duoc vsftpd package."; fi
    return "$missing"
}
audit_configuration() {
    [[ -r "$FTP_CONFIG" ]] || { error "Khong doc duoc $FTP_CONFIG"; return 1; }
    local key value
    for key in anonymous_enable local_enable write_enable chroot_local_user pasv_enable pasv_min_port pasv_max_port ssl_enable; do
        value=$(config_value "$key"); printf '%-24s %s\n' "$key" "${value:-(default/chua dat)}"
    done
    [[ "$(config_value anonymous_enable)" == YES ]] && warn "Anonymous login dang bat."
    [[ "$(config_value chroot_local_user)" != YES ]] && warn "Local users chua bi gioi han trong home."
}
check_control_port() {
    local port; port=$(config_value listen_port); port=${port:-21}
    if command_exists ss && ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]${port}$"; then success "TCP $port dang LISTEN."
    else error "Khong thay TCP $port dang LISTEN."; return 1; fi
}
test_local_ftp() {
    local port; port=$(config_value listen_port); port=${port:-21}
    if command_exists curl; then curl --silent --show-error --connect-timeout 5 "ftp://127.0.0.1:$port/" -o /dev/null \
        && success "FTP localhost phan hoi." || warn "Khong dang nhap duoc (co the anonymous bi tat), nhung server van co the dang chay."
    elif command_exists nc; then nc -vz -w 5 127.0.0.1 "$port"
    else error "Can curl hoac nc de test."; return 1; fi
}
show_network_addresses() { command_exists ip && ip -brief address || hostname -I; }
check_user_directories() {
    local path owner mode found=0
    while IFS= read -r path; do
        found=1; owner=$(stat -c '%U:%G' "$path" 2>/dev/null || stat -f '%Su:%Sg' "$path")
        mode=$(stat -c '%a' "$path" 2>/dev/null || stat -f '%Lp' "$path")
        printf '%-35s owner=%-18s mode=%s\n' "$path" "$owner" "$mode"
        [[ -d "$path/upload" && -w "$path/upload" ]] || warn "$path/upload khong ton tai hoac can kiem tra quyen."
    done < <(find /home -mindepth 2 -maxdepth 2 -type d -name ftp 2>/dev/null)
    (( found )) || warn "Chua co FTP home."
}
full_health_check() {
    section "1/6 Dependencies"; check_dependencies || true
    section "2/6 Service"; if service_is_active; then success "$FTP_SERVICE active"; else error "$FTP_SERVICE inactive"; fi
    section "3/6 Configuration"; audit_configuration || true
    section "4/6 Listening port"; check_control_port || true
    section "5/6 Firewall"; if command_exists firewall-cmd; then firewall-cmd --query-service=ftp 2>/dev/null && success "Firewall cho phep ftp" || warn "Firewall chua cho phep ftp"; else warn "firewalld khong co san"; fi
    section "6/6 Storage"; df -h /home 2>/dev/null || df -h /
}
handle_diagnostics_choice() {
    case "$1" in
        1) full_health_check ;; 2) check_dependencies ;; 3) audit_configuration ;; 4) check_control_port ;;
        5) test_local_ftp ;; 6) show_network_addresses ;; 7) check_user_directories ;; *) error "Lua chon khong hop le." ;;
    esac
}
diagnostics_menu() { run_submenu "CHAN DOAN KET NOI" diagnostics_menu_items handle_diagnostics_choice; }
