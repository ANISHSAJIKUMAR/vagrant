#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
  echo "Run as root: sudo $0 <client_name> <client_ip>"
  exit 1
fi

CLIENT_NAME="${1:-}"
CLIENT_IP="${2:-}"

if [ -z "${CLIENT_NAME}" ] || [ -z "${CLIENT_IP}" ]; then
  echo "Usage: sudo $0 <client_name> <client_ip>"
  echo "Example: sudo $0 brother 10.8.0.2/32"
  exit 1
fi

if [ ! -f /etc/wireguard/wg0.conf ]; then
  echo "WireGuard is not configured."
  exit 1
fi

if [ -f /etc/wireguard/server_meta.env ]; then
  # shellcheck disable=SC1091
  source /etc/wireguard/server_meta.env
fi
WG_SERVER_PUBLIC_IP="${WG_SERVER_PUBLIC_IP:-REPLACE_WITH_YOUR_PUBLIC_IP_OR_DNS}"
WG_PORT="${WG_PORT:-51820}"
WG_DNS="${WG_DNS:-1.1.1.1,8.8.8.8}"
CONNECTION_DIR="${CONNECTION_DIR:-/vagrant/connection}"

CLIENT_DIR="/etc/wireguard/clients/${CLIENT_NAME}"
mkdir -p "${CLIENT_DIR}"
chmod 700 "${CLIENT_DIR}"

umask 077
wg genkey | tee "${CLIENT_DIR}/private.key" | wg pubkey > "${CLIENT_DIR}/public.key"
PRESHARED_KEY="${CLIENT_DIR}/preshared.key"
wg genpsk > "${PRESHARED_KEY}"

CLIENT_PRIVATE_KEY="$(cat "${CLIENT_DIR}/private.key")"
CLIENT_PUBLIC_KEY="$(cat "${CLIENT_DIR}/public.key")"
CLIENT_PSK="$(cat "${PRESHARED_KEY}")"
SERVER_PUBLIC_KEY="$(cat /etc/wireguard/server_public.key)"

if ! grep -q "# client:${CLIENT_NAME}" /etc/wireguard/wg0.conf; then
  cat >> /etc/wireguard/wg0.conf <<EOF2

# client:${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
PresharedKey = ${CLIENT_PSK}
AllowedIPs = ${CLIENT_IP}
EOF2
fi

wg syncconf wg0 <(wg-quick strip wg0)

CLIENT_CONF="${CLIENT_DIR}/${CLIENT_NAME}.conf"
rm -f "${CLIENT_CONF}"
cat > "${CLIENT_CONF}" <<EOF3
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}
DNS = ${WG_DNS}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PSK}
Endpoint = ${WG_SERVER_PUBLIC_IP}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF3
chmod 600 "${CLIENT_CONF}"

echo "Client profile created: ${CLIENT_CONF}"
echo "QR code for mobile clients:"
qrencode -t ansiutf8 < "${CLIENT_CONF}"

HOST_CLIENT_DIR="${CONNECTION_DIR}/clients/${CLIENT_NAME}"
mkdir -p "${HOST_CLIENT_DIR}"
cp "${CLIENT_CONF}" "${HOST_CLIENT_DIR}/${CLIENT_NAME}.conf"

cat > "${HOST_CLIENT_DIR}/details.env" <<EOF4
CLIENT_NAME=${CLIENT_NAME}
CLIENT_IP=${CLIENT_IP}
WG_ENDPOINT=${WG_SERVER_PUBLIC_IP}:${WG_PORT}
WG_DNS=${WG_DNS}
WG_SERVER_PUBLIC_KEY=${SERVER_PUBLIC_KEY}
EOF4
chmod 600 "${HOST_CLIENT_DIR}/${CLIENT_NAME}.conf" "${HOST_CLIENT_DIR}/details.env"

echo "Connection files exported to: ${HOST_CLIENT_DIR}"
