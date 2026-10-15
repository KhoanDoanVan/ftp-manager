# FTP Manager - Phương án 2

Phiên bản này chỉ tập trung vào công việc quản trị trên **máy A (FTP Server)**.
Toàn bộ phiên bản đầy đủ ở thư mục gốc vẫn được giữ nguyên.

## Tư duy của phương án 2

Thay vì chia thành nhiều module kỹ thuật, bản này xem mỗi thư mục được công bố là
một **điểm chia sẻ FTP**. Quản trị viên tạo điểm chia sẻ, chọn đối tượng truy cập,
kiểm tra và có thể gỡ điểm chia sẻ đó.

Menu cấp cao chỉ có ba lựa chọn:

```text
1) Cong cu co ban
2) Cong cu mo rong
3) Thoat
```

Nhóm **Công cụ cơ bản** giữ đúng năm chức năng bắt buộc:

1. Cài đặt và cấu hình FTP Server.
2. Bật, tắt, restart và xem trạng thái FTP.
3. Thêm điểm chia sẻ: tạo thư mục rồi chọn anonymous hoặc local user.
4. Xóa điểm chia sẻ do tool quản lý.
5. Kiểm tra service, port, firewall, SELinux và permission.

Nhóm **Công cụ mở rộng** mở toàn bộ tool của version 1:

- Quản lý service và user chi tiết.
- Phân quyền FTP.
- Chỉnh cấu hình, TLS, firewall và SELinux.
- Giám sát, log và chẩn đoán.
- Truyền file terminal.
- DNS BIND.
- Backup và restore.

Version 1 được chạy trong một tiến trình riêng nên không xung đột hàm hoặc cấu
hình với năm tool cơ bản. Khi chọn `0` trong menu mở rộng, chương trình quay lại
menu cấp cao của version 2.

Máy B không cần chạy script. Việc truy cập, list, download và upload được kiểm thử
bằng giao diện FileZilla theo [FILEZILLA_DEMO.md](docs/FILEZILLA_DEMO.md).
Kịch bản cấu hình và trình bày đầy đủ nằm trong [GUIDELINE.md](GUIDELINE.md).

## Chạy trên máy A

```bash
cd ~/ftp-manager/version-2
chmod +x ftp_server_manager.sh
sudo ./ftp_server_manager.sh
```

Phải giữ nguyên cấu trúc repo vì nhóm mở rộng gọi `../ftp_manager.sh` và các
module của version 1. Không chỉ copy riêng thư mục `version-2` sang máy A.

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
