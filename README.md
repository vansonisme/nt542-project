# NT542 Project – AWS Infrastructure Deployment

## 1. Giới thiệu

Project triển khai mô hình hạ tầng Web Server trên AWS bằng AWS CloudFormation và Ansible.

Mô hình bao gồm:

- 1 VPC.
- 1 Public Subnet triển khai Load Balancer.
- 2 Private Subnet triển khai 2 Web Server.
- 1 Internet Gateway.
- 1 NAT Gateway dùng chung cho 2 Private Subnet.
- 1 Apache Load Balancer sử dụng Reverse Proxy để phân phối request.
- 2 Apache Web Server (Worker).
- Ansible quản lý và kiểm tra các máy chủ từ máy local thông qua SSH.

### Mô hình triển khai

| Máy chủ | Địa chỉ IP | Vai trò |
|---|---|---|
| Load Balancer | Public IP, Private IP: `10.0.1.10` | Apache Reverse Proxy / Load Balancer |
| Worker 1 | `10.0.2.10` | Apache Web Server |
| Worker 2 | `10.0.3.10` | Apache Web Server |

**AWS Region:** `us-east-1`

## 2. Cấu trúc project

```text
nt542-project/
├── ansible/
│   ├── ansible.cfg
│   └── inventory.ini
├── infrastructure/
│   ├── ssh_config.sh
│   └── template.yaml
└── README.md
```

## 3. Yêu cầu trước khi triển khai

Máy local cần cài đặt:

- Git
- AWS CLI
- Ansible
- SSH Client

Kiểm tra phiên bản:

```bash
git --version
aws --version
ansible --version
```

Ngoài ra, cần chuẩn bị:

- AWS Access Key ID.
- AWS Secret Access Key.
- AWS Session Token (nếu sử dụng Temporary Credentials).
- EC2 Key Pair do người triển khai tự tạo trong region `us-east-1`.
- File private key `.pem` tương ứng với Key Pair.

## 4. Các bước triển khai

### Bước 1. Clone project từ GitHub

Clone nhánh `infrastructure` và di chuyển vào thư mục project:

```bash
git clone -b infrastructure https://github.com/vansonisme/nt542-project.git && cd nt542-project
```

### Bước 2. Cấu hình AWS Credentials

Tạo thư mục cấu hình AWS và mở file credentials:

```bash
mkdir -p ~/.aws && nano ~/.aws/credentials
```

Điền thông tin AWS:

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
aws_session_token = YOUR_SESSION_TOKEN
```

Nếu sử dụng credentials dài hạn thì không cần khai báo `aws_session_token`.

Phân quyền file:

```bash
chmod 600 ~/.aws/credentials
```

Kiểm tra kết nối AWS:

```bash
aws sts get-caller-identity
```

Nếu lệnh trả về thông tin tài khoản AWS thì quá trình xác thực thành công.

**Lưu ý:** Temporary credentials cần có Session Token và phải được cập nhật khi hết hạn.

### Bước 3. Kiểm tra EC2 Key Pair

Kiểm tra danh sách Key Pair trong region `us-east-1`:

```bash
aws ec2 describe-key-pairs \
  --region us-east-1 \
  --query "KeyPairs[].KeyName" \
  --output table
```

Đảm bảo Key Pair bạn muốn sử dụng đã được tạo trong region `us-east-1`.

### Bước 4. Validate CloudFormation Template

Kiểm tra tính hợp lệ của template trước khi triển khai:

```bash
aws cloudformation validate-template \
  --template-body file://infrastructure/template.yaml \
  --region us-east-1
```

Nếu AWS trả về thông tin template mà không có lỗi, có thể tiếp tục triển khai.

### Bước 5. Tạo CloudFormation Stack

Triển khai hạ tầng bằng lệnh:

```bash
aws cloudformation deploy \
  --template-file infrastructure/template.yaml \
  --stack-name nt542-project \
  --region us-east-1 \
  --parameter-overrides KeyName=YOUR_KEY_PAIR_NAME
```

Thay `YOUR_KEY_PAIR_NAME` bằng tên EC2 Key Pair đã tạo ở Bước 3.

Giải thích:

| Tham số | Ý nghĩa |
|---|---|
| `--template-file` | Đường dẫn CloudFormation template |
| `--stack-name` | Tên CloudFormation Stack |
| `--region` | AWS Region triển khai |
| `KeyName` | Tên EC2 Key Pair sử dụng cho các instance |

### Bước 6. Kiểm tra trạng thái Stack

Kiểm tra trạng thái triển khai:

```bash
aws cloudformation describe-stacks \
  --stack-name nt542-project \
  --region us-east-1 \
  --query "Stacks[0].StackStatus" \
  --output text
```

Trạng thái triển khai thành công:

- `CREATE_COMPLETE`: Stack được tạo thành công lần đầu.
- `UPDATE_COMPLETE`: Stack được cập nhật thành công.

Nếu có lỗi, xem các sự kiện của Stack:

```bash
aws cloudformation describe-stack-events \
  --stack-name nt542-project \
  --region us-east-1 \
  --max-items 15 \
  --output table
```

### Bước 7. Lấy thông tin Outputs

Sau khi Stack được tạo thành công, lấy thông tin các tài nguyên:

```bash
aws cloudformation describe-stacks \
  --stack-name nt542-project \
  --region us-east-1 \
  --query "Stacks[0].Outputs" \
  --output table
```

Các Outputs quan trọng:

| Output | Ý nghĩa |
|---|---|
| `WebsiteURL` | Địa chỉ truy cập website |
| `LoadBalancerPublicIp` | Public IP của Load Balancer |
| `LoadBalancerPrivateIp` | Private IP của Load Balancer |
| `Worker1PrivateIp` | Private IP Worker 1 |
| `Worker2PrivateIp` | Private IP Worker 2 |
| `LoadBalancerInstanceId` | EC2 Instance ID của Load Balancer |
| `Worker1InstanceId` | EC2 Instance ID Worker 1 |
| `Worker2InstanceId` | EC2 Instance ID Worker 2 |

Truy cập `WebsiteURL` bằng trình duyệt để kiểm tra Load Balancer.

### Bước 8. Cấu hình SSH

Cấp quyền thực thi cho script:

```bash
chmod +x infrastructure/ssh_config.sh
```

Chạy script với đường dẫn đến file private key `.pem` tương ứng với Key Pair đã sử dụng khi tạo Stack:

```bash
./infrastructure/ssh_config.sh ~/Downloads/your-key.pem
```

Thay `~/Downloads/your-key.pem` bằng đường dẫn thực tế đến file private key trên máy local.

Cấp quyền cho file private key:

```bash
chmod 400 ~/Downloads/your-key.pem
```

Script tự động cấu hình các SSH Host:

- `loadbalancer`
- `worker1`
- `worker2`

Kiểm tra cấu hình:

```bash
cat ~/.ssh/config
```

### Bước 9. Kiểm tra kết nối SSH

Kết nối đến Load Balancer:

```bash
ssh loadbalancer
```

Kết nối đến Worker 1:

```bash
ssh worker1
```

Kết nối đến Worker 2:

```bash
ssh worker2
```

Hai Worker nằm trong Private Subnet nên kết nối SSH được thực hiện thông qua Load Balancer bằng `ProxyJump`.

### Bước 10. Kiểm tra kết nối Ansible

Khai báo đường dẫn file cấu hình Ansible:

```bash
export ANSIBLE_CONFIG=ansible/ansible.cfg
```

Kiểm tra danh sách các host:

```bash
ansible all --list-hosts
```

Kiểm tra kết nối đến tất cả máy chủ:

```bash
ansible all -m ping
```

Kiểm tra riêng Load Balancer:

```bash
ansible loadbalancers -m ping
```

Kiểm tra riêng các Worker:

```bash
ansible workers -m ping
```

Kết quả mong đợi là các host đều trả về trạng thái `SUCCESS` và `ping: pong`.

## 5. Kiểm tra hoạt động Load Balancer

Truy cập địa chỉ `WebsiteURL` lấy từ CloudFormation Outputs.

Để kiểm tra khả năng phân phối request đến các Worker, chạy nhiều request:

```bash
for i in {1..10}; do
  curl -s http://LOAD_BALANCER_PUBLIC_IP
  echo
done
```

Thay `LOAD_BALANCER_PUBLIC_IP` bằng Public IP của Load Balancer.

Kết quả mong đợi là nội dung phản hồi từ Worker 1 và Worker 2.

## 6. Xóa CloudFormation Stack

Sau khi hoàn thành thực hành, xóa Stack để giải phóng các tài nguyên AWS và hạn chế chi phí phát sinh:

```bash
aws cloudformation delete-stack \
  --stack-name nt542-project \
  --region us-east-1
```

Theo dõi quá trình xóa:

```bash
aws cloudformation wait stack-delete-complete \
  --stack-name nt542-project \
  --region us-east-1
```

Kiểm tra lại Stack:

```bash
aws cloudformation describe-stacks \
  --stack-name nt542-project \
  --region us-east-1
```

Khi Stack đã được xóa, AWS sẽ trả về lỗi không tìm thấy Stack nếu truy vấn lại.

## 7. Lưu ý

- Các lệnh AWS CLI trong tài liệu sử dụng region `us-east-1`.
- EC2 Key Pair được sử dụng phải tồn tại trong region `us-east-1` trước khi tạo Stack.
- File `.pem` phải tương ứng với Key Pair đã khai báo khi triển khai CloudFormation.
- Temporary AWS credentials cần có Session Token.
- SSH đang được mở cho mọi IPv4 thông qua `0.0.0.0/0`; đây là cấu hình phục vụ môi trường thực hành, không khuyến nghị cho môi trường production.
- NAT Gateway, Elastic IP và EC2 có thể phát sinh chi phí trong thời gian tồn tại.
- Sau khi thay đổi CloudFormation template, có thể chạy lại lệnh deploy để cập nhật Stack hiện có.
