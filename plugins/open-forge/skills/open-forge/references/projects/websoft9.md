---
name: websoft9
description: Websoft9 recipe for open-forge. Covers script-based install (recommended). Websoft9 is a web-based PaaS/Linux panel for deploying and managing 200+ open-source applications on a single server via Docker Compose and GitOps.
---

# Websoft9

Web-based PaaS platform and Linux server panel for self-hosters and cloud VM operators. One-click deployment of 200+ open-source applications (WordPress, Nextcloud, Gitea, Mattermost, etc.) using pre-built Docker Compose templates. Provides a unified web console for managing apps, viewing logs, configuring SSL/TLS via Let's Encrypt, file browsing, terminal access, Nginx reverse proxy, and user management. GitOps-driven: each installed app lives in a Git repository that Websoft9 manages. Upstream: <https://github.com/websoft9/websoft9>. Website: <https://www.websoft9.com>.

**License:** LGPL-3.0 · **Language:** Python / Shell · **Default port:** 9000 · **Stars:** ~2,100

> **Third-party dependencies note:** Websoft9 orchestrates many external Docker images. Its app catalog depends on internet access to pull images at install time. It installs Docker, Portainer, Cockpit, and Nginx as platform components.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script | <https://websoft9.github.io/websoft9/install/install.sh> | ✅ | **Recommended** — installs all platform components. |
| Cloud marketplace | AWS, Azure, Alibaba Cloud, Huawei Cloud | ✅ | Cloud VM launch — pre-configured AMI/image. |

## System requirements

| Component | Minimum | Recommended |
|---|---|---|
| OS | Ubuntu 20.04+ / Debian 11+ / CentOS 7.9+ / RHEL 8+ | Ubuntu 22.04 LTS |
| CPU | 2 cores | 4+ cores |
| RAM | 2 GB | 4+ GB |
| Disk | 20 GB | 40+ GB (SSD) |
| Access | Root or sudo | Root |

## Install

```bash
# Default install (port 9000)
wget -O install.sh https://websoft9.github.io/websoft9/install/install.sh && bash install.sh

# Custom port
wget -O install.sh https://websoft9.github.io/websoft9/install/install.sh && \
  bash install.sh --port 9000 --channel release --path "/data/websoft9/source" --version "latest"
```

After installation, access the web console at:

```
http://<your-server-ip>:9000
```

Login with your **Linux system user credentials** (e.g., `ubuntu` / your SSH password, or root).

## What the installer sets up

The install script deploys these platform components:

| Component | Purpose |
|---|---|
| Docker + Docker Compose | Container runtime for all apps |
| Portainer | Container management UI |
| Cockpit | Linux system management (storage, logs, terminal) |
| Nginx | Reverse proxy for installed apps + SSL termination |
| Websoft9 app manager | Web UI for deploying/managing apps from catalog |

## Deploying apps

1. Log in to `http://your-server:9000`
2. Go to **App Store** → browse or search for an app
3. Click **Install** → configure the app name and any required settings
4. Websoft9 deploys the app via Docker Compose and sets up a reverse proxy entry
5. Access the app via its assigned port or domain

Each app is stored as a Docker Compose project under `/data/websoft9/source/apps/<appname>/`.

## App catalog

200+ apps across categories: CMS, E-commerce, DevOps, databases, project management, communication, AI tools, analytics, and more.

Full app list: <https://www.websoft9.com/apps>

## Uninstall

```bash
# Uninstall Websoft9 (keeps installed apps)
curl https://websoft9.github.io/websoft9/install/uninstall.sh | bash

# Uninstall everything including Cockpit and all files
wget -O - https://websoft9.github.io/websoft9/install/uninstall.sh | bash /dev/stdin --cockpit --files
```

## Upgrade

```bash
# Upgrade Websoft9 to latest
wget -O install.sh https://websoft9.github.io/websoft9/install/install.sh && bash install.sh
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Root required | The installer must run as root. Use `sudo su` if on a non-root user. |
| Internet required at install time | The installer downloads Docker, Portainer, Cockpit, and the Websoft9 app catalog from the internet. Air-gapped installs not supported. |
| Port 9000 | Default port. Ensure 9000 is open in your firewall/security group. Can be changed with `--port`. |
| Linux login | Websoft9 uses your Linux system accounts for login — no separate user database. |
| GitOps architecture | Each app is a Git repo managed by Websoft9. Changes to `docker-compose.yml` inside an app's directory are tracked and can be rolled back. |
| App data persistence | App data is stored in Docker volumes or bind-mounted paths under `/data/websoft9/source/apps/`. Back up this directory. |
| Cockpit dependency | Cockpit provides the terminal, file browser, and system info panels. It runs as a system service (`cockpit.socket`) on the host. |
| Third-party images | Websoft9 doesn't build its own Docker images for apps — it uses official or community images from Docker Hub. |

## Gotchas

- **Root required:** The installer won't work without root. If you're on Ubuntu with a non-root user, run `sudo su` first.
- **Open port 9000:** Cloud VMs often block all inbound ports by default. Open port 9000 (TCP) in your cloud security group before trying to access the web console.
- **Linux credentials for login:** You log in with your Linux username and password (the same credentials you'd use for SSH). If your server uses key-only SSH auth, you may need to set a password: `passwd username`.
- **Apps are Docker Compose projects:** If you're comfortable with Docker, you can manage app configs directly under `/data/websoft9/source/apps/`. Websoft9's UI reflects changes made here.
- **Reinstalling = upgrade:** Running the install script again on an existing installation upgrades Websoft9. App data is preserved.
- **Not for Kubernetes:** Websoft9 is designed for single-server deployments. It doesn't target Kubernetes clusters.

## Upstream links

- GitHub: <https://github.com/websoft9/websoft9>
- Website: <https://www.websoft9.com>
- App catalog: <https://www.websoft9.com/apps>
- Architecture docs: <https://github.com/Websoft9/websoft9/blob/main/docs/architecture.md>
- Demo: <http://demo.goweb.cc:9000/> (user: demo / websoft9)
- Cloud marketplace (AWS): <https://aws.amazon.com/marketplace/pp/prodview-5jziwpvx4puq4>
