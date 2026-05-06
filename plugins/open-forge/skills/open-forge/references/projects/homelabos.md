---
name: homelabos
description: HomelabOS recipe for open-forge. Self-hosting solution that deploys 100+ services on a home server using Ansible and Docker, with automated HTTPS, Tor access, and backups. Source: https://gitlab.com/NickBusey/HomelabOS
---

# HomelabOS

Self-hosting solution that uses Ansible to deploy and manage 100+ Docker-based services on a home server. Covers media, productivity, communication, storage, monitoring, and more — all in one place. Includes automated HTTPS via Let's Encrypt, optional Tor hidden service access, automated backups, and settings sync via Git. Upstream: https://gitlab.com/NickBusey/HomelabOS. Docs: https://homelabos.com/docs/.

Note: Latest release is v1.0 (May 2024). Active community on Zulip. Commits are infrequent — review upstream before deploying for latest service support.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| One-command installer | Linux (Debian/Ubuntu) | Recommended. Bash script installs dependencies and runs Ansible. |
| Manual setup | Linux (Debian/Ubuntu) | Clone repo, configure, run Ansible manually. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Server IP or hostname?" | The target machine HomelabOS will configure |
| setup | "Domain name?" | e.g. example.com — used for service subdomains (service.example.com) |
| setup | "Admin email?" | For Let's Encrypt certificate registration |
| ssh | "SSH user and key?" | Ansible connects via SSH to the target server |
| services | "Which services to enable?" | Edit settings/config.yml — set enabled: true per service |

## Software-layer concerns

### One-command install

  bash <(curl -s https://gitlab.com/NickBusey/HomelabOS/-/raw/master/install_homelabos.sh)

This script:
1. Installs Ansible and dependencies on your local machine
2. Clones the HomelabOS repo
3. Prompts for configuration (domain, server IP, SSH details)
4. Writes settings/config.yml
5. Runs the Ansible playbook against your server

### Manual setup

  git clone https://gitlab.com/NickBusey/HomelabOS.git
  cd HomelabOS

  # Install dependencies (local machine)
  pip3 install ansible

  # Configure
  cp settings/config.yml.j2 settings/config.yml
  # Edit settings/config.yml: set domain, server IP, admin email, etc.

  # Enable services: find the service section in config.yml, set enabled: true
  # Example: nextcloud, jellyfin, gitea, etc.

  # Deploy
  ansible-playbook -i settings/inventory playbook.yml

### Service configuration

Each service has its own settings block in config.yml:

  nextcloud:
    enabled: true
    subdomain: nextcloud    # → nextcloud.yourdomain.com
    # service-specific vars here

Services are deployed as Docker containers. nginx-proxy + Let's Encrypt handle routing and TLS automatically.

### Key configuration (settings/config.yml)

  default:
    domain: example.com
    admin_email: admin@example.com
    server_ip: 192.168.1.100
    ssh_user: ubuntu
    # Storage
    storage_dir: /mnt/storage

### Tor access

  # Enable in config.yml:
  tor:
    enabled: true

Each enabled service gets a .onion address automatically.

### Backups

Built-in backup system: configure S3-compatible target or local path in config.yml. Run:

  ansible-playbook -i settings/inventory playbook.yml --tags backup

## Upgrade procedure

  cd HomelabOS
  git pull
  ansible-playbook -i settings/inventory playbook.yml

## Gotchas

- **Ansible runs locally, deploys to remote**: HomelabOS is not a Docker Compose stack you run on the server — it's Ansible that configures the server from your local machine.
- **Domain required**: designed around subdomain-per-service with Let's Encrypt. Purely local/LAN deployments need workarounds.
- **100+ services means docker-heavy**: the server needs adequate RAM (4GB+ recommended) if many services are enabled simultaneously.
- **Settings sync via Git**: the docs recommend committing settings/ to a private Git repo so settings survive local machine wipes.
- **Slow Ansible runs**: with many services, playbook runs can take many minutes. Use --tags to target specific services.
- **Community-maintained service list**: some service definitions may be outdated vs upstream projects. Review before enabling.

## References

- Upstream GitLab: https://gitlab.com/NickBusey/HomelabOS
- Documentation: https://homelabos.com/docs/
- Available software list: https://homelabos.com/docs/#available-software
- Installation guide: https://homelabos.com/docs/setup/installation/
- Community (Zulip): https://homelabos.zulipchat.com/
