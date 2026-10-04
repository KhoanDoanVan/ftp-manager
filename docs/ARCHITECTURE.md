# Kien truc

```text
ftp_manager.sh
      |
      +-- lib/core.sh (UI, sudo, validation, config helpers)
      |
      +-- modules/service.sh
      +-- modules/users.sh
      +-- modules/configuration.sh
      +-- modules/security.sh
      +-- modules/monitoring.sh
      +-- modules/backup.sh
      `-- modules/diagnostics.sh
               |
               +--> vsftpd / systemd / firewalld / SELinux / journal
```

## Nguyen tac tach module

- `ftp_manager.sh` chi dieu huong menu, khong chua logic nghiep vu.
- `lib/core.sh` chua bien moi truong va ham dung chung.
- Moi file trong `modules/` so huu mot submenu va mot nhom nghiep vu.
- Thao tac chi doc chay voi quyen hien tai; thao tac he thong di qua `as_root`.
- Moi thay doi `vsftpd.conf` tao file `.bak.YYYYmmdd-HHMMSS` truoc.
- Input username, port va gia tri config duoc validate truoc khi dua vao command.

## Them mot tool moi

1. Dat ham nghiep vu vao module gan nhat (hoac tao module moi).
2. Them dong vao ham `*_menu_items`.
3. Anh xa option trong `handle_*_choice`.
4. Neu tao module moi, `source` file tu entry point va them menu chinh.
5. Them test validation/syntax va cap nhat tai lieu trong `docs/features/`.

## Bien co the override

`FTP_SERVICE`, `FTP_CONFIG`, `FTP_USER_LIST`, `FTP_LOG`, `BACKUP_DIR`, `NO_COLOR`.
Override giup test tren file tam ma khong cham vao `/etc`.
