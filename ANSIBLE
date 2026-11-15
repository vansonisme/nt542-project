# Hướng dẫn chạy Ansible – CIS Audit & Remediation

Tài liệu này hướng dẫn kiểm tra kết nối, chạy audit, chạy remediation và xem report cho project `nt542-project`. Giả định hạ tầng đã được triển khai và SSH đã được cấu hình (xem `README.md`, Bước 1 đến 9).

## 1. Yêu cầu

- Ansible đã cài trên máy local.
- Các SSH Host `loadbalancer`, `webserver1`, `webserver2` đã kết nối được (`ssh loadbalancer`).
- Chạy mọi lệnh **tại thư mục gốc project** để Ansible nhận `ansible.cfg`.

## 2. Cấu trúc liên quan

```text
nt542-project/
├── ansible/
│   └── inventory.ini
├── ansible.cfg
├── playbooks/
│   ├── audit.yaml
│   └── remediate.yaml
├── scripts/
│   ├── audit/            # audit_<CIS>.sh
│   └── remediate/        # remediate_<CIS>.sh
└── reports/              # sinh ra sau khi chạy
```

CIS hiện có:

| CIS | Nội dung |
|---|---|
| 2.2 | Ensure the Log Config Module Is Enabled |
| 3.2 | Ensure the Apache User Account Has an Invalid Shell |
| 3.11 | Ensure Group Write Access for the Apache Directories and Files Is Properly Restricted |
| 7.1 | Ensure mod_ssl and/or mod_nss Is Installed |

## 3. Kiểm tra kết nối

```bash
ansible all --list-hosts
ansible all -m ping
ansible loadbalancers -m ping
ansible webservers -m ping
```

Kết quả mong đợi: mọi host trả về `SUCCESS` và `ping: pong`.

## 4. Tham số dùng chung

Cả `audit.yaml` và `remediate.yaml` nhận cùng các tham số:

| Tham số | Ý nghĩa | Mặc định |
|---|---|---|
| `target` | Host hoặc nhóm trong inventory | `all` |
| `cis` | Danh sách CIS, cách nhau bằng dấu phẩy, hoặc `all` | `all` |

## 5. Chạy Audit

Audit chỉ kiểm tra, **không thay đổi** hệ thống.

```bash
# Tất cả CIS, tất cả máy chủ
ansible-playbook playbooks/audit.yaml

# Theo nhóm hoặc máy chủ
ansible-playbook playbooks/audit.yaml -e target=webservers
ansible-playbook playbooks/audit.yaml -e target=webserver1

# Một số CIS cụ thể
ansible-playbook playbooks/audit.yaml -e cis=2.2,3.2

# Kết hợp
ansible-playbook playbooks/audit.yaml -e target=webservers -e cis=7.1
```

## 6. Chạy Remediation

Remediation **thay đổi cấu hình** máy chủ: đổi shell của user `apache`, sửa `LoadModule`, cài `mod_ssl`, restart `httpd`, bỏ quyền ghi nhóm. Nên chạy audit trước.

```bash
ansible-playbook playbooks/remediate.yaml
ansible-playbook playbooks/remediate.yaml -e target=webservers -e cis=3.2
ansible-playbook playbooks/remediate.yaml -e target=webserver1 -e cis=2.2,7.1
```

Sau khi sửa, chạy lại audit để xác nhận:

```bash
ansible-playbook playbooks/audit.yaml
```

## 7. Xem report

Report được lưu trong `reports/`:

| File | Nội dung |
|---|---|
| `audit_<host>.txt` | Chi tiết audit từng máy chủ |
| `audit_report.csv` | Tổng hợp audit (PASS, FAIL) |
| `remediate_<host>.txt` | Chi tiết remediation từng máy chủ |
| `remediate_report.csv` | Tổng hợp remediation (PASS, REMEDIATED, FAIL) |

```bash
ls reports/
cat reports/audit_webserver1.txt
```

Ví dụ nội dung:

```text
========== AUDIT REPORT - SERVER: webserver1 ==========
────────────────────────────────────────
CIS Check: 2.2
  [PASS] log_config_module is loaded (Current: loaded | Expected: loaded)
────────────────────────────────────────
TỔNG KẾT: 1 PASS | 0 FAIL
```

Xem CSV dạng bảng (cần `csvkit`):

```bash
sudo apt install csvkit
csvlook --no-inference reports/audit_report.csv
```

Dùng `--no-inference` để cột `check` không bị hiển thị `2.20`, `3.20`, `7.10`. File CSV gốc vẫn đúng.

Chỉ liệt kê check FAIL (audit) hoặc check vừa được sửa (remediate):

```bash
grep ',FAIL,' reports/audit_report.csv
grep ',REMEDIATED,' reports/remediate_report.csv
```

Ghi chú:

- Mỗi lần chạy **ghi đè** CSV và `.txt` của lượt trước. Muốn giữ lịch sử thì copy sang thư mục khác trước khi chạy lại.
- CSV chỉ chứa host trong lượt chạy hiện tại.
- Thư mục `reports/` được playbook tự tạo ở lần chạy đầu tiên.
- Host không kết nối được (`UNREACHABLE`) hoặc không có dòng `[PASS]`/`[FAIL]`/`[REMEDIATED]` sẽ không có dòng nào trong CSV; Ansible vẫn in lỗi ở cuối lần chạy.
- Tên host dùng trong `target` là tên trong inventory (ví dụ `loadbalancer`, `webserver1`, `webserver2`); xem bằng `ansible all --list-hosts`.

## 8. Thêm CIS mới

1. Tạo `scripts/audit/audit_<id>.sh` và `scripts/remediate/remediate_<id>.sh`.
2. Mỗi script in **đúng một dòng trạng thái** bắt đầu bằng `[PASS]`, `[FAIL]` hoặc `[REMEDIATED]`, theo dạng:

```text
[PASS] <mô tả> (Current: X | Expected: Y)
```

3. Exit code: `0` cho PASS và REMEDIATED, `1` cho FAIL.
4. Không cần sửa playbook, vì playbook tự tìm file theo mẫu `audit_*.sh` và `remediate_*.sh`.

Dòng trạng thái phải đứng đầu dòng; playbook dựa vào đó để tạo tổng kết và CSV.
