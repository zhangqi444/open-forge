---
name: isso
description: Isso recipe for open-forge. Lightweight self-hosted commenting server (Disqus alternative) written in Python with SQLite. Covers pip install, Docker, and website embed snippet. Upstream: https://github.com/isso-comments/isso
---

# Isso

Lightweight commenting server written in Python and JavaScript. Drop-in replacement for Disqus. Users comment in Markdown, moderation queue, email notifications, SQLite backend. Embed with a single JavaScript snippet.

5,275 stars · MIT

Upstream: https://github.com/isso-comments/isso
Website: https://isso-comments.de/
Docs: https://isso-comments.de/docs/
Quickstart: https://isso-comments.de/docs/guides/quickstart/

## What it is

Isso provides self-hosted blog/website comments:

- **Markdown comments** — Users write in Markdown; edit/delete within 15 minutes
- **Moderation** — Optional moderation queue; admin approval before public visibility
- **Email notifications** — Notify author and/or admin on new comments
- **SQLite backend** — Simple, file-based storage; no external database required
- **Disqus/WordPress import** — Migrate existing comments from Disqus or WordPress
- **Spam protection** — Rate limiting, CSRF protection, optional Gravatar
- **Multi-site** — One Isso instance can serve multiple websites
- **No tracking** — No ads, no telemetry, no third-party dependencies for users

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| pip (recommended) | https://isso-comments.de/docs/reference/installation/ | Direct install on any Python 3.7+ system |
| Docker | `ghcr.io/isso-comments/isso:latest` | Containerized deploy |

## Requirements

- Python 3.7+
- SQLite 3.3.8+
- A C compiler (for building Python extensions) — `gcc`, `build-essential`

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| host | "URL(s) of the website(s) that will embed Isso (e.g. https://example.org)" | All |
| db_path | "Path for the SQLite comments database? (e.g. /var/lib/isso/comments.db)" | All |
| moderation | "Enable comment moderation queue? (yes/no)" | All |
| notify_email | "Send email notifications? SMTP server details?" | Optional |

## pip install (recommended)

Upstream: https://isso-comments.de/docs/reference/installation/

### 1. Install dependencies and Isso

    apt install -y python3 python3-pip python3-dev gcc libsqlite3-dev

    pip3 install isso

### 2. Create configuration

    mkdir -p /etc/isso /var/lib/isso

    cat > /etc/isso/isso.cfg << 'CFGEOF'
    [general]
    dbpath = /var/lib/isso/comments.db
    host = https://example.org

    [server]
    listen = http://localhost:8080/

    [moderation]
    enabled = false
    # Set to true to require admin approval before comments appear

    [smtp]
    # Uncomment and configure for email notifications
    # host = smtp.example.org
    # port = 587
    # username = isso@example.org
    # password = secret
    # to = admin@example.org
    # from = isso@example.org
    # security = starttls
    CFGEOF

### 3. Test run

    isso -c /etc/isso/isso.cfg run

### 4. systemd service

    cat > /etc/systemd/system/isso.service << 'SVCEOF'
    [Unit]
    Description=Isso Commenting Server
    After=network.target

    [Service]
    Type=simple
    User=www-data
    ExecStart=/usr/local/bin/isso -c /etc/isso/isso.cfg run
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    chown -R www-data:www-data /var/lib/isso /etc/isso
    systemctl daemon-reload
    systemctl enable --now isso

## Docker install

    docker run -d \
      --name isso \
      --restart always \
      -p 8080:8080 \
      -v /etc/isso:/config \
      -v /var/lib/isso:/db \
      ghcr.io/isso-comments/isso:latest

    # Docker Compose
    services:
      isso:
        image: ghcr.io/isso-comments/isso:latest
        restart: always
        ports:
          - "127.0.0.1:8080:8080"
        volumes:
          - ./config:/config
          - ./db:/db

Config file at `./config/isso.cfg` (same format as above).

## Reverse proxy (Nginx)

    location /isso {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Script-Name /isso;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

## Embed on your website

Add to your HTML where you want comments to appear:

    <!-- Isso embed script -->
    <script data-isso="//comments.example.org/isso/"
            src="//comments.example.org/isso/js/embed.min.js"></script>

    <!-- Comments section -->
    <section id="isso-thread">
        <noscript>Javascript needs to be activated to view comments.</noscript>
    </section>

Replace `comments.example.org/isso/` with your Isso URL.

## Configuration reference

Full options: https://isso-comments.de/docs/reference/server-config/

Key settings:

| Option | Default | Description |
|---|---|---|
| `[general] dbpath` | required | SQLite database file path |
| `[general] host` | required | Website URL(s) allowed to embed Isso |
| `[moderation] enabled` | false | Require admin approval for comments |
| `[moderation] purge-after` | 30d | Auto-delete unactivated comments |
| `[guard] enabled` | true | Rate limit + spam protection |
| `[guard] ratelimit` | 2 | Max new comments per minute per IP |

## Upgrade

    pip3 install --upgrade isso
    systemctl restart isso

## Gotchas

- **`host` must match exactly** — Isso uses the `host` config to validate the `Origin` header. If the URL in the config doesn't match the website URL (including `https://` vs `http://`), comments will fail to load with CORS errors.
- **Reverse proxy X-Script-Name** — When running behind a reverse proxy at a path (e.g., `/isso/`), set `X-Script-Name` header in Nginx so Isso generates correct URLs.
- **`X-Forwarded-For` required** — Without this header, Isso sees all connections as coming from the proxy IP and rate-limiting won't work per-user.
- **SQLite is single-writer** — High-traffic sites may see occasional write contention. SQLite is fine for personal blogs and small sites.
- **Admin interface** — Isso has no admin web UI. Moderate comments via the API or directly in the SQLite database using the `sqlite3` CLI.

## Links

- GitHub: https://github.com/isso-comments/isso
- Website: https://isso-comments.de/
- Docs: https://isso-comments.de/docs/
- Quickstart: https://isso-comments.de/docs/guides/quickstart/
- Server config reference: https://isso-comments.de/docs/reference/server-config/
- Docker: https://isso-comments.de/docs/reference/installation/#using-docker
