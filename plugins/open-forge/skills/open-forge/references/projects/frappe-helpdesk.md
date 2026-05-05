---
name: frappe-helpdesk
description: Frappe Helpdesk recipe for open-forge. Open-source ticket management and customer support platform built on the Frappe framework. Covers production deployment via the easy-install.py script (Docker-based, recommended) and development setup via Docker Compose. Based on upstream docs at https://docs.frappe.io/helpdesk and the GitHub README.
---

# Frappe Helpdesk

Open-source ticket management and customer support platform built on the Frappe framework. Upstream: <https://github.com/frappe/helpdesk>. Docs: <https://docs.frappe.io/helpdesk>.

**License:** AGPL-3.0

## Key features

- **Agent and customer portals** — separate views for support agents and end-users
- **Customizable SLAs** — set and track service level agreements per ticket type
- **Assignment rules** — auto-assign tickets by priority, type, or agent workload
- **Knowledge base** — articles to empower users and reduce ticket volume
- **Saved replies** — pre-written responses for common queries
- **Email integration** — receive and reply to tickets via email
- **Automation** — triggers and actions to automate ticket workflows

## Compatible deploy methods

| Method | Upstream doc | When to use |
|---|---|---|
| `easy-install.py` script (production) | README Production Setup | Recommended for self-hosted production. Docker-based, handles TLS/nginx/setup in ~5 min. |
| Docker Compose (development) | README Development Setup | Local development and testing |
| Frappe bench (local) | README Development Setup | Contributing to Helpdesk / custom Frappe development |
| Frappe Cloud (managed) | <https://frappecloud.com/helpdesk/signup> | Managed hosting — no self-host required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain name for Helpdesk | E.g. `helpdesk.example.com` |
| preflight | Admin email address | Used for Let's Encrypt TLS + notifications |
| preflight | Version to deploy | `stable` or a specific tag |

## Production deployment (easy-install.py)

Upstream reference: <https://github.com/frappe/helpdesk#readme>

**Requirements:** Linux server with Docker and Python 3.

```bash
# Step 1: Download the install script
wget https://frappe.io/easy-install.py

# Step 2: Run the deployment
python3 ./easy-install.py deploy \
    --project=helpdesk_prod \
    --email=your@email.com \
    --image=ghcr.io/frappe/helpdesk \
    --version=stable \
    --app=helpdesk \
    --sitename=helpdesk.example.com
```

Replace:
- `your@email.com` — your email (used for Let's Encrypt TLS certificate)
- `helpdesk.example.com` — your domain (DNS A record must point to the server)

The script provisions a Docker Compose stack with nginx, MariaDB, Redis, and the Frappe application. Setup typically completes in about 5 minutes.

After deployment, open `https://helpdesk.example.com/helpdesk` in your browser.

**Default admin credentials:**
- Username: `Administrator`
- Password: set during the install wizard (you will be prompted)

## Development setup (Docker Compose)

Upstream reference: <https://github.com/frappe/helpdesk#readme>

```bash
mkdir frappe-helpdesk && cd frappe-helpdesk

# Download the Compose file and init script
wget -O docker-compose.yml \
  https://raw.githubusercontent.com/frappe/helpdesk/develop/docker/docker-compose.yml
wget -O init.sh \
  https://raw.githubusercontent.com/frappe/helpdesk/develop/docker/init.sh

# Start
docker compose up -d
```

Development instance available at: <http://helpdesk.localhost:8000/helpdesk>

Default dev credentials:
- Username: `Administrator`
- Password: `admin`

## Frappe framework compatibility

| Helpdesk branch | Compatible Frappe version |
|---|---|
| `main` | version-15, version-16 |
| `develop` | develop branch |

## Ports

| Port | Purpose |
|---|---|
| 80/443 | nginx reverse proxy (production) |
| 8000 | Gunicorn web server (development) |
| 9000 | Websocket server |

## Upgrade (easy-install.py)

```bash
python3 ./easy-install.py update \
    --project=helpdesk_prod
```

Or pull new images and restart:

```bash
cd /path/to/helpdesk_prod
docker compose pull && docker compose up -d
```

## Gotchas

- **DNS must be configured before running easy-install.py** — the script provisions a TLS certificate from Let's Encrypt, which requires the domain to resolve to the server's public IP.
- **Port 80/443 must be free** — the nginx container binds to these ports. Stop any other web servers on the host before deploying.
- **Frappe framework dependency** — Helpdesk is a Frappe app, not a standalone service. The easy-install script handles the full Frappe stack automatically, but be aware the architecture differs from simpler single-container apps.
- **Bench for local dev** — if you want to develop or customize Helpdesk, use the Frappe bench method (see README) rather than Docker. Docker dev mode is for testing only.
- **Email configuration** — to receive tickets by email, configure an incoming email account in Helpdesk Settings → Email Accounts. SMTP outbound is configured in Frappe's system settings.
- **Multi-app installs** — if you already run another Frappe app (e.g. ERPNext) on the same bench/server, you can add Helpdesk as an app: `bench get-app https://github.com/frappe/helpdesk && bench --site <site> install-app helpdesk`.
