---
name: LibreTranslate
description: "Free, self-hosted machine translation API — translate text between 30+ languages using open-source Argos Translate models, with no dependency on Google or Microsoft. Python/Docker. AGPL-3.0."
---

# LibreTranslate

LibreTranslate is a free, open-source machine translation API that runs entirely on your own server. It uses [Argos Translate](https://github.com/argosopentech/argos-translate) as its translation engine — no Google Translate, no Microsoft Azure, no vendor lock-in.

Provides a REST API compatible with many apps that support translation API endpoints. A web UI is included.

Use cases: (a) self-hosted translation API for apps, scripts, and pipelines (b) replacing Google Translate API or DeepL with a privacy-preserving alternative (c) offline/air-gapped translation (d) integration into content management, customer support, or localization workflows (e) translation in sensitive environments where sending text to cloud APIs is prohibited.

Features:

- **30+ language pairs** — English, Spanish, French, German, Chinese, Arabic, Russian, Japanese, Portuguese, and more
- **REST API** — simple POST endpoint; JSON in/out; drop-in replacement for some translation API clients
- **Web UI** — built-in browser interface for manual translation
- **Language detection** — auto-detect source language
- **Batch translation** — translate multiple strings in one request
- **API key support** — optional rate-limiting and access control per key
- **Docker-first** — official Docker image; one-command deploy
- **Offline capable** — once models are downloaded, no internet required
- **Language model downloads** — models downloaded on first use or pre-configured

- Upstream repo: https://github.com/LibreTranslate/LibreTranslate
- Homepage: https://libretranslate.com/
- API docs: https://docs.libretranslate.com/
- Demo: https://libretranslate.com/

## Architecture

- **Python** — Flask-based API server
- **Argos Translate** — underlying ML translation models (CTranslate2-based)
- **Language models** — downloaded separately per language pair (~100–300 MB each)
- **No database required** — stateless API; language models stored on disk
- **Optional Redis** — for rate limiting with API keys
- **Docker** — official image; recommended deployment method

## Compatible install methods

| Infra       | Runtime              | Notes                                                       |
|-------------|----------------------|-------------------------------------------------------------|
| Docker      | `libretranslate/libretranslate` | Recommended; models downloaded on first start     |
| Python      | `pip install libretranslate`   | Direct install; Python 3.8+                       |
| Docker Compose | with nginx reverse proxy    | Standard production pattern                       |
| Kubernetes  | Helm or custom pod             | CPU-only is fine for moderate load                |
| Offline     | Pre-download models into image | For air-gapped deployments                        |

## Inputs to collect

| Input            | Example                    | Phase    | Notes                                                      |
|------------------|----------------------------|----------|------------------------------------------------------------|
| Languages        | `en,es,fr,de,zh`           | Config   | Only download models for languages you need                |
| API key (opt)    | any string                 | Config   | Enable with `--api-keys`; required for public installs     |
| Port             | `5000`                     | Config   | Default port                                               |
| Suggestions (opt)| `--suggestions`            | Config   | Allow users to submit translation corrections              |

## Quick start (Docker)

```sh
docker run -ti --rm \
  -p 5000:5000 \
  -e LT_LOAD_ONLY=en,es,fr,de \
  libretranslate/libretranslate
```

Open `http://localhost:5000` for the web UI.

**First run downloads language models** — allow several minutes per language pair (~100–300 MB each).

## Docker Compose

```yaml
services:
  libretranslate:
    image: libretranslate/libretranslate:latest
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      - LT_LOAD_ONLY=en,es,fr,de,zh,ja,pt,ru,ar
      - LT_API_KEYS=true
    volumes:
      - lt-data:/home/libretranslate/.local/share

volumes:
  lt-data:
```

## API usage

```bash
# Translate text
curl -X POST http://localhost:5000/translate \
  -H "Content-Type: application/json" \
  -d '{"q": "Hello, world!", "source": "en", "target": "es"}'
# → {"translatedText": "¡Hola Mundo!"}

# Auto-detect source language
curl -X POST http://localhost:5000/translate \
  -d '{"q": "Bonjour", "source": "auto", "target": "en"}'

# Detect language only
curl -X POST http://localhost:5000/detect \
  -d '{"q": "Wie geht es dir?"}'
# → [{"confidence": 0.99, "language": "de"}]

# List supported languages
curl http://localhost:5000/languages
```

## Config options (environment variables / CLI flags)

| Flag / Env var       | Default   | Description                                              |
|----------------------|-----------|----------------------------------------------------------|
| `LT_LOAD_ONLY`       | all       | Comma-separated language codes to load (saves memory/disk)|
| `LT_API_KEYS`        | false     | Enable API key requirement                               |
| `LT_API_KEYS_DB_PATH`| in-memory | Path to API keys SQLite DB                               |
| `LT_CHAR_LIMIT`      | unlimited | Max characters per request                               |
| `LT_REQ_LIMIT`       | unlimited | Max requests per minute per client                       |
| `LT_HOST`            | `0.0.0.0` | Bind address                                             |
| `LT_PORT`            | `5000`    | Listen port                                              |
| `LT_SSL`             | false     | Enable HTTPS (use reverse proxy instead)                 |
| `LT_SUGGESTIONS`     | false     | Allow translation correction submissions                 |

## Data & config layout

- **Language models** — `~/.local/share/argos-translate/` (inside container); mount as volume for persistence
- **API keys DB** — SQLite file (if `--api-keys` enabled); mount as volume
- **No other persistent state**

## Upgrade

```sh
docker pull libretranslate/libretranslate:latest
docker compose up -d
# Models persist in named volume; no re-download needed
```

## Gotchas

- **Translation quality is not DeepL/Google quality** — Argos Translate models are smaller and less accurate than large commercial models. Quality is good for many use cases (draft translations, UI strings, support ticket routing) but not publication-ready without human review.
- **Memory per language pair** — each language model uses ~200–400 MB RAM. Loading all 30+ languages requires 6–12 GB RAM. Use `LT_LOAD_ONLY` to limit to only the languages you actually need.
- **First-run model download** — on first start, models are downloaded from the internet. For offline/air-gapped deployments, pre-build a Docker image with models baked in, or pre-populate the models volume.
- **English-centric** — many language pairs route through English (e.g., Spanish → Chinese may go via English internally). Quality of non-English-to-non-English pairs is lower than English-to-X pairs.
- **AGPL-3.0 license** — if you modify LibreTranslate and offer it as a network service, you must release modifications under AGPL-3.0.
- **Rate limiting requires Redis** — built-in rate limiting is basic; for production with API keys and proper per-key limits, add Redis.
- **No document translation** — LibreTranslate translates text strings via API. There's no built-in PDF/DOCX document translation. For document translation, use the API programmatically per paragraph, or look at LibreOffice + translation macros.
- **Alternatives:** DeepL API (high quality, free tier, SaaS), Google Cloud Translation (SaaS), Argos Translate standalone (Python library, no HTTP server), Lingva Translate (frontend for other engines), Bergamot (browser-based offline translation, Mozilla project).

## Links

- Repo: https://github.com/LibreTranslate/LibreTranslate
- Homepage: https://libretranslate.com/
- API docs: https://docs.libretranslate.com/
- Argos Translate (engine): https://github.com/argosopentech/argos-translate
- Docker Hub: https://hub.docker.com/r/libretranslate/libretranslate
- Community forum: https://community.libretranslate.com/
- Supported languages: https://libretranslate.com/languages
