# Hướng dẫn demo chuẩn — FTP Manager v2.0

Tài liệu này bám sát chức năng hiện có của dự án `ftp-manager`, dùng để chuẩn bị và
trình bày đề tài:

> **Xây dựng Bash script tự động hóa quản trị FTP Server trên CentOS.**

## 1. Mục tiêu cần chứng minh

Sau buổi demo, cần chứng minh được các nội dung sau:

1. Script cài đặt và điều khiển dịch vụ `vsftpd`.
2. Quản trị được FTP user và tạo đúng cấu trúc thư mục chroot.
3. Thay đổi được cấu hình upload, anonymous, chroot, passive port và FTPS.
4. Đồng bộ được cấu hình FTP với `firewalld` và kiểm tra SELinux.
5. Client đăng nhập, upload và download file thành công.
6. Theo dõi được service, port, connection, log và dung lượng.
7. Chạy được health check để tìm lỗi cấu hình.
8. Sao lưu, kiểm tra và khôi phục được cấu hình.

## 2. Kiến trúc demo

```text
┌──────────────────────┐          TCP 21 + passive ports
│      FTP Client      │ ───────────────────────────────────┐
│ lftp / FileZilla     │                                    │
└──────────────────────┘                                    ▼
                                                   ┌────────────────┐
                                                   │ CentOS Server │
                                                   │                │
                                                   │ ftp_manager.sh │
                                                   │       │        │
                                   ┌───────────────┼───────┼───────┐
                                   ▼               ▼       ▼       ▼
                                vsftpd           users  firewall  logs
```

Nên dùng hai máy ảo cùng một mạng:

- **Server:** CentOS Stream/RHEL/Rocky/AlmaLinux, chạy project.
- **Client:** Linux có `lftp` hoặc máy có FileZilla.

Nếu chỉ có một máy, có thể test bằng `lftp` tới `127.0.0.1`, nhưng sẽ không chứng
minh được firewall và kết nối qua mạng rõ bằng mô hình hai máy.

## 3. Chuẩn bị trước buổi demo

### 3.1. Thông số dùng trong tài liệu

| Thông số | Giá trị mẫu |
|---|---|
| Server IP | `192.168.1.120` |
| FTP user | `ftp_demo` |
| Control port | `21` |
| Passive range | `30000-31000` |
| Thư mục upload | `/home/ftp_demo/ftp/upload` |

Thay `192.168.1.120` bằng IP thật của máy CentOS.

### 3.2. Kiểm tra hệ điều hành và mạng

Chạy trên server:

```bash
cat /etc/os-release
hostname -I
ip -brief address
ping -c 4 8.8.8.8
```

Ghi lại IP của card mạng mà client truy cập được. Từ client, thử:

```bash
ping -c 4 192.168.1.120
```

Nếu ping không thông, xử lý cấu hình NAT/Bridged/Host-only của máy ảo trước khi demo.

### 3.3. Kiểm tra source

```bash
cd ~/ftp-manager
chmod +x ftp_manager.sh tests/smoke_test.sh
bash tests/smoke_test.sh
```

Kết quả mong đợi:

```text
Smoke tests: PASS
```

Smoke test chỉ kiểm tra cú pháp Bash, validation và thao tác config trên file mẫu;
nó không cài package hay thay đổi `/etc`.

### 3.4. Khởi chạy chương trình

```bash
sudo ./ftp_manager.sh
```

Kết quả mong đợi:

```text
FTP Manager v2.0.0
Quan tri vsftpd tren CentOS / RHEL
--------------------------------------------------
  1) Dich vu & cai dat
  2) Quan ly nguoi dung
  3) Cau hinh FTP
  4) Firewall & bao mat
  5) Giam sat & nhat ky
  6) Sao luu & khoi phuc
  7) Chan doan ket noi
  8) Tong quan nhanh
  0) Thoat
```

Có thể chạy script không kèm `sudo`; các thao tác thay đổi hệ thống sẽ tự gọi `sudo`.
Chạy trực tiếp bằng `sudo` thuận tiện hơn trong lúc trình bày.

## 4. Luồng demo chính

Ký hiệu `1 → 6` nghĩa là chọn `1` ở menu chính, sau đó chọn `6` trong submenu.

### Bước 1 — Cài đặt và kiểm tra dịch vụ

1. Chọn `1 → 1` — **Cài đặt vsftpd**.
2. Script dùng `dnf` hoặc `yum`, sau đó enable và start service.
3. Nếu `firewalld` đang chạy, script tự mở service `ftp`.
4. Chọn `1 → 6` — **Xem trạng thái**.
5. Chọn `1 → 7` — **Xem phiên bản gói**.

Kết quả cần chỉ ra:

```text
Active: active (running)
```

Lệnh đối chiếu:

```bash
rpm -q vsftpd
systemctl is-enabled vsftpd
systemctl is-active vsftpd
```

Các menu `1 → 2`, `1 → 3`, `1 → 4` lần lượt minh họa start, stop và restart. Không
nên chọn stop ngay trước phần test client.

### Bước 2 — Tạo FTP user

1. Chọn `2 → 1` — **Thêm FTP user**.
2. Nhập username `ftp_demo`.
3. Nhập và xác nhận password theo prompt của `passwd`.
4. Chọn `2 → 3` để thấy user trong danh sách.
5. Chọn `2 → 7`, nhập lại `ftp_demo` để xem FTP home.

Script tạo cấu trúc:

```text
/home/ftp_demo/ftp          root:root, mode 755
/home/ftp_demo/ftp/upload   ftp_demo:ftp_demo
```

Thư mục `ftp` không cho user ghi trực tiếp để phù hợp với chroot của `vsftpd`; user
upload vào thư mục con `upload`.

Lệnh đối chiếu:

```bash
id ftp_demo
sudo ls -ld /home/ftp_demo/ftp
sudo ls -ld /home/ftp_demo/ftp/upload
```

Lưu ý:

- Username chỉ nhận chữ thường, số, `_`, `-` và tối đa 32 ký tự.
- `2 → 4` đổi password; `2 → 5` và `2 → 6` khóa/mở khóa tài khoản.
- `2 → 2` xóa cả user và home directory, chỉ demo ở cuối nếu thật sự cần.

### Bước 3 — Cấu hình FTP cơ bản

1. Chọn `3 → 1` để xem cấu hình đang có hiệu lực.
2. Chọn `3 → 2`, nhập `yes` để đặt `write_enable=YES`.
3. Chọn `3 → 3`, nhập `no` để đặt `anonymous_enable=NO`.
4. Chọn `3 → 4` để đặt `chroot_local_user=YES`.
5. Chọn `3 → 5`, nhập:
   - Port đầu: `30000`
   - Port cuối: `31000`
6. Giữ control port mặc định `21`. Chỉ dùng `3 → 6` nếu muốn demo đổi port.
7. Chọn `3 → 9` để restart và áp dụng cấu hình.

Mỗi lần sửa một key, chương trình tạo một file backup dạng:

```text
/etc/vsftpd/vsftpd.conf.bak.YYYYmmdd-HHMMSS
```

Kiểm tra lại bằng `3 → 1`. Các giá trị chính nên có:

```ini
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000
```

Nếu `local_enable=YES` chưa có, dùng `3 → 8` để mở editor, thêm dòng này, lưu file rồi
chọn `3 → 9` để restart.

### Bước 4 — Mở firewall và kiểm tra SELinux

1. Chọn `4 → 2` để mở service FTP trong `firewalld`.
2. Chọn `4 → 4` để mở passive range; nhập `30000` và `31000`.
3. Chọn `4 → 1` để xem toàn bộ rule của zone hiện tại.
4. Chọn `4 → 5` để xem trạng thái và các boolean FTP của SELinux.

Kết quả firewall mong đợi có:

```text
services: ... ftp ...
ports: ... 30000-31000/tcp ...
```

Lệnh đối chiếu:

```bash
sudo firewall-cmd --query-service=ftp
sudo firewall-cmd --query-port=30000-31000/tcp
getenforce
```

Chỉ dùng `4 → 6` khi SELinux thực sự chặn upload trong bài lab. Tùy chọn này bật
`ftpd_full_access`, là quyền rộng và không phải lựa chọn ưu tiên cho production.

Không chọn `4 → 3` trong luồng demo chính vì chức năng đó đóng FTP trên firewall.

### Bước 5 — Chạy health check trước khi kết nối

Chọn `7 → 1` — **Chạy health check đầy đủ**.

Tool kiểm tra sáu nhóm:

1. Các command cần thiết và package `vsftpd`.
2. Trạng thái service.
3. Các key cấu hình quan trọng.
4. Control port đang LISTEN.
5. Rule FTP của firewall.
6. Dung lượng filesystem.

Kết quả quan trọng phải đạt:

- `vsftpd active`.
- Control port `21` đang LISTEN.
- Firewall cho phép FTP.
- Filesystem còn đủ dung lượng.

`anonymous_enable=NO` là cấu hình bảo mật đúng, không phải lỗi. Menu hiển thị là
“Kiểm tra port 21”, nhưng code sẽ dùng `listen_port` trong config nếu đã đổi port.

### Bước 6 — Test FTP từ client

Tạo file thử trên client:

```bash
echo "FTP Manager demo" > demo.txt
```

Nếu chưa bật TLS, kết nối bằng:

```bash
lftp -u ftp_demo 192.168.1.120
```

Trong prompt của `lftp`, chạy:

```text
pwd
ls
cd ftp/upload
put demo.txt
ls
get demo.txt -o downloaded.txt
bye
```

Kiểm tra file tải về:

```bash
cat downloaded.txt
```

Kết quả mong đợi là nội dung `FTP Manager demo`. Trên server có thể đối chiếu:

```bash
sudo ls -lah /home/ftp_demo/ftp/upload
```

Nếu dùng FileZilla:

- Protocol: FTP.
- Host: IP server.
- Port: `21`.
- Logon Type: Normal.
- User: `ftp_demo`.
- Transfer Mode: Passive.

### Bước 7 — Theo dõi trong khi client đang kết nối

Giữ một client đang mở rồi dùng terminal khác chạy tool:

1. Chọn `5 → 1` để xem tổng quan.
2. Chọn `5 → 3` để xem port đang LISTEN.
3. Chọn `5 → 4` để xem connection hiện tại.
4. Chọn `5 → 5` để xem 50 dòng systemd journal.
5. Chọn `5 → 7` để xem dung lượng các FTP home.

`5 → 8` theo dõi journal trực tiếp; nhấn `Ctrl+C` để dừng rồi quay lại menu.

`5 → 6` đọc `/var/log/xferlog`. File này chỉ có khi `vsftpd` được cấu hình ghi
transfer log. Nếu hiện cảnh báo “Không tìm thấy”, journal ở `5 → 5` vẫn là nguồn log
chính và đây không phải lỗi của menu.

### Bước 8 — Sao lưu cấu hình

1. Chọn `6 → 1` để tạo config backup.
2. Chọn `6 → 2` để liệt kê archive.
3. Copy đường dẫn `config-<timestamp>.tar.gz` vừa tạo.
4. Chọn `6 → 5`, nhập đường dẫn đó để xem nội dung archive.

Archive mặc định nằm tại:

```text
/var/backups/ftp-manager/config-YYYYmmdd-HHMMSS.tar.gz
```

Nội dung gồm:

- `vsftpd.conf`.
- `user_list` nếu file tồn tại.
- `metadata` gồm thời gian, hostname và phiên bản tool.

`6 → 4` tạo archive dữ liệu từ các thư mục `/home/*/ftp`. Tool hiện chỉ backup dữ
liệu user, không tự restore dữ liệu để tránh ghi đè ngoài ý muốn.

### Bước 9 — Demo khôi phục cấu hình (tùy chọn)

Chỉ thực hiện nếu đã kiểm tra đúng archive ở bước trước:

1. Chọn `6 → 3`.
2. Nhập đường dẫn tuyệt đối tới `config-*.tar.gz`.
3. Khi được hỏi ghi đè và restart, nhập `y`.

Trước khi ghi đè, tool tự tạo `.bak` cho config hiện tại. Sau khi cài lại file, tool
restart `vsftpd`.

Kết quả mong đợi:

```text
[OK] systemctl restart vsftpd thanh cong.
[OK] Khoi phuc thanh cong.
```

Sau restore, chạy lại `7 → 1` để xác nhận service, config, port và firewall.

## 5. Demo FTPS tự ký — phần mở rộng

Phần này là tùy chọn. Nên hoàn thành luồng FTP thường trước rồi mới bật FTPS, vì menu
`3 → 7` đặt `force_local_logins_ssl=YES` và `force_local_data_ssl=YES`; client FTP
thường sẽ không đăng nhập được sau đó.

### 5.1. Bật FTPS

1. Chọn `3 → 7`.
2. Tool tạo certificate tự ký tại `/etc/ssl/private/vsftpd.pem` nếu chưa có.
3. Chọn `3 → 9` để restart.

Các key được thiết lập:

```ini
ssl_enable=YES
force_local_logins_ssl=YES
force_local_data_ssl=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
```

### 5.2. Kết nối FTPS từ client

Với certificate tự ký trong môi trường lab:

```bash
lftp -e "set ftp:ssl-force true; set ssl:verify-certificate no" \
  -u ftp_demo 192.168.1.120
```

Chỉ tắt xác minh certificate trong lab. Hệ thống thật phải dùng certificate được CA
tin cậy và giữ xác minh certificate ở trạng thái bật.

## 6. Các chức năng phụ có thể trình bày

| Đường dẫn menu | Chức năng | Lưu ý |
|---|---|---|
| `1 → 2/3/4/5` | Start, stop, restart, enable | Start lại sau khi demo stop |
| `2 → 4` | Đổi password | Có prompt tương tác của `passwd` |
| `2 → 5/6` | Khóa/mở khóa user | Test login để chứng minh |
| `4 → 7/8/9` | Chặn, bỏ chặn, xem user | Dùng `/etc/vsftpd/user_list` |
| `7 → 2` | Kiểm tra package/command | Không thay đổi hệ thống |
| `7 → 3` | Audit config | Hiển thị tám key quan trọng |
| `7 → 5` | Test localhost | Anonymous tắt có thể tạo warning |
| `7 → 7` | Kiểm tra FTP home | Hiển thị owner và mode |

Danh sách chặn user giả định cấu hình CentOS mặc định:

```ini
userlist_enable=YES
userlist_deny=YES
```

Nếu hai key này đã bị thay đổi thủ công, ý nghĩa của `user_list` cũng thay đổi.

## 7. Lệnh đối chiếu nhanh

```bash
# Package và service
rpm -q vsftpd
systemctl is-enabled vsftpd
systemctl is-active vsftpd
sudo systemctl status vsftpd --no-pager

# Config và socket
sudo grep -Ev '^[[:space:]]*($|#)' /etc/vsftpd/vsftpd.conf
sudo ss -ltnp | grep vsftpd

# Firewall và SELinux
sudo firewall-cmd --list-all
getenforce
getsebool -a | grep -E 'ftp|ftpd'

# User và thư mục
id ftp_demo
sudo passwd -S ftp_demo
sudo ls -ld /home/ftp_demo/ftp /home/ftp_demo/ftp/upload

# Log và backup
sudo journalctl -u vsftpd -n 50 --no-pager
sudo find /var/backups/ftp-manager -maxdepth 1 -type f -name '*.tar.gz' -ls
```

## 8. Xử lý lỗi thường gặp

| Hiện tượng | Nguyên nhân nên kiểm tra | Menu hỗ trợ |
|---|---|---|
| `Connection refused` | Service inactive hoặc sai control port | `1 → 6`, `5 → 3`, `7 → 4` |
| Client timeout | Firewall, NAT hoặc IP sai | `4 → 1`, `7 → 6` |
| Login sai dù password đúng | User bị khóa hoặc nằm trong `user_list` | `2 → 6`, `4 → 9` |
| `500 OOPS: cannot change directory` | Home/permission/SELinux | `7 → 7`, `4 → 5` |
| Login được nhưng không upload | `write_enable`, quyền `upload`, SELinux | `3 → 1`, `7 → 7` |
| `ls` bị treo | Passive range chưa mở hoặc NAT chặn | `3 → 5`, `4 → 4` |
| Plain FTP login hỏng sau khi bật TLS | Server đang bắt buộc FTPS | Dùng client FTPS |
| Certificate warning | Certificate tự ký chưa được client tin | Chỉ bỏ verify trong lab |
| Restart thất bại | Config sai cú pháp/giá trị | `5 → 5`, restore `.bak` |
| Không có `/var/log/xferlog` | Transfer logging chưa bật | Dùng `5 → 5` journal |
| Localhost test báo warning | Anonymous login đang bị tắt | Test bằng user từ client |

## 9. Kịch bản rollback

Nếu sửa config làm service không khởi động:

```bash
sudo journalctl -u vsftpd -n 50 --no-pager
sudo ls -1t /etc/vsftpd/vsftpd.conf.bak.* | head
sudo cp /etc/vsftpd/vsftpd.conf.bak.TIMESTAMP /etc/vsftpd/vsftpd.conf
sudo systemctl restart vsftpd
```

Hoặc dùng `6 → 3` để restore từ archive config đã tạo trước đó.

## 10. Checklist trước khi kết thúc demo

- [ ] `vsftpd` đã cài, enabled và active.
- [ ] User `ftp_demo` tồn tại và đăng nhập được.
- [ ] User bị chroot nhưng ghi được vào `ftp/upload`.
- [ ] Upload và download thành công từ client.
- [ ] TCP 21 và passive range đã đi qua firewall.
- [ ] Xem được port, connection và systemd journal.
- [ ] Health check không còn lỗi quan trọng.
- [ ] Có config archive và xem được nội dung archive.
- [ ] Nếu bật TLS, client đã kết nối bằng FTPS thay vì plain FTP.

## 11. Dọn dẹp sau demo

Nếu máy chỉ dùng cho bài lab, có thể dọn user bằng menu `2 → 2`. Thao tác này xóa cả
home directory nên chỉ thực hiện sau khi đã backup dữ liệu cần giữ.

Không cần gỡ `vsftpd` hoặc đóng firewall nếu máy tiếp tục được dùng làm FTP Server.
Nếu muốn ngừng cung cấp dịch vụ, chọn `1 → 3` để stop và `4 → 3` để đóng rule FTP.

Tài liệu kiến trúc và mô tả từng module nằm trong [docs](docs/README.md).
