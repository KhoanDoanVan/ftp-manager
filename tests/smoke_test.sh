#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NO_COLOR=1
source "$ROOT_DIR/lib/core.sh"
source "$ROOT_DIR/modules/transfer.sh"

failures=0
assert_true() { "$@" || { printf 'FAIL: %s\n' "$*"; failures=$((failures + 1)); }; }
assert_false() { if "$@"; then printf 'FAIL (expected false): %s\n' "$*"; failures=$((failures + 1)); fi; }

assert_true valid_username ftp_user-1
assert_false valid_username 'Bad User'
assert_false valid_username 'UPPER'
assert_true valid_port 21
assert_true valid_port 65535
assert_false valid_port 0
assert_false valid_port 70000
assert_true valid_passive_range 30000 31000
assert_false valid_passive_range 31000 30000
assert_true valid_hostname ftp.sgu.edu.vn
assert_false valid_hostname 'ftp server.local'
assert_true valid_ipv4 192.168.1.120
assert_false valid_ipv4 192.168.1.999
assert_true valid_ipv4_cidr 192.168.1.0/24
assert_false valid_ipv4_cidr 192.168.1.0/99
[[ "$(lftp_quote 'folder/demo file.txt')" == '"folder/demo file.txt"' ]] || {
    printf 'FAIL: lftp_quote\n'; failures=$((failures + 1))
}
assert_false lftp_quote $'bad\ncommand'

# Exercise generation of a protected lftp command file without a network call.
lftp() {
    [[ "$1" == -f && -r "$2" ]] || return 1
    [[ "$(stat -c '%a' "$2" 2>/dev/null || stat -f '%Lp' "$2")" == 600 ]] || return 1
    grep -Fq 'open -p 21 -u "ftp_demo","test-password" "127.0.0.1"' "$2"
    grep -Fq 'cls -la "/"' "$2"
}
TRANSFER_HOST=127.0.0.1
TRANSFER_PORT=21
TRANSFER_USER=ftp_demo
TRANSFER_TLS_MODE=off
run_lftp_command 'cls -la "/"' <<< 'test-password' >/dev/null || {
    printf 'FAIL: run_lftp_command\n'; failures=$((failures + 1))
}
unset -f lftp

# Exercise config reading/writing against an isolated fixture without sudo.
TEST_TMP_DIR=$(mktemp -d)
trap 'rm -f "$TEST_TMP_DIR"/vsftpd.conf "$TEST_TMP_DIR"/vsftpd.conf.bak.*; rmdir "$TEST_TMP_DIR"' EXIT
cp "$ROOT_DIR/tests/fixtures/vsftpd.conf" "$TEST_TMP_DIR/vsftpd.conf"
FTP_CONFIG="$TEST_TMP_DIR/vsftpd.conf"
as_root() { "$@"; }
[[ "$(config_value write_enable)" == NO ]] || { printf 'FAIL: config_value\n'; failures=$((failures + 1)); }
set_config_value write_enable YES >/dev/null
[[ "$(config_value write_enable)" == YES ]] || { printf 'FAIL: set_config_value\n'; failures=$((failures + 1)); }
compgen -G "$TEST_TMP_DIR/vsftpd.conf.bak.*" >/dev/null || { printf 'FAIL: config backup\n'; failures=$((failures + 1)); }

for file in "$ROOT_DIR"/ftp_manager.sh "$ROOT_DIR"/lib/*.sh "$ROOT_DIR"/modules/*.sh; do
    bash -n "$file" || failures=$((failures + 1))
done

(( failures == 0 )) || exit 1
printf 'Smoke tests: PASS\n'
