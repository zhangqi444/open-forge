---
name: gobookmarks
description: gobookmarks recipe for open-forge. Self-hosted personal start/landing page that renders bookmarks from a Git-backed plaintext file. Go + Docker. Source: https://github.com/arran4/gobookmarks
---

# gobookmarks

A self-hosted personal landing page / start page that renders bookmarks from a simple plaintext file stored in Git (GitHub, GitLab, local Git, or SQL). Supports visual drag-and-drop editing, full-text search with keyboard navigation, multiple auth providers (database, GitHub OAuth, GitLab OAuth, local Git), and multi-page/tab layouts. AGPL-3.0 licensed, written in Go. Upstream: <https://github.com/arran4/gobookmarks>

## Compatible Combos

| Infra | Runtime | Auth backend | Notes |
|---|---|---|---|
| Any Linux VPS | Docker Compose | Local Git | Fully self-hosted; no third-party OAuth needed |
| Any Linux VPS | Docker Compose | GitHub OAuth | Bookmarks stored in a GitHub repo |
| Any Linux VPS | Docker Compose | GitLab OAuth | Bookmarks stored in a GitLab repo |
| Any Linux VPS | Docker Compose | Database | Username/password auth, SQL storage |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for gobookmarks?" | FQDN or localhost | e.g. start.example.com |
| "Which auth/storage backend?" | local-git / github / gitlab / database | Drives OAuth and storage config |
| "External URL?" | URL | Used in OAuth redirect URIs |

### Phase 2 — Deploy (varies by backend)

| Prompt | Format | Notes |
|---|---|---|
| "GitHub OAuth client ID + secret?" | strings | If using GitHub auth — create at github.com/settings/developers |
| "GitLab OAuth client ID + secret?" | strings | If using GitLab auth |
| "Local Git path?" | Directory path | Where bookmark files are stored locally |
| "Favicon cache directory?" | Directory path | Persistent dir for cached favicons |

## Software-Layer Concerns

- **Git-backed bookmarks**: Bookmark data is stored in a plaintext file committed to a Git repo — full history, no lock-in.
- **Visual + text editing**: Drag-and-drop reordering via visual editor, or bulk-edit in the full-text editor.
- **EXTERNAL_URL required**: Must be set correctly for OAuth redirect callbacks to work.
- **Volumes**: Two persistent volumes needed — cache (favicons) and db (local Git repo / SQL data).
- **Multi-backend**: Each auth/storage backend has its own env vars. Check upstream README for the full env var list per backend.
- **Favicon caching**: Fetches and caches favicons for bookmarked sites — the cache dir should be persistent.

## Deployment

### Docker Compose (local Git backend)

```yaml
services:
  gobookmarks:
    image: ghcr.io/arran4/gobookmarks:latest
    ports:
      - "8080:8080"
    volumes:
      - cache:/var/cache/gobookmarks
      - db:/var/lib/gobookmarks
    environment:
      EXTERNAL_URL: "http://localhost:8080"
      FAVICON_CACHE_DIR: /var/cache/gobookmarks/favcache
      LOCAL_GIT_PATH: /var/lib/gobookmarks/localgit
    restart: unless-stopped

volumes:
  cache:
  db:
```

### Docker Compose (GitHub OAuth backend)

```yaml
services:
  gobookmarks:
    image: ghcr.io/arran4/gobookmarks:latest
    ports:
      - "8080:8080"
    volumes:
      - cache:/var/cache/gobookmarks
      - db:/var/lib/gobookmarks
    environment:
      EXTERNAL_URL: "https://start.example.com"
      GITHUB_CLIENT_ID: your-github-client-id
      GITHUB_SECRET: your-github-secret
      FAVICON_CACHE_DIR: /var/cache/gobookmarks/favcache
    restart: unless-stopped

volumes:
  cache:
  db:
```

Create OAuth app at https://github.com/settings/developers — callback URL: `https://start.example.com/auth/github/callback`

## Upgrade Procedure

1. Pull new image: `docker compose pull && docker compose up -d`
2. Both volumes (cache and db) persist through upgrades.
3. Check release notes at https://github.com/arran4/gobookmarks/releases

## Gotchas

- **EXTERNAL_URL must be exact**: OAuth callbacks will fail if the URL doesn't match what's registered with GitHub/GitLab.
- **GitHub auth = GitHub-hosted bookmarks**: Using GitHub OAuth means your bookmarks live in a GitHub repo. Useful for sync across devices but requires internet access.
- **Local Git path**: On first run with local Git, gobookmarks initialises a new Git repo at LOCAL_GIT_PATH. Backup this directory.
- **Favicon cache**: Can grow over time — the cache dir is persistent but safe to clear if storage is a concern (will re-fetch on next visit).
- **Config file alternative**: Instead of env vars, you can mount a `config.json` and `gobookmarks.env` — see upstream README for format.

## Links

- Source: https://github.com/arran4/gobookmarks
- Releases: https://github.com/arran4/gobookmarks/releases
- Docker image: ghcr.io/arran4/gobookmarks
