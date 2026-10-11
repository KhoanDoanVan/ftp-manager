# Nhóm DNS BIND cho FTP

Module: `modules/dns.sh`.

Nhóm này tự động hóa phần BIND trong tài liệu tham khảo: cài `bind`/`bind-utils`, cho
client LAN truy vấn, tạo primary zone, thêm bản ghi `ftp`, validate, mở DNS firewall
và test bằng `dig` hoặc `nslookup`.

Khác với cách đặt `allow-query { any; };`, tool yêu cầu CIDR LAN và sinh:

```conf
listen-on port 53 { any; };
allow-query { localhost; 192.168.1.0/24; };
```

Zone do tool quản lý nằm tại `/var/named/ftp-manager-<zone>.zone`; khai báo zone được
thêm vào `/etc/named.rfc1912.zones`. Tool chạy `named-checkconf` và
`named-checkzone` trước khi restart.

DNS là phần tùy chọn. FTP vẫn hoạt động bằng địa chỉ IP nếu không cấu hình BIND.
