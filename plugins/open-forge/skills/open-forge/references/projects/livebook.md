---
name: Livebook
description: "Interactive, collaborative code notebooks for Elixir — Jupyter-like experience backed by BEAM/OTP. Reproducible .livemd (Markdown) format, Smart cells, real-time multi-user editing, rich Kino widgets (charts, tables, maps), embedded databases. By Dashbit + Elixir core team. Apache-2.0."
---

# Livebook

Livebook is **Elixir's answer to Jupyter/Observable** — interactive, collaborative code notebooks backed by the BEAM VM. Notebooks are `.livemd` files (a Markdown superset with code cells, Mermaid diagrams, KaTeX math) — **plain-text, git-friendly, diffable**. Elixir code runs in isolated BEAM runtimes; **Smart cells** provide high-level UI-driven tasks (database queries, chart building, map plotting) that generate readable Elixir code. Created by **José Valim** (Elixir's creator) and maintained at **Dashbit**.

**Why notable:**

- **Reproducible** — Livebook tracks cell dependencies + stale state; ensures deterministic execution
- **Collaborative** — multi-user real-time editing out of the box
- **Decentralized** — run anywhere; "Run in Livebook" badges import from URL
- **Self-contained runtime** — spins up a BEAM node per notebook; isolated
- **Rich outputs via Kino** — charts (Vega-Lite), tables, maps, input forms, audio, video
- **Mix integration** — notebooks can be attached to existing Elixir projects, accessing all modules + deps
- **ML use case** — Livebook + Nx / Bumblebee / Axon is the canonical Elixir ML stack (Hugging Face models, LLM chat, embeddings, training)
- **Database dashboards** — Smart cells query Postgres/MySQL/SQLite + auto-generate Ecto code
- **Teaching tool** — widely used to teach Elixir

- Upstream repo: <https://github.com/livebook-dev/livebook>
- Website: <https://livebook.dev>
- Docs (HexDocs): <https://hexdocs.pm/livebook>
- Install: <https://livebook.dev/#install>
- Integrations: <https://livebook.dev/integrations/>
- Kino (widget library): <https://github.com/livebook-dev/kino>
- Blog: <https://news.livebook.dev>

## Architecture in one minute

- **Elixir / Phoenix LiveView** web app (one of LiveView's flagship showcases)
- **Notebook = `.livemd` file** — Markdown + Elixir code + Smart cells + outputs (outputs not stored by default)
- **Runtime = ephemeral BEAM node** per notebook (or attached to existing Elixir Mix project / k8s runtime / Fly.io runtime)
- **Collaboration** via LiveView + OT — multi-cursor editing, real-time cell execution visible to all
- **No persistent DB** for Livebook itself — notebooks are files on disk (or S3, remote fs)
- **Resource**: Livebook server itself is small (~300 MB RAM); per-notebook runtimes each run a BEAM node (100s MB-GBs depending on workload)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Desktop           | **Livebook Desktop app** (macOS / Windows / Linux)                 | **Best for local/personal use**                                                     |
| Single VM          | **Docker** (`ghcr.io/livebook-dev/livebook`)                               | **Upstream-recommended for server deployment**                                                 |
| Kubernetes         | Official Helm / manifests                                                                   | Built-in multi-tenant runtime support                                                                      |
| Fly.io             | First-class — deploy with `fly launch`                                                                      | Very smooth                                                                                                             |
| Hugging Face Spaces | Official integration — deploy notebooks as HF Spaces                                                                       | For ML demos                                                                                                                                        |
| Escript / Mix      | `mix escript.install hex livebook`                                                                                                      | From source                                                                                                                                                              |

## Inputs to collect

| Input                  | Example                              | Phase     | Notes                                                                   |
| ---------------------- | ------------------------------------ | --------- | ----------------------------------------------------------------------- |
| Domain                 | `livebook.example.com`                   | URL       | TLS reverse proxy                                                               |
| Password               | Livebook uses password auth                   | Auth      | Single shared password OR OIDC (teams edition)                                                                   |
| Data dir               | `/data` (notebooks storage)                             | Storage   | Where `.livemd` files live                                                                                  |
| Runtime                | Elixir version                                                   | Runtime   | Livebook auto-manages embedded runtimes                                                                                                       |
| Admin token (auth)     | `LIVEBOOK_PASSWORD` env                                                  | Security  | Required for hosted deployments                                                                                                                              |

## Install via Docker

```yaml
services:
  livebook:
    image: ghcr.io/livebook-dev/livebook:latest       # pin in prod
    environment:
      LIVEBOOK_PASSWORD: CHANGE_ME_MIN_12_CHARS
      LIVEBOOK_HOME: /data
      LIVEBOOK_ROOT_PATH: /data
    volumes:
      - ./data:/data
    ports:
      - "8080:8080"
      - "8081:8081"                                    # runtime cluster port
    restart: unless-stopped
```

Browse `http://<host>:8080/` → enter password → you're in.

## Install via Desktop app

Download from <https://livebook.dev/#install> — packages for macOS/Windows/Linux (snap). Double-click; launches local Livebook + browser.

## First boot

1. Open Livebook → enter password
2. "New notebook" → starts a fresh BEAM runtime
3. Write Markdown + code cells
4. Install deps via **`Mix.install([:kino, :vega_lite, :explorer, ...])`** in the first cell — auto-fetched from Hex
5. Try a Smart cell: "Database connection" → point at your Postgres → generate query cell
6. Save notebook → it's a `.livemd` file on disk
7. Commit to git — notebook is diff-friendly Markdown

## Data & config layout

- Notebooks = `.livemd` files in `LIVEBOOK_HOME` (or anywhere on disk)
- `.livemd` files are **Markdown with YAML-like sections**; self-contained (code + outputs optional)
- Livebook state is ephemeral — restart = clean slate (apart from notebook files)
- No DB to back up; **backup = backup your `.livemd` files (git is ideal)**

## Backup

```sh
# Notebooks (the actual data)
tar czf livebook-$(date +%F).tgz data/
# Or better: git init && git push to a remote
```

**Best practice: keep `.livemd` in git.** Livebook's design assumes VCS-backed notebooks.

## Upgrade

1. Releases: <https://github.com/livebook-dev/livebook/releases>. Very active; aligned with Elixir releases.
2. Docker: bump tag → restart. No data migration (notebooks are files).
3. Desktop app: auto-update prompts.
4. **Elixir version compat**: check changelog — Livebook tracks current + one-back Elixir.

## Gotchas

- **Elixir-only.** If your team doesn't know Elixir, Livebook is a steep curve. Jupyter + Python is more universal.
- **Smart cells require Kino** (`Mix.install([:kino])`) — automatic but first cell adds 10-30s "fetching deps."
- **Runtime is ephemeral** — killing a notebook's runtime loses in-memory state. For long computations, **persist results to disk** (e.g., S3, file).
- **Authentication**: default is single shared password via `LIVEBOOK_PASSWORD`. For teams, use **Livebook Teams** (commercial) with OIDC + shared secrets + deployment.
- **Exposing to internet**: Livebook is an **Elixir code executor** — anyone with access can run arbitrary code on your server. **Treat Livebook URL like SSH: VPN + auth + TLS**. Never public without strong auth.
- **Sandboxing**: runtimes are isolated BEAM nodes, not OS-level sandboxes. Malicious code can still consume resources, read files Livebook can read. For untrusted users → separate containers per user.
- **Port requirements**: 8080 (HTTP) + 8081 (runtime cluster) — both must be accessible if runtimes are remote.
- **Large datasets**: Explorer (DataFrames) + Nx work well, but remember BEAM VM's memory model — GC per-process + copies on process sends. Native tensors via Nx/EXLA escape some of this.
- **Hugging Face / LLM use**: Bumblebee + GPU notebook running Llama-3 / Mistral / phi — works beautifully but needs GPU-enabled runtime (Livebook → Fly.io / modal / custom GPU VM).
- **Collaboration conflicts**: real-time editing is OT-based; rare conflicts on simultaneous edits but handled.
- **`.livemd` vs `.ipynb`**: `.livemd` is Markdown (diff-friendly, human-readable); `.ipynb` is JSON (harder to diff, often committed with output blobs).
- **Outputs not saved by default** — re-run to regenerate. This keeps files clean + prevents committing sensitive outputs.
- **Livebook Teams (commercial)** — adds multi-user auth, shared app deployments, secrets management, audit logs. SaaS + self-hosted options.
- **Use case: internal dashboards** — Livebook apps = notebooks published as LiveView web apps for stakeholders (no code required to use). Killer feature for Elixir shops.
- **Mix into existing project**: `livebook server --cookie ... --sname ...` attaches Livebook to your running Mix app — read/debug a production-like runtime.
- **License**: **Apache-2.0**.
- **Commercial**: Livebook Teams by Dashbit. <https://livebook.dev/teams>.
- **Alternatives worth knowing:**
  - **Jupyter / JupyterLab** — Python + many kernels; dominant in data science (separate recipe likely)
  - **Observable / Observable Framework** — JS reactive notebooks
  - **Quarto** — multi-lang; Rmarkdown successor
  - **Marimo** — reactive Python notebooks
  - **Deepnote / Hex / Noteable** — SaaS collaborative notebooks
  - **Zeppelin** — Spark-focused
  - **Pluto.jl** — reactive Julia notebooks
  - **Choose Livebook if:** Elixir/Phoenix stack + reactive execution + great collab + want git-friendly notebooks.
  - **Choose Jupyter if:** Python/R/Julia + broader ecosystem.
  - **Choose Observable/Marimo if:** reactive + modern UI.
  - **Choose Pluto if:** Julia.

## Links

- Repo: <https://github.com/livebook-dev/livebook>
- Website: <https://livebook.dev>
- Install: <https://livebook.dev/#install>
- HexDocs: <https://hexdocs.pm/livebook>
- Kino: <https://github.com/livebook-dev/kino>
- Integrations: <https://livebook.dev/integrations/>
- Blog: <https://news.livebook.dev>
- Releases: <https://github.com/livebook-dev/livebook/releases>
- Docker (GHCR): <https://github.com/livebook-dev/livebook/pkgs/container/livebook>
- Livebook Teams (commercial): <https://livebook.dev/teams>
- Dashbit (steward): <https://dashbit.co>
- Nx / Bumblebee / Axon (Elixir ML): <https://github.com/elixir-nx>
- Jupyter (alt): <https://jupyter.org>
- Marimo (alt, reactive Python): <https://marimo.io>
- Pluto.jl (alt, Julia): <https://github.com/fonsp/Pluto.jl>
