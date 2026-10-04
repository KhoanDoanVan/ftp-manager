# FTP Manager for CentOS

Cong cu Bash dang menu dung de cai dat, cau hinh, bao mat, giam sat va sao luu
FTP Server `vsftpd` tren CentOS/RHEL (cung phu hop Rocky Linux va AlmaLinux).

## Chuc nang

| Nhom | Cong cu chinh |
|---|---|
| Dich vu | Cai dat, start/stop/restart, enable, status, version |
| Nguoi dung | Tao/xoa, doi mat khau, khoa/mo khoa, xem FTP home |
| Cau hinh | Upload, anonymous, chroot, passive ports, control port, FTPS |
| Bao mat | firewalld, SELinux, danh sach chan dang nhap |
| Giam sat | IP, port, connection, journal, transfer log, disk usage |
| Backup | Backup/restore config, backup du lieu user, kiem tra archive |
| Chan doan | Health check, config audit, localhost test, permission check |

## Chay nhanh

```bash
chmod +x ftp_manager.sh
sudo ./ftp_manager.sh
```

Nen chay tren may ao CentOS dung cho bai lab. Mot so menu chi doc thong tin khong can
root; cac menu thay doi he thong se tu goi `sudo` khi can.

## Cau truc project

```text
ftp-manager/
├── ftp_manager.sh          # Entry point va menu chinh
├── lib/core.sh             # UI, validation, helpers dung chung
├── modules/                # Mot file cho moi nhom tinh nang
├── docs/
│   ├── ARCHITECTURE.md
│   └── features/            # Tai lieu theo nhom tinh nang
└── tests/smoke_test.sh      # Syntax + validation smoke tests
```

Tai lieu bat dau tai [docs/README.md](docs/README.md). Huong dan demo tren lop tai
[GUIDELINE.md](GUIDELINE.md).

## Kiem tra source

```bash
bash tests/smoke_test.sh
```

> FTP truyen password dang plain text. Neu dung ngoai bai lab, hay bat FTPS va dung
> chung chi do CA cap thay cho chung chi tu ky.
