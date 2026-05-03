# Private Captcha

> Privacy-first, self-hostable Proof-of-Work CAPTCHA service made in the EU. Drop-in alternative to Google reCAPTCHA, hCaptcha, and Cloudflare Turnstile — no behavior tracking, no PII processing, GDPR-compliant. Features adaptive challenge difficulty, lightweight customizable widget (including invisible mode), and a usage statistics portal.

**Official URL:** https://github.com/PrivateCaptcha/PrivateCaptcha  
**Self-hosting repo:** https://github.com/PrivateCaptcha/self-hosting  
**Docs:** https://docs.privatecaptcha.com

> ⚠️ **License:** PolyForm Noncommercial License — free for non-commercial use (Community Edition). Commercial use requires a paid Enterprise license (contact hello@privatecaptcha.com).

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Official method via self-hosting repo |
| Any Linux VPS/VM | Docker Compose (EE) | Enterprise edition — swap image + set `EE_LICENSE_KEY` |

**Stack:** Go backend + JavaScript widget + PostgreSQL (business data) + ClickHouse (operational data/stats)

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `PC_PORTAL_BASE_URL` | Public URL for the admin portal | `https://portal.yourdomain.com` |
| `PC_API_BASE_URL` | Public URL for the CAPTCHA API | `https://api.yourdomain.com` |
| `PC_CDN_BASE_URL` | Public URL for the widget CDN | `https://cdn.yourdomain.com` |
| Admin email | Initial admin account email | `admin@example.com` |
| Postgres credentials | DB user/password/db name | see `.env.example` |
| ClickHouse credentials | CH user/password | see `.env.example` |

### Phase: Community Edition (CE)
| Input | Description |
|-------|-------------|
| `CE_LICENSE_KEY` | Community edition license key (obtain from privatecaptcha.com) |

### Phase: Enterprise Edition (optional)
| Input | Description |
|-------|-------------|
| `EE_LICENSE_KEY` | Enterprise license key |

---

## Software-Layer Concerns

### Config & Environment
- All configuration via `.env` file (copy from `.env.example` in self-hosting repo)
- CE and EE license keys injected via `compose.override.yml`
- Portal, API, and CDN each need separate public subdomains (or paths) with TLS

### Services in the Stack
| Service | Purpose |
|---------|---------|
| `privatecaptcha` | Main app (API + Portal) |
| `migration` | One-shot DB migration container |
| `postgres` | Business data (accounts, properties, etc.) |
| `clickhouse` | Operational data (difficulty scaling, statistics) |

### Quick Start
```bash
git clone https://github.com/PrivateCaptcha/self-hosting.git private-captcha
cd private-captcha
cp .env.example .env
$EDITOR .env          # fill in domain, credentials, etc.
docker compose up -d
```

### CE License Override (`compose.override.yml`)
```yaml
services:
  privatecaptcha:
    environment:
      - CE_LICENSE_KEY=${CE_LICENSE_KEY}
```

### Local-Only Setup (no public domain)
Add to `/etc/hosts`:
```
127.0.0.1  portal.privatecaptcha.local
127.0.0.1  api.privatecaptcha.local
127.0.0.1  cdn.privatecaptcha.local
```
Use `privatecaptcha.local:8080` as base URL. Note: `.local` email addresses are not valid RFC-5322 — retrieve 2FA codes from Docker logs.

---

## Upgrade Procedure

See official docs: https://docs.privatecaptcha.com/docs/deployment/updating/

General steps:
1. `git pull` in the self-hosting repo to get latest `docker-compose.yml`
2. `docker compose pull` to fetch new images
3. `docker compose up -d` — migration container runs automatically

---

## Gotchas

- **Three public subdomains required** (portal, API, CDN) — each needs TLS; use a wildcard cert or configure individually
- **ClickHouse is resource-hungry** — requires more RAM than a typical single-service app; plan for 2–4 GB RAM minimum
- **2FA is required for admin login** — on local `.local` setups, retrieve the TOTP code from container logs
- **CE license key required** even for free/non-commercial use — register at privatecaptcha.com to obtain it
- **PostgreSQL + ClickHouse both required** — cannot drop either; ClickHouse handles statistics/difficulty scaling, Postgres handles accounts
- **Widget integration** requires adding the CDN script tag and replacing existing CAPTCHA form fields — see integration docs
- **Not a drop-and-forget swap** for reCAPTCHA — your application's server-side verification endpoint must be updated to call the Private Captcha API

---

## Links
- GitHub (main): https://github.com/PrivateCaptcha/PrivateCaptcha
- GitHub (self-hosting): https://github.com/PrivateCaptcha/self-hosting
- Documentation: https://docs.privatecaptcha.com
- Quickstart: https://docs.privatecaptcha.com/docs/deployment/quickstart/
- Configuration reference: https://docs.privatecaptcha.com/docs/deployment/configuration/
