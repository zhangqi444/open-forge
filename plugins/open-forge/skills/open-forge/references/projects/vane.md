---
name: Vane
description: "Privacy-focused AI answering engine — self-hosted Perplexity alternative combining web search (SearxNG) with local or cloud LLMs to deliver cited answers without sending queries to third parties. Docker. MIT."
---

# Vane

Vane is a privacy-focused AI answering engine that runs entirely on your own hardware — a self-hosted alternative to Perplexity AI. It combines live web search (via SearxNG) with your choice of LLM (local via Ollama, or cloud providers like OpenAI/Claude/Groq) to return cited, sourced answers while keeping all searches private.

Created by ItzCrazyKns. Actively developed with strong community growth.

Use cases: (a) private AI-assisted research without sending queries to Perplexity/Google (b) home lab search assistant (c) teams that need internal AI search with data sovereignty (d) replacing Google search + ChatGPT with a single self-hosted workflow.

Features:

- **Multiple AI providers** — Ollama (local LLMs), OpenAI, Anthropic Claude, Google Gemini, Groq; mix and match models per query
- **Search modes** — Speed, Balanced, Quality; trade off latency vs depth
- **Source types** — web, discussions, academic papers
- **SearxNG integration** — privacy-respecting metasearch engine; no tracking
- **Widgets** — weather, calculations, stock prices, quick info cards
- **Image and video search** — visual results alongside text
- **File uploads** — ask questions about PDFs, text files, images
- **Domain-scoped search** — limit search to specific websites
- **Smart suggestions** — search suggestions as you type
- **Search history** — local history of all searches
- **Discover feed** — trending/interesting articles without active searching
- **Docker deployment** — compose-based; minimal setup

- Upstream repo: https://github.com/ItzCrazyKns/Vane
- Docker Hub: https://hub.docker.com/r/itzcrazykns1337/vane
- Discord: https://discord.gg/26aArMy8tT

## Architecture

- **Vane server** — Node.js backend; orchestrates search + LLM calls
- **SearxNG** — self-hosted metasearch engine (bundled in compose); handles web queries
- **LLM** — local (Ollama) or cloud API; Vane sends search results + query to LLM for synthesis
- **Database** — local storage for search history
- **No data leaves your network** — all search queries go to SearxNG → web; LLM calls go to your Ollama instance (or directly to cloud API if you configure one)

## Compatible install methods

| Infra       | Runtime         | Notes                                                        |
|-------------|-----------------|--------------------------------------------------------------|
| Docker      | docker compose  | Recommended; includes Vane + SearxNG                         |
| VPS/Server  | docker compose  | Works on any Linux with Docker                               |
| Home lab    | docker compose  | Pair with local Ollama for fully offline operation           |

## Inputs to collect

| Input          | Example                        | Phase   | Notes                                                        |
|----------------|--------------------------------|---------|--------------------------------------------------------------|
| LLM provider   | Ollama / OpenAI / Claude       | Config  | Set in `.env`; Ollama recommended for full privacy           |
| Ollama URL     | `http://host:11434`            | Config  | If using local Ollama; must be reachable from container      |
| API keys       | `OPENAI_API_KEY=...`           | Config  | Only if using cloud providers                                |
| Domain         | `search.example.com`           | URL     | Optional reverse proxy; default port 3000                    |
| SearxNG config | auto-configured                | Search  | Bundled; custom engines can be added in searxng config       |

## Install (Docker Compose)

```sh
git clone https://github.com/ItzCrazyKns/Vane.git
cd Vane

# Copy and edit environment config
cp .env.example .env
# Edit .env: set your LLM provider + API keys

docker compose up -d
```

Open `http://localhost:3000`.

See https://github.com/ItzCrazyKns/Vane for the latest compose file and configuration options.

## Environment config (.env)

```env
# LLM provider: ollama | openai | anthropic | groq | gemini
VANE_LLM_PROVIDER=ollama

# If using Ollama (recommended for privacy)
OLLAMA_API_URL=http://host.docker.internal:11434

# If using OpenAI
OPENAI_API_KEY=sk-...

# Port
PORT=3000
```

## Data & config layout

- **`.env`** — LLM provider config, API keys, port
- **SearxNG config** — `searxng/settings.yml`; controls enabled search engines, rate limiting
- **Search history** — stored locally in container volume; persists across restarts
- **No cloud dependency** — all data stays local if using Ollama

## Upgrade

```sh
cd Vane
git pull
docker compose pull
docker compose up -d
```

## Gotchas

- **SearxNG rate limiting** — public search engines (Google, Bing, etc.) rate-limit scrapers. SearxNG manages this, but heavy usage on a single IP can trigger CAPTCHAs/blocks. Consider configuring SearxNG to use multiple search engines and enabling a request delay.
- **Ollama must be reachable from Docker** — if Ollama runs on the host, use `host.docker.internal` (macOS/Windows Docker Desktop) or the host's LAN IP (Linux). `localhost` inside the container refers to the container, not the host.
- **Cloud LLM providers = privacy tradeoff** — using OpenAI/Claude means queries and search results are sent to those providers. For full privacy, use Ollama with a local model.
- **Model quality affects answer quality** — small models (3B–7B) may hallucinate more when synthesizing search results. Llama-3 8B or Mistral 7B+ are reasonable local choices; larger models give better results.
- **Search results are as good as SearxNG results** — in regions where Google/Bing return thin results, Vane's answers will reflect that. Academic and discussion search modes often give better depth than web mode for research topics.
- **Active development = frequent breaking changes** — Vane moves fast. After updates, check the CHANGELOG or Discord for migration notes.
- **Alternatives:** Perplexica (similar self-hosted Perplexity clone, older), SearxNG standalone (search without AI synthesis), OpenWebUI (LLM interface without live search), Khoj (knowledge base + web search AI assistant).

## Links

- Repo: https://github.com/ItzCrazyKns/Vane
- Docker Hub: https://hub.docker.com/r/itzcrazykns1337/vane
- Discord: https://discord.gg/26aArMy8tT
- Architecture docs: https://github.com/ItzCrazyKns/Vane/tree/master/docs/architecture/README.md
