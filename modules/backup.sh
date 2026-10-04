#!/usr/bin/env bash

backup_menu_items() {
    printf '%s\n' "  1) Sao luu cau hinh" "  2) Liet ke ban sao luu" "  3) Khoi phuc cau hinh" \
        "  4) Sao luu du lieu FTP users" "  5) Kiem tra noi dung archive" "  0) Quay lai"
}
create_config_backup() {
    local stamp archive stage
    stamp=$(date +%Y%m%d-%H%M%S); archive="$BACKUP_DIR/config-$stamp.tar.gz"
    stage=$(mktemp -d) || return 1
    as_root mkdir -p "$BACKUP_DIR"
    if [[ -f "$FTP_CONFIG" ]]; then as_root cp -a "$FTP_CONFIG" "$stage/vsftpd.conf"; else error "Khong tim thay config."; rmdir "$stage"; return 1; fi
    [[ -f "$FTP_USER_LIST" ]] && as_root cp -a "$FTP_USER_LIST" "$stage/user_list"
    { printf 'created=%s\n' "$(date -Iseconds)"; printf 'host=%s\n' "$(hostname)"; printf 'version=%s\n' "$APP_VERSION"; } > "$stage/metadata"
    as_root tar -C "$stage" -czf "$archive" . && success "Da tao $archive"
    as_root rm -f "$stage/vsftpd.conf" "$stage/user_list" "$stage/metadata" 2>/dev/null || true
    rmdir "$stage" 2>/dev/null || true
}
list_backups() {
    [[ -d "$BACKUP_DIR" ]] || { warn "Chua co backup."; return; }
    as_root find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.tar.gz' -printf '%TY-%Tm-%Td %TH:%TM  %10s  %p\n' 2>/dev/null \
        || as_root find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.tar.gz' -ls
}
restore_config_backup() {
    local archive stage
    read -r -p "Duong dan config-*.tar.gz: " archive
    [[ -f "$archive" ]] || { error "Archive khong ton tai."; return 1; }
    tar -tzf "$archive" >/dev/null 2>&1 || { error "Archive bi hong/khong dung gzip tar."; return 1; }
    tar -tzf "$archive" | grep -Eq '^\./vsftpd\.conf$' || { error "Archive khong co vsftpd.conf."; return 1; }
    confirm "Ghi de cau hinh hien tai va restart vsftpd?" || { info "Da huy."; return; }
    backup_config_file || return 1; stage=$(mktemp -d) || return 1
    tar -xzf "$archive" -C "$stage" ./vsftpd.conf ./user_list 2>/dev/null || tar -xzf "$archive" -C "$stage" ./vsftpd.conf
    as_root install -m 600 "$stage/vsftpd.conf" "$FTP_CONFIG"
    [[ -f "$stage/user_list" ]] && as_root install -m 600 "$stage/user_list" "$FTP_USER_LIST"
    rm -f "$stage/vsftpd.conf" "$stage/user_list"; rmdir "$stage"
    control_ftp_service restart && success "Khoi phuc thanh cong."
}
backup_user_data() {
    local stamp archive homes=()
    stamp=$(date +%Y%m%d-%H%M%S); archive="$BACKUP_DIR/data-$stamp.tar.gz"
    while IFS= read -r path; do homes+=("$path"); done < <(find /home -mindepth 2 -maxdepth 2 -type d -name ftp 2>/dev/null)
    ((${#homes[@]})) || { warn "Khong co /home/*/ftp de sao luu."; return; }
    as_root mkdir -p "$BACKUP_DIR"
    as_root tar -czf "$archive" "${homes[@]}" && success "Da tao $archive"
}
inspect_archive() {
    local archive; read -r -p "Duong dan archive: " archive
    [[ -f "$archive" ]] || { error "File khong ton tai."; return 1; }
    tar -tzvf "$archive" | head -100
}
handle_backup_choice() {
    case "$1" in
        1) create_config_backup ;; 2) list_backups ;; 3) restore_config_backup ;;
        4) backup_user_data ;; 5) inspect_archive ;; *) error "Lua chon khong hop le." ;;
    esac
}
backup_menu() { run_submenu "SAO LUU & KHOI PHUC" backup_menu_items handle_backup_choice; }
