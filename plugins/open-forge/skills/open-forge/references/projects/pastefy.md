---
name: pastefy-project
description: Pastefy recipe for open-forge. Open-source Pastebin/Gist alternative. Code sharing with syntax highlighting, multi-file pastes, folders, rich previews (Markdown/Mermaid/SVG/CSV/GeoJSON/Asciinema), optional OAuth2 login (InteraApps/Google/GitHub/Discord/Twitch/custom OIDC), public API, VS Code extension. Java backend + MariaDB/MySQL. Upstream: https://github.com/interaapps/pastefy
---

# Pastefy

An open-source Pastebin and GitHub Gist alternative. Share code snippets with syntax highlighting, create multi-file pastes, organize with folders, and render rich previews for Markdown, Mermaid diagrams, SVG, CSV, GeoJSON, diffs, ICS calendars, regex, and Asciinema recordings. Optional login via OAuth2 (InteraApps, Google, GitHub, Discord, Twitch, or custom OIDC). Public API with JS/Java/Go client libraries.

Upstream: <https://github.com/interaapps/pastefy> | Docs: <https://docs.pastefy.app> | Public instance: <https://pastefy.app>

Two containers: Java backend + MariaDB.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Two containers (app + MariaDB 10.11) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `9999` |
| config | "Public server URL?" | `SERVER_NAME`; e.g. `https://paste.example.com` — used in share links |
| config | "Database password?" | `MYSQL_PASSWORD` / `DATABASE_PASSWORD` — set a strong password |
| config | "Enable OAuth2 login?" | Optional; choose provider(s): InteraApps, Google, GitHub, Discord, Twitch, or custom OIDC |
| config (OAuth2) | "OAuth2 client ID + secret?" | Per-provider; see Configuration section |

## Software-layer concerns

### Image

```
interaapps/pastefy:latest
```

Docker Hub: <https://hub.docker.com/r/interaapps/pastefy>

### Compose

```yaml
version: '3.3'

services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    volumes:
      - dbvol:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: pastefy
      MYSQL_USER: pastefy
      MYSQL_PASSWORD: changeme      # use a strong password

  pastefy:
    depends_on:
      - db
    image: interaapps/pastefy:latest
    restart: unless-stopped
    ports:
      - "9999:80"
    environment:
      HTTP_SERVER_PORT: 80
      HTTP_SERVER_CORS: "*"
      DATABASE_DRIVER: mysql
      DATABASE_NAME: pastefy
      DATABASE_USER: pastefy
      DATABASE_PASSWORD: changeme   # match MYSQL_PASSWORD above
      DATABASE_HOST: db
      DATABASE_PORT: 3306
      SERVER_NAME: "http://localhost:9999"   # set to your public URL
      # OAuth2 (all optional — omit to disable login):
      # OAUTH2_GITHUB_CLIENT_ID: your_id
      # OAUTH2_GITHUB_CLIENT_SECRET: your_secret
      # OAUTH2_GOOGLE_CLIENT_ID: your_id
      # OAUTH2_GOOGLE_CLIENT_SECRET: your_secret
      # OAUTH2_DISCORD_CLIENT_ID: your_id
      # OAUTH2_DISCORD_CLIENT_SECRET: your_secret
      # OAUTH2_TWITCH_CLIENT_ID: your_id
      # OAUTH2_TWITCH_CLIENT_SECRET: your_secret
      # OAUTH2_INTERAAPPS_CLIENT_ID: your_id
      # OAUTH2_INTERAAPPS_CLIENT_SECRET: your_secret
      # Custom OIDC:
      # OAUTH2_CUSTOM_CLIENT_ID: your_id
      # OAUTH2_CUSTOM_CLIENT_SECRET: your_secret
      # OAUTH2_CUSTOM_AUTH_ENDPOINT: https://auth.example.com/auth/oauth2
      # OAUTH2_CUSTOM_TOKEN_ENDPOINT: https://auth.example.com/oauth2/token
      # OAUTH2_CUSTOM_USERINFO_ENDPOINT: https://auth.example.com/oauth2/userinfo

volumes:
  dbvol:
```

> Source: upstream docker-compose.yml — <https://github.com/interaapps/pastefy>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `HTTP_SERVER_PORT` | `80` | Internal port the app listens on |
| `HTTP_SERVER_CORS` | `*` | CORS allowed origins |
| `DATABASE_DRIVER` | — | `mysql` (MariaDB/MySQL) |
| `DATABASE_HOST` | — | DB container name (e.g. `db`) |
| `DATABASE_NAME` | — | Database name |
| `DATABASE_USER` | — | Database user |
| `DATABASE_PASSWORD` | — | Database password |
| `SERVER_NAME` | — | Public URL — used in share links and OAuth2 callbacks |
| `OAUTH2_<PROVIDER>_CLIENT_ID` | — | OAuth2 client ID for chosen provider |
| `OAUTH2_<PROVIDER>_CLIENT_SECRET` | — | OAuth2 client secret for chosen provider |

Providers: `GITHUB`, `GOOGLE`, `DISCORD`, `TWITCH`, `INTERAAPPS`, `CUSTOM`

### Rich preview file types

| Extension | Renders as |
|---|---|
| `.md` | Markdown |
| `.mermaid`, `.mmd` | Mermaid diagram |
| `.svg` | SVG image |
| `.csv` | Table |
| `.geojson` | Map |
| `.diff` | Diff view |
| `.ics` | Calendar |
| `.regex` | Regex visualizer |
| `.cast` | Asciinema recording |

### API

Create a paste via curl:
```bash
curl -F f=@file.txt paste.example.com
```

Full API docs: <https://docs.pastefy.app/api/>

Client libraries: JavaScript/TypeScript, Java, Go — see <https://docs.pastefy.app/api/>

### VS Code extension

Install "Pastefy" from the VS Code marketplace to create and open pastes from the editor.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database persists in the `dbvol` named volume.

## Gotchas

- **`SERVER_NAME` must match your public URL** — OAuth2 redirect URIs and share link generation use this value. Set it to your real domain (including `https://` if behind TLS reverse proxy) before first run.
- **OAuth2 callback URL to register** — when setting up OAuth2 apps (GitHub, Google, etc.), the callback URL is `{SERVER_NAME}/auth/{provider}/callback`, e.g. `https://paste.example.com/auth/github/callback`.
- **No login = anonymous only** — without OAuth2 configured, pastes are anonymous and cannot be deleted or organized into folders. Users can still create and view pastes.
- **MariaDB 10.11 specifically** — the upstream compose pins to `mariadb:10.11`. Newer major versions may have compatibility issues.
- **No built-in HTTPS** — front with Caddy or nginx for TLS. Update `SERVER_NAME` to use `https://`.
- **Multiple OAuth2 providers** — you can enable all providers simultaneously; each needs its own client ID + secret.

## Links

- Upstream README: <https://github.com/interaapps/pastefy>
- Documentation: <https://docs.pastefy.app>
- Self-hosting guide: <https://docs.pastefy.app/self-hosting/index.html>
- Configuration reference: <https://docs.pastefy.app/self-hosting/configuration.html>
- API docs: <https://docs.pastefy.app/api/>
- Public instance: <https://pastefy.app>
