# Nhom giam sat va chan doan

Modules: `modules/monitoring.sh`, `modules/diagnostics.sh`.

## Giam sat

Tong quan hostname/IP/service/port, socket dang listen, connection hien tai,
`journalctl`, `xferlog`, disk usage va che do follow log.

## Chan doan

Health check gom dependency, service, config audit, listening port, firewall va disk.
Ngoai ra co test localhost bang `curl`, hien thi interface va kiem tra owner/mode cac
FTP home. Test anonymous co the bi tu choi du service van khoe; tool se bao day la
canh bao thay vi ket luan server hong.

Kich ban demo goi y: chay `7 > 1`, sua tung loi do health check neu ra, sau do chay
lai de trinh bay trang thai he thong.
