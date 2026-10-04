#!/usr/bin/env bash

APP_NAME="FTP Manager"
APP_VERSION="2.0.0"
FTP_SERVICE="${FTP_SERVICE:-vsftpd}"
FTP_CONFIG="${FTP_CONFIG:-/etc/vsftpd/vsftpd.conf}"
FTP_USER_LIST="${FTP_USER_LIST:-/etc/vsftpd/user_list}"
FTP_LOG="${FTP_LOG:-/var/log/xferlog}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/ftp-manager}"

if [[ -t 1 && "${NO_COLOR:-0}" != "1" ]]; then
    C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
    C_RED=$'\033[1;31m'; C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
    C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''; C_RESET=''
fi

print_rule() { printf '%s\n' "${C_BLUE}--------------------------------------------------${C_RESET}"; }
print_banner() {
    print_rule
    printf '%s%s v%s%s\n' "$C_BLUE" "$APP_NAME" "$APP_VERSION" "$C_RESET"
    printf '%sQuan tri vsftpd tren CentOS / RHEL%s\n' "$C_DIM" "$C_RESET"
    print_rule
}
section() { printf '\n%s== %s ==%s\n' "$C_BLUE" "$1" "$C_RESET"; }
info() { printf '%s[INFO]%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
success() { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
error() { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
clear_screen() { [[ -t 1 ]] && clear || true; }
pause_screen() { [[ -t 0 ]] && read -r -p "Nhan Enter de tiep tuc..." _ || true; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
require_command() { command_exists "$1" || { error "Thieu lenh '$1'."; return 1; }; }
as_root() { if (( EUID == 0 )); then "$@"; else sudo "$@"; fi; }
confirm() { local answer; read -r -p "$1 [y/N]: " answer; [[ "$answer" =~ ^[Yy]$ ]]; }
valid_username() { [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; }
valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }
valid_passive_range() { valid_port "$1" && valid_port "$2" && (( 10#$1 < 10#$2 )); }

service_is_active() { systemctl is-active --quiet "$FTP_SERVICE" 2>/dev/null; }
config_value() {
    local key="$1"
    [[ -r "$FTP_CONFIG" ]] || return 1
    awk -F= -v key="$key" '$1 == key { value=$2 } END { print value }' "$FTP_CONFIG"
}
backup_config_file() {
    [[ -f "$FTP_CONFIG" ]] || { error "Khong tim thay $FTP_CONFIG"; return 1; }
    local destination="${FTP_CONFIG}.bak.$(date +%Y%m%d-%H%M%S)"
    as_root cp -a "$FTP_CONFIG" "$destination" || return 1
    info "Da tao ban sao: $destination"
}
set_config_value() {
    local key="$1" value="$2" temporary
    [[ "$key" =~ ^[a-z_]+$ && "$value" =~ ^[A-Za-z0-9_./:-]+$ ]] || { error "Gia tri cau hinh khong hop le."; return 1; }
    [[ -f "$FTP_CONFIG" ]] || { error "Khong tim thay $FTP_CONFIG"; return 1; }
    backup_config_file || return 1
    temporary=$(mktemp) || return 1
    awk -v key="$key" -v value="$value" '
        BEGIN { changed=0 }
        $0 ~ "^[#[:space:]]*" key "=" { print key "=" value; changed=1; next }
        { print }
        END { if (!changed) print key "=" value }
    ' "$FTP_CONFIG" > "$temporary" || { rm -f "$temporary"; return 1; }
    as_root cp "$temporary" "$FTP_CONFIG" || { rm -f "$temporary"; return 1; }
    rm -f "$temporary"
    success "Da dat ${key}=${value}. Restart dich vu de ap dung."
}

run_submenu() {
    local title="$1" renderer="$2" handler="$3" choice
    while true; do
        clear_screen; print_banner; section "$title"; "$renderer"
        print_rule; read -r -p "Lua chon: " choice
        [[ "$choice" == "0" ]] && return 0
        "$handler" "$choice"
        pause_screen
    done
}
