---
name: Journiv
description: "Self-hosted AI-enhanced journaling app. Docker. Node.js + PostgreSQL. journiv/journiv-app. Daily prompts, mood tracking, streak calendar, rich text, AI reflections via OpenAI, tagging, search, OIDC SSO. MIT."
---

# Journiv

**Self-hosted AI-enhanced journaling platform.** Write daily journal entries with AI-powered reflections and personalized prompts (via OpenAI-compatible APIs). Track mood over time, maintain writing streaks, organize entries with tags, and review your history with full-text search. OIDC SSO for authentication. Clean, distraction-free UI.

Built + maintained by **Journiv team**. MIT license.

- Upstream repo: <https://github.com/journiv/journiv-app>
- Docker Hub: `ghcr.io/journiv/journiv-app` (check repo for current image)

## Architecture in one minute

- **Node.js** backend + frontend
- **PostgreSQL** database
- Docker Compose: app + database containers
- Optional **OpenAI-compatible API** for AI reflections and prompts
- Port **3000** (configurable)
- Resource: **low** — Node.js + PostgreSQL

## Compatible install methods

| Infra              | Runtime                          | Notes                                              |
| ------------------ | -------------------------------- | -------------------------------------------------- |
| **Docker Compose** | `ghcr.io/journiv/journiv-app`    | **Primary** — see repo for current compose         |

Full setup: <https://github.com/journiv/journiv-app>

## Key inputs to collect

| Input | Phase | Notes |
|-------|-------|-------|
| `DATABASE_URL` | DB | PostgreSQL connection string |
| `NEXTAUTH_SECRET` | Auth | Random string for session signing |
| `NEXTAUTH_URL` | Network | Your public URL |
| OpenAI API key (optional) | AI | For AI reflections and prompts |
| OIDC provider credentials (optional) | SSO | For OIDC-based login |

## Install

```bash
git clone https://github.com/journiv/journiv-app.git
cd journiv-app
# Copy .env.example → .env and fill in values
cp .env.example .env
docker compose up -d
```

Visit the configured URL.

## Features overview

| Feature | Details |
|---------|---------|
| Journal entries | Rich text editor; daily writing |
| AI reflections | AI-generated insights + reflections on your entries |
| Daily prompts | AI-generated or curated writing prompts |
| Mood tracking | Track mood per entry; view trends over time |
| Streak calendar | GitHub-style contribution heatmap for writing consistency |
| Tags | Categorize entries; filter by tag |
| Full-text search | Search across all entries |
| OIDC SSO | Authenticate via OIDC providers |
| Export | Export your journal data |

## AI features (optional)

Configure an OpenAI-compatible API key to enable:
- **AI reflections** on your journal entries (patterns, themes, insights)
- **Daily prompts** tailored to your recent writing

Works with OpenAI, Ollama, and any OpenAI-compatible local LLM. Without an API key, journaling features work without AI enhancement.

## Gotchas

- **AI is opt-in.** Without an OpenAI API key, Journiv is a standard journaling app. AI features are additive, not required.
- **OIDC SSO optional.** Local accounts work without OIDC. OIDC adds enterprise SSO (Authentik, Keycloak, etc.).
- **Back up your entries.** Your journal data lives in PostgreSQL. Back up the DB regularly — journal entries are personal and irreplaceable.
- **Refer to current README.** Journiv is in active development; the compose file and env vars may evolve. Use the current repo README as the authoritative setup reference.

## Backup

```sh
docker compose exec postgres pg_dump -U postgres journiv > journiv-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, AI reflections + prompts, mood tracking, streak calendar, OIDC SSO. MIT license.

## Journaling-family comparison

- **Journiv** — Node.js, AI reflections/prompts, mood, streaks, OIDC, MIT
- **Diaro** — SaaS; not self-hosted
- **Joplin** — Markdown notes; not journal-specific; no AI prompts
- **Obsidian** — local Markdown; community plugins for journal; no AI built-in
- **Standard Notes** — E2E encrypted notes; no AI prompts; different focus

**Choose Journiv if:** you want a self-hosted journaling app with AI reflections, mood tracking, writing streaks, and OIDC SSO.

## Links

- Repo: <https://github.com/journiv/journiv-app>
