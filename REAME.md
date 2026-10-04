content = r'''# Auto Script quản lý FTP Server trên CentOS

> **Đề tài:** “Xây dựng auto script để thực hiện quản lý FTP Server trên CentOS.”

Đây là đề tài khá hợp lý cho bài Linux/CentOS vì bạn không chỉ cấu hình FTP mà còn viết **Bash automation tool** để quản trị server.

## Kiến trúc đề xuất

```text
                    FTP Management Tool
                         ftp_manager.sh
                               │
          ┌────────────────────┼─────────────────────┐
          │                    │                     │
      Install FTP         Manage Service        Manage Users
          │                    │                     │
       vsftpd            start / stop            add / delete
                        restart / status          list users
          │
          ├── Firewall
          ├── Passive ports
          ├── FTP directory
          ├── Configuration
          └── Logs
```

Sau khi hoàn thành, chỉ cần chạy:

```bash
sudo ./ftp_manager.sh
```

và sẽ có menu kiểu:

```text
====================================
       FTP SERVER MANAGER
====================================
1. Install FTP Server
2. Start FTP Server
3. Stop FTP Server
4. Restart FTP Server
5. FTP Server Status
6. Add FTP User
7. Delete FTP User
8. List FTP Users
9. Configure FTP Server
10. Show FTP Logs
11. Show Server IP
0. Exit
====================================
Choose:
```

Ta sẽ làm **từng bước**, và mình khuyên chưa viết toàn bộ script ngay. Trước tiên phải cấu hình FTP bằng tay một lần để hiểu script đang tự động hóa thứ gì.

---

# Bước 1 — Kiểm tra CentOS

Trên CentOS VM của bạn chạy:

```bash
cat /etc/os-release
```

Sau đó:

```bash
hostnamectl
```

và:

```bash
ip addr
```

Bạn cần biết IP của CentOS, ví dụ:

```text
192.168.1.120
```

hoặc nếu dùng VMware NAT:

```text
192.168.200.128
```

Kiểm tra internet:

```bash
ping -c 4 google.com
```

Nếu thấy:

```text
64 bytes from ...
64 bytes from ...
```

thì ổn.

---

# Bước 2 — Cài FTP Server

CentOS thường dùng **vsftpd** — Very Secure FTP Daemon.

Cài:

```bash
sudo dnf install vsftpd -y
```

Kiểm tra:

```bash
rpm -q vsftpd
```

Bạn sẽ thấy dạng:

```text
vsftpd-3.x.x-...
```

---

# Bước 3 — Start FTP Server

Khởi động:

```bash
sudo systemctl start vsftpd
```

Cho phép tự chạy khi boot:

```bash
sudo systemctl enable vsftpd
```

Kiểm tra:

```bash
sudo systemctl status vsftpd
```

Kết quả quan trọng là:

```text
Active: active (running)
```

Bạn cũng có thể dùng:

```bash
systemctl is-active vsftpd
```

Nếu kết quả:

```text
active
```

là đúng.

---

# Bước 4 — Kiểm tra port FTP

FTP mặc định dùng TCP port:

```text
21
```

Kiểm tra:

```bash
sudo ss -tulpn | grep :21
```

Bạn nên thấy gần giống:

```text
LISTEN 0 32 0.0.0.0:21
```

Architecture lúc này:

```text
FTP Client
    │
    │ TCP 21
    ▼
┌─────────────────┐
│ CentOS Server   │
│                 │
│     vsftpd      │
│     Port 21     │
└─────────────────┘
```

---

# Bước 5 — Configure Firewall

Nếu `firewalld` đang chạy:

```bash
sudo firewall-cmd --state
```

Cho FTP qua firewall:

```bash
sudo firewall-cmd --permanent --add-service=ftp
```

Reload:

```bash
sudo firewall-cmd --reload
```

Kiểm tra:

```bash
sudo firewall-cmd --list-services
```

Bạn nên thấy:

```text
cockpit dhcpv6-client ftp ssh
```

---

# Bước 6 — Backup config trước khi sửa

File cấu hình chính:

```text
/etc/vsftpd/vsftpd.conf
```

Backup:

```bash
sudo cp /etc/vsftpd/vsftpd.conf \
/etc/vsftpd/vsftpd.conf.backup
```

Kiểm tra:

```bash
ls -l /etc/vsftpd/
```

Bạn sẽ có:

```text
vsftpd.conf
vsftpd.conf.backup
```

Đây là thao tác nên đưa vào auto script sau này.

---

# Bước 7 — Configure FTP local users

Mở:

```bash
sudo nano /etc/vsftpd/vsftpd.conf
```

Tìm hoặc thêm các cấu hình:

```ini
anonymous_enable=NO

local_enable=YES

write_enable=YES

local_umask=022

chroot_local_user=YES

allow_writeable_chroot=YES
```

Ý nghĩa:

| Setting | Ý nghĩa |
|---|---|
| `anonymous_enable=NO` | Không cho anonymous login |
| `local_enable=YES` | Cho phép Linux user login FTP |
| `write_enable=YES` | Cho phép upload/write |
| `local_umask=022` | Permission mặc định |
| `chroot_local_user=YES` | Nhốt user trong home directory |
| `allow_writeable_chroot=YES` | Cho phép chroot directory writable |

Restart:

```bash
sudo systemctl restart vsftpd
```

---

# Bước 8 — Tạo FTP user đầu tiên

Ví dụ tạo:

```bash
ftpuser1
```

Chạy:

```bash
sudo useradd -m ftpuser1
```

Đặt password:

```bash
sudo passwd ftpuser1
```

Ví dụ:

```text
New password:
Retype new password:
```

Kiểm tra:

```bash
id ftpuser1
```

và:

```bash
ls -ld /home/ftpuser1
```

---

# Bước 9 — Tạo folder FTP

Tạo:

```bash
sudo mkdir -p /home/ftpuser1/ftp
```

Set owner:

```bash
sudo chown -R ftpuser1:ftpuser1 /home/ftpuser1/ftp
```

Tạo file test:

```bash
sudo -u ftpuser1 touch /home/ftpuser1/ftp/hello.txt
```

Kiểm tra:

```bash
ls -la /home/ftpuser1/ftp
```

Bạn nên thấy:

```text
hello.txt
```

---

# Bước 10 — Test FTP

Có thể cài FTP client:

```bash
sudo dnf install ftp -y
```

Nếu package `ftp` không tồn tại trên CentOS version của bạn, dùng:

```bash
sudo dnf install lftp -y
```

Sau đó:

```bash
ftp localhost
```

hoặc:

```bash
lftp ftpuser1@localhost
```

Login:

```text
Username: ftpuser1
Password: ********
```

Sau login thử:

```bash
ls
```

```bash
cd ftp
```

```bash
ls
```

Bạn sẽ thấy:

```text
hello.txt
```

Như vậy **FTP Server cơ bản đã hoạt động**.

---

# Bước 11 — Bắt đầu viết automation script

Bây giờ mới tới phần quan trọng nhất của đề tài:

```text
Auto Script quản lý FTP Server
```

Tạo thư mục project:

```bash
mkdir -p ~/ftp-manager
```

Vào thư mục:

```bash
cd ~/ftp-manager
```

Tạo script:

```bash
nano ftp_manager.sh
```

Version đầu tiên:

```bash
#!/bin/bash

# ==========================================
# FTP Server Management Tool
# CentOS
# ==========================================

FTP_SERVICE="vsftpd"
FTP_CONFIG="/etc/vsftpd/vsftpd.conf"

show_menu() {

    clear

    echo "======================================"
    echo "       FTP SERVER MANAGEMENT"
    echo "======================================"
    echo "1. Install FTP Server"
    echo "2. Start FTP Server"
    echo "3. Stop FTP Server"
    echo "4. Restart FTP Server"
    echo "5. Show FTP Status"
    echo "6. Add FTP User"
    echo "7. Delete FTP User"
    echo "8. List FTP Users"
    echo "9. Show Server IP"
    echo "10. Show FTP Logs"
    echo "0. Exit"
    echo "======================================"
}
```

Đây mới chỉ là UI/menu.

---

# Bước 12 — Function Install FTP

Thêm:

```bash
install_ftp() {

    echo "Installing vsftpd..."

    sudo dnf install vsftpd -y

    sudo systemctl enable vsftpd
    sudo systemctl start vsftpd

    sudo firewall-cmd \
        --permanent \
        --add-service=ftp

    sudo firewall-cmd --reload

    echo "FTP Server installed successfully."
}
```

Function này tự động hóa:

```text
dnf install
      ↓
enable service
      ↓
start service
      ↓
configure firewall
```

---

# Bước 13 — Service-management functions

Thêm:

```bash
start_ftp() {
    sudo systemctl start vsftpd
    echo "FTP Server started."
}
```

```bash
stop_ftp() {
    sudo systemctl stop vsftpd
    echo "FTP Server stopped."
}
```

```bash
restart_ftp() {
    sudo systemctl restart vsftpd
    echo "FTP Server restarted."
}
```

```bash
status_ftp() {
    sudo systemctl status vsftpd --no-pager
}
```

---

# Bước 14 — Add FTP User

Đây là chức năng rất quan trọng.

```bash
add_ftp_user() {

    read -p "Enter FTP username: " username

    if id "$username" &>/dev/null; then

        echo "User $username already exists."

        return
    fi

    sudo useradd -m "$username"

    sudo passwd "$username"

    sudo mkdir -p "/home/$username/ftp"

    sudo chown -R \
        "$username:$username" \
        "/home/$username/ftp"

    echo "FTP user '$username' created successfully."
}
```

Workflow:

```text
Admin
  │
  │ username
  ▼
ftp_manager.sh
  │
  ├── useradd
  │
  ├── passwd
  │
  ├── create /home/user/ftp
  │
  └── set permissions
```

---

# Bước 15 — Delete FTP User

```bash
delete_ftp_user() {

    read -p "Enter username to delete: " username

    if ! id "$username" &>/dev/null; then

        echo "User does not exist."

        return
    fi

    read -p \
        "Delete $username and home directory? (y/n): " \
        confirm

    if [[ "$confirm" == "y" ]]; then

        sudo userdel -r "$username"

        echo "User deleted."

    else

        echo "Operation cancelled."

    fi
}
```

Việc hỏi confirmation giúp tránh:

```bash
userdel -r
```

xóa nhầm dữ liệu.

---

# Bước 16 — List FTP Users

Một cách đơn giản:

```bash
list_ftp_users() {

    echo "===== FTP Users ====="

    awk -F: '$3 >= 1000 {
        print $1 "  ->  " $6
    }' /etc/passwd
}
```

Output ví dụ:

```text
===== FTP Users =====

simon     -> /home/simon
ftpuser1  -> /home/ftpuser1
ftpuser2  -> /home/ftpuser2
```

Sau này mình sẽ cải tiến vì không phải Linux user nào cũng là FTP user.

---

# Bước 17 — Show IP

```bash
show_ip() {

    echo "===== Server IP ====="

    hostname -I
}
```

Ví dụ:

```text
192.168.200.128
```

Thì client sẽ connect:

```text
ftp://192.168.200.128
```

---

# Bước 18 — FTP Logs

Trên systemd:

```bash
show_logs() {

    sudo journalctl \
        -u vsftpd \
        -n 30 \
        --no-pager
}
```

Administrator có thể xem:

```text
login
logout
service errors
configuration errors
```

---

# Bước 19 — Main loop

Cuối file thêm:

```bash
while true
do

    show_menu

    read -p "Choose an option: " choice

    case $choice in

        1)
            install_ftp
            ;;

        2)
            start_ftp
            ;;

        3)
            stop_ftp
            ;;

        4)
            restart_ftp
            ;;

        5)
            status_ftp
            ;;

        6)
            add_ftp_user
            ;;

        7)
            delete_ftp_user
            ;;

        8)
            list_ftp_users
            ;;

        9)
            show_ip
            ;;

        10)
            show_logs
            ;;

        0)
            echo "Exit."
            exit 0
            ;;

        *)
            echo "Invalid option."
            ;;

    esac

    echo
    read -p "Press Enter to continue..."

done
```

---

# Bước 20 — Make executable

```bash
chmod +x ftp_manager.sh
```

Run:

```bash
sudo ./ftp_manager.sh
```

Bạn sẽ có:

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

Đây đã đạt được phần cốt lõi của đề tài.

---

# Nâng project thêm một mức

Nếu chỉ có script trên thì nó ở mức **basic automation**.

Final project nên có các chức năng:

```text
FTP Management System
│
├── Server
│   ├── Install
│   ├── Start
│   ├── Stop
│   ├── Restart
│   └── Status
│
├── User Management
│   ├── Add FTP user
│   ├── Delete FTP user
│   ├── Change password
│   ├── Lock user
│   └── List FTP users
│
├── Configuration
│   ├── Anonymous access
│   ├── Upload permission
│   ├── Download permission
│   ├── Passive mode
│   └── Port configuration
│
├── Security
│   ├── Firewall
│   ├── SELinux
│   ├── Chroot
│   └── Login restrictions
│
├── Monitoring
│   ├── Service status
│   ├── FTP connections
│   ├── Logs
│   └── Disk usage
│
└── Backup
    ├── Backup config
    └── Restore config
```

Như vậy đề tài không còn chỉ là:

> “script cài FTP”

mà đúng hơn là:

> **Automated FTP Server Administration Tool for CentOS**

Đây sẽ là scope đẹp hơn để demo/bảo vệ.

## Việc nên làm ngay bây giờ

**Chưa cần copy toàn bộ script phía trên.**

Trên CentOS của bạn hãy chạy lần lượt:

```bash
cat /etc/os-release
```

```bash
ip addr
```

```bash
sudo dnf install vsftpd -y
```

```bash
sudo systemctl enable --now vsftpd
```

```bash
sudo systemctl status vsftpd
```

Sau đó gửi output của các command này để tiếp tục với **Bước 2: cấu hình vsftpd đúng chuẩn + test FTP client**, rồi sau đó xây `ftp_manager.sh` từng module thay vì copy một script lớn mà chưa hiểu nó.
'''

path = "/mnt/data/README.md"
with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print(path)
