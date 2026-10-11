#!/usr/bin/env bash

# FTP Manager - entry point. Feature implementations live in modules/.
set -o pipefail

APP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$APP_DIR/lib/core.sh"
source "$APP_DIR/modules/service.sh"
source "$APP_DIR/modules/users.sh"
source "$APP_DIR/modules/access.sh"
source "$APP_DIR/modules/configuration.sh"
source "$APP_DIR/modules/security.sh"
source "$APP_DIR/modules/monitoring.sh"
source "$APP_DIR/modules/transfer.sh"
source "$APP_DIR/modules/dns.sh"
source "$APP_DIR/modules/backup.sh"
source "$APP_DIR/modules/diagnostics.sh"

show_main_menu() {
    clear_screen
    print_banner
    printf '%s\n' \
        "  1) Dich vu & cai dat" \
        "  2) Quan ly nguoi dung" \
        "  3) Quyen truy cap FTP" \
        "  4) Cau hinh FTP" \
        "  5) Firewall & bao mat" \
        "  6) Giam sat & nhat ky" \
        "  7) Truyen file FTP" \
        "  8) DNS BIND" \
        "  9) Sao luu & khoi phuc" \
        " 10) Chan doan ket noi" \
        " 11) Tong quan nhanh" \
        "  0) Thoat"
    print_rule
}

main() {
    while true; do
        show_main_menu
        read -r -p "Chon nhom chuc nang: " choice
        case "$choice" in
            1) service_menu ;;
            2) users_menu ;;
            3) access_menu ;;
            4) configuration_menu ;;
            5) security_menu ;;
            6) monitoring_menu ;;
            7) transfer_menu ;;
            8) dns_menu ;;
            9) backup_menu ;;
            10) diagnostics_menu ;;
            11) quick_overview; pause_screen ;;
            0) info "Hen gap lai."; exit 0 ;;
            *) error "Lua chon khong hop le."; pause_screen ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
