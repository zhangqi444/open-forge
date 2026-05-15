# Wiki-Go (LeoMoon Wiki-Go)

**What it is:** Modern, databaseless flat-file wiki platform built with Go. No database required — content stored as Markdown files. Features full-text search, version history, user management, Kanban boards, Mermaid diagrams, LaTeX math, link management, comments, and private wiki mode.

**Official site / Demo:** https://wikigo.leomoon.com  
**GitHub:** https://github.com/leomoon-studios/wiki-go

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container |
| Raspberry Pi / ARM | Docker | Multi-arch support |
| Any Linux | Binary | Pre-built binaries on GitHub releases |
| Windows / macOS | Binary | Cross-platform builds |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Data directory | Where wiki content (Markdown files) is stored |
| Config file | `config.yaml` — timezone, auth, settings |
| Host port | Port to expose the wiki UI |

### Phase: Configure (`config.yaml`)

| Setting | Description |
|---------|-------------|
| `allow_insecure_cookies` | Set `true` for HTTP-only setups (no HTTPS) — required to fix login on non-SSL |
| Admin credentials | Set in config or on first run |
| Private wiki mode | Restrict access to authenticated users only |

---

## Software-Layer Concerns

- **No external database** — all content stored as flat Markdown files; back up the data directory
- **Version history** — tracked per document via internal versioning; full revision restore supported
- **`allow_insecure_cookies: true`** is required for HTTP-only (non-HTTPS) setups — browsers reject `Secure` cookies over HTTP; only use in trusted internal networks
- **Hierarchical content** — documents organized in nested directories; sidebar order controlled by slug names (alphabetical)
- **File attachments** — supported types: jpg, jpeg, png, gif, svg, txt, log, csv, zip, pdf, docx, xlsx, pptx, mp4

### Feature summary

| Feature | Notes |
|---------|-------|
| Markdown + emoji | Full Markdown with emoji shortcodes |
| Mermaid diagrams | Render diagrams in Markdown |
| LaTeX math | Math rendering in pages |
| Full-text search | Smart search with highlighting and filters |
| Version history | Per-document revision tracking and restore |
| User management | Multi-user with access control |
| Private wiki mode | Restrict to authenticated users |
| Kanban boards | Interactive boards per page |
| Link management | Organize links with auto-metadata fetch |
| Comments | Per-page comments with moderation |

---

## Example Docker Compose

```yaml
services:
  wiki-go:
    image: ghcr.io/leomoon-studios/wiki-go:v1.8.9
    container_name: wiki-go
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
      - ./config.yaml:/app/config.yaml
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Content files persist in mounted data volume

---

## Gotchas

- **HTTP login broken without `allow_insecure_cookies: true`** — browsers silently reject Secure cookies over HTTP; set this in `config.yaml` for non-HTTPS setups
- Sidebar document order is alphabetical by directory slug, not by title — name directories accordingly
- No built-in HTTPS — use a reverse proxy (Caddy, Nginx, Traefik) for public deployments
- Pre-built Docker image may lag behind binary releases — check GitHub releases for latest

---

## Links

- Demo / Website: https://wikigo.leomoon.com
- GitHub: https://github.com/leomoon-studios/wiki-go
- Releases: https://github.com/leomoon-studios/wiki-go/releases
