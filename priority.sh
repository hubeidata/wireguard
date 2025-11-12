#!/usr/bin/env bash
set -euo pipefail

# priority.sh
# - marca paquetes RTP destino 5004 y aplica qdisc HTB
# - detecta interfaz por defecto, valida dependencias y evita duplicados

DEFAULT_ROUTE_IFACE() {
	# intenta obtener la interfaz usada para alcanzar Internet (8.8.8.8)
	ip route get 8.8.8.8 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -n1
}

if [[ $(id -u) -ne 0 ]]; then
	echo "This script must be run as root (use sudo)."
	exit 2
fi

IFACE="${1:-}"
if [[ -z "$IFACE" ]]; then
	IFACE=$(DEFAULT_ROUTE_IFACE || true)
fi
IFACE=${IFACE:-eth0}

echo "Using interface: $IFACE"

for cmd in tc iptables ip route; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Required command not found: $cmd"
		echo "On Amazon Linux 2023 install with: sudo dnf install -y iproute iptables" 
		exit 3
	fi
done

# 1) marcar paquetes RTP destino 5004 (idempotente)
if iptables -t mangle -C PREROUTING -p udp --dport 5004 -j MARK --set-mark 10 2>/dev/null; then
	echo "iptables rule already present"
else
	echo "Adding iptables mangle rule for UDP/5004"
	iptables -t mangle -A PREROUTING -p udp --dport 5004 -j MARK --set-mark 10
fi

# 2) qdisc simple HTB
if tc qdisc show dev "$IFACE" 2>/dev/null | grep -q "htb"; then
	echo "HTB qdisc already present on $IFACE"
else
	echo "Setting HTB qdisc on $IFACE"
	# remove any existing root qdisc first (best-effort)
	tc qdisc del dev "$IFACE" root 2>/dev/null || true
	tc qdisc add dev "$IFACE" root handle 1: htb default 20
fi

if tc class show dev "$IFACE" | grep -q "1:1"; then
	echo "HTB classes already present"
else
	tc class add dev "$IFACE" parent 1: classid 1:1 htb rate 100mbit
	tc class add dev "$IFACE" parent 1:1 classid 1:10 htb rate 80mbit ceil 100mbit
	tc class add dev "$IFACE" parent 1:1 classid 1:20 htb rate 20mbit
fi

# 3) filtrar marca a clase prioritaria (idempotente)
if tc filter show dev "$IFACE" | grep -q "handle 10"; then
	echo "tc filter for handle 10 already present"
else
	tc filter add dev "$IFACE" parent 1:0 prio 1 handle 10 fw flowid 1:10
fi

echo "Priority rules applied."

# End of script