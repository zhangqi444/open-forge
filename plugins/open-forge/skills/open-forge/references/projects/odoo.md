---
name: odoo-project
description: Odoo recipe for open-forge. LGPL-3.0 suite of open-source business apps (ERP, CRM, website, eCommerce, inventory, accounting, PoS, HR, manufacturing). Python + PostgreSQL. Covers the upstream docker-library image (Postgres-backed compose), binary package installs (deb/rpm on upstream repos), source install from git, and nightly tarball. Odoo releases two editions: Community (LGPL-3, self-host this) and Enterprise (paid, closed-source addons mounted into the same container).
---

# Odoo

LGPL-3.0 Python + PostgreSQL business-apps suite (formerly OpenERP). Upstream: <https://github.com/odoo/odoo>. Docs: <https://www.odoo.com/documentation/master>. Install guide: <https://www.odoo.com/documentation/master/administration/install/install.html>.

Single Python web service (Werkzeug-based) backed by PostgreSQL. Default port `:8069` (web) + `:8072` (longpolling/websocket). Apps ("modules") load dynamically from addon paths.

**Editions:**

- **Community** — LGPL-3, what's in `odoo/odoo`. This recipe covers Community self-host.
- **Enterprise** — paid, closed-source; extra modules mounted into the same runtime. Enterprise users typically still self-host the core and just add `enterprise/` to the addons path.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`odoo`) | <https://hub.docker.com/_/odoo> · <https://github.com/odoo/docker> | ✅ | The most common self-host shape. Image is maintained by Odoo SA. |
| APT (Debian/Ubuntu) | <https://www.odoo.com/documentation/master/administration/install/packages.html> | ✅ | Systemd unit + distro-native. Repo at `nightly.odoo.com/<version>/nightly/deb/`. |
| RPM (RHEL/Fedora) | Same install docs | ✅ | Same but for RPM distros. |
| Source install (from git) | `git clone odoo/odoo` + virtualenv | ✅ | Custom module dev, contributors. |
| Nightly tarball | <https://nightly.odoo.com> | ✅ | Offline / air-gapped installs. |
| Odoo.sh (managed) | <https://www.odoo.com/odoosh> | ✅ | Paid managed hosting — out of scope. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method? (docker / apt / rpm / source)" | `AskUserQuestion` | Drives section. |
| version | "Odoo major version?" | `AskUserQuestion`: `19.0` / `18.0` / `17.0` / `16.0` | Image tag / APT repo path. **Pin a major**; `latest` drifts. |
| edition | "Community or Community + Enterprise addons?" | `AskUserQuestion` | Enterprise requires a paid license; only legal to run with an active subscription. |
| db | "PostgreSQL: bundled container or external server?" | `AskUserQuestion` | Docker compose can bundle; production often uses RDS/managed. |
| db | "Postgres admin password + odoo DB password?" | Free-text (sensitive) | Sets `POSTGRES_PASSWORD` + Odoo's DB connection string. |
| db | "Odoo master password (for DB-management UI at `/web/database/manager`)?" | Free-text (sensitive) | Set via `admin_passwd` in config. Without this set to a strong value, any internet visitor can create/drop/restore DBs. |
| domain | "Public domain?" | Free-text | Reverse-proxy + TLS. |
| proxy | "Reverse proxy? (nginx / Caddy / Traefik / skip)" | `AskUserQuestion` | Odoo itself does NOT terminate TLS. Longpolling/websocket traffic on `:8072` must be routed separately. |
| addons | "Path(s) to custom addons?" | Free-text | Mounted at `/mnt/extra-addons` in the Docker image, or added to `addons_path=` in `odoo.conf`. |
| workers | "Worker count?" | Integer, default `(2 * CPU) + 1` | Odoo is a multi-process (prefork) server in production. Set via `workers=` in `odoo.conf`. |

## Install — Docker Compose (upstream-recommended)

```yaml
# compose.yaml — based on the docker-library/odoo README
services:
  web:
    image: odoo:18.0           # pin major version
    depends_on:
      - db
    ports:
      - "8069:8069"            # main HTTP
      - "8072:8072"            # longpolling (websocket)
    environment:
      HOST: db
      USER: odoo
      PASSWORD: ${DB_PASSWORD}
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo     # mount your odoo.conf here
      - ./addons:/mnt/extra-addons
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - odoo-db-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  odoo-web-data:
  odoo-db-data:
```

**Minimal `config/odoo.conf`:**

```ini
[options]
admin_passwd = <strong-random-string>
db_host = db
db_port = 5432
db_user = odoo
db_password = ${DB_PASSWORD}
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo
proxy_mode = True
workers = 4
longpolling_port = 8072
```

```bash
echo "DB_PASSWORD=$(openssl rand -hex 32)" > .env
docker compose up -d
# Visit http://localhost:8069 — Odoo's first-run UI creates the initial DB
# Use the 'admin_passwd' above when prompted
```

### Why `proxy_mode = True`

When Odoo is behind nginx/Caddy/Traefik, it needs to trust `X-Forwarded-*` headers to generate correct redirect URLs. Without it, HTTPS requests receive HTTP redirects (redirect loops).

## Install — APT (Debian/Ubuntu)

From <https://www.odoo.com/documentation/master/administration/install/packages.html>:

```bash
# 1. Install PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql postgresql-client

# 2. Add Odoo's APT repo
wget -q -O - https://nightly.odoo.com/odoo.key | sudo gpg --dearmor -o /etc/apt/keyrings/odoo-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/18.0/nightly/deb/ ./" | sudo tee /etc/apt/sources.list.d/odoo.list

# 3. Install
sudo apt-get update
sudo apt-get install -y odoo

# 4. Start + verify
sudo systemctl status odoo
curl -sI http://localhost:8069/web/database/selector
# → 200 OK
```

Config at `/etc/odoo/odoo.conf`; logs at `/var/log/odoo/odoo.log`; unit name is `odoo`.

## Install — Source (from git)

For developing custom modules / contributing to Odoo core:

```bash
# 1. PostgreSQL
sudo apt-get install -y postgresql
sudo -u postgres createuser -s odoo

# 2. Python deps (Python 3.10+ for Odoo 18)
sudo apt-get install -y python3-pip python3-venv python3-dev \
    build-essential libldap2-dev libsasl2-dev libssl-dev \
    node-less npm

# 3. Clone (choose a branch: 18.0 / 17.0 / master)
git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git
cd odoo

# 4. Virtualenv + deps
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. First run
./odoo-bin -c odoo.conf --dev=all
```

Develop with `--dev=all` for auto-reload + debug; production drops that flag + uses `workers=N`.

## Reverse proxy (nginx example)

Canonical nginx config for Odoo (from upstream docs):

```nginx
upstream odoo {
    server 127.0.0.1:8069;
}
upstream odoochat {
    server 127.0.0.1:8072;
}

server {
    listen 443 ssl;
    server_name odoo.example.com;
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    # TLS certs
    ssl_certificate /etc/letsencrypt/live/odoo.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/odoo.example.com/privkey.pem;

    # Proxy headers
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;

    # Longpolling / websocket
    location /longpolling {
        proxy_pass http://odoochat;
    }
    location /websocket {
        proxy_pass http://odoochat;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

    # Main app
    location / {
        proxy_redirect off;
        proxy_pass http://odoo;
    }

    # Static files cache
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }
}

server {
    listen 80;
    server_name odoo.example.com;
    return 301 https://$host$request_uri;
}
```

## Upgrade procedure

### Major version (18.0 → 19.0)

**Not a one-command upgrade.** Odoo version migrations require schema migrations per-module, and custom modules often need porting. Options:

1. **Self-serve OpenUpgrade** (community project at <https://github.com/OCA/OpenUpgrade>) — scripts for migrating DBs across majors, but requires testing.
2. **Odoo's paid upgrade service** — they migrate your DB for a fee.
3. **Fresh install + manual data migration** — export CSVs from old, import to new.

### Minor upgrade (18.0.x → 18.0.y)

```bash
# Docker
docker compose pull
docker compose up -d
# Restart triggers any pending minor-version migrations automatically
docker compose logs -f web
```

```bash
# APT
sudo apt-get update && sudo apt-get upgrade odoo
sudo systemctl restart odoo
```

Always back up Postgres + filestore (`/var/lib/odoo/`) before every upgrade.

## Data layout

| Path (APT) | Path (Docker) | Content |
|---|---|---|
| `/var/lib/odoo/` | `/var/lib/odoo/` (volume) | Filestore: module assets, user-uploaded files, session data. |
| `/etc/odoo/odoo.conf` | `/etc/odoo/odoo.conf` (mounted) | Main config. |
| `/var/log/odoo/` | container stdout | Logs. |
| Postgres | Postgres | One DB per Odoo "database" (Odoo supports multi-DB on one instance). |

**Backup = `pg_dump` + `tar -czf filestore.tar.gz /var/lib/odoo/`** while Odoo is stopped (or use the built-in Backup button in the DB manager UI, which does both).

## Gotchas

- **`admin_passwd` is not optional.** Without it set to a strong value, `/web/database/manager` (exposed by default) lets anyone create/drop/restore databases. For production, set it AND restrict `/web/database/manager` at the reverse proxy to internal IPs.
- **Multi-database mode is the default.** A single Odoo instance can host multiple tenant DBs selected by URL hostname. If you want a single DB, set `dbfilter = ^%d$` in `odoo.conf` to hide the DB selector.
- **`proxy_mode = True` is required behind any reverse proxy.** Without it, Odoo generates HTTP URLs in emails / redirects, breaking HTTPS.
- **Longpolling needs its own route.** Skipping the `/longpolling` and `/websocket` nginx blocks breaks realtime chat/notifications.
- **Enterprise modules are NOT in the git repo.** You need a paid subscription + the separate `enterprise/` clone. Running Enterprise modules without a subscription violates the Enterprise license.
- **Postgres version matters.** Odoo 17.0+ requires Postgres 12+. Odoo 18.0 upstream ships with `postgres:15` in compose; don't pair with older.
- **Workers vs gevent port.** `workers = N` enables multi-process mode. You MUST then also configure `longpolling_port = 8072` — gevent runs in that single process, not in the HTTP workers.
- **Memory per worker.** Odoo workers default to `limit_memory_hard = 2 GiB`. An 8-worker deploy can eat 16 GiB RSS. Size hosts accordingly; reduce via `limit_memory_hard` / `limit_memory_soft` if needed.
- **DB migration on module upgrade is NOT reversible.** `odoo -u <module>` applies schema migrations; rollback = restore from backup. Test on a copy first.
- **Enterprise/CE addons-path ordering matters.** Enterprise modules must appear FIRST in `addons_path` so they override CE modules with matching names.
- **Cron jobs run in workers.** If `workers = 0` (dev mode), scheduled actions don't fire. Production must have `workers >= 2`.

## Links

- Upstream repo: <https://github.com/odoo/odoo>
- Docs: <https://www.odoo.com/documentation/master>
- Install guide: <https://www.odoo.com/documentation/master/administration/install/install.html>
- Deployment: <https://www.odoo.com/documentation/master/administration/on_premise/deploy.html>
- Docker image: <https://hub.docker.com/_/odoo>
- Docker repo: <https://github.com/odoo/docker>
- Nightly builds: <https://nightly.odoo.com/>
- OpenUpgrade (community migration): <https://github.com/OCA/OpenUpgrade>
- Release notes: <https://www.odoo.com/odoo-release-notes>
