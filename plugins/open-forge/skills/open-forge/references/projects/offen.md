---
name: offen
description: Recipe for Offen Fair Web Analytics — a privacy-friendly, opt-in web analytics tool where users can access and delete their own data. Covers Docker single-binary and systemd service methods.
---

# Offen Fair Web Analytics

Privacy-first, open-source web analytics. Opt-in only — visitors must actively consent before any data is collected. Users can view and delete their own data. Operators see aggregate stats. All data is encrypted end-to-end. Upstream: <https://github.com/offen/offen>. Docs: <https://docs.offen.dev/>.

Latest release: v1.4.2. License: Apache-2.0.

Offen is a **single binary** (Go) that serves the admin UI, the JavaScript snippet, and the API. Default port: `3000` (or `443` if using built-in Let's Encrypt).

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended — easiest way to run Offen in production |
| Binary / systemd | For bare-metal or VMs without Docker |
| Heroku | Cloud PaaS — see upstream docs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Domain/subdomain for Offen (e.g. `offen.yourdomain.com`)?" | **Must** be a subdomain of the site being tracked (same-origin policy) |
| tls | "Use built-in Let's Encrypt auto-TLS, or bring your own cert?" | Built-in LE is simplest; reverse proxy if you have an existing cert setup |
| tls | "Email for Let's Encrypt expiration notices?" | Required if using built-in LE |
| smtp | "SMTP host, port, user, password for password-reset emails?" | Optional but recommended |
| db | "Datastore: SQLite (default) or PostgreSQL/MySQL?" | SQLite works well for low-to-medium traffic |
| db | "Database connection string?" | Only if using external DB |

## Docker (recommended)

```bash
mkdir offen && cd offen
```

Create `offen.env`:
```dotenv
OFFEN_SERVER_AUTOTLS=offen.yourdomain.com
OFFEN_SECRETS_COOKIEEXCHANGE=<random-secret-min-16-chars>
# Optional SMTP for password reset
OFFEN_SMTP_HOST=smtp.example.com
OFFEN_SMTP_PORT=587
OFFEN_SMTP_USER=you@example.com
OFFEN_SMTP_PASSWORD=changeme
OFFEN_SMTP_SENDER=offen@example.com
```

`docker-compose.yml`:
```yaml
services:
  offen:
    image: offen/offen:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - offen_data:/var/opt/offen
    env_file: offen.env
    restart: unless-stopped

volumes:
  offen_data:
```

```bash
docker compose up -d

# First run: create the first operator account
docker compose exec offen offen setup \
  -name "Your Name" \
  -email you@example.com \
  -password yourpassword \
  -populate
```

Offen will be available at `https://offen.yourdomain.com`.

## Behind a reverse proxy (nginx/Traefik)

If using a reverse proxy for TLS, **do not** set `OFFEN_SERVER_AUTOTLS`. Instead set the port:

```dotenv
OFFEN_SERVER_PORT=3000
OFFEN_SECRETS_COOKIEEXCHANGE=<random-secret>
```

Expose only the internal port; let your reverse proxy handle TLS termination. Example nginx snippet:

```nginx
server {
    listen 443 ssl;
    server_name offen.yourdomain.com;
    # ssl_certificate / ssl_certificate_key ...

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

> ⚠️ Upstream recommends **not** running Offen behind a reverse proxy for production to avoid unwanted IP logging. If your setup requires it, configure the proxy to suppress access logs.

## Binary / systemd install

```bash
# Download the latest binary
curl -sSL https://github.com/offen/offen/releases/latest/download/offen_linux_amd64.tar.gz | tar xz
sudo mv offen /usr/local/bin/

# Create config dir
sudo mkdir -p /etc/offen /var/opt/offen

# Create config file at /etc/offen/offen.env
sudo tee /etc/offen/offen.env << 'EOF'
OFFEN_SERVER_AUTOTLS=offen.yourdomain.com
OFFEN_SECRETS_COOKIEEXCHANGE=<random-secret>
EOF

# Systemd unit
sudo tee /etc/systemd/system/offen.service << 'EOF'
[Unit]
Description=Offen Fair Web Analytics
After=network.target

[Service]
EnvironmentFile=/etc/offen/offen.env
ExecStart=/usr/local/bin/offen serve
Restart=on-failure
WorkingDirectory=/var/opt/offen

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now offen

# Setup first account
offen setup -name "Your Name" -email you@example.com -password yourpassword -populate
```

## Embedding the tracking script

On each page you want to track, add inside `<head>`:

```html
<script
  async
  src="https://offen.yourdomain.com/script.js"
  data-account-id="YOUR_ACCOUNT_ID">
</script>
```

The account ID is shown in the Offen admin after creating an account.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | Environment variables or `offen.env` file |
| Data dir | `/var/opt/offen/` (SQLite DB + key material) |
| Default port | `3000` (HTTP); `443` (with AutoTLS) |
| Admin URL | `https://offen.yourdomain.com/` |
| Secret generation | `offen secret` command generates a suitable cookie exchange secret |
| Data retention | Usage data auto-deleted after 6 months |
| Databases | SQLite (default), PostgreSQL, MySQL via `OFFEN_DATABASE_DIALECT` + `OFFEN_DATABASE_CONNECTIONSTRING` |

## Upgrade procedure

1. Pull the new Docker image: `docker compose pull && docker compose up -d`
2. Or replace the binary and restart: `systemctl restart offen`
3. Offen applies database migrations automatically on startup.
4. Check the release notes at <https://github.com/offen/offen/releases> for any breaking changes.

## Gotchas

- **Subdomain requirement**: Offen must be served from a subdomain of the tracked site (e.g., `offen.example.com` to track `www.example.com`). Cross-origin deployments only work for users with third-party cookies enabled.
- **Opt-in only**: No data is collected until a user actively clicks "Accept" on the consent banner. Don't expect analytics day one.
- **`OFFEN_SECRETS_COOKIEEXCHANGE` is required**: If not set, Offen will refuse to start. Generate with `offen secret` or use `openssl rand -base64 16`.
- **No reverse proxy preferred**: Upstream actively advises against reverse proxies to avoid IP leakage in access logs. AutoTLS (built-in Let's Encrypt) is the recommended production setup.
- **sendmail fallback unavailable in Docker**: Configure SMTP explicitly; the fallback local `sendmail` is disabled in the Docker image.
- **Low activity since 2024**: The project has been quiet since v1.4.2 (May 2024). It is stable but not under active development.

## Upstream links

- Source: <https://github.com/offen/offen>
- Docs: <https://docs.offen.dev/>
- Installation with Docker: <https://docs.offen.dev/running-offen/installation-via-docker/>
- Configuration reference: <https://docs.offen.dev/running-offen/configuring-the-application/>
