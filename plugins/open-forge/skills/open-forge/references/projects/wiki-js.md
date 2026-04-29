---
name: wiki-js-project
description: Wiki.js recipe for open-forge. AGPLv3 modern lightweight wiki on Node.js — Markdown or WYSIWYG editing, Git sync, multiple authentication backends (local / LDAP / OAuth / SAML / OIDC), granular page permissions, tag-based organization, full-text search, i18n, Let's Encrypt built-in, rendering pipeline (Markdown/HTML/AsciiDoc/reST). Supports PostgreSQL (recommended) / MySQL / MariaDB / MSSQL / SQLite. Multi-arch (amd64 + arm64 from v2.4). Covers Docker Compose with Postgres, Docker run, env vars reference (DB_*, LETSENCRYPT_*), config.yml alternative, Kubernetes / Heroku deploy targets, upgrade procedure, and the v2-vs-v3 reality (v2 is current stable; v3 "Next" in development for years).
---

# Wiki.js

AGPLv3 modern wiki software. Upstream: <https://github.com/requarks/wiki>. Docs: <https://docs.requarks.io>. Website: <https://js.wiki>.

Modern, lightweight, full-featured wiki with a big feature set: Markdown + WYSIWYG + visual editor, Git sync, LDAP/OAuth/SAML/OIDC auth, tag-based navigation, full-text search, multi-language, comments, page history/diffs, page permissions by group, Let's Encrypt automation, rendering pipeline for Markdown/HTML/AsciiDoc/reStructuredText, API (GraphQL).

## ⚠️ v2 vs "v3" (a.k.a. "Wiki.js Next")

As of recipe-write-time:

- **v2.x** — the current **stable** version. Fully featured. All tutorials + documentation refer to v2. **Use v2 for new deploys.**
- **v3 / "Wiki.js Next"** — in long-running alpha/beta development. Not feature-complete; not recommended for production. Timeline uncertain.

Pin `ghcr.io/requarks/wiki:2` (or a minor like `:2.5`) in production. **Avoid `:latest`** — upstream docs explicitly warn against `latest` for Wiki.js.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.requarks.io/install/docker> | ✅ Recommended | Most self-hosters. |
| Docker run | <https://docs.requarks.io/install/docker> | ✅ | Single-container use. |
| Linux binary / tarball | <https://docs.requarks.io/install/linux> | ✅ | Bare-metal / systemd. |
| Ubuntu apt package | <https://docs.requarks.io/install/ubuntu> | ✅ | Debian/Ubuntu. |
| Windows | <https://docs.requarks.io/install/windows> | ✅ | IIS + Node on Windows Server. |
| macOS | <https://docs.requarks.io/install/macos> | ✅ | Dev only. |
| Kubernetes | <https://docs.requarks.io/install/kubernetes> | ✅ | Clusters. |
| Heroku | <https://docs.requarks.io/install/heroku> | ✅ | Managed. |
| DigitalOcean 1-click | <https://docs.requarks.io/install/digitalocean> | ✅ | DO users. |
| AWS / Azure | <https://docs.requarks.io/install/aws> / `/azurewebapp` | ✅ | Cloud-specific. |
| Portainer | <https://docs.requarks.io/install/portainer> | ✅ | UI on top of Docker. |

Image registries:

- `ghcr.io/requarks/wiki:2` — GitHub Container Registry (upstream-preferred)
- `requarks/wiki:2` — Docker Hub mirror

Multi-arch: amd64 + arm64 (from v2.4). ARMv7 dropped as of v2.5.304 (last supported v2.5.303). Original Pi v1 (ARMv6) never supported.

## Database backend

Wiki.js does NOT bundle a database. Supported databases (`DB_TYPE`):

| Option | Note |
|---|---|
| `postgres` | **Recommended by upstream.** Best-tested. |
| `mysql` | Works. |
| `mariadb` | Works. |
| `mssql` | Works. Microsoft SQL Server. |
| `sqlite` | Works for small / single-user. Not for multi-user production. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `linux-binary` / `kubernetes` / `heroku` / `digitalocean` | Drives section. |
| db | "Database type?" | `AskUserQuestion`: `postgres` / `mysql` / `mariadb` / `mssql` / `sqlite` | Postgres recommended. |
| db | "DB host / port / user / pass / name?" | Multi-field | Required unless `sqlite`. |
| db | "DB SSL?" | Boolean | `DB_SSL=1` if yes; may need `DB_SSL_CA`. |
| ports | "HTTP port?" | Default `3000` internal; map to `80` or behind proxy | |
| tls | "TLS provisioning?" | `AskUserQuestion`: `letsencrypt-built-in` / `reverse-proxy-handles-tls` / `config-file-manual` | Wiki.js can do LE directly (port 80 + 443 exposed). |
| tls | "ACME email + domain?" | Required if `letsencrypt-built-in` | `LETSENCRYPT_DOMAIN`, `LETSENCRYPT_EMAIL`. |
| user | "Run as `wiki` or `root`?" | Default `wiki` | Use `-u root` only for SQLite + volume-permission issues. |
| config | "Config source?" | `AskUserQuestion`: `env-vars` / `config.yml-mounted` | Env vars are easier; config.yml needed for HA / advanced setups. |

## Install — Docker Compose (PostgreSQL)

From upstream docs (<https://docs.requarks.io/install/docker>):

```yaml
# compose.yaml
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: wiki
      POSTGRES_PASSWORD: wikijsrocks     # CHANGE THIS
      POSTGRES_USER: wikijs
    logging:
      driver: none
    restart: unless-stopped
    volumes:
      - db-data:/var/lib/postgresql/data

  wiki:
    image: ghcr.io/requarks/wiki:2        # pin a minor in prod e.g. :2.5
    depends_on: [db]
    init: true
    environment:
      DB_TYPE: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: wikijs
      DB_PASS: wikijsrocks
      DB_NAME: wiki
    restart: unless-stopped
    ports:
      - "80:3000"

volumes:
  db-data:
```

Bring up:

```bash
docker compose up -d
# → http://<host>/ — first-run setup wizard
```

The setup wizard asks for admin email + password + site URL. Complete it, then log in.

## Install — Docker run (one-liner)

```bash
# PostgreSQL backend (assumes a `db` container on same network)
docker run -d \
  --name wiki --restart unless-stopped \
  -p 8080:3000 \
  -e DB_TYPE=postgres \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e DB_USER=wikijs \
  -e DB_PASS=wikijsrocks \
  -e DB_NAME=wiki \
  ghcr.io/requarks/wiki:2
```

### With Let's Encrypt built-in

```bash
docker run -d \
  --name wiki --restart unless-stopped \
  -p 80:3000 -p 443:3443 \
  -e LETSENCRYPT_DOMAIN=wiki.example.com \
  -e LETSENCRYPT_EMAIL=admin@example.com \
  -e DB_TYPE=postgres -e DB_HOST=db -e DB_PORT=5432 \
  -e DB_USER=wikijs -e DB_PASS=wikijsrocks -e DB_NAME=wiki \
  ghcr.io/requarks/wiki:2
```

Both port 80 + 443 MUST be reachable from the internet for LE issuance AND renewal. After first cert issuance, you can optionally enable HTTPS-redirect in the Admin UI → SSL section.

## Environment variables reference

| Variable | Default | Purpose |
|---|---|---|
| `DB_TYPE` | — | `postgres` / `mysql` / `mariadb` / `mssql` / `sqlite` |
| `DB_HOST` | — | DB hostname |
| `DB_PORT` | — | DB port |
| `DB_USER` | — | DB user |
| `DB_PASS` | — | DB password |
| `DB_PASS_FILE` | — | Alternate: path to a file containing the password (Docker secrets) |
| `DB_NAME` | — | DB name |
| `DB_SSL` | off | `1` / `true` to enable SSL |
| `DB_SSL_CA` | — | CA cert as single-line string (v2.3+) |
| `DB_FILEPATH` | — | Path to SQLite file (SQLite only) |
| `SSL_ACTIVE` | off | `1` / `true` to enable built-in TLS |
| `LETSENCRYPT_DOMAIN` | — | LE domain |
| `LETSENCRYPT_EMAIL` | — | LE admin email |
| `CONFIG_FILE` | — | Alternate config file path when mounting `config.yml` |
| `HA_ACTIVE` | off | High-availability mode |

Complete reference: <https://docs.requarks.io/install/docker>.

## Alternative — mount `config.yml`

Prefer a file over env vars? Download the sample:

```bash
curl -fsSLO https://raw.githubusercontent.com/Requarks/wiki/master/config.sample.yml
mv config.sample.yml config.yml
# Edit config.yml to match your setup

docker run -d -p 8080:3000 \
  --name wiki --restart unless-stopped \
  -v "$(pwd)/config.yml:/wiki/config.yml" \
  ghcr.io/requarks/wiki:2
```

Config file docs: <https://docs.requarks.io/install/config>.

## Reverse proxy (Caddy example)

```caddy
wiki.example.com {
    reverse_proxy wiki:3000
}
```

With a reverse proxy, don't set `LETSENCRYPT_*` (let Caddy/Traefik/nginx handle TLS). Don't expose Wiki.js port 443 directly.

## Non-root / permission issues

By default, the container runs as user `wiki`. If you hit permission issues with mounted volumes (common with SQLite or mounted certs), either:

- Adjust host-side file ownership to match `wiki` UID (default 1000).
- OR run as root:

```yaml
services:
  wiki:
    image: ghcr.io/requarks/wiki:2
    user: root    # not secure, but sometimes necessary
```

## First-run setup

1. Open `http://<host>/` or `https://wiki.example.com/`.
2. Setup wizard: admin email + password + site URL + admin locale.
3. Save → you're in.
4. Admin area → **General** → set site title, theme.
5. Admin area → **Authentication** → enable additional auth backends (LDAP, OAuth2, SAML, OIDC, Google, GitHub, Facebook, Microsoft, Auth0, etc.).
6. Admin area → **Groups** → create groups and page-access rules.
7. Admin area → **Storage** → configure optional Git sync (commit pages to a repo), Local Disk backup, Dropbox/Google Drive/S3 backup.
8. Admin area → **Modules** → enable renderers (Markdown, HTML, AsciiDoc, reST, etc.).

## Git sync

Wiki.js can commit + pull page changes to a Git repo. Admin → Storage → Git. Requires:

- A Git repo (self-hosted Gitea / GitHub / GitLab / etc.)
- SSH key (generated by Wiki.js or yours) added as deploy key
- Branch name + commit author identity

Good for: disaster recovery, markdown versioning, collaborating via PRs.

## Data layout

| Path | Content |
|---|---|
| Database | Pages, revisions, users, groups, uploads metadata, auth, config |
| `/wiki/data/` | Uploads (if not using S3/etc.) — binary assets |
| `/wiki/config.yml` | Config file (if mounted) |

**Backup priority:**

1. **Database** (`pg_dump` / `mysqldump`) — all content.
2. **`/wiki/data/`** — uploaded files.
3. `config.yml` — if you use it instead of env vars.

## Upgrade procedure

Upstream upgrade doc: <https://docs.requarks.io/install/upgrade>.

```bash
# Docker Compose
docker compose pull
docker compose up -d
docker compose logs -f wiki
```

Wiki.js runs DB migrations on startup automatically. **Don't skip minor versions** between v2.0 and current for production — some migrations are one-way. Major version jump (v2 → v3) will require a full data migration when v3 is GA.

**Tag pinning:**

- `:2` — latest v2.x (auto-upgrades on pull)
- `:2.5` — latest v2.5.x (recommended for production — predictable)
- `:2.5.307` — specific patch (most predictable)

## Gotchas

- **Don't use `:latest`.** Upstream docs explicitly warn: use a major tag (`:2`) or minor tag (`:2.5`) at minimum. `:latest` can unexpectedly jump to v3 when that's GA.
- **First-run setup wizard must complete before anything works.** If you navigate away mid-setup, reload → resume. If you rebuild the DB, you redo setup.
- **`LETSENCRYPT_DOMAIN` needs port 80 AND 443 reachable from the public internet.** LE HTTP-01 challenge uses port 80; certificate renewal (every ~60 days) also needs port 80. If behind a load balancer, ensure it forwards port 80 too.
- **LE renewal is automatic** (runs internally in the container). But if your domain ever becomes unreachable on port 80 during the renewal window, the cert expires. Monitor the Admin → SSL page.
- **Database is NOT bundled.** You need to run Postgres / MySQL / MariaDB / MSSQL / SQLite yourself. `compose.yaml` above provides Postgres.
- **SQLite for multi-user production = bad.** Works for tiny read-heavy sites; locks up under concurrent writes. Use Postgres.
- **PostgreSQL 15 is what the official docs recommend.** Newer Postgres versions (16, 17) work but aren't explicitly tested.
- **`DB_PASS_FILE`** reads the password from a file — useful with Docker secrets or Kubernetes sealed secrets. Use instead of `DB_PASS` when you don't want passwords in env vars.
- **Git sync conflicts are real.** If you edit pages via the Wiki.js UI AND push commits directly to the repo, merge conflicts happen. Pick one as the source of truth; Wiki.js handles bidirectional but not gracefully under rapid conflicting updates.
- **AsciiDoc / reST renderers need optional dependencies.** Admin → Modules → Rendering — enable only what you need; enabling all bloats memory.
- **Full-text search uses the database.** For Postgres, it uses tsvector columns. Performance is fine up to ~10K pages; beyond that consider external search backends (Elasticsearch via Wiki.js config).
- **OAuth/SAML setup is per-provider fiddly.** Callback URL must match EXACTLY what you registered with the provider. A common mistake: dev env `http://localhost:3000/login/...` vs prod `https://wiki.example.com/login/...`. Each deploy needs its own provider app/registration.
- **File uploads — max size.** Default 5 MB; configurable in Admin → Storage. Ensure reverse proxy doesn't impose a smaller limit (nginx default `client_max_body_size 1m` will override).
- **v3 ("Next") has been in development for years.** Don't plan migrations based on "v3 is coming soon." It will ship when ready; v2 is indefinitely maintained.
- **Mobile UI is basic.** Wiki.js is desktop-first. Reading works; editing on mobile is clunky.
- **Page permissions are additive.** A user in multiple groups gets the UNION of permissions. There's no "deny" rule per se; permissions are whitelist-based.
- **Admin account recovery**: if you lock yourself out, see <https://docs.requarks.io/install/sideload> — you can sideload a recovery config that resets admin password via the CLI.
- **Comments + threaded discussions** need admin enabling + optional external comment engine (Commento, Isso, Disqus, etc.). Not on by default.
- **Wiki.js v2 uses Node.js 18** internally (bundled in the image). Don't confuse with whatever Node is on your host.
- **ARMv7 users**: don't upgrade past v2.5.303. Last supported version for 32-bit ARM.

## Links

- Upstream repo: <https://github.com/requarks/wiki>
- Docs site: <https://docs.requarks.io>
- Docker install: <https://docs.requarks.io/install/docker>
- Requirements: <https://docs.requarks.io/install/requirements>
- Config file reference: <https://docs.requarks.io/install/config>
- Upgrade: <https://docs.requarks.io/install/upgrade>
- Docker images (GHCR): <https://github.com/Requarks/wiki/pkgs/container/wiki>
- Docker images (Hub): <https://hub.docker.com/r/requarks/wiki>
- Releases: <https://github.com/requarks/wiki/releases>
- Demo: <https://docs.requarks.io/demo>
- Discord: <https://discord.gg/rcxt9QS2jd>
- Feedback / feature requests: <https://feedback.js.wiki/wiki>
- Subreddit: <https://reddit.com/r/wikijs>
