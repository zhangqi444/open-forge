# Part-DB

Part-DB is an open-source web-based inventory management system for electronic components. It supports categorization, storage locations, barcodes, BOM management, KiCad integration, project tracking, multi-currency pricing, and AI-assisted part information retrieval.

**Website:** https://docs.part-db.de/
**Source:** https://github.com/Part-DB/Part-DB-server
**License:** AGPL-3.0
**Stars:** ~1,607

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Docker Compose + MySQL/MariaDB | Recommended |
| Any Linux/VPS | Docker Compose + SQLite | Simple single-container setup |
| Any Linux/VPS | Docker Compose + PostgreSQL | Supported |
| Any Linux/VPS | PHP 8.2+ + nginx/Apache | Manual install |

---

## Inputs to Collect

### Phase 1 — Planning
- Database choice: SQLite (simple) or MySQL/MariaDB/PostgreSQL (recommended for multi-user)
- `BASE_URL`: full URL the app will be accessed at (e.g. `https://parts.example.com`)
- Currency (default: EUR)
- Language (default: en)

### Phase 2 — Deployment
- `DATABASE_URL`: connection string (e.g. `mysql://partdb:pass@db/partdb`)
- `APP_ENV`: `prod`
- `APP_SECRET`: random 32-char secret
- `BASE_URL`: publicly accessible URL
- SMTP settings for email/password reset (optional)

---

## Software-Layer Concerns

### Docker Compose (MySQL backend)
```yaml
services:
  db:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: partdb
      MYSQL_USER: partdb
      MYSQL_PASSWORD: partdbpass
    volumes:
      - db_data:/var/lib/mysql

  part-db:
    image: jbtronics/part-db1:latest
    ports:
      - "8080:80"
    environment:
      - DATABASE_URL=mysql://partdb:partdbpass@db/partdb
      - APP_ENV=prod
      - APP_SECRET=changeme_random_32_char_string
      - BASE_URL=http://localhost:8080
      - DEFAULT_LANG=en
      - DEFAULT_TIMEZONE=UTC
      - CURRENCY=USD
    volumes:
      - uploads:/var/www/html/uploads
      - db_backups:/var/www/html/var/db_backups
    depends_on:
      - db

volumes:
  db_data:
  uploads:
  db_backups:
```

### Docker Compose (SQLite — minimal setup)
```yaml
services:
  part-db:
    image: jbtronics/part-db1:latest
    ports:
      - "8080:80"
    environment:
      - DATABASE_URL=sqlite:///%kernel.project_dir%/var/app.db
      - APP_ENV=prod
      - APP_SECRET=changeme_random_32_char_string
      - BASE_URL=http://localhost:8080
    volumes:
      - part_db_data:/var/www/html/var
      - uploads:/var/www/html/uploads

volumes:
  part_db_data:
  uploads:
```

### First-Time Setup
```bash
# Start containers
docker compose up -d

# Run database migrations (first time only, or after upgrade)
docker compose exec part-db bin/console doctrine:migrations:migrate --no-interaction

# Create admin user
docker compose exec part-db bin/console part-db:create-admin-user
```

Default admin login is created during first start if using the Docker image (check logs for temporary password or set via the above command).

### Data Volumes
| Path | What's stored |
|------|--------------|
| `/var/www/html/uploads` | Part images, datasheets, attached files |
| `/var/www/html/var` | SQLite DB (if using SQLite), cache, logs |
| MySQL/MariaDB volume | All inventory data |

### Key Features to Configure
- **Cloud providers** (Octopart, Digikey, Farnell, LCSC, TME): API keys in admin → System settings
- **KiCad integration**: Configure KiCad library connector URL pointing to your Part-DB instance
- **SSO via SAML**: Requires intermediate IdP like Keycloak
- **AI data extraction**: Optional, configure AI provider API key in settings

---

## Upgrade Procedure

```bash
# Pull new image
docker compose pull

# Stop containers
docker compose down

# Start new containers
docker compose up -d

# Run database migrations
docker compose exec part-db bin/console doctrine:migrations:migrate --no-interaction
```

---

## Gotchas

- **`BASE_URL` must be correct**: Used for generating barcode/QR code URLs, email links, and KiCad integration. Wrong value breaks these features.
- **`APP_SECRET` must be secret and stable**: Changing it invalidates all sessions and 2FA tokens.
- **Database migrations required after upgrade**: Always run `doctrine:migrations:migrate` after pulling a new image.
- **File uploads volume**: Attached datasheets and images are stored outside the database; back up the `uploads/` volume separately.
- **PHP memory**: For large inventories with many parts, increase PHP memory limit (set `PHP_MEMORY_LIMIT` env var or configure `php.ini`).
- **2FA enforcement**: Can be enforced per user group; affects all users in that group — plan before enabling.
- **KiCad plugin**: Requires the Part-DB KiCad plugin installed in KiCad and the correct API URL configured.

---

## Links
- Docs: https://docs.part-db.de/
- Installation Guide: https://docs.part-db.de/installation/
- Docker Hub: https://hub.docker.com/r/jbtronics/part-db1
- GitHub Releases: https://github.com/Part-DB/Part-DB-server/releases
- Demo: https://demo.part-db.de/
