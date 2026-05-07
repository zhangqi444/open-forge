---
name: egroupware
description: EGroupware recipe for open-forge. Open-source groupware suite with calendar, addressbook, email, project management, CRM, wiki, CMS, and more. PHP + MariaDB + Docker. Source: https://github.com/EGroupware/egroupware
---

# EGroupware

Open-source groupware and collaboration suite. Includes calendar, address books, email client, task management, project management, CRM, knowledge management, wiki, CMS, and more. Self-hosted alternative to Microsoft 365 / Google Workspace. PHP + MariaDB. Docker-based deployment with optional integrations (Collabora Online, Rocket.Chat). GPL-2.0 licensed.

Upstream: <https://github.com/EGroupware/egroupware> | Wiki: <https://github.com/EGroupware/egroupware/wiki>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux (Debian/Ubuntu/RHEL/SUSE) | Docker DEB/RPM package | **Recommended** — official packages |
| Any | Docker Compose (manual) | Non-Linux or unsupported distros |

> The DEB/RPM package install is the strongly recommended method. The Docker Compose manual install is for non-Linux environments only.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Domain / hostname | e.g. groupware.example.com |
| config | Admin email + password | Set during web setup |
| config | MariaDB password | Auto-configured if using package install |
| config (optional) | Collabora Online | For document editing |
| config (optional) | Rocket.Chat | For integrated chat |

## Software-layer concerns

### Docker Compose stack (when used)

| Container | Role |
|---|---|
| egroupware | PHP 8.3 FPM — main app |
| egroupware-push | Swoole WebSocket push server |
| egroupware-nginx | Nginx web server (port 8080) |
| egroupware-db | MariaDB 10.6 |
| egroupware-watchtower | Auto-updates containers daily at 4am |
| collabora-key | Collabora Online document editing (optional) |
| rocketchat | Rocket.Chat (optional) |

### Data directory

All EGroupware data is stored in `./data/` relative to the docker-compose.yml directory.

## Install — DEB/RPM package (recommended, Linux)

```bash
# Debian/Ubuntu
curl -s https://download.egroupware.org/egroupware/epl/EGroupware-ppa.key | sudo apt-key add -
sudo add-apt-repository "deb https://download.egroupware.org/egroupware/epl/$(lsb_release -c -s) ./"
sudo apt update
sudo apt install egroupware-docker

# RHEL/CentOS/SUSE: see https://github.com/EGroupware/egroupware/wiki/Distribution-specific-instructions
```

After install, configure at http://yourserver/egroupware/setup/

Full instructions: https://github.com/EGroupware/egroupware/wiki/Installation-using-egroupware-docker-RPM-DEB-package

## Install — Docker Compose (non-Linux)

```bash
mkdir egroupware && cd egroupware

curl https://raw.githubusercontent.com/EGroupware/egroupware/master/doc/docker/docker-compose.yml > docker-compose.yml
curl https://raw.githubusercontent.com/EGroupware/egroupware/master/doc/docker/nginx.conf > nginx.conf

# Create required directories
mkdir data
mkdir -p data/default/loolwsd
mkdir -p data/default/rocketchat/dump data/default/rocketchat/uploads
mkdir sources

# Edit docker-compose.yml if needed (default: http://localhost:8080/)
docker compose up -d
```

Complete install at http://localhost:8080/egroupware/setup/

## Upgrade procedure

DEB/RPM packages auto-update via Watchtower. Manual:
```bash
docker compose pull
docker compose up -d
# Then visit /egroupware/setup/ to run schema updates if prompted
```

## Gotchas

- **Use the package install on Linux** — the upstream README explicitly warns that manual Docker Compose is "way more complicated AND does not include all features." The DEB/RPM packages are the recommended path.
- Watchtower auto-updates all containers daily at 4am — this is convenient but can auto-apply breaking changes. Disable or configure a Watchtower allowlist for production.
- Required directories must exist before `docker compose up` — missing `data/`, `data/default/loolwsd`, and `data/default/rocketchat/dump` cause startup failures.
- The setup wizard at `/egroupware/setup/` must be completed after first install and after major upgrades.

## Links

- Source: https://github.com/EGroupware/egroupware
- Install wiki: https://github.com/EGroupware/egroupware/wiki/Installation-using-egroupware-docker-RPM-DEB-package
- Distribution-specific instructions: https://github.com/EGroupware/egroupware/wiki/Distribution-specific-instructions
- Docker Compose instructions: https://github.com/EGroupware/egroupware/wiki/Docker-compose-installation
