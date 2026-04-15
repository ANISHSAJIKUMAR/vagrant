# Vagrant VPN Gateway (Terminal-only)

This project creates a headless Ubuntu VM with a WireGuard VPN server.
All generated connection data is exported to:

`/Users/anishskumar/vagrant-vpn-gateway/connection`

## Prerequisites

- Vagrant
- VMware Fusion (recommended in this setup) or VirtualBox
- Router access for UDP port forwarding

## Folder layout

- `connection/server.env`: server endpoint and connection metadata
- `connection/endpoint.txt`: `IP_OR_DNS:PORT`
- `connection/server_public.key`: WireGuard server public key
- `connection/clients/<name>/<name>.conf`: client profile to import in WireGuard app
- `connection/clients/<name>/details.env`: client connection details

## Start VM and auto-provision

From host terminal:

```bash
cd /Users/anishskumar/vagrant-vpn-gateway
export WG_SERVER_PUBLIC_IP="YOUR_PUBLIC_IP_OR_DNS"
export WG_PORT="51820"
export WG_DNS="1.1.1.1,8.8.8.8"
vagrant up --provider=vmware_desktop
```

Notes:
- Provisioning is configured with `run: "always"`, so required setup scripts run on every `vagrant up`.
- Server connection files are automatically written to `connection/` during provisioning.

## One-command start and stop scripts

From host terminal:

```bash
cd /Users/anishskumar/vagrant-vpn-gateway
./start_vpn.sh
```

`start_vpn.sh` does end-to-end setup:
- Detects public IP (or uses `WG_SERVER_PUBLIC_IP` if provided)
- Runs `vagrant up` with provisioning
- Creates/refreshes client (`CLIENT_NAME`, `CLIENT_IP`)
- Populates `connection/` with server/client files
- Exports SSH config to `connection/vagrant-ssh-config.txt`

Environment variables you can override:
- `PROVIDER` (default `vmware_desktop`)
- `WG_SERVER_PUBLIC_IP` (auto-detected if empty)
- `WG_PORT` (default `51820`)
- `WG_DNS` (default `1.1.1.1,8.8.8.8`)
- `CLIENT_NAME` (default `brother`)
- `CLIENT_IP` (default `10.8.0.2/32`)
- `CONNECTION_DIR` host output folder (default `/Users/anishskumar/vagrant-vpn-gateway/connection`)
- `VM_CONNECTION_DIR` VM-side connection folder (default `/vagrant/connection`)

To stop and clean everything not required:

```bash
cd /Users/anishskumar/vagrant-vpn-gateway
./stop_cleanup_vpn.sh
```

`stop_cleanup_vpn.sh`:
- Halts and destroys the VM
- Removes `.vagrant` local VM state
- Cleans generated files under `connection/` (keeps `connection/README.md` by default)

## SSH to VM

Simple:

```bash
cd /Users/anishskumar/vagrant-vpn-gateway
vagrant ssh
```

Generate explicit SSH config on host:

```bash
cd /Users/anishskumar/vagrant-vpn-gateway
vagrant ssh-config > connection/vagrant-ssh-config.txt
```

Connect with OpenSSH:

```bash
ssh -F connection/vagrant-ssh-config.txt default
```

## Create client profile

Inside VM:

```bash
sudo /vagrant/scripts/add-client.sh brother 10.8.0.2/32
```

What this does:
- Adds client peer to `/etc/wireguard/wg0.conf`
- Creates VM-side profile at `/etc/wireguard/clients/brother/brother.conf`
- Exports host-side files to `connection/clients/brother/`

## Mobile usage

- Install WireGuard app on Android/iPhone.
- Import `connection/clients/brother/brother.conf`.
- Or run the client script in VM and scan the printed QR code.

## Required network setup

- Forward `UDP 51820` from router to your host machine LAN IP.
- Allow inbound `UDP 51820` in host firewall.
- Use public IP or DNS for `WG_SERVER_PUBLIC_IP` (not private LAN IP).

## Useful commands

From host:

```bash
cd /Users/anishskumar/vagrant-vpn-gateway
vagrant status
vagrant up --provider=vmware_desktop
vagrant halt
```

From VM:

```bash
sudo systemctl status wg-quick@wg0
sudo wg show
sudo journalctl -u wg-quick@wg0 -n 100 --no-pager
```

## Security notes

- Do not share server private keys.
- Share only each user/device profile under `connection/clients/<name>/`.
- Use one client per device/person.
- Revoke a client by removing that peer from `/etc/wireguard/wg0.conf` and restarting the service.
