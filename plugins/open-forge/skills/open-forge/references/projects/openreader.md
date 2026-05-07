---
name: openreader
description: OpenReader recipe for open-forge. Self-hosted text-to-speech document reader. EPUB, PDF, DOCX, MD, TXT → read-aloud with synchronized playback and word highlighting. Multi-provider TTS, audiobook export, library sync. Docker. Source: https://github.com/richardr1126/openreader
---

# OpenReader

Self-hosted text-to-speech document reader for EPUB, PDF, DOCX, MD, and TXT files. Reads documents aloud with synchronized read-along playback (sentence-aware for PDF/EPUB), optional word-by-word highlighting via `whisper.cpp` timestamps, and multi-provider TTS support. Can export audiobooks in `m4b`/`mp3` with chapter tracking. Embedded SeaweedFS object storage or external S3-compatible backend. Docker. MIT licensed.

Formerly named **OpenReader-WebUI**.

Upstream: <https://github.com/richardr1126/openreader> | Docs: <https://docs.openreader.richardr.dev>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (single container) | Recommended |
| Any | Vercel | Cloud deploy option |
| Any | TTS sidecar | Run Kokoro-FastAPI / KittenTTS-FastAPI locally for offline TTS |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | TTS provider reachable | Required: Kokoro-FastAPI, KittenTTS, OpenAI, Replicate, DeepInfra, or equivalent |
| config | API_BASE | TTS server base URL, e.g. http://host.docker.internal:8880/v1 |
| config | API_KEY | TTS API key (`none` for local Kokoro/KittenTTS) |
| config | BASE_URL | Public URL of OpenReader, e.g. http://localhost:3003 (enables auth when set with AUTH_SECRET) |
| config (optional) | AUTH_SECRET | Random secret to enable auth (`openssl rand -hex 32`) |
| config (optional) | Library path | Host path to mount as read-only server library |
| infra | Port 3003 | Web UI |
| infra | Port 8333 | Embedded SeaweedFS (for direct presigned browser uploads/downloads) |

## Software-layer concerns

### Auth

Auth is enabled only when **both** `BASE_URL` and `AUTH_SECRET` are set. Omit either to disable auth.

### Storage

- **Embedded SeaweedFS** (default) — bundled in container, no external deps; pins to version 4.18 (4.19+ has upload bugs)
- **External S3** — configure via env vars; see https://docs.openreader.richardr.dev/configure/object-blob-storage

### Env vars (key)

| Var | Description |
|---|---|
| API_BASE | TTS endpoint base URL |
| API_KEY | TTS API key |
| BASE_URL | App public URL (enables auth when combined with AUTH_SECRET) |
| AUTH_SECRET | Random secret for auth sessions |
| AUTH_TRUSTED_ORIGINS | Comma-separated trusted origins for LAN access |
| USE_ANONYMOUS_AUTH_SESSIONS | Allow anonymous sessions (true/false) |

### Data dirs

| Mount | Description |
|---|---|
| `/app/docstore` | Persistent document storage (SeaweedFS data + SQLite DB) |
| `/app/docstore/library:ro` | Optional read-only server library folder |

## Install — Docker (minimal, ephemeral)

```bash
docker run --name openreader \
  --restart unless-stopped \
  -p 3003:3003 \
  -p 8333:8333 \
  ghcr.io/richardr1126/openreader:latest
```

## Install — Docker (persistent + auth)

```bash
docker run --name openreader \
  --restart unless-stopped \
  -p 3003:3003 \
  -p 8333:8333 \
  -v openreader_docstore:/app/docstore \
  -v /path/to/your/library:/app/docstore/library:ro \
  -e API_BASE=http://host.docker.internal:8880/v1 \
  -e API_KEY=none \
  -e BASE_URL=http://localhost:3003 \
  -e AUTH_SECRET=$(openssl rand -hex 32) \
  ghcr.io/richardr1126/openreader:latest
```

## Install — LAN access

```bash
docker run --name openreader \
  --restart unless-stopped \
  -p 3003:3003 \
  -p 8333:8333 \
  -v openreader_docstore:/app/docstore \
  -e API_BASE=http://host.docker.internal:8880/v1 \
  -e BASE_URL=http://<YOUR_LAN_IP>:3003 \
  -e AUTH_SECRET=$(openssl rand -hex 32) \
  -e AUTH_TRUSTED_ORIGINS=http://localhost:3003,http://127.0.0.1:3003 \
  -e USE_ANONYMOUS_AUTH_SESSIONS=true \
  ghcr.io/richardr1126/openreader:latest
```

## Running local TTS (Kokoro-FastAPI)

```bash
# Run Kokoro locally (GPU recommended, CPU works)
# See: https://docs.openreader.richardr.dev/configure/tts-provider-guides/kokoro-fastapi
docker run -d --name kokoro -p 8880:8880 ghcr.io/remsky/kokoro-fastapi-cpu:latest

# Then set API_BASE=http://host.docker.internal:8880/v1, API_KEY=none
```

## Upgrade procedure

```bash
docker stop openreader && docker rm openreader
docker image rm ghcr.io/richardr1126/openreader:latest
docker pull ghcr.io/richardr1126/openreader:latest
# Re-run your docker run command — data in /app/docstore volume is preserved
# DB migrations run automatically on container startup
```

## Gotchas

- **TTS provider required before setup** — OpenReader does not bundle a TTS engine. You must have a TTS server running and reachable before the app is useful. Kokoro-FastAPI is a popular free local option.
- Auth is opt-in — set both `BASE_URL` and `AUTH_SECRET` to enable it. Without these, anyone with network access can use the app.
- SeaweedFS is pinned to 4.18 — the upstream notes that 4.19+ has intermittent S3 upload bugs in this app's upload flow. Don't override the bundled version.
- Port 8333 (SeaweedFS): if the browser can't reach port 8333 directly, uploads fall back to the `/api/documents/blob/upload/fallback` route — slower but functional.
- DB and storage migrations run automatically at container startup — no manual migration steps needed.

## Links

- Source: https://github.com/richardr1126/openreader
- Documentation: https://docs.openreader.richardr.dev
- TTS providers guide: https://docs.openreader.richardr.dev/configure/tts-providers
- Kokoro-FastAPI (local TTS): https://docs.openreader.richardr.dev/configure/tts-provider-guides/kokoro-fastapi
