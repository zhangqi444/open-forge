---
name: not-th-re
description: not-th.re (!3) recipe for open-forge. Paste sharing platform with client-side encryption and Monaco code editor. Node.js, multi-repo (UI + API). Source: https://github.com/not-three/main
---

# not-th.re (!3)

A simple paste-sharing platform (spoken "not three", from leet speak "not3") with client-side encryption and the Monaco browser-based code editor (the same editor as VS Code). Supports syntax highlighting, file transfers, dark mode, Excalidraw integration, and a CLI tool. No cookies, no tracking. AGPL-3.0 licensed, Node.js. Upstream (main): <https://github.com/not-three/main>. Demo: <https://not-th.re>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker Compose | Official images for UI + API |
| Any Linux VPS | Node.js native | Run UI and API separately |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for the UI?" | FQDN | e.g. paste.example.com |
| "Domain or path for the API?" | FQDN or path | e.g. paste-api.example.com or paste.example.com/api |
| "Storage backend for pastes?" | local / S3 / other | Check upstream API repo for supported backends |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Max paste size limit?" | Bytes | Configurable in API |
| "Enable file transfer support?" | Yes / No | Configurable feature |

## Software-Layer Concerns

- **Multi-repo**: UI, API, CLI, SDK, and Draw (Excalidraw) are separate repos under the `not-three` GitHub org. The main repo is the meta/coordination repo.
- **Client-side encryption**: Content is encrypted in the browser before upload — the server stores only ciphertext. Decryption requires the key embedded in the share URL fragment.
- **Monaco editor**: Full VS Code editor experience in the browser — syntax highlighting for hundreds of languages.
- **CLI tool**: `npm install -g @not3/cli` provides `not3` command for scripted paste creation/retrieval.
- **No cookies, no tracking**: By design — purely stateless share links.
- **Excalidraw integration**: Draw diagrams and share them as pastes.

## Deployment

### Docker Compose

```yaml
services:
  not3-api:
    image: ghcr.io/not-three/api:latest
    ports:
      - "3000:3000"
    volumes:
      - pastes:/data
    environment:
      # Configure storage backend, limits, etc.
      # See https://github.com/not-three/api for env var reference
    restart: unless-stopped

  not3-ui:
    image: ghcr.io/not-three/ui:latest
    ports:
      - "8080:80"
    environment:
      API_URL: https://paste-api.example.com
    restart: unless-stopped

volumes:
  pastes:
```

See the upstream API repo (https://github.com/not-three/api) and UI repo (https://github.com/not-three/ui) for full environment variable references.

### CLI usage

```bash
npm install -g @not3/cli

# Save a paste
echo "hello world" | not3 save -s https://paste-api.example.com

# Retrieve a paste
not3 query <id> <seed> -s https://paste-api.example.com

# Upload a file
not3 upload myfile.txt -s https://paste-api.example.com
```

## Upgrade Procedure

1. Pull new images: `docker compose pull && docker compose up -d`
2. Check release notes for UI at https://github.com/not-three/ui/releases and API at https://github.com/not-three/api/releases

## Gotchas

- **Multi-repo coordination**: UI and API are versioned separately — check compatibility between versions before upgrading only one.
- **Share URL contains decryption key**: The URL fragment (`#key`) holds the decryption seed. Losing the full URL means losing the ability to decrypt the paste.
- **API storage backend**: Verify supported storage backends in the API repo — local filesystem is simplest; S3-compatible for cloud setups.
- **Low activity recently**: Commit history shows minimal activity in late 2025 through early 2026. Verify the project is still maintained before deploying for critical use.

## Links

- Main (meta) repo: https://github.com/not-three/main
- API repo: https://github.com/not-three/api
- UI repo: https://github.com/not-three/ui
- CLI: https://github.com/not-three/cli (npm: @not3/cli)
- Demo: https://not-th.re
