# Pleroma

**What it is:** Federated microblogging server with ActivityPub support — lightweight Mastodon-compatible server software for running your own instance.
**Official URL:** https://pleroma.social
**Repo:** https://git.pleroma.social/pleroma/pleroma

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Community images available |
| Any Linux | OTP release (bare metal) | Recommended by upstream |

## Inputs to Collect

### Deploy phase
- Domain/hostname (permanent — cannot change)
- PostgreSQL credentials
- Admin username/email/password
- SMTP settings (for notifications)
- Upload storage path or S3 credentials

## Software-Layer Concerns

- **Config:** config/prod.secret.exs or env vars
- **Data dir:** PostgreSQL; uploads/ for media
- **Key env vars:** PLEROMA_DB_*, PLEROMA_UPLOAD_PATH

## Upgrade Procedure

OTP: ./bin/pleroma_ctl update && ./bin/pleroma_ctl migrate
Docker: pull latest image, run migrations

See: https://docs-develop.pleroma.social/backend/administration/updating/

## Gotchas

- Domain is baked into the database — permanent
- Mastodon API compatible; use Mastodon clients
- Lighter resource footprint than Mastodon
- MRF (Message Rewrite Facility) for federation control

## References

- [Docs](https://docs-develop.pleroma.social)
- [Repo](https://git.pleroma.social/pleroma/pleroma)
