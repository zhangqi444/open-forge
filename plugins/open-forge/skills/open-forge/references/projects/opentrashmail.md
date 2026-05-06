---
name: opentrashmail
description: Recipe for OpenTrashmail — a self-hosted disposable email service with SMTP server, web UI, JSON API, RSS feeds, and webhook support. No database required.
---

# OpenTrashmail

Self-hosted disposable/throwaway email service. Runs a Python SMTP server that accepts mail for any address on your domain(s), plus a PHP web UI for reading emails. Supports JSON API, RSS feeds per address, webhooks, and optional password protection. Fully file-based — no database needed. Upstream: <https://github.com/HaschekSolutions/opentrashmail>.

License: Apache-2.0. Platform: Python 3.11, PHP 8.1+, Docker. Stars: ~860.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended — everything bundled |
| Manual | PHP + Python on existing server |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Public URL for the web UI (e.g. `https://trashmail.example.com`)?" | Set as `URL` env var — no trailing slash |
| domains | "Domain(s) that will receive mail (comma-separated)?" | e.g. `trash.example.com,junk.example.com` — DNS MX record must point to this server |
| ports | "Host port for SMTP (default 25)? Web UI port (default 8080)?" | Port 25 may require root or `CAP_NET_BIND_SERVICE` |
| access | "Global password to protect the web UI?" | Optional — `PASSWORD` env var |
| admin | "Admin email address (catch-all view)?" | Any valid address format; not a real mailbox |

## Docker Compose (recommended)

```bash
mkdir opentrashmail && cd opentrashmail
```

`docker-compose.yml`:
```yaml
services:
  opentrashmail:
    image: hascheksolutions/opentrashmail:1
    volumes:
      - ./data:/var/www/opentrashmail/data
      - ./logs:/var/www/opentrashmail/logs
    environment:
      URL: "https://trashmail.example.com"
      DOMAINS: "trash.example.com,junk.example.com"
      DATEFORMAT: "D.M.YYYY HH:mm"
      ADMIN_ENABLED: "true"
      ADMIN: "admin@trash.example.com"  # Can view all received emails
      SKIP_FILEPERMISSIONS: "true"
      DISCARD_UNKNOWN: "false"           # Set true to discard mail not matching DOMAINS
      # PASSWORD: "secretpassword"       # Uncomment to require password for web access
      # ALLOWED_IPS: "192.168.0.0/16"   # Restrict web UI by IP
      # ATTACHMENTS_MAX_SIZE: "10000000" # Max attachment size in bytes (10MB)
      # WEBHOOK_URL: "https://example.com/hook" # Global webhook for all received mail
    ports:
      - "25:25"     # SMTP
      - "8080:80"   # Web UI
    restart: unless-stopped
```

```bash
mkdir -p data logs
docker compose up -d
```

Web UI at `http://your-host:8080`. Enter any email address at the domain to read its inbox.

## DNS setup

For OpenTrashmail to receive email, add an MX record for your mail domain pointing to your server:

```
trash.example.com.   MX   10   your-server-ip-or-hostname.
```

Also ensure port 25 (TCP) is open inbound on your firewall/security group.

> ⚠️ Port 25 is blocked by most cloud providers (AWS, GCP, Azure, Hetzner) by default. You may need to request unblocking or use an alternative port and configure `MAILPORT` env var (e.g. 2525) with external port forwarding.

## TLS-encrypted SMTP

For STARTTLS / TLS-on-connect support:

```yaml
environment:
  MAILPORT_TLS: "465"           # Port for TLS-on-connect
  TLS_CERTIFICATE: "/certs/cert.pem"
  TLS_PRIVATE_KEY: "/certs/key.pem"
volumes:
  - ./certs:/certs:ro
```

## API reference

| Endpoint | Description |
|---|---|
| `GET /json/<email>` | List all received emails for an address |
| `GET /json/<email>/<id>` | Get full email (HTML + raw body, attachments as base64) |
| `GET /rss/<email>` | RSS feed for an email address |
| `GET /json/listaccounts` | List all addresses (requires `SHOW_ACCOUNT_LIST=true`) |
| `GET /api/delete/<email>/<id>` | Delete a specific email |
| `GET /api/deleteaccount/<email>` | Delete all emails for an address |
| `GET /api/webhook/get/<email>` | Get webhook config for address |
| `POST /api/webhook/save/<email>` | Set webhook for address |

API authentication (if `PASSWORD` is set): pass via POST/GET `?password=` or HTTP header `PWD`.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Storage | `./data/` — all emails stored as files; no database |
| Logs | `./logs/` |
| SMTP port | `25` (default); set `MAILPORT` env var to change |
| Web UI port | `80` (internal); map to host port `8080` |
| Admin view | Set `ADMIN` to any address to see all received mail |
| File-based | No database dependency; backup by copying `data/` directory |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Email data in `./data/` is preserved across upgrades.

## Gotchas

- **Port 25 is often blocked**: Most cloud providers block inbound port 25. Use `MAILPORT` to configure an alternative SMTP port (e.g. 2525) and update your docker port mapping accordingly. Check your VPS/cloud provider's documentation.
- **MX record required**: Without an MX record pointing to your server, no external mail will be delivered. OpenTrashmail cannot receive email without proper DNS setup.
- **`URL` env var — no trailing slash**: Unlike PictShare, OpenTrashmail's `URL` should NOT have a trailing slash: `https://trashmail.example.com` not `https://trashmail.example.com/`.
- **`ADMIN` address is a view, not a real mailbox**: The admin address doesn't need to exist — it's just used to trigger an all-accounts view in the web UI and API.
- **`DISCARD_UNKNOWN=false` (default)**: OpenTrashmail will store mail for any address by default, not just domains in `DOMAINS`. Set to `true` to discard off-domain mail.
- **Storage grows unbounded**: There is no automatic cleanup. Implement a cron job to prune old mail from `./data/` if running long-term.
- **Low maintenance since 2025**: Project has minimal commits. It is functional but should be treated as stable/maintenance-mode software.

## Upstream links

- Source: <https://github.com/HaschekSolutions/opentrashmail>
- Docker Hub: <https://hub.docker.com/r/hascheksolutions/opentrashmail>
