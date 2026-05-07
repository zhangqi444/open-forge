---
name: mataroa
description: Mataroa recipe for open-forge. Minimalist "naked" blogging platform for writers. Subdomain-per-blog, custom domains, newsletter via email, export to Markdown/Hugo/Zola/Jekyll. Django + PostgreSQL. Source: https://github.com/mataroablog/mataroa
---

# Mataroa

Minimalist "naked" blogging platform. Each user gets a `username.mataroa.blog` subdomain. Supports custom domains, post-by-email, newsletter distribution, RSS, and full Markdown export (Hugo/Zola/Jekyll-compatible). Django + PostgreSQL. MIT licensed.

Upstream: <https://github.com/mataroablog/mataroa>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose (dev) | Django + PostgreSQL; requires subdomain DNS for blog subdomains |
| Linux | Python (manual) | Django + gunicorn + PostgreSQL + nginx |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Domain name (e.g. mataroa.example.com) | Each blog gets a subdomain: user.example.com |
| config | SECRET_KEY | Random Django secret key |
| config | DATABASE_URL | PostgreSQL DSN: postgres://user:pass@host:5432/mataroa |
| config | ADMIN_EMAIL | Receives server error notifications |
| config (optional) | EMAIL_HOST_USER / EMAIL_HOST_PASSWORD | SMTP for newsletter/post-by-email |
| config (optional) | STRIPE_API_KEY / STRIPE_PUBLIC_KEY / STRIPE_PRICE_ID | For optional paid plans |
| infra | Wildcard DNS | `*.yourdomain.com → server IP` required for per-user subdomains |
| infra | Custom domain IP (CUSTOM_DOMAIN_IP) | Your server's public IP for custom domain DNS validation |

## Software-layer concerns

### Env vars (`.envrc`)

| Var | Description |
|---|---|
| SECRET_KEY | Django session/CSRF secret |
| DATABASE_URL | PostgreSQL connection string |
| ADMIN_EMAIL | Email for error reports |
| EMAIL_HOST_USER | SMTP username |
| EMAIL_HOST_PASSWORD | SMTP password |
| CUSTOM_DOMAIN_IP | Server IP for custom domain feature |
| STRIPE_API_KEY / STRIPE_PUBLIC_KEY / STRIPE_PRICE_ID | Optional paid plans |
| DEBUG | 1=show tracebacks, 0=hide (production: 0) |
| LOCALDEV | 1=disable real email + HTTPS, 0=production mode |

### Key data

- Database: PostgreSQL (all user/post/subscription data)
- No media upload storage by default (text-only blog platform)

## Install — Docker Compose (dev/evaluation)

```bash
git clone https://github.com/mataroablog/mataroa.git
cd mataroa

# Add subdomains to /etc/hosts (local dev)
echo "127.0.0.1 mataroalocal.blog" | sudo tee -a /etc/hosts

# Override env vars if needed
cat > docker-compose.override.yml << 'EOF'
services:
  web:
    environment:
      SECRET_KEY: "your-random-secret"
      DEBUG: "1"
      LOCALDEV: "1"
EOF

docker compose up
# Access: http://mataroalocal.blog:8000
```

## Install — Manual (production)

```bash
# 1. PostgreSQL + Python 3.12+
sudo apt install postgresql python3 python3-pip uv nginx

# 2. Create DB
sudo -u postgres createuser mataroa
sudo -u postgres createdb -O mataroa mataroa

# 3. Clone and configure
git clone https://github.com/mataroablog/mataroa.git
cd mataroa
cp .envrc.example .envrc
# Edit .envrc: set SECRET_KEY, DATABASE_URL, ADMIN_EMAIL, set DEBUG=0 LOCALDEV=0
source .envrc

# 4. Install deps + migrate
uv venv && source .venv/bin/activate
uv pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic

# 5. Create superuser
python manage.py createsuperuser

# 6. Run with gunicorn (behind nginx)
gunicorn mataroa.wsgi:application --bind 127.0.0.1:8000
```

Nginx config needs wildcard subdomain support (`server_name *.yourdomain.com`).

## Upgrade procedure

```bash
git pull
source .envrc
uv pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic
# Restart gunicorn/docker
```

## Gotchas

- Wildcard DNS is required — `*.yourdomain.com` must point to your server. Without this, per-user subdomains won't work. Configure at your DNS provider.
- Set `LOCALDEV=0` and `DEBUG=0` in production — `LOCALDEV=1` disables real email and HTTPS enforcement (dev convenience only).
- Custom domains: users can point their own domain to Mataroa. `CUSTOM_DOMAIN_IP` must be set to your server's public IP so Mataroa can validate custom domain DNS.
- Email (SMTP) is needed for post-by-email and newsletter features — configure `EMAIL_HOST_USER`/`EMAIL_HOST_PASSWORD`.
- HTTPS is expected in production — use Certbot + nginx with a wildcard certificate (`*.yourdomain.com`).

## Links

- Source: https://github.com/mataroablog/mataroa
- Mirror: https://git.sr.ht/~sirodoht/mataroa
- Community mailing list: https://lists.sr.ht/~sirodoht/mataroa-community
