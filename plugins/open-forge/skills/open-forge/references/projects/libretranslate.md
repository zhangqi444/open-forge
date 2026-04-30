---
name: LibreTranslate
description: Free, fully self-hosted machine translation API. Argos Translate under the hood (offline neural models). HTTP API compatible with many translation-related clients. AGPL-3.0.
---

# LibreTranslate

LibreTranslate is a "DeepL / Google Translate without leaving your infrastructure" — HTTP API for text + document translation, backed by [Argos Translate](https://github.com/argosopentech/argos-translate) (offline OpenNMT neural models). No external API calls, no data sent to Google / Microsoft / OpenAI. Optional API-key gating, rate limits, and a simple web UI for manual translation.

50+ language pairs, quality varies by pair (EN↔ES/FR/DE is excellent; less-common pairs are rougher than the commercial services).

- Upstream repo: <https://github.com/LibreTranslate/LibreTranslate>
- Docs: <https://docs.libretranslate.com>
- Community forum: <https://community.libretranslate.com/>
- Public instance: <https://libretranslate.com> (rate-limited free tier + paid API)
- Argos Translate (engine): <https://github.com/argosopentech/argos-translate>

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                              |
| ----------- | ------------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | Docker (`libretranslate/libretranslate:latest`)         | **Recommended.** CPU-only, ~2 GB RAM + ~5 GB disk for models         |
| Single VM (GPU) | Docker (`libretranslate/libretranslate:latest-cuda`) | NVIDIA-only; significantly faster for high-volume workloads         |
| Single VM   | `pip install libretranslate && libretranslate`         | Python 3.9+; upstream publishes as PyPI package                    |
| Kubernetes  | Plain Deployment + PVC for models                      | Stateless; parallel replicas work fine                              |
| Managed     | libretranslate.com (commercial)                         | SaaS at the same URL as the public demo                             |

## Inputs to collect

| Input                    | Example                                      | Phase     | Notes                                                             |
| ------------------------ | -------------------------------------------- | --------- | ----------------------------------------------------------------- |
| Port                     | `5000:5000`                                  | Network   | HTTP listen                                                        |
| `LT_LOAD_ONLY`           | `en,fr,es,de`                                | Runtime   | Restricts loaded language pairs — saves **lots** of RAM + startup time |
| `LT_API_KEYS`            | `true` / `false`                             | Security  | Off by default; public instance = bot-flood risk                   |
| `LT_API_KEYS_DB_PATH`    | `/app/db/api_keys.db`                        | Data      | SQLite of API keys + rate limits                                   |
| `LT_REQ_LIMIT`           | `120`                                        | Security  | Requests per minute per IP                                         |
| `LT_CHAR_LIMIT`          | `500`                                        | Security  | Max chars per request; use for public endpoints                    |
| `LT_UPDATE_MODELS`       | `true` / `false`                             | Runtime   | Download updated Argos models on start                             |
| `LT_SECRET_MANAGEMENT_USERNAME` / `LT_SECRET_MANAGEMENT_PASSWORD` | admin creds | Admin | Gates the `/manage` UI for API key + stats |
| Data volume              | `/app/db` + `/home/libretranslate/.local`    | Data      | API keys DB + downloaded models                                    |
| GPU                      | NVIDIA w/ Container Toolkit (optional)       | Hardware  | Required only for `-cuda` tag                                      |

## Install via Docker Compose

From <https://github.com/LibreTranslate/LibreTranslate/blob/main/docker-compose.yml>:

```yaml
services:
  libretranslate:
    container_name: libretranslate
    image: libretranslate/libretranslate:latest    # pin to a release tag in prod
    ports:
      - "5000:5000"
    restart: unless-stopped
    healthcheck:
      test: ['CMD-SHELL', './venv/bin/python scripts/healthcheck.py']
      interval: 10s
      timeout: 4s
      retries: 4
      start_period: 5s
    environment:
      - LT_API_KEYS=true
      - LT_API_KEYS_DB_PATH=/app/db/api_keys.db
      - LT_UPDATE_MODELS=true
      - LT_LOAD_ONLY=en,fr,es,de     # only load these language pairs
    volumes:
      - libretranslate_api_keys:/app/db
      - libretranslate_models:/home/libretranslate/.local:rw

volumes:
  libretranslate_api_keys:
  libretranslate_models:
```

### Quick `docker run`

```sh
docker run -it --rm --name libretranslate \
  -p 5000:5000 \
  -v libretranslate_models:/home/libretranslate/.local \
  libretranslate/libretranslate:latest
```

First start downloads language models (~500 MB per pair); watch the logs. Browse `http://<host>:5000` for the web UI.

### GPU variant (NVIDIA CUDA)

From `docker-compose.cuda.yml`:

```yaml
services:
  libretranslate:
    image: libretranslate/libretranslate:latest-cuda
    ports: ["5000:5000"]
    restart: unless-stopped
    command: --disable-web-ui
    environment:
      - LT_API_KEYS=true
      - LT_API_KEYS_DB_PATH=/app/db/api_keys.db
      - LT_UPDATE_MODELS=true
    volumes:
      - ./db:/app/db
      - ./data:/root/.local:rw
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Prereq: [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) + `sudo nvidia-ctk runtime configure --runtime=docker`.

## API usage

```sh
# Detect language
curl -X POST http://localhost:5000/detect \
  -H "Content-Type: application/json" \
  -d '{"q": "Ciao, come stai?"}'
# [{"confidence": 98.6, "language": "it"}]

# Translate
curl -X POST http://localhost:5000/translate \
  -H "Content-Type: application/json" \
  -d '{"q": "Hello world", "source": "en", "target": "fr", "format": "text"}'
# {"translatedText": "Bonjour le monde"}

# With API key (if LT_API_KEYS=true)
curl -X POST http://localhost:5000/translate \
  -H "Content-Type: application/json" \
  -d '{"q": "Hello", "source": "en", "target": "fr", "api_key": "..."}'
```

API reference: <https://libretranslate.com/docs/>.

## Data & config layout

Inside the container:

- `/home/libretranslate/.local/share/argos-translate/packages/` — downloaded .argosmodel files (per-language-pair ~500 MB)
- `/app/db/api_keys.db` — SQLite of API keys, per-key rate limits, usage counts
- `/app/static/` — web UI assets
- `/app/config.json` (optional; can mount) — global config overrides

## Backup

```sh
# API keys DB (tiny)
docker cp libretranslate:/app/db/api_keys.db ./lt-api-keys-$(date +%F).db

# Models (large; re-downloadable, so optional backup)
docker run --rm -v libretranslate_models:/src -v "$PWD":/backup alpine \
  tar czf /backup/lt-models-$(date +%F).tgz -C /src .
```

Models are re-downloadable from Argos's public mirror — only back them up if you want to avoid the bandwidth / time of re-fetching.

## Upgrade

1. Releases: <https://github.com/LibreTranslate/LibreTranslate/releases>.
2. Docker: `docker compose pull && docker compose up -d`.
3. `LT_UPDATE_MODELS=true` triggers Argos model updates on startup; safe to leave on.
4. **Major version bumps** may change the API or default rate limits; read release notes.
5. Models can be updated independently from the code via the web UI's `/manage` panel (admin).

## Gotchas

- **Default install has NO rate limit or API-key protection.** Public-internet LibreTranslate on default settings = bot-flood instantly. Set `LT_API_KEYS=true` + `LT_REQ_LIMIT=60` (or lower) BEFORE exposing.
- **Loading all languages = RAM explosion.** Without `LT_LOAD_ONLY`, LibreTranslate loads every available language pair at startup. On a modest VPS, this OOMs or takes 10+ minutes. Always restrict to the pairs you need.
- **Model download on first boot is 500 MB+ per pair.** On slow connections, first start can take an hour. `LT_UPDATE_MODELS=true` blocks until done; set a long `start_period` in healthcheck.
- **GPU variant (`latest-cuda`) skips the Python healthcheck.** Upstream Dockerfile comment: *"./venv/bin/python is not implemented in the cuda docker yet"*. Use an HTTP healthcheck instead: `curl -f http://localhost:5000/languages`.
- **Quality varies wildly by language pair.** EN↔ES/FR/DE/IT/PT are production-grade. EN↔AR/HE/RU are decent. Small-corpus pairs (EN↔IS/MT/SI) are noticeably worse than commercial APIs.
- **Character limit `LT_CHAR_LIMIT=500`** is a hard per-request cap. Larger chunks = 400 error. Clients should chunk long documents.
- **File translation endpoint** (`/translate_file`) supports .docx, .txt, .html, .odt. Large files are processed synchronously — request timeouts matter.
- **Secret management UI at `/manage`** — requires `LT_SECRET_MANAGEMENT_USERNAME` + `LT_SECRET_MANAGEMENT_PASSWORD`. Set these; otherwise anyone can create API keys.
- **Health endpoint** is `GET /languages` — returns the list of loaded pairs. Fast, no translation cost.
- **Disable web UI in production** with `--disable-web-ui` or `LT_DISABLE_WEB_UI=true` if you only need the API.
- **CORS defaults to allow all origins.** Restrict with `LT_CORS_ORIGIN=https://your-app.example.com` for browser-side API usage.
- **No caching.** Repeated translations hit the model every time. Put a cache (Varnish / Redis) in front for high-volume use.
- **Multi-GPU / multi-worker** requires running multiple instances + a load balancer — single-process LibreTranslate binds one GPU.
- **Argos Translate models are neural, not rule-based.** They're non-deterministic across CPUs; same input + same model on different hardware can produce slightly different output.
- **AGPL-3.0 network copyleft.** Running a modified LibreTranslate as a SaaS requires offering source.
- **Alternatives worth knowing:**
  - **DeepL API** — commercial, best quality for EU languages
  - **NLLB-200 + vLLM / Ollama** — Meta's 200-language NLLB model; self-hostable, heavier
  - **Argos Translate CLI** — same engine, no HTTP wrapper (embed in your own app)
  - **Marian NMT** — raw framework if you want to train your own models

## Links

- Repo: <https://github.com/LibreTranslate/LibreTranslate>
- Docs: <https://docs.libretranslate.com>
- API reference: <https://libretranslate.com/docs/>
- Docker Hub: <https://hub.docker.com/r/libretranslate/libretranslate>
- Docker docs: <https://docs.libretranslate.com/guides/installation/>
- Arguments reference: <https://docs.libretranslate.com/guides/installation/#arguments>
- Argos Translate: <https://github.com/argosopentech/argos-translate>
- Releases: <https://github.com/LibreTranslate/LibreTranslate/releases>
- Community forum: <https://community.libretranslate.com/>
- Commercial hosting: <https://libretranslate.com>
