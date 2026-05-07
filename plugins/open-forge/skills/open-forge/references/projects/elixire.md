---
name: elixire
description: Elixire recipe for open-forge. Advanced image host and link shortener with user accounts, virus scanning, and admin panel. Python + PostgreSQL + Redis. Source: https://gitlab.com/elixire/elixire
---

# Elixire

An open-source image host and link shortening service. Supports user accounts, upload history, an admin panel (via elixiremanager), optional ClamAV virus scanning, InfluxDB metrics, and Mailgun email. AGPL-3.0 licensed, written in Python. Upstream: <https://gitlab.com/elixire/elixire>. Admin panel: <https://gitlab.com/elixire/elixiremanager>

> ⚠️ **Note**: The upstream repo explicitly states "Do not attempt to run" the included Dockerfiles, and MRs fixing them will be closed. Use the native Python install method below.

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Python 3.9+ + PostgreSQL + Redis | Only upstream-supported method |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Elixire?" | FQDN | e.g. img.example.com — must be www→non-www or vice versa (consistent) |
| "PostgreSQL connection details?" | host/user/pass/db | For the upload database |
| "Redis connection URL?" | URL | e.g. redis://localhost:6379/0 |
| "Port to run on?" | Number | Default 8081; put behind NGINX |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Enable ClamAV virus scanning?" | Yes / No | Optional; requires ClamAV installed |
| "Mailgun config for email?" | domain + API key | Optional; enables user verification emails |
| "Discord webhook for admin alerts?" | URL | Optional; notifies admins on malicious upload detection |
| "Enable user registration?" | Yes / No | Configurable in config.py |

## Software-Layer Concerns

- **No Docker support**: Upstream explicitly discourages Docker. Native Python install with hypercorn ASGI server.
- **Submodules**: Frontend and admin-panel are git submodules — must run `git submodule init && git submodule update` before build.
- **Frontend build**: Requires Node.js to build the frontend and admin panel (`make`).
- **Domain consistency**: Instance must redirect www↔non-www consistently — mismatches break the domain-checking logic.
- **Reverse proxy required**: Run behind NGINX with `proxy_set_header Host $host;` — Host header forwarding is essential.
- **Config file**: `config.py` (copied from `config.py.example`) — controls registration, webhooks, storage paths, etc.
- **Schema**: `schema.sql` must be imported into PostgreSQL before first run; edit the `INSERT INTO domains` line first.

## Deployment

### Native Python

```bash
git clone https://gitlab.com/elixire/elixire.git
cd elixire
git submodule init && git submodule update

pip3 install -Ur requirements.txt

# Edit schema.sql: update the "INSERT INTO domains" line with your domain
psql -U postgres -f schema.sql

cp config.py.example config.py
# Edit config.py: DB credentials, Redis URL, domain, storage path, optional features

# Edit frontend/config.json and admin-panel/config.json — set your domain

make update  # updates frontend/admin-panel submodules
make         # builds frontend and admin-panel

# Run with hypercorn
hypercorn run.py --access-log - --bind 0.0.0.0:8081
```

### NGINX config

```nginx
server {
    listen 443 ssl;
    server_name img.example.com;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;  # required
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### systemd service

```ini
[Unit]
Description=Elixire image host
After=network.target

[Service]
User=elixire
WorkingDirectory=/opt/elixire
ExecStart=hypercorn run.py --bind 0.0.0.0:8081
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Upgrade Procedure

1. `git pull` in the elixire directory.
2. `git submodule update` to update frontend/admin-panel.
3. `pip3 install -Ur requirements.txt` to update dependencies.
4. `make` to rebuild frontend.
5. Restart the hypercorn service.
6. Check for any schema migration notes in the repo.

## Gotchas

- **No Docker**: Upstream explicitly refuses Docker support — don't try to Dockerize it.
- **Host header required in proxy**: Missing `proxy_set_header Host $host` will cause domain validation failures.
- **www/non-www redirect**: Must be consistent — pick one and redirect the other, or uploads become inaccessible.
- **schema.sql domains insert**: Must be edited before importing — the example has a placeholder domain that won't match your instance.
- **Node.js needed for build**: Required to build the frontend (`make`), even though the backend is Python.
- **elixiremanager**: The admin panel is a separate submodule at https://gitlab.com/elixire/elixiremanager

## Links

- Source: https://gitlab.com/elixire/elixire
- Admin panel: https://gitlab.com/elixire/elixiremanager
