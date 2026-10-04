# Nhom firewall va bao mat

Module: `modules/security.sh`.

## Cong cu

- Xem zone hien tai, mo/dong FTP service va mo passive TCP range tren firewalld.
- Xem trang thai/boolean SELinux, bat `ftpd_full_access` khi bai lab can ghi home.
- Them/bo user trong `/etc/vsftpd/user_list`.

`ftpd_full_access` cap quyen rong cho daemon. Uu tien gan SELinux label dung nhu cau
trong he thong that; option nay duoc giu de bai lab co the demo nhanh.

Danh sach chan hoat dong theo cau hinh CentOS mac dinh (`userlist_enable=YES`,
`userlist_deny=YES`). Neu da thay doi hai key nay, can kiem tra lai y nghia danh sach.
