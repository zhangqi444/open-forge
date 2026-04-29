---
name: nextcloud-project
description: Nextcloud recipe for open-forge. AGPL-3.0 content collaboration platform — files, calendars, contacts, mail, video calls, docs, talk, and dozens of official apps. The biggest-tent self-host project on selfh.st. Three distinct first-party install paths with very different tradeoffs — AIO (the Nextcloud GmbH-recommended path for most self-hosters, ships Talk+Imaginary+ClamAV etc.), the community-maintained `nextcloud/docker` images (expert use, BYO reverse proxy + DB), and the official Helm chart for Kubernetes. This recipe covers all three + the common pitfalls (trusted_domains, OCC, upgrade path, external-storage backends, background jobs).
---

# Nextcloud

AGPL-3.0 content collaboration platform — the Swiss Army knife of self-host. Upstream: <https://github.com/nextcloud/server>. Docs: <https://docs.nextcloud.com>. Official hosted demos + commercial support: <https://nextcloud.com>.

Features encompass file sync+share (Dropbox-alike), calendars, contacts, mail, Talk (voice/video/chat), Office (Collabora/OnlyOffice integration), password manager, notes, news reader, tasks, forms, deck (kanban), and an app store with hundreds of community apps.

## Three first-party install paths — pick one deliberately

| Method | Upstream | When to use | Maintainer |
|---|---|---|---|
| **Nextcloud All-in-One (AIO)** | <https://github.com/nextcloud/all-in-one> | Recommended for **most self-hosters**. Includes Talk + HPB + Imaginary + ClamAV + backup + reverse proxy. One master container orchestrates the rest. | Nextcloud GmbH (official) |
| **`nextcloud/docker` image** (`nextcloud:latest`) | <https://github.com/nextcloud/docker> | **Expert use.** BYO reverse proxy, BYO database, BYO Talk/HPB, BYO backup. Flexible but every knob is yours. | Community volunteers, upstream-blessed |
| **Helm chart** | <https://github.com/nextcloud/helm> | Kubernetes deploys. | Community, semi-official |
| Tarball / .deb (bare metal) | <https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html> | Traditional LAMP on a VPS. Historically the default; now eclipsed by Docker. | Nextcloud GmbH |

**The upstream `nextcloud/docker` README has a ⚠️ note that literally tells people to use AIO unless they specifically need the fine-grained control.** Don't skip this — most "my Nextcloud is broken" threads are people who picked `nextcloud/docker` because it looked simpler, then discovered they also needed to provision + configure Postgres, Redis, cron, Collabora, HPB, etc. separately.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `aio` / `docker-compose` / `helm` / `bare-metal` | Drives section. |
| preflight | "Want Nextcloud Talk / Office / ClamAV bundled?" | Boolean | If yes → AIO. If no → either path works but AIO still simpler. |
| dns | "Public domain?" | Free-text | Required by AIO; trusted_domains requirement for all paths. |
| tls | "HTTPS source?" | `AskUserQuestion`: `AIO built-in (Caddy+LE)` / `External reverse proxy` / `Cloudflare Tunnel` / `Tailscale` | AIO's built-in Caddy handles TLS automatically with a public domain. For internal/LAN use, pick reverse-proxy mode. |
| db | "Database?" | `AskUserQuestion`: `postgres (recommended)` / `mysql` / `mariadb` / `sqlite` | AIO auto-provisions Postgres. `nextcloud/docker` compose — you pick. SQLite is demo-only. |
| admin | "Initial admin username + password?" | Free-text (sensitive) | AIO has its own password for the master container; Nextcloud admin user is set during web-wizard on first visit. |
| storage | "Data dir location?" | Free-text, default varies by install | Where uploaded files live. Back up this + the DB. |
| apps | "Bundled apps to enable on first install?" | Multi-select | Set via `NEXTCLOUD_APPS_INSTALL` in AIO or `occ app:install` after bootstrap. |

## Install — Nextcloud All-in-One (AIO) — RECOMMENDED

```bash
# Minimal invocation from upstream README
docker run \
  --init \
  --sig-proxy=false \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  --publish 80:80 \
  --publish 8080:8080 \
  --publish 8443:8443 \
  --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/nextcloud-releases/all-in-one:latest
```

Then:

1. Open `https://<host>:8443/` (self-signed cert — accept).
2. Copy the shown master password. **Save it immediately.**
3. Enter your public domain — AIO verifies DNS points at this host.
4. AIO spawns the other containers: Nextcloud, PostgreSQL, Redis, HPB, Collabora, Talk, etc. based on checkboxes.
5. Once all green, click the generated login link to reach Nextcloud; complete the initial admin wizard.

### Reverse proxy mode

If you already run a reverse proxy (Caddy / nginx / Traefik) and want to keep it:

```bash
docker run \
  --init \
  --sig-proxy=false \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  --publish 8080:8080 \
  --env APACHE_PORT=11000 \
  --env APACHE_IP_BINDING=127.0.0.1 \
  --env SKIP_DOMAIN_VALIDATION=false \
  --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/nextcloud-releases/all-in-one:latest
```

Then point your reverse proxy at `127.0.0.1:11000` with the correct headers. See <https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md> for the Caddy / nginx / Traefik / HAProxy snippets.

## Install — `nextcloud/docker` + Postgres (expert)

```yaml
# compose.yaml — expert-only; BYO everything
services:
  db:
    image: postgres:16-alpine
    restart: always
    volumes:
      - ./db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  redis:
    image: redis:7-alpine
    restart: always

  app:
    image: nextcloud:30-apache      # pin major.minor
    restart: always
    ports:
      - '8080:80'
    volumes:
      - ./html:/var/www/html
    environment:
      POSTGRES_HOST: db
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      REDIS_HOST: redis
      NEXTCLOUD_ADMIN_USER: admin
      NEXTCLOUD_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      NEXTCLOUD_TRUSTED_DOMAINS: 'cloud.example.com'
      OVERWRITEPROTOCOL: 'https'
      OVERWRITEHOST: 'cloud.example.com'
    depends_on:
      - db
      - redis

  cron:
    image: nextcloud:30-apache
    restart: always
    volumes:
      - ./html:/var/www/html
    entrypoint: /cron.sh
    depends_on:
      - app
```

Bring up:

```bash
echo "DB_PASSWORD=$(openssl rand -hex 24)" > .env
echo "ADMIN_PASSWORD=$(openssl rand -base64 24)" >> .env
docker compose up -d
docker compose logs -f app
```

The `cron` service runs `/cron.sh` every 5 minutes — **required** for background jobs (file indexing, email notifications, previews). Without it, Nextcloud lives in "AJAX cron" mode which only runs jobs when a user clicks around, and everything feels slow/broken.

### Reverse proxy for `nextcloud/docker` (Caddy)

```caddy
cloud.example.com {
    reverse_proxy app:80
    header Strict-Transport-Security "max-age=15552000"

    # Redirect well-known URLs for CalDAV/CardDAV discovery
    redir /.well-known/carddav  /remote.php/dav 301
    redir /.well-known/caldav   /remote.php/dav 301
    redir /.well-known/webfinger /index.php/.well-known/webfinger 301
    redir /.well-known/nodeinfo /index.php/.well-known/nodeinfo 301
}
```

## Install — Helm (Kubernetes)

```bash
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update
helm install my-nextcloud nextcloud/nextcloud \
  --set nextcloud.host=cloud.example.com \
  --set nextcloud.username=admin \
  --set nextcloud.password='<strong-password>' \
  --set internalDatabase.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.type=postgresql \
  --set externalDatabase.host=postgres.database.svc.cluster.local \
  --set externalDatabase.user=nextcloud \
  --set externalDatabase.password='<db-password>' \
  --set externalDatabase.database=nextcloud \
  --set redis.enabled=true
```

Values reference: <https://github.com/nextcloud/helm/tree/main/charts/nextcloud>. Configure an Ingress with cert-manager for TLS.

## OCC (Nextcloud's CLI)

Every serious Nextcloud admin ends up using `occ`. Run inside the container:

```bash
# AIO:
docker exec --user www-data -it nextcloud-aio-nextcloud php occ status

# nextcloud/docker:
docker exec --user www-data -it <app-container> php occ status

# bare metal:
sudo -u www-data php /var/www/html/occ status
```

Common commands:

```bash
occ maintenance:mode --on            # Maintenance mode (required before manual upgrades)
occ maintenance:repair               # Repair DB integrity
occ files:scan --all                 # Rescan file storage (after external changes)
occ app:install richdocuments        # Install Collabora app
occ user:add newuser                 # Create user
occ user:resetpassword admin         # Reset admin password
occ trusted_domains:list             # List trusted domains
occ config:system:set overwrite.cli.url --value=https://cloud.example.com
occ db:convert-type pgsql nextcloud 127.0.0.1 nextcloud    # Migrate DB backend
```

## Data layout

### AIO

All data lives in named Docker volumes managed by the master container. AIO's backup feature (BorgBackup) handles snapshotting.

### `nextcloud/docker`

- `html/` — application + `config/config.php` + `data/` (user files, if default)
- Separately:
  - `html/data/` — user files (move to external mount for large deployments)
  - `html/config/config.php` — site config (trusted_domains, DB creds, etc.)
  - `html/custom_apps/` — installed community apps

**Back up `config.php`, the DB, and the `data/` directory together.** A config+DB backup without the data directory is useless.

## Trusted domains + reverse proxy

The #1 self-host confusion. Nextcloud refuses requests whose `Host` header isn't in `trusted_domains`. Set it:

```bash
# Via occ
occ config:system:set trusted_domains 0 --value=cloud.example.com
occ config:system:set trusted_domains 1 --value=192.168.1.50    # LAN IP if needed
occ config:system:set trusted_domains 2 --value=localhost       # for health checks

# Via env on first boot (nextcloud/docker):
NEXTCLOUD_TRUSTED_DOMAINS: 'cloud.example.com 192.168.1.50'

# Or edit config/config.php:
'trusted_domains' => [
    0 => 'cloud.example.com',
    1 => '192.168.1.50',
],
```

For reverse proxy + HTTPS, also set:

```php
'overwriteprotocol' => 'https',
'overwritehost' => 'cloud.example.com',
'overwrite.cli.url' => 'https://cloud.example.com',
'trusted_proxies' => ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'],
```

Without `overwriteprotocol=https`, Nextcloud generates `http://` URLs in emails + shares, which 404 when the user clicks them through HTTPS.

## External storage

Nextcloud can attach external storage: S3, SMB/CIFS, FTP, SFTP, WebDAV, NFS (via host mount), Google Drive, Dropbox. **Settings → Administration → External storage**.

To use S3 as **primary storage** (all user files in S3 rather than local FS), configure in `config.php`:

```php
'objectstore' => [
    'class' => '\\OC\\Files\\ObjectStore\\S3',
    'arguments' => [
        'bucket' => 'nextcloud-data',
        'key'    => 'AKIA...',
        'secret' => '...',
        'region' => 'us-east-1',
        'use_path_style' => true,   // if using MinIO or compat
    ],
],
```

This must be set BEFORE first use. Migrating existing data to S3 is manual + painful.

## Upgrade procedure

### AIO

Just click "Update" in the AIO web UI. AIO handles container recreation + `occ upgrade` internally. Only jumps one major version at a time (e.g. 29 → 30 → 31); AIO refuses to skip majors.

### `nextcloud/docker`

```bash
# 1. Back up DB + html/ first
occ maintenance:mode --on

# 2. Bump image tag to next MAJOR version (e.g. nextcloud:29 → nextcloud:30)
# 3. docker compose pull && docker compose up -d
# 4. The container runs occ upgrade automatically on startup
docker compose logs -f app   # watch for errors

occ maintenance:mode --off
```

Nextcloud refuses to skip major versions. `28 → 30` requires going through `29` first. Follow the chain.

## Gotchas

- **Pick AIO unless you have a reason not to.** Most "my Nextcloud is slow / broken / upgrade failed" threads are from people who chose `nextcloud/docker` without understanding they needed to provision cron, HPB, Redis, Collabora, and TLS themselves.
- **Background jobs matter.** Without the `cron` container (or systemd timer on bare metal), file indexing, share notifications, and app-store updates silently don't run. Symptom: "file I uploaded isn't showing up in the mobile app for 20 minutes." Fix: ensure cron.
- **`trusted_domains` blocks requests for unknown hosts.** Symptom: "Access through untrusted domain" error. Fix: add to `trusted_domains` via `occ` or `config.php`.
- **Major version upgrades are one-at-a-time.** v28 → v30 via v29. Nextcloud refuses the jump otherwise. Read release notes — occasional apps get deprecated and need reinstalling.
- **`latest` tag on `nextcloud/docker` is scary.** Points at the newest major version. Auto-updaters can leapfrog you across a major boundary and break. Pin `nextcloud:30-apache` or similar.
- **`NEXTCLOUD_ADMIN_USER` / `NEXTCLOUD_ADMIN_PASSWORD` only work on FIRST boot.** After the setup wizard runs once, they do nothing. To reset admin password: `occ user:resetpassword admin`.
- **Preview generation is CPU-heavy.** The `OC\Preview\Generator` job runs in cron. For big libraries, install the `preview_generator` app + run `occ preview:pre-generate` in batches to avoid bogging down the cron container.
- **ONLY add trusted proxies for LANs you actually control.** If you add `0.0.0.0/0` to `trusted_proxies`, attackers can spoof `X-Forwarded-For` and bypass IP rate limits + audit logs.
- **Collabora / OnlyOffice are separate containers.** The `richdocuments` Nextcloud app is just a UI plugin; it needs a Collabora server running alongside. AIO provides this; `nextcloud/docker` does NOT — provision separately.
- **Default memory limits too low for big libraries.** `PHP_MEMORY_LIMIT` env var defaults to 512M. For users with >100k files or >20 GB, bump to 2G. Also raise upload limits: `PHP_UPLOAD_LIMIT=10G`.
- **`.well-known` redirects are crucial for CalDAV/CardDAV.** iOS Calendar/Contacts won't auto-configure without them. Add the redir rules in your reverse proxy (see Caddy example above).
- **Data-dir migration is manual.** Moving `data/` to a different mount requires stopping Nextcloud, rsyncing, updating `datadirectory` in `config.php`, restarting. Don't `rsync` while running.
- **AIO binds ports 80/443/8080/8443.** Conflicts with anything else on those ports. Use reverse-proxy mode if another service already holds 80/443.
- **Talk requires a separate TURN/STUN server (Coturn) + HPB for group calls.** AIO bundles both; `nextcloud/docker` requires you to stand them up yourself.
- **Config-file precedence:** `config/config.php` is edited in place + persists. `config/` env-var injection only applies on first boot. Changes via the Nextcloud admin UI write back to `config.php`. If you bake settings into env vars, ALSO document them somewhere for the next sysadmin.

## Links

- Server repo: <https://github.com/nextcloud/server>
- AIO repo: <https://github.com/nextcloud/all-in-one>
- Docker image repo: <https://github.com/nextcloud/docker>
- Helm chart: <https://github.com/nextcloud/helm>
- Admin docs: <https://docs.nextcloud.com/server/latest/admin_manual/>
- Upgrade docs: <https://docs.nextcloud.com/server/latest/admin_manual/maintenance/upgrade.html>
- AIO reverse proxy guide: <https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md>
- App store: <https://apps.nextcloud.com>
- Community forum: <https://help.nextcloud.com>
- Releases: <https://github.com/nextcloud/server/releases>
