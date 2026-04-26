# CLAUDE.md

Instructions for any Claude Code session working *on* the open-forge plugin (not running it). Different audience from `plugins/open-forge/skills/open-forge/SKILL.md`, which is what an end-user's Claude reads to *use* the plugin.

## What is open-forge

A Claude Code plugin/skill that turns "read a README, copy-paste 30 lines of bash, debug for hours" into a guided chat where Claude executes everything via the user's local CLI tools and the user only makes choices.

## Architecture — 3 layers, asked in 3 questions

A deployment is a tuple of three independent axes, asked in this order:

| # | Question | Layer | Examples |
|---|---|---|---|
| 1 | **What** to host? | software | OpenClaw, Ghost, Mastodon, Vaultwarden, Nextcloud |
| 2 | **Where** to host? | infra (cloud or local) | AWS / Hetzner / DigitalOcean / GCP / Azure / bring-your-own-VPS / **localhost** |
| 3 | **How** to host (within that cloud)? | infra-service + runtime | AWS: Lightsail blueprint, Lightsail Ubuntu + Docker, EC2 + native, EKS, ECS Fargate. Hetzner: Cloud CX + Docker, Cloud CX + native. localhost: Docker Desktop, native. |

The third question is *dynamically generated* from (software, cloud) — different clouds expose different compute services, and some software has vendor-bundled blueprints on specific clouds.

**Some infra services bundle the runtime** — EKS → Kubernetes, Lightsail OpenClaw blueprint → vendor's pre-baked install. In those cases the "runtime" question is not asked separately. **Other services give runtime choice** — EC2, plain VPS, localhost — there we ask Docker vs native vs k3s.

**Reusability is the test.** "Install Docker + run docker-compose" is the same on Lightsail Ubuntu, Hetzner CX-line, a DO droplet, and a localhost — write it once in the runtime layer, reference from every project. "Install k3s" is the same across clouds — write it once. Project recipes should be 80% software-specific concerns and contain *no* per-runtime install commands beyond a one-line link.

### File layout for the 3 layers

```
references/
├── projects/<sw>.md                       # software layer (thin)
├── infra/
│   ├── aws/
│   │   ├── lightsail-blueprint.md         # vendor-bundled, software-specific
│   │   ├── lightsail-ubuntu.md            # Lightsail as a plain VM
│   │   ├── ec2.md
│   │   ├── eks.md
│   │   └── ecs-fargate.md
│   ├── hetzner/cloud-cx.md
│   ├── digitalocean/droplet.md
│   ├── gcp/compute-engine.md
│   ├── byo-vps.md                         # user provides any Linux VPS, Claude SSH-es in
│   └── localhost.md                       # user's own machine, Claude runs commands directly
├── runtimes/
│   ├── docker.md                          # reusable wherever Docker works
│   ├── native.md                          # native installer (curl/apt)
│   └── kubernetes.md                      # reusable across EKS/GKE/AKS/k3s
└── modules/                               # cross-cutting (preflight, dns, tls, smtp providers, inbound forwarders, tunnels, backups, monitoring)
```

`localhost.md` is a first-class infra — for many projects (especially OpenClaw), running locally is the default upstream path. Same conversational UX as a cloud deploy; differences are: no SSH (Claude runs commands directly), no provisioning, public reach via tunnel (`references/modules/tunnels.md`).

## Operating principles

1. **Do more, ask less. Non-tech-friendly.** Default to autonomous execution. Only prompt the user for things only they can decide or provide: credentials, opinionated choices, things that touch their accounts at other companies. Hide everything Claude can figure out from the recipe.
2. **Towards production-ready architecture.** Even single-node hobby deploys should be on a path to backups, monitoring, TLS, key rotation, OS updates, and least-privilege firewalls. Don't write recipes that "work" but leave the system one outage away from data loss.
3. **Security in mind.** Treat tokens/keys as toxic — never log them, rotate after chat exposure, prefer fragment URLs over query strings. Default firewalls to closed; open ports explicitly. Default to SSH key auth; never password. Let's Encrypt for any public endpoint. Sandbox agent tool execution where the runtime supports it.
4. **One question at a time.** Use `AskUserQuestion` for structured choices. Reserve free-text for credentials and identifiers (domain names, emails). No upfront questionnaires.
5. **Auto-install with confirmation, never silently.** If `jq` or `aws` is missing, propose the install command, get one-line approval, then run.
6. **Reference upstream docs; don't replace them.** Recipes condense and translate upstream documentation into Claude-actionable steps — they aren't the source of truth for the product itself. Always link the upstream pages we summarized (e.g. `docs.openclaw.ai/install/docker`, AWS Lightsail user guide, Bitnami docs). Reasons: (a) users can verify what we condensed, (b) when upstream drifts our recipe goes stale fast and the link is the recovery path, (c) credit where due.
7. **Don't invent — interface.** open-forge is a chat-friendly interface to existing tools. Claude is the orchestrator; the user's existing software stack (AWS CLI, Docker, openclaw, ssh, gh, registrar UIs) is the substrate. **Do not** build custom DSLs, YAML schemas, CLI tools, deployment managers, or wrappers around upstream tools. **Do not** reimplement what an upstream tool already does (e.g. don't rebuild `openclaw onboard`'s prompts in chat — call the command). The state file is a thin orchestration helper for resume, nothing more. *Caveat:* "don't invent" applies to **fabricating a deployment path the upstream doesn't support** (e.g. authoring a Helm chart for a project that has no chart). It does **not** mean "no tooling." If upstream supports Docker / k8s / Helm / Terraform, lean on every skill and MCP that helps you orchestrate those paths well — see *Companion skills & MCPs* below.

## Companion skills & MCPs

open-forge orchestrates *upstream-blessed* deployment paths. To do that well, recipes are encouraged to depend on companion skills/MCPs as soft dependencies — declared in prose, not enforced. The filter is one question:

> Does this tool help me **drive** an upstream-supported deploy path more reliably?

| Shape | Stance | Examples |
|---|---|---|
| **Operators** — read state, query docs, drive existing CLIs more accurately | ✅ Embrace | `awsdocs` MCP, `gcp-docs` MCP, `cloudflare` MCP, GitHub MCP (fetch upstream `docker-compose.yml` / `charts/`), k8s state-query MCPs |
| **Generators** — author config from scratch | ❌ Avoid by default | `dockerfile-generator`, `k8s-yaml-generator`, `helm-generator`, `terraform-generator`. Only justified when upstream genuinely ships nothing and we deliberately wrap. |
| **Plain CLIs** | ✅ Default substrate | `docker`, `kubectl`, `helm`, `aws`, `gcloud`, `az`, `gh`, `ssh`, `terraform` |

How to reference companion tooling — **fallback hierarchy**, in order of preference:

1. **Companion skill/MCP**, if available. Name it in SKILL.md / recipe body in prose: *"If the k8s state MCP is available, use it to confirm pod readiness; otherwise parse `kubectl get pods -o json`."* Claude uses it when present, falls back gracefully when not.
2. **Captured docs in `references/`**, if no skill/MCP exists. Distill the relevant upstream pages (Helm chart values, k8s CRD schema, AWS CLI flags for the specific service) into a focused reference under `references/modules/<topic>.md` or alongside the recipe. Cite the upstream URL as the source of truth — captured docs are a lossy snapshot, the link is the recovery path (principle #6).
3. **Inline upstream-doc links** as a last resort, when even capture is overkill — let Claude WebFetch them on demand.

Where to declare companion tooling:

- **In recipe frontmatter**, optionally list `companion-skills:` / `companion-mcps:` as documentation (not enforced — no formal deps mechanism in plugin manifests yet).
- **In `plugins/open-forge/.mcp.json`**, register MCPs the recipes depend on heavily so they install transparently with the plugin. Reserve this for read-only docs/state MCPs; never wrap deployment commands.
- **For dev work on open-forge itself** (CI, settings audit, plugin packaging): use whatever skills help your local workflow (`gh-fix-ci`, `claude-settings-audit`) — these don't need to ship with the plugin.

When a recipe is exercised end-to-end and a companion skill/MCP proved necessary — or a captured doc was added to `references/` — record it in the recipe's *Compatible runtimes* or a new *Companion tooling* note alongside upstream doc links. Same first-run discipline applies.

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
        │   ├── runtimes/<name>.md         ← runtime layer (docker.md, native.md)
        │   ├── infra/<name>.md            ← infra layer (aws/, hetzner/, digitalocean/, gcp/, byo-vps.md, localhost.md)
        │   └── modules/<name>.md          ← cross-cutting (preflight, dns, tls, smtp providers, inbound forwarders, tunnels, backups, monitoring)
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

## Refactor (started 2026-04-24, completed 2026-04-26)

Initial state collapsed three axes into linear "Path A/B/C" inside `openclaw.md`, which hid valid combos and biased preflight toward AWS even for non-AWS deployments. Migrated to the 3-layer file layout above. Order:

1. ✅ CLAUDE.md model locked in (this section).
2. ✅ Preflight refactor — branch on infra choice; only require AWS CLI when infra ∈ AWS.
3. ✅ Skeleton infra adapters: `infra/aws/lightsail.md` (Bitnami + OpenClaw blueprints share this; the blueprint-vs-Ubuntu split is a project-recipe concern, not a separate adapter), `infra/aws/ec2.md`, `infra/hetzner/cloud-cx.md`, `infra/digitalocean/droplet.md`, `infra/gcp/compute-engine.md`, `infra/byo-vps.md`, `infra/localhost.md`.
4. ✅ Runtime modules: `runtimes/docker.md`, `runtimes/native.md`. Extracted from openclaw.md Paths B and C.
5. ✅ Slim down `projects/openclaw.md` — software-layer concerns only; reference runtimes + infra modules for everything else.
6. ✅ Add `modules/tunnels.md` for localhost public-reach (Cloudflare Tunnel / Tailscale / ngrok).
7. ✅ Update SKILL.md, README.md support tables and prompts. Bump plugin version (→ 0.6.0).

Path A/B/C terminology retired. Future work tracked in each adapter's *TODO — verify on subsequent deployments* section, not here.

## Behavioral guidelines (echoes of bota CLAUDE.md, kept here for autonomy)

- **Think before coding.** State assumptions; ask when uncertain; surface tradeoffs.
- **Simplicity first.** Minimum recipe content that works; no speculative abstractions.
- **Surgical changes.** When updating a recipe after a deploy, change only what the deploy taught us. Don't "improve" adjacent sections.
- **Goal-driven execution.** A recipe edit is "done" when the next deploy can use it without manual fixes.
- **Documentation updates** (the recipes themselves) are a deliverable of every deployment, not a follow-up.
