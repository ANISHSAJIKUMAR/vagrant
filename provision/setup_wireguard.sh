#!/usr/bin/env bash
set -euo pipefail

WG_SERVER_PUBLIC_IP="${WG_SERVER_PUBLIC_IP:-REPLACE_WITH_YOUR_PUBLIC_IP_OR_DNS}"
WG_PORT="${WG_PORT:-51820}"
WG_SUBNET="${WG_SUBNET:-10.8.0.0/24}"
WG_SERVER_ADDRESS="${WG_SERVER_ADDRESS:-10.8.0.1/24}"
WG_DNS="${WG_DNS:-1.1.1.1,8.8.8.8}"
CONNECTION_DIR="${CONNECTION_DIR:-/vagrant/connection}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wireguard qrencode iptables-persistent

mkdir -p /etc/wireguard/clients
chmod 700 /etc/wireguard /etc/wireguard/clients

if [ ! -s /etc/wireguard/server_private.key ]; then
  umask 077
  wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
fi
if [ ! -s /etc/wireguard/server_public.key ]; then
  umask 077
  wg pubkey < /etc/wireguard/server_private.key > /etc/wireguard/server_public.key
fi
SERVER_PRIVATE_KEY="$(cat /etc/wireguard/server_private.key)"
if [ -z "${SERVER_PRIVATE_KEY}" ]; then
  echo "WireGuard server private key is empty after generation."
  exit 1
fi

DEFAULT_IFACE="$(ip route | awk '/default/ {print $5; exit}')"
if [ -z "${DEFAULT_IFACE}" ]; then
  echo "Could not detect default interface"
  exit 1
fi

cat > /etc/wireguard/wg0.conf <<WGEOF
[Interface]
Address = ${WG_SERVER_ADDRESS}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}
SaveConfig = false
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ${DEFAULT_IFACE} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ${DEFAULT_IFACE} -j MASQUERADE
WGEOF

chmod 600 /etc/wireguard/wg0.conf

echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard-forward.conf
sysctl --system >/dev/null

# Save server metadata for client generation
cat > /etc/wireguard/server_meta.env <<META
WG_SERVER_PUBLIC_IP=${WG_SERVER_PUBLIC_IP}
WG_PORT=${WG_PORT}
WG_DNS=${WG_DNS}
META
chmod 600 /etc/wireguard/server_meta.env

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

mkdir -p "${CONNECTION_DIR}/clients"
chmod 755 "${CONNECTION_DIR}" "${CONNECTION_DIR}/clients"

cat > "${CONNECTION_DIR}/server.env" <<CONN
WG_SERVER_PUBLIC_IP=${WG_SERVER_PUBLIC_IP}
WG_PORT=${WG_PORT}
WG_SUBNET=${WG_SUBNET}
WG_SERVER_ADDRESS=${WG_SERVER_ADDRESS}
WG_DNS=${WG_DNS}
WG_ENDPOINT=${WG_SERVER_PUBLIC_IP}:${WG_PORT}
WG_SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
WG_DEFAULT_IFACE=${DEFAULT_IFACE}
CONN

echo "${WG_SERVER_PUBLIC_IP}:${WG_PORT}" > "${CONNECTION_DIR}/endpoint.txt"
cp /etc/wireguard/server_public.key "${CONNECTION_DIR}/server_public.key"
chmod 600 "${CONNECTION_DIR}/server.env"
chmod 644 "${CONNECTION_DIR}/endpoint.txt" "${CONNECTION_DIR}/server_public.key"

echo "WireGuard server ready."
echo "Server public key: $(cat /etc/wireguard/server_public.key)"
