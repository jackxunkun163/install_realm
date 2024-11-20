#!/bin/bash

# 安装 wget
echo "安装 wget..."
sudo apt update
sudo apt install -y wget

# 下载 realm
echo "下载 realm-x86_64-unknown-linux-musl.tar.gz..."
wget https://github.com/zhboner/realm/releases/download/v2.6.3/realm-x86_64-unknown-linux-musl.tar.gz

# 解压 realm
echo "解压 realm..."
tar -xvf realm-x86_64-unknown-linux-musl.tar.gz
chmod +x realm

# 移动到 /root 并新建 config.toml
echo "在 /root 创建 config.toml 文件..."
sudo mv realm /root/
sudo bash -c 'cat > /root/config.toml' << EOF
[network]
no_tcp = false
use_udp = true

[[endpoints]]
listen = "2409:8c5c:110:73::3037:36547"
remote = "[2A13:82C2:0001:1b7e:0000:0000:0000:0001]:45794"
EOF

# 获取用户输入
echo "请输入源 IP 和端口（例如 2409:abcd:1234:5678::1:12345）："
read -p "源 IP 和端口：" source_ip_port
echo "请输入目标 IP 和端口（例如 [2A13:abcd:5678::1]:12345）："
read -p "目标 IP 和端口：" target_ip_port

# 替换 config.toml 文件中的 IP 和端口
echo "替换 config.toml 文件中的 IP 和端口..."
sudo sed -i "s|2409:8c5c:110:73::3037:36547|$source_ip_port|g" /root/config.toml
sudo sed -i "s|\[2A13:82C2:0001:1b7e:0000:0000:0000:0001\]:45794|$target_ip_port|g" /root/config.toml

# 创建 realm.service 文件
echo "在 /etc/systemd/system 创建 realm.service 文件..."
sudo bash -c 'cat > /etc/systemd/system/realm.service' << EOF
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
DynamicUser=true
WorkingDirectory=/root
ExecStart=/root/realm -c /root/config.toml

[Install]
WantedBy=multi-user.target
EOF

# 启动和配置服务
echo "加载 systemctl 配置..."
sudo systemctl daemon-reload
sudo systemctl enable realm
sudo systemctl restart realm

# 查看服务状态
echo "服务状态："
sudo systemctl status realm

