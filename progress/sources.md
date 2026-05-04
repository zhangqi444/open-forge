# Catalog growth — signal sources

This file is the **source-of-truth queue** for the bot's catalog-growth work. AI sessions reading CLAUDE.md / AGENTS.md / ARCHITECTURE.md should look here to know which external lists / feeds are being processed and in what order.

The bot reads this file on each run to decide which source to pull from next. Maintainers update it when adding / completing / re-prioritizing sources.

## Source queue (in priority order)

| # | Source | Status | What it provides | Notes |
|---|---|---|---|---|
| 1 | **selfh.st directory** ([`cdn.jsdelivr.net/gh/selfhst/cdn@main/directory/software.json`](https://cdn.jsdelivr.net/gh/selfhst/cdn@main/directory/software.json)) | **Complete** | 1,274 self-hostable apps sorted by GitHub stars | Completed 2026-05-04. 1,257 apps addressed + 17 skipped = 1,274/1,274. State tracked in [`selfhst-progress.json`](selfhst-progress.json). |
| 2 | **awesome-selfhosted-data** ([`github.com/awesome-selfhosted/awesome-selfhosted-data`](https://github.com/awesome-selfhosted/awesome-selfhosted-data)) | **In progress** | ~1,315 entries categorized + license-tagged. Renders as <https://awesome-selfhosted.net/>. | YAML format (one file per software under `software/*.yml`). Dedupe baseline: 1,263 existing recipes vs 1,315 source entries → 817 net-new candidates. Processing in star-rank order. State tracked in [`awesome-selfhosted-progress.json`](awesome-selfhosted-progress.json). |
| 3 | **Self-Host Weekly newsletter** ([`selfh.st/weekly`](https://selfh.st/weekly)) | **Continuous** | Weekly cycle of new / updated / discovered self-hostable software | Process opportunistically — when a newsletter drops, audit the "Software Updates" / "New Software" / "Recently Discovered" / "Project Updates" sections against the catalog. The newsletter often surfaces software before it lands in the selfh.st directory or awesome-selfhosted. Past runs: [Self-Host Weekly 2026-05-01](https://github.com/zhangqi444/open-forge/issues?q=is%3Aissue+label%3Anewsletter%3Aselfhst-2026-05-01). |
| 4 | **GitHub issues** (templates: `recipe-feedback` / `software-nomination` / `method-proposal`) | **Continuous** | User-driven demand signal | Process per CLAUDE.md § *Processing incoming issues*. Highest-priority work (real users, not speculative authoring). |

## Processing order

1. **Continuous sources first** when fresh signal arrives. GitHub issues (channel #4) take priority over batch sources because they represent real user demand. New newsletter issues (channel #3) take priority over directory sweeps because they're time-sensitive.
2. **Batch sources** (channels #1, #2) processed in star-rank / popularity order from each source. Skip software already in catalog (dedupe by recipe-name slug).
3. **Don't speculatively author** Tier 1 recipes from any source's "long tail" — per CLAUDE.md graduation criteria, single weak signal isn't enough. The bot processes each source's top-N and stops; further entries need additional demand signal (3+ feedback issues, repeat newsletter mention, etc.) to graduate.

## Adding a new source

When a new directory / list / newsletter / signal source emerges:

1. Verify it has a stable, machine-readable format (JSON / YAML / RSS / API). Manual scraping of HTML is brittle — prefer sources with first-class data feeds.
2. Document the format conversion: what fields → recipe frontmatter, how to dedupe against existing catalog.
3. Add a row to the table above with status `Queued`.
4. The bot picks it up after current `In progress` source completes.
5. Don't process speculatively — wait for queue order or for a maintainer to re-prioritize.

## Out-of-scope sources

Lists that **don't** match open-forge's inclusion criteria (per CLAUDE.md § *Is this software in scope?*):

- **Awesome lists for libraries / SDKs** (e.g. `awesome-python`, `awesome-go`) — not deployable services.
- **Awesome lists for desktop apps** (e.g. `awesome-mac`, `awesome-linux-software`) — no self-hosted server side.
- **SaaS-aggregator directories** (Product Hunt, AlternativeTo's general categories) — most entries are managed-only with no self-host distribution.

Self-hosting-specific lists (selfh.st, awesome-selfhosted, r/selfhosted "weekly app share" threads) are in scope.

## Status updates

| Date | Event |
|---|---|
| 2026-04-29 | Bot bootstrapped on selfh.st (1,274 apps, processed in star-rank order). |
| 2026-05-03 | awesome-selfhosted-data registered as next source (this file). |

(Append new entries here when sources change status — completed / paused / re-prioritized.)
| 2026-05-04 | selfh.st source completed (1,274/1,274). awesome-selfhosted-data promoted to In progress. Batch 1 committed: apache-airflow, anubis, docker-mailserver, activitywatch, bytebase. |
