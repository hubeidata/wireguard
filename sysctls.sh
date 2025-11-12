# en la instancia EC2 (bash)
sudo tee /etc/sysctl.d/99-wireguard.conf > /dev/null <<'EOF'
net.ipv4.ip_forward=1
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.netdev_max_backlog=5000
net.netfilter.nf_conntrack_max=262144
net.netfilter.nf_conntrack_udp_timeout=30
EOF

sudo sysctl --system
sudo docker-compose up -d wireguard