# Nhóm truyền file bằng terminal

Module: `modules/transfer.sh`. Dependency: `lftp`.

## Chức năng

- Cấu hình host, port, username và chế độ TLS trong phiên hiện tại.
- List remote, upload/download một file.
- Mirror thư mục local lên remote hoặc remote về local bằng `--only-newer`.
- Tạo thư mục, đổi tên và xóa file remote.
- Test riêng quyền list/read và write/delete.

Password được hỏi lại cho mỗi thao tác, ghi tạm vào command file mode `600` và xóa
ngay sau khi `lftp` kết thúc. Profile không lưu password và biến profile cũng không
được ghi ra disk.

Ba chế độ TLS:

- `off`: plain FTP, chỉ phù hợp lab.
- `strict`: bắt buộc TLS và xác minh certificate.
- `self-signed-lab`: bắt buộc TLS nhưng bỏ xác minh; không dùng production.

Các lệnh mirror không có `--delete`, vì vậy file chỉ có ở đích sẽ không bị xóa.
