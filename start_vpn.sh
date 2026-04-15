#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"

PROVIDER="${PROVIDER:-vmware_desktop}"
WG_PORT="${WG_PORT:-51820}"
WG_DNS="${WG_DNS:-1.1.1.1,8.8.8.8}"
WG_SUBNET="${WG_SUBNET:-10.8.0.0/24}"
WG_SERVER_ADDRESS="${WG_SERVER_ADDRESS:-10.8.0.1/24}"
CLIENT_NAME="${CLIENT_NAME:-brother}"
CLIENT_IP="${CLIENT_IP:-10.8.0.2/32}"
HOST_CONNECTION_DIR="${CONNECTION_DIR:-${PROJECT_DIR}/connection}"
VM_CONNECTION_DIR="${VM_CONNECTION_DIR:-/vagrant/connection}"

get_public_ip() {
  local ip=""
  ip="$(curl -4 -fsS https://api.ipify.org 2>/dev/null || true)"
  if [ -z "${ip}" ]; then
    ip="$(curl -4 -fsS https://ifconfig.me/ip 2>/dev/null || true)"
  fi
  echo "${ip}"
}

WG_SERVER_PUBLIC_IP="${WG_SERVER_PUBLIC_IP:-}"
if [ -z "${WG_SERVER_PUBLIC_IP}" ]; then
  WG_SERVER_PUBLIC_IP="$(get_public_ip)"
fi

if [ -z "${WG_SERVER_PUBLIC_IP}" ]; then
  echo "Failed to detect public IP. Set WG_SERVER_PUBLIC_IP manually and run again."
  exit 1
fi

mkdir -p "${HOST_CONNECTION_DIR}/clients"

echo "Starting VPN VM with provider: ${PROVIDER}"
echo "Using endpoint: ${WG_SERVER_PUBLIC_IP}:${WG_PORT}"

CONNECTION_DIR="${VM_CONNECTION_DIR}"
export WG_SERVER_PUBLIC_IP WG_PORT WG_DNS WG_SUBNET WG_SERVER_ADDRESS CONNECTION_DIR
vagrant up --provider="${PROVIDER}"

# Helpful SSH config for direct ssh usage
vagrant ssh-config > "${HOST_CONNECTION_DIR}/vagrant-ssh-config.txt"

# Create/refresh client profile and export files to connection/
vagrant ssh -c "sudo /vagrant/scripts/add-client.sh '${CLIENT_NAME}' '${CLIENT_IP}'"

# Save a runtime status snapshot
vagrant ssh -c "sudo wg show" > "${HOST_CONNECTION_DIR}/wg-show.txt"

missing=0
for required_file in "endpoint.txt" "server.env" "server_public.key" "clients/${CLIENT_NAME}/${CLIENT_NAME}.conf"; do
  if [ ! -f "${HOST_CONNECTION_DIR}/${required_file}" ]; then
    echo "Missing expected file: ${HOST_CONNECTION_DIR}/${required_file}"
    missing=1
  fi
done
if [ "${missing}" -ne 0 ]; then
  echo "Start completed with missing connection artifacts."
  exit 1
fi

echo "Done. Connection files are in: ${HOST_CONNECTION_DIR}"
echo "Client config: ${HOST_CONNECTION_DIR}/clients/${CLIENT_NAME}/${CLIENT_NAME}.conf"
