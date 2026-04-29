---
name: Pangolin
description: Identity-aware reverse proxy + WireGuard tunneled access platform — expose web apps via Traefik and reach private resources through NAT-traversing site connectors. AGPL / dual-licensed.
---

# Pangolin

Pangolin (by Fossorial) combines a reverse-proxy management server with WireGuard-based site connectors. The central server (Traefik + Pangolin UI + optional **Gerbil** WireGuard gateway) handles routing, authentication, and Let's Encrypt; remote "sites" dial out to the server to expose internal resources without opening inbound ports. Think "Cloudflare Tunnel / Tailscale Funnel, self-hosted, with a real proxy UI on top".

- Upstream repo: <https://github.com/fosrl/pangolin>
- Docs: <https://docs.pangolin.net/>
- Quick-install guide: <https://docs.pangolin.net/self-host/quick-install>
- Image: `fosrl/pangolin` (Community Edition, AGPL). Enterprise image `fosrl/pangolin:ee-<ver>` under Fossorial Commercial License (free for personal use / SMBs under $100K revenue).

## Architecture in one minute

Three containers on the central VM:

1. **pangolin** — REST API + admin UI on `:3001` (internal)
2. **traefik** — reverse proxy on `:80`/`:443` with Let's Encrypt (and CrowdSec if enabled)
3. **gerbil** (optional) — WireGuard userspace gateway that terminates site tunnels on `:51820/udp` and shares network namespace with Traefik

Plus **newt** clients (separate binaries/containers at remote sites) that dial home to gerbil and advertise resources.

## Compatible install methods

| Infra                | Runtime                                    | Notes                                                      |
| -------------------- | ------------------------------------------ | ---------------------------------------------------------- |
| Single VM (1 GB+ RAM) | Docker + upstream installer (Go binary)   | **Recommended.** The installer templates compose/config    |
| Single VM            | Docker + hand-edited compose               | Start from `install/config/docker-compose.yml`             |
| DigitalOcean         | Marketplace one-click                      | Pre-configured install                                     |
| Kubernetes           | Not officially supported yet               | Gerbil + Traefik requires NET_ADMIN/SYS_MODULE             |

## Inputs to collect

| Input              | Example                                    | Phase     | Notes                                                              |
| ------------------ | ------------------------------------------ | --------- | ------------------------------------------------------------------ |
| Base domain        | `pangolin.example.com`                     | DNS       | Plus wildcard `*.pangolin.example.com` for each exposed resource   |
| Let's Encrypt email | `admin@example.com`                       | TLS       | Traefik auto-provisions per-host certs                             |
| Open ports         | TCP 80/443, UDP 51820/21820, UDP 443 (QUIC) | Firewall | 80/443 HTTP(S); 51820 WG; 21820 client relay; 443/udp for HTTP/3    |
| Admin email/password | first-run                                | Runtime   | Created through the setup wizard on first browse                   |
| Edition            | `community` or `enterprise`                | Install   | Installer asks; EE free under the terms above                      |
| `InstallGerbil`    | yes/no                                     | Install   | Skip only if terminating WireGuard elsewhere                       |
| CrowdSec           | yes/no                                     | Install   | Optional bot/abuse blocking integrated with Traefik                |

## Install via the official installer (recommended)

Per <https://docs.pangolin.net/self-host/quick-install>:

```sh
# 1. Install Docker + Docker Compose v2 on the VM.
# 2. Fetch the installer binary (replace <ver> with the latest release):
curl -fsSL https://github.com/fosrl/pangolin/releases/latest/download/installer_linux_amd64 -o pangolin-installer
chmod +x pangolin-installer
sudo ./pangolin-installer
```

The installer prompts for base domain, LE email, edition, whether to install Gerbil, whether to enable CrowdSec, whether to enable IPv6 — then writes `./config/`, `docker-compose.yml`, and runs `docker compose up -d`.

After boot, DNS the base domain + wildcard to the VM's public IP and browse `https://pangolin.example.com` to complete the setup wizard and create the admin account.

## Install via hand-edited compose

The installer's template is at <https://github.com/fosrl/pangolin/blob/main/install/config/docker-compose.yml> (Go template). The rendered structure:

- `pangolin` service on internal :3001 with `./config` mounted to `/app/config`
- `gerbil` cap_add NET_ADMIN + SYS_MODULE, owns ports 80/443/51820/udp/21820/udp
- `traefik` uses `network_mode: service:gerbil` when Gerbil is installed (ports appear on Gerbil) or binds 80/443 directly otherwise

A minimal reference example lives at <https://github.com/fosrl/pangolin/blob/main/docker-compose.example.yml>. Pin `fosrl/pangolin` to a release tag from <https://github.com/fosrl/pangolin/releases> — don't use `:latest`.

## Data & config layout

- `./config/` — all Pangolin state (SQLite by default; Postgres optional via `docker-compose.pgr.yml`)
- `./config/traefik/` — Traefik dynamic config + logs
- `./config/letsencrypt/` — ACME account + cert cache
- `./config/crowdsec/` — CrowdSec scenarios + data (if enabled)
- Environment variables and feature flags live in `./config/config.yml` (not a `.env` file)

## Connecting sites (newt clients)

Each remote site runs a `newt` container or binary and dials the central Pangolin. You get per-site tokens from the admin UI. See <https://docs.pangolin.net/self-host/manual-install/newt> for supported install methods (Docker, systemd, Windows service).

## Upgrade

1. Read release notes: <https://github.com/fosrl/pangolin/releases>.
2. Re-download the installer binary (or `git pull` your config repo) and run `sudo ./pangolin-installer upgrade` — it preserves `./config`.
3. Or manually: bump image tags in `docker-compose.yml`, `docker compose pull && docker compose up -d`.
4. Major version notes sometimes include a SQLite schema migration — the app runs it on boot; back up `./config/` first.

## Gotchas

- **AGPL ↔ Enterprise license.** The CE image is AGPL; EE has additional features (clustering, advanced SSO, SCIM) and its own license. If you deploy EE past the $100K revenue / personal-use thresholds, you need a paid license.
- **Traefik shares network namespace with Gerbil** when Gerbil is enabled. You cannot independently reach Traefik's dashboard; expose it via a file route.
- **Wildcard DNS is effectively mandatory.** Every exposed resource gets a subdomain; without a wildcard A record each new resource requires a DNS change.
- **NET_ADMIN + SYS_MODULE on Gerbil** means it can load kernel modules on the host. Treat Gerbil's container boundary as a strong trust line.
- **Kernel WireGuard vs userspace:** Gerbil falls back to userspace (wireguard-go) if the host kernel lacks `wg` support. This works but is slower.
- **Let's Encrypt rate limits** apply — test with `--staging` via the Traefik dynamic config before flipping to production, especially during onboarding of many subdomains.
- **Installer overwrites** `docker-compose.yml` and template outputs on each run. Customize only through `./config/` and compose override files.
- **QUIC (UDP 443)** is optional but silently disabled if the port is blocked; check Traefik logs if HTTP/3 isn't working.
- **CrowdSec is off by default.** Worth enabling for any internet-exposed deployment, but it adds a container and its own upgrade surface.
- **First-run wizard grants admin without email verification.** Do not boot the server with public DNS pointed before you're ready to claim the first-admin account.

## Links

- Docs: <https://docs.pangolin.net/>
- Quick install: <https://docs.pangolin.net/self-host/quick-install>
- Newt (site client): <https://docs.pangolin.net/self-host/manual-install/newt>
- Template compose: <https://github.com/fosrl/pangolin/blob/main/install/config/docker-compose.yml>
- Releases: <https://github.com/fosrl/pangolin/releases>
- Fossorial commercial license terms: <https://docs.pangolin.net/licensing>
