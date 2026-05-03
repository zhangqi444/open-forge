# Akkoma

**What it is:** Microblogging server software with ActivityPub support — a fork of Pleroma with additional features including custom emoji, MRF policies, and Mastodon API compatibility.
**Official URL:** https://akkoma.social
**Repo:** https://akkoma.dev/AkkomaGang/akkoma

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux server | Docker Compose | Official images available |
| Linux server | Bare metal (OTP release) | Production recommended |

## Inputs to Collect

### Deploy phase
- Domain/hostname (permanent — cannot change after setup)
- PostgreSQL credentials
- Admin username/email/password
- SMTP settings (optional but recommended)
- Upload storage path or S3 credentials

## Software-Layer Concerns

- **Config:** config/prod.secret.exs or environment variables
- **Data dir:** PostgreSQL for data; /var/lib/akkoma/uploads for media
- **Key env vars:** DOMAIN, DB_HOST, DB_NAME, DB_USER, DB_PASS

## Upgrade Procedure

1. Pull latest image / OTP release
2. Run migrations: docker exec <container> /app/bin/akkoma_ctl migrate
3. Restart

See: https://docs.akkoma.social/stable/administration/updating/

## Gotchas

- Domain is baked into the database — cannot be changed without data loss
- Federation means your instance interacts with thousands of other servers
- MRF (Message Rewrite Facility) policies control federation behavior
- Mastodon-compatible API; use Mastodon clients (Tusky, Ivory, etc.)

## References

- [Docs](https://docs.akkoma.social)
- [Repo](https://akkoma.dev/AkkomaGang/akkoma)
