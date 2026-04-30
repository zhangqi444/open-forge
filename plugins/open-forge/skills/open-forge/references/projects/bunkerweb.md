---
name: BunkerWeb
description: "Next-gen open-source Web Application Firewall (WAF) — an nginx-derived reverse proxy with ModSecurity CRS, antibot, bad-behavior blocking, auto Let's Encrypt, IP reputation, bot scoring, multisite vhosts. Docker/K8s/Swarm/Linux-native integrations. AGPL-3.0 (OSS) with optional PRO tier."
---

# BunkerWeb

BunkerWeb is a **Web Application Firewall + reverse proxy** built on top of nginx, focused on making "security-by-default" easy. Unlike a stock nginx + manual ModSecurity config, BunkerWeb ships pre-tuned with OWASP ModSecurity Core Rule Set (CRS), antibot challenges, IP reputation feeds, and a UI. Think of it as a turnkey alternative to commercial WAFs (Cloudflare, Imperva, F5) — or as "nginx with batteries included."

Key features:

- **Multisite** — protect many apps from one instance with per-vhost settings
- **ModSecurity + OWASP CRS** — battle-tested WAF rules enabled by default
- **Antibot** — CAPTCHA / JS challenge / recaptcha / hcaptcha
- **Bad behavior** — auto-block IPs that trigger N WAF rules in M seconds
- **Auto Let's Encrypt** — one setting enables HTTPS
- **Bot scoring + IP reputation** — feeds of known bad IPs / bots
- **Reverse proxy** — HTTP/HTTPS/gRPC backends + load balancing
- **Rate limiting** — per-IP / per-URI / custom
- **Custom NGINX/ModSec config injection** — escape hatch for advanced tuning
- **Web UI** — view blocked attacks, tweak settings, manage plugins
- **Plugin system** — ClamAV, VirusTotal, Coraza (alt WAF), Discord/Slack/webhook alerts
- **Integrations** — Docker / Docker autoconf / Kubernetes (official Helm) / Docker Swarm / Linux native / Azure ARM template

- Upstream repo: <https://github.com/bunkerity/bunkerweb>
- Website: <https://www.bunkerweb.io>
- Docs: <https://docs.bunkerweb.io>
- Demo: <https://demo.bunkerweb.io> (attack it to test)
- UI demo: <https://demo-ui.bunkerweb.io>
- Docker Hub: <https://hub.docker.com/u/bunkerity>
- Helm chart: <https://github.com/bunkerity/bunkerweb-helm>

## Architecture in one minute

- **BunkerWeb container** — the nginx + ModSecurity runtime; serves traffic
- **Scheduler container** — the "brain"; reads settings, writes nginx config, runs jobs (cert renewal, blacklist refresh, etc.)
- **Database** — SQLite (default), MariaDB, MySQL, or PostgreSQL — stores configuration state
- **Web UI (optional)** — management UI; a separate container
- **Autoconf (Docker/Swarm mode)** — watches Docker events; dynamically reconfigures without container rebuild

Traffic flow: Client → BunkerWeb (443/80) → nginx + ModSec → upstream app

## Compatible install methods

| Infra          | Runtime                                               | Notes                                                      |
| -------------- | ----------------------------------------------------- | ---------------------------------------------------------- |
| Single VM      | Docker / Compose (BunkerWeb + Scheduler)                | **Simplest**                                                |
| Single VM      | Docker autoconf (labels on your app containers)           | No restarts needed for config changes                         |
| Kubernetes     | **Official Helm chart** (acts as Ingress controller)       | Production path for K8s                                          |
| Docker Swarm   | Swarm + autoconf                                          | Labels-driven                                                     |
| Linux          | Native DEB/RPM packages                                     | Debian 12/13, Ubuntu 22.04/24.04, Fedora 42/43, RHEL 8/9/10         |
| Cloud (Azure)  | Azure Marketplace + ARM template                            | <https://azuremarketplace.microsoft.com/marketplace/apps/bunkerity.bunkerweb> |

## Inputs to collect

| Input                  | Example                           | Phase      | Notes                                                              |
| ---------------------- | --------------------------------- | ---------- | ------------------------------------------------------------------ |
| `SERVER_NAME`          | `app.example.com www.example.com`  | Vhost      | Space-separated list                                                  |
| `AUTO_LETS_ENCRYPT`    | `yes`                              | TLS        | Also works with Cloudflare DNS-01 via env                                |
| `EMAIL_LETS_ENCRYPT`   | `admin@example.com`                | TLS        | For cert expiry notices                                                   |
| `REVERSE_PROXY_HOST_1` | `http://app:8080`                   | Upstream   | Your app container URL                                                      |
| `REVERSE_PROXY_URL_1`  | `/`                                 | Upstream   | Path to proxy                                                                |
| `USE_ANTIBOT`          | `captcha` / `javascript` / `recaptcha` / `hcaptcha` | Antibot | If public-facing + high-value                                                   |
| `USE_MODSECURITY`      | `yes` (default)                      | WAF        | OWASP CRS loaded                                                                  |
| `USE_BAD_BEHAVIOR`     | `yes` (default)                      | IP bans    | Auto-ban after N ModSec rule triggers                                                |
| Database               | SQLite (default) OR Mariadb/MySQL/PG   | State      | Stores settings + metadata                                                                |
| UI admin password      | strong                                 | UI         | Via env on first boot                                                                          |

## Install via Docker Compose (minimal)

```yaml
# Protects app.example.com, reverse-proxies to the "myapp" container
services:
  bunkerweb:
    image: bunkerity/bunkerweb:1.6.x    # pin — check Docker Hub for latest 1.6.x
    container_name: bunkerweb
    restart: unless-stopped
    ports:
      - "80:8080"
      - "443:8443"
    environment:
      SERVER_NAME: app.example.com
      API_WHITELIST_IP: "127.0.0.0/8 10.20.30.0/24"
    labels:
      - "bunkerweb.INSTANCE=yes"
    networks:
      - bw-universe
      - bw-services
    depends_on:
      - bw-scheduler

  bw-scheduler:
    image: bunkerity/bunkerweb-scheduler:1.6.x
    container_name: bw-scheduler
    restart: unless-stopped
    depends_on:
      - bw-db
    environment:
      DATABASE_URI: mariadb+pymysql://bunkerweb:<strong>@bw-db:3306/db
      BUNKERWEB_INSTANCES: bunkerweb
      SERVER_NAME: app.example.com
      AUTO_LETS_ENCRYPT: "yes"
      EMAIL_LETS_ENCRYPT: "admin@example.com"
      USE_MODSECURITY: "yes"
      USE_BAD_BEHAVIOR: "yes"
      USE_REVERSE_PROXY: "yes"
      REVERSE_PROXY_URL: "/"
      REVERSE_PROXY_HOST: "http://myapp:8080"
    volumes:
      - bw-data:/data
    networks:
      - bw-universe
      - bw-services

  bw-db:
    image: mariadb:11
    container_name: bw-db
    restart: unless-stopped
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: db
      MYSQL_USER: bunkerweb
      MYSQL_PASSWORD: <strong>
    volumes:
      - bw-mariadb:/var/lib/mysql
    networks:
      - bw-universe

  # Your application — BunkerWeb proxies to this
  myapp:
    image: yourimage:tag
    container_name: myapp
    restart: unless-stopped
    networks:
      - bw-services

networks:
  bw-universe:
    name: bw-universe
    ipam:
      config:
        - subnet: 10.20.30.0/24
  bw-services:
    name: bw-services

volumes:
  bw-data:
  bw-mariadb:
```

## Install the Web UI

Optional but recommended — add a fourth service:

```yaml
  bw-ui:
    image: bunkerity/bunkerweb-ui:1.6.x
    container_name: bw-ui
    restart: unless-stopped
    environment:
      DATABASE_URI: mariadb+pymysql://bunkerweb:<strong>@bw-db:3306/db
      ADMIN_USERNAME: admin
      ADMIN_PASSWORD: <strong-ui-password>
    networks:
      - bw-universe
    # Expose behind BunkerWeb itself at /bw-ui on an internal-only hostname
```

Access UI via a BunkerWeb vhost restricted to your IP/VPN.

## Autoconf mode (preferred for Docker)

Run **autoconf** container; add labels to your app containers:

```yaml
  myapp:
    image: yourimage:tag
    labels:
      bunkerweb.SERVER_NAME: app.example.com
      bunkerweb.USE_REVERSE_PROXY: "yes"
      bunkerweb.REVERSE_PROXY_URL: "/"
      bunkerweb.REVERSE_PROXY_HOST: http://myapp:8080
      bunkerweb.AUTO_LETS_ENCRYPT: "yes"
```

When you deploy a new container with labels, BunkerWeb reconfigures automatically — no restart.

## Multisite example

```yaml
environment:
  SERVER_NAME: app1.example.com app2.example.com
  # Per-site settings prefix with hostname
  app1.example.com_REVERSE_PROXY_HOST: http://app1:8080
  app1.example.com_USE_ANTIBOT: captcha
  app2.example.com_REVERSE_PROXY_HOST: http://app2:9000
  app2.example.com_USE_MODSECURITY: "yes"
  app2.example.com_WHITELIST_IP: "1.2.3.4 5.6.7.8"
```

## Data & config layout

- `/data` volume on scheduler — configs, certs, state
- `/data/letsencrypt` — ACME account + certificate files
- Database — source of truth for settings (don't edit files directly)
- Custom config files: mount to `/etc/bunkerweb/configs/<context>/` (http, server-http, modsec, modsec-crs, stream, server-stream)

## Backup

```sh
# Database = primary backup target
docker compose exec -T bw-db mariadb-dump -ubunkerweb -p<strong> db | gzip > bw-db-$(date +%F).sql.gz

# /data volume (certs + cache)
docker run --rm -v bw-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/bw-data-$(date +%F).tgz -C /src .
```

Let's Encrypt certs can be re-issued; DB is the valuable piece (all your configured vhosts + settings).

## Upgrade

1. Releases: <https://github.com/bunkerity/bunkerweb/releases>. Active.
2. **Read release notes carefully** — setting names change across minor versions (1.5 → 1.6 renamed many `USE_*` flags).
3. `docker compose pull` (all 3-4 BunkerWeb images) → `docker compose up -d`.
4. Scheduler runs DB migrations on startup; back up DB first.
5. Tags: `latest`, `1.6`, `1.6.9`, `1-rc` (RC). **Pin to exact version** in prod.

## Gotchas

- **Multi-container architecture** — BunkerWeb + Scheduler + (optional UI) + DB. Not a single-container deploy. Plan on ~4 containers total.
- **Scheduler is required** — without it, configs don't propagate; the BunkerWeb container alone won't work.
- **Database is mandatory** — even "simple" single-site deployments need SQLite at minimum. Settings live there, not env vars (scheduler reads env on first boot, then DB is source of truth).
- **Setting changes**: after first boot, editing env vars and restarting does NOT change config — you must edit via UI / API OR wipe DB. Unless you enable `OVERRIDE_ADMIN_CREDS` / explicit reset settings.
- **AutoLetsEncrypt requires port 80 reachable from the internet** for HTTP-01 challenge. Behind a corporate NAT? Use DNS-01 (Cloudflare plugin) instead.
- **1.5 → 1.6 migration** renamed many settings (`USE_REVERSE_PROXY_X` → separate per-vhost). Check the upgrade guide.
- **ModSecurity false positives** are common on modern apps (React/SPAs, JSON APIs). Expect to whitelist CRS rules for your apps — use the `MODSECURITY_CRS_PLUGINS_URLS`-style plugins or custom rule exclusions.
- **Antibot CAPTCHA** — CAPTCHA is friction for legit users. Reserve for suspicious paths (`/admin`, `/login`, `/wp-admin`) via per-URI config.
- **Bad-behavior threshold defaults** — too aggressive will ban legit users behind NAT (corporate offices, ISPs). Tune `BAD_BEHAVIOR_BAN_TIME` / `_THRESHOLD` / `_STATUS_CODES` / `_COUNT_TIME`.
- **Commercial Pro tier** exists — "crown icons" in docs mark PRO features (some advanced WAF rules, extra plugins, dedicated support). Claim with `freetrial` promo. Core OSS is genuinely usable.
- **Plugin gotcha**: ClamAV plugin downloads ~300 MB of virus definitions; VirusTotal plugin needs a VT API key (free tier very limited).
- **BunkerWeb Cloud** (managed SaaS) is in beta — alternative if you don't want to self-host the WAF layer.
- **AGPL-3.0 license** — modifications served to users must be shared. Commercial use allowed.
- **Alternatives worth knowing:**
  - **Nginx + manual ModSecurity + OWASP CRS** — DIY; more work; no UI
  - **Caddy + caddy-security** — simpler TLS, lighter WAF
  - **Traefik + CrowdSec bouncer** — excellent complementary pairing (Traefik for routing, CrowdSec for IP reputation)
  - **HAProxy + ModSecurity** — enterprise-proxy choice
  - **CrowdSec** (standalone) — collaborative IP reputation + bouncers (Nginx/Traefik/Caddy); pair with any reverse proxy (separate recipe)
  - **OWASP Coraza** — Go WAF; pairs with Caddy/Traefik as middleware
  - **Cloudflare / AWS WAF / Imperva** — commercial SaaS
  - **Naxsi** — nginx module for simpler rules (less extensive than ModSec)
  - **Choose BunkerWeb if:** you want an nginx-based turnkey WAF with UI + multisite + integrations + plugin system.
  - **Choose CrowdSec if:** you want collective threat intelligence + modular bouncers for existing reverse proxies.
  - **Choose Traefik + CrowdSec if:** you're already Traefik-centric.

## Links

- Repo: <https://github.com/bunkerity/bunkerweb>
- Website: <https://www.bunkerweb.io>
- Docs: <https://docs.bunkerweb.io>
- Quickstart: <https://docs.bunkerweb.io/latest/quickstart-guide/>
- Integrations: <https://docs.bunkerweb.io/latest/integrations/>
- Features reference: <https://docs.bunkerweb.io/latest/features/>
- Plugins: <https://github.com/bunkerity/bunkerweb-plugins>
- Helm chart: <https://github.com/bunkerity/bunkerweb-helm>
- Docker Hub: <https://hub.docker.com/u/bunkerity>
- Releases: <https://github.com/bunkerity/bunkerweb/releases>
- Demo (attack it): <https://demo.bunkerweb.io>
- Web UI demo: <https://demo-ui.bunkerweb.io>
- Threatmap: <https://www.bunkerweb.io/threatmap/>
- Discord: <https://discord.com/invite/fTf46FmtyD>
- PRO / professional services: <https://panel.bunkerweb.io>
