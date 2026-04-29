---
name: puter-project
description: Puter recipe for open-forge. AGPL-3.0 "Internet OS" — a browser-based desktop environment + personal cloud + file/app platform. Self-host an alpha-grade stack via npm local dev, `docker run`, or docker-compose. Upstream explicitly marks self-host as ALPHA, not for production — several puter.com features (App Center, Code, Draw) are not yet available on self-host. This recipe covers the three install paths, domain/subdomain routing (api.example.com required), default-user bootstrap, and the reverse-proxy config needed for anything beyond localhost.
---

# Puter

AGPL-3.0 open-source "Internet OS" — a full browser-based desktop environment, filesystem, app runtime, and developer platform. Upstream: <https://github.com/HeyPuter/puter>. Docs: <https://github.com/HeyPuter/puter/tree/main/doc>. Live demo: <https://puter.com>.

**⚠️ Alpha-quality self-host.** Upstream's self-host guide opens with: *"The self-hosted version of Puter is currently in alpha stage and should not be used in production yet."* Specifically:

- No built-in way to install apps from puter.com's App Store (use Dev Center app to sideload)
- Several core apps (**Code**, **Draw**) are missing on self-host
- Some assets differ from the hosted version

Puter is still a legitimate self-host candidate — the underlying "personal cloud OS" fabric works — but expect sharp edges. Don't migrate a production workload onto it.

## What you get

- A desktop-like UI served at `http://puter.localhost:4100/` on first boot
- A filesystem + files API
- A user/auth system (default user auto-created with a random password, printed to logs)
- A simple app runtime (Dev Center to load your own apps)
- Node.js 24+ backend, single container / single process

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Local npm (`npm install && npm start`) | README §Local Development | ✅ | Development / kicking the tyres. Volatile config in `volatile/`. |
| Docker (`docker run`) | README §Docker | ✅ | Quick single-container test. |
| Docker Compose | `docker-compose.yml` on `main` | ✅ Recommended | Persistent self-host with named bind mounts. |
| Build from source | Clone + `npm install` | ✅ | Custom modifications / core dev. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `npm` / `docker` / `compose` | Drives the section. |
| platform | "Node 24+ installed?" | Boolean | npm install only. |
| dns | "LAN / LAN+nip.io / public domain?" | `AskUserQuestion` | Drives the config section. Public-domain needs an `api.<domain>` subdomain too. |
| dns | "Public domain?" | Free-text | E.g. `puter.example.com` — and separately `api.puter.example.com` must also resolve to the same host. |
| tls | "Reverse proxy (Caddy / nginx / Traefik) or skip (LAN only)?" | `AskUserQuestion` | Puter does not terminate TLS itself. |
| ports | "Host port for Puter?" | Free-text, default `4100` | Host-side port mapped to container's `4100`. |
| storage | "Host path for data volume?" | Free-text, default `./puter/data` | Mounted at `/var/puter` inside the container. |
| storage | "Host path for config volume?" | Free-text, default `./puter/config` | Mounted at `/etc/puter` inside the container. Contains generated `config.json`. |

## Install — Local npm (dev)

```bash
git clone https://github.com/HeyPuter/puter
cd puter
npm install
npm start
```

- Listens on `http://puter.localhost:4100/` (next free port if 4100 is taken).
- Generates a default user on first boot; the generated password is printed in the dev console — **log in and change it immediately**.
- Config path: `volatile/config/config.json` (regenerated if you `rm volatile/`).
- First-run issues: <https://github.com/HeyPuter/puter/blob/main/doc/self-hosters/first-run-issues.md>

## Install — Docker (one-liner)

```bash
mkdir -p puter/config puter/data
sudo chown -R 1000:1000 puter
docker run --rm \
  -p 4100:4100 \
  -v "$(pwd)"/puter/config:/etc/puter \
  -v "$(pwd)"/puter/data:/var/puter \
  ghcr.io/heyputer/puter
```

Use this for a throwaway test. For anything persistent, prefer Compose.

## Install — Docker Compose (recommended)

```bash
mkdir -p puter/config puter/data
sudo chown -R 1000:1000 puter
wget https://raw.githubusercontent.com/HeyPuter/puter/main/docker-compose.yml
docker compose up -d
docker compose logs -f puter
```

Upstream's `docker-compose.yml`:

```yaml
services:
  puter:
    container_name: puter
    image: ghcr.io/heyputer/puter:latest
    pull_policy: always
    restart: unless-stopped
    ports:
      - '4100:4100'
    environment:
      PUID: 1000
      PGID: 1000
      # TZ: Europe/Paris
      # CONFIG_PATH: /etc/puter
    volumes:
      - ./puter/config:/etc/puter
      - ./puter/data:/var/puter
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://puter.localhost:4100/test || exit 1
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 30s
```

### Windows

```powershell
mkdir -p puter
cd puter
New-Item -Path "puter\config" -ItemType Directory -Force
New-Item -Path "puter\data" -ItemType Directory -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/HeyPuter/puter/main/docker-compose.yml" -OutFile "docker-compose.yml"
docker compose up
```

## First-run config — default user

On first boot:

1. Puter generates a user `default_user` with a random password.
2. The password is printed in the dev/container console logs.
3. A warning banner persists in the dev console until that password is changed.

**First thing to do:** open the UI, log in as `default_user`, **Settings → Change password**. Do this before exposing the instance.

```bash
# Grep logs for the initial password
docker compose logs puter | grep -iE 'password|default_user'
```

## Access beyond localhost

Puter defaults to `puter.localhost:4100`, which only resolves on the host itself. Three options:

### Option A — LAN access via nip.io

Edit `config/config.json` (generated on first boot):

```json
{
  "allow_nipio_domains": true
}
```

Then hit `http://puter.<host-ip>.nip.io:4100/` from any device on the LAN (e.g. `http://puter.192.168.1.50.nip.io:4100/`).

### Option B — Custom domain

Edit `config/config.json`:

```json
{
  "domain": "puter.example.com",
  "http_port": 4100,
  "pub_port": 443,
  "protocol": "https",
  "allow_nipio_domains": false
}
```

**Both `puter.example.com` AND `api.puter.example.com` must resolve to the same host.** Puter routes the API on a separate subdomain. Missing the `api.` subdomain is the #1 self-host footgun.

See <https://github.com/HeyPuter/puter/blob/main/doc/self-hosters/domains.md> for the full domain guide.

After editing config, restart the container:

```bash
docker compose restart puter
```

### Option C — Reverse proxy (Caddy)

```caddy
puter.example.com, api.puter.example.com {
    reverse_proxy puter:4100
}
```

Caddy will obtain Let's Encrypt certs for both hostnames.

## Data layout

| Path (host) | Path (container) | Content |
|---|---|---|
| `./puter/config/` | `/etc/puter/` | `config.json` + generated secrets. Back this up (without it, users lose access to their files). |
| `./puter/data/` | `/var/puter/` | All user data: filesystem, SQLite DB(s), uploaded blobs. |

**Backup = tar both directories while the container is stopped.** Puter uses SQLite internally; a running tar can produce a corrupt snapshot.

```bash
docker compose stop
sudo tar -czf puter-backup-$(date +%F).tar.gz puter/config puter/data
docker compose start
```

## Upgrade procedure

```bash
# 1. ALWAYS back up first (see above). Alpha-stage project; schema migrations may break.
docker compose stop
sudo tar -czf puter-backup-pre-upgrade-$(date +%F).tar.gz puter/config puter/data

# 2. Pull new image + restart
docker compose pull
docker compose up -d

# 3. Watch logs for migration errors
docker compose logs -f puter
```

Read <https://github.com/HeyPuter/puter/releases> before every upgrade — alpha projects can require manual migration steps.

## Gotchas

- **Alpha quality — upstream says so.** Expect bugs, missing features, and breaking changes. Don't depend on Puter as your only backup of anything.
- **The `api.` subdomain is NOT optional for public deploys.** Puter routes API traffic on a separate host; without it, the UI loads but every API call 404s. Both `<domain>` and `api.<domain>` need DNS records.
- **`default_user` has a random password printed to logs — change it first.** Until you do, anyone who can read the container logs can log in.
- **`allow_nipio_domains: true` exposes your LAN IP in URLs.** Fine for home use, awkward for "dev environment visible to non-technical stakeholders" scenarios — use a real domain + reverse proxy for those.
- **PUID/PGID must match host uid/gid.** The container runs as 1000:1000 by default; if your host user is 1001, everything in `puter/data/` will be owned by a mismatched uid and the container can't write. Set `PUID`/`PGID` env vars to your host user's `id -u` / `id -g`.
- **Port 4100 — not standard.** `reverse_proxy puter:4100` inside the Docker network is fine; exposing `4100` directly to the public internet is unusual and requires Node's dev-mode headers to be correct, which they aren't in all cases. Always front with a reverse proxy for public access.
- **No built-in TLS.** Same as most Node apps — terminate at Caddy/nginx/Traefik. Puter's own HTTPS support is minimal and not recommended.
- **App Center / Code / Draw are missing.** Self-host-only apps are sideloaded via **Dev Center**. If a user asks "where's X app?", point them at Dev Center.
- **Node 24+ for npm install.** Earlier Node versions produce cryptic build errors. Verify with `node --version` before `npm install`.
- **Alpha = no LTS. No SLA. No promise of graceful upgrades.** Self-host Puter to tinker, not for business-critical use.

## Links

- Upstream repo: <https://github.com/HeyPuter/puter>
- Self-hosting guide: <https://github.com/HeyPuter/puter/blob/main/doc/self-hosters/instructions.md>
- Config reference: <https://github.com/HeyPuter/puter/blob/main/doc/self-hosters/config.md>
- Domain setup: <https://github.com/HeyPuter/puter/blob/main/doc/self-hosters/domains.md>
- First-run issues: <https://github.com/HeyPuter/puter/blob/main/doc/self-hosters/first-run-issues.md>
- Releases: <https://github.com/HeyPuter/puter/releases>
- Docker image: <https://github.com/HeyPuter/puter/pkgs/container/puter>
- Discord: <https://discord.com/invite/PQcx7Teh8u>
