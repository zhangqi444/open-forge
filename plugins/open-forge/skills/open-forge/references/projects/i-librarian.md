# I, Librarian

A self-hosted academic paper and PDF library management system. Organise, annotate, full-text search, and share your research literature. Supports PDF import from local files, URLs, and academic databases (PubMed, arXiv, IEEE, etc.). Includes OCR (via Tesseract), LibreOffice import, notes/annotations, citation export, and multi-user access. Built on PHP + Apache + SQLite. Available as Docker or native installer.

- **GitHub:** https://github.com/mkucej/i-librarian-free
- **License:** Open-source (GPLv3)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker run / Docker Compose | Build image from release archive; no pre-built image on Docker Hub |
| Linux (Debian/Ubuntu) | DEB package / installer | Automated installer from GitHub Releases |
| Windows 10 | Installer | Installer from GitHub Releases configures Apache + PHP |
| macOS | Manual | Manual Apache + PHP setup required |

---

## Inputs to Collect

### Deploy Phase
No environment variables required. Configuration is via `ilibrarian.ini`:

| Setting | Default | Description |
|---------|---------|-------------|
| Storage path | /i-librarian/data | Where PDFs and metadata are stored |
| Config path | /i-librarian/config | ilibrarian.ini location |

### Volumes
| Host path | Container path | Purpose |
|-----------|---------------|---------|
| /var/www/i-librarian/data | /i-librarian/data | Library storage (PDFs, SQLite database) — must be owned by UID/GID 33 |
| /var/www/i-librarian/config | /i-librarian/config | Config file (read-only mount) |

---

## Software-Layer Concerns

### Config
- Copy `ilibrarian-default.ini` from the release archive to your config directory as `ilibrarian.ini`
- Most settings (admin email, import sources, OCR language, etc.) are configurable via the web UI after setup

### Data Directories
- /i-librarian/data — PDFs, attachments, SQLite database (must be owned by UID 33, GID 33 — the Apache www-data user)

### Ports
- 80 (internal) — serve behind a reverse proxy on 9050 or similar

---

## Docker Setup

> Note: I, Librarian does not publish a pre-built Docker image. You must build from the release archive.

```bash
# 1. Download latest release from GitHub
wget https://github.com/mkucej/i-librarian-free/releases/latest/download/I-Librarian-<version>-Linux.tar.xz

# 2. Create data directories
mkdir -p /var/www/i-librarian/data /var/www/i-librarian/config
chown -R 33:33 /var/www/i-librarian/data

# 3. Extract and copy default config
tar xf I-Librarian-<version>-Linux.tar.xz config/ilibrarian-default.ini --strip-components=1
mv ilibrarian-default.ini /var/www/i-librarian/config/ilibrarian.ini

# 4. Build Docker image from the archive
docker build -t i-librarian-free:<version> - < I-Librarian-<version>-Linux.tar.xz

# 5. Run
docker run -d --name il-free \
  -p 127.0.0.1:9050:80 \
  -v /var/www/i-librarian/data:/i-librarian/data \
  -v /var/www/i-librarian/config:/i-librarian/config:ro \
  i-librarian-free:<version>
```

Docker Compose variant:
```yaml
services:
  il-free:
    image: i-librarian-free:5.11.3
    container_name: il-free
    restart: always
    ports:
      - "127.0.0.1:9050:80"
    volumes:
      - /var/www/i-librarian/data:/i-librarian/data
      - /var/www/i-librarian/config:/i-librarian/config:ro
```

---

## Reverse Proxy (Caddy example)

```caddyfile
# Subdomain
library.example.com {
    reverse_proxy 127.0.0.1:9050
}

# Subpath
example.com {
    handle /library* {
        reverse_proxy 127.0.0.1:9050
    }
}
```

---

## Upgrade Procedure

```bash
# Download new release archive
# Rebuild the Docker image with new version tag
docker build -t i-librarian-free:<new-version> - < I-Librarian-<new-version>-Linux.tar.xz
# Update docker-compose.yml image tag and restart
docker compose up -d
```

The data and config volumes carry over unchanged.

---

## Gotchas

- **No pre-built Docker Hub image:** You must build the image yourself from the GitHub Release archive each time you upgrade — there is no `latest` tag to pull
- **Data dir must be owned by UID 33:** Apache inside the container runs as www-data (UID 33); if ownership is wrong you'll get permission errors on first run — use `chown -R 33:33`
- **Config file required before first run:** Extract `ilibrarian-default.ini` from the release archive and place it as `ilibrarian.ini` in your config directory before starting
- **OCR requires Tesseract:** Install inside the container (or use the build that includes it) for OCR on scanned PDFs; also install LibreOffice for Office document import
- **Multi-user support:** I, Librarian supports multiple user accounts with different access levels; set up via the admin UI after first login
- **First login:** Create an admin account on first access at http://your-host:9050/librarian

---

## References
- GitHub: https://github.com/mkucej/i-librarian-free
- Docker install guide: https://raw.githubusercontent.com/mkucej/i-librarian-free/HEAD/README-Docker.md
- Releases: https://github.com/mkucej/i-librarian-free/releases
