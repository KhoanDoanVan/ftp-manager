# FTP Manager - Phương án 2

Phiên bản này chỉ tập trung vào công việc quản trị trên **máy A (FTP Server)**.
Toàn bộ phiên bản đầy đủ ở thư mục gốc vẫn được giữ nguyên.

## Tư duy của phương án 2

Thay vì chia thành nhiều module kỹ thuật, bản này xem mỗi thư mục được công bố là
một **điểm chia sẻ FTP**. Quản trị viên tạo điểm chia sẻ, chọn đối tượng truy cập,
kiểm tra và có thể gỡ điểm chia sẻ đó.

Menu chỉ có năm nhóm bắt buộc:

1. Cài đặt và cấu hình FTP Server.
2. Bật, tắt, restart và xem trạng thái FTP.
3. Thêm điểm chia sẻ: tạo thư mục rồi chọn anonymous hoặc local user.
4. Xóa điểm chia sẻ do tool quản lý.
5. Kiểm tra service, port, firewall, SELinux và permission.

Máy B không cần chạy script. Việc truy cập, list, download và upload được kiểm thử
bằng giao diện FileZilla theo [FILEZILLA_DEMO.md](docs/FILEZILLA_DEMO.md).
Kịch bản cấu hình và trình bày đầy đủ nằm trong [GUIDELINE.md](GUIDELINE.md).

## Chạy trên máy A

```bash
cd ~/ftp-manager/version-2
chmod +x ftp_server_manager.sh
sudo ./ftp_server_manager.sh
```

Tool lưu danh sách điểm chia sẻ tại:

```text
/etc/ftp-manager-v2/shares.tsv
```

## Cấu trúc điểm chia sẻ

| Kiểu truy cập | Đường dẫn trên máy A | Đường dẫn trong FileZilla | Quyền |
|---|---|---|---|
| Anonymous | `/var/ftp/<share>` | `/<share>` | Chỉ đọc |
| Local user | `/home/<user>/ftp/<share>` | `/ftp/<share>` | Đọc/ghi |

Anonymous được giữ ở chế độ chỉ đọc để tránh upload không xác thực. Local user sử
dụng password Linux và chỉ được ghi trong thư mục share của chính user.

## Ý nghĩa “Xóa FTP”

Trong tool này, “Xóa FTP” là gỡ một điểm chia sẻ đã tạo, **không uninstall
vsftpd và không xóa Linux user**. Dữ liệu không bị xóa vĩnh viễn mà được chuyển
vào `/var/backups/ftp-manager-v2/` để có thể phục hồi.

## Kiểm tra mã nguồn

```bash
bash tests/smoke_test.sh
```
