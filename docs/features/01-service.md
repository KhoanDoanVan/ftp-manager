# Nhom dich vu va cai dat

Module: `modules/service.sh`.

## Cong cu

- Cai `vsftpd` bang `dnf` (fallback `yum`).
- Enable/start dich vu va mo FTP service tren firewalld neu firewall dang chay.
- Start, stop, restart, enable, xem status va package version.

## Demo

Chon `1 > 1` de cai dat, sau do `1 > 6` de chung minh dich vu `active (running)`.
Co the doi chieu bang `systemctl is-active vsftpd` va `rpm -q vsftpd`.
