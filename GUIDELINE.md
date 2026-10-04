content = r'''# Hướng dẫn Demo A-Z — Auto Script Quản Lý FTP Server trên CentOS

> Tài liệu này dùng để demo đề tài: **“Xây dựng auto script để thực hiện quản lý FTP Server trên CentOS.”**

Mục tiêu của phần demo là chứng minh rằng script có thể:

- Cài đặt FTP Server.
- Khởi động / dừng / restart dịch vụ FTP.
- Kiểm tra trạng thái FTP Server.
- Tạo FTP user.
- Xóa FTP user.
- Liệt kê user.
- Hiển thị IP Server.
- Xem log FTP.
- Cho phép FTP client đăng nhập và thao tác file thực tế.

---

# 1. Kiến trúc demo

```text
┌───────────────────────┐
│       FTP Client      │
│  CentOS / Windows /   │
│       macOS           │
└───────────┬───────────┘
            │
            │ FTP
            │ TCP Port 21
            ▼
┌───────────────────────────────┐
│         CentOS Server         │
│                               │
│    ftp_manager.sh             │
│           │                   │
│           ▼                   │
│        vsftpd                 │
│           │                   │
│  ┌────────┴────────┐          │
│  │                 │          │
│ Users          FTP folders    │
│                               │
│ Firewall + Logs + Config      │
└───────────────────────────────┘
```

---

# 2. Chuẩn bị trước khi demo

## 2.1. Kiểm tra hệ điều hành

```bash
cat /etc/os-release
```

Kết quả mong đợi:

```text
NAME="CentOS Stream"
VERSION="10"
...
```

---

## 2.2. Kiểm tra IP của server

```bash
hostname -I
```

hoặc:

```bash
ip addr
```

Ví dụ:

```text
192.168.200.128
```

Ghi lại IP này để dùng cho bước test FTP từ máy client.

---

## 2.3. Kiểm tra Internet

```bash
ping -c 4 google.com
```

Nếu có response thì Internet hoạt động.

---

## 2.4. Kiểm tra file script

Đi đến thư mục project:

```bash
cd ~/ftp-manager
```

Kiểm tra:

```bash
ls -la
```

Bạn cần thấy:

```text
ftp_manager.sh
```

Cấp quyền thực thi:

```bash
chmod +x ftp_manager.sh
```

---

# 3. Khởi chạy FTP Management Tool

Chạy:

```bash
sudo ./ftp_manager.sh
```

Menu mong đợi:

```text
======================================
       FTP SERVER MANAGEMENT
======================================
1. Install FTP Server
2. Start FTP Server
3. Stop FTP Server
4. Restart FTP Server
5. Show FTP Status
6. Add FTP User
7. Delete FTP User
8. List FTP Users
9. Show Server IP
10. Show FTP Logs
0. Exit
======================================
Choose an option:
```

Đây là màn hình chính để demo toàn bộ project.

---

# 4. Demo tính năng 1 — Install FTP Server

Trong menu chọn:

```text
1
```

Script sẽ thực hiện các công việc chính:

```text
Install vsftpd
      ↓
Enable service
      ↓
Start service
      ↓
Configure firewall
```

Script tương đương với các command:

```bash
sudo dnf install vsftpd -y
sudo systemctl enable vsftpd
sudo systemctl start vsftpd
sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --reload
```

Sau khi chạy xong, kiểm tra package:

```bash
rpm -q vsftpd
```

Kết quả ví dụ:

```text
vsftpd-3.x.x-...
```

---

# 5. Demo tính năng 2 — Start FTP Server

Trong menu chọn:

```text
2
```

Sau đó kiểm tra:

```bash
systemctl is-active vsftpd
```

Kết quả:

```text
active
```

Có thể kiểm tra port 21:

```bash
sudo ss -tulpn | grep :21
```

Kết quả mong đợi:

```text
LISTEN ... :21
```

Ý nghĩa:

```text
FTP Server đang lắng nghe kết nối trên TCP port 21.
```

---

# 6. Demo tính năng 3 — Stop FTP Server

Trong menu chọn:

```text
3
```

Kiểm tra:

```bash
systemctl is-active vsftpd
```

Kết quả:

```text
inactive
```

Kiểm tra port:

```bash
sudo ss -tulpn | grep :21
```

Nếu không có kết quả thì FTP Server đã dừng.

Sau đó dùng menu chọn lại:

```text
2
```

để start server trước khi tiếp tục demo.

---

# 7. Demo tính năng 4 — Restart FTP Server

Trong menu chọn:

```text
4
```

Kiểm tra:

```bash
systemctl is-active vsftpd
```

Kết quả:

```text
active
```

Restart thường được sử dụng sau khi thay đổi:

```text
/etc/vsftpd/vsftpd.conf
```

---

# 8. Demo tính năng 5 — Show FTP Status

Trong menu chọn:

```text
5
```

Kết quả sẽ tương tự:

```text
● vsftpd.service - Vsftpd ftp daemon
     Loaded: loaded
     Active: active (running)
```

Phần cần chỉ cho giảng viên:

```text
Active: active (running)
```

---

# 9. Kiểm tra cấu hình vsftpd

File cấu hình:

```text
/etc/vsftpd/vsftpd.conf
```

Có thể kiểm tra nhanh:

```bash
sudo grep -E \
"anonymous_enable|local_enable|write_enable|local_umask|chroot_local_user|allow_writeable_chroot" \
/etc/vsftpd/vsftpd.conf
```

Cấu hình nên có:

```ini
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
```

Ý nghĩa:

| Cấu hình | Chức năng |
|---|---|
| `anonymous_enable=NO` | Không cho anonymous login |
| `local_enable=YES` | Cho local Linux user đăng nhập |
| `write_enable=YES` | Cho upload / ghi file |
| `local_umask=022` | Quyền mặc định của file mới |
| `chroot_local_user=YES` | Giới hạn user trong home directory |
| `allow_writeable_chroot=YES` | Cho phép chroot directory có quyền ghi |

Sau khi chỉnh config:

```bash
sudo systemctl restart vsftpd
```

---

# 10. Demo tính năng 6 — Add FTP User

Trong menu chọn:

```text
6
```

Nhập username:

```text
ftpuser1
```

Script sẽ gọi:

```bash
useradd -m ftpuser1
```

Sau đó nhập password.

Ví dụ:

```text
Enter FTP username: ftpuser1
New password:
Retype new password:
```

Kiểm tra user:

```bash
id ftpuser1
```

Kết quả dạng:

```text
uid=1001(ftpuser1) gid=1001(ftpuser1) groups=1001(ftpuser1)
```

Kiểm tra home directory:

```bash
sudo ls -ld /home/ftpuser1
```

---

# 11. Kiểm tra FTP directory của user

Script tạo:

```text
/home/ftpuser1/ftp
```

Kiểm tra:

```bash
sudo ls -ld /home/ftpuser1/ftp
```

Nếu gặp:

```text
Permission denied
```

khi dùng:

```bash
ls -la /home/ftpuser1/ftp
```

thì đó là do user hiện tại (`simon`) không có quyền truy cập home của `ftpuser1`.

Dùng:

```bash
sudo ls -la /home/ftpuser1/ftp
```

hoặc:

```bash
sudo -u ftpuser1 ls -la /home/ftpuser1/ftp
```

Không dùng:

```bash
sudo cd /home/ftpuser1
```

vì:

```text
cd
```

là shell built-in command, không phải executable riêng để `sudo` chạy trực tiếp.

Nếu muốn chuyển sang user:

```bash
sudo -iu ftpuser1
```

Sau đó:

```bash
cd ~/ftp
```

---

# 12. Tạo file test

Tạo file với đúng owner:

```bash
sudo -u ftpuser1 touch /home/ftpuser1/ftp/hello.txt
```

Kiểm tra:

```bash
sudo -u ftpuser1 ls -la /home/ftpuser1/ftp
```

Kết quả:

```text
hello.txt
```

Có thể tạo nội dung:

```bash
echo "Hello FTP Server" | \
sudo -u ftpuser1 tee /home/ftpuser1/ftp/demo.txt
```

Kiểm tra:

```bash
sudo cat /home/ftpuser1/ftp/demo.txt
```

Output:

```text
Hello FTP Server
```

---

# 13. Demo tính năng 7 — List FTP Users

Trong menu chọn:

```text
8
```

Output ví dụ:

```text
===== FTP Users =====
simon      -> /home/simon
ftpuser1   -> /home/ftpuser1
```

Lưu ý:

Phiên bản đơn giản của script liệt kê Linux users có UID >= 1000.

Vì vậy:

```text
simon
```

có thể xuất hiện mặc dù không được tạo riêng bởi FTP Manager.

Đây là điểm có thể cải tiến bằng cách duy trì một danh sách FTP users riêng.

---

# 14. Demo tính năng 8 — Show Server IP

Trong menu chọn:

```text
9
```

Kết quả:

```text
===== Server IP =====
192.168.200.128
```

IP này sẽ dùng để client kết nối:

```text
ftp://192.168.200.128
```

---

# 15. Kiểm tra Firewall

Kiểm tra trạng thái firewalld:

```bash
sudo firewall-cmd --state
```

Kết quả:

```text
running
```

Kiểm tra service được cho phép:

```bash
sudo firewall-cmd --list-services
```

Kết quả nên chứa:

```text
ftp
```

Ví dụ:

```text
cockpit dhcpv6-client ftp ssh
```

Có thể kiểm tra trực tiếp:

```bash
sudo firewall-cmd --query-service=ftp
```

Kết quả:

```text
yes
```

---

# 16. Test FTP trên chính CentOS Server

Nếu chưa có client:

```bash
sudo dnf install lftp -y
```

Kết nối:

```bash
lftp ftpuser1@localhost
```

Nhập password khi được yêu cầu.

Sau khi login:

```bash
ls
```

Nếu home directory chứa folder `ftp`:

```text
ftp
```

Chuyển directory:

```bash
cd ftp
```

Liệt kê file:

```bash
ls
```

Bạn sẽ thấy:

```text
hello.txt
demo.txt
```

---

# 17. Test download file bằng FTP

Trong `lftp`:

```bash
get demo.txt
```

Thoát:

```bash
exit
```

Kiểm tra file vừa download:

```bash
ls -la demo.txt
```

Đọc nội dung:

```bash
cat demo.txt
```

Output:

```text
Hello FTP Server
```

Đây là bằng chứng FTP download hoạt động.

---

# 18. Test upload file bằng FTP

Trên client tạo file:

```bash
echo "Upload test from client" > upload-test.txt
```

Kết nối lại:

```bash
lftp ftpuser1@localhost
```

Sau đó:

```bash
cd ftp
```

Upload:

```bash
put upload-test.txt
```

Kiểm tra:

```bash
ls
```

Kết quả nên có:

```text
upload-test.txt
```

Thoát:

```bash
exit
```

Kiểm tra từ server:

```bash
sudo cat /home/ftpuser1/ftp/upload-test.txt
```

Output:

```text
Upload test from client
```

Đây là bằng chứng FTP upload hoạt động.

---

# 19. Test FTP từ máy khác

Nếu CentOS chạy trong VMware:

```text
Host machine
     │
     │ Network
     ▼
CentOS VM
192.168.x.x
```

Đầu tiên kiểm tra:

```bash
hostname -I
```

Ví dụ:

```text
192.168.200.128
```

Từ client có thể dùng FileZilla hoặc `lftp`.

Thông tin kết nối:

```text
Host: 192.168.200.128
Port: 21
Username: ftpuser1
Password: <password đã tạo>
Protocol: FTP
```

Nếu kết nối thành công thì demo:

```text
Client
   │
   ├── Login
   ├── List files
   ├── Upload
   └── Download
        │
        ▼
CentOS FTP Server
```

---

# 20. Demo tính năng 9 — Show FTP Logs

Trong menu chọn:

```text
10
```

Hoặc chạy trực tiếp:

```bash
sudo journalctl -u vsftpd -n 30 --no-pager
```

Để theo dõi log realtime:

```bash
sudo journalctl -u vsftpd -f
```

Sau đó thử login từ FTP client.

Log sẽ giúp chứng minh:

```text
Client request
       ↓
vsftpd receives connection
       ↓
Authentication / Session
       ↓
System log
```

Nhấn:

```text
Ctrl + C
```

để thoát realtime log.

---

# 21. Demo tính năng 10 — Delete FTP User

Trước tiên kiểm tra:

```bash
id ftpuser1
```

Sau đó trong menu chọn:

```text
7
```

Nhập:

```text
ftpuser1
```

Script hỏi xác nhận:

```text
Delete ftpuser1 and home directory? (y/n):
```

Nhập:

```text
y
```

Script sử dụng:

```bash
userdel -r ftpuser1
```

Kiểm tra lại:

```bash
id ftpuser1
```

Kết quả mong đợi:

```text
id: 'ftpuser1': no such user
```

Kiểm tra home:

```bash
sudo ls /home/ftpuser1
```

Kết quả:

```text
No such file or directory
```

Điều này chứng minh tính năng xóa user và dữ liệu home hoạt động.

---

# 22. Demo Stop → Start → Restart toàn bộ flow

Có thể kết thúc phần demo bằng chuỗi thao tác:

```text
FTP running
    ↓
Stop FTP
    ↓
Check inactive
    ↓
Start FTP
    ↓
Check active
    ↓
Restart FTP
    ↓
Check active
```

Command kiểm tra nhanh:

```bash
systemctl is-active vsftpd
```

---

# 23. Kiểm tra toàn bộ hệ thống bằng command

## FTP package

```bash
rpm -q vsftpd
```

## Service

```bash
systemctl status vsftpd
```

## Port

```bash
sudo ss -tulpn | grep :21
```

## Firewall

```bash
sudo firewall-cmd --query-service=ftp
```

## User

```bash
id ftpuser1
```

## FTP folder

```bash
sudo ls -la /home/ftpuser1/ftp
```

## Logs

```bash
sudo journalctl -u vsftpd -n 20 --no-pager
```

---

# 24. Kịch bản demo ngắn 5–7 phút

Nếu thời gian bảo vệ ngắn, có thể demo theo thứ tự sau.

## Phần 1 — Giới thiệu

Nói:

> Đề tài của em là xây dựng Bash script hỗ trợ tự động hóa quản trị FTP Server trên CentOS. Script hỗ trợ cài đặt vsftpd, quản lý service, user, kiểm tra IP và log hệ thống.

---

## Phần 2 — Chạy script

```bash
cd ~/ftp-manager
sudo ./ftp_manager.sh
```

Cho giảng viên xem menu.

---

## Phần 3 — Status Server

Chọn:

```text
5
```

Cho thấy:

```text
active (running)
```

---

## Phần 4 — Tạo user

Chọn:

```text
6
```

Tạo:

```text
demoftp
```

Kiểm tra:

```bash
id demoftp
```

---

## Phần 5 — Test FTP thật

Tạo file:

```bash
sudo -u demoftp touch /home/demoftp/ftp/demo-file.txt
```

Login:

```bash
lftp demoftp@localhost
```

Sau đó:

```bash
cd ftp
ls
```

Hiển thị:

```text
demo-file.txt
```

---

## Phần 6 — Upload

Client:

```bash
echo "FTP DEMO" > test.txt
```

Trong `lftp`:

```bash
put test.txt
ls
```

---

## Phần 7 — Show logs

Thoát lftp:

```bash
exit
```

Trong FTP Manager chọn:

```text
10
```

Cho giảng viên xem log.

---

## Phần 8 — Delete user

Trong menu chọn:

```text
7
```

Xóa:

```text
demoftp
```

Kiểm tra:

```bash
id demoftp
```

Kết quả:

```text
no such user
```

---

# 25. Kịch bản demo đầy đủ 10–15 phút

Nếu có nhiều thời gian hơn:

```text
1. Show CentOS version
        ↓
2. Show Server IP
        ↓
3. Run FTP Manager
        ↓
4. Install / verify vsftpd
        ↓
5. Show status
        ↓
6. Stop service
        ↓
7. Verify inactive
        ↓
8. Start service
        ↓
9. Verify active
        ↓
10. Create FTP user
        ↓
11. Verify home directory
        ↓
12. Login using FTP client
        ↓
13. List files
        ↓
14. Upload file
        ↓
15. Download file
        ↓
16. Show FTP logs
        ↓
17. Restart FTP
        ↓
18. Delete FTP user
        ↓
19. Verify user deletion
```

---

# 26. Các câu hỏi giảng viên có thể hỏi

## FTP là gì?

FTP là:

```text
File Transfer Protocol
```

Dùng để truyền file giữa client và server thông qua network.

---

## FTP mặc định sử dụng port nào?

Control connection:

```text
TCP Port 21
```

---

## vsftpd là gì?

`vsftpd`:

```text
Very Secure FTP Daemon
```

là một FTP Server phổ biến trên Linux.

---

## Vì sao cần firewall rule?

Mặc định firewall có thể chặn kết nối từ client.

Do đó cần:

```bash
sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --reload
```

---

## systemctl dùng để làm gì?

Quản lý service trên hệ thống sử dụng `systemd`.

Ví dụ:

```bash
systemctl start vsftpd
systemctl stop vsftpd
systemctl restart vsftpd
systemctl status vsftpd
```

---

## Vì sao không dùng `sudo cd`?

`cd` là shell built-in.

Command:

```bash
sudo cd /home/ftpuser1
```

không hoạt động như mong muốn.

Có thể dùng:

```bash
sudo -iu ftpuser1
```

sau đó:

```bash
cd ~/ftp
```

---

## Chroot dùng để làm gì?

```ini
chroot_local_user=YES
```

giúp giới hạn FTP user trong home directory của chính họ.

Điều này giúp user không thể duyệt toàn bộ filesystem của server.

---

## Script giải quyết vấn đề gì?

Thay vì administrator phải nhớ và chạy nhiều command như:

```bash
dnf
systemctl
firewall-cmd
useradd
passwd
userdel
journalctl
```

script gom chúng lại thành:

```text
FTP Management Tool
```

với menu thống nhất.

---

# 27. Troubleshooting

## Lỗi: Permission denied

Ví dụ:

```text
ls: cannot access '/home/ftpuser1/ftp': Permission denied
```

Dùng:

```bash
sudo ls -la /home/ftpuser1/ftp
```

hoặc:

```bash
sudo -u ftpuser1 ls -la /home/ftpuser1/ftp
```

Kiểm tra permission:

```bash
sudo ls -ld /home/ftpuser1
sudo ls -ld /home/ftpuser1/ftp
```

---

## Lỗi FTP không chạy

Kiểm tra:

```bash
sudo systemctl status vsftpd
```

Xem log:

```bash
sudo journalctl -u vsftpd -n 50 --no-pager
```

Restart:

```bash
sudo systemctl restart vsftpd
```

---

## Không connect được từ client

Kiểm tra server IP:

```bash
hostname -I
```

Kiểm tra port:

```bash
sudo ss -tulpn | grep :21
```

Kiểm tra firewall:

```bash
sudo firewall-cmd --query-service=ftp
```

Phải trả về:

```text
yes
```

---

## User login bị từ chối

Kiểm tra:

```bash
id ftpuser1
```

Đổi password:

```bash
sudo passwd ftpuser1
```

Kiểm tra:

```ini
local_enable=YES
```

trong:

```text
/etc/vsftpd/vsftpd.conf
```

Sau đó:

```bash
sudo systemctl restart vsftpd
```

---

# 28. Checklist trước khi lên demo

Kiểm tra từng mục:

```text
[ ] CentOS boot bình thường
[ ] Có network
[ ] Biết IP Server
[ ] ftp_manager.sh tồn tại
[ ] Script có execute permission
[ ] vsftpd đã cài
[ ] vsftpd đang active
[ ] Port 21 LISTEN
[ ] Firewall cho phép FTP
[ ] lftp đã cài
[ ] Có sẵn user demo hoặc có thể tạo nhanh
[ ] Biết password user demo
[ ] Có file để upload
[ ] Có file để download
[ ] Logs hoạt động
```

---

# 29. Command cheat sheet

```bash
# Run project
cd ~/ftp-manager
sudo ./ftp_manager.sh

# Status
systemctl is-active vsftpd

# Full status
sudo systemctl status vsftpd

# Restart
sudo systemctl restart vsftpd

# Port
sudo ss -tulpn | grep :21

# Firewall
sudo firewall-cmd --query-service=ftp

# IP
hostname -I

# Create test user
sudo useradd -m ftpuser1
sudo passwd ftpuser1

# FTP folder
sudo mkdir -p /home/ftpuser1/ftp
sudo chown -R ftpuser1:ftpuser1 /home/ftpuser1/ftp

# Test file
sudo -u ftpuser1 touch /home/ftpuser1/ftp/hello.txt

# Safe listing
sudo -u ftpuser1 ls -la /home/ftpuser1/ftp

# FTP client
lftp ftpuser1@localhost

# Logs
sudo journalctl -u vsftpd -n 30 --no-pager
```

---

# 30. Kết quả cuối cùng cần chứng minh

Sau khi demo thành công, hệ thống phải chứng minh được:

```text
               Admin
                 │
                 ▼
        ftp_manager.sh
                 │
     ┌───────────┼───────────┐
     ▼           ▼           ▼
   vsftpd      Users       Firewall
     │           │           │
     └───────────┼───────────┘
                 ▼
             FTP Server
                 │
                 │ TCP 21
                 ▼
             FTP Client
                 │
          ┌──────┴──────┐
          ▼             ▼
       Upload        Download
```

Đề tài khi hoàn thành không chỉ chứng minh FTP hoạt động, mà còn chứng minh rằng quá trình quản trị FTP Server đã được **tự động hóa bằng Bash script** trên CentOS.
'''

path = "/mnt/data/README_DEMO.md"
with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print(path)
