# Contributing

This repository is a small Vagrant lab for local infrastructure workflows.

## Scope
- Keep changes small and focused.
- Prefer documentation, configuration, or automation improvements that make the lab easier to reproduce.
- Avoid committing generated artifacts or local machine state.

## What to change
- Improve setup instructions
- Add repeatable provisioning steps
- Fix bugs in the helper scripts
- Tighten the README when the workflow changes

## Before opening a PR
- Run `vagrant up` and confirm the lab boots
- Run `vagrant validate` if you change the Vagrantfile
- Run `vagrant destroy -f` after testing if you made VM changes
- Check that any shell scripts remain executable

## Pull request expectations
- Explain what changed and why
- Mention any manual steps required for verification
- Avoid unrelated formatting-only churn
