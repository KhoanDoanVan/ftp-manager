# Kịch bản demo - Auto Script quản lý FTP Server

Tài liệu này **chỉ dùng cho phần demo công cụ quản lý**. Không trình bày lại quá trình
cài package, sửa `vsftpd.conf`, tạo zone BIND hoặc cấu hình firewall ban đầu.

Phần cấu hình hệ thống từ A-Z với domain `ftp.sgu.edu.vn` nằm tại
[docs/SETUP_SGU.md](docs/SETUP_SGU.md) và phải hoàn thành trước buổi demo.

## 1. Phạm vi trình bày

Tên đề tài nên giới thiệu là:

> **Xây dựng Auto Script quản lý FTP Server trên CentOS.**

Mục tiêu buổi demo là chứng minh quản trị viên có thể dùng một giao diện terminal để:

- Kiểm tra tổng quan FTP Server.
- Quản lý vòng đời dịch vụ.
- Tạo, khóa, mở khóa và kiểm tra FTP user.
- Gán quyền read-only hoặc read-write.
- Upload, download và quản lý file remote.
- Chứng minh anonymous, local user và blocked user có quyền khác nhau.
- Theo dõi connection, socket và log.
- Chạy health check.
- Backup và kiểm tra archive cấu hình.

Không demo các việc sau vì đã làm ở giai đoạn chuẩn bị:

- Cài CentOS, `vsftpd`, BIND hoặc `lftp`.
- Nhập toàn bộ `vsftpd.conf`.
- Tạo zone `sgu.edu.vn`.
- Cấu hình card mạng, DNS client hoặc firewall lần đầu.
- Tắt firewall hay tắt SELinux.

## 2. Trạng thái phải có trước khi bắt đầu

Sử dụng domain và user mẫu:

```text
FTP Server : ftp.sgu.edu.vn
FTP/DNS IP : 192.168.10.2 (enp26s0 - Private to My Mac)
Internet   : 192.168.65.129 (enp2s0 - Share with My Mac, DHCP)
FTP port   : 21
FTP user   : itadmin
FTP path   : /home/itadmin/ftp/upload
Passive    : 30000-31000
```

Kiểm tra nhanh trước khi lên trình bày:

```bash
cd ~/ftp-manager
bash tests/smoke_test.sh
systemctl is-active vsftpd
systemctl is-active named
dig +short @127.0.0.1 ftp.sgu.edu.vn A
sudo firewall-cmd --query-service=ftp
sudo firewall-cmd --query-port=30000-31000/tcp
```

Kết quả phải có:

```text
Smoke tests: PASS
active
active
192.168.10.2
yes
yes
```

Chuẩn bị file demo:

```bash
echo "FTP Manager upload demo" > /tmp/ftp-upload-demo.txt
mkdir -p /tmp/ftp-demo-folder
echo "file one" > /tmp/ftp-demo-folder/one.txt
echo "file two" > /tmp/ftp-demo-folder/two.txt
```

## 3. Mở đầu bài demo - khoảng 1 phút

Chạy:

```bash
sudo ./ftp_manager.sh
```

Giới thiệu ngắn:

> Project chia nghiệp vụ quản trị FTP thành các module độc lập. Entry point chỉ điều
> hướng menu; mỗi nhóm dịch vụ, user, quyền, transfer, bảo mật, monitoring, DNS và
> backup nằm trong một file riêng. Các thao tác thay đổi hệ thống tự dùng quyền root,
> còn password FTP không được lưu lâu dài.

Menu chính:

```text
  1) Dich vu & cai dat
  2) Quan ly nguoi dung
  3) Quyen truy cap FTP
  4) Cau hinh FTP
  5) Firewall & bao mat
  6) Giam sat & nhat ky
  7) Truyen file FTP
  8) DNS BIND
  9) Sao luu & khoi phuc
 10) Chan doan ket noi
 11) Tong quan nhanh
  0) Thoat
```

Trong phần demo không chọn menu cài đặt `1 -> 1` hoặc tạo DNS zone mới. Hệ thống đã
được chuẩn bị trước.

## 4. Demo 1 - Tổng quan và trạng thái dịch vụ

### Thao tác

1. Chọn `11` - **Tổng quan nhanh**.
2. Chọn `1 -> 6` - **Xem trạng thái**.
3. Chọn `1 -> 7` - **Xem phiên bản gói**.

### Nội dung cần chỉ ra

- Hostname của CentOS Server.
- IP server.
- `vsftpd` đang active.
- Control port `21`.
- Passive range `30000-31000`.
- Đường dẫn `/etc/vsftpd/vsftpd.conf`.

Có thể nói:

> Thay vì nhớ nhiều lệnh `systemctl`, quản trị viên xem trạng thái và điều khiển dịch
> vụ từ cùng một menu. Tool vẫn cung cấp start, stop, restart và enable, nhưng trong
> demo tôi không stop để tránh làm gián đoạn các phần sau.

## 5. Demo 2 - Quản lý user bằng auto script

### 5.1. Xem user đã chuẩn bị

1. Chọn `2 -> 3` - **Liệt kê user thường**.
2. Chỉ ra user `itadmin` và home `/home/itadmin`.
3. Chọn `2 -> 7`, nhập `itadmin`.

Kết quả phải thấy thư mục `ftp/upload`.

### 5.2. Tạo một user demo

1. Chọn `2 -> 1`.
2. Nhập `ftp_demo`.
3. Đặt password tạm.
4. Chọn lại `2 -> 3` để chứng minh user được tạo.

Giải thích:

```text
/home/ftp_demo/ftp          root:root, không cho user ghi vào gốc chroot
/home/ftp_demo/ftp/upload   ftp_demo:ftp_demo, vùng upload
```

Không xóa user ngay. Giữ `ftp_demo` cho phần demo phân quyền, sau đó mới dọn dẹp.

### 5.3. Khóa và mở khóa

1. Chọn `2 -> 5`, nhập `ftp_demo`.
2. Chọn `3 -> 8`, nhập `ftp_demo`; trạng thái phải là `L`.
3. Chọn `2 -> 6` để mở khóa.
4. Kiểm tra lại `3 -> 8`; trạng thái có password là `P`.

Phải dùng `2 -> 6` cho trạng thái `L`. Menu `5 -> 8` chỉ bỏ user khỏi danh sách
chặn của `vsftpd`, không mở khóa password của Linux. Chức năng `2 -> 6` sẽ kiểm tra
lại trạng thái; nếu `usermod -U` chưa đủ, tool thử `passwd -u` và đề nghị đặt password
mới khi account vẫn chưa về `P`.

Điểm cần nhấn mạnh: khóa account không xóa dữ liệu; đây là thao tác phù hợp khi cần
thu hồi quyền đăng nhập tạm thời.

## 6. Demo 3 - Quản lý quyền truy cập

### 6.1. Xem ma trận quyền

Chọn `3 -> 1`.

Giải thích năm vai trò:

1. `root/sudo admin`: quản trị server, không dùng để login FTP.
2. Local read-write: upload/download trong `ftp/upload`.
3. Local read-only: list/download, không upload.
4. Anonymous: quyền phụ thuộc profile được bật.
5. Locked/blocked: không đăng nhập được.

### 6.2. Kiểm tra quyền read-write của `itadmin`

1. Chọn `3 -> 6`, nhập `itadmin`.
2. Chọn `3 -> 7`, nhập `itadmin`.

Chỉ ra rằng gốc `ftp` thuộc root còn `upload` thuộc `itadmin`. Đây là cấu trúc vừa
đáp ứng chroot vừa cho phép truyền file.

## 7. Demo 4 - Upload và download hoàn toàn bằng terminal

Đây là phần trọng tâm để chứng minh project không phụ thuộc FileZilla.

### 7.1. Tạo profile kết nối

Chọn `7 -> 2`, nhập:

```text
FTP host: ftp.sgu.edu.vn
Control port: 21
Username: itadmin
TLS mode: 1
```

Chọn `7 -> 3` để xem profile. Tool không hiển thị hoặc lưu password.

### 7.2. List remote

Chọn `7 -> 4`, nhập remote path:

```text
/
```

Sau đó list:

```text
ftp/upload
```

### 7.3. Upload

Chọn `7 -> 5`:

```text
Local file: /tmp/ftp-upload-demo.txt
Remote file: ftp/upload/ftp-upload-demo.txt
```

Nhập password của `itadmin`. Kết quả cần có thông báo upload thành công.

### 7.4. Download

Chọn `7 -> 6`:

```text
Remote file: ftp/upload/ftp-upload-demo.txt
Local file: /tmp/ftp-downloaded.txt
```

Đối chiếu ngoài menu:

```bash
cat /tmp/ftp-downloaded.txt
```

Nội dung phải là:

```text
FTP Manager upload demo
```

### 7.5. Quản lý file remote

Thực hiện ngắn gọn:

1. `7 -> 9`: tạo `ftp/upload/demo-directory`.
2. `7 -> 10`: đổi tên thành `ftp/upload/renamed-directory`.
3. `7 -> 7`: mirror `/tmp/ftp-demo-folder` lên
   `ftp/upload/renamed-directory`.
4. `7 -> 4`: list thư mục để thấy `one.txt`, `two.txt`.
5. `7 -> 8`: mirror thư mục đó về `/tmp/ftp-mirror-download`.

Không cần demo xóa file nếu thời gian ngắn. Menu `7 -> 11` có xác nhận trước khi xóa
remote file.

### 7.6. Test quyền tự động

Chọn `7 -> 12`, nhập:

```text
ftp/upload
```

Kết quả cho user read-write:

```text
[OK] READ/LIST: cho phep
[OK] WRITE/DELETE: cho phep
```

Tool tự upload một file test tạm, xóa file đó và báo hai quyền riêng biệt.

## 8. Demo 5 - Chuyển user thành read-only

Sử dụng `ftp_demo`, không thay đổi quyền của user chính `itadmin`.

### Thao tác

1. Chọn `3 -> 5`, nhập `ftp_demo` và xác nhận.
2. Chọn `3 -> 7` để xem owner/mode.
3. Chọn `7 -> 2`, đổi profile sang `ftp_demo`.
4. Chọn `7 -> 12`, test tại `ftp/upload`.

Kết quả mong đợi:

```text
[OK] READ/LIST: cho phep
[WARN] WRITE/DELETE: bi tu choi
```

Giải thích:

> Tool không chỉ thay đổi một biến trong config. Nó áp dụng quyền filesystem thật,
> vì vậy cùng một FTP Server nhưng từng user có thể có mức truy cập khác nhau.

Sau khi chứng minh, chọn `3 -> 6` cho `ftp_demo` nếu muốn trả lại quyền ghi.

## 9. Demo 6 - Anonymous read-only

Anonymous đã được chuẩn bị sẵn với `/var/ftp/pub/readme.txt`.

### Thao tác

1. Chọn `3 -> 2` để bảo đảm anonymous ở chế độ chỉ đọc.
2. Chọn `4 -> 9` để restart và áp dụng.
3. Chọn `7 -> 2`:

   ```text
   Host: ftp.sgu.edu.vn
   Port: 21
   Username: anonymous
   TLS: off
   ```

4. Chọn `7 -> 4`, list `/pub`.
5. Chọn `7 -> 6`, download `/pub/readme.txt`.
6. Chọn `7 -> 12`, test `/pub`.

Kết quả:

```text
READ/LIST: cho phep
WRITE/DELETE: bi tu choi
```

Nếu cần minh họa hộp nhận file, menu `3 -> 3` bật anonymous upload cô lập tại
`/var/ftp/upload`. File được tạo với `umask 077` nên anonymous khác không đọc lại
được. Đây là phần mở rộng, không cần demo nếu thời gian giới hạn.

Sau phần anonymous, chọn `3 -> 4` rồi `4 -> 9` nếu muốn tắt anonymous.

## 10. Demo 7 - Chặn user ở lớp vsftpd

Phần này khác khóa account ở hệ điều hành.

1. Chọn `5 -> 7`, nhập `ftp_demo`.
2. Chọn `5 -> 9` để thấy user trong `/etc/vsftpd/user_list`.
3. Chọn `4 -> 9` để restart.
4. Cấu hình profile transfer là `ftp_demo` và thử `7 -> 4`.
5. Login phải bị từ chối.
6. Chọn `5 -> 8` để bỏ chặn và restart lại.

Giải thích:

> Khóa bằng `usermod -L` tác động ở lớp account Linux; `user_list` là chính sách của
> riêng vsftpd. Script quản lý được cả hai lớp.

Phần này giả định `userlist_enable=YES` và `userlist_deny=YES`.

## 11. Demo 8 - Monitoring trong lúc transfer

Mở terminal thứ hai và chạy `sudo ./ftp_manager.sh`. Giữ một phiên transfer hoặc
thực hiện upload ở terminal thứ nhất.

Trong terminal quản trị:

1. `6 -> 1`: tổng quan.
2. `6 -> 3`: port đang LISTEN.
3. `6 -> 4`: connection FTP hiện tại.
4. `6 -> 5`: 50 dòng journal gần nhất.
5. `6 -> 6`: transfer log.
6. `6 -> 7`: dung lượng FTP homes.
7. `6 -> 8`: follow log; nhấn `Ctrl+C` để dừng.

Nếu `/var/log/xferlog` chưa có, dùng journal. File này phụ thuộc các key
`xferlog_enable` và `dual_log_enable` trong config nền.

## 12. Demo 9 - Health check

Chọn `10 -> 1`.

Tool kiểm tra:

- Commands và package bắt buộc.
- Các tool tùy chọn như `curl`, `lftp`, `named-checkconf`, `dig`.
- Trạng thái `vsftpd`.
- Các key config quan trọng.
- Control port đang LISTEN.
- Firewall FTP.
- Dung lượng storage.

Có thể mở thêm:

| Menu | Nội dung |
|---|---|
| `10 -> 3` | Audit từng key FTP |
| `10 -> 4` | Kiểm tra control port |
| `10 -> 6` | Xem địa chỉ mạng |
| `10 -> 7` | Kiểm tra permission FTP homes |

`10 -> 5` dùng anonymous để test localhost; khi anonymous đã tắt, warning ở bước này
không có nghĩa local user hoặc server bị hỏng.

## 13. Demo 10 - Backup cấu hình

### Thao tác

1. Chọn `9 -> 1` để tạo config archive.
2. Chọn `9 -> 2` để liệt kê backup.
3. Copy đường dẫn `config-<timestamp>.tar.gz` vừa tạo.
4. Chọn `9 -> 5`, nhập đường dẫn để xem nội dung.

Archive gồm:

- `vsftpd.conf`.
- `user_list` nếu tồn tại.
- Metadata gồm hostname, thời gian và phiên bản tool.

Chỉ giải thích menu `9 -> 3` restore, không nên restore thật trong demo nếu hệ thống
đang hoạt động ổn. Menu `9 -> 4` backup toàn bộ `/home/*/ftp`.

## 14. DNS trong phần demo

Không demo quá trình cài và tạo zone BIND. Chỉ dùng domain để chứng minh hệ thống đã
được tích hợp.

Có thể dành khoảng 30 giây:

1. Chọn `8 -> 6` để cho thấy `named` đang active.
2. Chọn `8 -> 7`:

   ```text
   FQDN: ftp.sgu.edu.vn
   DNS server: 127.0.0.1
   ```

3. Chỉ ra kết quả trả về IP FTP Server.

Không chọn `8 -> 1/2/3/4` trong demo vì đó là các công cụ setup.

## 15. Kịch bản trình bày rút gọn 10-12 phút

Nếu thời gian giới hạn, dùng thứ tự sau:

| Thời gian | Nội dung | Menu |
|---:|---|---|
| 1 phút | Giới thiệu kiến trúc và tổng quan | `11` |
| 1 phút | Service status và user list | `1 -> 6`, `2 -> 3` |
| 1 phút | Ma trận và permission user | `3 -> 1`, `3 -> 7` |
| 3 phút | List, upload, download, test quyền | `7 -> 4/5/6/12` |
| 1 phút | Chuyển user read-only và test bị từ chối | `3 -> 5`, `7 -> 12` |
| 1 phút | Anonymous read-only | `3 -> 2`, `7 -> 4/12` |
| 1 phút | Monitoring và log | `6 -> 3/4/5` |
| 1 phút | Health check | `10 -> 1` |
| 1 phút | Backup và xem archive | `9 -> 1/2/5` |
| 30 giây | DNS lookup `ftp.sgu.edu.vn` | `8 -> 7` |

Nếu chỉ có 7-8 phút, bỏ phần tạo user mới, anonymous và DNS status; tập trung vào
transfer, phân quyền, monitoring, health check và backup.

## 16. Các câu hỏi phản biện thường gặp

### Vì sao không dùng FileZilla?

FileZilla là GUI client, còn mục tiêu đề tài là automation bằng Bash. Module transfer
dùng `lftp` để script hóa list, upload, download, mirror và kiểm thử quyền. FileZilla
vẫn có thể kết nối nhưng không phải thành phần chính của project.

### Vì sao không tắt firewall và SELinux?

Tắt chúng làm demo dễ hơn nhưng không thể hiện đúng quản trị server. Project mở đúng
service/port trên firewall và chỉ thay SELinux boolean khi cần.

### Password FTP được lưu ở đâu?

Password không lưu trong profile. Mỗi thao tác hỏi lại password, ghi vào command file
tạm mode `600`, chạy `lftp` rồi xóa file.

### Vì sao gốc `ftp` thuộc root?

`vsftpd` chroot không nên cho local user ghi vào gốc jail. User chỉ ghi trong thư mục
con `upload` thuộc chính user đó.

### Read-only được thực hiện như thế nào?

Tool đổi owner cây FTP về `root:root` và bỏ quyền ghi. Đây là quyền filesystem thật,
không chỉ là trạng thái hiển thị trong menu.

### Anonymous upload có nguy hiểm không?

Có. Vì vậy mặc định chỉ bật anonymous read-only. Khi bật upload, tool dùng thư mục
riêng mode `733`, `anon_umask=077` và không cho anonymous đọc lại file không
world-readable.

### DNS có bắt buộc để FTP hoạt động không?

Không. FTP hoạt động qua IP. BIND chỉ cung cấp tên dễ nhớ `ftp.sgu.edu.vn` và chứng
minh khả năng tích hợp dịch vụ mạng.

## 17. Xử lý lỗi ngay trong demo

| Lỗi | Xử lý nhanh |
|---|---|
| Connection refused | `1 -> 6`, `6 -> 3`, `10 -> 4` |
| Timeout khi list | Kiểm tra passive range bằng `4 -> 1`, firewall `5 -> 1` |
| Login bị từ chối | `3 -> 8`, `5 -> 9`, kiểm tra password |
| Upload bị từ chối | Xác nhận user không ở read-only; `3 -> 7`, `4 -> 1` |
| DNS không resolve | Dùng IP tạm; kiểm tra sau bằng `8 -> 6/7` |
| Không có `xferlog` | Dùng journal ở `6 -> 5` |
| Health check cảnh báo anonymous | Bình thường nếu anonymous đã tắt |
| FTPS certificate warning | Demo nền đang dùng plain FTP; không bật TLS giữa bài |

Nếu lỗi không xử lý được trong 30-60 giây, chuyển sang IP `127.0.0.1` để tiếp tục
chứng minh module transfer, rồi giải thích lỗi nằm ở mạng/DNS chứ không phải logic
quản lý FTP.

## 18. Kết thúc và dọn dữ liệu demo

Sau phần trình bày:

1. Bỏ chặn `ftp_demo` nếu còn trong `user_list` bằng `5 -> 8`.
2. Mở khóa user nếu còn bị khóa bằng `2 -> 6`.
3. Tắt anonymous bằng `3 -> 4`, restart bằng `4 -> 9` nếu không cần giữ.
4. Chọn `2 -> 2` để xóa `ftp_demo` và home sau khi xác nhận không cần dữ liệu.
5. Giữ user chính `itadmin` và các archive backup.

## 19. Checklist trước khi đứng demo

- [ ] Đã hoàn thành [setup SGU A-Z](docs/SETUP_SGU.md).
- [ ] `ftp.sgu.edu.vn` resolve đúng IP.
- [ ] `vsftpd` và `named` active.
- [ ] User `itadmin` login và upload được.
- [ ] File `/tmp/ftp-upload-demo.txt` đã tồn tại.
- [ ] Passive ports và firewall hoạt động.
- [ ] `bash tests/smoke_test.sh` trả về PASS.
- [ ] Đã tập luồng demo rút gọn ít nhất một lần.
- [ ] Không còn user demo bị khóa/chặn từ lần chạy trước.
- [ ] Có sẵn IP `127.0.0.1` làm phương án dự phòng nếu DNS/mạng lỗi.
