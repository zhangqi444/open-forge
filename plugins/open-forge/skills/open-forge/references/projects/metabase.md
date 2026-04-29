---
name: metabase-project
description: Metabase recipe for open-forge. AGPL-3.0 (OSS) / commercial (Pro/Enterprise) BI + dashboard tool. Java/Clojure app that connects to your existing databases and lets non-technical users build questions/dashboards/models. Ships as a single JAR or `metabase/metabase` Docker image; backed by an "application DB" (H2 default — fine for hobby, Postgres/MySQL required for production). This recipe covers the upstream-blessed install paths (JAR, Docker, Docker Compose with Postgres appdb) plus the H2-to-production migration procedure.
---

# Metabase

AGPL-3.0 open-source BI / dashboard tool. Connect to your databases, let users build questions + dashboards + embed them. Upstream: <https://github.com/metabase/metabase>. Docs: <https://www.metabase.com/docs/>.

Metabase is a Java/Clojure app that needs two databases:

1. **The user's data source(s)** — Postgres, MySQL, BigQuery, Snowflake, MongoDB, Redshift, etc. (read-only, or read/write for "Actions").
2. **The Metabase application database** — where Metabase stores its OWN state (questions, dashboards, users, permissions). H2 by default; **must be swapped for Postgres/MySQL for production**.

Default port: `:3000`.

## Editions

| Edition | License | What you get |
|---|---|---|
| **Metabase OSS** | AGPL-3.0 | Core BI features. Full self-host, no license key. |
| **Metabase Pro / Enterprise** | Commercial | Adds SSO (SAML, JWT, LDAP), advanced embedding, auditing, data sandboxing, advanced permissions, white-labeling. Requires a license activated in the admin UI. |
| **Metabase Cloud** | Managed | Their hosted offering; not covered here. |

Pro/Enterprise self-hosted: pull the `metabase-enterprise` image instead of `metabase`, activate license at `/admin/settings/license`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`metabase/metabase`) | <https://hub.docker.com/r/metabase/metabase> | ✅ Recommended | Most common deploy. |
| Docker + external Postgres (compose) | <https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-docker> | ✅ | Production-ready shape. |
| JAR on JVM | <https://www.metabase.com/docs/latest/installation-and-operation/running-the-metabase-jar-file> | ✅ | Bare-metal / no-Docker deploys. Needs Java 21 (current). |
| Metabase Enterprise image | <https://hub.docker.com/r/metabase/metabase-enterprise> | ✅ | Pro/Enterprise. |
| Kubernetes (Helm) | <https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-kubernetes> | ✅ | K8s with chart `metabase/metabase`. |
| AWS Elastic Beanstalk | <https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-elastic-beanstalk> | ⚠️ Deprecated in newer docs | Legacy deploys. Upstream is steering people toward Docker/K8s. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "OSS or Pro/Enterprise?" | `AskUserQuestion` | Picks image tag. |
| appdb | "Application DB — H2 (default, dev only) or external Postgres/MySQL?" | `AskUserQuestion` | **Production MUST use external DB.** H2 data loss risk + no upgrade story. |
| appdb | "Postgres host / port / DB / user / password?" | Free-text | Fills `MB_DB_*` env vars. |
| domain | "Public domain?" | Free-text | For `MB_SITE_URL`. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Metabase doesn't terminate TLS itself. |
| data-sources | "Which source DBs to connect?" | Multi-select (Postgres, MySQL, BigQuery, Snowflake, etc.) | Configured in admin UI after first boot; just affects network/firewall planning. |
| jvm | "JVM heap size?" | Free-text, default `-Xmx2g` for small, `-Xmx4g+` for production | `JAVA_OPTS` env var. |
| tz | "Report timezone?" | Free-text (e.g. `America/New_York`) | `MB_REPORT_TIMEZONE`. |

## Install — Docker quick start (H2, dev only)

Per upstream README:

```bash
docker pull metabase/metabase:latest
docker run -d -p 3000:3000 --name metabase metabase/metabase
docker logs -f metabase   # watch boot
# → http://localhost:3000
```

**Do not use this for production.** H2 is an embedded file DB that lives INSIDE the container's filesystem — `docker rm metabase` = every dashboard, user, permission is gone. Also no upgrade story (every Metabase upgrade rebuilds the H2 file; a corrupt H2 kills you).

## Install — Docker Compose (Postgres appdb, production)

From upstream's `running-metabase-on-docker.md`:

```yaml
# compose.yaml
services:
  metabase:
    image: metabase/metabase:latest     # or metabase-enterprise:latest
    container_name: metabase
    hostname: metabase
    restart: unless-stopped
    volumes:
      - /dev/urandom:/dev/random:ro      # upstream-recommended workaround for JVM entropy
    ports:
      - "3000:3000"
    environment:
      MB_DB_TYPE: postgres
      MB_DB_DBNAME: metabaseappdb
      MB_DB_PORT: 5432
      MB_DB_USER: metabase
      MB_DB_PASS: ${METABASE_DB_PASSWORD}
      MB_DB_HOST: postgres
      MB_SITE_URL: https://metabase.example.com
      JAVA_TIMEZONE: America/New_York
      JAVA_OPTS: "-Xmx2g"
    networks:
      - metanet1
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: curl --fail -I http://localhost:3000/api/health || exit 1
      interval: 15s
      timeout: 5s
      retries: 5
  postgres:
    image: postgres:16
    container_name: metabase-postgres
    hostname: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: metabase
      POSTGRES_DB: metabaseappdb
      POSTGRES_PASSWORD: ${METABASE_DB_PASSWORD}
    volumes:
      - ./pg_data:/var/lib/postgresql/data
    networks:
      - metanet1
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U metabase"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  metanet1:
    driver: bridge
```

```bash
echo "METABASE_DB_PASSWORD=$(openssl rand -hex 32)" > .env
docker compose up -d
docker compose logs -f metabase
# Wait ~1-2 min for migrations to complete on first boot.
```

Visit the SITE_URL; the setup wizard asks for admin name/email/password, default user language, and your first data source connection.

## Install — JAR file

```bash
# 1. Java 21 (current). Verify with `java -version`.
sudo apt-get install -y openjdk-21-jre-headless

# 2. Dedicated user + working dir
sudo useradd --system --no-create-home --shell /usr/sbin/nologin metabase
sudo mkdir -p /opt/metabase
sudo chown metabase:metabase /opt/metabase

# 3. Download JAR (check https://www.metabase.com/start/oss/jar for latest)
sudo -u metabase curl -L -o /opt/metabase/metabase.jar \
  https://downloads.metabase.com/latest/metabase.jar

# 4. Create env file with appdb config
sudo tee /etc/default/metabase > /dev/null <<'EOF'
MB_DB_TYPE=postgres
MB_DB_DBNAME=metabaseappdb
MB_DB_PORT=5432
MB_DB_USER=metabase
MB_DB_PASS=REPLACE_ME
MB_DB_HOST=127.0.0.1
MB_SITE_URL=https://metabase.example.com
JAVA_TIMEZONE=America/New_York
EOF
sudo chmod 600 /etc/default/metabase

# 5. Systemd unit
sudo tee /etc/systemd/system/metabase.service > /dev/null <<'EOF'
[Unit]
Description=Metabase
After=network.target postgresql.service

[Service]
Type=simple
User=metabase
Group=metabase
EnvironmentFile=/etc/default/metabase
WorkingDirectory=/opt/metabase
ExecStart=/usr/bin/java -Xmx2g -jar /opt/metabase/metabase.jar
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now metabase
sudo journalctl -u metabase -f
```

## H2 → production DB migration

If you started with the H2 default (or upgraded from an old install) and want to move to Postgres/MySQL:

```bash
# Docker
docker run -d --name metabase-migrate \
  -e "MB_DB_TYPE=postgres" \
  -e "MB_DB_DBNAME=metabaseappdb" \
  -e "MB_DB_PORT=5432" \
  -e "MB_DB_USER=metabase" \
  -e "MB_DB_PASS=${METABASE_DB_PASSWORD}" \
  -e "MB_DB_HOST=postgres" \
  -v /path/to/metabase.db:/metabase.db \
  metabase/metabase:latest \
  load-from-h2 /metabase.db
```

Wait for "Metabase Initialization COMPLETE" in the logs. Then start your production container pointed at the same Postgres. Full guide: <https://www.metabase.com/docs/latest/installation-and-operation/migrating-from-h2>.

**Do this BEFORE your install grows real data.** Migrating late = painful dump/restore exercise.

## Reverse proxy

```caddy
metabase.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

Set `MB_SITE_URL` to the public HTTPS URL — Metabase generates email links and embed tokens based on this.

## Upgrade procedure

```bash
# 1. Back up the application DB (Postgres appdb)
pg_dump -h 127.0.0.1 -U metabase metabaseappdb > metabase-appdb-$(date +%F).sql

# 2. Read release notes: https://github.com/metabase/metabase/releases

# 3. Docker
docker compose pull metabase
docker compose up -d metabase

# OR JAR
sudo systemctl stop metabase
sudo -u metabase curl -L -o /opt/metabase/metabase.jar \
  https://downloads.metabase.com/latest/metabase.jar
sudo systemctl start metabase

# 4. Check boot logs — Metabase runs Liquibase migrations on first start
docker compose logs -f metabase  # or journalctl -u metabase
```

Metabase auto-runs DB migrations. Major version bumps (0.49 → 0.50 etc.) sometimes include long migrations (5+ min). Don't kill the process during first boot.

## Gotchas

- **H2 is NOT for production.** The default embedded DB is convenient for 5-minute demos and nothing else. H2 files corrupt under load, there's no upgrade safety, and migrations on H2 are slower than Postgres. Set `MB_DB_TYPE=postgres` from day one on any real install.
- **`MB_SITE_URL` must be set.** Without it, email links in user invitations + password resets land at `http://localhost:3000/...` — unusable.
- **Memory is the #1 performance issue.** Metabase default heap is small (~1G). For any production install with teams, set `JAVA_OPTS="-Xmx2g"` minimum, `-Xmx4g` if you have many dashboards / lots of connected DBs. Monitor with `docker stats` / `jstat`.
- **Browser query cache vs DB cache.** Metabase caches question results in the app DB (configurable TTL). If users complain "my data is stale," check admin → Settings → Caching.
- **SSL to source databases.** If your source Postgres requires SSL, add `?sslmode=require` to the JDBC URL in the connection config, or the right provider-specific flag. Error messages are unhelpful.
- **Serialization (admin → Tools → Serialization)** is the way to move questions/dashboards between instances. Mentioned because it's not obvious from the UI.
- **Pro/Enterprise uses a separate image.** `metabase/metabase-enterprise` — don't try to pull the OSS image and activate a license (won't work; Enterprise features are compiled in).
- **Java version matters.** Current Metabase requires Java 21 for the JAR install. Old installs running Java 11 break on upgrade.
- **`JAVA_TIMEZONE` ≠ `MB_REPORT_TIMEZONE`.** The former affects JVM-level date handling; the latter affects how "This month" resolves in a question. Set both to the same value for sanity.
- **Default admin creation is first-signup-wins.** The setup wizard appears on first `http://host:3000` visit. If you expose Metabase before running the wizard, anyone can claim the admin account.
- **Embedding requires the `MB_EMBEDDING_SECRET_KEY` env var.** Rotating it invalidates all existing embedded links. Generate once, stash in secrets manager.
- **Metabase logs a LOT at INFO.** For production, set `-Dlog4j2.level=WARN` via `JAVA_OPTS`. Disk can fill up otherwise.
- **Version suffixes: `vX.Y.Z` (OSS) vs `vX.Y.Z-enterprise` (Enterprise).** Upstream release page has both; don't mix.

## Links

- Upstream repo: <https://github.com/metabase/metabase>
- Docs site: <https://www.metabase.com/docs/>
- Docker guide: <https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-docker>
- JAR guide: <https://www.metabase.com/docs/latest/installation-and-operation/running-the-metabase-jar-file>
- H2-to-production migration: <https://www.metabase.com/docs/latest/installation-and-operation/migrating-from-h2>
- Kubernetes guide: <https://www.metabase.com/docs/latest/installation-and-operation/running-metabase-on-kubernetes>
- Environment variables: <https://www.metabase.com/docs/latest/configuring-metabase/environment-variables>
- Enterprise / activation: <https://www.metabase.com/docs/latest/installation-and-operation/activating-the-enterprise-edition>
- Releases: <https://github.com/metabase/metabase/releases>
- Docker image: <https://hub.docker.com/r/metabase/metabase>
