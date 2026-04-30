---
name: Nexterm
description: "Open-source web-based server management — SSH/VNC/RDP in browser, SFTP, Docker app deployment, Proxmox LXC/QEMU management, 2FA + OIDC SSO, organizations, session recordings. Node.js. MIT."
---

# Nexterm

Nexterm is **"bring a browser, manage everything"** — an open-source web-based unified server manager. From a single web UI you get: **SSH/VNC/RDP remote terminals, SFTP file transfer, Docker app deployment via a catalog, Proxmox LXC + QEMU container management, per-organization isolation, 2FA + OIDC SSO, session recordings for audit, AI-assisted commands, snippet library, monitoring dashboards**.

Built + maintained by **gnmyt**. MIT-licensed. Active development; visible community. Positions itself as **"open-source replacement for commercial remote-access tools like Guacamole / Remmina / Teleport (basic tier) / XPipe"**.

Features:

- **Protocols**: SSH, VNC, RDP (in-browser via Guacamole-style rendering)
- **SFTP** file browser
- **Docker apps catalog** — deploy stacks via UI
- **Proxmox integration** — LXC + QEMU lifecycle
- **2FA** (TOTP)
- **OIDC SSO**
- **Organizations** — isolate servers + users
- **Session recording** — replay later (audit)
- **Snippets** — reusable command library
- **Monitoring** — server resource dashboards
- **AI command assistant** — configurable system prompt (`AI_SYSTEM_PROMPT` env)
- **Engine/Server split** — runtime modularity
- **Encryption** at rest for stored credentials (`ENCRYPTION_KEY`)

- Upstream repo: <https://github.com/gnmyt/Nexterm>
- Homepage + docs: <https://docs.nexterm.dev>
- Install docs: <https://docs.nexterm.dev/installation>
- Discord: <https://dc.gnmyt.dev>
- Docker images:
  - `nexterm/aio` — all-in-one (server + client + engine)
  - `nexterm/server` — server + client (external engine)
  - `nexterm/engine` — engine only

## Architecture in one minute

- **Node.js** backend + React frontend + separate "engine" process for terminal sessions
- **AIO image** bundles all three for simple deploys
- **Split deploy** (server + engine) for horizontal scaling / multi-region engine
- **Default port**: 6989 server, 7800 engine control-plane
- **DB**: per docs (likely SQLite or external)
- **Resource**: 300-500MB RAM typical; grows with active sessions + recordings

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker AIO         | **`nexterm/aio`** — server + client + engine                      | **Upstream-recommended for most**                                                  |
| Docker split       | `nexterm/server` + `nexterm/engine` separately                            | For distributed setups                                                                     |
| Bare-metal (dev)   | Node 18+ + Yarn; `yarn dev`                                                         | Dev mode only per README                                                                               |
| Kubernetes         | Standard Docker deploy                                                                               | Works                                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `term.example.com`                                              | URL          | **TLS mandatory** — credentials + session replay in transit                     |
| `SERVER_PORT`        | 6989 default                                                            | Network      | Reverse-proxied                                                                          |
| `ENCRYPTION_KEY`     | Long random string — **THE** secret                                     | Secret       | Encrypts SSH keys, passphrases, passwords stored in Nexterm                                                 |
| `CONTROL_PLANE_PORT` | 7800 default — engine ↔ server                                                | Internal     | Not exposed publicly                                                                                         |
| 2FA                  | Enforce for all admins                                                                 | Auth         | TOTP                                                                                                                 |
| OIDC provider        | Keycloak / Authentik / Authelia / Kanidm                                                          | Auth         | Optional but strongly recommended for teams                                                                                  |
| `AI_SYSTEM_PROMPT`   | optional                                                                                      | AI           | Determines AI command-generator behavior                                                                                                                |
| Backup strategy      | for DB + recordings                                                                                      | Ops          | Recordings can grow fast                                                                                                                                |

## Install via Docker (AIO)

```yaml
services:
  nexterm:
    image: nexterm/aio:latest                        # **pin version** in prod
    restart: unless-stopped
    ports: ["6989:6989"]
    volumes:
      - ./nexterm-data:/app/data
    environment:
      ENCRYPTION_KEY: ${ENCRYPTION_KEY}              # from /run/secrets/encryption_key supported
      NODE_ENV: production
      LOG_LEVEL: info
```

See <https://docs.nexterm.dev/installation> for authoritative values + OIDC + SMTP + AI setup.

## First boot

1. Generate strong `ENCRYPTION_KEY` → store in secrets manager
2. Deploy + browse URL → first-run creates admin
3. Enable 2FA on admin account IMMEDIATELY
4. Create an Organization + invite users
5. Add first SSH server → test connection
6. Configure OIDC if using external IdP
7. Set up session recordings retention policy (disk)
8. Put behind TLS
9. Back up `/app/data` (DB + recordings + encrypted credential store)

## Data & config layout

- `/app/data/` — DB + session recordings + uploaded SSH keys (encrypted)
- Env vars — all runtime config
- `/run/secrets/encryption_key` — supported Docker Secrets path for the critical secret

## Backup

```sh
# Stop for consistency or use online backup for the DB
docker compose stop nexterm
sudo tar czf nexterm-$(date +%F).tgz nexterm-data/
docker compose start nexterm
```

Crucially: **back up `ENCRYPTION_KEY` separately + securely**. Losing the key = all stored SSH keys/passwords are unrecoverable.

## Upgrade

1. Releases: <https://github.com/gnmyt/Nexterm/releases>.
2. Docker: bump tag; restart. Migrations run on boot.
3. **Back up DB before major versions.**
4. Engine + server version compatibility — keep them pinned to matching versions if split-deployed.

## Gotchas

- **`ENCRYPTION_KEY` is THE critical secret.** Nexterm stores SSH keys + passwords + passphrases for every server you manage, encrypted at rest with this key. If you LOSE the key = all credentials unrecoverable. If key LEAKS = attacker with DB access can decrypt EVERY credential you've entered. Treatment: (a) generate with `openssl rand -hex 32` (b) store in a password manager / secrets vault (c) use `/run/secrets/encryption_key` Docker Secrets path (d) back up separately from DB (e) NEVER commit to git. (f) Rotate procedure is likely "export secrets, rewrite with new key, verify" — nontrivial.
- **Nexterm = hub-of-credentials = crown-jewel attack target.** A compromised Nexterm = compromised every server you manage through it. Treat with the same hardening as you would a password manager or bastion host:
  - **MFA enforced** on all accounts (not just admins)
  - **Reverse proxy with client-cert auth** or **IP allowlist** or **VPN-only access** for high-value deployments
  - **OIDC with short-lived tokens** + conditional access (geo, device posture)
  - **Audit session recordings** regularly
  - **Log to external SIEM** — if the box is compromised, you need logs elsewhere
- **TLS is MANDATORY.** In-browser RDP/VNC/SSH streams credentials + session content. HTTP = credentials leaked to the network.
- **Browser-based remote access UX**: slower than native clients for latency-sensitive work (coding over SSH, gaming over RDP). Great for "quick check" and audit workflows; native clients (OpenSSH, Remmina, Microsoft Remote Desktop) are still faster for heavy daily use.
- **Proxmox integration is a power feature but a big blast-radius.** LXC/QEMU lifecycle control from a web UI = attacker with Nexterm access can create/destroy VMs. Gate access carefully.
- **Session recordings = privacy + compliance implications.** Recording every typed command is great for audit but also means: developer keystrokes (including passwords typed inline) are stored. Consider (a) retention policy (b) access controls on recordings (c) warn users that sessions are recorded (labor-law-dependent in some jurisdictions).
- **Docker-apps catalog**: one-click deploy of common apps via Docker. Useful but: review catalog entries' images + pin versions before production use. Convenience-vs-supply-chain tradeoff.
- **AI command assistant**: sends prompts + shell context to an LLM endpoint. If using a cloud LLM = your command history + server fingerprints leave your network. Self-host Ollama or similar for local AI. Same AI-privacy-boundary class as WhoDB (batch 77), Baserow-etc — growing family.
- **OIDC integration**: supported; documented. Use it for team deployments. Local-auth-only is fine for solo homelab.
- **`AI_SYSTEM_PROMPT` example in README**: `"You are a Linux command generator assistant."` — audit + customize. The prompt shapes what the AI suggests; leave it dumb or bias it toward safe commands.
- **Engine-server split** for distributed deployments: run engine in target environments close to servers (low latency), server central. Worthwhile for multi-region ops; overkill for homelab.
- **`ENCRYPTION_KEY` rotation procedure** likely requires export/re-import. Plan: rotate annually OR on suspected compromise. Keep old key available during transition.
- **Alternative: SSO + no-passwords-stored**: for sensitive deployments, configure Nexterm to use SSH cert-based auth or per-user SSH keys fetched from an SSH CA (e.g., Smallstep, HashiCorp Vault SSH) rather than storing passwords. Reduces ENCRYPTION_KEY blast-radius.
- **MIT license** — maximally permissive.
- **Project health**: gnmyt solo core + Discord community + active. Bus-factor mitigation: (a) MIT + clean Node stack (b) Docker distribution (c) small surface area. Sustained release cadence observed.
- **Alternatives worth knowing:**
  - **Apache Guacamole** — the incumbent web-based remote-access gateway (since 2012); Java; very mature; less polished UI
  - **Teleport** (Gravitational) — enterprise-grade; SSH cert authority + browser access; complex; commercial-tier-heavy
  - **Bastion Host + tmate** — lightweight alternatives for small teams
  - **Warpgate** — Rust-based SSH/HTTP gateway; modern
  - **Cloudflare Zero Trust / Teleport / BoundaryHQ / StrongDM** — commercial zero-trust
  - **XPipe** — desktop, not web-based; different UX
  - **RDPgateway / noVNC** — single-protocol alternatives
  - **Choose Nexterm if:** want a unified web UI + clean modern UX + Docker-easy deploy + self-hosted commercial-feature-set.
  - **Choose Guacamole if:** want battle-tested incumbent + Java shop + willing to invest in its UX.
  - **Choose Teleport if:** enterprise-grade + SSH CA + compliance + budget.
  - **Choose Warpgate if:** Rust stack + minimal + modern.

## Links

- Repo: <https://github.com/gnmyt/Nexterm>
- Docs: <https://docs.nexterm.dev>
- Installation: <https://docs.nexterm.dev/installation>
- Discord: <https://dc.gnmyt.dev>
- Docker Hub (AIO): <https://hub.docker.com/r/nexterm/aio>
- Releases: <https://github.com/gnmyt/Nexterm/releases>
- Apache Guacamole (alt): <https://guacamole.apache.org>
- Teleport (alt): <https://goteleport.com>
- Warpgate (alt): <https://github.com/warp-tech/warpgate>
- XPipe (alt): <https://xpipe.io>
