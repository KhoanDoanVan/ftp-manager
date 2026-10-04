# Nhom quan ly nguoi dung

Module: `modules/users.sh`.

User moi co cau truc:

```text
/home/<user>/ftp          root:root, 755 (chroot root khong ghi duoc)
/home/<user>/ftp/upload   <user>:<user> (vung upload)
```

## Cong cu

Tao/xoa user, doi password, khoa/mo khoa tai khoan, liet ke user thuong va xem noi
dung FTP home. Username chi nhan chu thuong, so, `_`, `-`, toi da 32 ky tu.

Xoa user la thao tac mat du lieu nen chuong trinh luon yeu cau xac nhan.
