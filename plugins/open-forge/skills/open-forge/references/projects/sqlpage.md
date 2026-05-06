---
name: sqlpage
description: SQLPage recipe for open-forge. Covers Docker (recommended for servers) and binary (local/simple) install methods. SQLPage is an SQL-only web app builder — write .sql files and get clean, interactive web pages backed by SQLite, PostgreSQL, MySQL, MSSQL, or other databases.
---

# SQLPage

SQL-only web application builder. Write `.sql` files containing queries to your database and get good-looking interactive web pages displaying your data as text, lists, grids, plots, and forms. No HTML, CSS, or JavaScript required. Upstream: <https://github.com/sqlpage/SQLPage>. Docs: <https://sql-page.com>.

**License:** MIT · **Language:** Rust · **Default port:** 8080 · **Stars:** ~2,500

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/lovasoa/sqlpage> | ✅ | Recommended for servers — multi-arch (x86_64, arm64, armv7). |
| Binary download | <https://github.com/sqlpage/SQLPage/releases> | ✅ | Local development or simple single-server deploys on x86_64 Linux/macOS/Windows. |
| Build from source | <https://github.com/sqlpage/SQLPage> | ✅ | Custom builds; requires Rust toolchain. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method — Docker or binary?" | AskUserQuestion | Determines section below. |
| database | "Which database backend — SQLite (built-in, zero setup) or external (PostgreSQL/MySQL/MSSQL)?" | AskUserQuestion | Drives configuration below. |
| database_url | "Database connection string (e.g. postgres://user:pass@host/db)?" | Free-text (sensitive) | External DB only. |
| port | "Port to expose SQLPage on?" | Free-text (default 8080) | Both methods. |
| config | "Do you need a sqlpage.json config file (custom port, DB URL, etc.)?" | AskUserQuestion: Yes / No | Both methods. |
| proxy | "Are you placing a reverse proxy in front?" | AskUserQuestion: Yes / No | Optional. |

## Install — Docker (recommended)

Reference: <https://github.com/sqlpage/SQLPage#with-docker>

### SQLite (simplest — no external DB)

```bash
mkdir myapp
# Create your first SQL page
cat > myapp/index.sql << 'EOF'
SELECT 'list' AS component, 'My App' AS title;
SELECT 'Hello from SQLPage' AS title, 'This is my first page' AS description;
EOF

docker run -it \
  --name sqlpage \
  -p 8080:8080 \
  --volume "$(pwd)/myapp:/var/www" \
  --rm \
  lovasoa/sqlpage
```

Visit `http://localhost:8080`.

### Docker Compose (with config + external DB)

```yaml
services:
  sqlpage:
    image: lovasoa/sqlpage:main
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./source:/var/www           # SQL files (your application)
      - ./configuration:/etc/sqlpage:ro  # sqlpage.json config
    environment:
      # Or set DATABASE_URL here instead of in sqlpage.json
      DATABASE_URL: "postgres://user:password@db:5432/mydb"
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

Create directories and start:

```bash
mkdir source configuration
docker compose up -d
```

### Configuration file (sqlpage.json)

Place `sqlpage.json` in the configuration directory (mounted to `/etc/sqlpage`):

```json
{
  "listen_on": "0.0.0.0:8080",
  "database_url": "sqlite:///var/www/sqlpage.db",
  "max_database_pool_connections": 10,
  "allow_exec": false
}
```

## Install — Binary

Reference: <https://github.com/sqlpage/SQLPage/releases>

```bash
# Download the release for your OS (linux, macos, windows)
# Example for Linux x86_64:
wget https://github.com/sqlpage/SQLPage/releases/latest/download/sqlpage-linux.tgz
tar -xzf sqlpage-linux.tgz

# Create your SQL app directory and run
mkdir myapp
./sqlpage.bin --web-root myapp
```

SQLPage starts on port 8080. Create `myapp/index.sql` to build your first page.

Note: Precompiled binaries are x86_64 only. For ARM (Raspberry Pi, cheap ARM VPS), use the Docker image.

## Software-layer concerns

| Concern | Detail |
|---|---|
| SQL files | Place .sql files in the web root (/var/www in Docker). Each file is a page. |
| Database | Default: SQLite file at /var/www/sqlpage.db (zero config). External: set DATABASE_URL env var or sqlpage.json. |
| Configuration | sqlpage.json mounted to /etc/sqlpage in Docker; or placed next to binary. Controls port, DB URL, pool size, etc. |
| allow_exec | sqlpage.json option to allow running shell commands from SQL — disabled by default; keep disabled in production. |
| Port | Default 8080; change via listen_on in sqlpage.json or -p HOST:8080 in Docker. |
| Auth | None built-in — use a reverse proxy with basic auth, OAuth2 proxy, or SQLPage's built-in session/cookie features for app-level auth. |
| ARM support | Docker image supports arm64 and armv7; binary releases are x86_64 only. |
| Migrations | SQLPage supports running migration SQL files on startup via the sqlpage/migrations/ directory in the web root. |
| Static files | Place static assets in the web root alongside .sql files — served directly by SQLPage. |

## Upgrade procedure

```bash
# Docker
docker pull lovasoa/sqlpage:main
docker compose pull && docker compose up -d

# Binary
# Download new release, replace sqlpage.bin, restart service
```

SQLite database file and SQL application files are in mounted volumes — no data migration needed for upgrades unless SQL schema changes.

## Gotchas

- **ARM needs Docker:** Pre-built binaries are x86_64 only. On Raspberry Pi or ARM VPS, use the Docker image (`lovasoa/sqlpage` is multi-arch).
- **Base image stripped:** The `lovasoa/sqlpage` Docker image is extremely minimal and won't have standard tools. If building a custom image, use `debian:stable-slim` as base and copy the sqlpage binary from the official image: `COPY --from=lovasoa/sqlpage:main /usr/local/bin/sqlpage /usr/local/bin/sqlpage`.
- **allow_exec security:** Never enable `allow_exec: true` on a public-facing instance — it allows SQL pages to run arbitrary shell commands.
- **SQLite vs external DB:** SQLite is great for low-traffic apps and local development. For multi-user production apps with concurrent writes, use PostgreSQL or MySQL.
- **Web root path:** The Docker container expects SQL files at `/var/www`. Map your app directory there with `--volume "$(pwd)/source:/var/www"`.
- **sqlpage.json in /etc/sqlpage:** The config file must be in `/etc/sqlpage/sqlpage.json` inside the container (or next to the binary outside Docker). Mounting to /var/www won't work for config.

## Upstream links

- GitHub: <https://github.com/sqlpage/SQLPage>
- Docs / Get Started: <https://sql-page.com/get_started.sql>
- Docker Hub: <https://hub.docker.com/r/lovasoa/sqlpage>
- Releases: <https://github.com/sqlpage/SQLPage/releases>
