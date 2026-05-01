---
name: Slink
description: "Self-hosted image sharing platform. Docker. Symfony + SvelteKit. andrii-kryvoviaz/slink. Private/password-protected/expiring shares, collections, SSO/OIDC, ShareX integration, S3/local/SMB storage."
---

# Slink

**Self-hosted image sharing platform** — take control of your media sharing without third-party services. Private-by-default shares, password protection, expiring links, collections, public explore, nested tags, ShareX integration, OIDC/SSO, admin moderation, and API keys. Storage backends: local disk, SMB, or S3-compatible.

Built + maintained by **Andrii Kryvoviaz**. Live demo at [demo.slinkapp.io](https://demo.slinkapp.io). AGPL-3.0.

- Upstream repo: <https://github.com/andrii-kryvoviaz/slink>
- Docs: <https://docs.slinkapp.io>
- Demo: <https://demo.slinkapp.io>
- Docker Hub: <https://hub.docker.com/r/anirdev/slink>

## Architecture in one minute

- **Symfony** (PHP) backend API
- **SvelteKit** frontend (built to static assets served by the backend or a proxy)
- Docker Compose stack
- Storage: **local disk** (default), **SMB**, or **S3-compatible**
- Authentication: email/password + **SSO/OIDC** (Google, Authentik, Keycloak, Authelia, Pocket ID, custom)
- Resource: **low-to-medium** — PHP-FPM + SvelteKit

## Compatible install methods

| Infra             | Runtime                         | Notes                                                       |
| ----------------- | ------------------------------- | ----------------------------------------------------------- |
| **Docker Compose**| `anirdev/slink`                 | **Primary** — see [Quick Start docs](https://docs.slinkapp.io/getting-started/02-quick-start/) |

## Inputs to collect

| Input                           | Example                           | Phase    | Notes                                                                                  |
| ------------------------------- | --------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| Domain                          | `images.example.com`              | URL      | Reverse proxy + TLS; set `APP_URL` env                                                |
| `APP_SECRET`                    | random 32-char string             | Auth     | Symfony app secret; required; set before first run                                    |
| Admin user                      | created on registration           | Auth     | First registered user becomes admin; optionally disable public registration after     |
| OIDC provider (optional)        | Google / Authentik / Keycloak     | Auth     | Client ID + Secret + issuer URL; see env vars                                         |
| Storage provider                | `local` / `smb` / `s3`           | Storage  | Set via env vars; `local` is default                                                  |
| S3 creds (optional)             | bucket + access key + secret      | Storage  | For S3/MinIO backend                                                                  |
| SMB creds (optional)            | share + user + pass               | Storage  | For NAS share backend                                                                  |
| `ALLOW_GUEST_UPLOADS`           | `true` / `false`                  | Config   | Enables unauthenticated uploads; off by default                                       |

## Install via Docker Compose

```bash
# Follow quick start: https://docs.slinkapp.io/getting-started/02-quick-start/
curl -O https://raw.githubusercontent.com/andrii-kryvoviaz/slink/main/docker-compose.yml
# Edit docker-compose.yml: set APP_SECRET, APP_URL, and any storage/OIDC vars
docker compose up -d
```

Visit `https://images.example.com`.

## Key environment variables

| Variable              | Required | Notes |
| --------------------- | -------- | ----- |
| `APP_URL`             | ✅       | Full public URL (`https://images.example.com`) |
| `APP_SECRET`          | ✅       | Symfony app secret — generate with `openssl rand -hex 32` |
| `APP_ENV`             |          | `prod` for production |
| `STORAGE_PROVIDER`    |          | `local` / `smb` / `s3` (default: `local`) |
| `S3_*`                |          | S3 bucket, region, key, secret (if using S3) |
| `SMB_*`               |          | SMB host, share, user, pass (if using SMB) |
| `OIDC_*`              |          | OIDC client ID/secret/issuer (if using SSO) |
| `ALLOW_GUEST_UPLOADS` |          | `true` to allow anonymous uploads |
| `USER_APPROVAL`       |          | `true` to require admin approval for new registrations |

Full env reference: <https://docs.slinkapp.io/configuration/01-environment-variables/>

## First boot

1. Set `APP_SECRET` + `APP_URL` in compose (required).
2. `docker compose up -d`
3. Visit the app → register the first account (auto-becomes admin).
4. Disable open registration if this is a private instance (Admin → Settings → `USER_APPROVAL: true`).
5. Configure storage provider (local is default; S3/SMB for NAS/cloud).
6. Set up OIDC if desired (Admin → Settings or env vars).
7. Configure ShareX upload target with your API key if using it (User → API Keys).
8. Put behind TLS (required for secure cookie handling).
9. Back up the storage volume + DB.

## Features overview

| Feature | Details |
|---------|---------|
| Private shares | All shares private by default; URL-based access |
| Password-protected | Optional password on individual shares |
| Expiring shares | Set expiry date/time; auto-revoked after |
| Collections | Group images into a shareable collection |
| Public Explore | Browse images users have opted to make public |
| Guest upload | Optional unauthenticated upload (no account needed) |
| ShareX integration | Automatic screenshot → Slink upload |
| Nested tags | Hierarchical tag management |
| OIDC/SSO | Google, Authentik, Keycloak, Authelia, Pocket ID, custom |
| User approval | Require admin to approve new registrations |
| API keys | Generate personal API keys for external tools |
| Storage providers | Local disk, SMB (NAS), AWS S3 / S3-compatible |
| Multi-language | EN, DE, ES, FR, IT, JA, PL, UA, ZH |
| Dark mode | System-default or manual toggle |
| Admin dashboard | Stats, user management, image moderation |
| Deduplication | Detects duplicate uploads at upload time |

## Backup

```sh
docker compose down
sudo tar czf slink-$(date +%F).tgz <data-volume>/ <uploads-volume>/
docker compose up -d
```

Contents: user accounts, share metadata, image files (if local storage). AGPL project; your images stay yours.

## Upgrade

1. `docker compose pull && docker compose up -d`
2. Review release notes: <https://github.com/andrii-kryvoviaz/slink/releases>

## Gotchas

- **`APP_SECRET` must be set before first run.** Symfony uses it for cryptographic operations (CSRF, session signing). Don't leave it at the default placeholder; generate a proper random string.
- **`APP_URL` must match what users see.** Used in generated share URLs, OAuth redirect URIs, and API responses. Wrong URL = broken share links and broken OIDC.
- **First registered user is the admin.** Register your own account first before opening registration to others. Or enable `USER_APPROVAL` from the start.
- **OIDC redirect URIs must be registered in your IdP.** For Google/Authentik/Keycloak: add `https://your-domain.com/auth/oidc/callback` as an allowed redirect URI. Wrong URI = OAuth 403.
- **Guest uploads are disabled by default.** Enable `ALLOW_GUEST_UPLOADS=true` if you want a public upload box (like a temporary Imgur-style service). Keep disabled for private instances.
- **SMB/S3 storage = file operations go to that backend.** If you switch storage providers after having images on local disk, the old images don't migrate automatically — do that manually first.
- **AGPL-3.0 license.** Serving a modified Slink over a network requires publishing your modified source.
- **Collections share via single link.** Useful for sending multiple images at once without creating individual share links.
- **ShareX integration** — configure ShareX with your Slink API key as a "Custom Uploader" destination. Every screenshot automatically goes to your own Slink instance.

## Project health

Active Symfony + SvelteKit development, Docker Hub, live demo, docs site, multi-language, OIDC, ShareX integration. Solo-maintained by Andrii Kryvoviaz.

## Image-sharing-family comparison

- **Slink** — Symfony + SvelteKit, private-by-default, OIDC, collections, ShareX, S3/SMB/local, AGPL
- **Pingvin Share** — Go + React, file sharing (not image-focused), simpler
- **Lychee** — PHP, photo gallery + sharing, album-centric
- **Chevereto** — PHP, feature-rich image hosting, freemium/commercial
- **Zipline** — Node.js, screenshot/file sharing, ShareX integration, simpler

**Choose Slink if:** you want a polished, OIDC-enabled, private-by-default image sharing platform with collections, ShareX integration, and S3/SMB storage support.

## Links

- Repo: <https://github.com/andrii-kryvoviaz/slink>
- Docs: <https://docs.slinkapp.io>
- Quick start: <https://docs.slinkapp.io/getting-started/02-quick-start/>
- Demo: <https://demo.slinkapp.io>
- Docker Hub: <https://hub.docker.com/r/anirdev/slink>
- Zipline (simpler ShareX alt): <https://github.com/diced/zipline>
