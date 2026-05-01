# Jelu

**Self-hosted personal book tracker — your own Goodreads replacement. Track read, reading, and to-read lists with metadata from online sources, Goodreads import, ISBN scanning, reviews, stats, and multi-user support.**
Docs: https://bayang.github.io/jelu-web/
GitHub: https://github.com/bayang/jelu
Discord: https://discord.gg/3RZJ4zuMP5

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — includes fetch-ebook-metadata |
| Any Linux | Java JAR | Spring fat jar, no container needed |
| Kubernetes | Helm | Unofficial chart on ArtifactHub |

---

## Inputs to Collect

### Required
- Paths for config, database, images, and imports (host volumes)

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  jelu:
    image: wabayang/jelu
    container_name: jelu
    volumes:
      - ~/jelu/config:/config
      - ~/jelu/database:/database
      - ~/jelu/files/images:/files/images
      - ~/jelu/files/imports:/files/imports
      - /etc/timezone:/etc/timezone:ro
    ports:
      - 11111:11111
    restart: unless-stopped
```

The Docker image includes `fetch-ebook-metadata` (calibre tool) for automatic book metadata import by title, author, or ISBN.

### Ports
- `11111` — web UI

### Data
- Single-file SQLite database at the mapped `/database` path — portable and easy to back up

### Key features
- Track read/reading/to-read with history by year and month
- Import from Goodreads (CSV export) or list of ISBNs
- Export data to CSV
- Auto-import metadata (title, author, ISBN search)
- Tagging for custom shelves
- Author pages with Wikipedia auto-import
- Book embed code snippets (for blogs, Markdown notes)
- Reading statistics
- Multi-user with LDAP and proxy authentication
- REST API
- Reviews (shareable; see other users' reviews)
- Metadata from epub/opf files
- ISBN scanning via camera on mobile
- Fallback metadata providers (configurable)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- All data (database) is in a single SQLite file — back up the `/database` volume regularly
- Metadata auto-import requires internet access; calibre's `fetch-ebook-metadata` is bundled in Docker image
- Config can be customized via `application.yml` in the `/config` volume

---

## References
- Documentation: https://bayang.github.io/jelu-web/
- GitHub: https://github.com/bayang/jelu#readme
- Discord: https://discord.gg/3RZJ4zuMP5
