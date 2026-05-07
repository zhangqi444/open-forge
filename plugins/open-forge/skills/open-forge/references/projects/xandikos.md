---
name: Xandikos
description: Lightweight CardDAV and CalDAV server backed by a Git repository. Minimal admin overhead, full RFC compliance. GPL-3.0 licensed.
website: https://github.com/jelmer/xandikos
source: https://github.com/jelmer/xandikos
license: GPL-3.0
stars: 559
tags:
  - caldav
  - carddav
  - calendar
  - contacts
  - dav
platforms:
  - Python
  - Docker
---

# Xandikos

Xandikos is a lightweight CalDAV and CardDAV server that stores data in a Git repository. It provides full CalDAV (RFC 4791) and CardDAV (RFC 6352) compliance with minimal administrative overhead. Each user's calendars and contacts are stored as plain files in a Git repo, giving you a built-in change history. Works with DAVx5, Thunderbird, Apple iOS, Evolution, and most other CalDAV/CardDAV clients.

Source: https://github.com/jelmer/xandikos
Docs: https://www.xandikos.org/docs/
Man page: https://www.xandikos.org/manpage.html
Container: ghcr.io/jelmer/xandikos

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Recommended; official image at ghcr.io |
| Any Linux VM / VPS | Python 3.7+ | Native install via pip |

## Inputs to Collect

**Phase: Planning**
- Data directory path (stores Git repos for each user's calendars/contacts)
- Port to expose (default: 8000)
- Current user principal path (default: /user/)
- Whether to auto-create default calendar and addressbook on first run
- Authentication method (Xandikos relies on a reverse proxy for auth)

## Software-Layer Concerns

**Docker (recommended):**

```bash
docker run -d \
  --name xandikos \
  -p 8000:8000 \
  -e AUTOCREATE=true \
  -e DEFAULTS=true \
  -e CURRENT_USER_PRINCIPAL=/user/ \
  -v xandikos_data:/data \
  --restart unless-stopped \
  ghcr.io/jelmer/xandikos:latest
```

**Docker Compose (fetch official example):**

```bash
curl -o docker-compose.yml \
  https://raw.githubusercontent.com/jelmer/xandikos/master/examples/docker-compose.yml
docker compose up -d
```

**Container environment variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Port to listen on | 8000 |
| METRICS_PORT | Prometheus metrics endpoint | 8001 |
| LISTEN_ADDRESS | Bind address | 0.0.0.0 |
| DATA_DIR | Data directory | /data |
| CURRENT_USER_PRINCIPAL | Principal path | /user/ |
| AUTOCREATE | Auto-create directories | (false) |
| DEFAULTS | Create default calendar/addressbook | (false) |
| NO_STRICT | Enable client compatibility workarounds | (false) |
| EAGER | Pre-populate indexes at startup | (false) |

**Native install:**

```bash
# Debian/Ubuntu dependencies
sudo apt install python3-dulwich python3-defusedxml python3-icalendar python3-jinja2

# Or via pip
pip install xandikos

# Run standalone (no auth, for testing)
xandikos --defaults -d ~/dav
# Server at http://localhost:8080
```

**Authentication — reverse proxy required:**

Xandikos does not handle authentication itself. Use Nginx with HTTP Basic Auth or OAuth proxy in front:

```nginx
server {
    listen 443 ssl;
    server_name dav.example.com;

    location / {
        auth_basic "DAV";
        auth_basic_user_file /etc/nginx/.htpasswd;

        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

**Calendar/contact URLs (after --defaults):**

```
CalDAV:  http://dav.example.com/user/calendars/calendar
CardDAV: http://dav.example.com/user/contacts/addressbook
```

Some clients (DAVx5, iOS) support auto-discovery (RFC 5397) — just provide the base URL.

**Data storage:**
- Each principal's calendars and contacts are stored as Git repositories under DATA_DIR
- Back up the data directory; each change is a Git commit with full history

## Upgrade Procedure

1. `docker pull ghcr.io/jelmer/xandikos:latest`
2. `docker stop xandikos && docker rm xandikos`
3. Re-run `docker run` with the same volume mounts
4. Check releases: https://github.com/jelmer/xandikos/releases

## Gotchas

- **No built-in authentication**: Must be placed behind a reverse proxy that handles auth — never expose the raw port publicly
- **Multi-user is experimental**: Single-user deployments are stable; multi-user support is flagged as experimental in the docs
- **Git-backed storage**: All data is in Git repos — this is a feature (history, easy backup) but also means the data directory grows over time with commit history; run `git gc` periodically
- **Client URLs**: Clients without auto-discovery need the full path to the calendar or addressbook collection
- **NO_STRICT mode**: Enable if you experience issues with Apple Calendar or other strict clients — adds compatibility workarounds
- **iMIP scheduling**: CalDAV scheduling works between users on the same server; outbound email scheduling requires additional `--imip-send` configuration

## Links

- Upstream README: https://github.com/jelmer/xandikos/blob/master/README.rst
- Documentation: https://www.xandikos.org/docs/
- Man page: https://www.xandikos.org/manpage.html
- Container packages: https://github.com/jelmer/xandikos/pkgs/container/xandikos
- Example configs: https://github.com/jelmer/xandikos/tree/master/examples
