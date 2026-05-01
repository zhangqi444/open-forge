---
name: SecureAI Tools
description: "Private + secure AI tools for productivity — chat w/ AI + chat w/ documents (PDFs). Local inference via Ollama. Paperless-ngx integration. Docker Compose. SecureAI-Tools/SecureAI-Tools. Discord."
---

# SecureAI Tools

SecureAI Tools is **"ChatGPT interface + document-RAG — but fully private + local-Ollama"** — a chat-with-AI + chat-with-documents (PDFs) platform optimized for self-hosting. **Local inference via Ollama** (100+ open-source models). Built-in auth + user management + family/coworker multi-user. Docker Compose < 5-min setup. **Paperless-ngx integration** (chat with your paperless docs).

Built + maintained by **SecureAI-Tools** org. Discord. Likely Next.js + Postgres + Ollama.

Use cases: (a) **private ChatGPT alternative on your hardware** (b) **chat with your PDFs** (c) **RAG over Paperless-ngx archives** (d) **family/team shared AI** (e) **Mistral/Llama local on M2 MacBook** (f) **OpenAI GPT3.5/4 backend option** (g) **document-collections RAG** (h) **self-hosted productivity AI**.

Features (per README):

- **Chat with AI**
- **Chat with documents** (PDFs)
- **Local inference via Ollama** (100+ models)
- **Optional OpenAI GPT3.5/4**
- **Built-in auth** (email/password)
- **Multi-user** (family/coworkers)
- **Docker Compose** quickstart
- **Paperless-ngx integration**
- **Document collections**

- Upstream repo: <https://github.com/SecureAI-Tools/SecureAI-Tools>
- Discord: <https://discord.gg/YTyPGHcYP9>

## Architecture in one minute

- **Next.js** frontend
- Postgres
- **Ollama** for local inference (separate service)
- PDF processing
- **Resource**: heavy if local-inference (GPU or fast CPU)
- **Port**: HTTP + Ollama API

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Upstream                                                                                                               | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `ai.example.com`                                            | URL          | TLS                                                                                    |
| Hardware             | GPU or strong CPU                                           | Hardware     | For local models                                                                                    |
| Admin                | Email/password                                              | Auth         |                                                                                    |
| Ollama model         | mistral/llama2/etc.                                         | AI           | Pull locally                                                                                    |
| OpenAI API key       | Optional                                                    | Secret       | If using GPT3.5/4                                                                                    |

## Install via Docker Compose

Per README:
```sh
mkdir secure-ai-tools && cd secure-ai-tools
# Run setup script from README
```
Then typical compose:
```yaml
services:
  secureai:
    image: secureai/secureai-tools:latest        # **pin**
    ports: ["3000:3000"]
    environment:
      - OLLAMA_URL=http://ollama:11434
      - OPENAI_API_KEY=...        # Optional
    depends_on: [postgres, ollama]
  postgres:
    image: postgres:15
  ollama:
    image: ollama/ollama:latest
    volumes: [./ollama:/root/.ollama]
```

## First boot

1. Follow setup script
2. Pull Ollama models (`ollama pull mistral`)
3. Create admin
4. Add users
5. Upload PDFs → create collections
6. (Optional) Paperless-ngx integration
7. Put behind TLS
8. Back up DB + Ollama models

## Data & config layout

- Postgres — users, chats, docs, embeddings
- Ollama models on disk (large!)
- Uploaded PDFs

## Backup

```sh
pg_dump secureai > secureai-$(date +%F).sql
# PDFs + chat history + embeddings
# **ENCRYPT** — chats may contain sensitive info
```

## Upgrade

1. Releases: <https://github.com/SecureAI-Tools/SecureAI-Tools/releases>
2. Docker pull + restart
3. Check Ollama version compat

## Gotchas

- **191st HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — PRIVATE-AI-CHAT + DOCUMENT-CORPUS**:
  - Holds: **chat history** (often very personal / confidential), **uploaded PDFs** (often sensitive — contracts, health, finances), **document embeddings**, OpenAI API key (if used), Paperless credentials (if integrated)
  - Chat + documents = highly-personal corpus
  - **191st tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "private-AI-chat + document-corpus-RAG"** (1st — SecureAI Tools; distinct from Obico AI-ML-server which is image-classification not personal-text-corpus)
  - **CROWN-JEWEL Tier 1: 65 tools / 58 sub-categories**
- **AI-CHAT-HISTORY-PII**:
  - People confide in AI chats (health questions, financial planning, relationship advice)
  - Chat history = confessional-level PII
  - **Recipe convention: "AI-chat-history-confessional-PII-retention-discipline callout"**
  - **NEW recipe convention** (SecureAI Tools 1st formally; HIGH-severity)
- **DOCUMENT-RAG-ADVERSARIAL**:
  - Uploaded docs in embeddings can leak via prompt-injection
  - **Recipe convention: "RAG-prompt-injection-leakage-risk callout"**
  - **NEW recipe convention** (SecureAI Tools 1st formally)
- **OPENAI-API-KEY-OPTIONAL-BUT-RISKY**:
  - If user opts into OpenAI backend, data leaves local
  - "SecureAI" brand + OpenAI toggle = tension
  - **Recipe convention: "cloud-AI-backend-data-leaves-local-boundary callout"**
  - **NEW recipe convention** (SecureAI Tools 1st formally)
- **OLLAMA-DEPENDENCY**:
  - Ollama is excellent but separate service
  - **Ollama-local-inference: 1 tool** 🎯 **NEW FAMILY** (SecureAI Tools)
  - **AI-model-serving-tool: 7 tools** 🎯 **7-TOOL MILESTONE** (+SecureAI)
- **PAPERLESS-NGX-INTEGRATION**:
  - Companion-pattern to Paperless-ngx
  - **Companion-tool-to-popular-selfhosted: 2 tools** (IPP+SecureAI) 🎯 **2-TOOL MILESTONE**
- **100-PLUS-MODELS-CLAIM**:
  - Via Ollama's library
  - **Recipe convention: "100-plus-AI-models-via-Ollama-library positive-signal"**
  - **NEW positive-signal convention** (SecureAI Tools 1st formally)
- **FAMILY-COWORKER-MULTI-USER**:
  - Explicit multi-user positioning
  - **Recipe convention: "family-or-team-multi-user-positioning positive-signal"**
  - **NEW positive-signal convention** (SecureAI Tools 1st formally)
- **FIVE-MIN-SETUP-CLAIM**:
  - Quick-start discipline
  - **Recipe convention: "sub-5-min-quickstart-positioning positive-signal"**
  - **NEW positive-signal convention** (SecureAI Tools 1st formally)
- **YOUTUBE-DEMO-VIDEOS**:
  - Multiple demo videos embedded
  - **Recipe convention: "demo-video-embedded-in-README positive-signal"**
  - **NEW positive-signal convention** (SecureAI Tools 1st formally)
  - **Demo-video-in-README: 1 tool** 🎯 **NEW FAMILY** (SecureAI Tools)
- **INSTITUTIONAL-STEWARDSHIP**: SecureAI-Tools org + Docker Compose + Discord + demo-videos + Paperless-integration + Ollama-ecosystem. **177th tool — AI-privacy-focused-productivity-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Docker + Discord + demo-videos + integrations. **183rd tool in transparent-maintenance family.**
- **PRIVATE-AI-CHAT-CATEGORY:**
  - **SecureAI Tools** — docs-RAG + multi-user; Paperless-integration
  - **Open WebUI** — Ollama UI; mature
  - **LibreChat** — OpenAI-compat front-end
  - **Lobe Chat** — feature-rich
  - **AnythingLLM** — similar RAG-focused
- **ALTERNATIVES WORTH KNOWING:**
  - **Open WebUI** — if you want mature Ollama UI
  - **AnythingLLM** — similar RAG + workspace
  - **Choose SecureAI Tools if:** you want docs-RAG + multi-user + Paperless-integration.
- **PROJECT HEALTH**: active + Discord + Paperless-integration + Docker. Strong.

## Links

- Repo: <https://github.com/SecureAI-Tools/SecureAI-Tools>
- Ollama: <https://github.com/ollama/ollama>
- Open WebUI (alt): <https://github.com/open-webui/open-webui>
- AnythingLLM (alt): <https://github.com/Mintplex-Labs/anything-llm>
