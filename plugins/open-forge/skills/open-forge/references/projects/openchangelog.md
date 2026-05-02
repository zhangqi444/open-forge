# Openchangelog

**What it is:** Renders Markdown changelog files (from a local directory or GitHub) into a beautiful, searchable changelog website. Supports keep-a-changelog format, one-file-per-release, full-text search, password protection, analytics, dark/light/system themes, automatic RSS feed, colorful tags, and Next.js embed. Has a managed cloud option; easily self-hostable with a single Docker container.

**Official URL:** https://github.com/JonasHiltl/openchangelog  
**Website:** https://openchangelog.com  
**Docs:** https://openchangelog.com/docs/  
**Demo:** https://demo.openchangelog.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | Docker run | Single container |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | Config file path | `openchangelog.yml` bound to `/etc/openchangelog.yml` |
| Deploy | Release notes directory | Mounted at `/release-notes` inside container |
| Deploy | Host port | Default `6001` |
| Config | Changelog source | Local directory or GitHub repo (configured in `openchangelog.yml`) |
| Optional | Password | Enable password protection in config |
| Optional | Analytics | Configure in `openchangelog.yml` |

---

## Software-Layer Concerns

### Docker image
```
ghcr.io/jonashiltl/openchangelog:0.7.2
```
(Pin to a released tag; check https://github.com/JonasHiltl/openchangelog/releases for latest.)

### docker run (quickstart)
```bash
docker run \
  -v ./openchangelog.yml:/etc/openchangelog.yml:ro \
  -v ./release-notes:/release-notes \
  -p 6001:6001 \
  ghcr.io/jonashiltl/openchangelog:0.7.2
```

### docker-compose.yml
```yaml
services:
  openchangelog:
    image: "ghcr.io/jonashiltl/openchangelog:0.7.2"
    ports:
      - "6001:6001"
    volumes:
      - ./release-notes:/release-notes
      - type: bind
        source: openchangelog.yml
        target: /etc/openchangelog.yml
    restart: unless-stopped
```

### Configuration file (`openchangelog.yml`)
Copy from `openchangelog.example.yml` in the repo and configure for your source:
- **Local files**: point to `/release-notes` directory
- **GitHub**: provide repo owner/name and optional token for private repos

Full config reference: https://openchangelog.com/docs/getting-started/self-hosting/#configuration

### Release notes format
Supports two formats:
- Single `CHANGELOG.md` following [keep a changelog](https://keepachangelog.com/en/1.1.0/) convention
- One Markdown file per release in a directory

---

## Upgrade Procedure

```bash
# Update image tag in docker-compose.yml
docker compose pull
docker compose up -d
```

No stateful database — changelog source files are external. No migration needed.

---

## Gotchas

- **Config file must exist before starting** — Openchangelog will fail to start if `openchangelog.yml` is missing or not mounted
- **Local files source** — when using local files, the release-notes directory must be mounted and non-empty; an empty directory renders a blank changelog
- **GitHub source** — for private repos, supply a GitHub token in the config; public repos work without a token but may hit rate limits
- **Pinned image tag recommended** — tag `0.7.2` shown in docs; check releases for newer stable tags

---

## Links

- GitHub: https://github.com/JonasHiltl/openchangelog
- Documentation: https://openchangelog.com/docs/
- Self-hosting guide: https://openchangelog.com/docs/getting-started/self-hosting/
- Demo: https://demo.openchangelog.com
