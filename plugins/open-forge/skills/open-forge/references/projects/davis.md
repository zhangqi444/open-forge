# Davis

**Modern, self-hosted CalDAV/CardDAV/WebDAV server with web admin UI — built on sabre/dav + Symfony 7. Supports calendar sharing, scheduling, public calendars, birthday calendars, IMAP/LDAP auth, and more.**
GitHub: https://github.com/tchapi/davis

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose (standalone) | Includes Caddy reverse proxy — easiest path |
| Any Linux | Docker Compose (barebone) | No bundled proxy; bring your own |
| Any Linux | Bare metal (PHP 8.2+) | Composer + MySQL/MariaDB/PostgreSQL/SQLite |
| NixOS | Nix package/module | Available in nixpkgs unstable |

---

## Inputs to Collect

### Required
- `APP_SECRET` — random secret for Symfony (generate with `openssl rand -hex 32`)
- `DATABASE_URL` — MySQL/MariaDB recommended: `mysql://user:pass@host:3306/dbname?serverVersion=10.9.3-MariaDB&charset=utf8mb4`
- `ADMIN_LOGIN` + `ADMIN_PASSWORD` — credentials for the web admin dashboard
- `AUTH_REALM` — realm string shown in HTTP auth prompts (e.g. `SabreDAV`)

### Optional
- IMAP or LDAP env vars — for alternative authentication methods
- `ADMIN_AUTH_BYPASS=true` — bypass admin auth when using an upstream proxy like Authelia

---

## Software-Layer Concerns

### Docker images
- **Standalone** (recommended): `ghcr.io/tchapi/davis-standalone` — includes Caddy reverse proxy
- **Barebone**: `ghcr.io/tchapi/davis` — PHP-FPM only; add your own nginx/Caddy

Sample `docker-compose` configuration provided in the repo.

### First run — run database migrations
```bash
docker exec -it davis sh -c "APP_ENV=prod bin/console doctrine:migrations:migrate --no-interaction"
```

### Key features
- CalDAV, CardDAV, WebDAV
- Calendar sharing and scheduling
- Public calendars (shareable via link)
- Automatic birthday calendar (updates when contacts change)
- Basic auth, IMAP auth, LDAP auth
- Light/dark mode web UI, mobile-responsive

### Database support
- MySQL / MariaDB (recommended)
- PostgreSQL (not extensively tested)
- SQLite (not extensively tested)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d
3. Run migrations: `docker exec -it davis sh -c "APP_ENV=prod bin/console doctrine:migrations:migrate --no-interaction"`

---

## Gotchas

- **Always run migrations after upgrading** — skipping this will break the app
- `ADMIN_AUTH_BYPASS=true` must be the literal string `true` (not a boolean) — only use when an upstream proxy handles auth
- PHP `imap` and `ldap` extensions are pre-compiled in the Docker image but not in bare metal PHP by default

---

## References
- GitHub: https://github.com/tchapi/davis#readme
