#!/usr/bin/env bash

DNS_CONFIG="${DNS_CONFIG:-/etc/named.conf}"
DNS_ZONES_CONFIG="${DNS_ZONES_CONFIG:-/etc/named.rfc1912.zones}"
DNS_ZONE_DIR="${DNS_ZONE_DIR:-/var/named}"
DNS_LAN_INTERFACE="${DNS_LAN_INTERFACE:-enp26s0}"

dns_menu_items() {
    printf '%s\n' \
        "  1) Cai BIND va DNS utilities" \
        "  2) Cho phep client LAN truy van DNS" \
        "  3) Tao/cap nhat zone va ban ghi FTP" \
        "  4) Mo DNS tren firewall" \
        "  5) Kiem tra cu phap BIND" \
        "  6) Xem trang thai named" \
        "  7) Kiem tra phan giai ten FTP" \
        "  8) Xem cac zone do tool quan ly" \
        "  0) Quay lai"
}

install_bind_server() {
    local package_manager
    if command_exists dnf; then package_manager=dnf
    elif command_exists yum; then package_manager=yum
    else error "Khong co dnf/yum tren he thong nay."; return 1
    fi
    as_root "$package_manager" install -y bind bind-utils || return 1
    as_root systemctl enable --now named && success "BIND da cai va dang chay."
}

rewrite_named_option() {
    local key="$1" replacement="$2" temporary
    [[ -f "$DNS_CONFIG" ]] || { error "Khong tim thay $DNS_CONFIG"; return 1; }
    temporary=$(mktemp) || return 1
    as_root awk -v key="$key" -v replacement="$replacement" '
        $0 ~ "^[[:space:]]*" key "[[:space:]]" { print "\t" replacement; changed=1; next }
        { print }
        END { if (!changed) exit 2 }
    ' "$DNS_CONFIG" > "$temporary"
    local status=$?
    if (( status != 0 )); then
        rm -f "$temporary"
        error "Khong tim thay option '$key' trong $DNS_CONFIG; hay kiem tra file thu cong."
        return 1
    fi
    as_root cp "$temporary" "$DNS_CONFIG"; status=$?
    rm -f "$temporary"
    return "$status"
}

allow_lan_dns_queries() {
    local backup network suggested_network
    suggested_network=$(ip -4 route show dev "$DNS_LAN_INTERFACE" scope link 2>/dev/null \
        | awk '$1 ~ /^[0-9]+\./ && $1 ~ /\// {print $1; exit}')
    [[ -n "$suggested_network" ]] || suggested_network=$(ip route 2>/dev/null \
        | awk '$1 ~ /^[0-9]+\./ && $1 ~ /\// {print $1; exit}')
    read -r -p "Mang LAN duoc phep truy van [${suggested_network:-192.168.1.0/24}]: " network
    network=${network:-${suggested_network:-192.168.1.0/24}}
    valid_ipv4_cidr "$network" || { error "CIDR khong hop le."; return 1; }
    warn "BIND se lang nghe tren moi IPv4 interface, nhung chi localhost va $network duoc truy van."
    confirm "Ap dung cau hinh truy van LAN?" || { info "Da huy."; return; }
    backup=$(next_backup_path "$DNS_CONFIG") || return 1
    as_root cp -a "$DNS_CONFIG" "$backup" || return 1
    info "Da tao ban sao: $backup"
    rewrite_named_option 'listen-on port 53' 'listen-on port 53 { any; };' || return 1
    rewrite_named_option 'allow-query' "allow-query { localhost; $network; };" || return 1
    if command_exists named-checkconf; then as_root named-checkconf "$DNS_CONFIG" || { error "named.conf khong hop le; dung file .bak de rollback."; return 1; }; fi
    as_root systemctl restart named && success "BIND dang lang nghe va cho phep client LAN truy van."
}

append_zone_declaration() {
    local zone="$1" zone_filename="$2" temporary
    grep -Eq "^[[:space:]]*zone[[:space:]]+\"${zone//./\\.}\"" "$DNS_ZONES_CONFIG" && return 0
    temporary=$(mktemp) || return 1
    as_root awk '{ print }' "$DNS_ZONES_CONFIG" > "$temporary" || { rm -f "$temporary"; return 1; }
    {
        printf '\n// Managed by FTP Manager\n'
        printf 'zone "%s" IN {\n' "$zone"
        printf '    type master;\n'
        printf '    file "%s";\n' "$zone_filename"
        printf '    allow-update { none; };\n'
        printf '};\n'
    } >> "$temporary"
    local backup
    backup=$(next_backup_path "$DNS_ZONES_CONFIG") || { rm -f "$temporary"; return 1; }
    as_root cp -a "$DNS_ZONES_CONFIG" "$backup" || { rm -f "$temporary"; return 1; }
    as_root cp "$temporary" "$DNS_ZONES_CONFIG"; local status=$?
    rm -f "$temporary"
    return "$status"
}

configure_ftp_dns_record() {
    require_command named-checkzone || { error "Cai BIND bang menu 1 truoc."; return 1; }
    local zone label ip suggested_ip zone_filename zone_path temporary serial
    read -r -p "DNS zone (vi du sgu.edu.vn): " zone
    valid_hostname "$zone" && [[ "$zone" == *.* ]] || { error "Zone khong hop le."; return 1; }
    read -r -p "Ten host FTP [ftp]: " label; label=${label:-ftp}
    valid_hostname "$label" && [[ "$label" != *.* ]] || { error "Host label chi nen la mot nhan, vi du ftp."; return 1; }
    suggested_ip=$(ip -4 -o address show dev "$DNS_LAN_INTERFACE" 2>/dev/null \
        | awk '{split($4, address, "/"); print address[1]; exit}')
    [[ -n "$suggested_ip" ]] || suggested_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    read -r -p "IPv4 cua FTP server [${suggested_ip:-192.168.1.120}]: " ip; ip=${ip:-${suggested_ip:-192.168.1.120}}
    valid_ipv4 "$ip" || { error "IPv4 khong hop le."; return 1; }
    zone_filename="ftp-manager-${zone}.zone"; zone_path="$DNS_ZONE_DIR/$zone_filename"
    serial=$(date +%Y%m%d%H)
    temporary=$(mktemp) || return 1
    {
        printf '$TTL 86400\n'
        printf '@ IN SOA ns1.%s. root.%s. (\n' "$zone" "$zone"
        printf '    %s ; serial\n    3600 ; refresh\n    1800 ; retry\n    604800 ; expire\n    86400 ; minimum\n)\n' "$serial"
        printf '@    IN NS ns1.%s.\n' "$zone"
        printf 'ns1  IN A  %s\n' "$ip"
        printf '%s  IN A  %s\n' "$label" "$ip"
    } > "$temporary"
    named-checkzone "$zone" "$temporary" || { rm -f "$temporary"; error "Zone file khong hop le."; return 1; }
    if [[ -f "$zone_path" ]]; then
        local zone_backup
        zone_backup=$(next_backup_path "$zone_path") || { rm -f "$temporary"; return 1; }
        as_root cp -a "$zone_path" "$zone_backup" || { rm -f "$temporary"; return 1; }
    fi
    as_root install -o root -g named -m 640 "$temporary" "$zone_path" || { rm -f "$temporary"; return 1; }
    rm -f "$temporary"
    append_zone_declaration "$zone" "$zone_filename" || return 1
    as_root named-checkconf "$DNS_CONFIG" || { error "BIND config khong hop le; chua restart."; return 1; }
    as_root named-checkzone "$zone" "$zone_path" || return 1
    as_root systemctl enable --now named && as_root systemctl restart named || return 1
    success "Da tao ${label}.${zone} -> $ip"
}

open_dns_firewall() {
    require_firewalld || return 1
    as_root firewall-cmd --permanent --add-service=dns \
        && as_root firewall-cmd --reload \
        && success "Da mo DNS (TCP/UDP 53) tren firewalld."
}

validate_bind_configuration() {
    require_command named-checkconf || { error "named-checkconf chua duoc cai."; return 1; }
    as_root named-checkconf -z "$DNS_CONFIG" && success "BIND config va cac primary zone hop le."
}

show_named_status() { systemctl status named --no-pager || true; }

test_ftp_name_resolution() {
    local fqdn server
    read -r -p "FQDN can test (vi du ftp.sgu.edu.vn): " fqdn
    valid_hostname "$fqdn" || { error "FQDN khong hop le."; return 1; }
    read -r -p "DNS server [127.0.0.1]: " server; server=${server:-127.0.0.1}
    valid_ipv4 "$server" || { error "DNS server IP khong hop le."; return 1; }
    if command_exists dig; then dig +short "@$server" "$fqdn" A
    elif command_exists nslookup; then nslookup "$fqdn" "$server"
    else error "Can dig hoac nslookup (package bind-utils)."; return 1; fi
}

list_managed_zones() {
    [[ -d "$DNS_ZONE_DIR" ]] || { warn "$DNS_ZONE_DIR khong ton tai."; return; }
    as_root find "$DNS_ZONE_DIR" -maxdepth 1 -type f -name 'ftp-manager-*.zone' -print
}

handle_dns_choice() {
    case "$1" in
        1) install_bind_server ;; 2) allow_lan_dns_queries ;; 3) configure_ftp_dns_record ;;
        4) open_dns_firewall ;; 5) validate_bind_configuration ;; 6) show_named_status ;;
        7) test_ftp_name_resolution ;; 8) list_managed_zones ;; *) error "Lua chon khong hop le." ;;
    esac
}

dns_menu() { run_submenu "DNS BIND" dns_menu_items handle_dns_choice; }
