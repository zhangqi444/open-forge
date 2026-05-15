---
name: WeTTY
description: "Terminal access in browser over HTTP/HTTPS — SSH (or local shell) delivered through xterm.js + websockets. Lightweight Node.js bridge for remote TTY access from any browser. MIT."
---

# WeTTY

WeTTY (Web + TTY) is **terminal access in your browser** — a Node.js webapp that bridges an SSH connection (or the host's local `/bin/login`) to **xterm.js** over **websockets**, so any browser becomes a usable terminal. Alternative to older AjaxTerm/AnyTerm projects, but modern (xterm.js = real terminal emulator in JS; websockets = real-time responsiveness).

Developed by **Cian Butler (@butlerx)**. Mature, stable, single-purpose; small active community (41 contributors).

**Core use case**: SSH to a bastion/jumpbox from a browser where native SSH clients are inconvenient (locked-down Chromebooks, mobile browsers, shared terminals, corp workstations, educational labs). Also used as a bundled-shell for dev containers, cloud IDEs, Raspberry Pi kiosks, educational environments.

Features:

- **xterm.js-based** — proper terminal emulation in browser (colors, cursor, mouse, resize)
- **Websocket transport** — low-latency vs Ajax-polling alternatives
- **SSH mode** — jump through WeTTY to SSH anywhere
- **Local shell mode** — direct `/bin/login` / custom shell on the WeTTY host
- **Pre-specified user in URL** — `/wetty/ssh/<username>` to skip prompt
- **SSL** — ship own cert or terminate at reverse proxy
- **Configurable base path** — host under `/wetty/` or any path
- **Optional iframe embedding** — for dashboards
- **CLI or Docker** deploy
- **Published to npm** (`npm i -g wetty`) + Docker Hub (`wettyoss/wetty`)

- Upstream repo: <https://github.com/butlerx/wetty>
- Docs: <https://butlerx.github.io/wetty/>
- Docker Hub: <https://hub.docker.com/r/wettyoss/wetty>
- npm: <https://www.npmjs.com/package/wetty>

## Architecture in one minute

- **Node.js** server (requires Node 18+)
- **xterm.js** frontend
- **Websockets** between browser + server
- **SSH or login(1)** spawned per session
- **No persistent state** — stateless per-session; close browser → session ends
- **Resource**: tiny — <100 MB RAM per 10 concurrent sessions

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker (`wettyoss/wetty`)**                                      | **Most popular**                                                                   |
| Bare-metal / any-Node | `npm i -g wetty` + systemd                                              | Light + native                                                                             |
| Kubernetes         | Community manifests                                                                           | Works; often as a sidecar or debug container                                                                              |
| Raspberry Pi       | Docker or npm                                                                                 | Popular for Pi admin                                                                                                     |

## Inputs to collect

| Input                | Example                                              | Phase        | Notes                                                                    |
| -------------------- | ---------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Mode                 | `--ssh-host` (SSH jump) OR local login                       | Mode         | Determines what terminal user gets                                              |
| SSH target           | `bastion.internal` : 22                                              | SSH          | If SSH mode                                                                           |
| Base path            | `/wetty` (default)                                                      | URL          | Configurable                                                                                           |
| TLS                  | certs direct OR reverse-proxy                                                       | Transport    | **Mandatory for production** — terminal traffic = sensitive                                                                        |
| Auth                 | your SSH credentials / `/bin/login` credentials                                                                 | Auth         | Plus additional HTTP auth (reverse-proxy based)                                                                                     |
| Iframe embedding     | disabled by default                                                                             | UI           | Enable only if you know you need it                                                                                                    |

## Install via Docker

```yaml
services:
  wetty:
    image: wettyoss/wetty:2.5.0                          # pin a specific version
    container_name: wetty
    restart: unless-stopped
    command:
      - "--ssh-host=bastion.internal"
      - "--ssh-port=22"
      - "--base=/wetty"
    ports:
      - "3000:3000"
```

Browse `http://<host>:3000/wetty` → SSH login prompt → type password (or pubkey if configured).

## Install via npm (bare-metal)

```sh
npm -g i wetty
wetty --ssh-host=bastion.internal --port=3000 --ssl-key=/etc/wetty/tls.key --ssl-cert=/etc/wetty/tls.crt
```

Wrap with systemd or similar.

## First boot

1. Browse `http://host:3000/wetty` → login prompt
2. Authenticate (SSH or local login)
3. Verify shell works
4. Front with reverse proxy + HTTPS + forward-auth (Authelia/Authentik/OIDC) for public exposure
5. For internal deployments: at minimum TLS + HTTP Basic Auth via reverse proxy
6. Lock down with network ACLs / VPN

## Data & config layout

- **No persistent state** — WeTTY is a bridge; no storage
- Config via CLI flags or `--conf <file>` (YAML/JSON)
- Logs to stdout / stderr

## Backup

Nothing to back up. Re-deploy from compose file / install command.

## Upgrade

1. Releases: <https://github.com/butlerx/wetty/releases>.
2. Docker: bump tag.
3. npm: `npm update -g wetty`.
4. Test SSH connection after upgrade — xterm.js/Node.js updates occasionally shift behavior.

## Gotchas

- **WeTTY is a gateway to SSH/shell — treat it like SSH itself.** Same threat model as batch 70 Webmin or batch 69 Livebook:
  - Never expose on public internet without strong auth + TLS + IP allowlist
  - HTTP Basic Auth alone = insufficient if internet-facing; use forward-auth (Authelia/Authentik) + OIDC
  - Log access; alert on brute-force
- **TLS is MANDATORY for any production use.** Plaintext WeTTY = plaintext passwords + plaintext terminal content on the wire. Reverse-proxy terminate TLS or use `--ssl-cert`/`--ssl-key`.
- **`--ssh-key` option with no password = insecure per the CLI help itself**: *"connection will be password-less and insecure!"* Only use this for specific kiosk / demo scenarios where you intend low-auth. Prefer interactive SSH key auth via agent forwarding.
- **Iframe embedding**: disabled by default for clickjacking protection. Only enable `--allow-iframe` when you specifically know you want WeTTY embedded in another site AND you've validated the embedding page.
- **Default port 3000**: conflicts with many Node dev servers. Pick a dedicated port in production.
- **Node version**: requires Node 18+. Check your Docker base image stays current.
- **Running as root launches `/bin/login`**: WeTTY behavior changes based on UID. If you run the WeTTY process as root and don't set `--force-ssh`, users get `/bin/login` prompt directly on the WeTTY host. This is often NOT what you want.
  - **Recommended**: run WeTTY as non-root user + use `--force-ssh` to always enforce SSH hop.
- **Session cleanup**: closed browser = session gone. Long-running tasks need tmux/screen/nohup — WeTTY is a display bridge, not a session manager.
- **File transfer**: limited support (see docs/downloading-files). For real file transfer use SCP/SFTP/rsync + proper tools.
- **Browser compatibility**: whatever xterm.js supports — modern browsers; IE/Edge-legacy not supported.
- **Reverse-proxy path handling**: set `--base` correctly and make sure proxy forwards websocket upgrades (`Upgrade: websocket` header). Traefik/nginx-proxy/Caddy handle this out-of-box.
- **Audit logging**: WeTTY itself doesn't audit. Enable server-side auth logs (sshd, PAM) and reverse-proxy access logs.
- **No MFA built-in**: add via SSH (Google Authenticator PAM module) or front reverse proxy with MFA (Authelia).
- **Alternatives worth knowing:**
  - **ttyd** — C-based lighter alternative; similar feature set
  - **Gotty** — Go-based; share terminal output via web
  - **Guacamole** — full remote-desktop/RDP/VNC + SSH gateway; heavier
  - **shellinabox** — older Python-based; less active
  - **Teleport** — enterprise SSH proxy with full audit + recording
  - **sshwifty** — Go-based; modern competitor
  - **Cloud consoles** (AWS Session Manager, Azure Bastion, GCP IAP) — managed equivalent
  - **Choose WeTTY if:** you want a small Node-based SSH-over-web bridge + xterm.js quality + MIT license.
  - **Choose Teleport if:** enterprise SSH audit + recording + compliance.
  - **Choose Guacamole if:** also need RDP/VNC in addition to SSH.
- **License**: **MIT**.

## Links

- Repo: <https://github.com/butlerx/wetty>
- Docs: <https://butlerx.github.io/wetty/>
- Docker Hub: <https://hub.docker.com/r/wettyoss/wetty>
- npm: <https://www.npmjs.com/package/wetty>
- Releases: <https://github.com/butlerx/wetty/releases>
- Flags: <https://butlerx.github.io/wetty/flags>
- HTTPS + nginx: <https://butlerx.github.io/wetty/nginx>
- Auto-login: <https://butlerx.github.io/wetty/auto-login>
- xterm.js: <https://xtermjs.org>
- ttyd (alt): <https://github.com/tsl0922/ttyd>
- Gotty (alt): <https://github.com/yudai/gotty>
- Guacamole: <https://guacamole.apache.org>
- Teleport (enterprise): <https://goteleport.com>
