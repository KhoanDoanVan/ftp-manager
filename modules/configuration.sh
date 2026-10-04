#!/usr/bin/env bash

configuration_menu_items() {
    printf '%s\n' "  1) Xem cau hinh dang hoat dong" "  2) Bat/tat upload" \
        "  3) Bat/tat anonymous" "  4) Bat chroot user" "  5) Dat passive port range" \
        "  6) Doi control port" "  7) Cau hinh TLS tu ky" "  8) Mo file cau hinh" \
        "  9) Restart de ap dung" "  0) Quay lai"
}
show_effective_config() {
    [[ -r "$FTP_CONFIG" ]] || { error "Khong doc duoc $FTP_CONFIG"; return 1; }
    grep -Ev '^[[:space:]]*($|#)' "$FTP_CONFIG" || true
}
prompt_yes_no_option() {
    local key="$1" label="$2" answer
    read -r -p "$label (yes/no): " answer
    case "${answer,,}" in yes|y) set_config_value "$key" YES ;; no|n) set_config_value "$key" NO ;; *) error "Chi nhap yes hoac no." ;; esac
}
configure_passive_ports() {
    local minimum maximum
    read -r -p "Port dau [30000]: " minimum; minimum=${minimum:-30000}
    read -r -p "Port cuoi [31000]: " maximum; maximum=${maximum:-31000}
    valid_passive_range "$minimum" "$maximum" || { error "Khoang port khong hop le."; return 1; }
    set_config_value pasv_enable YES && set_config_value pasv_min_port "$minimum" && set_config_value pasv_max_port "$maximum"
    warn "Hay mo TCP ${minimum}-${maximum} trong firewall (menu Bao mat)."
}
configure_control_port() {
    local port; read -r -p "Control port [21]: " port; port=${port:-21}
    valid_port "$port" || { error "Port phai nam trong 1..65535."; return 1; }
    set_config_value listen_port "$port"
}
configure_tls() {
    require_command openssl || return 1
    local cert=/etc/ssl/private/vsftpd.pem
    if [[ ! -f "$cert" ]]; then
        as_root mkdir -p /etc/ssl/private
        as_root openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
            -subj "/CN=$(hostname -f 2>/dev/null || hostname)" -keyout "$cert" -out "$cert" || return 1
        as_root chmod 600 "$cert"
    fi
    set_config_value rsa_cert_file "$cert" && set_config_value rsa_private_key_file "$cert" \
        && set_config_value ssl_enable YES && set_config_value force_local_logins_ssl YES \
        && set_config_value force_local_data_ssl YES
    success "Da bat FTPS explicit voi chung chi tu ky."
}
edit_configuration() {
    local editor=${EDITOR:-vi}; backup_config_file || return 1
    if (( EUID == 0 )); then "$editor" "$FTP_CONFIG"; else sudo "$editor" "$FTP_CONFIG"; fi
}
handle_configuration_choice() {
    case "$1" in
        1) show_effective_config ;; 2) prompt_yes_no_option write_enable "Cho phep upload?" ;;
        3) prompt_yes_no_option anonymous_enable "Cho phep anonymous?" ;; 4) set_config_value chroot_local_user YES ;;
        5) configure_passive_ports ;; 6) configure_control_port ;; 7) configure_tls ;; 8) edit_configuration ;;
        9) control_ftp_service restart ;; *) error "Lua chon khong hop le." ;;
    esac
}
configuration_menu() { run_submenu "CAU HINH FTP" configuration_menu_items handle_configuration_choice; }
