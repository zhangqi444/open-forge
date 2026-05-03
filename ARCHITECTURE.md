# ARCHITECTURE.md

How open-forge actually works as a system — the actors, the data flow, where state lives, what keeps quality up. Different audience from [CLAUDE.md](CLAUDE.md) (which is the *policy* — strict-doc rules, sanitization principles, processing workflow): ARCHITECTURE is *system shape*.

> **Pointers**: For project intent (why / who / success / non-goals) see [BRD.md](BRD.md). For policy details (what's in scope, how to verify against upstream, sanitization rules) see [CLAUDE.md](CLAUDE.md). For end-user usage see [README.md](README.md). For the skill content the end-user's agent reads see [SKILL.md](plugins/open-forge/skills/open-forge/SKILL.md).

## System overview

```
                                 (input pipe)
   end users  ─┐                                              ┌─►  marketplace
  (skill-      │     ┌────────────────┐                       │   (Claude Code
   assisted    ├──►  │ GitHub issues  │  ←──── batch ───────  │    + 6 other
   feedback)   │     │ ┌────────────┐ │      newsletter       │    platforms)
               │     │ │ recipe-fb  │ │      crawls           │
   maintainer  ├──►  │ │ nominate   │ │                       │
  (manual)     │     │ │ method     │ │                       │
               │     │ └────────────┘ │                       │
               │     └────────┬───────┘                       │
               │              │                               │
               │              ▼                               │
               │     ┌────────────────┐    ┌────────────┐     │
               │     │  AI session    │───►│   PR on    │────►│ merge → main
               │     │   (the bot     │    │   main     │     │
               │     │   on schedule  │    │            │     │
               │     │   OR ad-hoc)   │    └─────┬──────┘     │
               │     └────────────────┘          │            │
               │              ▲                  ▼            │
               │              │             ┌─────────┐       │
               │              │             │   CI    │ ──────┘
               │              │             │ guards  │
               │              │             └─────────┘
               │              │
               │       (strict-doc-policy verification:
               │        re-fetch upstream → diff → patch)
               │              │
   public      │              │
   newsletters ┴──────────────┘
   (selfh.st,
    other RSS)
```

The catalog grows continuously — at the time of this writing, the catalog has 1,100+ verified recipes; main is updated via a stream of small bot-authored PRs (recently `batch 183 — owntracks-frontend, paaster, …`) plus occasional maintainer / AI-session PRs. The exact count is a [shields.io live badge](https://img.shields.io/github/directory-file-count/zhangqi444/open-forge/plugins/open-forge/skills/open-forge/references/projects?type=file&extension=md) in the README.

## The four actors

| Actor | What they do | Files they touch |
|---|---|---|
| **The bot** (scheduled AI session) | Polls public newsletters (selfh.st, others) + GitHub issues. Triages by template type. Verifies against upstream per strict-doc-policy. Authors patches in batches. Bumps `plugin.json` version. Updates `progress/selfhst-progress.json` + `progress/issues-log.json`. | `references/projects/*.md`, `progress/*`, `plugin.json`, occasional `dist/` regen |
| **Maintainer (zhangqi444)** | Strategic decisions, PR merges, repo-settings (About / topics / website / social preview), high-judgment edits | Repo settings (web UI), occasional manual PRs |
| **AI sessions like Claude Code / Codex / Cursor / Aider / Continue / OpenClaw / Hermes / generic** | Maintainer-prompted: file issues, author specific PRs, audit catalog quality, generate distribution bundles for non-Claude-Code platforms | Anything except repo settings |
| **End users** | File issues via the three templates: recipe-feedback / software-nomination / method-proposal. The skill drafts these automatically with sanitization at the end of each deploy. | GitHub issue templates only — no direct repo write access |

End users do **not** open PRs. Per CLAUDE.md § *Issue-driven contribution model*, issues are the universal contribution channel; AI sessions process them centrally so the strict-doc-policy stays enforced and credentials don't leak into commit history.

## Data flow — how an issue becomes a recipe edit

```
  1. END USER files issue        ──►   uses one of three templates:
     (skill-drafted or manual)         recipe-feedback / software-nomination /
                                       method-proposal
                                       
                                       OR — bot picks up signal directly from
                                       public newsletters (skips the issue step)
                                       
  2. BOT or AI SESSION triages   ──►   labels: triaged / in-progress / applied /
                                       needs-info / out-of-scope (per CLAUDE.md
                                       § Processing incoming issues, state-
                                       machine via labels)
                                       
  3. UPSTREAM VERIFICATION       ──►   re-fetch the recipe's cited upstream URLs
                                       (or for nominations, locate upstream's
                                       install-method index); apply strict-doc-
                                       policy; if fetch fails, stop and label
                                       'needs-info'
                                       
  4. PATCH AUTHORSHIP            ──►   apply per Recipe structure (must-have
                                       sections); cite upstream URL at top of
                                       every section; flag community-maintained
                                       methods with the ⚠️ blockquote;
                                       sanitize user-shared content
                                       
  5. dist/ REGENERATION          ──►   if patch touches CLAUDE.md / SKILL.md /
                                       references/modules/, run
                                       ./scripts/build-dist.sh all
                                       (CI's dist-bundles-up-to-date check
                                       enforces this)
                                       
  6. PR open on main             ──►   branch: bot/issue-<N>-<slug>;
                                       PR body cites originating issue + every
                                       upstream URL re-verified + version-bump
                                       rationale
                                       
  7. CI guards                   ──►   .github/workflows/dist-bundles.yml
                                       fails the build if dist/ drifted from
                                       canonical sources
                                       
  8. Merge to main               ──►   marketplace publishes on next
                                       /plugin marketplace update
                                       (controlled by plugin.json version)
                                       
  9. Issue label flips to        ──►   bot triage closes the loop;
     'applied'                         label-state-machine documents what's done
```

## State stores

| Where | What | Owned by |
|---|---|---|
| **GitHub issues** | The input queue. Three templates encode the structured signals. State tracked via labels. | End users (drafts) + bot/maintainer (triage) |
| **`progress/selfhst-progress.json`** | Per-app processing status — which selfh.st apps have been cataloged, which are pending or skipped. | Bot |
| **`progress/selfhst-software.json`** | Cached source data fetched from selfh.st — app list with star counts. Rebuilt as needed. | Bot |
| **`progress/issues-log.json`** | Per-issue triage history — issue number, status (addressed/skipped/waiting), commit ref, action taken. | Bot |
| **`progress/sources.md`** | Catalog-growth source queue — which external lists / feeds the bot pulls from and in what order (selfh.st in progress, awesome-selfhosted-data queued, Self-Host Weekly newsletter continuous, GitHub issues continuous). Maintainer-curated; the bot reads it on each run to decide which source to pull from next. | Maintainer (curates queue) + bot (reads on each run) |
| **`plugins/open-forge/skills/open-forge/references/projects/*.md`** | The catalog itself. ~1,100+ Tier 1 verified recipes. | Bot (mostly) + maintainer (strategic recipes like ghost.md) |
| **`plugins/open-forge/skills/open-forge/references/{infra,runtimes,modules}/`** | Reusable orchestration layers — infra adapters, runtime modules, cross-cutting modules (preflight, dns, tls, smtp, inbound, tunnels, credentials, feedback, backups) | Maintainer mostly; bot adds modules when first-deploy-discipline surfaces gaps |
| **`plugins/open-forge/skills/open-forge/references/bundles/*.md`** | Curated multi-software deployment bundles (AI homelab, privacy stack). Recipe-of-recipes that orchestrate existing Tier 1 recipes for goal-shaped requests. | Maintainer-direct authoring (per CLAUDE.md graduation criteria, bundles aren't speculative authoring — they pair existing recipes) |
| **`dist/`** | Auto-generated multi-platform distribution bundles (codex / cursor / aider / continue / openclaw / hermes / generic). Concatenated from canonical sources via `scripts/build-dist.sh`. | Build script; CI enforces freshness |
| **`docs/platforms/`** | Per-platform integration guides for the 7 supported platforms. | Maintainer; updated when a new platform is added |
| **`.github/ISSUE_TEMPLATE/`** | The three input-channel forms (recipe-feedback / software-nomination / method-proposal) plus `config.yml` (disables blank issues) | Maintainer |
| **`.github/workflows/dist-bundles.yml`** | CI gate: regenerates `dist/` and fails the build if it drifted from canonical sources | Maintainer |
| **`~/.open-forge/deployments/<name>.yaml`** (on user machines) | End-user deployment state. Phased-workflow checkpoints, inputs, outputs. Resume across sessions. | End user; never enters the repo |

## Quality gates

What keeps the catalog from rotting:

| Gate | Where it runs | What it catches |
|---|---|---|
| **Strict doc-verification policy** | At patch-authorship time (per CLAUDE.md) | Recipe content cited from training data / blog posts / search snippets — not upstream docs. Past failures (v0.7.0 Helm hallucination, v0.6.0 OpenClaw "every blessed path" 4-of-17 claim) traced back here. |
| **Sanitization principles** | At issue-submission time (skill-side) AND at patch-acceptance time (issue-processing AI session re-checks) | User identifiers (domains, IPs, SSH keys, API keys, AWS account IDs, emails) leaking into the public repo. |
| **CI: dist-bundles-up-to-date** | Every PR + push to main | Stale `dist/` bundles after CLAUDE.md / SKILL.md / module changes. Forces build-script regen. |
| **Community-maintained flagging** | At patch-authorship time | Third-party install methods presented as upstream-blessed. ⚠️ blockquote required for community-maintained methods. |
| **First-run discipline** | At deploy time (per CLAUDE.md) | Recipes that "look right" but fail in the wild. End-of-deploy feedback flow drafts a sanitized issue capturing the gotcha. |
| **Versioning rules** | At commit time (in PR review) | User-visible behavior changes shipped without a version bump (breaks marketplace cache invalidation). |

## Cadence — what actually happens in main

Observed from the commit log (2026-04 to 2026-05):

- **Bot batches** — the bot ships small batches (3-5 recipes per commit), tagged `batch <N>` in the commit message. Catalog grew from ~180 to 1,100+ recipes over the observation window.
- **Source queue** — bot pulls from external sources in priority order (see [`progress/sources.md`](../progress/sources.md)): currently working through selfh.st (1,274 apps, ~92% done); next source queued is awesome-selfhosted-data; Self-Host Weekly newsletter + GitHub issues processed continuously alongside.
- **AI-session PRs** (this Claude Code session) — periodic batches authored on demand: catalog audits, architectural additions (issue-driven contribution model, multi-platform support, agent-platform support, backups module, monitoring module, bundles), bug fixes (#40 broken in-bundle links).
- **End-user issues** — sparse but valuable; recent issues #24-27 (Windows setup gotchas), #40 (broken links), #41 (BookStack URL).
- **Version bumps** — driven by user-visible changes. Recent: `0.17.1 → 0.17.2 → 0.19.x → 0.20.x → 0.21.0 (multi-platform) → 0.22.0 (agent platforms) → 0.23.0 (backups + bundles) → 0.24.0 (monitoring + gstack pointer)`.

## Three layers, one orchestration layer above

The deployment model is a tuple of three independent axes (per CLAUDE.md § Architecture):

1. **What** to host — software → `references/projects/<sw>.md`
2. **Where** to host — infra → `references/infra/<cloud>/<service>.md`
3. **How** to host — runtime → `references/runtimes/<runtime>.md`

Cross-cutting concerns (preflight / dns / tls / smtp / inbound / tunnels / credentials / feedback / backups) live as reusable modules under `references/modules/`.

**A fourth orchestration layer** sits above these: **bundles** (`references/bundles/`). A bundle is a *recipe-of-recipes* — it pairs commonly-co-deployed software for goal-shaped user requests (*"set up an AI homelab"*) and ships the cross-software wiring (env vars / DNS / ports between the constituent recipes). Bundles don't replace single-recipe routing; they're an additional entry point for goal-shaped intents.

## Two-tier coverage

Per CLAUDE.md § *Two-tier coverage model*:

- **Tier 1** — verified recipes in `references/projects/`. Authored ahead of time, audited against upstream docs, kept current via first-run discipline + version bumps. Quality bar: every install method cites upstream URL; community methods flagged with blockquote.
- **Tier 2** — derived live from upstream docs at request time. When the user names software not in the catalog, the skill announces the fallback, fetches upstream live, applies the strict-doc-policy on the fly, and reuses the runtime/infra/module layers. Best-effort, not authoritative.

Tier 2 → Tier 1 graduation is **demand-driven**: 3+ feedback issues for the same software, repeat user, captured non-obvious gotcha, or maintainer-driven deploy.

## Multi-platform shape

The skill is content-agnostic markdown that runs on 7+ AI platforms via per-platform integration:

| Platform | Integration |
|---|---|
| Claude Code | Plugin marketplace (`/plugin marketplace add`); auto-loads via SKILL.md description match |
| Codex | System-prompt embedding (ChatGPT custom instructions) or workspace files (Codex CLI) |
| Cursor | `.cursor/rules/` bundle from `dist/cursor/` |
| Aider | `--read` files + `CONVENTIONS.md` from `dist/aider/` |
| Continue.dev | Context provider + slash command from `dist/continue/config.snippet.yaml` |
| OpenClaw | Workspace skill at `~/.openclaw/workspace/skills/open-forge/SKILL.md` |
| Hermes-Agent | User skill at `~/.hermes/skills/open-forge/SKILL.md` |
| Generic | Single-file bundle from `dist/generic/open-forge-bundle.md` |

The build script (`scripts/build-dist.sh`) generates each platform's bundle by concatenating canonical sources (CLAUDE.md + SKILL.md + the `credentials` and `feedback` modules) into the format that platform expects, plus a sed post-process step that rewrites in-bundle hyperlinks to point at the inlined sections (the original cross-references are valid for the Claude Code plugin install where files coexist, but break in single-file bundles — see issue #40).

## Where each subsystem's docs live

| Subsystem | Doc | Purpose |
|---|---|---|
| Project policy | [CLAUDE.md](CLAUDE.md) | What's in scope; strict-doc rules; sanitization; issue-processing workflow |
| AI-agent landing page | [AGENTS.md](AGENTS.md) | agents.md-standard pointer file for non-Claude-Code agents working on the repo |
| User-facing project doc | [README.md](README.md) | Value prop, install, coverage |
| End-user skill content | [SKILL.md](plugins/open-forge/skills/open-forge/SKILL.md) | Phased workflow, credential handling, post-deploy feedback |
| Per-platform usage | [docs/platforms/*.md](docs/platforms/) | How to use open-forge on Codex / Cursor / Aider / Continue / OpenClaw / Hermes / generic agents |
| Build tooling | [scripts/build-dist.sh](scripts/build-dist.sh) | Regenerates `dist/` bundles; documents itself with usage comment |
| **System architecture** | **this file** | Actors, flow, state stores, quality gates — how it all fits together |

## What this doc deliberately doesn't cover

- **Per-recipe content** — that's the catalog itself; browse `references/projects/` or [DeepWiki](https://deepwiki.com/zhangqi444/open-forge).
- **Policy detail** — strict-doc-policy regex patterns, sanitization strip-list, recipe-structure must-haves are in [CLAUDE.md](CLAUDE.md).
- **Per-platform integration nuance** — those live in [docs/platforms/](docs/platforms/) for Codex / Cursor / Aider / Continue / OpenClaw / Hermes / generic.
- **End-user deployment instructions** — README.md and SKILL.md cover that; this doc is for contributors, maintainers, and AI sessions trying to understand the maintenance system.
