#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_DIR}"

CONNECTION_DIR="${CONNECTION_DIR:-${PROJECT_DIR}/connection}"
KEEP_CONNECTION_README="${KEEP_CONNECTION_README:-1}"

echo "Stopping VM..."
vagrant halt >/dev/null 2>&1 || true

echo "Destroying VM..."
vagrant destroy -f >/dev/null 2>&1 || true

echo "Removing local VM state..."
rm -rf "${PROJECT_DIR}/.vagrant"

echo "Cleaning generated connection files..."
if [ -d "${CONNECTION_DIR}" ]; then
  if [ "${KEEP_CONNECTION_README}" = "1" ]; then
    find "${CONNECTION_DIR}" -mindepth 1 ! -name "README.md" -exec rm -rf {} +
    mkdir -p "${CONNECTION_DIR}/clients"
  else
    rm -rf "${CONNECTION_DIR}"
    mkdir -p "${CONNECTION_DIR}/clients"
  fi
fi

echo "Cleanup complete."
