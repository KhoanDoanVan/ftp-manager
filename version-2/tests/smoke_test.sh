#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$project_dir/ftp_server_manager.sh"

bash -n "$script"

for required_text in \
    "1) Cong cu co ban" \
    "2) Cong cu mo rong" \
    "3) Thoat" \
    "1) Cai dat FTP Server" \
    "2) Bat/tat FTP Server" \
    "3) Them FTP share" \
    "4) Xoa FTP share" \
    "5) Kiem tra FTP Server"; do
    grep -Fq "$required_text" "$script"
done

grep -Fq '../ftp_manager.sh' "$script"
grep -Fq "FileZilla" "$project_dir/docs/FILEZILLA_DEMO.md"
grep -Fq "/etc/ftp-manager-v2/shares.tsv" "$project_dir/README.md"
grep -Fq "Anonymous" "$project_dir/GUIDELINE.md"
grep -Fq "Local FTP user" "$project_dir/GUIDELINE.md"
grep -Fq "Locked/invalid user" "$project_dir/GUIDELINE.md"
grep -Fq "set_vsftpd_value reverse_lookup_enable NO" "$script"
grep -Fq "192.168.65.129" "$project_dir/GUIDELINE.md"

printf 'Version 2 smoke tests: PASS\n'
