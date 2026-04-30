---
name: MeshCentral
description: "Web-based remote monitoring and management — free self-hostable alternative to TeamViewer/ConnectWise/Splashtop/ScreenConnect. Remote desktop, terminal, file transfer across Windows/Linux/macOS/Android. Single Node.js server. Apache-2.0."
---

# MeshCentral

MeshCentral is **a free, self-hostable remote management platform** — deploy one server; install an agent on every PC, Mac, Linux box, or Android device you want to manage; get web-based remote desktop, terminal, file transfer, power control, chat, scripting, alerts, and reporting.

It's the **open-source answer to TeamViewer / ConnectWise Control / ScreenConnect / AnyDesk / Splashtop / Kaseya** — you run the server, you own the data, no per-seat licensing, no phone-home telemetry.

Heavily used by **MSPs** (managed service providers) and **IT departments** wanting to self-host their RMM.

Features:

- **Remote desktop** — via WebRTC or server-relay; works through firewalls/NAT
- **Remote terminal** (SSH-like shell, PowerShell, cmd)
- **File transfer** — upload/download, browse filesystem
- **Agent-based** (always-connected) + **Agentless** modes
- **Cross-platform agents**: Windows, Linux, macOS, Android (app), iOS (limited)
- **Device groups** — organize; assign users
- **User roles + permissions** — per-device-group granular
- **2FA** — TOTP + WebAuthn/passkeys + backup codes
- **Power control** — Wake-on-LAN, shutdown, restart, Intel AMT/vPro
- **Scripts** — run shell commands remotely; schedule; batch
- **Alerts** — email / webhook / Teams / Slack / Telegram on disconnect/reconnect
- **Chat** — user-to-user; audio/video (WebRTC)
- **Sessions recording** (enterprise-ish feature)
- **MeshCentral Router** — port forwarding tunneled through the server (expose a LAN service through MC)
- **Certificate-based trust** — agents pin server certs
- **TLS offload / reverse-proxy friendly** (nginx/Caddy/HAProxy)
- **SSO** — OIDC / SAML
- **HashiCorp Vault** integration for secrets
- **Database** — NeDB (default, embedded) or **MongoDB** (recommended for >100 agents)
- **Very active development** by Ylian Saint-Hilaire (formerly Intel, now self-funded)

- Upstream repo: <https://github.com/Ylianst/MeshCentral>
- Website: <https://meshcentral.com>
- Docs (new searchable): <https://ylianst.github.io/MeshCentral/>
- Design & Architecture Guide (PDF): <https://meshcentral.com/docs/MeshCentral2DesignArchitecture.pdf>
- User's Guide (PDF): <https://meshcentral.com/docs/MeshCentral2UserGuide.pdf>
- Installation Guide (PDF): <https://meshcentral.com/docs/MeshCentral2InstallGuide.pdf>
- YouTube channel: <https://www.youtube.com/@MeshCentral>

## Architecture in one minute

- **Single Node.js server** — `meshcentral` npm package
- **Database**: **NeDB** (embedded, default, single-file JSON-ish) or **MongoDB** (recommended for scale)
- **TLS**: built-in Let's Encrypt support OR reverse-proxy-terminated
- **Agents connect** via WebSocket over TLS (port 443 typically)
- **Relay vs Direct**: WebRTC used when possible; falls back to server-relayed
- **MeshAgent**: tiny (~10 MB) cross-platform agent; auto-updates
- **Plugins** supported (community)

## Compatible install methods

| Infra              | Runtime                                              | Notes                                                                         |
| ------------------ | ---------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **`npm install -g meshcentral`** + Node.js 16+/18+/20+   | **Upstream-documented primary path**                                              |
| Single VM          | **Docker (`typhonragewind/meshcentral` community)**                    | Works; not official                                                                          |
| Single VM          | Windows installer                                                                   | For Windows-centric MSPs                                                                                 |
| Kubernetes         | Community manifests                                                                             | Works                                                                                                              |
| Raspberry Pi       | arm64 Node.js                                                                                                 | Works; NeDB fine for small fleets                                                                                              |
| Managed SaaS       | — (no official SaaS; some MSP communities offer hosted MC)                                                                |                                                                                                                                            |

## Inputs to collect

| Input              | Example                                      | Phase      | Notes                                                                      |
| ------------------ | -------------------------------------------- | ---------- | -------------------------------------------------------------------------- |
| Public domain      | `mc.example.com`                                   | URL        | **Stable FQDN required** — agents pin it                                          |
| Public IP          | static recommended                                      | Network    | Port 443 + 80 inbound                                                                     |
| TLS                | Let's Encrypt built-in OR your cert                                 | Security   | For agent trust                                                                                            |
| DB                 | NeDB (default) or MongoDB                                                | Storage    | MongoDB for >100 agents                                                                                              |
| Admin user         | via signup on first connect                                                   | Bootstrap  | Lock signup after creating admin                                                                                                |
| SMTP               | for email alerts + password reset                                                         | Email      | Recommended                                                                                                                          |
| SMS (opt)          | Twilio                                                                                          | Auth/Alerts | For SMS 2FA                                                                                                                                     |

## Install (npm)

```sh
# Prereqs
sudo apt install -y nodejs npm        # or nvm for recent Node.js
# Install
mkdir meshcentral && cd meshcentral
npm install meshcentral
# First run — creates config.json, generates certs, downloads self-signed
node node_modules/meshcentral
# Visit https://<host> on port 443 — create first admin account
# Ctrl-C; edit config.json for domain + LE; restart
```

Abbreviated `config.json`:

```json
{
  "settings": {
    "Cert": "mc.example.com",
    "Port": 443,
    "RedirPort": 80,
    "MongoDb": "mongodb://localhost/meshcentral",
    "WANonly": true,
    "SelfUpdate": false
  },
  "domains": {
    "": {
      "Title": "Acme IT",
      "Title2": "Remote Mgmt",
      "NewAccounts": false,                     // disable public signup!
      "UserAllowedIP": "",
      "certUrl": "https://mc.example.com:443/"
    }
  },
  "letsencrypt": {
    "email": "ops@example.com",
    "names": "mc.example.com",
    "production": true
  }
}
```

Full reference: <https://ylianst.github.io/MeshCentral/>.

## First boot

1. Browse `https://mc.example.com` → create first admin account → **disable `NewAccounts`** in config.json + restart
2. Enable 2FA on admin account
3. Create a Device Group (e.g., "Workstations") → pick mesh type (**Agent** recommended)
4. Download agent → install on a test PC
5. Agent connects → appears in dashboard
6. Try remote desktop → terminal → file transfer
7. Configure SMTP → enable email alerts
8. Add more admin/operator accounts with role-limited access

## Data & config layout

- `config.json` — main config
- `meshcentral-data/` — NeDB files / certs / plugins
- `meshcentral-backups/` — auto DB backups
- `meshcentral-files/` — user-uploaded files
- `meshcentral-web/` — custom branding
- MongoDB (if used) — separate

## Backup

```sh
# Stop mesh first for consistent backup (seconds)
sudo systemctl stop meshcentral       # or kill the node process
tar czf mc-$(date +%F).tgz meshcentral-data/ meshcentral-files/ config.json
sudo systemctl start meshcentral
```

**Losing `meshcentral-data/` = losing agent trust certificates = every agent needs re-install.** Offsite backup mandatory.

## Upgrade

1. Releases: <https://github.com/Ylianst/MeshCentral/releases>. **Extremely active** — multiple releases per week.
2. `cd meshcentral && npm update meshcentral` → restart
3. Auto-update: set `SelfUpdate: true` in config.json (pulls new agent + server). For production, consider manual updates + testing.
4. Agents auto-update — verify on a canary machine before mass rollout.

## Gotchas

- **Agent trust is tied to server certificate.** If you lose `meshcentral-data/` and restore from nothing, agents won't trust the new server → all must be reinstalled. **Back up that directory religiously.**
- **Domain must not change.** Agents pin the FQDN. Moving from `mc.example.com` to `rmm.example.com` = reinstall all agents.
- **Disable `NewAccounts`** after creating your admin. Otherwise anyone who finds your MC instance can create an account.
- **2FA mandatory on admin accounts.** MeshCentral = root on every managed machine. Treat auth like it's crown jewels (because it is).
- **TLS cert matters.** Self-signed works for first boot; switch to Let's Encrypt or your CA before bringing agents online.
- **NAT-busting**: MC's agents work through almost any NAT (outbound 443 only), but the MC server needs inbound 443 reachable. Behind CGNAT = Tailscale or similar front-end.
- **Agent auto-update**: enabled by default. Pause during known-bad releases. Watch issue tracker; MC moves fast; occasional regressions.
- **Resource on server**: a few hundred agents is fine on 1 vCPU / 2 GB RAM. At >1000 agents, switch to MongoDB.
- **MongoDB lifecycle**: pin version; plan for MongoDB LTS upgrades separately from MC.
- **Remote desktop performance**: WebRTC when possible (direct); server-relay when not (slower, server bandwidth). Test from outside network.
- **Audit logs**: extensive server-side logging. Critical for compliance (HIPAA / SOC 2 / GDPR).
- **Session recording**: commercial-grade feature in MC; enable for compliance.
- **Scripts + command execution**: MC lets any user with permission run arbitrary commands as root/SYSTEM. Scope permissions tightly.
- **Legal / compliance**: remote access to employee/client machines implies consent + notice. Be aware of local laws (US ECPA, EU GDPR, etc.). Configure "notify user when watched" if required.
- **macOS agent**: works but macOS's PPPC (Privacy Preferences Policy Control) prompts on first access — deploy with MDM for silent install.
- **Intel vPro/AMT**: MC supports hardware-level out-of-band management for Intel vPro machines — power cycle even when OS is dead.
- **Android agent**: good for basic management (screen share, file, location); not full RMM
- **Alternatives worth knowing:**
  - **RustDesk** — self-hostable remote desktop (no full RMM, but lighter) (separate recipe likely)
  - **TeamViewer** — commercial SaaS; de-facto standard; paid per seat
  - **AnyDesk** — commercial SaaS; popular
  - **ConnectWise Control (ScreenConnect)** — commercial on-prem/SaaS; MSP-focused
  - **Tactical RMM** — open-source MSP RMM with more features (Django + Go agent); heavier setup (separate recipe likely)
  - **Zabbix + custom scripts** — monitoring-first; remote control limited
  - **Apache Guacamole** — web-based RDP/SSH/VNC gateway; no agent model (separate recipe likely)
  - **NoVNC + TigerVNC** — DIY route
  - **Splashtop / Zoho Assist / BeyondTrust** — commercial competitors
  - **Choose MeshCentral if:** you want a full RMM platform, self-hosted, free, with real remote desktop + shell + files + scripts + WoL + audit.
  - **Choose Tactical RMM if:** you want MSP features (billing, ticketing integrations, more enterprise polish).
  - **Choose RustDesk if:** you just need remote desktop without full RMM.
  - **Choose TeamViewer/AnyDesk if:** zero-ops SaaS + don't mind commercial licensing.

## Links

- Repo: <https://github.com/Ylianst/MeshCentral>
- Website: <https://meshcentral.com>
- Docs (searchable): <https://ylianst.github.io/MeshCentral/>
- Install Guide (PDF): <https://meshcentral.com/docs/MeshCentral2InstallGuide.pdf>
- User Guide (PDF): <https://meshcentral.com/docs/MeshCentral2UserGuide.pdf>
- Design & Architecture (PDF): <https://meshcentral.com/docs/MeshCentral2DesignArchitecture.pdf>
- Releases: <https://github.com/Ylianst/MeshCentral/releases>
- YouTube: <https://www.youtube.com/@MeshCentral>
- Discord (unofficial): <https://discord.gg/8wHC6ASWAc>
- Telegram (unofficial): <https://t.me/meshcentral>
- Reddit: <https://www.reddit.com/r/MeshCentral/>
- MeshAgent repo: <https://github.com/Ylianst/MeshAgent>
- MeshCentralRouter repo: <https://github.com/Ylianst/MeshCentralRouter>
- RustDesk (alt): <https://rustdesk.com>
- Tactical RMM (alt): <https://tacticalrmm.com>
- Apache Guacamole (alt): <https://guacamole.apache.org>
