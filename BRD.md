# BRD — open-forge

> **Why this exists, who it's for, what success looks like, what we're explicitly not building.** Lightweight by design — strategic clarity in one place, refreshed when the answers change. Not a formal enterprise BRD; closer to a product-vision brief.
>
> **Pointers**: Policy lives in [CLAUDE.md](CLAUDE.md). System shape lives in [ARCHITECTURE.md](ARCHITECTURE.md). User-facing pitch lives in [README.md](README.md). This file is *intent*.

## Why open-forge exists

**The pain.** Self-hosting open-source software is harder than it should be. Every project has its own quirks — install scripts that fail at non-obvious places, config schemas that broke between versions, gotchas that only surface in production. Upstream documentation tells you the commands but not the surprises. A power user who wants to run their own Vaultwarden / Mastodon / Ghost / OpenClaw spends most of their time debugging things that are not actually their problem.

**Generic AI assistance helps but resets every session.** Raw Claude Code / ChatGPT / Cursor will happily walk a user through a deploy, but they re-learn each project's quirks from scratch each time. Yesterday's gotcha doesn't help today's user. There's no compounding.

**The bet.** A guided-chat self-hosting skill, paired with a recipe catalog that captures tribal knowledge from real deploys, produces a better self-hosting experience than either upstream docs alone OR raw AI assistance. The catalog is the moat: the 1,001st user benefits from the previous 1,000 because their gotchas got captured.

**The moat is the feedback loop**, not the recipe count. Recipe count is a lagging metric for catalog usefulness. Anyone can scrape awesome-selfhosted into 1,000 stub files. The differentiator is per-recipe captured gotchas + ongoing maintenance via end-user feedback issues.

## Who it's for

| Persona | Concrete shape | What they want |
|---|---|---|
| **Homelab self-hoster** | Raspberry Pi 5 / Mac mini / NUC at home; a few services for the family | "Run my own Plex / Vaultwarden / Pi-hole without breaking it" |
| **Indie maker** | Side projects on a Hetzner CX22; doesn't want to babysit infrastructure | "Ship the side project; spend cycles on product, not yak-shaving Postgres backups" |
| **Privacy-conscious individual** | Escaping cloud SaaS (Notion → Outline; Bitwarden cloud → Vaultwarden self-host; Google Photos → Immich) | "Own my data without becoming a sysadmin" |
| **Small-team operator** | 5-20 person team; standing up internal tools without a dedicated DevOps hire | "Deploy Plausible / Mattermost / GitLab with sane defaults; survive the on-call" |
| **AI-coding-tool-savvy developer** | Already runs Claude Code / Cursor / Aider; finds open-forge by recognizing the workflow shape | "I already trust an AI agent in my terminal; this just adds the deploy-recipes layer" |

**NOT for**:
- Enterprise compliance (SOC2 / HIPAA / FedRAMP) buyers — open-forge ships zero compliance artifacts
- Production multi-region operators with strict SLA requirements — single-node first, replication is per-recipe and unsupervised
- Complete beginners with no terminal experience — the skill assumes a user who can paste a command and answer prompts

## Success criteria

Measured (or measurable) — *honest about leading vs lagging:*

| Metric | Type | Target | Notes |
|---|---|---|---|
| **Deploy success rate** | Leading | >70% of started deploys complete `hardening` | Captured in feedback-issue outcomes; today: unmeasured |
| **Recipe quality bar** | Leading | 100% of Tier 1 recipes cite upstream URLs per strict-doc-policy | Today: enforced for new recipes; older recipes mostly compliant |
| **Demand-signal density** | Leading | ≥1 recipe-feedback issue per popular recipe per quarter | Today: very low (issue queue mostly empty) |
| **Catalog growth** | Lagging | Steady weekly additions from queued sources | Today: bot ships 3-5/day from selfh.st; ~92% through that source |
| **Marketplace installs** | Lagging | Unmeasured (no telemetry) | Could approximate via GitHub stars + DeepWiki traffic |
| **Multi-platform adoption** | Lagging | At least 1 deploy per platform / quarter | Today: anecdotal only |

The metrics that matter most are **leading** (deploy success, recipe quality, demand-signal density). Lagging metrics (install count, stars) are vanity unless paired with leading signal.

## What we're explicitly NOT building

| Not | Why |
|---|---|
| Custom DSLs / wrapper CLIs | Per CLAUDE.md Operating Principle #7 — open-forge orchestrates existing tools, doesn't replace them |
| A Claude-Code-replacement chat UI | The skill runs *inside* Claude Code (and 6 other platforms); building our own chat UI duplicates effort |
| Per-recipe automated end-to-end testing | Too expensive (each test = real cloud spend); rely on user feedback issues + first-run discipline |
| A managed SaaS tier | Open-source self-hosting is the product; running it for users would be a different product |
| Compliance certifications | We can't promise SOC2 / HIPAA / etc. for self-hosted deploys; users own the compliance posture of their own infra |
| Auth / authz / multi-tenancy on the catalog | The catalog is public; issues are public; no per-user partitioning |
| A web dashboard | The skill is the interface; a web dashboard would be a parallel product |
| A GitHub-issue-replacement system | GitHub issues are the universal substrate; building our own is reinventing |
| Commercial features behind paywall | MIT-licensed, fully open. Sponsorship / grants are fine; product gating is not. |

## Differentiation

| Comparable | Their shape | Our shape |
|---|---|---|
| **awesome-selfhosted / selfh.st** | Curated lists of links | Guided execution + captured gotchas |
| **Raw Claude Code / ChatGPT** | One-session, zero compounding | Multi-session, compounds via feedback loop |
| **Coolify / Dokku / Caprover** | Deployment platforms (lock-in) | BYO infra; user keeps host control |
| **Bitnami / DO Marketplace / vendor blueprints** | Vendor-specific, single-cloud | Cross-cloud, vendor-neutral |
| **Hostinger / managed self-host providers** | Managed-for-you | Self-driven (with guidance) |
| **YouTube / blog deployment tutorials** | Drift in days; no maintenance loop | Drift surfaced by feedback issues; maintained centrally |

The simplest framing for newcomers: **open-forge is a recipe library that happens to come with an AI agent that runs the recipes for you, on your infra.**

## Roadmap (rough — next 6 months)

| Status | Item | Notes |
|---|---|---|
| ✅ | Multi-platform support (Codex / Cursor / Aider / Continue / OpenClaw / Hermes / generic) | PR #34, #36 |
| ✅ | Issue-driven contribution model + sanitization principles | PR #28 |
| ✅ | Two-tier coverage (Tier 1 verified + Tier 2 live-derived) | PR #23 |
| ✅ | Backups + Monitoring modules | PR #44, #46 |
| ✅ | Curated bundles (AI homelab, privacy stack) | PR #44 |
| ✅ | ARCHITECTURE.md + signal-source registration | PR #45, #48 |
| ⏳ | Per-recipe `## Backup` + `## Monitoring` section sweeps | ~1,100 recipes; bot work over weeks |
| ⏳ | awesome-selfhosted-data ingestion (after selfh.st completes) | Queued in `progress/sources.md` |
| 📋 | Cost estimation pre-deploy | Per-adapter; small per-item, lots of items |
| 📋 | Recipe-staleness automation (CI cron job) | Re-fetch upstream URLs; flag drift |
| 📋 | More bundles (knowledge base, self-hosted Google Drive, dev-tools stack) | Gated on demand signal — 3+ user requests for the same combo |
| 📋 | First-deploy verification campaign | Pick top-50 most-popular recipes; deploy each end-to-end; surface gotchas |
| ❓ | Multi-language recipe content | No demand surfaced yet; recipes are English-only |
| ❓ | Sponsorship / GitHub Sponsors / maintenance grant | Hobby project today; revisit if sustained external usage |

## Open questions / decisions deferred

These are the strategic choices we're **not yet committing to** — captured here so they don't get re-litigated each session:

1. **Auto-promotion of Tier 2 → Tier 1 on demand signal?** Currently the graduation criteria say 3+ feedback issues; should that auto-promote, or always require maintainer review?
2. **AI-compute infra category?** Lambda Labs / RunPod / Modal / Vast.ai have a different shape (per-job spend, ephemeral instances) than VPS adapters. Worth a sub-category, or out of scope?
3. **Recipe deprecation policy.** When upstream archives a project (e.g. Booklore → Grimmory fork), what's the recipe lifecycle? Today: ad-hoc.
4. **Public deployment success rate measurement.** No telemetry today (privacy) — should we offer opt-in pings? Or stay anonymous and rely on issue-volume as proxy?
5. **Funding / sustainability model.** Maintainer-as-hobby works at current scale. If usage 10×s, what's the path? Sponsors, grants, commercial tier, or step away from active maintenance?
6. **Catalog ownership long-term.** Is open-forge the canonical AI-guided self-hosting catalog, or one of many? If others fork-and-extend, do we welcome / merge / acknowledge?

## Status

This document was first drafted 2026-05-03 and is intended as a living artifact. Refresh when:

- The roadmap status changes
- A new deferred decision is settled
- Differentiation shifts (a new comparable enters the space)
- Success criteria need re-tuning
- The persona set evolves
