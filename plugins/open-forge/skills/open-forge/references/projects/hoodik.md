---
name: Hoodik
description: "Lightweight self-hosted E2E encrypted cloud storage. Docker. Rust/Actix + Vue 3 + SQLite/PostgreSQL. hudikhq/hoodik. Client-side RSA+AEGIS encryption, encrypted notes, public share links, S3 storage backend, Android app. CC BY-NC 4.0."
---

# Hoodik

**Lightweight self-hosted end-to-end encrypted cloud storage.** Files are encrypted in the browser before upload — the server never sees plaintext. Hybrid RSA-2048 + AEGIS-128L encryption. Encrypted search (hash tokens), encrypted rich-text notes, public sharing links (key in URL fragment), optional S3-compatible backend, Android app, TOTP 2FA.

Built + maintained by **hudikhq**. CC BY-NC 4.0 license.

> ⚠️ **License: CC BY-NC 4.0** — free for personal, non-commercial use. Commercial use requires a license from hudikhq.

- Upstream repo: <https://github.com/hudikhq/hoodik>
- Website: <https://hoodik.io>
- Docker Hub: <https://hub.docker.com/r/hudik/hoodik>
- Android app: <https://play.google.com/store/apps/details?id=com.hudikhq.hoodik>
- VPS setup guide: <https://hoodik.io/get-started>

## Architecture in one minute

- **Rust / Actix-web** backend
- **Vue 3** frontend (all crypto in browser)
- **SQLite** (default, zero-config) or **PostgreSQL** database
- Optional **S3-compatible** storage for encrypted chunks (AWS S3, MinIO, Backblaze B2, Wasabi)
- Port **5443** (HTTPS — self-signed cert auto-generated on first run)
- Multi-arch Docker: amd64, armv6, armv7, arm64
- Resource: **very low** — Rust daemon; SQLite; minimal RAM

## Compatible install methods

| Infra      | Runtime            | Notes                                                                 |
| ---------- | ------------------ | --------------------------------------------------------------------- |
| **Docker** | `hudik/hoodik`     | **Primary** — Docker Hub; multi-arch                                  |

## Inputs to collect

| Input              | Example                          | Phase   | Notes                                                              |
| ------------------ | -------------------------------- | ------- | ------------------------------------------------------------------ |
| `APP_URL`          | `https://cloud.example.com`      | Config  | **Required** — public URL; affects cookie security + link generation |
| `DATA_DIR`         | `/data`                          | Storage | Persistent volume for DB + keys + encrypted chunks                 |
| SMTP (optional)    | SMTP host + creds                | Email   | For email verification + password reset                            |
| S3 (optional)      | endpoint, bucket, key, secret    | Storage | Replace local chunk storage with S3-compatible object storage      |

## Install (quickstart)

```bash
docker run --name hoodik -d \
  -e DATA_DIR='/data' \
  -e APP_URL='https://my-app.example.com' \
  --volume "$(pwd)/data:/data" \
  -p 5443:5443 \
  hudik/hoodik:latest
```

With email + custom TLS (see the README: <https://github.com/hudikhq/hoodik#docker-with-email-and-custom-tls>).

## Docker Compose (PostgreSQL + MinIO)

```yaml
services:
  postgres:
    image: bitnami/postgresql:latest
    restart: always
    environment:
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - POSTGRESQL_DATABASE=postgres
      - POSTGRESQL_WAL_LEVEL=logical

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      - MINIO_ROOT_USER=minioadmin
      - MINIO_ROOT_PASSWORD=minioadmin
    volumes:
      - ./data-minio:/data
    ports:
      - "9000:9000"

  hoodik:
    image: hudik/hoodik:latest
    depends_on:
      - postgres
      - minio
    environment:
      - DATA_DIR=/data
      - APP_URL=https://cloud.example.com
      - DATABASE_URL=postgresql://postgres:postgres@postgres/postgres
      - STORAGE_DRIVER=s3
      - S3_ENDPOINT=http://minio:9000
      - S3_BUCKET=hoodik
      - S3_ACCESS_KEY=minioadmin
      - S3_SECRET_KEY=minioadmin
    volumes:
      - ./data:/data
    ports:
      - "5443:5443"
```

## First boot

1. Start container with `APP_URL` set.
2. Visit `https://localhost:5443` (self-signed cert — browser warning is expected until you add a real cert or proxy).
3. Register your account.
4. **Back up your RSA private key** (shown on registration) — save it in a password manager.
5. Upload files — they encrypt in the browser before leaving your device.
6. Explore encrypted notes (Settings → Notes).
7. Share files via public links.
8. (Optional) Install the Android app.
9. Put behind a TLS reverse proxy (nginx/Caddy) for a proper HTTPS certificate.

## How encryption works

| Step | Details |
|------|---------|
| Registration | RSA-2048 key pair generated; private key encrypted with your passphrase + stored on server |
| File upload | Random symmetric key per file → encrypt file chunks with AEGIS-128L → upload encrypted chunks |
| Symmetric key storage | File key encrypted with your RSA public key → stored in DB |
| Search | File names tokenized + hashed → opaque tokens → server can match queries without seeing names |
| Public links | Random link key generated → file key + metadata encrypted with link key → link key in URL fragment |
| Cipher tracking | Each file stores which cipher was used → correct algorithm always used for decryption |

### Cryptographic primitives

| Use | Algorithm |
|-----|-----------|
| Asymmetric | RSA-2048 PKCS#1 |
| Symmetric (default) | AEGIS-128L (hardware-accelerated AEAD, WASM SIMD128) |
| Symmetric (supported) | Ascon-128a, ChaCha20-Poly1305 |
| Key derivation | SHA-2, Blake2b |

## Features overview

| Feature | Details |
|---------|---------|
| E2E encryption | RSA + AEGIS-128L; server never sees plaintext |
| Encrypted search | Hash-token file name search; no plaintext to server |
| Encrypted notes | Rich markdown notes, WYSIWYG editor; same E2E encryption |
| Public share links | Key in URL fragment; server never sees it |
| Chunked transfers | Concurrent upload/download of encrypted chunks |
| 2FA | TOTP-based per account |
| Admin dashboard | Manage users, sessions, invitations, app settings |
| SQLite / PostgreSQL | SQLite default; PostgreSQL via env var |
| S3 storage | Store encrypted chunks on S3/MinIO/Backblaze/Wasabi |
| Multi-arch Docker | amd64, armv6, armv7, arm64 |
| Android app | Native Android client |

## Gotchas

- **⚠️ Back up your private key.** The RSA private key is the only way to recover your account and decrypt your files if you forget your password. The server stores it encrypted with your passphrase — if both are lost, files are unrecoverable. **Store the private key in a password manager.**
- **CC BY-NC 4.0 license.** Hoodik is free for personal, non-commercial use. If you plan to offer it as a service to clients or use it in a business context, contact hudikhq for a commercial license.
- **Self-signed cert on first run.** Hoodik auto-generates a self-signed TLS cert so it can start with HTTPS immediately. Browsers will warn about it. For production, either configure your own cert or put Hoodik behind nginx/Caddy (set `APP_URL` to the proxy URL and expose the proxy on 443).
- **Public link key is in URL fragment.** Share links look like `https://host/links/id#key`. The `#key` fragment is never sent to the server in HTTP requests — it stays in the browser. The recipient must have the full URL (including the fragment) to decrypt.
- **S3 stores encrypted chunks only.** With S3 backend enabled, file chunks go to S3 but metadata (DB) stays local. Back up both the DB and S3 bucket.
- **No browser extension needed.** All crypto runs as in-browser WebAssembly (WASM) — no extension install required.
- **AEGIS-128L requires hardware AES or WASM SIMD.** Modern x86/ARM hardware accelerates this; older devices may fall back to software WASM.

## Backup

```sh
docker stop hoodik
sudo tar czf hoodik-$(date +%F).tgz data/   # includes DB + keys + local chunks
docker start hoodik
# If using S3: back up bucket separately (versioned bucket recommended)
```

## Upgrade

```sh
docker pull hudik/hoodik:latest && docker stop hoodik && docker rm hoodik
# Re-run the docker run command with the same volumes
```

## Project health

Active Rust + Vue development, Docker Hub (multi-arch), Android app, AEGIS-128L crypto, S3 backend, 2FA. Maintained by hudikhq. CC BY-NC 4.0.

## E2E-cloud-storage-family comparison

- **Hoodik** — Rust, RSA+AEGIS E2E, encrypted search, encrypted notes, S3 backend, Android, CC BY-NC
- **Cryptgeon** — Go, one-time E2E secret sharing; different scope (not file storage)
- **Cryptpad** — Node.js, E2E encrypted collaborative docs; no file storage focus
- **Nextcloud + E2EE** — PHP, optional E2E encryption module; heavier; full cloud platform
- **Proton Drive** — SaaS; not self-hosted; similar E2E model

**Choose Hoodik if:** you want a lightweight self-hosted cloud with true end-to-end encryption (client-side RSA + AEGIS), encrypted search and notes, optional S3 backend, and an Android app — for personal non-commercial use.

## Links

- Repo: <https://github.com/hudikhq/hoodik>
- Website: <https://hoodik.io>
- Docker Hub: <https://hub.docker.com/r/hudik/hoodik>
- Android: <https://play.google.com/store/apps/details?id=com.hudikhq.hoodik>
- VPS guide: <https://hoodik.io/get-started>
