---
name: Cryptgeon
description: "Secure self-destructing secret note/file sharing service. Docker + Redis. Rust backend. cupcakearmy/cryptgeon. Client-side AES-256-GCM encryption, view/time constraints, no persistence, CLI + Raycast."
---

# Cryptgeon

**Secure, open-source, self-destructing note and file sharing service.** Inspired by PrivNote. Notes are encrypted client-side (AES-256-GCM) before being sent to the server — the server **never sees the decryption key** and cannot read note content. Data stored in Redis only (no disk persistence). Self-destruct after N views or a time limit. CLI client, Raycast extension, custom theming.

Built + maintained by **cupcakearmy**. Live service at [cryptgeon.org](https://cryptgeon.org).

- Upstream repo: <https://github.com/cupcakearmy/cryptgeon>
- Live service: <https://cryptgeon.org>
- Docker Hub: <https://hub.docker.com/r/cupcakearmy/cryptgeon>
- CLI: `npx cryptgeon`
- Raycast extension: available

## Architecture in one minute

- **Rust** backend (`app` service) — API + serves the web frontend
- **Redis 7** — in-memory only storage (no disk persistence: `--save "" --appendonly no`)
- Port **8000** inside container (upstream maps `80:8000`)
- Each note: random 256-bit `id` (for retrieval) + 256-bit `key` (never sent to server)
- Encryption: **AES-256-GCM** in the browser/client; server stores only ciphertext
- The decryption key is in the URL fragment (`#key`) — never sent to the server
- Resource: **tiny** — Rust binary + Redis in-memory

## Compatible install methods

| Infra          | Runtime                       | Notes                                             |
| -------------- | ----------------------------- | ------------------------------------------------- |
| **Docker**     | `cupcakearmy/cryptgeon`       | **Primary** — Docker Hub                          |
| **Live hosted**| cryptgeon.org                 | No setup; trust the maintainer's instance          |

## Install via Docker Compose

```yaml
services:
  redis:
    image: redis:7-alpine
    command: redis-server --save "" --appendonly no   # in-memory only
    tmpfs:
      - /data                                          # prevents anonymous volume

  app:
    image: cupcakearmy/cryptgeon:latest
    depends_on:
      - redis
    environment:
      SIZE_LIMIT: 4 MiB      # max note/file size
    ports:
      - 80:8000
```

```bash
docker compose up -d
```

Visit `http://localhost:80`.

> ⚠️ **HTTPS required.** Browsers block `SubtleCrypto` (the Web Crypto API used for AES-GCM) on non-HTTPS origins. Self-hosted Cryptgeon **must** be served over HTTPS for encryption to work. HTTP-only deploys produce a broken experience.

## Environment variables

| Variable                | Default          | Description                                                                                                 |
| ----------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------- |
| `REDIS`                 | `redis://redis/` | Redis connection URL                                                                                         |
| `SIZE_LIMIT`            | `1 KiB`          | Max note/file size. `512 MiB` maximum. UI shows the size including ~35% base64 overhead.                    |
| `MAX_VIEWS`             | `100`            | Maximum allowed view count per note                                                                         |
| `MAX_EXPIRATION`        | `360`            | Maximum expiration in minutes                                                                               |
| `ALLOW_ADVANCED`        | `true`           | Allow custom note config (views, expiry). `false` = all notes are 1-view only                               |
| `ALLOW_FILES`           | `true`           | Allow file uploads. `false` = text notes only                                                               |
| `ID_LENGTH`             | `32`             | Note ID size in bytes. Lower = shorter URLs. Does not affect encryption strength.                           |
| `VERBOSITY`             | `warn`           | Log level: `error` / `warn` / `info` / `debug` / `trace`                                                   |
| `THEME_IMAGE`           | `""`             | Custom logo URL (must be publicly reachable)                                                                |
| `THEME_TEXT`            | `""`             | Custom description text below logo                                                                          |
| `THEME_PAGE_TITLE`      | `""`             | Custom page title                                                                                           |
| `THEME_FAVICON`         | `""`             | Custom favicon URL                                                                                          |
| `THEME_NEW_NOTE_NOTICE` | `true`           | Show the "stored in memory, may be evicted" notice on new note creation                                     |
| `IMPRINT_URL`           | `""`             | URL for an external imprint/legal page (EU deployments)                                                     |
| `IMPRINT_HTML`          | `""`             | Inline HTML for `/imprint` (alternative to `IMPRINT_URL`)                                                   |

## CLI usage

```bash
# Send a text note
npx cryptgeon send text "This is a secret" --server https://cryptgeon.example.com

# Send a file
npx cryptgeon send file ./confidential.pdf --server https://cryptgeon.example.com

# Receive a note (by URL)
npx cryptgeon receive "https://cryptgeon.example.com/note#key..."
```

No install required — runs via `npx`. Full CLI docs: <https://github.com/cupcakearmy/cryptgeon/blob/main/packages/cli/README.md>

## First boot

1. Deploy (`docker compose up -d`).
2. Put behind HTTPS (Caddy / certbot / nginx + Let's Encrypt). **Required for encryption.**
3. Visit `https://cryptgeon.example.com`.
4. Create a test note → copy the link → open in incognito → verify self-destruct.
5. Optionally configure `SIZE_LIMIT`, `MAX_VIEWS`, `MAX_EXPIRATION`, branding env vars.

## Backup

**Nothing to back up.** All notes live in Redis memory only. Notes are ephemeral by design — when Redis restarts, all notes are gone. This is a feature: no persistent storage = no data breach risk for stored secrets.

## Upgrade

```bash
docker compose pull && docker compose up -d
```

## Gotchas

- **HTTPS is not optional.** `SubtleCrypto` (Web Crypto API) is blocked on HTTP origins by all modern browsers. Without HTTPS, the encryption doesn't work and the app shows an error. Always deploy behind TLS.
- **Server restarts delete all notes.** Redis is in-memory only (`--save "" --appendonly no`). Restart = all pending notes gone. By design — secrets shouldn't be persisted to disk.
- **Key is in the URL fragment — never sent to server.** The URL looks like `https://cryptgeon.example.com/note/ABC#KEY`. The `#KEY` fragment is client-side only; browsers don't send URL fragments in HTTP requests. Share the full URL (including the fragment) with the recipient.
- **Race condition with multiple Redis instances.** Upstream notes this: view-count guarantees only hold with a single Redis instance. Multiple Redis instances (for HA) can allow a note to be viewed more than the configured limit due to race conditions.
- **`SIZE_LIMIT` includes ~35% base64 overhead.** If you set `SIZE_LIMIT=4 MiB`, the actual plaintext max is ~2.9 MiB (the rest is base64 encoding of the encrypted content). The UI shows the configured value (including overhead) as the advertised limit.
- **`ALLOW_ADVANCED=false` for strict one-view-only deployments.** Good for compliance scenarios where all secrets must be one-time-only.
- **Custom branding via env vars.** `THEME_IMAGE` + `THEME_TEXT` + `THEME_PAGE_TITLE` + `THEME_FAVICON` — all must be publicly reachable URLs (served from a CDN or your own host). They're loaded client-side.
- **EU hosting: use `IMPRINT_URL` or `IMPRINT_HTML`.** German/EU law may require an Impressum/legal notice. Set either env var for compliance.
- **`tmpfs: - /data`** in the Redis service prevents creation of an anonymous Docker volume for Redis data (which would accumulate across restarts with no data in it). Good hygiene.

## Project health

Active Rust + TypeScript development, Docker Hub, CI, Raycast extension, CLI, multiple languages (EN/中文/ES), live hosted demo, AGPL-3.0.

## Ephemeral-secret-sharing-family comparison

- **Cryptgeon** — Rust + Redis, client-side AES-256-GCM, no persistence, CLI, custom branding, AGPL
- **PrivNote** — SaaS original inspiration; not self-hosted; server-side encryption
- **Yopass** — Go, similar concept, client-side encryption, Redis or Memcached
- **OneTimeSecret** — SaaS; also open-source self-hosted; Ruby; server-side encryption
- **Privatebin** — PHP, paste-bin style, client-side encryption, optional persistence

**Choose Cryptgeon if:** you want a self-hosted, client-side-encrypted, zero-persistence secret sharing service with a clean UI, CLI, and custom branding support.

## Links

- Repo: <https://github.com/cupcakearmy/cryptgeon>
- Live service: <https://cryptgeon.org>
- Docker Hub: <https://hub.docker.com/r/cupcakearmy/cryptgeon>
- CLI README: <https://github.com/cupcakearmy/cryptgeon/blob/main/packages/cli/README.md>
- Yopass (Go alt): <https://github.com/jhaals/yopass>
- Privatebin (PHP alt): <https://privatebin.info>
