---
name: Datasette
description: Publish SQLite databases as interactive, explorable websites + JSON APIs. Built for data journalists, archivists, researchers. Python + SQLite. Apache-2.0.
---

# Datasette

Datasette (by Simon Willison, co-creator of Django) is a tool that takes a SQLite database file and instantly serves it as a browsable website with a JSON API. Think: "GitHub Pages for datasets" — point it at a `.db` file and get a shareable, paginated, searchable, graphable, API-enabled web interface for free.

Target users:

- **Data journalists** publishing datasets alongside stories
- **Museum curators + archivists** sharing collections
- **Local government** publishing open data
- **Scientists + researchers** sharing data underlying papers
- **Anyone** with a SQLite DB they want to explore + share

Features:

- **Browse tables** — pagination, sort, facet (filter by column values)
- **Full-text search** — if your SQLite has FTS tables
- **SQL console** — run arbitrary `SELECT` from the browser (read-only; can be disabled)
- **Every row has a URL** — permalink any record
- **JSON API for everything** — `?_format=json` on any page
- **CSV + YAML + Atom feed** export
- **Plugins** — ~100 plugins on <https://datasette.io/plugins> (auth, visualization, editing, import, geospatial, LLMs)
- **Deploy to Heroku / Cloud Run / Vercel / Fly / Railway** with one command (`datasette publish`)
- **Lightweight** — a few MB, runs on Raspberry Pi, Python 3.8+

- Upstream repo: <https://github.com/simonw/datasette>
- Website: <https://datasette.io>
- Docs: <https://docs.datasette.io/>
- Plugin directory: <https://datasette.io/plugins>
- Tool ecosystem: <https://datasette.io/tools>
- Demo: <https://datasette.io/global-power-plants/global-power-plants>

## Architecture in one minute

- **Python + Starlette** ASGI app
- **SQLite** (zero or more `.db` files served)
- Loads DBs **read-only by default** — great for publishing archival data
- Optional **write-enabled** mode via `datasette-rows-edit` plugin or similar
- Port `8001` by default
- **Plugins** extend everything: authentication, visualization, data mutation, LLM chat over data

## Compatible install methods

| Infra            | Runtime                                             | Notes                                                                    |
| ---------------- | --------------------------------------------------- | ------------------------------------------------------------------------ |
| Local / dev      | `pip install datasette` + `datasette serve file.db` | **Canonical**                                                              |
| Local / dev      | `brew install datasette`                             | macOS Homebrew                                                             |
| Single VM        | Docker (`datasetteproject/datasette`)               | For prod-ish deploys                                                       |
| Local / dev      | Desktop app `datasette-desktop` (macOS)              | Electron wrapper; drag-and-drop .db files                                   |
| Cloud / PaaS     | `datasette publish heroku/cloudrun/vercel/fly`       | One-line deploy of a DB                                                    |
| Kubernetes       | Any Python deployment                                  | Stateless-ish; mount DBs as ConfigMaps / PVCs                                |
| JupyterHub       | `datasette-jupyter` plugin                            | Notebook integration                                                         |

## Inputs to collect

| Input                | Example                              | Phase     | Notes                                                        |
| -------------------- | ------------------------------------ | --------- | ------------------------------------------------------------ |
| SQLite DB file(s)    | `data.db`                             | Data      | One or many, read-only by default                              |
| `metadata.json`      | title, license, source, column units   | Data      | Displayed in footer + JSON API                                  |
| Plugins              | list per requirement                   | Features  | `pip install datasette-<plugin>`                                |
| Port                 | `8001`                                 | Network   | Default                                                          |
| Static assets (opt.) | custom CSS / templates                 | Branding  | Via `--static` / `--template-dir`                                |
| Auth (opt.)          | token-based or OAuth plugin            | Security  | Plugins: `datasette-auth-passwords`, `datasette-auth-github`      |
| CORS (opt.)          | `--cors`                               | Integration | For embedding in other sites                                     |

## Install via pip (local)

```sh
pip install datasette

# or: pipx install datasette (isolated)

datasette serve path/to/data.db
# → http://localhost:8001
```

## Install via Docker

```sh
docker run -p 8001:8001 \
  -v $(pwd)/data:/mnt \
  datasetteproject/datasette \
  datasette -h 0.0.0.0 /mnt/data.db
```

## Install via Docker Compose

```yaml
services:
  datasette:
    image: datasetteproject/datasette:0.65.2    # pin
    container_name: datasette
    restart: unless-stopped
    command: >
      datasette -h 0.0.0.0 -p 8001
      /data/main.db
      -m /config/metadata.json
      --cors
    ports:
      - "8001:8001"
    volumes:
      - ./data:/data:ro
      - ./config/metadata.json:/config/metadata.json:ro
```

## Useful plugins

```sh
pip install datasette-dashboards        # dashboard pages
pip install datasette-vega              # chart rendering
pip install datasette-graphql           # GraphQL API
pip install datasette-auth-passwords    # password auth
pip install datasette-cluster-map       # geospatial pins
pip install datasette-write             # web-based data entry
pip install datasette-copyable          # copy data to clipboard
pip install datasette-render-images     # render binary image columns
```

Browse all at <https://datasette.io/plugins>.

## Deploy to cloud (one-liner)

```sh
# Heroku
datasette publish heroku data.db --name=my-dataset

# Google Cloud Run
datasette publish cloudrun data.db --service=my-dataset

# Fly.io
datasette publish fly data.db --app=my-dataset

# Vercel
datasette publish vercel data.db --project=my-dataset --token=<TOKEN>
```

Each target builds a Docker image containing your DB + Datasette and deploys it.

## metadata.json example

```json
{
  "title": "Five Thirty Eight Data",
  "description": "Data backing articles on fivethirtyeight.com",
  "license": "CC Attribution 4.0 License",
  "license_url": "http://creativecommons.org/licenses/by/4.0/",
  "source": "fivethirtyeight/data on GitHub",
  "source_url": "https://github.com/fivethirtyeight/data",
  "databases": {
    "main": {
      "tables": {
        "polls": {
          "title": "Polling data",
          "description": "Historical polling results",
          "units": {
            "pct": "%"
          }
        }
      }
    }
  }
}
```

## Data & config layout

- **SQLite DB file(s)** — external; you provide
- **`metadata.json`** — titles, licenses, descriptions
- **`plugins/`** directory OR `settings.json` for plugin config
- **`--static` dir** — your own static assets
- Datasette itself is stateless — **you can regenerate the whole deploy from the DB file + metadata**

## Backup

```sh
# Source DB backup
sqlite3 data.db ".backup data-$(date +%F).db"

# Or VACUUM INTO for consistency
sqlite3 data.db "VACUUM INTO 'data-$(date +%F).db'"
```

SQLite's `.backup` is online/hot. Datasette doesn't hold long locks in read-only mode.

## Upgrade

1. Releases: <https://docs.datasette.io/en/latest/changelog.html>. Frequent (weekly-ish).
2. `pip install -U datasette` or `docker pull datasetteproject/datasette`.
3. Datasette is backward-compatible; plugins occasionally need updates on major versions.
4. **Datasette 1.0 is in active development** — API stabilization in progress; current stable is 0.6x.

## Gotchas

- **Read-only by default** — Datasette's assumption is "publish data"; it doesn't offer a native editing UI out of the box. For write workflows, use `datasette-write` plugin or [Datasette Studio](https://github.com/datasette/datasette-studio).
- **SQL injection exposure** — if you enable arbitrary-SQL queries (the `/:db` page lets users run `SELECT`), that's a public read-only SQL console. Fine for public data; **disable with `--setting allow_sql 0`** for private/authenticated datasets.
- **Not for large DBs** — SQLite is fine up to ~100 GB, but UI performance on big tables depends on indexing. Add indexes to columns you'll facet/filter on.
- **Full-text search** requires an FTS table in your SQLite — Datasette doesn't auto-create it. Use `sqlite-utils enable-fts table col1 col2` (from the `sqlite-utils` companion tool).
- **`datasette publish`** deploys your DB file **as part of the Docker image** — not a separate volume. Re-deploy to update data. For dynamic data, don't use this pattern.
- **Authentication is plugin-based** — no built-in login. `datasette-auth-passwords`, `datasette-auth-github`, `datasette-auth-tokens` are common choices.
- **Plugins sandbox = nothing, really.** Plugin code runs with Datasette's full privileges. Review before installing.
- **Datasette + JupyterLab** pair well for exploratory data work — Datasette for sharing, Jupyter for cleaning.
- **SQLite limitations** are Datasette's limitations — no native multi-writer concurrency, limited JSON queries vs Postgres, etc. For huge live data, use Postgres-backed tools; for archived/published data, SQLite + Datasette is ideal.
- **CORS** enabled with `--cors` lets cross-origin JavaScript fetch your Datasette API. For public datasets, turn it on. For private, keep off.
- **AI features** — several plugins integrate LLMs for "ask questions about your data in English" (`datasette-llm`, `datasette-enrichments`, `datasette-ask-reddit`). Datasette is a darling of the LLM-data-tools community.
- **`sqlite-utils`** is the companion CLI tool (also by Simon Willison) — transform CSVs, enrich data, apply migrations. Install alongside.
- **Datasette.cloud** (hosted SaaS by Simon Willison Labs) — run-your-own-Datasette-as-a-service, in alpha/closed beta.
- **Apache 2.0 license** — permissive.
- **Alternatives worth knowing:**
  - **Grist** — spreadsheet-database hybrid, editable; complementary (see separate recipe)
  - **Apache Superset** — BI dashboards, not publishing-focused
  - **Metabase** — same category as Superset
  - **Retool / Appsmith** — internal-tool builders
  - **Observable / Hex / Streamlit / Dash / Shiny** — notebook-style data apps
  - **CKAN** — government open-data portal (heavier)
  - **NocoDB / Baserow** — Airtable-likes (see other recipes)
  - Choose Datasette if you want **publish + explore + API** for read-only datasets; choose Grist for **edit + collaborate on live data**.

## Links

- Repo: <https://github.com/simonw/datasette>
- Website: <https://datasette.io>
- Docs: <https://docs.datasette.io/>
- Changelog: <https://docs.datasette.io/en/latest/changelog.html>
- Plugins: <https://datasette.io/plugins>
- Tools: <https://datasette.io/tools>
- `sqlite-utils` companion: <https://sqlite-utils.datasette.io/>
- `datasette publish` docs: <https://docs.datasette.io/en/stable/publish.html>
- Docker Hub: <https://hub.docker.com/r/datasetteproject/datasette>
- Newsletter: <https://datasette.substack.com/>
- Discord: <https://datasette.io/discord>
- Simon's blog (extensive Datasette content): <https://simonwillison.net/tags/datasette/>
