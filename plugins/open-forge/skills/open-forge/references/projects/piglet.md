# Piglet 🐷

> Simple household budget manager — track expenses by category, share budgets with family members, generate monthly reports, and keep financial data private on your own server. Docker Compose deployment with MariaDB.

**Official URL:** https://github.com/k3nd0x/piglet

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; includes MariaDB |
| Any Linux VPS/VM | Docker (manual) | Separate MariaDB container |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | MariaDB root password | strong password |
| `MYSQL_DATABASE` | Database name | `piglet` |
| `MYSQL_USER` | Database username | `piglet` |
| `MYSQL_PASSWORD` | Database user password | strong password |
| `MYSQL_HOST` | Database hostname | `database` |
| `DOMAIN` | Instance domain (used for default admin email) | `localhost` or `piglet.example.com` |
| `SECURE_COOKIE` | Set to `True` for HTTPS deployments | `False` (HTTP) / `True` (HTTPS) |

### Phase: Optional (Email)
| Input | Description | Example |
|-------|-------------|---------|
| `MAIL_SERVER` | SMTP hostname | `smtp.example.com` |
| `MAIL_USER` | SMTP username | `noreply@example.com` |
| `MAIL_PASSWORD` | SMTP password | secret |
| `MAIL_PORT` | SMTP port | `587` |
| `MAIL_ENCRYPTIONPROTOCOL` | `TLS` or `STARTTLS` | `STARTTLS` |

---

## Software-Layer Concerns

### Docker Compose
```yaml
version: '3.3'
services:
  piglet:
    image: k3nd0x/piglet:latest
    restart: unless-stopped
    depends_on:
      - database
    ports:
      - "80:80"    # Web UI
      - "8080:8080" # API
    environment:
      DB_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_HOST: ${MYSQL_HOST}
      DOMAIN: ${DOMAIN}
      SECURE_COOKIE: ${SECURE_COOKIE}
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro

  database:
    image: mariadb:11.1.2
    restart: unless-stopped
    volumes:
      - database-data:/var/lib/mysql
    environment:
      MARIADB_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MARIADB_DATABASE: ${MYSQL_DATABASE}
      MARIADB_USER: ${MYSQL_USER}
      MARIADB_PASSWORD: ${MYSQL_PASSWORD}

volumes:
  database-data:
```

### Default Login
- Username: `admin@<DOMAIN>` (e.g. `admin@localhost`)
- Password: `admin` — **change immediately after first login**

### Data Directories
| Path | Purpose |
|------|---------|
| `database-data` volume | MariaDB data — back this up |

### Ports
- Web UI: `80`
- API: `8080`

---

## Upgrade Procedure

1. Pull latest: `docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. Database migrations run automatically on first start of new version

---

## Gotchas

- **SECURE_COOKIE must be `True` for HTTPS** — by default `SECURE_COOKIE=False` to allow HTTP login; if you put Piglet behind a reverse proxy with HTTPS, set `SECURE_COOKIE=True` or your login session cookie won't be set correctly
- **Default admin email includes domain** — the default admin username is `admin@<DOMAIN>`, not just `admin`; if `DOMAIN=localhost`, the login is `admin@localhost`
- **Change default password immediately** — default password is `admin`; no enforcement at first run
- **Early-stage project** — started as a learning project; may have rough edges; SQLite support is on the roadmap (currently MariaDB only)
- **Budget sharing** — multiple household members can share budgets; each needs their own account

---

## Links
- GitHub: https://github.com/k3nd0x/piglet
