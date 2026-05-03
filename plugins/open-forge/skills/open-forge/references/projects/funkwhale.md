# Funkwhale

**What it is:** Self-hosted, federated music streaming platform — publish and share your music library across the Fediverse via ActivityPub.
**Official URL:** https://funkwhale.audio
**Repo:** https://dev.funkwhale.audio/funkwhale/funkwhale

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended for most deployments |
| Any Linux | Bare metal | Official docs available |

## Inputs to Collect

### Deploy phase
- Domain/hostname (permanent — baked into ActivityPub IDs)
- PostgreSQL credentials
- Redis URL
- DJANGO_SECRET_KEY
- S3-compatible storage (optional; local storage default)
- SMTP settings

## Software-Layer Concerns

- **Config:** .env file at project root
- **Data dir:** media/ for uploads; /srv/funkwhale (bare metal)
- **Key env vars:** FUNKWHALE_HOSTNAME, DATABASE_URL, CACHE_URL, DJANGO_SECRET_KEY

## Upgrade Procedure

1. Pull latest images
2. Run migrations: docker compose run --rm api python manage.py migrate
3. Collect static files: docker compose run --rm api python manage.py collectstatic
4. Restart

See: https://docs.funkwhale.audio/administrator/upgrade/docker.html

## Gotchas

- Domain is permanent; changing it breaks federation
- Requires PostgreSQL + Redis (no SQLite)
- ActivityPub federation allows sharing music with Mastodon/Pleroma users
- S3 storage recommended for production (local storage can grow large)

## References

- [Docs](https://docs.funkwhale.audio)
- [Docker Setup](https://docs.funkwhale.audio/administrator/installation/docker.html)
