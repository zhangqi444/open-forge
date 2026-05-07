---
name: xsrv
description: xsrv recipe for open-forge. Ansible-based toolkit to install and manage self-hosted services on your own server(s). Roles for Nextcloud, Gitea, Jellyfin, Matrix, Wireguard, mail, and 30+ more. CLI wrapper + templates for single-server and multi-server setups. Source: https://github.com/nodiscc/xsrv
---

# xsrv

Ansible-based toolkit for installing and managing self-hosted applications on your own Linux server(s). Provides 30+ Ansible roles (Nextcloud, Gitea, Jellyfin, Matrix, Wireguard, mail, monitoring, backup, LDAP, etc.) and an optional `xsrv` CLI wrapper that simplifies common operations. Start with a single server in minutes using the included template. GPL-3.0 licensed.

Upstream: <https://github.com/nodiscc/xsrv> | Docs: <https://xsrv.readthedocs.io>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux (controller) | Python 3.9+, Ansible, Bash | Controller: the machine you run xsrv from |
| Debian 11/12 (target) | SSH + Python | Managed hosts must run Debian-based Linux |
| Ubuntu (target) | SSH + Python | Supported target OS |
| Any (controller) | macOS (with brew) | macOS controller supported |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Controller machine (Linux/macOS) with Python 3.9+, git, bash, ssh | Where xsrv runs |
| preflight | Target server with SSH access | Debian/Ubuntu preferred |
| preflight | SSH key pair | For passwordless access to the managed host |
| config | Target hostname/IP | e.g. my.example.org |
| config | Which roles to enable | Uncomment roles in playbook.yml |
| config | Per-role variables | Set in host_vars/<hostname>.yml (prompted by `xsrv edit-host`) |

## Software-layer concerns

### Architecture

xsrv uses a standard Ansible project structure:

```
playbooks/
  default/
    playbook.yml          # lists roles to apply to each host
    host_vars/
      my.example.org.yml  # plaintext host variables
      my.example.org.vault.yml  # encrypted secrets (ansible-vault)
    .ansible-vault-password  # vault decryption key (keep private!)
    ansible_collections/nodiscc/xsrv/  # installed collection
```

The `xsrv` CLI wrapper calls `ansible-playbook` underneath. You can also use it as a plain Ansible collection in your own playbooks.

### Available roles (subset)

| Role | What it installs |
|---|---|
| common | Base Debian setup, SSH hardening |
| apache | Web server + PHP-FPM |
| nextcloud | File sharing/sync |
| gitea | Git forge |
| jellyfin | Media server |
| matrix | Matrix/Element chat |
| mail_dovecot | IMAP mail server |
| wireguard | VPN |
| monitoring.grafana | Metrics + dashboards |
| postgresql | Database |
| openldap | LDAP directory |
| backup | rsnapshot-based backup |
| samba | File sharing |
| searxng | Metasearch engine |
| jitsi | Video conferencing |
| tt_rss | Feed reader |
| shaarli | Bookmarking |
| mumble | VoIP |
| kiwix | Offline Wikipedia |
| stirlingpdf | PDF tools |

## Install — controller setup

```bash
# Debian/Ubuntu controller
sudo apt update && sudo apt install git bash python3-venv python3-pip \
  python3-cryptography openssh-client pwgen wget

# Download xsrv CLI
wget https://github.com/nodiscc/xsrv/-/raw/release/xsrv
chmod a+x xsrv
sudo cp xsrv /usr/local/bin/

# (Optional) tab completion
wget https://github.com/nodiscc/xsrv/-/raw/release/xsrv-completion.sh
sudo cp xsrv-completion.sh /etc/bash_completion.d/

# Generate SSH key if needed
ssh-keygen -b 4096

# Copy SSH key to managed host
ssh-copy-id deploy@my.example.org
```

## Initialize a project

```bash
xsrv init-project
# Interactive prompts: enter hostname, confirm paths
# Installs Ansible collection, generates vault password, creates project skeleton
```

## Configure and deploy

```bash
# Edit playbook.yml — uncomment roles to enable
xsrv edit-playbook

# Edit host variables
xsrv edit-host

# Edit secrets (vault-encrypted)
xsrv edit-vault

# Deploy everything
xsrv deploy

# Deploy only specific tags (e.g. just nextcloud)
xsrv deploy --tags nextcloud
```

## Upgrade procedure

```bash
# Update xsrv CLI
wget https://github.com/nodiscc/xsrv/-/raw/release/xsrv
chmod a+x xsrv && sudo cp xsrv /usr/local/bin/

# Update the Ansible collection
xsrv upgrade

# Re-deploy
xsrv deploy
```

## Gotchas

- xsrv is an automation framework, not an app itself — it deploys and configures other services. You still need a Linux server to deploy to.
- Managed hosts should run Debian or Ubuntu — other distributions are not officially tested.
- `.ansible-vault-password` stores your vault decryption key in plaintext in the project directory — back it up securely and keep it out of version control (it is gitignored by default). Losing it means losing access to all encrypted secrets.
- The xsrv CLI wraps Ansible — for anything the CLI doesn't expose, you can always run `ansible-playbook` directly from the project directory.
- Each role has its own variables with sensible defaults — read the role's README (in `ansible_collections/nodiscc/xsrv/roles/<rolename>/README.md`) before enabling it.
- `xsrv deploy` is idempotent — safe to run repeatedly. Run it after any config change to apply the new state.

## Links

- Source: https://github.com/nodiscc/xsrv
- Documentation: https://xsrv.readthedocs.io
- Available roles: https://github.com/nodiscc/xsrv#roles
- Installation guide: https://xsrv.readthedocs.io/en/latest/installation.html
