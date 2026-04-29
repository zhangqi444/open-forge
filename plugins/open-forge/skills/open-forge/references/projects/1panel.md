---
name: 1panel-project
description: 1Panel recipe for open-forge. GPL-3.0 web-based Linux VPS control panel (think cPanel/Plesk alternative) with one-click app marketplace (165+ apps), Docker/container management, website + domain + SSL automation, and fail2ban/WAF/firewall integration. Installs directly on the host via a curl|bash script — it's a **host-level control plane**, not a containerized app. Upstream also prominently advertises native OpenClaw AI agent support. Covers the one-liner install, port / security-path bootstrap, and the CRITICAL understanding that 1Panel manages the host, so you pick one "meta" control plane per server.
---

# 1Panel

GPL-3.0 open-source web-based VPS control panel. Upstream: <https://github.com/1Panel-dev/1Panel>. Site: <https://1panel.pro>. Docs: <https://1panel.pro/docs>.

**Host-level control plane, not a containerized app.** 1Panel installs binaries + systemd units directly on the Linux host. It manages:

- Docker containers and Docker Compose stacks
- Websites (Nginx config + automatic Let's Encrypt SSL)
- Databases (MySQL/MariaDB/PostgreSQL/Redis — installed via its own app store)
- Domain/DNS/firewall/fail2ban
- Backups (S3 / Cloudflare R2 / local)
- One-click installs of 165+ self-host apps from its marketplace

1Panel is notable for native AI agent support — upstream docs highlight **OpenClaw** integration + Ollama LLM hosting as first-class features. (Yes, that's us — 1Panel bundles OpenClaw agent runtime in its marketplace.)

## Compatible install methods

1Panel is a host-level installer; it doesn't run in Docker. You SSH into the box and run the installer.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Curl \| bash (one-liner) | <https://resource.1panel.pro/v2/quick_start.sh> | ✅ Recommended | The canonical install. Works on Debian / Ubuntu / CentOS / Rocky / AlmaLinux. |
| Offline tarball | Release assets at <https://github.com/1Panel-dev/1Panel/releases> | ✅ | Air-gapped hosts. |
| 1Panel OSS cloud image | DigitalOcean / Aliyun / etc. marketplaces | ✅ | Pre-installed VPS. |
| Docker install (NOT SUPPORTED) | — | ❌ | Don't try. 1Panel controls Docker; running 1Panel inside Docker is fighting its design. |

## When NOT to use 1Panel

Pick one "meta" control plane per server. 1Panel coexists poorly with:

- **CasaOS** (similar scope — UI for containers, apps, storage)
- **cPanel / Plesk / DirectAdmin** (classical web hosting panels)
- **aaPanel** (Chinese-origin, similar feature set — 1Panel's primary competitor)
- **YunoHost** (self-hosting OS-like distro)
- **Webmin** (older-school host admin)
- **Coolify** / **Dokploy** / **CapRover** (PaaS-style deployers)

Running two of these fights over `/etc/nginx/`, `80`/`443`, Docker state, and certificate renewal cron.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Supported OS?" | `AskUserQuestion`: `Debian` / `Ubuntu` / `CentOS` / `Rocky` / `AlmaLinux` | Installer supports these; other distros (Arch, Alpine) are NOT supported. |
| preflight | "No other control panel installed?" | Boolean | 1Panel will refuse or break on conflict with cPanel/Plesk/aaPanel. |
| preflight | "Root/sudo access?" | Boolean | Required — 1Panel installs systemd units, modifies firewall, edits `/etc/` configs. |
| network | "Firewall inbound open for the 1Panel port?" | Boolean | Default port is randomized; you'll need to open it in cloud security groups + host firewall. |
| network | "Public IP or LAN / Tailscale?" | `AskUserQuestion` | Public-facing installs should use a reverse proxy + restrict admin-panel access by IP or Tailscale ACL. |

## Install — one-liner

```bash
# Per upstream README, as root
bash -c "$(curl -sSL https://resource.1panel.pro/v2/quick_start.sh)"
```

**Review the script before running.** Source is at <https://github.com/1Panel-dev/1Panel/tree/master/deploy>.

The installer:

1. Detects OS + package manager.
2. Installs Docker (if not present).
3. Downloads 1Panel binary into `/usr/local/bin/1panel` + `1pctl`.
4. Writes systemd unit `/etc/systemd/system/1panel.service`.
5. Prompts interactively for:
   - **Admin username** (default: random)
   - **Admin password** (default: random, displayed once)
   - **Port** (default: random high port, e.g. `:37219`)
   - **Security path** — a random URL prefix (e.g. `/abc123`) required to access the admin UI; acts as a path-based "hidden URL" secret.
6. Enables + starts the service.
7. Prints the access URL: `http://<server-ip>:<port>/<security-path>`.

### Retrieve access info later

```bash
sudo 1pctl user-info     # shows username, password (reset), port, security path
sudo 1pctl listen-ip     # which IP 1Panel listens on (defaults to 0.0.0.0)
sudo 1pctl reset         # reset admin password
```

### Common 1pctl commands

```bash
sudo 1pctl status         # service status
sudo 1pctl restart        # restart daemon
sudo 1pctl uninstall      # full removal (WIPES 1Panel data, NOT user data in its managed apps)
sudo 1pctl update         # upgrade to latest 1Panel OSS
sudo 1pctl upgrade        # alternative command for major upgrades
```

## First-login security

1. Open `http://<ip>:<port>/<security-path>/`.
2. Log in with printed credentials.
3. Immediately: **Settings → Panel → change port, change security path, change password.**
4. **Settings → Safe → enable 2FA (TOTP).**
5. **Settings → Safe → restrict admin-panel access by IP** (allow-list your office / home IP).

The random port + security path + password is decent defense-in-depth, but **do NOT expose 1Panel's admin UI to the raw internet long-term.** Either:

- Bind to `127.0.0.1` and reach via SSH tunnel / Tailscale, OR
- Bind publicly but allowlist admin IPs + enable 2FA.

## What 1Panel installs on the host

1Panel writes to:

| Path | Content |
|---|---|
| `/usr/local/bin/1panel`, `/usr/local/bin/1pctl` | Binaries |
| `/opt/1panel/` | Data directory — config, SQLite DB, logs, managed app volumes |
| `/opt/1panel/db/` | 1Panel's own SQLite (stores managed apps, websites, users) |
| `/opt/1panel/apps/` | Volumes for apps installed via the marketplace |
| `/opt/1panel/www/` | Website document roots |
| `/opt/1panel/secret/` | Generated secrets (admin user keys, etc.) |
| `/etc/systemd/system/1panel.service` | systemd unit |

**Back up `/opt/1panel/` entirely** for disaster recovery. 1Panel's built-in backup feature (Settings → Backup) can push to S3 / R2 / local — use it.

## Marketplace apps

Each app in 1Panel's marketplace is a pre-written `docker-compose.yml` + env template. Installing "Nextcloud" via the UI:

1. Provisions `/opt/1panel/apps/nextcloud/`
2. Writes a docker-compose.yml + .env
3. Creates an nginx vhost for the domain you specified
4. Requests a Let's Encrypt cert
5. Starts the stack via `docker compose up -d`

Manage lifecycle (start/stop/upgrade) from the UI OR directly via `docker compose` in the app's directory. If you prefer writing your own compose, 1Panel's **Containers → Compose** page lets you upload or edit raw YAML.

## OpenClaw + AI agents

1Panel's marketplace includes an **OpenClaw** app entry that provisions the OpenClaw agent runtime on the host. After install:

- Agents run as host processes (not in Docker)
- The 1Panel UI provides a dashboard for agent status + logs
- Pro tier: unlimited agents; OSS: one agent

Also bundled: **Ollama** for local LLM hosting. Point the OpenClaw agent at the Ollama endpoint (default `http://localhost:11434`) to run agents against local models.

## Upgrade procedure

```bash
sudo 1pctl update
```

Reads the current version, downloads the new binary, runs any DB migrations on the internal SQLite, restarts the service.

Major upgrades (v1 → v2) were historically a paid-upgrade event with some data migration requirements; read release notes at <https://github.com/1Panel-dev/1Panel/releases> before running `update` across a major boundary.

## Gotchas

- **Host-level control plane = chooses for you.** Once installed, 1Panel owns `/etc/nginx/` (rewrites configs on website create/delete). Manually editing nginx configs under 1Panel-managed sites is asking for them to get overwritten on the next save from the UI.
- **Conflicts with other control panels.** If cPanel / Plesk / aaPanel / CasaOS are already present, uninstall them before installing 1Panel. The installer does NOT warn about this reliably.
- **Random port + security path is defense-in-depth, not security.** Port scanners find high ports in minutes. A random `/abc123/` security path blocks trivial bots but is guessable if your URL leaks (e.g. via browser history on a shared machine). Still enable 2FA and IP allowlisting.
- **OSS vs Pro feature split.** Pro ($80/year+) adds unlimited agents, WAF, uptime monitoring, multi-node, custom branding. OSS is fully functional for single-server self-host; don't assume Pro features from reading the homepage.
- **GPL-3.0 license.** If you fork 1Panel and ship derivatives, you must release source. Fine for internal use / self-host; matters if you're building a product on top.
- **The `1pctl uninstall` command wipes 1Panel's config + /opt/1panel/.** Before running it, back up `/opt/1panel/apps/` because some app volumes live there and will be deleted. Export DB dumps from inside each app first.
- **Chinese-origin project.** Mostly documented in English now, but some error messages, release notes, and community threads are in Chinese. Use <https://translate.google.com> or the language switchers in the docs.
- **Docker-required, but 1Panel installs Docker for you if missing.** If you already have a tuned Docker setup (rootless, custom storage driver, custom daemon.json), 1Panel's installer may step on it. Review before installing on a pre-configured Docker host.
- **Not listed on selfh.st filter for "official Docker image"** — because there isn't one. This is a host-install project.
- **Uses `resource.1panel.pro` + Chinese CDN for marketplace asset downloads.** If you're air-gapped or behind the GFW, some marketplace items will fail to install. The offline tarball install works but marketplace still needs network.
- **The marketplace version of "OpenClaw" is a downstream package** — verify the version matches current upstream before relying on features. (Yes, the maintainers are the same team; check the bundled version in 1Panel's marketplace against <https://github.com/openclaw/openclaw/releases>.)

## Links

- Upstream repo: <https://github.com/1Panel-dev/1Panel>
- Website: <https://1panel.pro>
- Docs: <https://1panel.pro/docs>
- Releases: <https://github.com/1Panel-dev/1Panel/releases>
- Pricing / Pro: <https://1panel.pro/pricing>
- Discord: <https://discord.gg/bUpUqWqdRr>
- Installer source: <https://github.com/1Panel-dev/1Panel/tree/master/deploy>
