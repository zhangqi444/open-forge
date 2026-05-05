---
name: debops-project
description: DebOps recipe for open-forge. Covers installation from PyPI, project initialisation, inventory setup, running playbooks, and key roles. Not a Docker app — DebOps is an Ansible collection run from a control machine against target Debian/Ubuntu hosts.
---

# DebOps

Comprehensive collection of Ansible roles and playbooks for managing Debian/Ubuntu servers — "your data centre in a box". Covers sshd, PKI, nginx, PostgreSQL, MariaDB, Redis, Postfix, Dovecot, fail2ban, firewall (ferm), LVM, NFS, Docker, LXC, and 200+ more roles. GPL-3.0. Upstream: <https://github.com/debops/debops>. Docs: <https://docs.debops.org/>.

DebOps is an Ansible collection — not a Docker app, not a web UI. It runs on a **control machine** (your laptop, a jump box, or a CI runner) and configures **target hosts** running Debian or Ubuntu over SSH.

## Requirements

| Component | Minimum version |
|---|---|
| Python | 3.8+ |
| Ansible | 2.12+ |
| Control machine OS | Linux, macOS, or WSL (Windows native unsupported) |
| Target host OS | Debian 11 (Bullseye), Debian 12 (Bookworm), Ubuntu 20.04, Ubuntu 22.04 |

Target hosts need: SSH access, `sudo`, Python 3.

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Control machine OS?" (Linux / macOS / WSL) | All |
| preflight | "Target host IP or hostname?" | All |
| preflight | "SSH user on target?" (must have sudo) | All |
| preflight | "DebOps project directory name?" (e.g. `~/myinfra`) | All |
| roles | "Which roles to run?" (e.g. sshd, nginx, postgresql, docker) | Drives the playbook/role selection |
| domain | "Domain name for the target host?" (used by PKI, nginx, etc.) | If running PKI / nginx / mail roles |

After each prompt, record the value in the state file under `inputs.*`.

---

## Phase 1 — Install DebOps on the control machine

```bash
# Option A — install DebOps + Ansible together (recommended)
pip install debops[ansible]

# Option B — if Ansible is already installed
pip install debops

# Verify
debops --version
ansible --version
```

Both `debops` and `ansible` executables must be on `PATH`.

---

## Phase 2 — Initialise a project

A DebOps *project* is a directory containing an Ansible inventory, group/host vars, and optional local overrides.

```bash
debops-init ~/myinfra
cd ~/myinfra
```

Directory structure created:

```
myinfra/
  ansible/
    inventory/
      hosts          ← Ansible inventory file
      group_vars/
        all/
          .keep
      host_vars/
        .keep
  .debops.cfg        ← project config (DebOps settings)
```

---

## Phase 3 — Configure the inventory

Edit `ansible/inventory/hosts` to add your target host:

```ini
[debops_all_hosts]
myserver ansible_host=192.0.2.10 ansible_user=ubuntu

# Optional group memberships for role activation:
[debops_service_nginx]
myserver

[debops_service_postgresql]
myserver

[debops_service_docker]
myserver
```

DebOps uses **group memberships** to decide which roles apply to which hosts. A host in `[debops_service_nginx]` gets the nginx role; in `[debops_service_docker]` gets Docker; etc. See the full group list: <https://docs.debops.org/en/stable/ansible/roles/>.

### Set host/group variables

```bash
# Per-host variables
mkdir -p ansible/inventory/host_vars/myserver
cat > ansible/inventory/host_vars/myserver/vars.yml << 'EOF'
# Example: set the FQDN DebOps uses for PKI/nginx
ansible_domain: "myserver.example.com"
EOF
```

---

## Phase 4 — Bootstrap a target host

The `bootstrap` role prepares a freshly-provisioned host: creates the `ansible` system user, installs Python 3, configures sudo, and hardens SSH.

```bash
# Run the bootstrap playbook against one host
# Supply the initial SSH user (often 'root' or 'ubuntu')
debops run bootstrap -l myserver -u ubuntu --ask-become-pass
```

After bootstrapping, subsequent runs use the `ansible` system user created by the role (no password prompt needed).

---

## Phase 5 — Run playbooks

### Full site playbook (all roles for all hosts)

```bash
debops run site.yml
```

### Limit to one host

```bash
debops run site.yml -l myserver
```

### Run a specific role/service playbook

```bash
# nginx only
debops run service/nginx -l myserver

# PostgreSQL only
debops run service/postgresql -l myserver

# sshd hardening only
debops run service/sshd -l myserver

# PKI / TLS certificates
debops run service/pki -l myserver

# Docker
debops run service/docker -l myserver

# fail2ban
debops run service/fail2ban -l myserver
```

### Dry run (check mode — no changes)

```bash
debops run site.yml -l myserver --check --diff
```

---

## Available roles (selected)

| Category | Role | What it does |
|---|---|---|
| System | `sshd` | Harden OpenSSH (disable root login, key-only auth, ciphers) |
| System | `pki` | Internal CA + TLS certificates for all services |
| System | `ferm` | iptables firewall (declarative rule management) |
| System | `fail2ban` | Brute-force protection |
| System | `lvm` | Logical volume management |
| System | `nfs` | NFS server / client |
| Web | `nginx` | nginx vhosts (with PKI integration) |
| Database | `postgresql` | PostgreSQL server + users/databases |
| Database | `mariadb` | MariaDB server + users/databases |
| Cache | `redis` | Redis server |
| Mail | `postfix` | Postfix MTA |
| Mail | `dovecot` | Dovecot IMAP/POP3 |
| Container | `docker` | Docker CE + daemon configuration |
| Container | `lxc` | LXC containers |
| Monitoring | `rsyslog` | Centralised logging |
| Auth | `ldap` | OpenLDAP integration |

Full role index: <https://docs.debops.org/en/stable/ansible/roles/>.

---

## Example: harden SSH + install nginx + PostgreSQL

1. Add host to inventory groups:

```ini
[debops_all_hosts]
myserver ansible_host=192.0.2.10

[debops_service_nginx]
myserver

[debops_service_postgresql]
myserver
```

2. Bootstrap:

```bash
debops run bootstrap -l myserver -u ubuntu
```

3. Run site playbook:

```bash
debops run site.yml -l myserver
```

DebOps will apply `common` (base hardening), `sshd`, `ferm`, `pki`, `nginx`, and `postgresql` in dependency order.

---

## Verify

```bash
# Check Ansible can reach the host
debops run ping -l myserver

# Check what will change (dry run)
debops run site.yml -l myserver --check

# On the target host: check services
ssh ansible@myserver 'systemctl status nginx postgresql'
```

---

## Lifecycle

```bash
# Update DebOps collection (new roles / role updates)
pip install --upgrade debops

# Re-run the full site playbook to apply any drift
debops run site.yml

# Apply a single role update
debops run service/nginx -l myserver

# Run ad-hoc Ansible commands through DebOps
debops run adhoc -m shell -a "apt list --upgradable" -l myserver
```

---

## Gotchas

- **Not a Docker app.** DebOps has no Docker image or `docker run` command. It is an Ansible collection that configures bare Debian/Ubuntu hosts via SSH. It *can* install Docker on those hosts via the `docker` role.
- **Steep learning curve.** DebOps uses many interdependent roles; understanding PKI and `ferm` (firewall) is required before running `site.yml` on a production host. Read the role docs before running.
- **`site.yml` applies all roles.** Running `debops run site.yml` against a host will apply every role matching the host's inventory groups. On a new host this is fine; on an existing configured host, run `--check --diff` first to review changes.
- **Each role is individually usable.** You don't need to use the full DebOps stack. Any single role can be applied independently: `debops run service/sshd -l myserver`.
- **Target must be Debian or Ubuntu.** DebOps roles target Debian/Ubuntu only. RHEL, Alpine, Arch, etc. are unsupported.
- **Python 3 must be present on target hosts.** Some minimal cloud images lack Python 3; the `bootstrap` role installs it. Run bootstrap before `site.yml` on a fresh host.
- **SSH key auth required after bootstrap.** The bootstrap role disables password SSH. Make sure your SSH public key is in `~/.ssh/authorized_keys` on the target before running bootstrap, or use `--ask-pass` on the first run.
- **`ansible` system user.** Bootstrap creates an `ansible` system user on the target with passwordless sudo. Subsequent DebOps runs use this user automatically. Don't delete it.

---

## Resources

- Docs: <https://docs.debops.org/>
- GitHub: <https://github.com/debops/debops> (~1.4k stars)
- Role reference: <https://docs.debops.org/en/stable/ansible/roles/>
- License: GPL-3.0
