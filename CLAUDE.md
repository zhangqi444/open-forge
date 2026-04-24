# CLAUDE.md

Instructions for any Claude Code session working *on* the open-forge plugin (not running it). Different audience from `plugins/open-forge/skills/open-forge/SKILL.md`, which is what an end-user's Claude reads to *use* the plugin.

## What is open-forge

A Claude Code plugin/skill that turns "read a README, copy-paste 30 lines of bash, debug for hours" into a guided chat where Claude executes everything via the user's local CLI tools and the user only makes choices.

## Architecture — 3 layers that combine

A deployment is a tuple of three independent axes:

```
software  ×  runtime  ×  infra
```

| Layer | What it owns | Examples | Lives in |
|---|---|---|---|
| **software** | What the app *is*, app-specific config, gotchas, mail block shape, admin paths | Ghost, OpenClaw, Mastodon, Vaultwarden, Nextcloud | `references/projects/<name>.md` |
| **runtime** | How the software runs on a host | native (curl/apt installer), Docker + compose, Kubernetes, vendor-managed blueprint | `references/runtimes/<name>.md` |
| **infra** | The underlying VM / cluster + how to provision it | AWS Lightsail, Hetzner Cloud, DigitalOcean, GCP Compute, EC2 | `references/infra/<name>.md` |

**Reusability is the test.** "Install Docker + run docker-compose" is the same on Lightsail Ubuntu, Hetzner CX-line, and a DO droplet — write it once in the runtime layer, reference from every project. "Install k3s" is the same across clouds — write it once. Project recipes should be 80% software-specific concerns and contain *no* per-runtime install commands beyond a one-line link.

**Vendor-managed blueprints** (Lightsail Ghost-Bitnami, Lightsail OpenClaw) are a fourth path — they bundle software+runtime+sometimes-infra into one opinionated package. Document them as a *runtime* (e.g. `references/runtimes/lightsail-blueprint.md`) and have the project recipe note "this software ships with a Lightsail blueprint, see the blueprint runtime."

## Operating principles

1. **Do more, ask less. Non-tech-friendly.** Default to autonomous execution. Only prompt the user for things only they can decide or provide: credentials, opinionated choices, things that touch their accounts at other companies. Hide everything Claude can figure out from the recipe.
2. **Towards production-ready architecture.** Even single-node hobby deploys should be on a path to backups, monitoring, TLS, key rotation, OS updates, and least-privilege firewalls. Don't write recipes that "work" but leave the system one outage away from data loss.
3. **Security in mind.** Treat tokens/keys as toxic — never log them, rotate after chat exposure, prefer fragment URLs over query strings. Default firewalls to closed; open ports explicitly. Default to SSH key auth; never password. Let's Encrypt for any public endpoint. Sandbox agent tool execution where the runtime supports it.
4. **One question at a time.** Use `AskUserQuestion` for structured choices. Reserve free-text for credentials and identifiers (domain names, emails). No upfront questionnaires.
5. **Auto-install with confirmation, never silently.** If `jq` or `aws` is missing, propose the install command, get one-line approval, then run.
6. **Reference upstream docs; don't replace them.** Recipes condense and translate upstream documentation into Claude-actionable steps — they aren't the source of truth for the product itself. Always link the upstream pages we summarized (e.g. `docs.openclaw.ai/install/docker`, AWS Lightsail user guide, Bitnami docs). Reasons: (a) users can verify what we condensed, (b) when upstream drifts our recipe goes stale fast and the link is the recovery path, (c) credit where due.

## Recipe structure (must-have sections)

Every `references/projects/<software>.md` should have:

| Section | Purpose |
|---|---|
| **Frontmatter** (name + description) | Loaded into context whenever the skill triggers. Keep concise; this is for Claude, not the user. |
| **Inputs to collect** (table keyed by phase) | Exact prompts, structured-choice options, defaults. So the same recipe is consistent across runs. |
| **Compatible runtimes** | Which runtime modules this software supports + recommended default |
| **Phase applicability** | Which of preflight/provision/dns/tls/smtp/inbound/hardening apply or skip |
| **Per-phase content** | Project-specific commands, config patches, verification checks |
| **Gotchas (consolidated)** | One-line summaries of every non-obvious thing learned in production. Single source of truth. |
| **TODO — verify on subsequent deployments** | Open questions to resolve on the next real deploy. Empty = recipe is fully validated. |

`references/runtimes/<name>.md` and `references/infra/<name>.md` mirror this with their own scope (no `Inputs to collect` for infra usually — preflight handles AWS profile/region; infra adds bundle/region-specific bits).

## First-run discipline

When a recipe is exercised end-to-end against a real deployment for the first time:

1. Capture every gotcha that surprised us into the recipe's *Gotchas* section.
2. Resolve / delete TODO items as they're answered.
3. Update the deployment state file's phase notes.
4. Bump `plugin.json` `version` (see *Versioning* below).
5. Commit.

This is how the recipe stops being a guess and becomes a known-working deployment template. Don't skip it.

## File layout

```
open-forge/
├── CLAUDE.md                              ← you are reading
├── README.md                              ← user-facing, lives on GitHub
├── LICENSE                                ← MIT
├── .claude-plugin/marketplace.json        ← marketplace manifest
└── plugins/open-forge/
    ├── .claude-plugin/plugin.json         ← plugin manifest (version!)
    └── skills/open-forge/
        ├── SKILL.md                       ← end-user-Claude entrypoint
        ├── references/
        │   ├── projects/<name>.md         ← software layer
        │   ├── runtimes/<name>.md         ← runtime layer (planned — see refactor below)
        │   ├── infra/<name>.md            ← infra layer
        │   └── modules/<name>.md          ← cross-cutting (preflight, dns, tls, smtp providers, inbound forwarders, backups, monitoring)
        └── scripts/                       ← reused operational scripts; empty by default
```

`scripts/` stays empty unless something is reused 3+ times across deployments. Inline commands in recipes are clearer for one-off use.

## Versioning + publish flow

`plugin.json` `version` controls what the Claude Code marketplace fetches.

- **Bump on**: skill description change, new project/runtime/infra, major recipe rewrite, anything that changes user-visible behavior.
- **Don't bump on**: typo fixes, internal comment cleanups, lint-only changes.

Publish flow:

1. Local commit (with version bump if applicable).
2. `git push` to `github.com/zhangqi444/open-forge`.
3. End user runs `/plugin marketplace update zhangqi444/open-forge` then re-installs.

## Author convention

Commits authored as `Qi Zhang <zhangqi444@gmail.com>` — set inline via env vars (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`), **don't write to git config**.

## Known refactor needed

Current state mixes the runtime layer into project recipes:

- `references/projects/openclaw.md` has Path A (Lightsail blueprint), Path B (Ubuntu native), Path C (Docker) all in one file. The runtime-specific install/upgrade/restart steps should move to `references/runtimes/{lightsail-blueprint,native,docker}.md`, and openclaw.md should become "software-layer concerns + which runtimes are compatible + which is recommended."
- Same will apply to ghost.md if a Docker runtime is later added.

Plan: do the split incrementally — first time a second project shares a runtime with OpenClaw, extract the runtime layer rather than copy-paste. Don't pre-extract on speculation.

## Behavioral guidelines (echoes of bota CLAUDE.md, kept here for autonomy)

- **Think before coding.** State assumptions; ask when uncertain; surface tradeoffs.
- **Simplicity first.** Minimum recipe content that works; no speculative abstractions.
- **Surgical changes.** When updating a recipe after a deploy, change only what the deploy taught us. Don't "improve" adjacent sections.
- **Goal-driven execution.** A recipe edit is "done" when the next deploy can use it without manual fixes.
- **Documentation updates** (the recipes themselves) are a deliverable of every deployment, not a follow-up.
