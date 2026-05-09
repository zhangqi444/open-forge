---
name: minuspod
description: Recipe for MinusPod — a self-hosted podcast server that removes ads before playback using Whisper transcription and LLM ad detection.
---

# MinusPod

Self-hosted podcast server that removes ads before you ever hit play. Transcribes episodes with Whisper, uses an LLM to detect and cut ad segments, and learns from corrections over time. Serves modified RSS feeds and processed audio to any podcast app. Upstream: https://github.com/ttlequals0/MinusPod.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host with NVIDIA GPU | Docker Compose (GPU) | Default path. Uses faster-whisper with CUDA for local transcription. Image: ttlequals0/minuspod:latest |
| Any Linux/macOS host (no GPU) | Docker Compose (CPU) | Pull ttlequals0/minuspod:cpu (~3 GB vs ~16 GB for GPU image). Local CPU transcription is slow; pair with a remote Whisper API for practical use. |
| Any host (no GPU) | Docker Compose + remote Whisper | CPU image + WHISPER_BACKEND=openai-api pointed at Groq, OpenAI, or a self-hosted whisper.cpp server. Practical for GPU-less deployments. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Do you have an NVIDIA GPU available?" | Yes/No | Determines GPU vs CPU image. |
| preflight | "What public URL will MinusPod be reachable at?" | URL | Becomes BASE_URL. Used in generated feed URLs. Example: http://192.168.1.100:8000 |
| preflight | "Which LLM provider for ad detection?" | Choice: anthropic / openrouter / ollama / openai-compatible | Determines which API key to ask for next. |
| llm | "Anthropic API key?" | Sensitive string (starts re_ or sk-ant-) | Required when LLM_PROVIDER=anthropic |
| llm | "OpenRouter API key?" | Sensitive string | Required when LLM_PROVIDER=openrouter |
| llm | "Ollama base URL?" | URL, default http://host.docker.internal:11434/v1 | Required when LLM_PROVIDER=ollama. On Linux add extra_hosts: host.docker.internal:host-gateway |
| llm | "Ollama model name?" | String, e.g. qwen3:14b | Required for Ollama (OPENAI_MODEL env var) |
| whisper | "Whisper backend — local GPU, or remote API (Groq/OpenAI/whisper.cpp)?" | Choice: local / openai-api | Determines WHISPER_BACKEND. |
| whisper | "Remote Whisper API base URL?" | URL | Only if WHISPER_BACKEND=openai-api |
| whisper | "Remote Whisper API key?" | Sensitive string | Only if WHISPER_BACKEND=openai-api and the provider requires auth |
| security | "Admin password for the web UI?" | Free-text, min 12 chars | APP_PASSWORD. Required before exposing publicly. |
| security | "Master passphrase for encrypting stored API keys?" | Free-text (long random string) | MINUSPOD_MASTER_PASSPHRASE. Strongly recommended; losing it makes stored keys unrecoverable. |
| optional | "Running behind a reverse proxy (nginx, Cloudflare, Traefik)?" | Yes/No | Set MINUSPOD_TRUSTED_PROXY_COUNT=1 if yes; otherwise login lockout and per-IP rate limits silently break. |

## Software-layer concerns

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| BASE_URL | http://localhost:8000 | Public URL for generated podcast feed links. |
| LLM_PROVIDER | anthropic | LLM backend: anthropic, openrouter, openai-compatible, ollama |
| ANTHROPIC_API_KEY | (none) | Required for LLM_PROVIDER=anthropic |
| OPENROUTER_API_KEY | (none) | Required for LLM_PROVIDER=openrouter |
| OPENAI_BASE_URL | (varies) | Base URL for OpenAI-compatible or Ollama endpoint |
| OPENAI_MODEL | (none) | Required for Ollama (e.g. qwen3:14b) |
| WHISPER_MODEL | small | Whisper model size: tiny, base, small, medium, large-v3, turbo |
| WHISPER_DEVICE | cuda | cuda or cpu. Set to cpu when using a remote Whisper API. |
| WHISPER_BACKEND | local | local (faster-whisper) or openai-api (remote HTTP) |
| WHISPER_API_BASE_URL | (none) | Base URL for remote Whisper API (Groq, OpenAI, whisper.cpp) |
| WHISPER_API_KEY | (none) | API key for remote Whisper API |
| WHISPER_API_MODEL | whisper-1 | Model name sent to remote Whisper API |
| APP_PASSWORD | (none) | Web UI admin password. Required before public exposure. Min 12 chars. |
| MINUSPOD_MASTER_PASSPHRASE | (none) | Encrypts stored provider API keys at rest with AES-256-GCM. Strongly recommended. |
| SESSION_COOKIE_SECURE | true | Set to false only when serving over plain HTTP. |
| MINUSPOD_TRUSTED_PROXY_COUNT | 0 | Number of reverse-proxy hops to trust for X-Forwarded-For. Set to 1 behind nginx/Cloudflare/Traefik. |
| DATA_DIR | /app/data | Data storage directory inside the container. |
| LOG_LEVEL | INFO | DEBUG, INFO, WARNING, or ERROR |

### Data directories

- /app/data — all application state: SQLite database (podcast.db), per-feed episode directories with cached RSS and processed audio, and backups.

### Ports

- Container port 8000 → host port 8000: web UI, REST API, and podcast feed serving

## Deploy

### GPU (NVIDIA) image

```bash
# Create data directory and .env file
mkdir -p data
cat > .env << 'EOF'
ANTHROPIC_API_KEY=your-key-here
BASE_URL=http://localhost:8000
APP_PASSWORD=your-password-12chars
MINUSPOD_MASTER_PASSPHRASE=long-random-string-keep-it-safe
EOF

docker compose up -d
```

### CPU-only image (no GPU)

```bash
docker compose -f docker-compose.cpu.yml up -d
```

The CPU image is ttlequals0/minuspod:cpu. Reuse the same .env and data/ directory. Pin a specific version with MINUSPOD_VERSION=2.0.21-cpu in .env.

### Remote Whisper API (GPU-less, fast transcription)

Add to .env:
```
WHISPER_BACKEND=openai-api
WHISPER_API_BASE_URL=https://api.groq.com/openai/v1
WHISPER_API_KEY=gsk_your_key_here
WHISPER_API_MODEL=whisper-large-v3-turbo
WHISPER_DEVICE=cpu
```

Then run the CPU image as above.

Access the web UI at http://<host>:8000/ui/ to add and manage podcast RSS feeds.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

### Upgrading to 2.0.0+ (security hardening release)

If upgrading from 1.x, review these breaking changes before pulling:

- SESSION_COOKIE_SECURE defaults to true in 2.0.0+. Set SESSION_COOKIE_SECURE=false if not on HTTPS.
- Behind a reverse proxy: set MINUSPOD_TRUSTED_PROXY_COUNT=1 or login lockout breaks.
- CSRF token required on all POST/PUT/DELETE /api/v1/* requests. The built-in UI handles this; raw curl scripts need the X-CSRF-Token header.
- API docs moved from /docs to /api/v1/docs.
- ANTHROPIC_API_KEY fallback for OpenAI-compatible providers removed. Set OPENAI_API_KEY explicitly.
- Container runs as UID 1000. First boot chowns the data volume automatically.

## Gotchas

- Master passphrase is write-once (effectively) — if lost, stored provider API keys are unrecoverable. Env-var credentials still work. Back it up separately from the database.
- SESSION_COOKIE_SECURE — defaults to true. Browsers will drop the session cookie over plain HTTP. Set to false when not using HTTPS.
- MINUSPOD_TRUSTED_PROXY_COUNT=0 behind a reverse proxy silently breaks login lockout and per-IP rate limits. Startup logs a WARN when unset and running in a container.
- GPU image is ~16 GB vs ~3 GB for CPU image — plan disk space accordingly.
- Processing is single-threaded and memory-intensive — one episode processes at a time. Large episodes may require 8–16 GB of RAM depending on length and Whisper model.
- Ollama on Linux — host.docker.internal does not resolve by default on Linux. Add to the compose service: extra_hosts: ["host.docker.internal:host-gateway"].
- Audiobookshelf SSRF — if using Audiobookshelf as a podcast client, add MinusPod's hostname/IP to SSRF_REQUEST_FILTER_WHITELIST in Audiobookshelf's config.
- LLM accuracy — most development and testing was done with Anthropic Claude models. Ollama/OpenRouter open-weights models reduce detection accuracy, especially for host-read ads.
- Pascal-generation NVIDIA GPUs (GTX 10xx) — float16 compute type is unsupported. Set WHISPER_COMPUTE_TYPE=int8 explicitly; or use the openai-api Whisper backend.

## Links

- GitHub README: https://github.com/ttlequals0/MinusPod
- Docker Hub (GPU): https://hub.docker.com/r/ttlequals0/minuspod
- API docs (once running): http://<host>:8000/api/v1/docs
