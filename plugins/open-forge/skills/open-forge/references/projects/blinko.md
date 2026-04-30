---
name: Blinko
description: AI-powered card-style note-taking app — quick capture for "fleeting thoughts" with full Markdown + AI-powered RAG search over your notes. Tauri multi-platform (macOS/Windows/Android/Linux), self-hosted server via Docker. AI features require OpenAI-compatible endpoint. AGPL-3.0.
---

# Blinko

Blinko is a modern note-taking app focused on one-line capture — think "Google Keep meets Obsidian, with AI search baked in." The premise: ideas are fleeting, so the capture path is deliberately quick (open Blinko → type → done). Then the AI makes your accumulated notes actually searchable via natural-language queries.

Key features:

- **Quick-capture card notes** — simple text, Markdown, attachments
- **AI-enhanced retrieval (RAG)** — ask questions like "what did I note about X?"; Blinko embeds + vector-searches your notes and synthesizes answers
- **Self-hosted** — your notes live on your infrastructure
- **Cross-platform** — Tauri desktop apps (macOS, Windows, Linux) + mobile (Android, iOS via PWA)
- **Multi-user** — with authentication
- **Full Markdown** including embedded images, files, code blocks
- **Tags + categories** — loose classification without rigid folders
- **Public sharing** — selectively share notes via public URLs
- **API** — for integrations + 3rd-party clients
- **Plugin system** — extensibility

- Upstream repo: <https://github.com/blinkospace/blinko>
- Website: <https://blinko.space>
- Demo: <https://demo.blinko.space> (user `blinko` / password `blinko`)
- Docs: <https://docs.blinko.space>
- Docker Hub: <https://hub.docker.com/r/blinkospace/blinko>
- Telegram (English): <https://t.me/blinkoEnglish>

## Architecture in one minute

- **Next.js** app (frontend + backend API routes)
- **PostgreSQL** + **pgvector** extension for AI vector search
- **Tauri-based** desktop/mobile apps (native wrappers around the web UI)
- Single Docker container bundles the Next.js server
- **External AI dependency** — configure OpenAI API key OR any OpenAI-compatible endpoint (local LLMs via Ollama / LM Studio / LocalAI all work)

## Compatible install methods

| Infra       | Runtime                                       | Notes                                                               |
| ----------- | --------------------------------------------- | ------------------------------------------------------------------- |
| Single VM   | Official `install.sh` script                    | **Simplest** — downloads compose + sets up                             |
| Single VM   | Docker Compose (manual)                          | More control                                                              |
| Single VM   | Docker (`blinkospace/blinko`)                     | With an external Postgres + pgvector                                        |
| Kubernetes  | Community manifests                                | DIY                                                                             |
| Managed     | PikaPods (<https://www.pikapods.com/pods?run=blinko>) | 20% revenue contributed back to upstream                                          |
| Desktop     | Tauri apps (no self-host needed)                      | Or point at your self-hosted server                                                |

## Inputs to collect

| Input                         | Example                              | Phase     | Notes                                                           |
| ----------------------------- | ------------------------------------ | --------- | --------------------------------------------------------------- |
| `DATABASE_URL`                | `postgresql://blinko:<pw>@db:5432/blinko` | DB        | **Must have pgvector**; use `pgvector/pgvector:pg16` image          |
| `NEXTAUTH_URL`                | `https://blinko.example.com`           | URL       | Must match public URL                                               |
| `NEXTAUTH_SECRET`             | `openssl rand -hex 32`                  | Security  | Session token signing                                                  |
| `NEXT_PUBLIC_BASE_URL`        | same as NEXTAUTH_URL                     | URL       | Frontend-side references                                                   |
| OpenAI-compatible API endpoint | `https://api.openai.com/v1` OR your Ollama etc. | AI | Enables RAG/embeddings; cost/privacy implications                              |
| OpenAI API key                 | `sk-...`                                 | AI        | For OpenAI; blank string for local                                                   |
| Admin user                     | bootstrapped via first-user wizard        | Bootstrap | Race risk if exposed during setup                                                      |
| TLS                            | Let's Encrypt                             | Security  | Required for PWA install, Tauri integration                                                    |

## Install via official script (fastest)

```sh
curl -s https://raw.githubusercontent.com/blinko-space/blinko/main/install.sh | bash
```

**Review the script first** (<https://raw.githubusercontent.com/blinko-space/blinko/main/install.sh>) before piping to bash. It generates a docker-compose stack with Blinko + pgvector and writes a `.env`.

## Install via Docker Compose (manual)

```yaml
services:
  blinko:
    image: blinkospace/blinko:1.x.x     # pin; check Docker Hub
    container_name: blinko
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
    ports:
      - "1111:1111"
    environment:
      NODE_ENV: production
      NEXTAUTH_URL: https://blinko.example.com
      NEXT_PUBLIC_BASE_URL: https://blinko.example.com
      NEXTAUTH_SECRET: <openssl rand -hex 32>
      DATABASE_URL: postgresql://blinko:<strong>@postgres:5432/blinko
    volumes:
      - blinko-data:/app/.blinko

  postgres:
    image: pgvector/pgvector:pg16    # CRITICAL: pgvector variant, not plain postgres
    container_name: blinko-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: blinko
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: blinko
    volumes:
      - blinko-pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U blinko"]
      interval: 10s
      retries: 5

volumes:
  blinko-data:
  blinko-pg:
```

## First boot

1. Browse `https://blinko.example.com` → registration wizard (first user = admin)
2. Create admin account **immediately** (race risk if public)
3. Settings → AI → configure your OpenAI API key + embedding/chat models
   - Can use local: Ollama at `http://host.docker.internal:11434/v1` with model `llama3.1` + embedding `nomic-embed-text`
   - Or OpenAI: `https://api.openai.com/v1` + `gpt-4o-mini` + `text-embedding-3-small`
4. (Optional) disable public registration — Settings → System → close signups
5. Install desktop/mobile app, point at your URL

## Configure local AI (Ollama example)

Run Ollama alongside:

```yaml
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - ollama:/root/.ollama
    # GPU access (if NVIDIA):
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - capabilities: [gpu]
```

Pull models: `docker exec ollama ollama pull llama3.1 && docker exec ollama ollama pull nomic-embed-text`

In Blinko AI settings: endpoint `http://ollama:11434/v1`, API key blank, chat model `llama3.1`, embedding model `nomic-embed-text`.

## Data & config layout

- `/app/.blinko` — uploaded attachments (images, files)
- Postgres — notes + vector embeddings + users + sessions

## Backup

```sh
# DB (includes notes + embeddings)
docker compose exec -T postgres pg_dump -U blinko blinko | gzip > blinko-db-$(date +%F).sql.gz

# Uploads
docker run --rm -v blinko-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/blinko-data-$(date +%F).tgz -C /src .

# .env (NEXTAUTH_SECRET loss = all users logged out)
cp .env blinko-env-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/blinkospace/blinko/releases>. Very active.
2. `docker compose pull && docker compose up -d`. DB migrations run on startup.
3. **Young project** — back up DB first; breaking schema changes possible between minor versions.
4. Watch the Telegram English channel or GitHub Releases for migration notes.

## Gotchas

- **pgvector is MANDATORY** — plain Postgres will fail. Use `pgvector/pgvector:pg16` or install pgvector extension manually. AI search doesn't work without it.
- **AI features cost money** — OpenAI API usage on a note corpus adds up. Embedding 10k notes with `text-embedding-3-small` is cheap (~$0.30); chat completions are not (GPT-4o ≈ $5-10/million tokens). Local Ollama is free after hardware.
- **Local embeddings quality** — `nomic-embed-text` is a solid free choice but lower-quality than OpenAI's `text-embedding-3-large`. RAG quality reflects this.
- **macOS install "damaged" error** — per upstream FAQ, run: `sudo xattr -rd com.apple.quarantine /Applications/blinko.app`. This is because the DMG isn't notarized.
- **First-user-is-admin race** — open Blinko immediately after deploy + create admin; otherwise someone else might.
- **Closing public registration** after initial setup is in Settings → System. Recommended unless you're running for many users.
- **PWA install** requires HTTPS. Plain HTTP = no install prompt on iOS/Android.
- **Tauri desktop app** bundles a WebView and points at the server you configure. Not a fully offline app (still needs the server for sync).
- **Data is NOT end-to-end encrypted** — notes are stored plaintext in Postgres. Use filesystem-level encryption if that matters (LUKS, host-level at-rest crypto).
- **Young project** — frequent releases; watch for breaking changes. Back up before major upgrades. The repo has ~10k stars but is newer than competitors.
- **RAG isn't magic** — if your notes are ambiguous, RAG answers are ambiguous. Embedding-based search is better than keyword but isn't a LLM-level reasoning engine.
- **Single-tenant model** — one user = one account; users don't share notes by default. For team-style features, consider a different tool.
- **AI data-flow transparency**: if you use OpenAI, your notes are sent to OpenAI. They claim no training on API data, but if privacy matters, use local Ollama.
- **Chinese-origin project** — Chinese docs/community are richer; English docs + community are growing. This is not a criticism, just context.
- **AGPL-3.0 license** — copyleft; SaaS hosting requires source disclosure to users.
- **Alternatives worth knowing:**
  - **Obsidian + obsidian-livesync** — mature; Markdown files; extensive plugins; sync via self-hosted CouchDB (separate recipe)
  - **Logseq** — outliner; Markdown/org-mode files; open source
  - **Memos** — similar "quick note" philosophy; lighter; no AI search (separate recipe for Memos may exist)
  - **AppFlowy** — Notion-alike; Rust+Flutter; more structured
  - **Joplin** — long-standing Markdown notes with sync; many platforms
  - **TriliumNext / Trilium Notes** — hierarchical notes; powerful; desktop+web
  - **SilverBullet** — notebooks-as-code; Lua extensibility
  - **Google Keep** — SaaS; free but not private
  - **Apple Notes** — Apple-ecosystem-only
  - **Mem.ai / Reflect.app** — AI-first SaaS note apps
  - **Choose Blinko if:** you want a modern, AI-first quick-capture UX with self-hosted data.
  - **Choose Memos if:** you want maximum minimalism without AI.
  - **Choose Obsidian if:** you want long-term knowledge base with plugin depth.

## Links

- Repo: <https://github.com/blinkospace/blinko>
- Website: <https://blinko.space>
- Docs: <https://docs.blinko.space>
- Demo: <https://demo.blinko.space>
- Install script: <https://raw.githubusercontent.com/blinko-space/blinko/main/install.sh>
- Docker Hub: <https://hub.docker.com/r/blinkospace/blinko>
- Releases: <https://github.com/blinkospace/blinko/releases>
- PikaPods: <https://www.pikapods.com/pods?run=blinko>
- Ko-fi: <https://ko-fi.com/blinkospace>
- Telegram (English): <https://t.me/blinkoEnglish>
- Telegram (Chinese): <https://t.me/blinkoChinese>
- pgvector: <https://github.com/pgvector/pgvector>
- Ollama (for local AI): <https://ollama.com>
