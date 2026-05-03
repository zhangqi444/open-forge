# Socialhome

**What it is:** Federated personal profile with social networking — ActivityPub-compatible blogging and social platform with rich content streams.
**Official URL:** https://socialhome.network
**Repo:** https://gitlab.com/jaywink/socialhome

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Bare metal (Python/Django) | See upstream docs |

## Inputs to Collect

### Deploy phase
- Domain/hostname (permanent)
- PostgreSQL credentials
- Redis URL
- SECRET_KEY
- SMTP settings
- Admin email

## Software-Layer Concerns

- **Config:** Environment variables (.env file)
- **Data dir:** media/ for uploads; PostgreSQL
- **Key env vars:** SOCIALHOME_DOMAIN, DATABASE_URL, REDIS_URL, SECRET_KEY

## Upgrade Procedure

Pull latest image, run migrations: docker compose exec django python manage.py migrate

## Gotchas

- Domain is permanent after setup
- Federated via ActivityPub and Diaspora protocol
- User registration can be restricted/invite-only

## References

- [Docs](https://socialhome.readthedocs.io)
- [GitLab](https://gitlab.com/jaywink/socialhome)
