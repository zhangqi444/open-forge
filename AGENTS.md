# AGENTS.md

[`agents.md`](https://agents.md) compatibility — this file orients any AI coding agent (Claude Code, Codex, Cursor, Aider, Continue.dev, OpenClaw, Hermes-Agent, or a custom tools-using LLM) that's working *on* the open-forge codebase. End users **using** the open-forge skill to deploy software should look at [SKILL.md](plugins/open-forge/skills/open-forge/SKILL.md) instead.

> **Canonical reference.** This file is intentionally short. The full architectural treatment, strict-doc-verification policy, two-tier coverage model, sanitization rules, and issue-processing workflow live in [**CLAUDE.md**](CLAUDE.md). Read that for the complete picture — AGENTS.md is the agents.md-standard landing page that points at it.

## What this project is

`open-forge` is a guided self-hosting **skill** distributed via Claude Code's plugin marketplace and adapted for 6+ other AI platforms. It walks users from *"I have a cloud account and a domain"* to *"working app at https://my.domain"* via a phased workflow (preflight → provision → dns → tls → smtp → inbound → hardening → feedback) using 2,200+ verified recipes plus curated bundles for goal-shaped requests (AI homelab, privacy stack) plus a live-derived fallback for the long tail.

This **isn't a typical software repo** — it's a library of platform-agnostic markdown recipes + a thin Bash build script. There's no compiled artifact, no test suite, no lint config. The "build" is regenerating distribution bundles from canonical sources.

## Working on this repo — the rules

Per [CLAUDE.md](CLAUDE.md):

1. **No human PRs — issues only.** Catalog evolves through GitHub issues processed by AI sessions. See [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) for the three input channels (recipe-feedback, software-nomination, method-proposal). Direct PRs are discouraged; if you submit one, the strict-doc policy still applies.
2. **Strict-doc-verification policy.** Every install method in every recipe must cite an upstream URL (`> **Source:** <url>`). Community-maintained methods open with the required ⚠️ blockquote. The README is necessary but **not sufficient** — also read the upstream docs site, repo `docs/install/` tree, and wiki. If upstream-doc fetch fails, **stop**; do not write speculative content. Full rules in [CLAUDE.md § Strict doc-verification policy](CLAUDE.md#strict-doc-verification-policy-mandatory-before-writing-any-recipe).
3. **Sanitization principles.** User-shared content (deploy logs, gotchas, error output) must be stripped of identifiers (domains, IPs, SSH keys, API keys, AWS account IDs, emails) before being merged into recipes or posted to GitHub issues. Full strip-list with regex patterns in [CLAUDE.md § Sanitization principles](CLAUDE.md#sanitization-principles).
4. **Two-tier coverage model.** Tier 1 = verified recipes in `references/projects/`. Tier 2 = live-derived from upstream docs at runtime for software not yet in the catalog. Promotion criteria in [CLAUDE.md § Two-tier coverage model](CLAUDE.md#two-tier-coverage-model).
5. **In-scope test.** Before adding a recipe: deployable service / static-site generator / CLI agent / AI inference server / CI runner / storage backend → ✅. Library / desktop app / SaaS-only → ❌. Decision rule + edge-case table in [CLAUDE.md § Is this software in scope?](CLAUDE.md#is-this-software-in-scope).

## Build / test / lint

There is no traditional build / test / lint pipeline. The single build artifact is the multi-platform distribution bundles under `dist/`:

```bash
./scripts/build-dist.sh all          # regenerate bundles for all 7 platforms
./scripts/build-dist.sh codex        # just Codex
./scripts/build-dist.sh openclaw     # just OpenClaw
```

**Required after touching any of:** `CLAUDE.md`, `plugins/open-forge/skills/open-forge/SKILL.md`, `plugins/open-forge/skills/open-forge/references/modules/*.md`. The bundles concatenate these files; they drift if not regenerated, which silently breaks non-Claude-Code platforms.

CI enforces this — see [`.github/workflows/dist-bundles.yml`](.github/workflows/dist-bundles.yml). If the `dist-bundles-up-to-date` check fails on your PR, the fix is always: run `./scripts/build-dist.sh all` from the repo root, commit the changes, push.

## Versioning

`plugins/open-forge/.claude-plugin/plugin.json` `version` controls what the Claude Code marketplace fetches.

- **Bump on**: skill description change, new project / runtime / infra / module, major recipe rewrite, anything user-visible.
- **Don't bump on**: typo fixes, internal cleanups, lint-only changes.

## Author convention

Commits authored as `Qi Zhang <zhangqi444@gmail.com>` — set inline via env vars (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`). Never write to `git config`.

## Recommended companion skill — `garrytan/gstack`

If you're a Claude Code session working on this repo, install [`garrytan/gstack`](https://github.com/garrytan/gstack) — Garry Tan's SDLC slash-command bundle. Its `/review`, `/qa`, `/ship`, `/cso`, `/learn`, and `/plan-eng-review` commands map directly onto the maintenance workflows used here. Install:

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack \
  && cd ~/.claude/skills/gstack && ./setup
```

See [CLAUDE.md § Recommended companion: garrytan/gstack](CLAUDE.md#recommended-companion-garrytangstack) for the per-command mapping. Optional but encouraged.

## Per-platform integration (when working on platform-specific bits)

If your patch touches platform-specific behavior, check the per-platform integration docs:

- [Claude Code](README.md#install) — canonical platform; auto-discovers via plugin marketplace
- [Codex](docs/platforms/codex.md) — system-prompt embedding or workspace files
- [Cursor](docs/platforms/cursor.md) — `.cursor/rules/` bundle
- [Aider](docs/platforms/aider.md) — `--read` flags + `CONVENTIONS.md`
- [Continue.dev](docs/platforms/continue.md) — context provider + slash command
- [OpenClaw](docs/platforms/openclaw.md) — workspace skill
- [Hermes-Agent](docs/platforms/hermes.md) — user skill
- [Generic agents](docs/platforms/generic.md) — any tools-using LLM

Cross-platform behavior changes (e.g. credential handling) live in `references/modules/` so all platforms inherit them through the dist bundles.

## Reference

For everything not covered above:
- **[BRD.md](BRD.md)** — *intent*: why the project exists, who it's for, success criteria, what we're explicitly not building.
- **[CLAUDE.md](CLAUDE.md)** — *policy*: what's in scope, strict-doc rules, sanitization, processing workflow.
- **[ARCHITECTURE.md](ARCHITECTURE.md)** — *system shape*: actors, data flow, state stores, quality gates, cadence.

User-facing project documentation lives in [README.md](README.md). End-user-skill content lives in [plugins/open-forge/skills/open-forge/SKILL.md](plugins/open-forge/skills/open-forge/SKILL.md).
