---
name: chiyogami
description: Chiyogami recipe for open-forge. Sleek, modern self-hosted pastebin with encryption, customizable expiry, private pastes, user accounts, and an API.
---

# Chiyogami

Sleek, modern self-hosted pastebin with client-side encryption, configurable expiry, private/unlisted pastes, user accounts, and a REST API. Upstream: <https://github.com/rhee876527/chiyogami>.

Built in Go with SQLite. Runs as a single container on port `8000`. Supports TailwindCSS + DaisyUI frontend with syntax highlighting (HighlightJS) and Markdown rendering.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | `docker-compose.yml` in repo | ✅ | Recommended — drops privileges, volume for pastes |
| Docker run | `ghcr.io/rhee876527/chiyogami:latest` | ✅ | Quick start |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | `SECRET_KEY` | Free-text (sensitive) | Session key — generate with `openssl rand -base64 32` |
| optional | `PASTE_DEFAULT_EXPIRATION` | Duration string | Default `24h`; valid units: ns, us, ms, s, m, h, or `Never` |
| optional | `MAX_CHAR_CONTENT` | Number | Default `50000` |
| optional | `DISABLE_RATE_LIMIT` | `1` or omit | Set `1` to disable rate limiting |
| optional | `CREATE_PER_MIN` | Number | Requests per minute for create/auth endpoints; default `10` |
| optional | `DELETE_RETENTION` | Number (1–99) | Days to keep soft-deleted pastes; default `90` |
| optional | `COMPLEX_PASSWORD` | `1` or omit | Enforces strong passwords on registration |
| optional | `ADMIN_CONTACT` | Email | Shown for moderation purposes |

## Software-layer concerns

Single-container, SQLite-backed. The `/pastes` volume holds the database and uploaded content. The `/health` endpoint should be protected from public access.

```yaml
services:
  chiyogami:
    container_name: chiyogami
    image: ghcr.io/rhee876527/chiyogami:latest
    cap_drop:
      - ALL
    cap_add:
      - SETGID
      - SETUID
      - CHOWN
    security_opt:
      - no-new-privileges
    environment:
      - SECRET_KEY=your_random_string_here
      # - GID=1000
      # - UID=1000
      # - PASTE_DEFAULT_EXPIRATION=24h
    volumes:
      - ./pastes:/pastes
    ports:
      - 127.0.0.1:8000:8000/tcp
    restart: unless-stopped
```

### Protecting the /health endpoint with Traefik

```yaml
labels:
  - "traefik.http.routers.chiyogami.middlewares=localonly-health"
  - "traefik.http.middlewares.localonly-health.replacepathregex.regex=^/health$"
  - "traefik.http.middlewares.localonly-health.replacepathregex.replacement=/nonexistent-path"
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

SQLite database lives in the mounted volume and persists across upgrades.

## Gotchas

- `SECRET_KEY` is required; the app will not start without it.
- The `/health` endpoint can be abused if exposed publicly — restrict it at the reverse proxy level.
- Client-side encryption in the web UI means the server never sees the decryption key; share the full URL (including fragment) with the recipient.
- `PASTE_DEFAULT_EXPIRATION=Never` creates pastes that never expire — storage will grow unbounded without manual cleanup.
- Rate limiting is enabled by default; disable only in trusted environments.
