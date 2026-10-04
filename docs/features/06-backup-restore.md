# Nhom sao luu va khoi phuc

Module: `modules/backup.sh`.

## Config backup

Archive `config-<timestamp>.tar.gz` gom `vsftpd.conf`, `user_list` neu co va metadata.
Mac dinh luu tai `/var/backups/ftp-manager`. Restore kiem tra archive, xac nhan,
backup config hien tai, cai file va restart dich vu.

## Data backup

Archive `data-<timestamp>.tar.gz` gom cac thu muc `/home/*/ftp`. Dung `Kiem tra noi
dung archive` de xem toi da 100 dong dau truoc khi phuc hoi thu cong.

Tool co tinh khong tu dong restore user data vi viec ghi de du lieu la thao tac rui ro
cao; quan tri vien can xem archive va chon du lieu can phuc hoi.
