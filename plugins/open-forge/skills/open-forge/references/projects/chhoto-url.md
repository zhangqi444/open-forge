# Chhoto URL

**Simple, fast, self-hosted URL shortener built in Rust. Minimal footprint: <6 MB Docker image, <15 MB RAM. No bloat, no tracking.**
GitHub: https://github.com/SinTan1729/chhoto-url
Demo: https://chhoto-url-demo.sayantansantra.com (password: chhoto-url-demo-pass)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Docker run | Single container |
| Any | Podman / Podman quadlets | Sample .container file in repo |

---

## Inputs to Collect

### Required
- `CHHOTO_PASSWORD` — admin password for managing links

### Important optional
- `CHHOTO_DB_URL` — path to SQLite database (default: in-memory; persist by mounting a volume)
- `CHHOTO_SQLITE_USE_WAL_MODE` — strongly recommended to enable (prevents corruption under concurrent use)
- `CHHOTO_SLUG_STYLE` — UID recommended for instances with many links; set `CHHOTO_SLUG_LENGTH` to 16+ if so

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  chhoto-url:
    image: sintan1729/chhoto-url:latest
    ports:
      - "4567:4567"
    environment:
      - CHHOTO_PASSWORD=your-password
      - CHHOTO_DB_URL=/data/urls.sqlite
    volumes:
      - ./data:/data
    restart: unless-stopped
```

### Docker run (with persistent DB)
```bash
touch ./urls.sqlite
docker run -p 4567:4567 \
  -e CHHOTO_PASSWORD="password" \
  -v ./data:/data \
  -e CHHOTO_DB_URL=/data/urls.sqlite \
  -d sintan1729/chhoto-url:latest
```

### Image variants
- `sintan1729/chhoto-url:latest` — scratch-based, minimal (<6 MB)
- `sintan1729/chhoto-url:<VERSION>-alpine` — alpine-based with shell tools for debugging

### Architectures
linux/amd64, linux/arm64, linux/arm/v7, linux/riscv64

### Ports
- `4567` — web UI and API

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- WAL mode is strongly recommended — enable via `CHHOTO_SQLITE_USE_WAL_MODE`
- If using WAL mode with a custom `CHHOTO_DB_URL`, mount the whole directory (not just the file) to avoid data corruption
- For instances with thousands of links, use UID slug style with length ≥ 16 or link generation will fail
- No user management by design — single password for the whole instance
- scratch-based image has no shell or TMPDIR — if SQLite migrations fail with error 6410, set `TMPDIR` to a writable path
- Transport is unencrypted — use a reverse proxy (e.g. Caddy) for TLS
- Public mode available: anyone can add links, admin password required to list/delete

---

## References
- Installation guide: https://github.com/SinTan1729/chhoto-url/blob/main/INSTALLATION.md
- GitHub: https://github.com/SinTan1729/chhoto-url#readme
