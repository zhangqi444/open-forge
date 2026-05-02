# FlashPaper

**One-time encrypted zero-knowledge secret sharing**
Official site: https://github.com/AndrewPaglusch/FlashPaper

FlashPaper generates single-use encrypted URLs for sharing passwords and secrets. Once viewed, the secret is permanently deleted. Uses double-layer AES-256-CBC encryption with bcrypt-hashed IDs. No external database required — SQLite-backed, zero-knowledge design.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | Single container, no dependencies |
| VPS / bare metal | PHP 7.0+ + web server | Traditional install with Apache/Nginx |

## Inputs to Collect

### Phase: Pre-deployment
- `BASE_URL` — public URL of the instance (e.g. `https://secrets.example.com/flashpaper`); leave empty if serving from root

### Phase: Customization (optional)
- `SITE_TITLE` — browser tab title
- `SITE_LOGO` — path to logo image
- `MAX_SECRET_LENGTH` — max characters per secret (default: `3000`)
- `PRUNE_MIN_DAYS` / `PRUNE_MAX_DAYS` — auto-delete window for unread secrets (default: 365–730 days)

## Software-Layer Concerns

**Docker image:** `ghcr.io/andrewpaglusch/flashpaper:v2`

**Data volume:** `./data:/var/www/html/data` — contains the SQLite database and AES static key; **back this up**

**Port:** `8080` (maps to container's `80`)

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `BASE_URL` | Public URL prefix; critical if not serving from root |
| `RETURN_FULL_URL` | `true` = return full URL in API responses |
| `MAX_SECRET_LENGTH` | Character limit per secret |
| `PRUNE_ENABLED` | `true` to auto-delete expired secrets |
| `PRUNE_MIN_DAYS` | Minimum age before a secret can be pruned |
| `PRUNE_MAX_DAYS` | Maximum age before pruning |
| `ANNOUNCEMENT` | Optional banner message on the UI |

**API usage:**
```bash
curl -s -X POST -d "secret=my secret&json=true" https://secrets.example.com
# Returns: {"url":"https://secrets.example.com/?k=..."}
```

**How it works:**
1. Secret encrypted with random AES-256-CBC key + IV
2. Ciphertext re-encrypted with a static AES key stored in `data/`
3. ID + AES key returned as one-time URL parameter `k`
4. On retrieval: decrypted, delivered, immediately deleted from DB

## Upgrade Procedure

1. Pull new image: `docker-compose pull`
2. Recreate: `docker-compose up -d`
3. Data dir persists; no migration needed between minor versions
4. Pin to a specific tag if stability is critical (e.g. `:v2`)

## Gotchas

- **Disable access logging** — upstream strongly recommends disabling web server access logs to avoid recording IP addresses and timestamps tied to secret retrieval
- **`BASE_URL` must be exact** — if serving under a subpath, `BASE_URL` must match or one-time URLs will break
- **Static AES key is in `data/`** — loss of the `data/` volume means all stored secrets become unreadable; treat it like a keystore
- **Single-use is enforced server-side** — the secret is deleted from DB immediately on first view; no way to recover it
- **Prune is approximate** — pruning only runs on page load when enabled; long-idle instances may accumulate expired entries until next visit

## References
- Upstream README: https://github.com/AndrewPaglusch/FlashPaper/blob/master/README.md
- Docker Compose: https://github.com/AndrewPaglusch/FlashPaper/blob/master/docker-compose.yml
- Live demo: https://flashpaper.io
