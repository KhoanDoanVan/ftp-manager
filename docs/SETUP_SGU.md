# Cấu hình A-Z trước demo - FTP Server với domain SGU

Tài liệu này dùng để **chuẩn bị hệ thống trước buổi demo**, không phải nội dung cần
trình bày trên lớp. Sau khi hoàn thành, dùng `GUIDELINE.md` để demo riêng các auto
script quản lý FTP Server.

## A. Thông số mô hình

Ví dụ dưới đây bám theo mô hình của nhóm trước:

| Thành phần | Giá trị mẫu |
|---|---|
| FTP/DNS Server | CentOS |
| Server IP | `192.168.154.129` |
| LAN | `192.168.154.0/24` |
| Domain | `sgu.edu.vn` |
| FTP FQDN | `ftp.sgu.edu.vn` |
| DNS host | `server.sgu.edu.vn` |
| Local FTP user | `itadmin` |
| Passive ports | `30000-31000` |

Thay IP và LAN mẫu bằng thông số thật của máy ảo. Các bước bên dưới giả định server
có IP cố định; không nên dùng DHCP thay đổi liên tục cho DNS Server.

## B. Kiểm tra hệ điều hành và mạng

```bash
cat /etc/os-release
hostnamectl
hostname -I
ip -brief address
ip route
ping -c 4 8.8.8.8
```

Đặt hostname:

```bash
sudo hostnamectl set-hostname server.sgu.edu.vn
```

Thêm ánh xạ cục bộ để server tự nhận diện hostname:

```text
192.168.154.129  server.sgu.edu.vn server ftp.sgu.edu.vn ftp
```

Thêm dòng trên vào `/etc/hosts`, nhưng phải thay bằng IP thật nếu khác IP mẫu. Alias
`ftp.sgu.edu.vn` cũng là phương án dự phòng để tool transfer chạy tại server ngay cả
khi DNS resolver cục bộ chưa trỏ về BIND.

## C. Cài các package cần thiết

```bash
sudo dnf install -y vsftpd bind bind-utils lftp policycoreutils-python-utils
```

Kiểm tra:

```bash
rpm -q vsftpd bind bind-utils lftp
```

Chưa start dịch vụ cho tới khi hoàn thành config ở các bước tiếp theo.

## D. Backup cấu hình gốc

```bash
sudo cp -a /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.original
sudo cp -a /etc/named.conf /etc/named.conf.original
sudo cp -a /etc/named.rfc1912.zones /etc/named.rfc1912.zones.original
```

Nếu các file `.original` đã tồn tại, không ghi đè; tạo tên có timestamp khác.

## E. Tạo local FTP user và cấu trúc chroot

```bash
sudo useradd -m itadmin
sudo passwd itadmin
sudo mkdir -p /home/itadmin/ftp/upload
sudo chown root:root /home/itadmin/ftp
sudo chmod 755 /home/itadmin/ftp
sudo chown -R itadmin:itadmin /home/itadmin/ftp/upload
sudo chmod -R 700 /home/itadmin/ftp/upload
```

Kiểm tra:

```bash
id itadmin
sudo ls -ld /home/itadmin/ftp /home/itadmin/ftp/upload
```

Kết quả cần đạt:

```text
/home/itadmin/ftp          root:root
/home/itadmin/ftp/upload   itadmin:itadmin
```

Gốc chroot thuộc `root` để user không thể thay đổi; `upload` là vùng được ghi.

## F. Chuẩn bị anonymous read-only

```bash
sudo mkdir -p /var/ftp/pub
sudo chown root:root /var/ftp /var/ftp/pub
sudo chmod 755 /var/ftp /var/ftp/pub
echo "Welcome to SGU FTP Server" | sudo tee /var/ftp/pub/readme.txt
sudo chmod 644 /var/ftp/pub/readme.txt
```

Anonymous chỉ được đọc `/var/ftp/pub`. Không tạo vùng anonymous upload trong cấu hình
nền; có thể bật tạm bằng tool khi cần chứng minh phân quyền.

## G. Cấu hình `/etc/vsftpd/vsftpd.conf`

Mở file:

```bash
sudo vi /etc/vsftpd/vsftpd.conf
```

Bảo đảm các key sau chỉ xuất hiện một lần và có giá trị:

```ini
anonymous_enable=YES
no_anon_password=YES
anon_root=/var/ftp
anon_world_readable_only=YES
anon_upload_enable=NO
anon_mkdir_write_enable=NO

local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=NO

dirmessage_enable=YES
xferlog_enable=YES
xferlog_std_format=YES
dual_log_enable=YES
connect_from_port_20=YES

listen=YES
listen_ipv6=NO
listen_port=21

pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000

pam_service_name=vsftpd
userlist_enable=YES
userlist_deny=YES

ssl_enable=NO
```

Lưu ý về chroot:

- Với `chroot_local_user=YES`, tất cả local user mặc định bị cô lập trong home.
- Không cần thêm `itadmin` vào `chroot_list`.
- Nếu đồng thời bật `chroot_list_enable=YES`, user trong danh sách có thể trở thành
  ngoại lệ không bị chroot, tùy giá trị `chroot_local_user`. Vì vậy không sao chép
  máy móc cách `echo itadmin > chroot_list` nếu chưa hiểu cặp cấu hình này.

Kiểm tra các dòng hiệu lực:

```bash
sudo grep -Ev '^[[:space:]]*($|#)' /etc/vsftpd/vsftpd.conf
```

## H. Cấu hình firewall, không tắt firewall

```bash
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --permanent --add-port=30000-31000/tcp
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

Kết quả cần có `ftp`, `dns` và `30000-31000/tcp`.

## I. Cấu hình SELinux

Kiểm tra trước:

```bash
getenforce
getsebool -a | grep -E 'ftp|ftpd'
```

Không tắt SELinux. Với bài lab cần FTP ghi vào home directory, có thể dùng:

```bash
sudo setsebool -P ftpd_full_access on
```

Đây là boolean rộng, thuận tiện cho lab. Khi triển khai thật nên dùng SELinux label
đúng phạm vi thay vì cấp toàn quyền cho daemon.

## J. Cấu hình BIND lắng nghe trong LAN

Mở:

```bash
sudo vi /etc/named.conf
```

Trong block `options`, đặt:

```conf
listen-on port 53 { 127.0.0.1; 192.168.154.129; };
allow-query { localhost; 192.168.154.0/24; };
```

Nếu IP/LAN khác mẫu, phải thay cả hai giá trị. Không dùng `allow-query { any; };` trên
máy có thể truy cập từ Internet vì sẽ tạo resolver mở.

## K. Khai báo zone `sgu.edu.vn`

Mở:

```bash
sudo vi /etc/named.rfc1912.zones
```

Thêm cuối file:

```conf
zone "sgu.edu.vn" IN {
    type master;
    file "ftp-manager-sgu.edu.vn.zone";
    allow-update { none; };
};
```

## L. Tạo zone database

Tạo `/var/named/ftp-manager-sgu.edu.vn.zone`:

```bash
sudo vi /var/named/ftp-manager-sgu.edu.vn.zone
```

Nội dung:

```dns
$TTL 86400
@ IN SOA server.sgu.edu.vn. root.sgu.edu.vn. (
    2026101101 ; serial - tăng mỗi lần sửa zone
    3600       ; refresh
    1800       ; retry
    604800     ; expire
    86400      ; minimum
)

@       IN NS  server.sgu.edu.vn.
@       IN A   192.168.154.129
server  IN A   192.168.154.129
ftp     IN A   192.168.154.129
```

Thay IP nếu cần. Mỗi lần sửa zone, tăng `serial`.

Phân quyền:

```bash
sudo chown root:named /var/named/ftp-manager-sgu.edu.vn.zone
sudo chmod 640 /var/named/ftp-manager-sgu.edu.vn.zone
```

## M. Validate BIND trước khi chạy

```bash
sudo named-checkconf /etc/named.conf
sudo named-checkzone sgu.edu.vn /var/named/ftp-manager-sgu.edu.vn.zone
sudo named-checkconf -z /etc/named.conf
```

Chỉ tiếp tục nếu `named-checkzone` trả về `OK` và không có lỗi từ
`named-checkconf`.

## N. Khởi động dịch vụ

```bash
sudo systemctl enable --now named
sudo systemctl enable --now vsftpd
sudo systemctl restart named
sudo systemctl restart vsftpd
sudo systemctl status named --no-pager
sudo systemctl status vsftpd --no-pager
```

Cả hai phải ở trạng thái `active (running)`.

## O. Kiểm tra DNS

Trên server:

```bash
dig @127.0.0.1 ftp.sgu.edu.vn A
nslookup ftp.sgu.edu.vn 127.0.0.1
```

Trên client:

```bash
dig @192.168.154.129 ftp.sgu.edu.vn A
nslookup ftp.sgu.edu.vn 192.168.154.129
```

Kết quả phải trả về `192.168.154.129` hoặc IP thật đã cấu hình.

Muốn mọi ứng dụng trên client dùng FQDN, đặt IP CentOS làm DNS Server cho kết nối mạng
của client. Với demo ngắn có thể thêm tạm vào `/etc/hosts` của client:

```text
192.168.154.129  ftp.sgu.edu.vn
```

## P. Kiểm tra FTP trước buổi demo

Kiểm tra port:

```bash
sudo ss -ltnp | grep ':21'
sudo firewall-cmd --query-service=ftp
sudo firewall-cmd --query-port=30000-31000/tcp
```

Kiểm tra anonymous:

```bash
curl --list-only ftp://127.0.0.1/pub/
curl ftp://127.0.0.1/pub/readme.txt
```

Kiểm tra local user:

```bash
lftp -u itadmin ftp://127.0.0.1
```

Trong `lftp`:

```text
ls
cd ftp/upload
put /etc/hostname -o hostname-demo.txt
get hostname-demo.txt -o /tmp/hostname-downloaded.txt
bye
```

## Q. Chuẩn bị project và smoke test

```bash
cd ~/ftp-manager
chmod +x ftp_manager.sh tests/smoke_test.sh
bash tests/smoke_test.sh
```

Kết quả:

```text
Smoke tests: PASS
```

## R. Tạo dữ liệu sẵn cho phần demo

```bash
echo "FTP Manager upload demo" > /tmp/ftp-upload-demo.txt
mkdir -p /tmp/ftp-demo-folder
echo "file one" > /tmp/ftp-demo-folder/one.txt
echo "file two" > /tmp/ftp-demo-folder/two.txt
```

Ghi sẵn các thông tin dùng khi demo:

```text
FTP host: ftp.sgu.edu.vn
FTP port: 21
FTP user: itadmin
Passive range: 30000-31000
```

## S. Checklist sẵn sàng

- [ ] IP server cố định và client ping được server.
- [ ] `ftp.sgu.edu.vn` phân giải đúng IP.
- [ ] `named` và `vsftpd` active.
- [ ] Firewall có `ftp`, `dns`, `30000-31000/tcp`.
- [ ] User `itadmin` đăng nhập được.
- [ ] `/home/itadmin/ftp` thuộc root.
- [ ] `/home/itadmin/ftp/upload` thuộc `itadmin`.
- [ ] Anonymous đọc được `/pub/readme.txt`.
- [ ] Upload/download local user thành công.
- [ ] `bash tests/smoke_test.sh` trả về PASS.
- [ ] Đã có file `/tmp/ftp-upload-demo.txt` để demo.

Khi toàn bộ checklist đạt, chuyển sang [kịch bản demo auto script](../GUIDELINE.md).
