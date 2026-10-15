# Kiểm thử máy B bằng FileZilla

Script chỉ chạy trên máy A. Máy B dùng FileZilla để chứng minh FTP Server hoạt
động bằng giao diện, không cần `lftp`, `curl` hay menu truyền file terminal.

## 1. Chuẩn bị mạng

Trên máy A, lấy IP private:

```bash
ip -4 -br address show enp26s0
```

Trong mô hình hiện tại, máy A là `192.168.10.2`. Máy B phải truy cập được IP này.
Nếu dùng domain, `ftp.sgu.edu.vn` phải phân giải về cùng IP.

## 2. Kết nối anonymous

Trong FileZilla Site Manager:

```text
Protocol   : FTP - File Transfer Protocol
Host       : ftp.sgu.edu.vn (hoặc 192.168.10.2)
Port       : 21
Encryption : Only use plain FTP (insecure)
Logon Type : Anonymous
```

Sau khi máy A tạo anonymous share tên `public`, truy cập `/public`.

Kết quả cần chứng minh:

- List và download được.
- Upload bị từ chối vì anonymous được cấu hình read-only.

## 3. Kết nối local user

Trong FileZilla Site Manager:

```text
Protocol   : FTP - File Transfer Protocol
Host       : ftp.sgu.edu.vn (hoặc 192.168.10.2)
Port       : 21
Encryption : Only use plain FTP (insecure)
Logon Type : Normal
User       : <user đã chọn trên máy A>
Password   : <password Linux của user>
```

Nếu máy A tạo share `documents` cho `itadmin`, truy cập `/ftp/documents`.

Kết quả cần chứng minh:

- List thư mục được.
- Upload một file được.
- Download file vừa upload được.
- Đổi tên và xóa file được.

## 4. Trình tự demo ngắn

1. Máy A: chọn `1` để cài FTP.
2. Máy A: chọn `2` để xem trạng thái hoặc bật/tắt service.
3. Máy A: chọn `3`, tạo một anonymous share.
4. Máy B: dùng FileZilla kiểm tra anonymous chỉ đọc.
5. Máy A: chọn `3`, tạo một local-user share.
6. Máy B: dùng FileZilla kiểm tra user đọc/ghi.
7. Máy A: chọn `5` để kiểm tra server và permission.
8. Máy A: chọn `4` để gỡ share demo; dữ liệu được đưa vào backup.

## 5. Lỗi thường gặp

### `Name or service not known`

Thử kết nối bằng `192.168.10.2`. Nếu IP hoạt động nhưng domain không hoạt động,
thêm trên máy B:

```text
192.168.10.2  ftp.sgu.edu.vn
```

### Connection timed out

Kiểm tra máy A bằng menu `5`, đặc biệt port 21, firewalld và dải passive
`30000-31000/tcp`. Đồng thời kiểm tra card VMware Private to My Mac.

### `530 Login incorrect`

Kiểm tra username/password, trạng thái khóa của Linux account và danh sách
`/etc/vsftpd/user_list`.

### List được nhưng upload bị từ chối

Với anonymous, đây là kết quả đúng. Với local user, chạy menu `5` trên máy A và
kiểm tra dòng `WRITE(user): YES`.
