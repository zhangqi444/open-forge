---
name: ChartDB
description: Open-source, web-based database diagram editor. Client-side SPA — no backend, no account, uses a single "smart query" to import schemas from PostgreSQL/MySQL/MSSQL/MariaDB/SQLite/CockroachDB/ClickHouse.
---

# ChartDB

ChartDB is a Vite + React **static single-page app** that runs entirely in the browser. You point it at your own database by running a read-only "smart query" ChartDB gives you; you paste the JSON result back into the UI; ChartDB renders an editable ER diagram. Optionally, it can talk to an OpenAI-compatible endpoint to generate DDL in a different SQL dialect (migration helper).

- Upstream repo: <https://github.com/chartdb/chartdb>
- Image: `ghcr.io/chartdb/chartdb`
- Hosted demo: <https://app.chartdb.io>
- License: AGPL-3.0

## Architecture in one minute

- No server component. The Docker image is nginx serving a Vite build.
- "Self-hosting" means hosting a static bundle you control instead of using `app.chartdb.io`.
- Your schema data never leaves the browser unless you enable the AI feature, in which case the browser posts to the OpenAI-compatible endpoint you configured.
- There is no database persistence; diagrams are stored in the browser's `localStorage`. Use the Export feature to save to a `.chartdb` file or SQL.

## Compatible install methods

| Infra           | Runtime                       | Notes                                                                        |
| --------------- | ----------------------------- | ---------------------------------------------------------------------------- |
| Any host / K8s  | Docker (`ghcr.io/chartdb/chartdb`) | Recommended; single container, nginx under the hood                      |
| Static hosting  | Build locally, upload `dist/` to Netlify / Cloudflare Pages / S3+CF | `npm run build`; no server code to run                 |
| Dev             | `npm install && npm run dev`  | Vite dev server, hot reload                                                   |

## Inputs to collect

| Input                      | Example                                   | Phase   | Notes                                                                                |
| -------------------------- | ----------------------------------------- | ------- | ------------------------------------------------------------------------------------ |
| Listen port                | `8080` (maps to container 80)             | Runtime | nginx port inside                                                                     |
| `OPENAI_API_KEY` (optional) | `sk-...`                                 | Runtime | Only needed for AI DDL generation; alternatively use a local inference server         |
| `OPENAI_API_ENDPOINT` (optional) | `http://ollama:11434/v1`             | Runtime | Use with a self-hosted OpenAI-compatible endpoint (Ollama, vLLM, LM Studio)           |
| `LLM_MODEL_NAME` (optional) | `qwen2.5-coder:32b`                      | Runtime | Model id when using a custom endpoint                                                 |
| `DISABLE_ANALYTICS`        | `true`                                    | Runtime | Disables Fathom Analytics ping                                                        |
| `HIDE_CHARTDB_CLOUD`       | `true`                                    | Runtime | Hide "Try cloud" UI affordances                                                       |

All runtime env vars are consumed by `entrypoint.sh` via `envsubst` into `/etc/nginx/conf.d/default.conf` before nginx starts (see <https://github.com/chartdb/chartdb/blob/main/entrypoint.sh>).

## Install via Docker

Single-container quick start (verbatim from the README, with the image pinned and analytics disabled):

```sh
docker run -d --name chartdb \
  -p 8080:80 \
  -e DISABLE_ANALYTICS=true \
  -e HIDE_CHARTDB_CLOUD=true \
  --restart unless-stopped \
  ghcr.io/chartdb/chartdb:1.10.0
```

Track versions at <https://github.com/chartdb/chartdb/releases>. Check the `ghcr.io/chartdb/chartdb` package page for the exact tag list.

### With AI enabled (OpenAI)

```sh
docker run -d --name chartdb \
  -p 8080:80 \
  -e OPENAI_API_KEY=sk-... \
  -e DISABLE_ANALYTICS=true \
  ghcr.io/chartdb/chartdb:1.10.0
```

### With a local LLM (Ollama / vLLM / LM Studio)

The key is rebuilding the image with `VITE_` build args, **not** runtime env — the endpoint URL is baked into the frontend bundle at build time:

```sh
git clone https://github.com/chartdb/chartdb.git
cd chartdb
docker build \
  --build-arg VITE_OPENAI_API_ENDPOINT=http://ollama.lan:11434/v1 \
  --build-arg VITE_LLM_MODEL_NAME=qwen2.5-coder:32b \
  --build-arg VITE_DISABLE_ANALYTICS=true \
  -t chartdb:custom .

docker run -d -p 8080:80 \
  -e OPENAI_API_ENDPOINT=http://ollama.lan:11434/v1 \
  -e LLM_MODEL_NAME=qwen2.5-coder:32b \
  chartdb:custom
```

### Compose

```yaml
services:
  chartdb:
    image: ghcr.io/chartdb/chartdb:1.10.0
    container_name: chartdb
    restart: unless-stopped
    ports:
      - 8080:80
    environment:
      - DISABLE_ANALYTICS=true
      - HIDE_CHARTDB_CLOUD=true
```

## Data & config layout

- No volumes, no database, no uploads dir.
- Diagrams persist to the browser's `localStorage` per origin.
- Export via File → Save (downloads `.chartdb` JSON) for durable backup.
- nginx config is generated from `default.conf.template` at start via `envsubst`.

## Upgrade

1. Bump the image tag. Check <https://github.com/chartdb/chartdb/releases>.
2. `docker compose pull && docker compose up -d`.
3. Hard-refresh the browser (or bump a cache-busting query) — old JS may be cached.
4. **Before upgrading**, export any diagrams you care about; upgrades don't migrate localStorage schema automatically.

## Gotchas

- **localStorage is your only storage.** Clearing site data, switching browsers, or serving ChartDB on a new hostname loses every saved diagram. Export early, export often.
- **Browser private/incognito mode** often disables or wipes localStorage on tab close — expected, but catches people off guard.
- **AI endpoint is baked at build time**, not runtime — for self-hosted LLMs you must rebuild the image (the runtime `OPENAI_API_ENDPOINT` only overrides what the server sends in the nginx-injected config, and the frontend still reads the build-time fallback).
- **Analytics on by default** — set `DISABLE_ANALYTICS=true` if you care about the Fathom ping.
- **Schema import is read-only from the user's DB.** The "smart query" is a SELECT-only introspection query; ChartDB never connects to your DB — *your browser / DB client* does.
- **No auth.** Anyone who can reach the URL can use it. If that matters, put it behind an auth-aware reverse proxy.
- **CORS for custom LLMs.** If your LLM endpoint isn't same-origin, make sure it sends `Access-Control-Allow-Origin` — the browser does the fetch directly.
- **`:latest` image floats.** Pin for reproducibility; the release cadence is fast (multiple minors per month).
- **AGPL.** If you modify ChartDB and serve it to users over a network, you must offer source.

## Links

- Repo: <https://github.com/chartdb/chartdb>
- Dockerfile + entrypoint: <https://github.com/chartdb/chartdb/blob/main/Dockerfile>, <https://github.com/chartdb/chartdb/blob/main/entrypoint.sh>
- Releases: <https://github.com/chartdb/chartdb/releases>
- Container registry: <https://github.com/chartdb/chartdb/pkgs/container/chartdb>
- Templates + docs: <https://chartdb.io/>
