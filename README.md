# Vagrant Lab

Reusable Vagrant project for reproducible local VM environments.

## Purpose
- Standard local infra/dev test setup
- Fast rebuild with destroy/recreate flow

## Common commands
- vagrant up
- vagrant ssh
- vagrant halt
- vagrant destroy -f

## Suggested workflow
- Update the Vagrantfile or provisioning scripts.
- Rebuild the VM from scratch to verify the full flow.
- Refresh the README if the setup steps change.
# Project Layout

- `Vagrantfile`: cluster definition
- `connection/`: connection helpers
- `provision/`: provisioning scripts
- `scripts/`: utility scripts
