# Khoj

AI second brain and personal assistant. Khoj lets you search and chat with your personal notes, documents, and the web using AI. Supports multiple LLM providers (OpenAI, Gemini, Anthropic) or local models via Ollama. Features document indexing, web search, code execution (via sandbox), and an optional computer-use agent. Self-hosted version is fully featured.

**Official site:** https://khoj.dev  
**Source:** https://github.com/khoj-ai/khoj  
**Upstream docs:** https://docs.khoj.dev  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |
| macOS / Linux | pip install | Python package for local installs |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `KHOJ_DOMAIN` | Externally accessible domain or IP (no prefix) | `khoj.example.com` or `192.168.1.10` |

### LLM provider (choose one or more)
| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | OpenAI API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `ANTHROPIC_API_KEY` | Anthropic Claude API key |
| `OPENAI_BASE_URL` | Ollama or custom OpenAI-compatible base URL |
| `KHOJ_DEFAULT_CHAT_MODEL` | Default model slug (e.g., `qwen3` for Ollama) |

### Optional
| Variable | Description | Default |
|----------|-------------|---------|
| `KHOJ_TELEMETRY_DISABLE` | Disable usage telemetry | unset |
| `KHOJ_NO_HTTPS` | Disable HTTPS enforcement | unset |
| `KHOJ_OPERATOR_ENABLED` | Enable computer-use agent | unset |
| `SERPER_DEV_API_KEY` | Web search via Serper | unset |
| `FIRECRAWL_API_KEY` | Web search + scraping via Firecrawl | unset |

---

## Software-Layer Concerns

### Services (docker-compose.yml)
| Service | Image | Role |
|---------|-------|------|
| `server` | `ghcr.io/khoj-ai/khoj:latest` | Main Khoj server |
| `database` | `pgvector/pgvector:pg15` | PostgreSQL with vector extension |
| `sandbox` | `ghcr.io/khoj-ai/terrarium:latest` | Isolated code execution |
| `search` | `searxng/searxng:latest` | Local web search (optional) |
| `computer` | `ghcr.io/khoj-ai/khoj-computer:latest` | Computer-use agent (optional) |

### Docker Compose quick start
```sh
git clone https://github.com/khoj-ai/khoj.git
cd khoj
# Edit docker-compose.yml: uncomment KHOJ_DOMAIN and LLM provider keys
docker compose up -d
```

Access at `http://<host>:42110`.

### Minimal environment additions to docker-compose.yml server section
```yaml
environment:
  - KHOJ_DOMAIN=khoj.example.com
  - OPENAI_API_KEY=sk-your-key-here
  # OR for local Ollama:
  # - OPENAI_BASE_URL=http://host.docker.internal:11434/v1/
  # - KHOJ_DEFAULT_CHAT_MODEL=qwen3
  - KHOJ_TELEMETRY_DISABLE=True
```

### Port
- `42110` — Khoj web UI and API

### Data volumes
| Volume | Contents |
|--------|----------|
| `khoj_config` | Khoj config and indexed documents |
| `khoj_db` | PostgreSQL data (pgvector) |
| `khoj_models` | Downloaded sentence transformer models |
| `khoj_search` | SearXNG config |
| `khoj_computer` | Computer agent workspace |

### Document indexing
Khoj indexes Markdown, PDF, plaintext, Org-mode files, and Notion/Obsidian vaults. Upload via the web UI, CLI, or desktop/mobile apps.

---

## Upgrade Procedure

1. Pull latest: `docker compose pull`
2. Restart: `docker compose up -d`
3. DB migrations run automatically
4. Check release notes: https://github.com/khoj-ai/khoj/releases

---

## Gotchas

- **Anonymous mode enabled by default** — the startup command includes `--anonymous-mode`, which lets anyone access the instance without auth; remove this flag for internet-exposed deployments and configure user accounts
- **KHOJ_DOMAIN required for public access** — without it, CSRF protection and cookie settings break; set to your domain/IP (no `http://` prefix)
- **pgvector is required** — Khoj uses PostgreSQL with the pgvector extension for semantic search; standard Postgres images won't work
- **Model download on first start** — sentence transformer models are downloaded from Hugging Face on first run; ensure internet access and enough disk space (~500 MB)
- **Computer agent needs Docker-in-Docker** — the `khoj-computer` service runs a desktop environment; `KHOJ_OPERATOR_ENABLED=True` must be set explicitly to enable it
- **AGPL-3.0 license** — network use triggers copyleft; modifications to Khoj must be open-sourced if offered as a network service

---

## Links
- Upstream README: https://github.com/khoj-ai/khoj
- Documentation: https://docs.khoj.dev
- Self-hosting guide: https://docs.khoj.dev/self-hosting/setup
- Telemetry info: https://docs.khoj.dev/miscellaneous/telemetry
