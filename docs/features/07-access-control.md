# Nhóm quyền truy cập theo vai trò

Module: `modules/access.sh`.

## Vai trò

| Vai trò | Quyền |
|---|---|
| Admin `root`/`sudo` | Quản trị package, service, user, config và firewall |
| Local read-only | Đăng nhập và download, không sửa FTP home |
| Local read-write | Đọc/ghi trong `ftp/upload`, không ghi vào gốc chroot |
| Anonymous read-only | Đọc file công khai trong `/var/ftp/pub` |
| Anonymous upload | Upload vào `/var/ftp/upload`; file mode 600 không đọc lại |
| Locked/blocked | Không đăng nhập được |

Không dùng tài khoản root để đăng nhập FTP. Quyền quản trị hệ thống và quyền truyền
file là hai lớp riêng.

Chế độ read-only đổi owner toàn bộ FTP home thành `root:root`; chế độ read-write trả
owner của cây `upload` về local user. Cả hai là thay đổi đệ quy nên tool yêu cầu xác
nhận ở thao tác thu hồi quyền ghi.

Anonymous upload chỉ phù hợp bài lab hoặc hộp nhận file được kiểm soát. Tool đặt
`anon_umask=077` và `anon_world_readable_only=YES` để người anonymous khác không tải
lại file vừa gửi.
