# OTS (One-Time Secret)

**Self-hosted one-time secret sharing — secrets are AES-256 encrypted in the browser before being sent to the server; the server never sees the plaintext. Secret is deleted on first read.**
GitHub: https://github.com/Luzifer/ots
Public instance: https://ots.fyi

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Single container |
| Any Linux | Binary | Pre-built static binary available |

---

## Inputs to Collect

### Required
- Storage backend choice — `mem` (in-memory) or `redis` (persistent)

### If using Redis
- `REDIS_URL` — connection string: `redis://USR:PWD@HOST:PORT/DB`
- `REDIS_KEY` — key prefix (default: `io.luzifer.ots`)

### Optional
- `SECRET_EXPIRY` — expiry in seconds (default: 0 = no expiry)

---

## Software-Layer Concerns

### Docker (in-memory, ephemeral)
```bash
docker run -d \
  -p 3000:3000 \
  ghcr.io/luzifer/ots
```

### Docker with Redis (persistent)
```bash
docker run -d \
  -p 3000:3000 \
  -e REDIS_URL=redis://:password@redis:6379/0 \
  -e SECRET_EXPIRY=604800 \
  ghcr.io/luzifer/ots
```

### Docker Compose with Redis
```yaml
services:
  ots:
    image: ghcr.io/luzifer/ots
    ports:
      - "3000:3000"
    environment:
      - REDIS_URL=redis://:yourpassword@redis:6379/0
      - SECRET_EXPIRY=604800   # 7 days
    depends_on:
      - redis

  redis:
    image: redis:alpine
    command: redis-server --requirepass yourpassword
    volumes:
      - redis_data:/data

volumes:
  redis_data:
```

### Ports
- `3000` — web UI and API

### CLI usage
OTS-CLI available for scripted secret sharing:
```bash
echo "my password" | ots-cli create
ots-cli fetch 'https://ots.fyi/#<id>|<password>'
```

### How it works
- Secret is encrypted with AES-256 in the browser
- Encrypted blob is stored on server; decryption key only exists in the URL fragment (`#id|key`)
- Fragment is never sent to the server — server cannot decrypt secrets
- Secret deleted from storage on first read

---

## Upgrade Procedure

1. docker pull ghcr.io/luzifer/ots
2. docker stop/rm ots && docker run ... (same args)

---

## Gotchas

- `mem` backend loses all secrets on container restart — use Redis for persistence
- The URL fragment contains the decryption key — losing the URL means losing access to the secret
- Pre-Redis v6: use `auth` as the username in `REDIS_URL`; v6+: use an ACL user
- Customization options (branding, theme, etc.) documented in the wiki

---

## References
- Wiki: https://github.com/Luzifer/ots/wiki
- Customization: https://github.com/Luzifer/ots/wiki/Customization
- GitHub: https://github.com/Luzifer/ots#readme
