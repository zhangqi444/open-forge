---
name: Warpgate
description: "Smart, fully transparent SSH / HTTPS / Kubernetes / MySQL / PostgreSQL bastion host — no client-app / SSH-wrapper needed. Built-in 2FA + OIDC SSO + session recording + replay. Single Rust binary, SQLite default. Apache-2.0."
---

# Warpgate

Warpgate is **a modern bastion host / smart proxy** that sits in your DMZ and accepts SSH, HTTPS, Kubernetes, MySQL, and PostgreSQL connections, authenticates the user (with local accounts + TOTP 2FA + OIDC SSO), and then *transparently* proxies the connection to the target host. Every session is optionally recorded and replayable through a built-in web admin UI.

Compared to a jump host / VPN / Teleport:

- **1:1 user-target assignment** — admins grant specific users specific targets (no "full LAN access")
- **Zero client customization** — `ssh alice:my-server@warpgate.example.com` works from any SSH client; HTTPS uses target-selection page
- **Built-in 2FA + SSO** (OIDC) — no PAM tricks
- **Session recording + replay** — watch terminal sessions live or later; HTTP traffic browsed via admin UI
- **Non-interactive supported** — scp, ansible, git over SSH all work
- **Single binary, no dependencies** — Rust-native
- **Command-level audit** — knows what commands were run over SSH

Protocols proxied:

- **SSH** — incl. subsystems (sftp, scp), port forwarding (configurable allow/deny)
- **HTTPS** — arbitrary web apps; Warpgate presents a target selector; can switch without reconnect
- **Kubernetes** — kubectl proxy
- **MySQL + PostgreSQL** — wire protocol proxy with auth

- Upstream repo: <https://github.com/warp-tech/warpgate>
- Docs: <https://warpgate.null.page>
- Releases: <https://github.com/warp-tech/warpgate/releases>
- Discord: <https://discord.gg/Vn7BjmzhtF>
- Ko-fi: <https://ko-fi.com/J3J8KWTF>

## Architecture in one minute

- **Single Rust binary** (`warpgate`) — all protocols in one process
- **SQLite** default DB (users, targets, tickets, sessions, audit log); Postgres optional
- **Web admin UI** — same process, ports bound per-protocol
- **Session recording** — terminal recordings as asciinema-style; HTTP flow logs in DB
- **TLS** — ACME (Let's Encrypt) built-in, or use external certs
- **No external dependencies** — no Redis, no Nginx required

## Compatible install methods

| Infra         | Runtime                                   | Notes                                                                         |
| ------------- | ----------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM     | **Native binary + systemd**                  | **Upstream-recommended**                                                          |
| Single VM     | **Docker**                                         | Official image                                                                            |
| Kubernetes    | Community manifests                                     | Works                                                                                     |
| Raspberry Pi  | arm64 binary available                                          | Fine for home DMZ                                                                                  |
| Managed       | — (no SaaS)                                                            |                                                                                                           |

## Inputs to collect

| Input              | Example                            | Phase      | Notes                                                              |
| ------------------ | ---------------------------------- | ---------- | ------------------------------------------------------------------ |
| Domain             | `warpgate.example.com`                 | URL        | Admin UI + HTTPS proxy entry                                             |
| Ports              | 2222 (SSH) / 8888 (HTTPS) / 3306 (MySQL) / 5432 (Postgres) / 8443 (k8s) | Network    | Per-protocol listen ports                                                                 |
| Admin user         | first user in setup                                    | Bootstrap  | Configure via `warpgate setup`                                                                    |
| 2FA                | TOTP enroll after first login                                  | Auth       | Or OIDC                                                                                                   |
| OIDC (opt)         | client id + secret + issuer                                              | SSO        | Google / Azure / Authentik / Keycloak / etc.                                                                              |
| Targets            | `alice@prod-db: host=db.internal, user=alice, port=22`                          | Config     | Add via admin UI                                                                                                                |
| TLS certs          | ACME automatic or custom                                                                | Security   | Admin UI + HTTPS proxy                                                                                                                       |

## Install (binary + systemd)

```sh
# Grab release
wget https://github.com/warp-tech/warpgate/releases/download/v0.x.x/warpgate-v0.x.x-x86_64-linux
sudo mv warpgate-v0.x.x-x86_64-linux /usr/local/bin/warpgate
sudo chmod +x /usr/local/bin/warpgate

# Create config + admin user (interactive)
sudo mkdir /var/lib/warpgate
cd /var/lib/warpgate
sudo warpgate setup

# Edit /etc/systemd/system/warpgate.service — point at config.yaml
sudo systemctl enable --now warpgate
```

## Install (Docker)

```yaml
services:
  warpgate:
    image: ghcr.io/warp-tech/warpgate:0.x        # pin
    container_name: warpgate
    restart: unless-stopped
    volumes:
      - ./data:/data
    ports:
      - "2222:2222"            # SSH
      - "8888:8888"            # HTTPS (proxy + admin UI)
      - "3306:3306"            # MySQL (if used)
      - "5432:5432"            # Postgres (if used)
    command: ["--config", "/data/warpgate.yaml", "run"]
```

Run `warpgate setup` once inside the container to initialize config:
```sh
docker run --rm -it -v $(pwd)/data:/data ghcr.io/warp-tech/warpgate:0.x setup
```

## First boot

1. Browse `https://warpgate.example.com:8888/` → log in as admin (from setup)
2. **Enroll 2FA** immediately (Profile → 2FA → TOTP)
3. Users → create operational users; set passwords + 2FA requirements
4. Targets → + HTTP target (URL, auth policy) / SSH target (host, user, port)
5. Assign target permissions per user (roles)
6. Test SSH: `ssh alice:target-name@warpgate.example.com -p 2222` → prompted for password + TOTP → connected
7. Test HTTPS: browse `https://warpgate.example.com:8888/?warpgate-login` → pick target → use
8. Watch session live in admin UI → Sessions → active session

## Data & config layout

- `config.yaml` — ports, roles, SSO, listeners
- `data.sqlite3` (or Postgres) — users, targets, sessions, audit log
- `recordings/` — terminal session replays
- TLS certs — ACME storage or paths to custom certs

## Backup

```sh
# Stop Warpgate briefly
sudo systemctl stop warpgate
tar czf warpgate-$(date +%F).tgz /var/lib/warpgate/
sudo systemctl start warpgate
```

Recordings can grow — archive + rotate separately if retention matters.

## Upgrade

1. Releases: <https://github.com/warp-tech/warpgate/releases>. Active.
2. **Back up data directory first.**
3. Binary: replace binary → restart systemd service.
4. Docker: bump tag → restart.
5. Schema migrations run on startup (check logs).
6. Read release notes — protocol support additions are common.

## Gotchas

- **Not a replacement for strong upstream auth.** Warpgate auths users at the gate; then proxies. The target host still sees Warpgate's SSH client identity (unless you use cert-based forwarding). If your targets rely on IP allowlists, they'll see Warpgate's IP, not the user's.
- **Port forwarding** in SSH can be a security hole (tunneling arbitrary traffic). Disable it per-target if not needed.
- **Session recording ethics + law** — inform users their sessions are recorded (pop banner or policy doc); some jurisdictions require explicit consent.
- **Recording storage growth** — Linux admin sessions aren't huge, but 24/7 recording across 100 users can consume GBs weekly. Retention policy + rotation.
- **HTTPS target selection** — Warpgate injects a target picker UI for browser HTTP; non-browser clients (curl, API clients) need special handling (use session tokens).
- **MySQL/Postgres proxy** — proxies the wire protocol. TLS to target required or use internal LAN. Some advanced driver features may not pass through.
- **Kubernetes proxy** — proxies kubectl; generate a kubeconfig pointing at Warpgate URL.
- **Admin UI port** is usually the HTTPS proxy port (`/@warpgate/admin`). Default scheme uses subpaths.
- **2FA setup** — require for all users; recovery codes optional. Don't let admins opt out.
- **OIDC mapping** — external-user to Warpgate user; ensure group-to-role mapping is tight.
- **SSH client compatibility** — OpenSSH 7+ works; some older/embedded clients may struggle with novel kex/auth negotiations.
- **Single point of failure** — Warpgate down = no admin access to protected hosts. Have a break-glass admin path (direct SSH from a specific bastion IP, documented + monitored).
- **Fail-secure default** — if DB is corrupt, Warpgate refuses connections. Good for security; plan DR.
- **No HA out of the box** — run a warm-standby for critical environments (sync data dir via DRBD / replica) or use Postgres replica.
- **Scope creep warning** — resist the urge to put your whole intranet behind Warpgate. Use it for admin access; use proper SSO for user-facing web apps.
- **Written in Rust** — stable, memory-safe; small binary; fast; small active community.
- **License**: Apache-2.0.
- **Alternatives worth knowing:**
  - **Teleport** (OSS Community / commercial Enterprise) — the commercial reference; deeper but Go-heavy; Apache-2.0 (community)
  - **HashiCorp Boundary** — BSL license; identity-based access
  - **StrongDM** — commercial SaaS for credentialed access
  - **Pangolin** — auth-enforcing reverse proxy (HTTP-focused; separate recipe)
  - **sshpiper** — SSH-only proxying; Apache-2.0
  - **Sish** — SSH tunnel tool (different use case)
  - **OpenSSH ProxyJump + 2FA** (PAM) — DIY route
  - **Apache Guacamole** — HTML5-based access to RDP/VNC/SSH; different UX (separate recipe likely)
  - **Cloudflare Tunnel + Access** — SaaS zero-trust
  - **Tailscale SSH** — simpler tunnels + access list
  - **Choose Warpgate if:** you want a single self-hosted gate for SSH + HTTPS + DB access with built-in 2FA/SSO/recording.
  - **Choose Teleport if:** you need the broadest protocol support + commercial backing.
  - **Choose Tailscale SSH if:** you want simpler ACLs + mesh VPN; don't need session recording.
  - **Choose Guacamole if:** you need RDP/VNC + HTML5 web client, not CLI.

## Links

- Repo: <https://github.com/warp-tech/warpgate>
- Docs: <https://warpgate.null.page>
- Getting started: <https://warpgate.null.page/getting-started/>
- Docker getting started: <https://warpgate.null.page/getting-started-on-docker/>
- Releases: <https://github.com/warp-tech/warpgate/releases>
- Nightly builds: <https://nightly.link/warp-tech/warpgate/workflows/build/main>
- Discord: <https://discord.gg/Vn7BjmzhtF>
- FLOSS/fund: <https://floss.fund>
- Security policy: <https://github.com/warp-tech/warpgate/security/policy>
- Teleport alternative: <https://github.com/gravitational/teleport>
- sshpiper alternative: <https://github.com/tg123/sshpiper>
