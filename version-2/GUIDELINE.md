# Guideline 2 - Quản lý FTP trên máy A, kiểm thử FileZilla trên máy B

Tài liệu này dành riêng cho `version-2`. Trọng tâm demo là năm chức năng quản trị
FTP Server trên máy A. Máy B chỉ dùng giao diện FileZilla để xác nhận kết quả với
nhiều vai trò truy cập khác nhau.

## 1. Mô hình demo

```text
Máy A - CentOS FTP Server
  enp2s0  : DHCP, Share with My Mac, dùng ra Internet
  enp26s0 : 192.168.10.2/24, Private to My Mac, phục vụ FTP
  Domain  : ftp.sgu.edu.vn -> 192.168.10.2

Máy B - FTP Client
  Cùng mạng private với máy A
  Dùng FileZilla để list, upload và download
```

Card private `enp26s0` không được có default gateway. Default route phải đi qua
card NAT `enp2s0`.

Kiểm tra trên máy A:

```bash
ip -4 -br address
ip route
```

Kết quả quan trọng:

```text
enp26s0  UP  192.168.10.2/24
default via 192.168.65.2 dev enp2s0
```

Nếu xuất hiện default route qua `enp26s0`, sửa theo tài liệu setup của project
trước khi demo.

## 2. Các vai trò trong bài demo

| Vai trò | Đăng nhập FileZilla | Phạm vi | List/download | Upload/delete |
|---|---|---|---|---|
| Server administrator | Không dùng FTP root | Toàn hệ thống qua `sudo` | Quản trị | Quản trị |
| Anonymous | Anonymous | `/var/ftp` | Có | Không |
| Local FTP user | Username/password | Home đã chroot | Có | Có trong share của mình |
| Local user khác | Username/password riêng | Home riêng | Có trong home riêng | Không thấy share user khác |
| Locked/invalid user | Bị từ chối | Không có | Không | Không |

Không đăng nhập FTP bằng `root`. Tài khoản quản trị chỉ chạy script trên máy A.

## 3. Chuẩn bị project trên máy A

```bash
cd ~/ftp-manager/version-2
chmod +x ftp_server_manager.sh tests/smoke_test.sh
bash tests/smoke_test.sh
sudo ./ftp_server_manager.sh
```

Kết quả smoke test:

```text
Version 2 smoke tests: PASS
```

## 4. Chức năng 1 - Cài FTP Server

Trong menu chính, chọn:

```text
1) Cai dat FTP Server
```

Tool sẽ:

1. Cài package `vsftpd`.
2. Tạo bản sao cấu hình ban đầu.
3. Bật local user, chroot và passive mode.
4. Giữ anonymous ở trạng thái tắt cho đến khi có anonymous share.
5. Mở service FTP và dải passive `30000-31000/tcp` trên firewalld.
6. Bật SELinux boolean cần cho bài lab ghi dữ liệu FTP.
7. Enable và start `vsftpd`.

Không cần chạy lại mục này trong phần demo nếu FTP đã được cài sẵn. Có thể giới
thiệu chức năng rồi chuyển sang phần trạng thái.

## 5. Chức năng 2 - Bật và tắt FTP

Chọn:

```text
2) Bat/tat FTP Server
```

Các thao tác con:

```text
1) Bat FTP
2) Tat FTP
3) Restart FTP
4) Xem trang thai
```

Kịch bản trình bày an toàn:

1. Chọn `4` để chứng minh service đang chạy.
2. Chọn `2` để dừng FTP.
3. Trên máy B, FileZilla kết nối lại và phải thất bại.
4. Chọn `1` để bật FTP.
5. Trên máy B, FileZilla kết nối lại và phải thành công.

## 6. Chức năng 3 - Thêm anonymous FTP share

Trên máy A chọn:

```text
3) Them FTP share
Ten thu muc/share: public
Doi tuong truy cap: 1
```

Tool tạo:

```text
/var/ftp/public
```

Anonymous chỉ có quyền đọc. Chuẩn bị một file để máy B download:

```bash
echo "Anonymous FTP demo" | sudo tee /var/ftp/public/readme.txt
sudo chmod 644 /var/ftp/public/readme.txt
```

### Kết nối từ máy B bằng FileZilla

Mở **File > Site Manager > New site** và nhập:

```text
Protocol   : FTP - File Transfer Protocol
Host       : ftp.sgu.edu.vn
Port       : 21
Encryption : Only use plain FTP (insecure)
Logon Type : Anonymous
```

Nếu domain chưa hoạt động, tạm dùng host `192.168.10.2`.

Sau khi kết nối, mở remote path:

```text
/public
```

Kiểm thử role anonymous:

1. Thấy `readme.txt`.
2. Download `readme.txt` thành công.
3. Thử upload một file và nhận lỗi permission denied.

Đây là kết quả đúng: anonymous có thể đọc nhưng không thể sửa dữ liệu server.

## 7. Chức năng 3 - Thêm local-user FTP share

Trên máy A chọn lại:

```text
3) Them FTP share
Ten thu muc/share: documents
Doi tuong truy cap: 2
Linux/FTP username: itadmin
```

Nếu `itadmin` chưa tồn tại, tool hỏi xác nhận tạo user và yêu cầu đặt password.
Tool tạo:

```text
/home/itadmin/ftp/documents
```

Quyền dự kiến:

```text
/home/itadmin/ftp            root:root, 755
/home/itadmin/ftp/documents  itadmin:itadmin, 700
```

### Kết nối từ máy B bằng FileZilla

Tạo site thứ hai:

```text
Protocol   : FTP - File Transfer Protocol
Host       : ftp.sgu.edu.vn
Port       : 21
Encryption : Only use plain FTP (insecure)
Logon Type : Normal
User       : itadmin
Password   : password đã đặt trên máy A
```

Remote path:

```text
/ftp/documents
```

Kiểm thử role local user:

1. Upload một file từ máy B.
2. Download lại file đó.
3. Đổi tên file.
4. Xóa file.
5. Tạo một thư mục con.

Tất cả thao tác trên phải thành công trong `/ftp/documents`.

## 8. Chứng minh các local user bị cô lập

Tạo thêm share cho user thứ hai trên máy A:

```text
3) Them FTP share
Ten thu muc/share: student-data
Doi tuong truy cap: 2
Linux/FTP username: student01
```

Trên máy B, tạo thêm một FileZilla site dùng `student01`. User này nhìn thấy:

```text
/ftp/student-data
```

User `student01` không nhìn thấy `/home/itadmin` vì `chroot_local_user=YES` giữ
mỗi local user trong home riêng. Nếu cùng nhập `/ftp/documents`, đó là đường dẫn
bên trong home của `student01`, không phải share của `itadmin`.

Đây là điểm cần nhấn mạnh khi giảng viên hỏi về nhiều role: hai user đều là local
FTP user nhưng dữ liệu và phạm vi truy cập được tách biệt.

## 9. Chứng minh user không hợp lệ hoặc bị khóa

### Sai password

Trên FileZilla, nhập đúng username nhưng password sai. Kết quả mong đợi:

```text
530 Login incorrect
```

### Khóa tạm một local user

Trên máy A:

```bash
sudo usermod -L student01
sudo passwd -S student01
```

Trạng thái phải bắt đầu bằng `L`. Kết nối lại bằng FileZilla phải bị từ chối.

Sau khi demo, mở khóa:

```bash
sudo usermod -U student01
sudo passwd -S student01
```

Trạng thái có password phải là `P`. Nếu vẫn là `L`, đặt lại password:

```bash
sudo passwd student01
```

## 10. Chức năng 5 - Kiểm tra FTP Server

Trên máy A chọn:

```text
5) Kiem tra FTP Server
```

Tool kiểm tra:

- Package `vsftpd` đã cài.
- Service đang chạy và được enable.
- TCP port 21 đang listen.
- Firewalld cho phép FTP và passive ports.
- Trạng thái SELinux.
- Danh sách share do tool quản lý.
- Owner, group và mode của từng thư mục.
- Quyền đọc/ghi hiệu lực của local user.

Với `documents`, kết quả cần có:

```text
READ(itadmin): YES
WRITE(itadmin): YES
```

Anonymous không có dòng `WRITE: YES`; quyền của role này được chứng minh trực tiếp
bằng thao tác upload thất bại trên FileZilla.

## 11. Chức năng 4 - Xóa FTP share

Trên máy A chọn:

```text
4) Xoa FTP share
```

Tool hiển thị danh sách có số thứ tự. Chọn share demo và xác nhận. Tool sẽ:

1. Gỡ share khỏi registry.
2. Chuyển dữ liệu vào `/var/backups/ftp-manager-v2/`.
3. Không xóa Linux user.
4. Tắt anonymous login nếu không còn anonymous share.
5. Restart `vsftpd` để áp dụng.

Sau đó refresh FileZilla. Đường dẫn share cũ không còn truy cập được.

## 12. Làm cho máy B phân giải được domain

Trước tiên thử IP trực tiếp trong FileZilla:

```text
192.168.10.2
```

Nếu IP kết nối được nhưng `ftp.sgu.edu.vn` không kết nối được, thêm ánh xạ hosts
trên máy B.

### Máy B là macOS hoặc Linux

Mở file:

```bash
sudo vi /etc/hosts
```

Thêm **bên trong file**, không nhập dòng này như một command:

```text
192.168.10.2  ftp.sgu.edu.vn
```

Kiểm tra:

```bash
getent hosts ftp.sgu.edu.vn 2>/dev/null || ping -c 1 ftp.sgu.edu.vn
```

### Máy B là Windows

Mở Notepad bằng quyền Administrator rồi sửa:

```text
C:\Windows\System32\drivers\etc\hosts
```

Thêm:

```text
192.168.10.2  ftp.sgu.edu.vn
```

Sau đó chạy trong Command Prompt:

```bat
ipconfig /flushdns
ping ftp.sgu.edu.vn
```

## 13. Kiểm tra kết nối mạng từ máy B

Nếu FileZilla báo timeout, kiểm tra theo thứ tự:

1. Máy A vẫn có `192.168.10.2/24` trên `enp26s0`.
2. Máy A và máy B nằm trên cùng VMware private network.
3. `vsftpd` đang active.
4. Port 21 và `30000-31000/tcp` đã mở đúng firewalld zone.
5. FileZilla sử dụng Passive mode.

Trên macOS/Linux B:

```bash
ping -c 2 192.168.10.2
nc -vz 192.168.10.2 21
```

Ping có thể bị firewall chặn; kiểm tra port 21 mới là phép thử FTP quan trọng.

Trong FileZilla chọn:

```text
Settings > FTP > Passive mode
```

## 14. Kịch bản demo hoàn chỉnh

1. Giới thiệu mô hình hai máy và năm menu bắt buộc.
2. Máy A: xem trạng thái FTP bằng menu `2`.
3. Máy A: tạo anonymous share `public`.
4. Máy B: anonymous list/download được, upload bị từ chối.
5. Máy A: tạo share `documents` cho `itadmin`.
6. Máy B: `itadmin` upload, download, rename và delete được.
7. Máy A: tạo share riêng cho `student01`.
8. Máy B: chứng minh `student01` không nhìn thấy dữ liệu của `itadmin`.
9. Máy A: chạy menu `5`, chỉ ra service, port và permission.
10. Máy A: dùng menu `4` gỡ một share; máy B refresh và không còn truy cập được.

Thông điệp kết luận:

> Máy A chịu trách nhiệm cài đặt, vận hành, cấp phát, thu hồi và kiểm tra FTP.
> Máy B chỉ đóng vai trò client FileZilla để xác nhận quyền thực tế của từng role.
