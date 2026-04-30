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

## Is this software in scope?

open-forge is for **deployable self-hosted services**. Use these criteria when deciding whether a piece of software belongs as a Tier 1 recipe (see *Two-tier coverage model* below).

### Inclusion criteria — recipe is in scope when ALL are true

1. **Software runs as a deployed service or is served from a host the user owns**: long-running daemon, scheduled job, web service, API, CLI agent, or static asset published to a host.
2. **Source code or binaries are user-installable on infrastructure they control**: cloud VM, VPS, k3s cluster, or localhost. Paid AMIs / vendor stacks (Bitnami, Dify Premium, etc.) count — closed-source SaaS-only does not.
3. **At least one upstream-documented install method or canonical install artifact in-repo** exists, so the strict-doc-policy below has something to verify against.

### Exclusion criteria — out of scope

- **Pure libraries / SDKs / packages** that you `import` or call (Unsloth, requests, lodash). No deployment surface.
- **Desktop / mobile end-user apps** with no self-hosted server side (Slack desktop, VS Code, Discord client).
- **SaaS / managed-only products** with no self-host distribution (Notion, Linear, Figma).
- **Dev-only tooling that runs ephemerally on a developer machine** and is never deployed (Storybook *dev* mode, Vite dev server, REPLs).

### Edge cases — borderline classes

| Class | Verdict | Recipe shape |
|---|---|---|
| **Static-site generators** (Hugo, Jekyll, Docusaurus, Storybook in production-preview mode) | ✅ in scope | Thin: `<sg> build` → static dir → deploy via a static-host module (nginx / S3+CDN / Pages). The SG-specific bit is build config, theme path, content tree. |
| **CLI agents** (Aider, OpenClaw, Hermes-Agent) | ✅ in scope | Install on a host, run as daemon or interactive CLI. Standard recipe shape. |
| **AI inference servers** (vLLM, Ollama, TGI) | ✅ in scope | Deployed services exposing HTTP APIs. Standard recipe shape. |
| **AI training libraries** (Unsloth, axolotl, transformers) | ❌ out of scope | Libraries called from training scripts, not deployed services. If a "training environments" track ever exists, it's a separate category — not project recipes under `references/projects/`. |
| **CI runners** (GitHub Actions self-hosted, Buildkite agent) | ✅ in scope | Long-running daemon attached to a control plane. Standard recipe shape. |
| **Standalone databases** (Postgres, ClickHouse, Redis) | ⚠️ borderline | Useful but usually a dependency of another recipe rather than a deployment goal. Document as a supporting service inside the consuming recipe; only write a standalone recipe when there's clear demand. |
| **Storage backends** (MinIO, SeaweedFS, Garage) | ✅ in scope | Self-hostable services with HTTP APIs. Standard recipe shape. |

### When in doubt

Ask: *"Would the user need open-forge to walk them through provisioning + DNS + TLS + ongoing lifecycle for this?"* If yes, write a recipe. If no (e.g. they'd just `pip install` it inside their own scripts), it's out of scope — or fall back to Tier 2 (below) for one-off requests.

## Operating principles

1. **Do more, ask less. Non-tech-friendly.** Default to autonomous execution. Only prompt the user for things only they can decide or provide: credentials, opinionated choices, things that touch their accounts at other companies. Hide everything Claude can figure out from the recipe.
2. **Towards production-ready architecture.** Even single-node hobby deploys should be on a path to backups, monitoring, TLS, key rotation, OS updates, and least-privilege firewalls. Don't write recipes that "work" but leave the system one outage away from data loss.
3. **Security in mind.** Treat tokens/keys as toxic — never log them, rotate after chat exposure, prefer fragment URLs over query strings. Default firewalls to closed; open ports explicitly. Default to SSH key auth; never password. Let's Encrypt for any public endpoint. Sandbox agent tool execution where the runtime supports it.
4. **One question at a time.** Use `AskUserQuestion` for structured choices. Reserve free-text for credentials and identifiers (domain names, emails). No upfront questionnaires.
5. **Auto-install with confirmation, never silently.** If `jq` or `aws` is missing, propose the install command, get one-line approval, then run.
6. **Reference upstream docs; don't replace them.** Recipes condense and translate upstream documentation into Claude-actionable steps — they aren't the source of truth for the product itself. Always link the upstream pages we summarized (e.g. `docs.openclaw.ai/install/docker`, AWS Lightsail user guide, Bitnami docs). Reasons: (a) users can verify what we condensed, (b) when upstream drifts our recipe goes stale fast and the link is the recovery path, (c) credit where due. **See *Strict doc-verification policy* below — every install method documented by upstream must have its own recipe section, verified against upstream before being written.**
7. **Don't invent — interface.** open-forge is a chat-friendly interface to existing tools. Claude is the orchestrator; the user's existing software stack (AWS CLI, Docker, openclaw, ssh, gh, registrar UIs) is the substrate. **Do not** build custom DSLs, YAML schemas, CLI tools, deployment managers, or wrappers around upstream tools. **Do not** reimplement what an upstream tool already does (e.g. don't rebuild `openclaw onboard`'s prompts in chat — call the command). The state file is a thin orchestration helper for resume, nothing more. *Caveat:* "don't invent" applies to **fabricating a deployment path the upstream doesn't support** (e.g. authoring a Helm chart for a project that has no chart). It does **not** mean "no tooling." If upstream supports Docker / k8s / Helm / Terraform, lean on every skill and MCP that helps you orchestrate those paths well — see *Companion skills & MCPs* below.

## Credential handling (expanded from Operating Principle #3)

Pasting raw credentials into Claude Code is risky — secrets enter session history, may be relayed via MCP servers, and could appear in shared transcripts. The skill must offer safer alternatives **first** and only fall back to direct paste with explicit risk acknowledgement.

### The five patterns (priority order)

| # | Pattern | When to suggest |
|---|---|---|
| 1 | **Local file path** — user gives skill a path; skill `cat`s it | Personal-use API keys; user already has a `.env` or `.secrets` file |
| 2 | **Env var name** — user pre-exports the secret; skill reads `$<NAME>` | Shell users with secrets in `.envrc` / `.bashrc` |
| 3 | **Cloud-CLI session** — user runs `<provider> login` ahead of time; skill uses the resulting profile / session | Default for AWS, GCP, Azure, GitHub, DigitalOcean, Hetzner, Cloudflare |
| 4 | **Secrets-manager reference** — user gives skill a `op://` / `bw://` / `vault://` reference; skill calls the matching CLI just-in-time | Users with proper secret management (1Password, Bitwarden, Vault, AWS Secrets Manager, GCP Secret Manager, `pass`) |
| 5 | **Direct chat paste** — last resort, requires risk acknowledgement | When patterns 1-4 don't apply; user explicitly opts in |

### Hard rules

- **Always offer the five patterns** when asking for any sensitive input. Don't silently accept a paste; don't assume Claude Code is a vault.
- **Surface the risk** before accepting a direct paste: *"the key will live in this session's history; rotate after deploy completes."*
- **Never accept SSH key contents.** Always ask for the key file *path* (skill uses `ssh -i <path>`); never the key material itself in chat.
- **Validate before proceeding**: `test -r <path>` for file paths; `test -n "$<VAR>"` for env vars; smoke-command for cloud-CLI sessions and secrets-manager refs.
- **Refuse files with permissions wider than 600**; offer to `chmod 600` first.
- **Detect accidental pastes** (regex for `re_*`, `sk-*`, `AKIA*`, etc. in a prompt that expected a path) and stop the user before the secret commits to chat.
- **End-of-deploy rotation reminder** if the user pasted any secret directly during the deploy: list each pasted credential + the provider's dashboard URL; recommend rotating now that the deploy is done.

The full pattern catalog with skill prompt templates, per-credential-class recommendations, and failure-mode handling lives in [`plugins/open-forge/skills/open-forge/references/modules/credentials.md`](plugins/open-forge/skills/open-forge/references/modules/credentials.md).

## Strict doc-verification policy (mandatory before writing any recipe)

Recipes are condensations of upstream docs; condensing what we haven't read is speculation. Past failures (the v0.7.0 Helm chart claim sourced from a search snippet, the v0.6.0 OpenClaw "every blessed path" claim that was 4 of 17 because we trusted the README's enumeration) traced back to this. The policy:

### Before writing or expanding any project / infra recipe

1. **Read the upstream README verbatim.** Not summarized — the actual README. Note: the README is necessary but **not sufficient** — many projects' READMEs are deliberately minimal and point at a separate docs site for install methods.
2. **Locate the upstream install-method index.** Typically:
   - The project's docs site (`docs.PROJECT.ai`, `PROJECT.com/docs`, `PROJECT.github.io`, etc.).
   - The repo's `docs/install/` or `website/docs/getting-started/` tree.
   - The repo's wiki (often a separate `<repo>.wiki.git` clone).
3. **Enumerate every method documented under that index.** Include:
   - First-party install scripts (`install.sh`, `install.ps1`, vendor blueprints).
   - First-party Docker / Compose / Kubernetes / Helm support.
   - First-party package-manager support (Homebrew, Nix, Pacman, etc.).
   - First-party PaaS templates (`fly.toml`, `render.yaml`, Railway / Zeabur / Sealos one-click buttons published by upstream).
   - First-party cloud templates (Terraform / CDK / Computing Nest published by upstream).
4. **Read the canonical install artifacts in the repo:** `docker-compose.yml`, `Dockerfile`, `flake.nix`, the project's primary config-file example. These often surface details the docs gloss over (service inventory, env-var matrix).
5. **Write one section per documented method.** No merging, no skipping. Each section's first line cites the upstream URL it's derived from.

### What counts as "official"

| Source | Official? |
|---|---|
| Upstream's own README | ✅ |
| Upstream's own docs site (linked from README) | ✅ |
| Upstream's repo `docs/` or `website/` tree | ✅ |
| Upstream's repo wiki | ✅ |
| Upstream-published PaaS deploy buttons (Railway/Render/Fly/etc.) where the manifest lives in the upstream repo | ✅ |
| Community-maintained Docker images / Helm charts when upstream ships none | ⚠️ Allowed but **must be flagged** as "community-maintained, verify source"; recipe lists multiple options (most-active first), doesn't pick a winner |
| Anything else (third-party blogs, search snippets, my training data) | ❌ Not allowed as the basis for a section. If upstream ships no path for X, do not invent one. |

### When upstream-doc fetch fails

- WebFetch rate-limited / 403 / 404 → try `raw.githubusercontent.com/<org>/<repo>/<branch>/<path>` for repo content.
- Wiki page WebFetch fails → `git clone https://github.com/<org>/<repo>.wiki.git` and read locally.
- All fetch paths fail → **stop**. Do not write speculative content. Either: (a) ask the user to paste relevant doc text, (b) wait until access is restored, or (c) write only the sections for methods we *did* read and note in the recipe's TODO that the rest is pending verification.

### Community-maintained methods — flagging requirements

When a recipe documents a method upstream doesn't ship (e.g. A1111 + ComfyUI Docker, Helm charts for many projects), the section MUST:

1. Open with an explicit "community-maintained" note in a blockquote.
2. List **multiple** options when they exist (most-active first; reference upstream README's pointer if upstream lists them).
3. Frame commands as "illustrative — verify the README at the version you pull"; never present community-chart `--set` values as authoritative.
4. Document the gap in the recipe's TODO section: "Verify which community option is most actively maintained at first-deploy time."

### Retroactive application

When this policy is added (or strengthened), every existing recipe must be re-verified against its upstream docs index. If the verification surfaces a missing method, file it in that recipe's TODO, write the missing section, and bump the plugin version.

### When in doubt

Ask the user whether to pause for verification or accept the README's enumeration. Don't silently downgrade thoroughness.

---

## Two-tier coverage model

open-forge ships a finite catalogue of verified recipes (Tier 1) plus a documented fallback for everything else (Tier 2). Both tiers obey the strict-doc-policy above; the difference is *when* the verification happens.

### Tier 1 — verified recipes (the catalogue)

The current set under `references/projects/`. Authored ahead of time, audited against upstream docs, kept current via the first-run discipline + version bumps. **Quality bar:**

- Every install method has a `> **Source:** <upstream URL>` line at the top of its section.
- Community-maintained methods open with the required ⚠️ blockquote per *Community-maintained methods — flagging requirements*.
- Gotchas captured from real deploys; TODOs track unresolved verifications.
- Plugin version bumped on each user-visible change.

### Tier 2 — derived live from upstream docs

When a user asks for software that has no Tier 1 recipe, the skill **falls back** instead of refusing:

1. **Announce the fallback in one sentence**: *"This software isn't in our verified recipe set — I'll fetch upstream docs live and reuse the runtime / infra modules. Treat my output as best-effort, not authoritative."*
2. **Apply the strict-doc-policy on the fly** — same rules as Tier 1:
   - Read upstream README via `WebFetch`. If 403/404, fall back to `raw.githubusercontent.com` paths and/or `git clone` the docs repo locally.
   - Locate the upstream install-method index (docs site, repo `docs/install/` tree, wiki).
   - Enumerate methods from upstream — **do not invent**. If fetches fail, stop and tell the user; never speculate to fill a gap.
   - Read canonical install artifacts (`Dockerfile`, `docker-compose.yml`, `helm/`, `flake.nix`).
3. **Reuse runtime + infra + cross-cutting modules** under `references/runtimes/`, `references/infra/`, `references/modules/` for all the reusable parts (Docker install, k8s prereqs, VM provisioning, DNS, TLS, SMTP). Tier 2 is mostly *software-specific* on top of those — same shape as Tier 1, just authored at request time.
4. **Cite every upstream URL** the same way Tier 1 does.
5. **Offer to capture the result** as a new Tier 1 recipe when the deploy succeeds — that's how the catalogue grows. The captured recipe must still go through first-run discipline before claiming Tier 1 status.

### Routing

The skill checks Tier 1 first by name match against `references/projects/*.md`. If no match, fall back to Tier 2 with the announcement above. **Never silently mix tiers** — the user should always know which tier they're in, since the verification depth differs.

### Quality boundary

Tier 2 output is **best-effort, not authoritative.** It will hallucinate at the edges of upstream docs we couldn't fetch; it skips the iterative refinement that Tier 1 recipes get from real deploys. Tell the user this. They're trading verification depth for coverage breadth.

### Tier 2 → Tier 1 graduation criteria

The catalogue grows demand-driven, not by guess. Promote a Tier 2 deploy to a Tier 1 recipe when ANY of:

1. **3+ feedback issues** for the same software (demand signal — see *Issue-driven contribution model*).
2. **Same user has deployed it 3+ times** and asks for first-run discipline applied.
3. **A Tier 2 deploy surfaced a non-obvious gotcha** that's likely to bite the next person — capture the gotcha as a recipe even if demand is small (one-shot promotion is allowed when the value is in the captured knowledge).
4. **A maintainer chooses to deploy the software themselves** (sunk cost is acceptable).

Don't author Tier 1 recipes speculatively from a "popular self-host" list — without a real demand signal, the compounding effect can't kick in and the upfront cost goes to waste.

---

## Issue-driven contribution model

The catalogue evolves through GitHub issues, not direct human PRs. AI coding sessions (whether triggered by a maintainer running this skill, by a scheduled job, or by a webhook) read incoming issues, verify them against upstream docs per *Strict doc-verification policy*, and author patches.

### Three input channels

GitHub issue templates under `.github/ISSUE_TEMPLATE/` define the structured input:

| Template | When to use | Filed by |
|---|---|---|
| `recipe-feedback.yml` | A user deployed via the skill and wants to suggest recipe edits (gotchas captured, install steps that surprised them, sections that were wrong/outdated). The skill drafts these automatically at the end of a deploy. | End user (skill-assisted) |
| `software-nomination.yml` | A user wants software added to the Tier 1 catalogue. Must include rationale + upstream URL + the user's intended deploy combo. | End user |
| `method-proposal.yml` | A user knows an upstream-supported install method that an existing recipe doesn't cover. Must include the upstream URL where the method is documented. | End user |

A blank-issue / off-template issue is treated as a request for routing — close politely with a pointer to the templates.

### Why issues, not PRs

- **Sanitization happens at submission time.** The skill (or a careful manual filer) redacts identifiers before posting; the issue templates encode the structure. PRs from random users could include credentials in commit history that can't be cleanly removed.
- **Verification happens centrally.** Every change is re-verified against upstream by the AI session that processes the issue, not trusted because someone filed a PR.
- **Demand signal lives in the issue stream.** Issues with the most thumbs-up / cross-linking / repeat filings are the demand signal that drives Tier 2 → Tier 1 graduation.

### Direct human PRs

Discouraged. If a maintainer writes a PR by hand, it's still subject to the strict-doc-policy and recipe-structure rules — the issue model is the documented contribution path.

---

## Sanitization principles

User-shared content (deployment logs, gotchas, error output) routinely contains identifiers that **must not** end up in the public repo. Both the skill (when drafting issue content) and any session reviewing user-supplied content (when accepting a PR sourced from an issue) must apply these rules.

### Always strip

| Class | Replace with |
|---|---|
| Domain names (apex / canonical / admin) | `${CANONICAL_HOST}` / `${APEX}` / `${ADMIN_DOMAIN}` |
| IP addresses (public + private + IPv6) | `${PUBLIC_IP}` / `${PRIVATE_IP}` |
| SSH key paths and contents | `${KEY_PATH}` / `<REDACTED-SSH-KEY>` |
| API keys and bearer tokens (regex: `re_[A-Za-z0-9_]+`, `SG\.[A-Za-z0-9._-]+`, `sk-[A-Za-z0-9]+`, `xox[bp]-[A-Za-z0-9-]+`, `ghp_[A-Za-z0-9]+`, AWS access keys `AKIA[0-9A-Z]{16}` + secret `[A-Za-z0-9/+=]{40}`, GCP service-account JSON, generic `Bearer [A-Za-z0-9._-]{20,}`) | `<REDACTED>` |
| AWS account IDs (12 consecutive digits in AWS context) | `${AWS_ACCOUNT}` |
| AWS profile names | `${AWS_PROFILE}` |
| Email addresses (LE email, SMTP from-address, user identity) | `${EMAIL}` |
| State-file contents from `~/.open-forge/deployments/<name>.yaml` | Reference the file by name only, never paste contents |
| Hostnames embedded in URLs that include the user's domain | `https://${CANONICAL_HOST}/path` |
| Anything from the user's clipboard / env vars they pasted into chat | `<REDACTED>` |

### Multi-step consent (no auto-post, ever)

The skill flow when posting feedback to GitHub:

1. **Opt-in prompt** — *"Want to share what you learned?"* User must explicitly opt in.
2. **Show the redacted draft in chat** — full text, before any submission attempt.
3. **Confirm post?** — explicit "yes" required.
4. **If user edits the draft**, re-show + re-confirm before submitting.
5. **Standing reminder text** in the prompt: *"GitHub issues are public and permanent. Once posted, this can't be unposted. Review every line; edit if anything looks identifiable."*
6. **Liability notice in the issue body**: *"Submitter grants a non-revocable license to use this content in the open-forge recipe; the project bears no liability for the submitter's choice to share."*

### When reviewing PRs sourced from issues

Issue-processing sessions must re-scan PR diffs against the same strip-list before merging. If any identifier slipped through, redact in the PR before merge — never merge content with live identifiers.

---

## Processing incoming issues

When an AI coding session is asked to process incoming issues (whether by a maintainer prompt, a scheduled job, or a webhook), apply this workflow:

### 1. Triage

For each open issue without an `applied` / `out-of-scope` / `needs-info` label:

- Identify the template type from the issue body's structured fields. If the issue doesn't follow a template, comment with a pointer to the templates and label `needs-info`.
- Validate that the issue is in scope per *Is this software in scope?*. Out-of-scope → comment + `out-of-scope` label + close.
- Otherwise, label `triaged` and proceed to validation.

### 2. Validate against upstream

Apply *Strict doc-verification policy* to every change:

- For `recipe-feedback`: re-fetch the recipe's cited upstream URLs; verify the user's proposed change is consistent with current upstream content. If upstream has drifted in a way that conflicts with the user's report, prefer upstream and explain the discrepancy in the PR.
- For `software-nomination`: confirm the software passes inclusion criteria; locate upstream's install-method index; do **not** start authoring a recipe until the index is reachable.
- For `method-proposal`: confirm the cited upstream URL documents the method; if it's community-maintained, it must be flagged per *Community-maintained methods — flagging requirements*.

If validation fails (upstream URL 404s, software is out of scope, methodology is unverifiable), comment on the issue explaining + label `needs-info` or `out-of-scope` as appropriate. Do not author a patch.

### 3. Author the patch

- Apply the change per *Recipe structure (must-have sections)*.
- Cite the upstream URL at the top of every section per *Strict doc-verification policy*.
- Flag community-maintained methods with the required ⚠️ blockquote.
- Re-scan against the *Sanitization principles* strip-list — if any identifier slipped through user-supplied content, redact before drafting.
- **If your patch touches `CLAUDE.md`, `plugins/open-forge/skills/open-forge/SKILL.md`, or any file under `plugins/open-forge/skills/open-forge/references/`, regenerate the multi-platform distribution bundles**: `./scripts/build-dist.sh all`. Include the regenerated `dist/` files in the same PR. The bundles concatenate canonical sources for non-Claude-Code platforms (Codex / Cursor / Aider / Continue / generic); they drift if not regenerated, which silently breaks those platforms. CI enforces this — see `.github/workflows/dist-bundles.yml`.
- Bump `plugin.json` `version` per *Versioning + publish flow*.
- If multiple feedback issues for the same recipe are pending, batch them into a single PR.

### 4. Open the PR

- **Branch naming**: `bot/issue-<N>-<short-slug>` (where `<N>` is the originating issue number).
- **Commit author**: `Qi Zhang <zhangqi444@gmail.com>` per *Author convention*.
- **PR body** must cite (a) the originating issue number(s), (b) every upstream URL re-verified, (c) the version bump rationale.
- After opening, label the issue `in-progress`. After merge, relabel `applied`.

### 5. State-machine via labels

| Label | Meaning |
|---|---|
| (none) | New issue, not yet triaged |
| `triaged` | Identified template type + scope-checked; ready to validate |
| `in-progress` | A PR is open against this issue |
| `applied` | PR merged; issue resolved |
| `needs-info` | Author needs to provide more before processing can continue |
| `out-of-scope` | Software / request doesn't meet inclusion criteria; closed |

Optionally also: `recipe:<name>`, `tier:1`, `tier:2`, `infra:<cloud>`, `runtime:<runtime>` for filtering.

### 6. Conflicts and ambiguity

- **Contradicting suggestions across issues**: prefer upstream-doc-verified content; cite the upstream URL in the PR explaining which suggestion was chosen and why.
- **Ambiguous suggestion**: if the issue is unclear about what should change, comment asking for clarification with a deadline (e.g. *"reply within 14 days or this issue will be auto-closed"*) and label `needs-info`.
- **Idempotency**: never re-process an issue already labeled `applied`. If the same recipe issue resurfaces under a new issue number, treat it as a fresh demand signal (counts toward Tier 2 → Tier 1 graduation per *Two-tier coverage model*).

---

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

The dominant path for first-run discipline is now **user-submitted feedback issues** processed per *Processing incoming issues* — the skill drafts a sanitized issue at the end of each deploy and the user opts in to share. Maintainer-driven deploys (where the maintainer is also the recipe author) still apply for new recipes. Either way, the same five-step capture applies.

## File layout

```
open-forge/
├── CLAUDE.md                              ← you are reading
├── README.md                              ← user-facing, lives on GitHub
├── LICENSE                                ← MIT
├── .claude-plugin/marketplace.json        ← marketplace manifest
├── .github/
│   ├── ISSUE_TEMPLATE/                    ← three issue channels (recipe-feedback, software-nomination, method-proposal)
│   └── workflows/dist-bundles.yml         ← CI: fail PRs whose dist/ bundles are stale vs canonical sources
├── docs/platforms/                        ← per-platform usage guides (Codex / Cursor / Aider / Continue / generic)
├── dist/                                  ← regenerated multi-platform distribution bundles (see scripts/build-dist.sh)
├── scripts/
│   └── build-dist.sh                      ← regenerates dist/ from canonical sources; run when CLAUDE.md / SKILL.md / modules change
└── plugins/open-forge/
    ├── .claude-plugin/plugin.json         ← plugin manifest (version!)
    └── skills/open-forge/
        ├── SKILL.md                       ← end-user-Claude entrypoint
        ├── references/
        │   ├── projects/<name>.md         ← software layer
        │   ├── runtimes/<name>.md         ← runtime layer (docker.md, podman.md, native.md, kubernetes.md)
        │   ├── infra/<name>.md            ← infra layer (aws/, azure/, hetzner/, digitalocean/, gcp/, oracle/, paas/, hostinger.md, raspberry-pi.md, macos-vm.md, byo-vps.md, localhost.md)
        │   └── modules/<name>.md          ← cross-cutting (preflight, dns, tls, smtp providers, inbound forwarders, tunnels, backups, monitoring, credentials, feedback)
        └── scripts/                       ← deployment-time operational scripts (per-recipe); empty by default
```

The skill-side `plugins/open-forge/skills/open-forge/scripts/` (deployment-time) stays empty unless something is reused 3+ times across deployments — inline commands in recipes are clearer for one-off use. Distinct from the top-level `scripts/` (build-time tooling for dist/ bundles).

## Versioning + publish flow

`plugin.json` `version` controls what the Claude Code marketplace fetches.

- **Bump on**: skill description change, new project/runtime/infra, major recipe rewrite, anything that changes user-visible behavior.
- **Don't bump on**: typo fixes, internal comment cleanups, lint-only changes.

Publish flow (typical path: AI session processing an issue per *Issue-driven contribution model*):

1. Commit the change with version bump if applicable. Author per *Author convention*.
2. Push to `github.com/zhangqi444/open-forge` — typically as a PR opened against `main` (branch name per *Processing incoming issues*).
3. After merge, end users run `/plugin marketplace update zhangqi444/open-forge` then re-install.

Maintainer manual edits follow the same flow but skip the issue-tracking labels.

## Author convention

Commits authored as `Qi Zhang <zhangqi444@gmail.com>` — set inline via env vars (`GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`), **don't write to git config**.

## Refactor (started 2026-04-24, completed 2026-04-26)

Initial state collapsed three axes into linear "Path A/B/C" inside `openclaw.md`, which hid valid combos and biased preflight toward AWS even for non-AWS deployments. Migrated to the 3-layer file layout above. Order:

1. ✅ CLAUDE.md model locked in (this section).
2. ✅ Preflight refactor — branch on infra choice; only require AWS CLI when infra ∈ AWS.
3. ✅ Skeleton infra adapters: `infra/aws/lightsail.md` (Bitnami + OpenClaw blueprints share this; the blueprint-vs-Ubuntu split is a project-recipe concern, not a separate adapter), `infra/aws/ec2.md`, `infra/azure/vm.md`, `infra/hetzner/cloud-cx.md`, `infra/digitalocean/droplet.md`, `infra/gcp/compute-engine.md`, `infra/oracle/free-tier-arm.md`, `infra/hostinger.md`, `infra/raspberry-pi.md`, `infra/macos-vm.md`, `infra/byo-vps.md`, `infra/localhost.md`, plus a PaaS family under `infra/paas/`: `fly.md`, `render.md`, `railway.md`, `northflank.md`, `exe-dev.md`.
4. ✅ Runtime modules: `runtimes/docker.md`, `runtimes/podman.md`, `runtimes/native.md`, `runtimes/kubernetes.md`. Docker + native extracted from openclaw.md Paths B and C; kubernetes added when openclaw upstream's Kustomize-based path was wired in; podman added in v0.8.0.
5. ✅ Slim down `projects/openclaw.md` — software-layer concerns only; reference runtimes + infra modules for everything else. v0.8.0: corrected the Kubernetes section to be Kustomize-first (matches upstream `scripts/k8s/deploy.sh`); added Podman, ClawDock, Ansible, Nix, and Bun (experimental) sections; combo table now enumerates every upstream-blessed install method documented under `docs.openclaw.ai/install/*`.
6. ✅ Add `modules/tunnels.md` for localhost public-reach (Cloudflare Tunnel / Tailscale / ngrok).
7. ✅ Update SKILL.md, README.md support tables and prompts. Bump plugin version (→ 0.8.0).

Path A/B/C terminology retired. Future work tracked in each adapter's *TODO — verify on subsequent deployments* section, not here. Cluster-provisioning adapters (EKS / GKE / AKS / DOKS) are intentionally not in scope — open-forge orchestrates an existing cluster; users own cluster create/delete in their cloud's k8s UI. Cloud-VM adapters and PaaS adapters added in v0.8.0 are documented from upstream docs only — none has been exercised end-to-end yet; first-run discipline (CLAUDE.md § *First-run discipline*) applies as those deployments happen.

## Behavioral guidelines (echoes of bota CLAUDE.md, kept here for autonomy)

- **Think before coding.** State assumptions; ask when uncertain; surface tradeoffs.
- **Simplicity first.** Minimum recipe content that works; no speculative abstractions.
- **Surgical changes.** When updating a recipe after a deploy, change only what the deploy taught us. Don't "improve" adjacent sections.
- **Goal-driven execution.** A recipe edit is "done" when the next deploy can use it without manual fixes.
- **Documentation updates** (the recipes themselves) are a deliverable of every deployment, not a follow-up.
