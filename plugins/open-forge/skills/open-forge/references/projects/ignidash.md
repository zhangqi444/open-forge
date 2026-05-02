---
name: ignidash
description: Recipe for Ignidash — open-source retirement/financial planning app with Monte Carlo simulations, historical backtesting, US tax estimation, and AI chat. Next.js + Convex backend. Self-hosting via npm setup script + Docker Compose.
---

# Ignidash

Open-source personal financial planning and retirement simulation app. Upstream: https://github.com/schelskedevco/ignidash

Web-based retirement planning tool: Monte Carlo simulations, historical backtesting, US tax estimation (withdrawals, asset location, income changes), AI chat (Azure OpenAI), and AI insights. Next.js 16 + React 19 + Convex (DB & server functions) + Better-Auth with Google OAuth. AGPL-3.0 licensed.

Hosted version: https://www.ignidash.com/ — self-hosting guide: https://github.com/schelskedevco/ignidash/blob/main/SELF_HOSTING.md

> **Beta software** — actively developed. Currently US-focused (tax modeling). See known limitations at https://www.ignidash.com/help

## Compatible combos

| Method | Notes |
|---|---|
| Docker Compose (self-hosted Convex) | Primary self-hosting method — uses npm setup script to orchestrate |
| ignidash.com (managed) | Fully hosted — no install needed |

## Prerequisites

- Node.js 20+
- Docker Engine

## Inputs to collect

The setup script (`npm run selfhost -- --init`) handles most configuration by generating `.env.local` from a template. Typically:

| Phase | Prompt | Notes |
|---|---|---|
| auth | Google OAuth client ID + secret | For user authentication (Better-Auth + Google OAuth) |
| AI (opt) | Azure OpenAI endpoint + API key | For AI chat and insights features |
| preflight | App URL | Default: http://localhost:3000 |

Follow the interactive prompts from the setup script — do not manually write the `.env.local` file.

## Software-layer concerns

**Architecture:** Two main services — the Next.js app and a self-hosted Convex backend. Both run via Docker Compose, orchestrated by the npm setup script.

**Setup script handles:**
- Generating `.env.local` from template
- Building Docker images
- Starting services
- Generating the Convex admin key
- Syncing env vars to the Convex backend

**Important:** Running `npm run selfhost` (without `--init`) regenerates the Convex admin key — your Dashboard credentials change each run. The new key is saved to `.env.local`.

**Docker image tags:**
| Tag | Use |
|---|---|
| stable | Latest tagged release — recommended for production |
| latest | Latest commit to main |
| vX.Y.Z | Specific version |

**No separate database** — Convex is the database and server functions runtime, running as a self-hosted container.

## Setup

```bash
git clone https://github.com/schelskedevco/ignidash.git
cd ignidash

# First-time setup (generates .env.local, builds, starts)
npm run selfhost -- --init
```

After setup, open http://localhost:3000/signup to create your account.

## Useful commands

| Command | Description |
|---|---|
| `npm run selfhost -- --init` | First-time setup |
| `npm run selfhost` | Rebuild, restart, regen admin key, sync env, deploy |
| `npm run selfhost -- --sync-only` | Sync env vars to Convex without rebuilding |
| `npm run docker:up` | Start services in background |
| `npm run docker:down` | Stop services |
| `npm run docker:logs` | Stream logs |

## Upgrade procedure

```bash
git pull
npm run selfhost
```

Note: this regenerates the Convex admin key. Save the new key from `.env.local`.

## Gotchas

- **`npm run selfhost` changes the Convex admin key** — every run regenerates it. If using the Convex Dashboard, retrieve the new key from `.env.local` after each run.
- **AGPL-3.0 license** — modifications offered as a network service must be released under AGPL-3.0.
- **US tax modeling only** — tax estimation is US-specific (federal). Non-US users can use simulations but tax features won't apply.
- **Azure OpenAI required for AI features** — AI chat and insights require an Azure OpenAI endpoint/key. The app works without it but AI features will be unavailable.
- **Beta software** — financial modeling tools should be used for planning guidance, not as definitive financial advice.

## Links

- Upstream repository: https://github.com/schelskedevco/ignidash
- Self-hosting guide: https://github.com/schelskedevco/ignidash/blob/main/SELF_HOSTING.md
- Hosted version: https://www.ignidash.com/
- Known limitations: https://www.ignidash.com/help
- Discord: https://discord.gg/AVNg9JCNUr
