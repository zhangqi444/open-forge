---
name: debops-project
description: DebOps recipe for open-forge. Covers pip install, project initialisation, inventory setup, and running playbooks against Debian/Ubuntu hosts. Not a Docker app — it is an Ansible collection run from a control machine.
---

# DebOps

Comprehensive collection of Ansible roles and playbooks for managing Debian/Ubuntu servers — "your data centre in a box." Covers sshd, PKI/TLS, NGINX, PostgreSQL, MariaDB, Redis, Postfix, Dovecot, fail2ban, firewall (ferm), LVM, NFS, Docker, LXC, and 200+ more roles. GPL-3.0.

- **GitHub:** https://github.com/debops/debops (1.4 k stars)
- **Docs:** https://docs.debops.org/
- **Ansible Galaxy:** https://galaxy.ansible.com/debops/debops

> **Not a Docker app.** DebOps runs from a control machine (your laptop or a jump host) via Ansible against target Debian/Ubuntu servers. No daemon to run, no image to pull.

## Compatible install methods

| Method | When to use |
|---|---|
| `pip install debops` | Quickest — installs DebOps + compatible Ansible into a virtualenv |
| `pip install debops[ansible]` | Same, but also pins and installs the exact Ansible version DebOps requires |
| Source clone | Development / contributing to DebOps itself |

## Requirements

| Component | Minimum |
|---|---|
| Python | 3.8+ |
| Ansible | 2.12+ (see `requirements.txt` for exact pin) |
| Control machine OS | Linux, macOS, or WSL2 |
| Target host OS | Debian 11 (Bullseye), Debian 12 (Bookworm), Ubuntu 20.04 / 22.04 LTS |
| SSH access to targets | Root or sudoer with passwordless sudo |

## Installation (control machine)

```bash
# 1. Create and activate a virtualenv (recommended)
python3 -m venv ~/.venv/debops
source ~/.venv/debops/bin/activate

# 2. Install DebOps with pinned Ansible
pip install debops[ansible]

# 3. Verify
debops --version
ansible --version
```

## Project initialisation

```bash
# Create a DebOps project directory (holds inventory, config, secrets)
debops-init ~/myproject
cd ~/myproject
```

This creates:

```
myproject/
  ansible/
    inventory/
      hosts          <- add your servers here
      host_vars/
      group_vars/
        all/
          vars.yml   <- global variables
  .debops.cfg        <- project config (playbook paths, etc.)
```

## Inventory setup

Edit `ansible/inventory/hosts`:

```ini
[debops_all_hosts]
webserver01  ansible_host=192.168.1.10
dbserver01   ansible_host=192.168.1.11

[debops_service_nginx]
webserver01

[debops_service_postgresql]
dbserver01
```

Groups starting with `debops_service_` activate the corresponding DebOps role for those hosts automatically.

## Running playbooks

```bash
# Run the full site playbook against all hosts
debops run site.yml

# Limit to a single host
debops run site.yml -l webserver01

# Limit to a specific role/service
debops run service/nginx.yml -l webserver01

# Dry-run (check mode)
debops run site.yml -l webserver01 --check

# Run with verbose output
debops run site.yml -l webserver01 -v
```

## Key roles (selection)

| Role | What it manages |
|---|---|
| `debops.sshd` | Hardened OpenSSH daemon config |
| `debops.pki` | PKI infrastructure, internal CA, TLS certs |
| `debops.nginx` | NGINX vhosts, TLS, proxy configs |
| `debops.postgresql` | PostgreSQL clusters, databases, users |
| `debops.mariadb` | MariaDB/MySQL instances |
| `debops.redis` | Redis instances |
| `debops.postfix` | Postfix MTA configuration |
| `debops.dovecot` | Dovecot IMAP/POP3 |
| `debops.fail2ban` | Intrusion prevention |
| `debops.ferm` | iptables firewall management |
| `debops.lvm` | LVM volume groups and logical volumes |
| `debops.nfs` | NFS server and client |
| `debops.docker_server` | Docker CE daemon |
| `debops.lxc` | LXC container host |
| `debops.unbound` | Local DNS resolver |
| `debops.apt` | APT sources, preferences, pinning |

Full role index: https://docs.debops.org/en/stable/ansible/roles/index.html

## Group variables example

`ansible/inventory/group_vars/all/vars.yml`:

```yaml
# Global admin email for PKI / system notifications
debops__admin_email: 'admin@example.com'

# Internal domain used for PKI and hostnames
debops__domain: 'example.com'

# Timezone
tzdata__timezone: 'Europe/London'
```

Role-specific vars go in `host_vars/<hostname>/` or `group_vars/<group>/`:

```yaml
# group_vars/debops_service_nginx/nginx.yml
nginx__servers:
  - name: 'myapp'
    filename: 'myapp'
    server_name: [ 'myapp.example.com' ]
    root: '/srv/www/myapp/public'
```

## Secrets management

DebOps stores secrets (PKI keys, passwords) in `secret/` inside the project dir. This directory is **never** committed to version control — add it to `.gitignore`.

```bash
# View generated secrets
ls ~/myproject/secret/
```

## Notes

- Steep learning curve — DebOps is designed for production-hardened infra, not quick installs.
- Each role is individually usable without running the full `site.yml`.
- DebOps opinionatedly manages `/etc/apt/sources.list`, SSH, and the firewall — review the `common.yml` play before running against production.
- Official docs are comprehensive: https://docs.debops.org/
- IRC / Matrix: `#debops` on Libera.Chat / Matrix.
