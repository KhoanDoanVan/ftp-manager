# Nhom cau hinh FTP/FTPS

Module: `modules/configuration.sh`.

## Cong cu

- Xem cac dong cau hinh co hieu luc.
- Bat/tat upload va anonymous login; bat chroot local user.
- Dat control port va passive port range.
- Tao RSA certificate tu ky, bat TLS cho login va data.
- Mo editor va restart dich vu.

Moi lan tool sua mot key, config hien tai duoc copy thanh
`/etc/vsftpd/vsftpd.conf.bak.<timestamp>`. Passive range con phai duoc mo trong
firewall. Chung chi tu ky chi phu hop demo; production can certificate hop le.
