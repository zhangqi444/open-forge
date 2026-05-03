# Tamari

> Fully-featured self-hosted recipe manager — store, search, and share recipes; import from 107,000+ public recipes; shopping lists with barcode scanning; weekly meal planner; REST API; PWA for mobile. Built with Python/Flask, SQLite storage.

**Official URL:** https://github.com/alexbates/Tamari  
**Docs:** https://tamariapp.com/docs  
**Demo:** https://app.tamariapp.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; SQLite; recommended |
| Debian/Ubuntu | Python/Gunicorn | Manual install with virtualenv |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `PORT` | Host port to expose | `4888` |

### Phase: Optional (Email/Password Reset)
| Input | Description | Example |
|-------|-------------|---------|
| `MAIL_SERVER` | SMTP hostname | `mail.example.com` |
| `MAIL_PORT` | SMTP port | `587` |
| `MAIL_USE_TLS` | Enable TLS (`1`/`0`) | `1` |
| `MAIL_USERNAME` | SMTP username/email | `you@example.com` |
| `MAIL_PASSWORD` | SMTP password | secret |

---

## Software-Layer Concerns

### Quick Start (Docker)
```bash
docker run -d \
  --restart=always \
  -p 4888:4888 \
  -v tamariappdata:/app/appdata \
  --name tamari \
  alexbates/tamari:1.5
```
Or pull `ghcr.io/alexbates/tamari:latest` / `alexbates/tamari:latest`.

### With Email (Password Reset)
```bash
docker run -d \
  -e MAIL_SERVER=mail.example.com \
  -e MAIL_PORT=587 \
  -e MAIL_USE_TLS=1 \
  -e MAIL_USERNAME=you@example.com \
  -e MAIL_PASSWORD=yourpassword \
  --restart=always \
  -p 4888:4888 \
  -v tamariappdata:/app/appdata \
  --name tamari \
  alexbates/tamari:1.5
```

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/appdata` (named volume `tamariappdata`) | SQLite database + uploaded photos — **back this up** |

### Ports
- Default: `4888` — proxy with Nginx/Caddy for TLS

### Manual Install (Debian/Ubuntu)
```bash
sudo apt install python3 python3-venv git libpango-1.0-0 libcairo2 libgdk-pixbuf2.0-0 libffi-dev libpangocairo-1.0-0
git clone https://github.com/alexbates/Tamari && cd Tamari
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
flask db init && flask db migrate -m "Initial" && flask db upgrade
export FLASK_APP=tamari.py
gunicorn -b 0.0.0.0:4888 -w 4 app:app
```

---

## Upgrade Procedure

1. Pull the new image: `docker pull alexbates/tamari:1.5` (replace with latest tag)
2. Stop: `docker stop tamari && docker rm tamari`
3. Run with the same volume and new image tag
4. Database migrations run automatically on startup
5. Backup details: https://tamariapp.com/docs/backups/

---

## Gotchas

- **Back up `/app/appdata`** — contains both the SQLite database and all uploaded recipe photos; losing this volume means losing all your recipes
- **Email is optional** — without SMTP settings, users cannot reset forgotten passwords; only admins can recover accounts
- **Barcode scanning** — requires camera access; works in browser on mobile; HTTPS is needed for camera API in production
- **Public recipe library** — 107,000+ recipes are available to browse and import; this data is bundled/fetched from tamariapp.com, not local
- **First run** — creates an initial admin user on first startup; visit http://localhost:4888 to complete setup

---

## Links
- GitHub: https://github.com/alexbates/Tamari
- Docs: https://tamariapp.com/docs
- Backup guide: https://tamariapp.com/docs/backups/
- Docker Hub: https://hub.docker.com/r/alexbates/tamari
