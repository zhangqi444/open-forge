---
name: Hemmelig
description: "Self-hosted encrypted secret sharing platform. Docker. Node.js/Fastify + SQLite. HemmeligOrg/Hemmelig.app. Client-side TweetNaCl encryption, expiry, view limits, IP restrictions, password protection, file uploads, QR codes."
---

# Hemmelig

**Encrypted secret sharing for everyone.** Share passwords, credentials, API keys, or sensitive messages via a unique URL that self-destructs. All encryption happens client-side using TweetNaCl before anything reaches the server — the decryption key is only in the URL fragment (never stored on the server). IP restrictions, expiry, view count limits, password protection, and encrypted file uploads.

Built + maintained by **HemmeligOrg**. MIT license.

- Upstream repo: <https://github.com/HemmeligOrg/Hemmelig.app>
- Website + SaaS: <https://hemmelig.app>
- Docker Hub: <https://hub.docker.com/r/hemmeligapp/hemmelig>

## Architecture in one minute

- **Node.js / Fastify** backend
- **SQLite** database (default) for encrypted secrets metadata
- Port **3000**
- Client-side encryption: **TweetNaCl** in the browser — server never sees plaintext
- Decryption key lives only in the URL fragment (`#key`) — not sent to server, not in logs
- Encrypted files stored in `/var/tmp/hemmelig/upload/files` volume
- Resource: **low** — Fastify + SQLite; very lightweight

## Compatible install methods

| Infra      | Runtime                         | Notes                                      |
| ---------- | ------------------------------- | ------------------------------------------ |
| **Docker** | `hemmeligapp/hemmelig`          | **Primary** — Docker Hub; pin to a version tag |
| **SaaS**   | hemmelig.app                    | Hosted version; free plan available        |

## Inputs to collect

| Input                     | Example                       | Phase    | Notes                                                               |
| ------------------------- | ----------------------------- | -------- | ------------------------------------------------------------------- |
| `SECRET_HOST`             | `https://share.example.com`   | Network  | **Required** — your public domain; used for CORS + cookies          |
| `SECRET_JWT_SECRET`       | random string                 | Security | **Required** — JWT signing secret; change from default              |
| `SECRET_ROOT_PASSWORD`    | strong password               | Auth     | Admin account password; **change immediately after first login**    |
| `SECRET_ROOT_EMAIL`       | admin email                   | Auth     | Admin account email                                                 |
| `SECRET_ROOT_USER`        | `groot`                       | Auth     | Admin username (default: `groot`)                                   |

## Install via Docker Compose

```yaml
services:
  hemmelig:
    image: hemmeligapp/hemmelig:latest  # Pin to a version tag in production
    container_name: hemmelig
    init: true
    ports:
      - '3000:3000'
    volumes:
      - ./hemmelig-files:/var/tmp/hemmelig/upload/files
      - ./hemmelig-db:/home/node/hemmelig/database/
    environment:
      - SECRET_LOCAL_HOSTNAME=0.0.0.0
      - SECRET_PORT=3000
      - SECRET_HOST=https://share.example.com     # CHANGE: your domain
      - SECRET_ROOT_USER=groot
      - SECRET_ROOT_PASSWORD=changeme_admin        # CHANGE: strong password
      - SECRET_ROOT_EMAIL=admin@example.com
      - SECRET_JWT_SECRET=changeme_random_secret   # CHANGE: random string
      - SECRET_FILE_SIZE=4                         # max upload size in MB
      - SECRET_MAX_TEXT_SIZE=256                   # max secret text in KB
      - SECRET_FORCED_LANGUAGE=en
    restart: always
    stop_grace_period: 1m
    healthcheck:
      test: 'curl -o /dev/null localhost:3000/api/healthz || exit 1'
      timeout: 5s
      retries: 3
```

Visit `http://localhost:3000`.

## First boot

1. Set `SECRET_HOST`, `SECRET_JWT_SECRET`, and `SECRET_ROOT_PASSWORD` before starting.
2. `docker compose up -d`.
3. Visit `http://localhost:3000`.
4. Log in as admin (`groot` or your configured username).
5. **Change admin password immediately** (Settings → Account).
6. Create a test secret → verify the share link works.
7. Configure user registration settings (open/invite-only/disabled).
8. Put behind TLS — **required for the security model** (HTTPS ensures fragment key isn't logged by proxies).

## How the security model works

```
1. You enter: "my-password-123"
2. Browser generates: unique encryption key (random)
3. Browser encrypts: encryptedBlob = TweetNaCl.encrypt(text, key)
4. Browser sends: only encryptedBlob to server
5. Server stores: encryptedBlob (can't decrypt without key)
6. Share URL: https://share.example.com/secret/abc123#encryptionKey
7. Recipient opens URL: browser extracts #encryptionKey from fragment
8. Browser fetches: encryptedBlob from server
9. Browser decrypts: locally, never sends key to server
```

The URL fragment (`#...`) is never sent in HTTP requests — it's client-side only. This means the server, logs, and proxies never see the decryption key.

## Features overview

| Feature | Details |
|---------|---------|
| Client-side encryption | TweetNaCl; server never sees plaintext |
| Expiry | Set TTL: 1 hour to 14 days |
| View limits | Self-destructs after N views |
| Password protection | Optional second factor on top of URL key |
| IP restrictions | Whitelist specific IPs that can decrypt |
| File uploads | Encrypted file uploads (authenticated users; size-limited) |
| QR code | Generate QR code of the secret link |
| Separate key sharing | Option to share link and decryption key separately |
| Public paste | Unencrypted public paste mode (with IP logging) |
| Rich text | Inline image support in secret content |
| Base64 conversion | Convert binary data to Base64 for sharing |
| Multi-language | Interface language configurable via `SECRET_FORCED_LANGUAGE` |

## Gotchas

- **Pin to a version tag in production.** The compose example uses `hemmeligapp/hemmelig:vX.X.X` in the upstream docs. Using `:latest` may pull breaking changes. Pin to a specific version tag from <https://github.com/HemmeligOrg/Hemmelig.app/tags>.
- **`SECRET_HOST` is critical.** This domain is used for CORS and cookie configuration. If set incorrectly (e.g., `localhost` in production), sharing links won't work from external browsers and the UI will break.
- **HTTPS is required for the security model.** The decryption key is in the URL fragment. HTTP proxies and servers don't log fragments, but HTTP also means no TLS — a network eavesdropper can see the fragment in the full URL from the browser. Use HTTPS. Always.
- **Change admin password before first share.** The default `SECRET_ROOT_PASSWORD` placeholder would allow anyone who finds your instance to log in as admin. Change it before creating any real secrets.
- **SQLite is fine for personal use.** SQLite handles Hemmelig's sequential write workload well. For high-traffic shared instances, consider the persistence characteristics (SQLite WAL mode is enabled by default in recent versions).
- **Encrypted files are in the volume.** Uploaded files are stored encrypted in `/var/tmp/hemmelig/upload/files`. The DB tracks which file belongs to which secret. If the DB is lost, encrypted files become orphaned and can't be decrypted.
- **Secret destruction.** After max views or expiry, the server deletes the encrypted blob from the DB. The decryption key was only in the URL — both are gone. There's no recovery.
- **Public paste mode.** The "public paste" option skips client-side encryption — it's a plain text paste visible to everyone. Use this for non-sensitive sharing only.

## Backup

```sh
docker compose stop hemmelig
sudo tar czf hemmelig-$(date +%F).tgz hemmelig-db/ hemmelig-files/
docker compose start hemmelig
```

## Upgrade

1. Check release notes: <https://github.com/HemmeligOrg/Hemmelig.app/releases>
2. Update version tag in compose
3. `docker compose pull && docker compose up -d`

## Project health

Active Node.js/Fastify development, Docker Hub, SaaS instance (hemmelig.app), file uploads, OIDC-capable, QR codes, IP restrictions. Maintained by HemmeligOrg. MIT license.

## Secret-sharing-family comparison

- **Hemmelig** — Node.js+Fastify, TweetNaCl client-side E2E, file uploads, IP restrictions, self-destruct, MIT
- **ots (One-Time Secret)** — Ruby, simple text secrets, self-destruct; no client-side crypto
- **Privatebin** — PHP, client-side AES encryption, paste-focused; similar security model
- **Yopass** — Go, simple secret sharing; no file uploads
- **Vaultwarden** — full password manager; different scope

**Choose Hemmelig if:** you want a self-hosted encrypted secret sharing platform with client-side TweetNaCl encryption, file uploads, IP restrictions, expiry, and view limits — for sharing credentials safely without the server ever seeing plaintext.

## Links

- Repo: <https://github.com/HemmeligOrg/Hemmelig.app>
- SaaS: <https://hemmelig.app>
- Docker Hub: <https://hub.docker.com/r/hemmeligapp/hemmelig>
- Release tags: <https://github.com/HemmeligOrg/Hemmelig.app/tags>
