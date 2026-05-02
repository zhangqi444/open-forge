---
name: spacepad
description: Spacepad recipe for open-forge. Self-hosted room display system syncing with Google Calendar, Microsoft 365, and CalDAV. Based on upstream docs at https://github.com/magweter/spacepad.
---

# Spacepad

Self-hosted room availability display system for tablets and overview boards. Syncs in real-time with Google Calendar, Microsoft 365 (Outlook), or CalDAV (Nextcloud, iCloud, etc.). Supports on-device room booking, check-in, full-day schedules, custom themes/logos, and multi-workspace team management. Built with Laravel (PHP). Upstream: <https://github.com/magweter/spacepad>. Website: <https://spacepad.io>.

> **Licensing:** Free for personal/hobbyist self-hosting (unlimited displays). Business use with multiple displays requires a paid self-hosted license. See <https://spacepad.io/pricing>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host with public domain + HTTPS | Docker Compose (app + scheduler) | Standard self-hosted deploy — requires HTTPS for Microsoft 365 integration |
| Any Docker host (LAN / home) | Docker Compose | Works for Google/CalDAV without public domain; Microsoft 365 requires HTTPS |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Public domain for Spacepad?" | Required for TLS and OAuth callbacks; e.g. `spacepad.example.com` |
| tls | "Email for Let's Encrypt (ACME_EMAIL)?" | Used by Traefik/Caddy for cert issuance |
| app | "Generate APP_KEY?" | Run `openssl rand -base64 32` and set `APP_KEY=base64:<result>` in `.env` |
| auth | "Which login method: Email (magic link) / Microsoft OAuth / Google OAuth?" | At least one must be configured |
| smtp | "SMTP host/port/user/pass?" | Required for email magic-link login |
| smtp | "From email address (MAIL_FROM_ADDRESS)?" | e.g. `hello@spacepad.example.com` |
| oauth-microsoft | "Azure AD client ID (AZURE_AD_CLIENT_ID)?" | From Azure Portal app registration |
| oauth-microsoft | "Azure AD client secret (AZURE_AD_CLIENT_SECRET)?" | From Azure Portal certificates & secrets |
| oauth-google | "Google OAuth client ID (GOOGLE_CLIENT_ID)?" | From Google Cloud Console |
| oauth-google | "Google OAuth client secret (GOOGLE_CLIENT_SECRET)?" | From Google Cloud Console |

## Software-layer concerns

**Config file:** `.env` (copy from `.env.example`, edit `DOMAIN`, `ACME_EMAIL`, `APP_KEY`, mail and OAuth vars).

**Key env vars:**

| Variable | Purpose |
|---|---|
| `APP_KEY` | Laravel app key — `base64:<32-byte-random>` |
| `DOMAIN` | Public domain name |
| `ACME_EMAIL` | Let's Encrypt contact email |
| `MAIL_MAILER` / `MAIL_HOST` / `MAIL_PORT` / `MAIL_USERNAME` / `MAIL_PASSWORD` | SMTP for magic-link login |
| `MAIL_FROM_ADDRESS` | From address for outgoing emails |
| `AZURE_AD_CLIENT_ID` / `AZURE_AD_CLIENT_SECRET` | Microsoft OAuth credentials |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth credentials |

**Services in compose:**
- `app` — Main Laravel app (`ghcr.io/magweter/spacepad:latest`, port `8080`)
- `scheduler` — Laravel cron scheduler (same image, runs `php artisan schedule:work`)

**Data volumes:**
- `storage_data` → `/var/www/html/storage` — app storage (uploads, cache, logs)

**Ports:** `8080` (HTTP; expose via reverse proxy for HTTPS).

**OAuth redirect URIs to register:**
- Microsoft: `https://<domain>/outlook-accounts/callback` and `https://<domain>/auth/microsoft/callback`
- Google: `https://<domain>/google-accounts/callback` and `https://<domain>/auth/google/callback`

## Upgrade procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose down && docker compose up -d`
3. Laravel migrations run automatically on start (`AUTORUN_LARAVEL_MIGRATION: 'true'`).
4. Check logs: `docker compose logs app`

## Gotchas

- Microsoft 365 calendar integration **requires HTTPS and a publicly accessible domain** — HTTP or LAN-only deployments won't work with Microsoft OAuth.
- `APP_KEY` must be generated once and stored — changing it invalidates all sessions and encrypted data.
- The scheduler service must run alongside the app container — without it, real-time calendar syncs and webhooks will not process.
- CalDAV support works with Nextcloud, iCloud, and any standards-compliant CalDAV server.
- Multi-tenant Azure AD (not single-tenant) is required for Microsoft integration.
- Business users with >1 display must purchase a self-hosted license; the app enforces this.

## Links

- GitHub: <https://github.com/magweter/spacepad>
- Setup guide: <https://github.com/magweter/spacepad/blob/main/docs/SETUP.md>
- Website / pricing: <https://spacepad.io/pricing>
- Azure App Registrations: <https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade>
- Google Cloud Console: <https://console.cloud.google.com/>
