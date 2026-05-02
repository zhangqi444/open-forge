---
name: fail2ban-report-project
description: Fail2Ban-Report recipe for open-forge. Covers the Docker deployment (from the Fail2Ban-Report-Docker repo) and native bare-metal install of this multi-server Fail2Ban log dashboard with UFW blocklist management. Based on upstream README at https://github.com/SubleXBle/Fail2Ban-Report and Docker repo at https://github.com/SubleXBle/Fail2Ban-Report-Docker.
---

# Fail2Ban-Report

Web-based dashboard that transforms daily Fail2Ban logs into searchable, filterable JSON reports. Provides centralized UFW IP blocklist management across multiple servers via pull-based HTTPS sync. Built with PHP + shell scripts; no database, no external frameworks. Upstream: <https://github.com/SubleXBle/Fail2Ban-Report>. Docker variant: <https://github.com/SubleXBle/Fail2Ban-Report-Docker>.

> ⚠️ **Security-critical**: This tool modifies UFW firewall rules via backend cron scripts running as root. Deploy it **only** behind HTTPS with IP restrictions or HTTP authentication. Never expose to the public internet without access controls.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host with Fail2Ban + UFW | Docker (Docker variant repo) | Docker-specific repo; version may lag behind native by one release |
| Linux host with Fail2Ban + UFW | Bare metal (Apache + PHP) | Native install; recommended for full feature parity |

> Note: Docker support was added in v0.4.0 (Docker repo) and is planned to reach parity with native in v0.5.1+. The primary (native) repo's Docker section is still "coming soon" as of v0.5.0.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| server | "Path to your fail2ban.log?" | File path | Default: `/var/log/fail2ban.log` |
| server | "Server name/label for the dashboard?" | Free-text | Identifies this node in the multi-server dropdown |
| auth | "Admin password for the dashboard?" | Free-text (hashed via bcrypt at setup) | Viewer accounts are read-only; admin can ban/unban |
| integrations | "AbuseIPDB API key (optional)?" | Free-text | Enables IP reputation lookups; free API key available |
| integrations | "IP-Info.io API key (optional)?" | Free-text | Enables geo/provider lookups; free tier available |
| sync | "Will this be a primary (dashboard) server or a sync-client only?" | Primary / Client | Sync-clients push ban data to the primary; see [Sync-Concept](https://github.com/SubleXBle/Fail2Ban-Report/blob/main/Docs/Sync-Concept.md) |

## Software-layer concerns

### Architecture

- **Backend shell scripts** parse `fail2ban.log` → generate daily JSON event files in `archive/<server>/`
- **PHP frontend** reads the JSON files and renders the dashboard
- **UFW integration**: `firewall-update.sh` applies/removes rules; runs as root via cron
- **Blocklists**: stored as `*.blocklist.json` per jail, per server; metadata includes `active`/`pending` status, timestamps, and source
- **Auth**: bcrypt password storage; UUID + optional IP check for sessions
- **Multi-server sync**: primary exposes HTTPS endpoint; clients push data on a schedule

### Requirements (native install)

| Component | Notes |
|---|---|
| Fail2Ban with logging enabled | Required |
| UFW | Firewall integration (iptables support planned) |
| Apache web server | With HTTPS and `.htaccess` support |
| PHP 7.4+ with JSON support | Frontend |
| `jq` | JSON processing in shell scripts |
| `awk`, `curl` | Standard tools |

### Data paths

| Path | Purpose |
|---|---|
| `/opt/Fail2Ban-Report/` | Application root (settings, scripts) |
| `archive/<server>/` | Daily JSON event files |
| `*.blocklist.json` | Per-jail persistent blocklists |

### Docker (from Docker variant repo)

The Docker variant bundles the web interface in a container. Backend scripts and UFW still run on the host (the container mounts `archive/` and blocklists from the host):

```bash
# See https://github.com/SubleXBle/Fail2Ban-Report-Docker for full instructions
# A Helper-Script.sh is provided to configure .htaccess and container permissions
```

Key Docker difference: `/opt/Fail2Ban-Report/` and web-related files are inside the container; `archive/` and blocklist JSON files are mounted from the host.

## Upgrade procedure

**Native (≥ v0.3.3):**
> Follow [update-existing-installation.md](https://github.com/SubleXBle/Fail2Ban-Report/blob/main/Docs/update-existing-installation.md). Daily JSON files and blocklists are compatible across upgrades; rename blocklist files to `*.blocklist.json` if upgrading from pre-0.3.3.

**Docker variant:**
> Pull the new image from the Docker variant repo and recreate the container. Mounted volumes preserve data.

## Gotchas

- Backend scripts and UFW **must run on the host** — containerizing the firewall layer is not supported.
- The `.htaccess` IP whitelist is critical for access control; edit it before exposing the dashboard.
- Multi-server sync requires valid HTTPS certificates on all nodes (used for the pull-based sync endpoint).
- The Docker version may be 1 minor version behind the native release while integration testing is done.
- AbuseIPDB and IP-Info.io integrations require free API keys — configure in the web UI after first login.
- `firewall-update.sh` runs as root via cron; ensure the host is hardened before deployment.

## Links

- Native upstream repo: <https://github.com/SubleXBle/Fail2Ban-Report>
- Docker variant repo: <https://github.com/SubleXBle/Fail2Ban-Report-Docker>
- Sync concept: <https://github.com/SubleXBle/Fail2Ban-Report/blob/main/Docs/Sync-Concept.md>
- Chain of trust: <https://github.com/SubleXBle/Fail2Ban-Report/blob/main/Docs/chain-of-trust.md>
- Auth system: <https://github.com/SubleXBle/Fail2Ban-Report/blob/main/Docs/Authentication-System.md>
- New install guide: <https://github.com/SubleXBle/Fail2Ban-Report/blob/main/Docs/Setup-Instructions.md>
