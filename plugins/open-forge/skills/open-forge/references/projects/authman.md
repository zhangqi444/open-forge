# Authman

**What it is:** Self-hosted TOTP/2FA authenticator app with backup and sync — a self-hosted alternative to Google Authenticator.
**Official URL:** https://github.com/simular/authman-app
**GitHub:** https://github.com/simular/authman-server (server) / https://github.com/simular/authman-app (client)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Server component |

## Inputs to Collect

### Deploy phase
- Domain/hostname for server
- Port (see upstream for default)
- Admin credentials

## Software-Layer Concerns

- **Config:** Environment variables (see upstream)
- **Data dir:** Persistent volume for TOTP secrets
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart. Back up data volume first.

## Gotchas

- Requires companion mobile app (authman-app) for full functionality
- Keep backups of TOTP secrets — losing them locks you out of accounts

## References

- [Server GitHub](https://github.com/simular/authman-server)
- [App GitHub](https://github.com/simular/authman-app)
