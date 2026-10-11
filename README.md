# FTP Manager for CentOS

Công cụ Bash dạng menu để cài đặt, cấu hình, phân quyền, truyền file, giám sát và sao
lưu FTP Server `vsftpd` trên CentOS/RHEL, Rocky Linux và AlmaLinux.

## Nhóm chức năng

| Nhóm | Công cụ chính |
|---|---|
| Dịch vụ | Cài `vsftpd`, start/stop/restart, enable, status |
| Người dùng | Tạo/xóa user, password, khóa/mở khóa, FTP home |
| Quyền truy cập | Local read-only/read-write, anonymous read-only/upload |
| Cấu hình FTP | Upload, chroot, passive ports, control port, FTPS |
| Bảo mật | Firewalld, SELinux, danh sách user bị chặn |
| Giám sát | Socket, connection, journal, transfer log, disk usage |
| Truyền file | List, upload, download, mirror, mkdir, rename, delete, test quyền |
| DNS BIND | Cài BIND, tạo zone/FTP record, firewall, validation, lookup |
| Backup | Backup/restore config và backup dữ liệu FTP user |
| Chẩn đoán | Health check, config audit, localhost test, permission check |

## Chạy nhanh

```bash
chmod +x ftp_manager.sh tests/smoke_test.sh
bash tests/smoke_test.sh
sudo ./ftp_manager.sh
```

Các thao tác chỉ đọc có thể chạy bằng user thường. Các thao tác thay đổi package,
service, user, `/etc`, firewall hoặc `/var` sẽ dùng `sudo` qua helper `as_root`.

## Cấu trúc

```text
ftp-manager/
├── ftp_manager.sh
├── lib/core.sh
├── modules/
│   ├── service.sh
│   ├── users.sh
│   ├── access.sh
│   ├── configuration.sh
│   ├── security.sh
│   ├── monitoring.sh
│   ├── transfer.sh
│   ├── dns.sh
│   ├── backup.sh
│   └── diagnostics.sh
├── docs/
│   ├── ARCHITECTURE.md
│   └── features/
└── tests/
```

Hướng dẫn demo đầy đủ nằm tại [GUIDELINE.md](GUIDELINE.md); tài liệu từng nhóm nằm
tại [docs/README.md](docs/README.md).

## Nguyên tắc an toàn

- Password FTP không được lưu lâu dài và không xuất hiện trong tham số tiến trình.
- Mỗi thao tác sửa config tạo file `.bak.<timestamp>` trước khi ghi.
- Anonymous upload tạo vùng riêng và file upload mặc định không cho anonymous đọc lại.
- DNS chỉ cho localhost và CIDR LAN được chọn truy vấn, thay vì mở resolver cho tất cả.
- Xóa user, file remote, restore và thay đổi quyền đệ quy đều yêu cầu xác nhận.

> Plain FTP truyền thông tin xác thực không mã hóa. Chỉ dùng trong lab hoặc bật FTPS
> với certificate đáng tin cậy khi triển khai thực tế.
