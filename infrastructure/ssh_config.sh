#! /bin/bash

if [ -z "$1" ]; then
    echo "Lỗi: Vui lòng truyền đường dẫn của file .pem!"
    echo "Cách dùng: $0 <duong_dan_file_pem>"
    exit 1
fi

KEY_PATH=$(eval echo "$1")

if [ ! -f "$KEY_PATH" ]; then
    echo "Lỗi: Không tìm thấy file key tại: $KEY_PATH"
    exit 1
fi

LB_IP=$(aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=apache-load-balancer" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PublicIpAddress" --output text)

if [ -z "$LB_IP" ] || [ "$LB_IP" == "None" ]; then
    echo "Lỗi: Không tìm thấy Public IP cho instance apache-load-balancer!"
    exit 1
fi

echo "-> Đã tìm thấy Loadbalancer Public IP: $LB_IP"

mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 3. Ghi nội dung cấu hình vào ~/.ssh/config
cat << EOF > ~/.ssh/config
Host loadbalancer
    HostName $LB_IP
    User ec2-user
    IdentityFile ~/nt542/project/4444.pem

Host worker1
    HostName 10.0.2.10
    User ec2-user
    ProxyJump loadbalancer
    IdentityFile ~/nt542/project/4444.pem

Host worker2
    HostName 10.0.3.10
    User ec2-user
    ProxyJump loadbalancer
    IdentityFile ~/nt542/project/4444.pem
EOF

chmod 600 ~/.ssh/config

echo "==> Hoàn tất! Cấu hình file ~/.ssh/config với IP Loadbalancer là $LB_IP và key $KEY_PATH"

