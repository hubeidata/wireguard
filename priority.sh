# marcar paquetes RTP destino 5004
sudo iptables -t mangle -A PREROUTING -p udp --dport 5004 -j MARK --set-mark 10

# qdisc simple HTB
sudo tc qdisc add dev eth0 root handle 1: htb default 20
sudo tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit
sudo tc class add dev eth0 parent 1:1 classid 1:10 htb rate 80mbit ceil 100mbit
sudo tc class add dev eth0 parent 1:1 classid 1:20 htb rate 20mbit

# filtrar marca a clase prioritaria
sudo tc filter add dev eth0 parent 1:0 prio 1 handle 10 fw flowid 1:10