---
name: job-ops
description: Recipe for self-hosting JobOps, a self-hosted job search pipeline that aggregates listings from 10+ job boards, scores roles against your profile with AI, tailors your CV, and tracks applications — DevOps principles applied to job hunting. Based on upstream documentation at https://github.com/DaKheera47/job-ops.
---

# JobOps

Self-hosted job search pipeline. Aggregates listings from 10+ boards (LinkedIn, Indeed, Glassdoor, Adzuna, etc.), scores each role 0-100 against your profile using AI, tailors your CV to each job description, exports polished PDFs, and tracks applications with Gmail auto-detection. Upstream: <https://github.com/DaKheera47/job-ops>. Docs: <https://jobops.dakheera47.com/docs>. Stars: 3k+. License: MIT.

**Does not auto-apply.** You apply to each job yourself — JobOps accelerates research, tailoring, and tracking.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended |
| Any host | Node.js + Python | Direct; Node 22+ and Python 3 required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| required | LLM provider + API key | Gemini (CLI/API), OpenAI, OpenRouter, or OpenClaw Codex |
| optional | BASIC_AUTH_USER / BASIC_AUTH_PASSWORD | Enable auth (app is unauthenticated by default) |
| optional | RXRESUME_API_KEY | Required for tailored resume generation via Reactive Resume v5 |
| optional | JOBOPS_PUBLIC_BASE_URL | Public URL for PDF tracer links in background/pipeline runs |

## Docker Compose deployment

```bash
git clone https://github.com/DaKheera47/job-ops.git
cd job-ops

# Configure environment
cp .env.example .env
# Edit .env: set MODEL, LLM_PROVIDER, and any API keys

docker compose up -d
```

Open `http://localhost:3005` and follow the onboarding wizard.

## .env reference

```bash
# LLM model (default: Gemini)
MODEL=google/gemini-3-flash-preview

# LLM provider: gemini_cli, gemini, openai, openrouter, codex
# LLM_PROVIDER=gemini_cli
# For Gemini CLI: install @google/gemini-cli, run `gemini` and sign in (OAuth)
# GEMINI_API_KEY=your-gemini-api-key

# Optional authentication (app is fully unauthenticated if not set)
BASIC_AUTH_USER=
BASIC_AUTH_PASSWORD=

# Optional JWT (auto-generated if auth is enabled and not set)
# JWT_SECRET=at-least-32-char-secret

# Public base URL (for PDF links in background runs)
JOBOPS_PUBLIC_BASE_URL=https://jobops.example.com

# Reactive Resume v5 API key (for tailored CV PDF generation)
RXRESUME_API_KEY=
```

## Data volumes

| Path | Contents |
|---|---|
| ./data | SQLite database, generated PDFs |
| codex-home | Codex/agent session data (if using Codex LLM provider) |

## Supported job boards

LinkedIn, Indeed, Glassdoor, Adzuna, Hiring Cafe, startup.jobs, Working Nomads, Gradcracker (UK STEM), UK Visa Jobs, Golang Jobs, Seek (AU/NZ via Apify). Custom extractors can be added via TypeScript.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data in `./data` and `codex-home` volume is preserved across upgrades.

## Gotchas

- **Authentication is disabled by default.** Set `BASIC_AUTH_USER` and `BASIC_AUTH_PASSWORD` before exposing to any network beyond localhost.
- JobOps uses an LLM for scoring and CV tailoring — you need a valid API key for your chosen provider (Gemini, OpenAI, OpenRouter, etc.) or a local Gemini CLI login.
- CV tailoring (PDF export) requires `RXRESUME_API_KEY` pointing to a [Reactive Resume v5](https://rxresu.me) instance. You can self-host Reactive Resume separately.
- `./data` is a bind-mount on the host (not a named volume) — it persists as long as the directory exists. Deleting the project directory deletes all job data.
- Some job boards (e.g. Seek via Apify) may require additional API keys for their extractors — check the extractor docs.

## Upstream docs

- README: https://github.com/DaKheera47/job-ops/blob/main/README.md
- Self-hosting guide: https://jobops.dakheera47.com/docs/getting-started/self-hosting
- Extractor docs: https://jobops.dakheera47.com/docs/extractors/overview
