---
name: PentAGI
description: "Self-hosted fully autonomous AI penetration testing system — multi-agent team using LLMs (OpenAI, Anthropic, Gemini, Bedrock, Ollama, DeepSeek, etc.) to plan and execute security tests, with 20+ professional tools (nmap, metasploit, sqlmap, …), vector DB memory, knowledge graph, built-in web scraper, Grafana observability, and detailed reports. Docker Compose. GPL-3.0."
---

# PentAGI

PentAGI is a fully autonomous AI penetration testing system that spins up a **team of specialized AI agents** (researcher, developer, infrastructure) to automatically plan and execute security tests against a target system, then generate detailed vulnerability reports.

It ships 20+ professional security tools (nmap, metasploit, sqlmap, Burp Suite, hydra, nikto, ...), a sandboxed Docker execution environment, long-term vector memory (PostgreSQL + pgvector), optional knowledge-graph integration (Neo4j + Graphiti), a built-in headless browser scraper, and Grafana/Prometheus/Jaeger/Loki observability — all wired together behind a modern React web UI.

Supports 10+ LLM providers: OpenAI, Anthropic, Google Gemini, AWS Bedrock, Ollama (local), DeepSeek, GLM, Kimi, Qwen, and any OpenAI-compatible endpoint. At least one LLM key is required.

- Upstream repo: <https://github.com/vxcontrol/pentagi>
- Upstream docs: <https://pentagi.com/>
- Docker Hub: `vxcontrol/pentagi:latest`
- Latest release: v2.0.0 (check <https://github.com/vxcontrol/pentagi/releases>)
- License: GPL-3.0

> **Ethics & legality**: PentAGI is a penetration testing tool. Only test systems you own or have explicit written permission to test. Running autonomous pentests against third-party systems without authorization is illegal in most jurisdictions.

## Architecture in one minute

- **Frontend** — React + TypeScript SPA
- **Backend** — Go + GraphQL API (also exposes REST)
- **Database** — PostgreSQL with pgvector extension (`vxcontrol/pgvector`)
- **Scraper** — isolated headless Chromium (`vxcontrol/scraper`)
- **Pentest containers** — spawned on-demand from Docker socket; 20+ tools
- **Optional add-ons** (separate compose files):
  - `docker-compose-graphiti.yml` — Neo4j + Graphiti knowledge graph
  - `docker-compose-langfuse.yml` — Langfuse LLM analytics (ClickHouse + Redis + MinIO)
  - `docker-compose-observability.yml` — Grafana + VictoriaMetrics + Jaeger + Loki + OpenTelemetry
- **Minimum**: 2 vCPU, 4 GB RAM, 20 GB disk

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Single Linux VM | **Docker Compose (interactive installer)** | Recommended. amd64 + arm64. Installer handles .env config + TLS. |
| Single Linux VM | **Docker Compose (manual)** | Clone repo, copy .env.example, fill keys, docker compose up -d. |
| Two-node (main + worker) | Docker Compose on both | Production-grade isolation. Worker runs pentest containers on separate host. |
| macOS / Windows | Docker Compose via installer | Supported via installer; dev/lab use. |
| Podman | Podman Compose | Community supported; see upstream Podman guide. |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| LLM provider + API key | OpenAI / sk-... | preflight | At least one required. Multiple can be set for different agent roles. |
| Bind IP | 127.0.0.1 (default) | network | Change to 0.0.0.0 for external access. |
| Public URL | https://192.168.1.100:8443 | network | Used for CORS config. |
| CORS origins | https://localhost:8443,... | network | Comma-separated list of allowed origins. |
| Ollama server URL (opt) | http://ollama-server:11434 | LLM | For local model inference. |
| Search API keys (opt) | Tavily, Traversaal, Perplexity, Google CSE | enrichment | DuckDuckGo works free; others enhance results. |
| Langfuse integration (opt) | base URL + keys | observability | Separate compose file; tracks LLM calls. |
| Grafana + metrics (opt) | — | observability | Separate compose file; monitors services. |

## Install — interactive installer (recommended)

```bash
# Linux amd64 — adjust URL for arm64/macOS/Windows from https://pentagi.com/downloads/
mkdir -p pentagi && cd pentagi

wget -O installer.zip https://pentagi.com/downloads/linux/amd64/installer-latest.zip
unzip installer.zip

# Run as root for Docker socket access (recommended in production)
sudo ./installer
```

The installer:
1. Verifies Docker + network
2. Creates and populates `.env` with your LLM keys + secrets
3. Configures SSL certificates
4. Starts the stack with `docker compose up -d`

Visit `https://localhost:8443` — default credentials are **admin@pentagi.com / admin**. Change immediately.

## Install — manual Docker Compose

```bash
mkdir -p pentagi && cd pentagi

# Download env template + provider config examples
curl -o .env https://raw.githubusercontent.com/vxcontrol/pentagi/master/.env.example
curl -o example.custom.provider.yml \
  https://raw.githubusercontent.com/vxcontrol/pentagi/master/examples/configs/custom-openai.provider.yml
curl -o example.ollama.provider.yml \
  https://raw.githubusercontent.com/vxcontrol/pentagi/master/examples/configs/ollama-llama318b.provider.yml

# Download docker-compose.yml
curl -o docker-compose.yml \
  https://raw.githubusercontent.com/vxcontrol/pentagi/master/docker-compose.yml

# Edit .env — set at least one LLM key
nano .env

docker compose up -d
```

Key `.env` variables:

```ini
# At least one of these is required
OPEN_AI_KEY=
ANTHROPIC_API_KEY=
GEMINI_API_KEY=

# Network (change for external access)
PENTAGI_LISTEN_IP=127.0.0.1
PENTAGI_LISTEN_PORT=8443
PUBLIC_URL=https://localhost:8443
CORS_ORIGINS=https://localhost:8443

# PostgreSQL password
PENTAGI_POSTGRES_PASSWORD=<generate with: openssl rand -hex 32>
```

Web UI at `https://localhost:8443` — default login `admin@pentagi.com / admin`.

## Enable optional add-ons

Each add-on has its own compose file. **Start the base compose first** to create named networks:

```bash
# Base stack first
docker compose -f docker-compose.yml up -d

# Then any combination of add-ons
docker compose -f docker-compose-langfuse.yml up -d
docker compose -f docker-compose-graphiti.yml up -d
docker compose -f docker-compose-observability.yml up -d
```

## External network access

By default PentAGI binds to `127.0.0.1`. To expose to LAN/internet:

```ini
# .env
PENTAGI_LISTEN_IP=0.0.0.0
PENTAGI_LISTEN_PORT=8443
PUBLIC_URL=https://192.168.1.100:8443
CORS_ORIGINS=https://localhost:8443,https://192.168.1.100:8443
```

```bash
docker compose down && docker compose up -d
```

## Data layout

| Path | Content |
|---|---|
| `pentagi-data` Docker volume | PentAGI app data (reports, results) |
| `pentagi-ssl` Docker volume | TLS certificates |
| `pentagi-postgres-data` Docker volume | PostgreSQL vector DB |
| `pentagi-ollama` Docker volume | Ollama model cache |
| `scraper-ssl` Docker volume | Scraper TLS certs |

## Upgrade

```bash
cd pentagi
docker compose pull
docker compose up -d --force-recreate
docker image prune -f
```

## Gotchas

- **Change default credentials immediately.** First login with `admin@pentagi.com / admin` then set a strong password in Settings.
- **Only test authorized targets.** Autonomous pentest agents can cause real damage. Never point at production systems or third-party targets without explicit permission.
- **Docker socket gives root equivalent.** PentAGI runs as root to spawn pentest containers. For better isolation, use the two-node setup (worker node guide in repo).
- **Network ordering matters.** Add-on compose files depend on named networks created by the base compose. Start the base first, or you'll get "network not found" errors.
- **At least one LLM provider required.** The system won't start agent tasks without a configured LLM. Ollama works for fully local deployments but needs sufficient GPU/RAM for useful models.
- **4 GB RAM minimum; 8+ GB for full stack.** Monitoring add-ons (Grafana + VictoriaMetrics + Jaeger + Loki) add significant memory overhead.
- **DB passwords are write-once.** `PENTAGI_POSTGRES_PASSWORD` is written to the DB on first init. Changing it in `.env` later only changes the config but not the actual stored password — breaking connectivity. Rotate only via full DB recreate + restore from backup.
- **External access exposes security tools.** If binding to `0.0.0.0`, put PentAGI behind a VPN or firewall. The web UI has no rate limiting by default.

## Links

- Repo: <https://github.com/vxcontrol/pentagi>
- Website & docs: <https://pentagi.com/>
- Releases: <https://github.com/vxcontrol/pentagi/releases>
- Worker node (two-node) guide: <https://github.com/vxcontrol/pentagi/blob/main/examples/guides/worker_node.md>
- vLLM + Qwen3 local inference guide: <https://github.com/vxcontrol/pentagi/blob/main/examples/guides/vllm-qwen35-27b-fp8.md>
- Discord: <https://discord.gg/2xrMh7qX6m>
- Telegram: <https://t.me/+Ka9i6CNwe71hMWQy>
