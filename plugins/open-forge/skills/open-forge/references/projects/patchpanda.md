# PatchPanda

A self-hosted Docker Compose stack update manager built with .NET 10 and Blazor Server. Scans your running Docker Compose projects, monitors GitHub releases for new versions, reads release notes, detects breaking changes, and lets you review and apply updates — one at a time or in bulk. Edits your actual compose/.env files and runs `docker compose pull && up -d`, so you stay in control. Optional AI summarisation (Ollama) and security scanning. Portainer integration available.

> ⚠️ **Beta software:** PatchPanda does not cover all edge cases. Always have backups before using any automated update tool.

- **GitHub:** https://github.com/dkorecko/PatchPanda
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux Docker host | Docker Compose | Mounts Docker socket + compose directories |
| Windows Docker host | Docker Compose | Windows path variant for volume mounts |

---

## Inputs to Collect

### Required environment variables
| Variable | Required | Description |
|----------|----------|-------------|
| BASE_URL | Yes | Public URL of PatchPanda (e.g. http://localhost:5093); used in notifications |
| GITHUB_USERNAME | Yes | GitHub username for API calls |
| GITHUB_PASSWORD | Yes | GitHub Personal Access Token (PAT) — avoids rate limiting |

### Optional environment variables
| Variable | Description |
|----------|-------------|
| DISCORD_WEBHOOK_URL | Discord webhook for new-version notifications |
| APPRISE_API_URL | Apprise API URL for multi-service notifications |
| APPRISE_NOTIFICATION_URLS | Comma-separated Apprise notification URLs |
| OLLAMA_URL | Ollama/compatible LLM API URL for AI summaries and breaking change detection |
| OLLAMA_MODEL | Model name for AI summarisation |
| OLLAMA_NUM_CTX | Context size for AI (default: 32768) |
| PORTAINER_URL | Portainer API URL to include Portainer-managed stacks |
| PORTAINER_ACCESS_TOKEN | Portainer API token |
| PORTAINER_IGNORE_SSL | Set true for self-signed Portainer certificates |

### Volumes (critical)
| Mount | Required | Description |
|-------|----------|-------------|
| /var/run/docker.sock:/var/run/docker.sock:rw | Yes | Docker socket for container discovery |
| /srv/www:/srv/www:rw | Yes | **Host path must match container path** — directory containing your compose stacks |

---

## Software-Layer Concerns

### Config
- All configuration via environment variables
- SQLite database stored in /app/data (persist this)

### Architecture
- Single .NET 10 Blazor Server container
- Reads Docker socket to discover running compose projects
- Reads/writes compose files and .env files directly on the host filesystem

### Ports
- 5093 — Web UI

### Critical: Compose files path matching
PatchPanda mounts your compose directories and edits them in-place. The container path **must match the host path** (e.g. if stacks are at `/srv/www/myapp/compose.yml` on the host, mount `/srv/www:/srv/www` so the container path is identical). This ensures edited files are written to the right host locations.

---

## Example docker-compose.yml

```yaml
services:
  patchpanda:
    image: ghcr.io/dkorecko/patchpanda:latest
    container_name: patchpanda
    ports:
      - "5093:5093"
    environment:
      - BASE_URL=http://localhost:5093
      - GITHUB_USERNAME=your-github-username
      - GITHUB_PASSWORD=your-github-pat
      # - DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
      # - OLLAMA_URL=http://ollama:11434
      # - OLLAMA_MODEL=llama3
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - /srv/www:/srv/www:rw   # adjust to your stacks directory
      - ./data:/app/data
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull patchpanda
docker compose up -d patchpanda
```

---

## Gotchas

- **GitHub credentials are mandatory:** Without a GitHub PAT, PatchPanda hits rate limits immediately and cannot fetch release data; create a fine-grained PAT with read-only public repo access
- **Container path must equal host path:** If your stacks live at `/srv/www` on the host, mount it as `/srv/www:/srv/www` — not `/srv/www:/app/stacks`; PatchPanda writes back to the path it discovered the file at
- **Beta — do not use unattended on critical production:** Review the update plan shown in the UI before applying; PatchPanda shows a diff of what will change before executing
- **Rollback on failure:** If an update fails, PatchPanda attempts to revert; check the update history page for stdout/stderr of each operation
- **Automatic updates (optional):** Enable in Settings to auto-apply non-breaking updates after a configurable delay — off by default
- **AI features require Ollama:** Set OLLAMA_URL to enable AI-powered release note summarisation and security scanning (code diff analysis for malicious changes)
- **Breaking change detection is heuristic:** PatchPanda uses release note keywords and optional AI analysis; it is not a guarantee — always read release notes for critical services

---

## References
- GitHub: https://github.com/dkorecko/PatchPanda
- README (full env var list): https://raw.githubusercontent.com/dkorecko/PatchPanda/HEAD/README.md
