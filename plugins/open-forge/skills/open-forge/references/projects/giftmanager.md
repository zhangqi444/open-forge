---
name: giftmanager
description: Recipe for GiftManager — self-hosted gift ideas manager for families. Track wish lists, mark bought gifts, Secret Santa, OIDC auth, email notifications, dark mode. Self-hosting via upstream installation guide.
---

# GiftManager

Self-hosted gift ideas manager for families and groups. Upstream: https://github.com/icbestCA/giftmanager

Manage wish lists and gift ideas for yourself and others, track what's been bought to avoid duplicates, keep surprises secret between users, run Secret Santa draws, and send email notifications. Features OIDC authentication, admin dashboard, user management, dark mode, and multi-family support.

Demo: https://giftmanagerdemo.pages.dev/
Installation docs: https://gift.icbest.ca/getting-started/installation

## Compatible combos

| Method | Notes |
|---|---|
| Docker / Docker Compose | Primary self-hosting method — see upstream installation guide |
| gift.icbest.ca (docs) | Official installation guide |

## Inputs to collect

Exact inputs depend on the current upstream installation guide at:
https://gift.icbest.ca/getting-started/installation

Typically:
| Phase | Prompt | Notes |
|---|---|---|
| preflight | App URL / domain | Where GiftManager will be accessible |
| preflight | Database config | Connection details for the backend DB |
| auth | OIDC provider settings | Issuer URL, client ID, client secret (if using OIDC) |
| smtp | SMTP settings | For email notifications (gift alerts, Secret Santa invites) |
| admin | Initial admin credentials | Set up the admin account on first launch |

## Software-layer concerns

**Config:** See upstream installation guide — config format and required env vars are documented there.

**Auth:** Supports OIDC for single sign-on. Can also use built-in user management via admin dashboard.

**Secret feature:** GiftManager is designed to keep gift selections secret — users cannot see who has reserved gifts for them. This is enforced at the application level.

**Multi-family:** Supports managing separate family/group spaces independently.

**Email notifications:** SMTP required for gift bought notifications and Secret Santa invitations.

**No compose example in README:** The README links to the installation guide; follow that for the current Docker/compose setup.

## Docker Compose

Follow the upstream installation guide:
https://gift.icbest.ca/getting-started/installation

Do not use a fabricated compose file — the upstream guide provides the authoritative setup.

## Upgrade procedure

Follow the upgrade instructions in the upstream installation documentation.

Typical pattern:
```bash
docker compose pull
docker compose up -d
```

Back up the database before upgrading.

## Gotchas

- **Installation guide is external** — the README points to https://gift.icbest.ca for setup instructions; always follow the live upstream guide rather than guessing config.
- **OIDC required for SSO** — if your organization uses SSO, configure OIDC before inviting users; switching auth methods after onboarding may complicate account migration.
- **Secret Santa timing** — coordinate Secret Santa draws before participants start browsing wish lists to avoid accidental reveals.

## Links

- Upstream repository: https://github.com/icbestCA/giftmanager
- Installation guide: https://gift.icbest.ca/getting-started/installation
- Demo: https://giftmanagerdemo.pages.dev/
