---
name: nginx-proxy-manager-project
description: Nginx Proxy Manager (NPM) recipe for open-forge. MIT-licensed web UI for managing Nginx as a reverse proxy — create proxy hosts, SSL via Let's Encrypt (DNS-01 or HTTP-01 challenges), redirections, 404 hosts, streams (TCP/UDP pass-through), access lists with HTTP basic auth, users + audit log. Single Docker container with SQLite (default) or MariaDB backend. The go-to "I want a reverse proxy with a GUI" option for self-hosters who don't want to hand-edit nginx configs. Covers Docker Compose (default), MariaDB variant, router port-forwarding prerequisites, and the armv7-dropped-in-v2.14+ gotcha.
---

# Nginx Proxy Manager

MIT-licensed GUI for managing Nginx as a reverse proxy. Upstream: <https://github.com/NginxProxyManager/nginx-proxy-manager>. Docs: <https://nginxproxymanager.com>. Docker image: `docker.io/jc21/nginx-proxy-manager`.

Commonly called "NPM" (confusing with Node's npm — the package manager). Beautiful web UI (based on Tabler) for:

- **Proxy Hosts** — point `subdomain.example.com` → `10.0.0.50:3000` (plus many options)
- **Redirection Hosts** — `old.example.com` → `new.example.com`
- **Streams** — raw TCP/UDP pass-through (useful for SSH / game servers / non-HTTP protocols)
- **404 Hosts** — catch-all domains
- **SSL certificates** — free via Let's Encrypt (HTTP-01 or DNS-01) or upload your own
- **Access Lists** — HTTP Basic auth + IP allow/deny lists applied to any host
- **User management** — multiple admin users with permissions
- **Audit log** — who changed what, when

## Who this is for

- Home labbers / self-hosters with a growing zoo of services on one VPS or LAN
- "I know what Nginx is but I don't want to write configs by hand for every app"
- Quick TLS for internal services via DNS-01 (no need to expose ports 80/443 publicly)

**NOT** for: multi-node / HA setups, large-scale production (Traefik / Caddy / HAProxy / dedicated nginx with IaC are better), or anyone who wants full control over nginx configs (NPM adds layers of generated config you have to learn to override).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (default SQLite) | <https://nginxproxymanager.com/setup/> | ✅ Recommended | Most self-hosters. 2-file install. |
| Docker Compose (MariaDB) | <https://nginxproxymanager.com/advanced-config/> | ✅ | If you expect many hosts (100+) or want to run multiple NPM instances sharing state. |
| Build from source | <https://github.com/NginxProxyManager/nginx-proxy-manager/blob/develop/backend/README.md> | ✅ | Contributors only. |
| Kubernetes Helm | ❌ No official chart | Community-only | Not first-party. Use Traefik / cert-manager for K8s native. |
| Home Assistant add-on | <https://github.com/hassio-addons/addon-nginx-proxy-manager> | ⚠️ Community | HA users. Well-maintained community project. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Architecture?" | Detect `uname -m`: `x86_64` / `aarch64` / `armv7l` | **armv7 is NOT supported in v2.14+** — use `jc21/nginx-proxy-manager:2.13.7` if armv7. |
| preflight | "Are ports 80, 81, and 443 free on the host?" | Boolean, required | 80 + 443 are the public reverse-proxy ports; 81 is the admin UI. All three MUST be free. |
| db | "Database backend?" | `AskUserQuestion`: `sqlite (default)` / `mariadb` | SQLite is simpler; MariaDB for scale or HA. |
| data | "Where to store data + certs?" | Free-text, default `./data` and `./letsencrypt` | Two bind mounts. Persistent across restarts/upgrades. |
| router | "If hosting at home, have you port-forwarded 80 + 443 from your router to this host?" | Boolean | Required for public HTTPS via Let's Encrypt HTTP-01 challenge. Not required for DNS-01 or LAN-only use. |
| dns | "Point your domains' A/AAAA records at this host's public IP?" | Boolean | Required before NPM can issue Let's Encrypt certs via HTTP-01. |

## Install — Docker Compose (default SQLite)

```yaml
# compose.yaml
services:
  app:
    image: docker.io/jc21/nginx-proxy-manager:latest   # pin a version in prod (see tags below)
    restart: unless-stopped
    ports:
      - '80:80'        # Public HTTP (and HTTP-01 challenge)
      - '81:81'        # Admin Web UI
      - '443:443'      # Public HTTPS
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

```bash
docker compose up -d
```

1. Open `http://<host>:81/` → admin UI.
2. Default login:
   - **Email:** `admin@example.com`
   - **Password:** `changeme`
3. You'll be forced to change these on first login. **Do this immediately.**
4. Start adding hosts.

### armv7 (old Raspberry Pi 2/3/Zero W) alternative

```yaml
services:
  app:
    image: docker.io/jc21/nginx-proxy-manager:2.13.7    # last version with armv7 support
    # ... rest same
```

Upstream explicitly flags:

> `armv7` is no longer supported in version 2.14+. This is due to Nodejs dropping support for armhf. Please use the `2.13.7` image tag if this applies to you.

## Install — Docker Compose with MariaDB

For larger deployments or if you want external DB (easier backups, replication):

```yaml
services:
  app:
    image: docker.io/jc21/nginx-proxy-manager:latest
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm-secret-password"
      DB_MYSQL_NAME: "npm"
      # NOTE: Leave the DB_SQLITE_FILE env var blank → disables SQLite
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - db

  db:
    image: jc21/mariadb-aria:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: 'strong-root-password'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm-secret-password'
    volumes:
      - ./mysql:/var/lib/mysql
```

## First-login checklist

1. Log in at `:81/`.
2. **Change email + password** (forced).
3. Go to **Users → Add User** to create additional admins if needed.
4. **SSL Certificates → Add SSL Certificate → Let's Encrypt** to pre-provision a wildcard or per-domain cert (or let individual Proxy Hosts request their own).
5. **Proxy Hosts → Add Proxy Host:**
   - Domain: `app.example.com`
   - Forward Hostname/IP: `10.0.0.50` (or a container name if using Docker network)
   - Forward Port: `3000`
   - Block Common Exploits: ✅
   - Websocket Support: ✅ (if the backend uses WebSockets)
   - SSL tab → choose cert, enable Force SSL, HSTS, HTTP/2 Support.

## Access Lists (HTTP Basic auth in front of any host)

**Admin → Access Lists → Add:**

- **Authorization** — username/password pairs (HTTP Basic)
- **Access** — IP allow / deny lists (CIDR supported)

Attach to any Proxy Host's "Access List" dropdown → immediate auth wrap. Useful for putting a login in front of un-authenticated apps (old file browsers, Prometheus UIs, etc.).

## DNS-01 challenge (for certs on hosts not reachable from internet)

For internal services that never expose port 80 to the internet, use DNS-01:

**SSL Certificates → Add SSL Certificate → Let's Encrypt:**

- Domain Names: `*.internal.example.com`
- Email Address: your email
- Use a DNS Challenge: ✅
- DNS Provider: Cloudflare / Route53 / DigitalOcean / ... (dozens supported)
- Credentials File Content: paste the API creds per the dropdown's format.

Wildcard certs work with DNS-01.

## Reverse proxying services on the same Docker host

If NPM and target apps are in the same Docker Compose project, share a network:

```yaml
# compose.yaml
networks:
  proxy:
    external: true

services:
  app:
    image: jc21/nginx-proxy-manager:latest
    networks: [proxy]
    ports: [...]
    volumes: [...]

  # Elsewhere / another compose file:
  my-app:
    image: ghost:5
    networks: [proxy]
    # no ports: needed — NPM reaches it via the proxy network
```

In NPM → Proxy Host → Forward Hostname/IP: `my-app` (container name), Port: `2368`. NPM resolves container DNS inside the shared network.

## Data layout

| Path | Content |
|---|---|
| `./data/` | SQLite DB, generated nginx configs, NPM state |
| `./letsencrypt/` | Let's Encrypt certs + account keys |
| `./mysql/` (MariaDB variant) | MariaDB data files |

**Backup** = tar both `data/` and `letsencrypt/` while the container is stopped (or at minimum, while no changes are in flight). MariaDB users: `mysqldump` the `npm` DB + back up `letsencrypt/`.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose logs app
```

Migrations run automatically on startup. Upstream is generally backwards-compatible within the 2.x line. Read release notes before major-version jumps (3.x when it lands).

## Gotchas

- **Default admin password `changeme` is a footgun.** If NPM is reachable before you log in and change it, anyone can claim your instance. Firewall port 81 or log in IMMEDIATELY.
- **`armv7` dropped in 2.14+.** Pi Zero W / older Pi 3 users: pin `:2.13.7` OR upgrade hardware.
- **Port 80 MUST be free** on the host (not just container). If you have Apache / other nginx / Traefik already binding 80, NPM can't claim it. Ditto 443.
- **Let's Encrypt HTTP-01 requires public internet access to port 80.** Certs will fail to issue or renew if port 80 is firewalled. DNS-01 avoids this.
- **Cert renewal happens automatically**, but if renewal fails silently (DNS provider credentials expired, domain NS changed), you only notice when cert expires. Check the SSL Certificates page periodically.
- **NPM generates nginx configs; don't hand-edit them in the container.** They get overwritten on save. For custom nginx directives, use the Proxy Host → Advanced tab (that config IS preserved) OR edit the per-host include files in `data/nginx/custom/` (documented in upstream wiki, supported).
- **Websocket hosts need the "Websocket Support" checkbox.** Forgetting this means Socket.IO / websockets don't connect, with cryptic browser errors.
- **HTTP/2 requires HTTPS.** Can't enable HTTP/2 on a host without a cert attached.
- **Wildcard cert + multiple hosts — NPM re-uses the wildcard cert automatically** if the domain matches. Don't create per-host certs that overlap with a wildcard; it just wastes LE rate limits.
- **Let's Encrypt staging vs production.** For testing, NPM has a "Use Staging Environment" checkbox on cert creation → issues from LE staging (non-trusted but no rate limit). Switch off for real certs.
- **SQLite can corrupt on power loss / ungraceful shutdowns.** For critical deployments, use MariaDB variant OR ensure the host has a UPS / journaled FS.
- **Multi-instance deployments need MariaDB.** SQLite = single-instance only. Running two NPM containers pointing at the same SQLite file corrupts it.
- **Backup `letsencrypt/` separately from `data/`.** Certs + keys live there. If you restore `data/` without `letsencrypt/`, all hosts will try to re-issue certs on next renewal, potentially hitting LE rate limits (50 certs/week/domain).
- **"Forward Scheme" dropdown: HTTP vs HTTPS.** This is about how NPM talks to the UPSTREAM, not the client. If your app listens on HTTPS internally (e.g. self-signed), set Forward Scheme to `https` + check "Block Common Exploits" behavior.
- **Audit log grows unbounded.** Every create/update/delete is logged forever. For very active instances, periodic DB pruning may be needed.
- **No HA / active-active clustering.** NPM is single-instance. Options: cold standby (rsync of `data/` + `letsencrypt/`), OR accept downtime on NPM upgrades.
- **Admin UI is on port 81, not 80/443.** If NPM itself is publicly accessible (not great practice), set up a Proxy Host pointing `npm.example.com` → `127.0.0.1:81` and firewall port 81 externally.
- **"Block Common Exploits" is a basic WAF-lite.** Blocks a few known bad user-agents + paths. NOT a replacement for a real WAF (Cloudflare / ModSecurity).

## Links

- Upstream repo: <https://github.com/NginxProxyManager/nginx-proxy-manager>
- Docs: <https://nginxproxymanager.com>
- Setup guide: <https://nginxproxymanager.com/setup/>
- Advanced config: <https://nginxproxymanager.com/advanced-config/>
- Docker Hub: <https://hub.docker.com/r/jc21/nginx-proxy-manager>
- Releases: <https://github.com/NginxProxyManager/nginx-proxy-manager/releases>
- Subreddit: <https://reddit.com/r/nginxproxymanager>
- Discussions: <https://github.com/NginxProxyManager/nginx-proxy-manager/discussions>
- Develop preview docs: <https://develop.nginxproxymanager.com>
