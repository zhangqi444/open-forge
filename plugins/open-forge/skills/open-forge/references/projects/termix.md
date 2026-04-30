---
name: Termix
description: Browser-based SSH / RDP / VNC / Telnet terminal + tunnel manager + remote file manager + Docker manager + server stats dashboard. Split-screen panels, OIDC + 2FA, SSH jump hosts + Warpgate + OPKSSH + port knocking. TypeScript (backend) + React (frontend). AGPL-3.0.
---

# Termix

Termix is a web-based remote-access Swiss Army knife. Open a browser, manage your SSH sessions, RDP/VNC/Telnet remote desktops, SSH tunnels, remote files, Docker containers, and server health dashboards — all without installing native clients on every device.

Key capabilities:

- **SSH terminal** — split-screen (up to 4 panels), tabbed browser-like UX, color themes, custom fonts
- **RDP / VNC / Telnet** — via Apache Guacamole's `guacd` backend; full in-browser remote desktop
- **SSH tunnel manager** — create + maintain `-L` / `-R` tunnels with auto-reconnect + health monitoring
- **Remote file manager** — view/edit code, images, audio, video on remote hosts; upload/download/rename/delete/move; `sudo` support
- **Docker management** — start/stop/pause/remove containers, view stats, `docker exec` in terminal (positioned as "simpler than Portainer/Dockge")
- **Server stats** — CPU, memory, disk, network, uptime, firewall status, port monitor (most Linux servers)
- **Auth**: local users + admin roles, OIDC (with access control), 2FA (TOTP), session management across platforms
- **SSH feature-rich**: jump hosts, Warpgate integration, TOTP-based conn, SOCKS5, host key verification, password autofill, [OPKSSH](https://github.com/openpubkey/opkssh), tmux, port knocking
- **Network graph dashboard** — visualize your homelab based on SSH hosts
- **Multi-platform**: web + desktop (Windows/Linux/macOS standalone) + PWA + native iOS + native Android

Trade-offs:

- ✅ One login, access every server (SSH-focused homelabs love this)
- ✅ RDP/VNC in the browser via Guacamole is genuinely nice
- ❌ You're now centralizing all your SSH access through one web app — it's a high-value attack target; MUST have 2FA + strong auth
- ❌ Younger project than e.g. Guacamole; smaller community

- Upstream repo: <https://github.com/Termix-SSH/Termix>
- Docs: <https://docs.termix.site>
- Install guide: <https://docs.termix.site/install>
- Discord: <https://discord.gg/jVQGdvHDrf>

## Architecture in one minute

- **Termix backend** (TypeScript/Node.js) — API + WebSocket gateway + SSH/SFTP/Docker client
- **Termix frontend** (React PWA) — served by the same backend, plus desktop + mobile app builds
- **guacd** (Apache Guacamole daemon) — handles RDP/VNC/Telnet protocols; optional (skip if you only need SSH)
- **Persistent volume** — users, hosts, tunnels, keys, saved sessions, network graph data

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                                       |
| ----------- | --------------------------------------------------- | --------------------------------------------------------------------------- |
| Single VM   | Docker Compose (termix + guacd)                     | **Upstream-recommended**                                                     |
| Single VM   | Docker (termix only, no RDP/VNC/Telnet)             | Skip `guacd` if SSH-only                                                    |
| Desktop     | Native app (Windows, Linux, macOS)                  | Standalone binary — can run without a backend                                |
| Mobile      | Native iOS (v15.1+) / Android (v7+) via App Store / Play Store / APK | Needs pairing with a Termix backend                      |
| Kubernetes  | Community deployment                                  | Not upstream-maintained                                                       |

## Inputs to collect

| Input          | Example                            | Phase     | Notes                                                     |
| -------------- | ---------------------------------- | --------- | --------------------------------------------------------- |
| Port           | `8080:8080`                        | Network   | Web UI                                                     |
| `guacd` port   | `4822:4822`                        | Network   | Only if using RDP/VNC/Telnet                               |
| Data volume    | `termix-data:/app/data`            | Storage   | Users, hosts, tunnels, SSH private keys (encrypted)         |
| Public URL     | `https://termix.example.com`       | DNS       | Behind HTTPS reverse proxy with WS support                 |
| OIDC creds     | client_id/secret/issuer             | Auth      | Optional; SSO                                              |
| Admin account  | created on first web visit          | Bootstrap | First user = admin; disable public signup after            |

## Install via Docker Compose (with RDP/VNC)

From README:

```yaml
services:
  termix:
    image: ghcr.io/lukegus/termix:v1.x.x    # pin; check releases
    container_name: termix
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - termix-data:/app/data
    environment:
      PORT: "8080"
    depends_on:
      - guacd
    networks:
      - termix-net

  guacd:
    image: guacamole/guacd:1.6.0
    container_name: guacd
    restart: unless-stopped
    ports:
      - "4822:4822"    # Optional: expose only if needed for debugging; otherwise private
    networks:
      - termix-net

volumes:
  termix-data:
    driver: local

networks:
  termix-net:
    driver: bridge
```

For SSH-only (no RDP/VNC), drop `guacd` + `depends_on` + `networks`:

```yaml
services:
  termix:
    image: ghcr.io/lukegus/termix:v1.x.x
    restart: unless-stopped
    ports: ["8080:8080"]
    volumes:
      - termix-data:/app/data
    environment:
      PORT: "8080"

volumes:
  termix-data:
```

## Reverse proxy

Termix uses WebSockets for live terminal streams — proxy MUST forward WS upgrade:

```nginx
location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 86400s;       # long terminals
}
```

Caddy auto-handles WS:

```
termix.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

## First-boot

1. Browse `https://termix.example.com`
2. Create the **first admin** account
3. **Settings → Authentication**: enable 2FA (TOTP) + optionally OIDC
4. **Disable public signup** if not wanted
5. Add SSH hosts: **Hosts → Add** — name, address, username, key or password, optional jump host / Warpgate / TOTP
6. Connect

## Data & config layout

Inside `/app/data/`:

- SQLite DB (or similar) — users, hosts, tunnels, sessions, OIDC config, network graph
- SSH private keys — stored encrypted at rest (key passphrases still protected)
- 2FA secrets — per-user
- Session state — for "resume where I left off"

## Backup

```sh
docker run --rm -v termix-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/termix-data-$(date +%F).tgz -C /src .
```

Include this in a **rotating encrypted backup** (Borg / Restic / Kopia) — the volume contains encrypted private keys, but the DB is a single point of compromise if the host is breached.

## Upgrade

1. Releases: <https://github.com/Termix-SSH/Termix/releases>. Frequent (weekly-ish).
2. `docker compose pull && docker compose up -d`. Migrations on startup.
3. Changelog often includes new SSH features (e.g., OPKSSH support added mid-2024). Read before upgrading.
4. Back up the data volume before each upgrade.

## Gotchas

- **Centralized SSH access = high-value target.** If Termix is compromised, attacker has a key chain to every server you paired. **Always enable 2FA** + put behind VPN/Tailscale or a hardened reverse proxy. Consider IP allow-listing.
- **SSH private keys stored encrypted at rest** but the decryption key is in the same volume — not hardware-backed. For high-sensitivity use, configure per-connection password/key re-prompts.
- **WebSocket-required.** Reverse proxies without WS forwarding = blank terminal, silent fail.
- **`guacd` listens on port 4822** — if you expose it publicly, attacker can proxy arbitrary RDP/VNC traffic through your Termix host. Keep guacd private (container-to-container bridge network).
- **Guacamole version pinned** to `1.6.0` in upstream example — guacd protocol has changed across versions; don't jump to `:latest` without testing.
- **Docker management** is simple-by-design. If you need multi-node Swarm/K8s UI, use Portainer Business / Dockge / Rancher.
- **RDP credentials per host** are stored in the DB. Same threat model as SSH keys.
- **Port knocking** + **TOTP-based SSH connections** + **Warpgate** integration let you layer auth; use them for high-value targets.
- **Desktop app** can run standalone (without the backend) — useful for local-only terminal use. Mobile apps require the backend.
- **PWA** install works from most browsers — it's a good "daily driver" option on iPad with keyboard.
- **OIDC access control** lets you scope who can log in by OIDC group (useful with Keycloak / Zitadel / Authelia).
- **Logs to stdout** — no file-based logging inside container by default.
- **AGPL-3.0** — public SaaS = source-sharing obligation; private use = fine.
- **Data import/export** supports migrating hosts/tunnels between instances (useful for DR).
- **Translation** ~30 languages via Crowdin.
- **Memory**: typical idle ~100-200 MB; spikes during active terminals + guacd sessions.
- **Alternatives worth knowing:**
  - **Apache Guacamole** (full) — battle-tested RDP/VNC/SSH gateway; heavier, more enterprise
  - **Sshwifty** — browser SSH only, simpler, Go-based
  - **Shellngn** — commercial web SSH/SFTP client
  - **Wetty** — minimal SSH-in-browser, no tunnel mgmt
  - **Teleport** — enterprise access proxy with audit, session recording, RBAC (recipe exists separately)
  - **Warpgate** — SSH/HTTP/MySQL proxy with session recording (pairs with Termix)
  - **Portainer** — for Docker management only

## Links

- Repo: <https://github.com/Termix-SSH/Termix>
- Docs: <https://docs.termix.site>
- Install: <https://docs.termix.site/install>
- Translations: <https://docs.termix.site/translations>
- Releases: <https://github.com/Termix-SSH/Termix/releases>
- Docker image: <https://github.com/Termix-SSH/Termix/pkgs/container/termix>
- Apache Guacamole: <https://guacamole.apache.org>
- OPKSSH: <https://github.com/openpubkey/opkssh>
- Issues / support: <https://github.com/Termix-SSH/Support/issues>
- Discord: <https://discord.gg/jVQGdvHDrf>
