---
name: Erugo
description: "Self-hosted file sharing platform. Docker. PHP/Laravel + Vue.js + SQLite. ErugoOSS/Erugo. Upload files/folders, set expiry + download limits, password protection, reverse share tokens (guest uploads), OIDC/OAuth2, email notifications. MIT."
---

# Erugo

**Self-hosted file sharing platform.** Upload files and folders; share via expiring links with optional download limits and password protection. Reverse share tokens let guests upload files to you without an account. OIDC/OAuth2 SSO, email notifications, storage management. Clean Vue.js UI.

Built + maintained by **deanward / ErugoOSS**. MIT license.

- Upstream repo: <https://github.com/ErugoOSS/Erugo>
- Demo: <https://demo.erugo.app/shares/tight-silence-sweet-sea>
- Docker Hub: <https://hub.docker.com/r/wardy784/erugo>
- Discord: <https://discord.gg/M74X2wmqY8>

## Architecture in one minute

- **PHP / Laravel** backend
- **Vue.js** frontend (Inertia.js)
- **SQLite** (default, zero-config) database
- Port **9998** → container **80**
- Files stored in `./erugo-storage` volume (`/var/www/html/storage`)
- Optional **S3-compatible** storage backend
- Resource: **low** — PHP + SQLite; runs on a Raspberry Pi

## Compatible install methods

| Infra      | Runtime             | Notes                                              |
| ---------- | ------------------- | -------------------------------------------------- |
| **Docker** | `wardy784/erugo`    | **Primary** — Docker Hub; official image           |

## Install

```yaml
services:
  app:
    image: wardy784/erugo:latest
    restart: unless-stopped
    volumes:
      - ./erugo-storage:/var/www/html/storage
    ports:
      - "9998:80"
    environment:
      - APP_URL=https://share.example.com    # set your public URL
      # - MAIL_MAILER=smtp                   # uncomment for email
      # - MAIL_HOST=smtp.example.com
```

```bash
docker compose up -d
```

Visit `http://localhost:9998`.

## First boot

1. Set `APP_URL` to your public domain before starting (important for share links).
2. `docker compose up -d`.
3. Visit `http://localhost:9998`.
4. **Register the first account** → becomes admin.
5. Log in → go to the dashboard.
6. Upload files: drag-and-drop to create a share.
7. Configure expiry, download limits, and password if needed.
8. Copy the share link and send it to the recipient.
9. Create a **reverse share token** (Settings → Reverse Shares) to let guests upload to you.
10. Configure OIDC/OAuth2 in admin settings if desired.
11. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| File sharing | Upload single files or entire folders |
| Share expiry | Set TTL: 1 hour to never |
| Download limits | Max N downloads per share |
| Password protection | Optional password per share |
| Reverse share tokens | Let guests upload to you without an account |
| Share management | View all your shares, revoke anytime |
| Progress tracking | Upload progress display with multi-file support |
| OIDC/OAuth2 SSO | Log in with Google, GitHub, Authentik, Keycloak, etc. |
| Email notifications | Notify uploader when someone downloads; notify admin of reverse shares |
| S3 storage | Optional S3-compatible backend for file storage |
| Admin dashboard | User management, storage quotas, site settings |
| Storage management | Per-user quotas; admin storage overview |
| Theming | Customizable UI colors |
| Multi-language | Interface translations (check repo for supported languages) |

## Reverse share tokens

A standout feature: **reverse share tokens** let you invite guests to upload files to you.

1. Admin or user creates a reverse share token (one-time or multi-use)
2. Share the token URL with the guest
3. Guest opens the URL and uploads files — no account required
4. File appears in your account's dashboard
5. Optional email notification when the upload completes

Useful for: receiving files from clients, collecting assets from collaborators, receiving sensitive files securely.

## Gotchas

- **`APP_URL` must be set correctly.** Share links embed the `APP_URL`. If set to `localhost`, links sent to others won't work. Set it to your public domain before first run.
- **First account = admin.** Register first — that account has admin privileges. If you want to prevent open registration after setup, disable registration in admin settings.
- **SQLite is fine for personal use.** SQLite handles thousands of shares well. For high-traffic multi-user deployments, consider migrating to MySQL/PostgreSQL (check the repo for migration instructions).
- **Storage volume is critical.** All uploaded files live in `./erugo-storage`. This volume must be persistent and backed up. Losing it loses all shared files.
- **Email requires SMTP config.** Upload/download notifications require SMTP credentials in the environment. Without SMTP, emails silently fail.
- **S3 backend.** For large files or distributed deployments, configure an S3-compatible backend (AWS S3, MinIO, Backblaze B2). See the admin settings for S3 configuration options.
- **Reverse shares are powerful.** A reverse share token URL lets anyone upload to your account. Don't share widely or with untrusted parties; use one-time tokens when possible.

## Backup

```sh
docker compose stop app
sudo tar czf erugo-$(date +%F).tgz erugo-storage/
docker compose start app
```

## Upgrade

```sh
docker compose pull && docker compose up -d
# Laravel migrations run automatically on startup
```

## Project health

Active PHP/Laravel + Vue.js development, Docker Hub, OIDC/OAuth2, reverse share tokens, S3 backend, Discord community. Solo-maintained by deanward. MIT license.

## File-sharing-family comparison

- **Erugo** — PHP+Laravel+Vue, reverse share (guest upload), OIDC, email notifications, S3 backend, MIT
- **Pingvin Share** — TypeScript, similar scope, active; different tech stack
- **FileShelter** — C++, minimal, no auth
- **Hemmelig** — Node.js/Fastify, E2E encrypted secrets; different focus
- **Sharry** — Scala/JVM, tus resumable uploads, alias pages; similar reverse-share concept

**Choose Erugo if:** you want a self-hosted file sharing platform with reverse share tokens (guest uploads), OIDC SSO, email notifications, and S3 storage — in a clean, Raspberry-Pi-friendly PHP package.

## Links

- Repo: <https://github.com/ErugoOSS/Erugo>
- Demo: <https://demo.erugo.app>
- Docker Hub: <https://hub.docker.com/r/wardy784/erugo>
- Discord: <https://discord.gg/M74X2wmqY8>
