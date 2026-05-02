# FerriShare

A self-hosted file sharing application with built-in client-side end-to-end encryption. Files and filenames are encrypted in the browser using the WebCrypto API before upload — the server never sees plaintext content. The encryption key lives in the download link's URL fragment (after `#`), which is never sent to the server. Files auto-expire (1 hour, 1 day, or 1 week). Uploaders get a public download link and a private admin link. Built in Rust (tokio + axum) with SQLite.

- **GitHub:** https://github.com/TobiasMarschner/ferrishare
- **Docker image:** `ghcr.io/tobiasmarschner/ferrishare` (amd64, arm64, arm/v7)
- **Demo:** https://ferrishare-demo.tobiasm.dev
- **License:** Open-source

> ⚠️ The author notes they are not a cryptography expert and the project has not been independently audited. Review the cryptographic notes in the README before deploying.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Must run behind a reverse proxy (HTTPS required for WebCrypto) |

---

## Inputs to Collect

### Deploy Phase — interactive wizard
FerriShare uses an interactive CLI wizard to generate config (not env vars):

```bash
docker compose run --rm -it ferrishare --init
```

The wizard sets:
| Setting | Description |
|---------|-------------|
| Admin password | Site-wide admin panel password |
| Max file size | Maximum upload size (≤ 2 GiB, WebCrypto limit) |
| Max storage quota | Total storage limit across all files |
| Upload rate limit | Max uploads per IP per time period |
| Request rate limit | Max HTTP requests per IP per time period |
| Privacy policy | Optional legal text / contact info |
| Legal notice | Optional legal notice |

Config is written to `./data/` — re-run `--init` anytime to reconfigure without touching the database.

---

## Software-Layer Concerns

### Architecture
- Single Rust binary in a Docker container
- SQLite database for file metadata
- Must run behind a reverse proxy providing HTTPS (WebCrypto requires a secure context)
- Traefik example provided in docker-compose.yml; also works with Caddy/nginx

### Data Directories
| Mount | Contents |
|-------|----------|
| ./data | Config, SQLite database, uploaded (encrypted) files |

### Ports
- Internal only — expose via reverse proxy, not directly

---

## Setup Steps

```bash
# 1. Create a directory and download docker-compose.yml
mkdir ferrishare && cd ferrishare
curl -L https://raw.githubusercontent.com/TobiasMarschner/ferrishare/HEAD/docker-compose.yml -o docker-compose.yml

# 2. Pull the image
docker compose pull

# 3. Run the interactive configuration wizard
docker compose run --rm -it ferrishare --init

# 4. Start the app
docker compose up -d
```

---

## Upgrade Procedure

```bash
docker compose pull ferrishare
docker compose up -d ferrishare
```

Schema migrations run automatically. Re-run `--init` only if you want to change settings; it won't touch the database or uploaded files.

---

## Gotchas

- **HTTPS is required:** The WebCrypto API used for client-side encryption only works in a [secure context](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts) — you must serve FerriShare behind HTTPS; `localhost` also works for testing
- **Key is in the URL fragment:** The `#` fragment is never sent to the server; if a user loses the download link, the file cannot be decrypted — not even by the admin
- **Max file size is 2 GiB:** The WebCrypto API limits message length to 2 GiB; this is enforced during setup
- **IP-based rate limiting:** Both upload rate and general request rate are limited per IP (IPv4 full address or IPv6 /64 subnet); configure during `--init`
- **Admin panel at /admin:** Password-protected; shows global storage stats and allows early file deletion
- **Files auto-expire:** Choose 1 hour, 1 day, or 1 week per upload; expiry enforced on access
- **Uploader gets two links:** A public download link (shareable) and a private admin link (for stats + early deletion)

---

## References
- GitHub: https://github.com/TobiasMarschner/ferrishare
- Demo: https://ferrishare-demo.tobiasm.dev
- Cryptographic notes: https://github.com/TobiasMarschner/ferrishare#cryptography
