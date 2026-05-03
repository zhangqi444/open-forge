# Cannery

**What it is:** Self-hosted ammunition inventory tracking app for shooters.
**Official URL:** https://cannery.app
**GitHub:** N/A (Codeberg: https://codeberg.org/shibao/cannery)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- Port (default: 4000)
- PostgreSQL database credentials
- SECRET_KEY_BASE (generate with: mix phx.gen.secret)
- EMAIL_FROM and SMTP settings
- REGISTRATION_ENABLED (true/false)

## Software-Layer Concerns

- **Config:** Environment variables in docker-compose.yml
- **Data dir:** PostgreSQL volume
- **Key env vars:** DATABASE_URL, SECRET_KEY_BASE, EMAIL_FROM, SMTP_HOST

## Upgrade Procedure

1. Pull latest image
2. Run database migrations: docker exec <container> bin/cannery eval "Cannery.Release.migrate"
3. Restart

## Gotchas

- Built with Elixir/Phoenix; requires PostgreSQL (no SQLite)
- Email required for user registration/invites
- Set REGISTRATION_ENABLED=false after creating admin account

## References

- [Codeberg Repo](https://codeberg.org/shibao/cannery)
