#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NO_COLOR=1
source "$ROOT_DIR/lib/core.sh"

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
