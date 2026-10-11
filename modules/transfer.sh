#!/usr/bin/env bash

TRANSFER_HOST="${TRANSFER_HOST:-127.0.0.1}"
TRANSFER_PORT="${TRANSFER_PORT:-21}"
TRANSFER_USER="${TRANSFER_USER:-}"
TRANSFER_TLS_MODE="${TRANSFER_TLS_MODE:-off}"

transfer_menu_items() {
    printf '%s\n' \
        "  1) Cai lftp client" \
        "  2) Cau hinh ket noi" \
        "  3) Xem profile ket noi" \
        "  4) Liet ke file remote" \
        "  5) Upload mot file" \
        "  6) Download mot file" \
        "  7) Upload/dong bo thu muc" \
        "  8) Download/dong bo thu muc" \
        "  9) Tao thu muc remote" \
        " 10) Doi ten remote" \
        " 11) Xoa file remote" \
        " 12) Kiem tra quyen doc/ghi" \
        "  0) Quay lai"
}

install_lftp_client() {
    command_exists lftp && { success "lftp da duoc cai."; lftp --version | head -1; return; }
    local package_manager
    if command_exists dnf; then package_manager=dnf
    elif command_exists yum; then package_manager=yum
    else error "Khong co dnf/yum. Hay cai lftp bang package manager cua may client."; return 1
    fi
    as_root "$package_manager" install -y lftp && success "Da cai lftp client."
}

configure_transfer_profile() {
    local value
    read -r -p "FTP host [$TRANSFER_HOST]: " value; value=${value:-$TRANSFER_HOST}
    valid_hostname "$value" || valid_ipv4 "$value" || { error "Host/IP khong hop le."; return 1; }
    TRANSFER_HOST="$value"
    read -r -p "Control port [$TRANSFER_PORT]: " value; value=${value:-$TRANSFER_PORT}
    valid_port "$value" || { error "Port khong hop le."; return 1; }; TRANSFER_PORT="$value"
    read -r -p "Username [${TRANSFER_USER:-anonymous}]: " value; value=${value:-${TRANSFER_USER:-anonymous}}
    [[ "$value" == anonymous ]] || valid_username "$value" || { error "Username khong hop le."; return 1; }
    TRANSFER_USER="$value"
    printf '%s\n' "TLS mode: 1) off  2) strict  3) self-signed-lab"
    read -r -p "Chon [1]: " value
    case "${value:-1}" in
        1) TRANSFER_TLS_MODE=off ;;
        2) TRANSFER_TLS_MODE=strict ;;
        3) TRANSFER_TLS_MODE=insecure; warn "Chi bo verify certificate trong bai lab." ;;
        *) error "TLS mode khong hop le."; return 1 ;;
    esac
    success "Profile chi duoc giu trong phien chay hien tai."
}

show_transfer_profile() {
    section "FTP CLIENT PROFILE"
    printf 'Host      : %s\nPort      : %s\nUsername  : %s\nTLS       : %s\n' \
        "$TRANSFER_HOST" "$TRANSFER_PORT" "${TRANSFER_USER:-(chua dat)}" "$TRANSFER_TLS_MODE"
    printf 'Password  : khong luu; hoi lai moi thao tac\n'
}

lftp_quote() {
    local value="$1"
    [[ "$value" != *$'\n'* && "$value" != *$'\r'* ]] || return 1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    printf '"%s"' "$value"
}

require_transfer_profile() {
    require_command lftp || { error "Chon menu 1 de cai lftp client."; return 1; }
    [[ -n "$TRANSFER_USER" ]] || { error "Chon menu 2 de cau hinh ket noi truoc."; return 1; }
}

run_lftp_command() {
    require_transfer_profile || return 1
    local commands="$1" password script status host_q user_q password_q
    if [[ "$TRANSFER_USER" == anonymous ]]; then
        read -r -s -p "Anonymous password [anonymous@]: " password; printf '\n'
        password=${password:-anonymous@}
    else
        read -r -s -p "Password cho $TRANSFER_USER: " password; printf '\n'
    fi
    host_q=$(lftp_quote "$TRANSFER_HOST") || return 1
    user_q=$(lftp_quote "$TRANSFER_USER") || return 1
    password_q=$(lftp_quote "$password") || return 1
    script=$(mktemp) || return 1
    chmod 600 "$script"
    {
        printf '%s\n' "set cmd:fail-exit yes" "set net:max-retries 1" "set net:timeout 8"
        case "$TRANSFER_TLS_MODE" in
            strict) printf '%s\n' "set ftp:ssl-force true" "set ssl:verify-certificate true" ;;
            insecure) printf '%s\n' "set ftp:ssl-force true" "set ssl:verify-certificate false" ;;
            *) printf '%s\n' "set ftp:ssl-force false" ;;
        esac
        printf 'open -p %s -u %s,%s %s\n' "$TRANSFER_PORT" "$user_q" "$password_q" "$host_q"
        printf '%s\n' "$commands" "bye"
    } > "$script"
    password=''; password_q=''
    lftp -f "$script"; status=$?
    rm -f "$script"
    return "$status"
}

list_remote_files() {
    local path path_q
    read -r -p "Remote path [/]: " path; path=${path:-/}
    path_q=$(lftp_quote "$path") || { error "Path khong hop le."; return 1; }
    run_lftp_command "cls -lah $path_q"
}

upload_one_file() {
    local local_file remote_path local_q remote_q
    read -r -p "Local file: " local_file
    [[ -f "$local_file" ]] || { error "Local file khong ton tai."; return 1; }
    read -r -p "Remote file [ftp/upload/$(basename "$local_file")]: " remote_path
    remote_path=${remote_path:-ftp/upload/$(basename "$local_file")}
    local_q=$(lftp_quote "$local_file") || return 1; remote_q=$(lftp_quote "$remote_path") || return 1
    run_lftp_command "put $local_q -o $remote_q" && success "Upload thanh cong: $remote_path"
}

download_one_file() {
    local remote_file local_file remote_q local_q
    read -r -p "Remote file: " remote_file
    [[ -n "$remote_file" ]] || { error "Can remote file."; return 1; }
    read -r -p "Local file [$(basename "$remote_file")]: " local_file
    local_file=${local_file:-$(basename "$remote_file")}
    remote_q=$(lftp_quote "$remote_file") || return 1; local_q=$(lftp_quote "$local_file") || return 1
    run_lftp_command "get $remote_q -o $local_q" && success "Download thanh cong: $local_file"
}

mirror_upload_directory() {
    local local_dir remote_dir local_q remote_q
    read -r -p "Local directory: " local_dir
    [[ -d "$local_dir" ]] || { error "Local directory khong ton tai."; return 1; }
    read -r -p "Remote directory [ftp/upload]: " remote_dir; remote_dir=${remote_dir:-ftp/upload}
    local_q=$(lftp_quote "$local_dir") || return 1; remote_q=$(lftp_quote "$remote_dir") || return 1
    run_lftp_command "mirror --reverse --verbose --only-newer $local_q $remote_q"
}

mirror_download_directory() {
    local remote_dir local_dir remote_q local_q
    read -r -p "Remote directory: " remote_dir
    [[ -n "$remote_dir" ]] || { error "Can remote directory."; return 1; }
    read -r -p "Local directory [./ftp-download]: " local_dir; local_dir=${local_dir:-./ftp-download}
    remote_q=$(lftp_quote "$remote_dir") || return 1; local_q=$(lftp_quote "$local_dir") || return 1
    run_lftp_command "mirror --verbose --only-newer $remote_q $local_q"
}

make_remote_directory() {
    local path path_q; read -r -p "Remote directory moi: " path
    [[ -n "$path" ]] || { error "Can ten thu muc."; return 1; }
    path_q=$(lftp_quote "$path") || return 1
    run_lftp_command "mkdir -p $path_q" && success "Da tao $path"
}

rename_remote_path() {
    local old new old_q new_q
    read -r -p "Remote path hien tai: " old; read -r -p "Remote path moi: " new
    [[ -n "$old" && -n "$new" ]] || { error "Can du ca hai path."; return 1; }
    old_q=$(lftp_quote "$old") || return 1; new_q=$(lftp_quote "$new") || return 1
    run_lftp_command "mv $old_q $new_q" && success "Da doi ten."
}

delete_remote_file() {
    local path path_q; read -r -p "Remote file can xoa: " path
    [[ -n "$path" ]] || { error "Can remote file."; return 1; }
    confirm "Xoa vinh vien remote file '$path'?" || { info "Da huy."; return; }
    path_q=$(lftp_quote "$path") || return 1
    run_lftp_command "rm $path_q" && success "Da xoa $path"
}

test_transfer_permissions() {
    local directory directory_q test_file remote_test list_status write_status commands
    read -r -p "Remote directory can test [ftp/upload]: " directory; directory=${directory:-ftp/upload}
    directory=${directory%/}; directory_q=$(lftp_quote "$directory") || return 1
    section "TEST QUYEN DOC/LIST"
    run_lftp_command "cls -la $directory_q"; list_status=$?
    test_file=$(mktemp) || return 1
    printf 'FTP Manager permission test - %s\n' "$(date -Iseconds)" > "$test_file"
    remote_test="$directory/.ftp-manager-test-$$"
    local local_q remote_q
    local_q=$(lftp_quote "$test_file") || return 1; remote_q=$(lftp_quote "$remote_test") || return 1
    section "TEST QUYEN GHI/DELETE"
    printf -v commands 'put %s -o %s\nrm %s' "$local_q" "$remote_q" "$remote_q"
    run_lftp_command "$commands"; write_status=$?
    rm -f "$test_file"
    (( list_status == 0 )) && success "READ/LIST: cho phep" || warn "READ/LIST: bi tu choi"
    (( write_status == 0 )) && success "WRITE/DELETE: cho phep" || warn "WRITE/DELETE: bi tu choi"
    (( list_status == 0 && write_status == 0 ))
}

handle_transfer_choice() {
    case "$1" in
        1) install_lftp_client ;; 2) configure_transfer_profile ;; 3) show_transfer_profile ;;
        4) list_remote_files ;; 5) upload_one_file ;; 6) download_one_file ;;
        7) mirror_upload_directory ;; 8) mirror_download_directory ;; 9) make_remote_directory ;;
        10) rename_remote_path ;; 11) delete_remote_file ;; 12) test_transfer_permissions ;;
        *) error "Lua chon khong hop le." ;;
    esac
}

transfer_menu() { run_submenu "TRUYEN FILE FTP" transfer_menu_items handle_transfer_choice; }
