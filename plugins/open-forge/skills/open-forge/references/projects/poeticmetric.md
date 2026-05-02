---
name: poeticmetric
description: Recipe for PoeticMetric — privacy-first, GDPR/CCPA/PECR/KVKK-compliant open-source website analytics. No cookies, no personal data. Self-hosting via Docker Compose per official docs.
---

# PoeticMetric

Privacy-first, regulation-compliant open-source website analytics. Upstream: https://github.com/th0th/poeticmetric

No cookies, no personal data collected — fully compliant with GDPR, CCPA, PECR, and KVKK. No cookie consent banner required. AGPL-3.0 licensed. Managed cloud alternative available at poeticmetric.com.

## Compatible combos

| Method | Notes |
|---|---|
| Docker Compose (self-hosted) | Officially documented method — see upstream self-hosting guide |
| poeticmetric.com (managed) | Fully managed cloud service — no install needed |

## Inputs to collect

Exact inputs depend on the current upstream self-hosting guide. Collect after reviewing:
https://poeticmetric.com/docs/open-source/self-hosting

Typically includes:
| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain / public URL | Where your PoeticMetric instance will be accessible |
| preflight | Admin email + password | Initial admin account credentials |
| smtp (opt) | SMTP settings | For account notifications and password reset |

## Software-layer concerns

**Architecture:** Multi-service stack (typically includes API, frontend, worker, and one or more databases). Exact services defined in the upstream docker-compose — follow the official guide.

**Data persistence:** Database volumes must be preserved across upgrades. Follow upstream backup guidance before upgrading.

**Tracker snippet:** After deploy, add the PoeticMetric JS snippet to your website(s). The snippet is available from within your PoeticMetric dashboard.

**No cookies:** PoeticMetric does not set cookies or collect personal data (IPs are not stored). No consent banner needed under GDPR/CCPA.

## Docker Compose

The upstream README delegates compose details to the official self-hosting docs.

**Do not use a fabricated compose file.** Follow the current upstream guide at:
https://poeticmetric.com/docs/open-source/self-hosting

The guide is maintained by the author and reflects the current architecture.

## Upgrade procedure

Follow the upgrade instructions in the upstream self-hosting documentation. Typically:

```bash
docker compose pull
docker compose up -d
```

Check release notes for database migration steps before upgrading.

## Gotchas

- **Self-hosting guide is at poeticmetric.com/docs, not in the README** — the README intentionally points there; always follow the live upstream guide.
- **AGPL-3.0 license** — if you modify PoeticMetric and offer it as a network service, you must release your modifications.
- **Multi-service stack** — not a single container; resource requirements are higher than single-binary apps.

## Links

- Upstream repository: https://github.com/th0th/poeticmetric
- Official self-hosting guide: https://poeticmetric.com/docs/open-source/self-hosting
- Managed cloud: https://poeticmetric.com
- Live demo: https://poeticmetric.com/s?d=poeticmetric.com
