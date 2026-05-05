---
name: ansible-nas
description: Ansible-NAS recipe for open-forge. Ansible playbook that provisions a full-featured home server (NAS + media + services) on a stock Ubuntu machine using Docker and Ansible roles. Upstream: https://github.com/DaveStephens/ansible-nas
---

# Ansible-NAS

Ansible playbook that turns a stock Ubuntu box into a full-featured home NAS and media server. Instead of a monolithic NAS OS (TrueNAS, OpenMediaVault), Ansible-NAS uses Ansible roles and Docker Compose to deploy any combination of 100+ self-hosted apps. Each application is an Ansible role — enable only what you want. Upstream: <https://github.com/DaveStephens/ansible-nas> — MIT.

This is an infrastructure automation tool, not an app itself. Open-forge treats it as a "self-hosting solution" rather than a single service recipe.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Ansible playbook on Ubuntu | <https://ansible-nas.io/docs/> | Yes | Primary method. Ubuntu 22.04+ on a dedicated machine or VM. |
| Manual role cherry-picking | Per individual role | Yes | Run specific roles to deploy only selected apps to an existing server. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | What is the IP or hostname of your NAS host? | Free-text | All |
| preflight | Which Ubuntu version? (22.04 or 24.04 recommended) | Free-text | Informs compatibility notes |
| storage | What drive(s) will you mount for data storage? | Free-text (e.g. /dev/sdb, /dev/sdc) | Configures data_root in group_vars |
| data | Where should app data live? (default: /mnt/Volume1) | Free-text | Sets ansible_nas_data_root |
| domain | Do you have a domain for external access? (optional) | Free-text or skip | Enables Traefik + external DNS if set |
| apps | Which applications do you want to enable? | Multi-select from roles list | Drives group_vars/all.yml feature flags |

## Prerequisites

- Ubuntu 22.04+ (dedicated machine, VM, or Pi 4/5 with USB storage)
- Ansible 2.10+ on your control machine (laptop/workstation)
- SSH access from control machine to NAS host
- Docker and Docker Compose installed on NAS host (Ansible-NAS can install these)

## Quick start

```bash
# On your control machine:
git clone https://github.com/DaveStephens/ansible-nas.git
cd ansible-nas
cp group_vars/all.yml.dist group_vars/all.yml
cp inventories/my-ansible-nas/inventory.ini.dist inventories/my-ansible-nas/inventory.ini

# Edit inventory: point at your NAS host
nano inventories/my-ansible-nas/inventory.ini

# Edit group_vars/all.yml to:
#   - Set ansible_nas_data_root (e.g. /mnt/Volume1)
#   - Enable apps: set each <app>_enabled: true
#   - Configure domain, timezone, users
nano group_vars/all.yml

# (Optional) install requirements
ansible-galaxy install -r requirements.yml

# Run the playbook
ansible-playbook -i inventories/my-ansible-nas/inventory.ini site.yml -K
```

## Key configuration variables

All configuration lives in `group_vars/all.yml`. Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `ansible_nas_data_root` | `/mnt/Volume1` | Root path for all app data volumes |
| `ansible_nas_hostname` | `ansible-nas` | Hostname set on the NAS |
| `ansible_nas_timezone` | `America/Chicago` | System timezone |
| `ansible_nas_domain` | `nas.example.com` | Base domain for Traefik routing |
| `traefik_enabled` | `false` | Enable Traefik reverse proxy with Let's Encrypt |
| `samba_enabled` | `false` | Enable SMB file sharing |
| `<app>_enabled` | `false` | Enable/disable each application |
| `<app>_available_externally` | `false` | Expose app via Traefik with subdomain |

## Enabling applications

Each application has two flags in `group_vars/all.yml`:

```yaml
# Example: enable Jellyfin, accessible externally
jellyfin_enabled: true
jellyfin_available_externally: true

# Example: enable Nextcloud, LAN-only
nextcloud_enabled: true
nextcloud_available_externally: false
```

When `available_externally: true`, Traefik automatically routes `<app>.your-domain.com` to the container and provisions a Let's Encrypt cert.

## Directory structure

```
ansible-nas/
  group_vars/
    all.yml             # Your main config file
  inventories/
    my-ansible-nas/
      inventory.ini     # Points to your NAS host
  roles/
    <app>/              # One role per application
      tasks/main.yml
      defaults/main.yml
      templates/        # docker-compose.yml.j2 and config templates
  site.yml              # Main playbook
```

## Upgrade procedure

```bash
cd ansible-nas
git pull
ansible-playbook -i inventories/my-ansible-nas/inventory.ini site.yml -K
```

Ansible-NAS re-runs are idempotent — only changed resources are updated.

To upgrade a specific app only:

```bash
ansible-playbook -i inventories/my-ansible-nas/inventory.ini site.yml -K --tags jellyfin
```

## Gotchas

- **Not a GUI.** Ansible-NAS is configured entirely in YAML and run from the command line. It is not a web dashboard like CasaOS or Umbrel.
- **Data root must be a mounted drive.** If `ansible_nas_data_root` doesn't exist or isn't mounted, app volume creation will fail. Ensure drives are mounted and fstab entries are set before running.
- **All apps disabled by default.** You must explicitly set each `<app>_enabled: true` — nothing is turned on out of the box.
- **Traefik + domain required for external access.** Without a domain and Traefik, apps are LAN-only on their mapped ports. Set `traefik_enabled: true` and configure `ansible_nas_domain` + DNS.
- **Samba shares need proper permissions.** If enabling SMB, set `samba_shares` and ensure Unix file ownership aligns with Samba user config.
- **Upstream commit activity is low (2025-2026).** The project is maintained but not heavily active. Applications bundled may lag behind their upstream versions.
- **Ubuntu only.** The playbook assumes Ubuntu/Debian. Non-Ubuntu targets (RHEL, Alpine, Arch) are not supported.

## Upstream docs

- GitHub: <https://github.com/DaveStephens/ansible-nas>
- Documentation site: <https://ansible-nas.io/docs/>
- Available applications list: <https://ansible-nas.io/docs/apps>
