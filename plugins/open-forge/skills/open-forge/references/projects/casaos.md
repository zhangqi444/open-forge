# CasaOS

Personal home cloud OS with an app store. CasaOS is a simple, elegant home cloud system built on top of Docker. It provides a web-based dashboard for managing Docker apps, files, and system resources — designed for Raspberry Pi, ZimaBoard, Intel NUC, and any Ubuntu/Debian/CentOS machine. Ships with an app store of 100,000+ Docker ecosystem apps.

**Official site:** https://www.casaos.io  
**Source:** https://github.com/IceWhaleTech/CasaOS  
**Upstream docs:** https://wiki.casaos.io  
**License:** Apache-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Raspberry Pi (3B+/4/5) | Bash installer | Official target hardware |
| x86-64 Linux | Bash installer | Ubuntu, Debian, CentOS supported |
| ZimaBoard / Intel NUC | Bash installer | Official target hardware |
| arm64 Linux | Bash installer | Fully supported |

---

## Inputs to Collect

### All phases
| Requirement | Notes |
|-------------|-------|
| Linux host (fresh install recommended) | Ubuntu 22.04/20.04, Debian 11/12, Raspberry Pi OS, CentOS 7/8 |
| `sudo` / root access | Installer requires elevated privileges |
| Port 80 free | CasaOS web UI uses port 80 by default |

---

## Software-Layer Concerns

### Installation
CasaOS is installed via a one-liner script — no Docker Compose file needed (it installs and manages Docker itself):

```sh
# Install
curl -fsSL https://get.casaos.io | sudo bash
# OR
wget -qO- https://get.casaos.io | sudo bash
```

The installer:
1. Installs Docker if not already present
2. Installs CasaOS system components (daemon, proxy, app management, user service)
3. Starts the CasaOS web UI on port 80

### Accessing CasaOS
After installation, open `http://<host-ip>` in a browser. Create an admin account on first visit.

### Update
```sh
curl -fsSL https://get.casaos.io/update | sudo bash
# OR
wget -qO- https://get.casaos.io/update | sudo bash
```

### Uninstall
```sh
casaos-uninstall
# OR
curl -fsSL https://get.icewhale.io/casaos-uninstall.sh | sudo bash
```

### App store
Apps are installed one-click from the CasaOS dashboard. Each app runs as a Docker container. You can also import custom Docker Compose files directly via the UI.

### Data directories
- App data: stored per-app, configurable in each app's compose settings
- CasaOS config: `/etc/casaos/`
- CasaOS logs: `/var/log/casaos/`

### System services
CasaOS installs several systemd services:
- `casaos` — main daemon
- `casaos-gateway` — internal HTTP proxy
- `casaos-user-service` — user/auth management
- `casaos-app-management` — Docker app orchestration

---

## Upgrade Procedure

Run the update script:
```sh
curl -fsSL https://get.casaos.io/update | sudo bash
```
Or update via the CasaOS dashboard Settings → System Update.

---

## Gotchas

- **Not a container itself** — CasaOS is a host-level system service, not a Docker image; it installs directly onto the OS and manages Docker for you
- **Port 80 required** — CasaOS uses port 80 for its dashboard; ensure nothing else is bound to port 80 before installing
- **Fresh install recommended** — the installer works best on a freshly provisioned OS; existing Docker/nginx configs may conflict
- **ARM + x86-64 only** — officially supported architectures; other architectures are untested
- **App store pulls from Docker Hub** — app installations require internet access; air-gapped installs need manual Docker image loading
- **ZimaOS** — IceWhale also makes ZimaOS, a more opinionated fork of CasaOS for ZimaCube hardware; they share lineage but are separate projects

---

## Links
- Upstream README: https://github.com/IceWhaleTech/CasaOS
- Installation docs: https://wiki.casaos.io/en/get-started
- App store: https://wiki.casaos.io/en/feature/app-store
