---
name: open-forge
description: Automate self-hosting of open-source apps on cloud infrastructure the user owns. Use when the user asks to "self-host", "deploy to my own cloud", "install X on AWS / Lightsail / EC2 / Azure / Hetzner / DigitalOcean / GCP / Oracle Cloud / Hostinger / Raspberry Pi / Kubernetes / Fly.io / Render / Railway / Northflank / exe.dev", "set up my own Ghost blog / Mastodon / WordPress / Nextcloud", wants to deploy the self-hosted personal AI agent **OpenClaw** (openclaw.ai — NOT the Captain Claw platformer game) or **Hermes-Agent** (Nous Research's self-improving AI agent at github.com/NousResearch/hermes-agent), wants to run **Ollama** (local-LLM inference server at ollama.com — pairs with every AI agent / chat UI as an OpenAI-compatible provider), wants to run **Open WebUI** (feature-rich self-hosted ChatGPT-like UI at github.com/open-webui/open-webui — pairs natively with Ollama and any OpenAI-compatible backend; adds RAG, web search, image gen, voice, multi-user), wants to run **Stable Diffusion WebUI** / **Automatic1111** / **A1111** (the most-popular open-source AI image generator at github.com/AUTOMATIC1111/stable-diffusion-webui — text-to-image, img2img, inpainting, ControlNet, LoRA; pairs with Open WebUI as an image-gen backend), wants to run **ComfyUI** (node-based AI image / video generation at github.com/comfyanonymous/ComfyUI — power-user alternative to A1111 with workflow graphs; same models, different UX; pairs with Open WebUI as image-gen backend), wants to deploy **Dify** (open-source LLMOps + AI app builder at github.com/langgenius/dify — visual workflow builder, RAG, multi-tenant; the "build a SaaS-grade AI app" platform, different category from chat UIs), wants to deploy **LibreChat** (multi-provider chat UI with deep enterprise plumbing at github.com/danny-avila/LibreChat — alternative to Open WebUI for teams; multi-user with social logins, per-user balance + transactions, agents + MCP, dedicated rag_api), wants to deploy **AnythingLLM** (RAG-focused workspace + agent platform at github.com/Mintplex-Labs/anything-llm — drop-in PDFs + URLs + GitHub repos, ask questions over them; built-in LanceDB; Desktop App + Docker + 8 cloud one-clicks), wants to install **Aider** (AI pair-programming CLI at github.com/Aider-AI/aider — runs in the terminal next to a git repo, edits files via diffs, auto-commits; pairs with any LLM provider including Ollama for local), wants to deploy **vLLM** (production-grade LLM inference server at github.com/vllm-project/vllm — high-throughput multi-tenant serving with PagedAttention + tensor parallelism + prefix caching; NVIDIA / AMD / Intel / CPU; Docker / Kubernetes / Helm / PaaS), wants to deploy **Langfuse** (open-source LLM engineering platform at github.com/langfuse/langfuse — observability, evals, prompt management, datasets, scoring; v3 six-service architecture with Postgres + ClickHouse + Redis + S3; Docker Compose, Kubernetes Helm chart, first-party Terraform modules for AWS / GCP / Azure, Railway one-click), or names any combination of an open-source app and a cloud provider. Walks the user through provisioning, DNS, TLS, outbound email (SMTP), and inbound email, in phases that are resumable across sessions via a state file at `~/.open-forge/deployments/<name>.yaml`. Supported today: Ghost on AWS Lightsail (Bitnami blueprint); OpenClaw via every upstream-blessed path documented at docs.openclaw.ai/install/* — AWS Lightsail blueprint, Docker Compose, Podman, Kubernetes (Kustomize), native installers (install.sh / install-cli.sh / install.ps1), ClawDock, Ansible, Nix, Bun, plus per-host adapters for AWS EC2 / Azure / Hetzner / DigitalOcean / GCP / Oracle Cloud / Hostinger / Raspberry Pi / macOS-VM (Lume) / BYO Linux server / localhost / Fly.io / Render / Railway / Northflank / exe.dev. More projects and infras added under `references/projects/` and `references/infra/`.
---

# open-forge

## Overview

Walk a user from "I have a cloud account and a domain" to "working app at `https://my.domain` with TLS and mail." Load the appropriate project recipe and infra adapter based on the user's stated intent; run phases sequentially; record state so the user can resume later.

## Operating principle

**Claude does the work; the user makes the choices.** open-forge replaces the traditional "read a README, copy-paste 30 lines of bash, debug for hours" experience with a guided chat where Claude executes everything via the user's local CLI tools (aws, ssh, jq, curl) and only stops to ask when input is genuinely required.

What this means in practice:

- **Run, don't print.** When a recipe contains a bash block, *Claude executes it*. Announce it in one sentence first ("Opening port 22 in the Lightsail firewall now."), then run. Don't paste the block into chat for the user to run.
- **Ask for choices and credentials only.** Things only the user can decide or provide: AWS profile name, domain choice, canonical www-vs-apex, SMTP API key, model provider preference. Everything else (which jq command to run, which sed pattern to apply, which IAM script URL to fetch) Claude figures out from the recipe.
- **One question at a time when possible.** Use the `AskUserQuestion` tool for structured choices (multiple-choice, single-select). Reserve free-text questions for things like API keys and domain names. Avoid wall-of-questions forms.
- **Auto-install with confirmation, not silently.** If `jq` or `aws` is missing, propose the install command, get one-line approval, then run it. Never `sudo apt-get install` without asking.
- **The recipe files in `references/projects/` and `references/infra/` are guidance for Claude, not pages for the user to read.** Keep that lens when extending or refactoring.

## What's supported

Check `references/projects/` and `references/infra/` for available recipes/adapters. As of this writing:

Supported **software**:

| Software | What it is |
|---|---|
| Ghost | Self-hosted blogging platform |
| OpenClaw | Self-hosted personal AI agent (openclaw.ai — NOT the Captain Claw platformer game) |
| Hermes-Agent | Self-improving personal AI agent from Nous Research (github.com/NousResearch/hermes-agent). Native (`scripts/install.sh`), Docker, Nix, manual-dev, Termux (Android), Homebrew. Includes `hermes claw migrate` for OpenClaw users. |
| Ollama | Local-LLM inference server (ollama.com). Foundation layer — pairs with OpenClaw / Hermes / Open WebUI / LibreChat / Aider / etc. as an OpenAI-compatible provider. Native (`install.sh` / `install.ps1` / `.dmg` / `.exe`), Docker (CPU + NVIDIA + AMD ROCm + Vulkan), Kubernetes (community Helm chart), Homebrew, Nix, Pacman. |
| Open WebUI | Feature-rich web UI for any OpenAI-compatible LLM backend (github.com/open-webui/open-webui). Multi-user, RAG, web search, image gen, voice, MCP. Pairs naturally with Ollama. Docker (`:main` / `:cuda` / `:ollama` / `:dev` tags), docker-compose (with bundled or external Ollama), pip (Python 3.11), Kubernetes (community Helm). |
| Stable Diffusion WebUI (A1111) | The most-popular open-source AI image generator (github.com/AUTOMATIC1111/stable-diffusion-webui). Pairs with Open WebUI as an image-gen backend. Native (`webui.sh` Linux/macOS, `webui-user.bat` Windows, `sd.webui.zip` one-click), GPU paths for NVIDIA CUDA / AMD ROCm Linux / AMD DirectML Windows fork / Apple Silicon MPS, plus community-maintained Docker images (AbdBarho recommended). |
| ComfyUI | Node-based AI image / video generation (github.com/comfyanonymous/ComfyUI). Power-user alternative to A1111; same models, workflow-graph UX. Pairs with Open WebUI as image-gen backend. Desktop App (Windows/macOS), Windows portable 7z (NVIDIA / AMD / Intel variants), `comfy-cli`, manual install, plus broad GPU support (NVIDIA CUDA, AMD ROCm Linux + Windows nightly, Intel Arc XPU, Apple Silicon MPS) and community Docker (AbdBarho `comfy` profile, yanwk/comfyui-boot). |
| Dify | Open-source LLMOps + AI app builder platform (github.com/langgenius/dify). Visual workflow builder, RAG with many vector-DB backends (Weaviate / Qdrant / Milvus / pgvector / Elasticsearch / OpenSearch / Couchbase / Chroma / +more), multi-tenant, plugin marketplace. Different category from chat UIs — Dify is the platform for *building* AI products. Docker Compose (canonical, ~12 services), Kubernetes via community Helm, source code, aaPanel one-click, plus cloud templates (Azure / GCP Terraform, AWS CDK for EKS/ECS, Alibaba Computing Nest). |
| LibreChat | Multi-provider chat UI with deep enterprise plumbing (github.com/danny-avila/LibreChat). Multi-user with social logins (GitHub / Google / Discord / OIDC / SAML / Apple / Facebook), per-user balance + transactions, agents + assistants + MCP, RAG via pgvector + dedicated rag_api, web search, TTS/STT. Alternative to Open WebUI for teams. Docker Compose dev (`docker-compose.yml`), Docker Compose prod (`deploy-compose.yml` + Nginx), npm / source, **first-party Helm chart** (`helm/librechat/` v2.0.2), plus one-click deploys for Railway / Zeabur / Sealos. |
| AnythingLLM | Open-source RAG-focused workspace + AI agent platform (github.com/Mintplex-Labs/anything-llm). Workspace-style "drop a folder of PDFs, ask questions over them" UX with built-in LanceDB vector store (or external Pinecone / Weaviate / Qdrant / Chroma / Milvus / Astra / pgvector), built-in agents, MCP support, multi-user, embeddable chat widget. Docker (canonical, `docker/HOW_TO_USE_DOCKER.md`), Desktop App (Mac / Windows / Linux installers), bare-metal source install (per `BARE_METAL.md`, "not supported by core team" — flagged), plus upstream-published one-click cloud deploys for AWS CloudFormation / GCP Cloud Run / DigitalOcean Terraform / Render / Railway / RepoCloud / Elestio / Northflank. |
| Aider | AI pair-programming CLI (github.com/Aider-AI/aider). Different category — runs in the developer's terminal alongside their git repo, edits files via diffs, auto-commits per change. Pairs with any LLM provider (Anthropic / OpenAI / DeepSeek / Gemini / OpenRouter / Ollama / vLLM / OpenAI-compatible). `aider-install` (recommended, isolated Python 3.12 env), uv-based one-liner script (Mac / Linux / Windows), uv direct, pipx, plain pip, plus Docker (`paulgauthier/aider` + `paulgauthier/aider-full`), GitHub Codespaces, and Replit. |
| vLLM | Production-grade LLM inference server (github.com/vllm-project/vllm). Different niche from Ollama (single-user / hobby) — vLLM is for high-throughput multi-tenant serving with PagedAttention, tensor parallelism, prefix caching. NVIDIA CUDA (canonical) + AMD ROCm + Intel XPU/Gaudi + CPU variants (x86 / ARM / Apple Silicon / s390x), Docker (`vllm/vllm-openai`), Kubernetes (raw manifests + first-party Helm chart + LeaderWorkerSet for distributed inference), plus upstream PaaS cookbooks (SkyPilot / RunPod / Modal / Cerebrium / dstack / Anyscale / Triton). |
| Langfuse | Open-source LLM engineering platform (github.com/langfuse/langfuse). LLM observability + evaluation + prompt management + datasets + scoring; cross-cutting layer that pairs with vLLM / Ollama (inference) and Open WebUI / LibreChat / AnythingLLM / Dify / Aider (apps). v3 architecture is six services (web, worker, Postgres, ClickHouse, Redis, MinIO/S3). Docker Compose (local + single-VM), Kubernetes Helm chart (`langfuse/langfuse-k8s`, recommended for prod), first-party Terraform modules for AWS (EKS + Aurora + ElastiCache + S3 + ALB), GCP (GKE + Cloud SQL + Memorystore + GCS + LB), Azure (AKS + PG-Flex + Redis + Storage + App Gateway), plus upstream-published Railway one-click. |

Supported **infras** (under `references/infra/`):

| Cloud / where | Adapter |
|---|---|
| AWS | `aws/lightsail.md` (Ghost Bitnami + OpenClaw blueprints), `aws/ec2.md` (general-purpose VM) |
| Azure | `azure/vm.md` (Bastion-hardened, no public IP) |
| Hetzner Cloud | `hetzner/cloud-cx.md` (CX-line VPS via `hcloud`) |
| DigitalOcean | `digitalocean/droplet.md` (Droplet via `doctl`) |
| GCP Compute Engine | `gcp/compute-engine.md` (VM via `gcloud`) |
| Oracle Cloud | `oracle/free-tier-arm.md` (Always-Free A1.Flex ARM + Tailscale) |
| Hostinger | `hostinger.md` (managed via hPanel — no CLI) |
| Raspberry Pi | `raspberry-pi.md` (Pi 4/5 64-bit, ARM64) |
| macOS VM (Apple Silicon) | `macos-vm.md` (Lume; for iMessage via BlueBubbles) |
| Any Linux VM (other providers, on-prem) | `byo-vps.md` (SSH-only, no cloud APIs) |
| Your own machine | `localhost.md` (Claude runs commands directly) |
| Fly.io | `paas/fly.md` (`fly.toml` + persistent volume; public or private mode) |
| Render | `paas/render.md` (`render.yaml` Blueprint, one-click) |
| Railway | `paas/railway.md` (one-click template) |
| Northflank | `paas/northflank.md` (one-click stack) |
| exe.dev | `paas/exe-dev.md` (Shelley agent or manual nginx) |

Supported **runtimes** (under `references/runtimes/`):

| Runtime | Notes |
|---|---|
| Docker | `docker.md` — install Docker on host + lifecycle via docker-compose. Reusable across every infra. |
| Podman | `podman.md` — rootless Docker-compatible alternative; Quadlet (systemd-user) supported. Reusable across every Linux/macOS infra. |
| Native | `native.md` — OS prereqs, systemd / launchd / Scheduled-Tasks lifecycle, reverse-proxy guidance. Covers `install.sh` (macOS / Linux / WSL2), `install-cli.sh` (local-prefix, no root), and `install.ps1` (native Windows). |
| Kubernetes | `kubernetes.md` — kubectl + Kustomize (preferred, what openclaw upstream uses) and Helm orchestration. open-forge does not provision clusters — point `kubectl` at one and we'll deploy into it. |
| Vendor blueprints | Bundled into infra adapters (e.g. Lightsail Ghost-Bitnami, Lightsail OpenClaw) — runtime choice is the vendor's |

## Selection — ask three questions

Before provisioning, establish three things by asking (or inferring from the user's prompt):

1. **What** to host? → loads `references/projects/<software>.md`
2. **Where** to host? → loads `references/infra/<cloud>/<service>.md` or `references/infra/{byo-vps,localhost}.md`
3. **How** to host? → loads the matching `references/runtimes/<runtime>.md` (skipped if the infra bundles the runtime, e.g. vendor blueprints)

The **how** question is *dynamically generated* from (software, where) — each project lists its "Compatible combos" table in the project recipe, and the options shown are filtered by the user's where answer. If the user's initial prompt already names a clear infra ("deploy to Lightsail" → AWS), announce the inferred choice and continue — don't re-ask. Use `AskUserQuestion` only when genuinely ambiguous.

Then **immediately load `references/modules/preflight.md`** and run its steps. Preflight is combo-aware — it only installs / validates what the chosen tuple actually needs (AWS CLI only when infra ∈ AWS, Docker only when runtime = docker, nothing extra on localhost).

## Tier 1 vs Tier 2 routing

open-forge ships a finite catalogue of verified recipes (Tier 1) plus a documented fallback for the long tail (Tier 2). When the user names a piece of software, decide which tier you're in **before** loading anything.

### Tier 1 — verified recipe exists

If `references/projects/<name>.md` matches the user's software, you're in Tier 1. Load it, follow it, and stay in the standard workflow below.

### Tier 2 — no recipe; derive from upstream live

If no recipe matches, **don't refuse — fall back to Tier 2**:

1. **Announce in one sentence**: *"This software isn't in our verified recipe set — I'll fetch upstream docs live and reuse the runtime / infra modules. Treat my output as best-effort, not authoritative."*
2. **Fetch upstream the same way Tier 1 does**:
   - `WebFetch` the upstream README first. If 403/404, fall back to `raw.githubusercontent.com/<org>/<repo>/<branch>/README.md`, or `git clone` the docs repo locally if the docs site is Cloudflare-protected.
   - Locate the upstream install-method index (docs site, repo `docs/install/` tree, wiki).
   - Enumerate every method documented under that index. **Do not invent methods upstream doesn't ship** — if fetches fail, stop and tell the user, don't speculate.
   - Read canonical install artifacts in the repo (`Dockerfile`, `docker-compose.yml`, `helm/`, `flake.nix`, primary config example).
3. **Reuse the existing modules**: drive the Docker install via `runtimes/docker.md`, Kubernetes via `runtimes/kubernetes.md`, VM provisioning via `infra/<cloud>/*.md`, DNS / TLS / SMTP via `references/modules/`. The Tier 2 work is only the software-specific bits on top.
4. **Cite every upstream URL** in chat the same way Tier 1 sections do (`> Source: <url>`).
5. **Offer to capture the result** as a new Tier 1 recipe once the deploy succeeds — that's how the catalogue grows. Captured recipes must go through first-run discipline before promotion.

**Quality boundary:** Tier 2 output is best-effort, not authoritative. It will hallucinate at the edges of upstream docs we couldn't fetch and skips the real-deploy refinement Tier 1 recipes get. Always tell the user which tier you're in; never silently mix.

### Out-of-scope software

Some user requests are not deployable services at all (libraries like Unsloth or `requests`, desktop apps like Slack, SaaS like Notion). When you detect this, say so clearly and offer the closest in-scope alternative if there is one. See CLAUDE.md § *Is this software in scope?* for criteria.

## Phased workflow

Each phase is verifiable and resumable. Do NOT batch phases — complete, verify, and update state before moving on.

```
1. preflight     → check prerequisites (CLI tools, profiles, domain ownership); collect inputs
2. provision     → create instance, allocate + attach static IP, retrieve SSH key
3. dns           → print exact DNS records for user to add at registrar; poll until resolved
4. tls           → obtain Let's Encrypt cert, fix reverse proxy, switch app URL to https
5. smtp          → configure outbound email provider; verify a test send
6. inbound       → (optional) set up forwarding or mailbox
7. hardening     → rotate default admin creds, rotate any secrets pasted into chat
```

Infra adapter defines *how* to do each phase (what CLI commands to run). Project recipe defines *what's specific* about that app (config file paths, gotchas, mail block shape). Cross-cutting steps — DNS guidance, Let's Encrypt, SMTP providers, inbound forwarders — live in `references/modules/` and are loaded as needed.

## State file

Every deployment has a YAML state file at:

```
~/.open-forge/deployments/<name>.yaml
```

Shape:

```yaml
name: my-blog
project: ghost
infra: lightsail
inputs:
  aws_profile: qi-experiment
  aws_region: us-east-1
  domain: ariazhang.org
  canonical: www  # or "apex"
  letsencrypt_email: user@example.com
outputs:
  instance_name: my-blog
  static_ip_name: my-blog-ip
  public_ip: 54.156.69.42
  ssh_key_path: ~/.ssh/lightsail-default.pem
  admin_url: https://www.ariazhang.org/ghost
phases:
  preflight:   { status: done,  at: "2026-04-22T19:00Z" }
  provision:   { status: done,  at: "2026-04-22T19:10Z" }
  dns:         { status: done,  at: "2026-04-22T19:25Z" }
  tls:         { status: done,  at: "2026-04-22T19:30Z" }
  smtp:        { status: done,  at: "2026-04-22T20:05Z" }
  inbound:     { status: skipped }
  hardening:   { status: pending }
```

At the start of each session: if a state file exists for the named deployment, read it and resume from the first non-done phase. If the user says "start over", confirm destructively before unlinking.

## Execution mode

Default: **autonomous** — run AWS CLI, SSH, and file edits directly. Announce each external command in one sentence before running. Never fabricate outputs.

Flag: **`--dry-run`** — print what would be done, do not execute. Useful for review.

Commands that cross trust boundaries (paste secrets into config files, send real emails, spend money) should be announced and, when ambiguous, confirmed.

## Inputs

Inputs split across three layers:

- **Cross-cutting (all deployments)** — handled by `references/modules/preflight.md`: AWS profile, region, deployment name, tool install confirmations.
- **Infra-specific** — handled by the loaded infra adapter (e.g. `references/infra/lightsail.md`): bundle/blueprint choice, SSH key path defaults.
- **Project-specific** — handled by the loaded project recipe (e.g. `references/projects/ghost.md`): domain, canonical preference, Let's Encrypt email, SMTP provider + API key, model provider, etc.

Each recipe and adapter has its own **"Inputs to collect"** section listing exactly what it needs and at which phase. Collect just-in-time per phase, not all upfront. Use `AskUserQuestion` for structured choices.

## Verification after each phase

| Phase | Verify with |
|---|---|
| provision | `aws lightsail get-instance ... --query 'instance.state'` is `running`; SSH to `<user>@<ip>` succeeds |
| dns | `dig +short <domain> @1.1.1.1` returns the static IP for apex AND the canonical host |
| tls | `curl -sI https://<domain>/` returns 2xx/3xx with a valid cert; browser loads without warnings |
| smtp | Send a test email from the app's admin UI; confirm arrival in the recipient inbox and in the provider's log |
| inbound | Send a test email to the configured alias; confirm it lands in the destination inbox |

Never mark a phase `done` without verification.

## Post-deploy feedback (closes the catalogue evolution loop)

After `hardening` (or after the user explicitly says "we're done", or after they abort mid-phase and want to share what they learned), offer to file a GitHub issue with the deployment notes. Per CLAUDE.md § *Issue-driven contribution model*, this is how the catalogue evolves — the bot or a future Claude session reads these issues and patches the recipes.

Three flows the user can trigger from this prompt:

1. **Recipe feedback** (default at end of deploy) — submit gotchas, suggested edits, or "the recipe was outdated". Claude self-summarizes from the session; the user reviews + opts in.
2. **Software nomination** — when the user asked to deploy something not in the catalogue and Tier 2 worked, offer to nominate it for Tier 1.
3. **Method proposal** — when the user discovered an upstream-supported install method the recipe doesn't cover.

### The flow (multi-step consent — never auto-post)

Load `references/modules/feedback.md` for the full sanitization rules + draft templates + submission paths. Summary:

1. **Opt-in prompt**:
   - Recipe feedback: *"Want to share what you learned with the open-forge project? I can draft a sanitized GitHub issue with the gotchas + suggested edits — you review, then post."*
   - Software nomination (Tier 2 deploy): *"This software isn't in the Tier 1 catalogue yet. Want to nominate it? I'll draft an issue with the rationale + upstream URLs."*
   - User must explicitly opt in (no auto-post).
2. **Self-summarize the session**:
   - Which recipe + combo was used, plugin version.
   - Which phases ran, which retried, which failed.
   - Where the user got prompted unexpectedly (gaps in the recipe).
   - Any gotchas Claude observed (commands that failed, error messages, deviations from the documented path).
3. **Draft the issue** in the format from `references/modules/feedback.md`:
   - Specific recipe-edit suggestions (preferred: as a diff), not free-prose.
   - All identifiers redacted per CLAUDE.md § *Sanitization principles*.
4. **Show the redacted draft in chat — full text — before any submission attempt.**
5. **Standing reminder**: *"GitHub issues are public and permanent. Once posted, this can't be unposted. Review every line; if anything looks identifiable to you, edit before posting. By submitting, you grant a non-revocable license to use this content in the recipe; the project bears no liability for your decision to share."*
6. **Confirm post?** — explicit "yes" required. If user edits the draft, re-show + re-confirm.
7. **Submit via the first available path**:
   - `gh issue create --title "..." --body "..." --label recipe-feedback,recipe:<name>` if the user has `gh` authenticated.
   - GitHub MCP `mcp__github__issue_write` if available.
   - Fallback: print a prefilled URL (`https://github.com/zhangqi444/open-forge/issues/new?template=recipe-feedback.yml&title=...&body=...`) and ask the user to open + submit in browser.

### Sanitization is mandatory

Per CLAUDE.md § *Sanitization principles* — strip every domain, IP, SSH key path, API key, AWS account ID, email address, state-file content, and anything from the user's clipboard / env vars before showing the draft. Use the patterns + replacements documented in `references/modules/feedback.md`.

If you find something in the draft that you can't confidently classify as safe, **redact it** rather than ship it. The user's review pass is a safety net, not the only line of defense.

### When to skip

- User says "no thanks" or doesn't reply → drop it, don't pester.
- Deploy aborted very early (before any state was created) → no useful feedback to capture; skip.
- Tier 2 deploy that obviously wasn't in scope (e.g. user tried to "self-host" a library) → don't nominate; politely explain it's out of scope per CLAUDE.md § *Is this software in scope?*.

## Common pitfalls across infras/projects

- **Stale DNS**: browsers cache 301 responses with long max-age. After any HTTP↔HTTPS or apex↔www redirect change, suggest hard reload or incognito.
- **Host key mismatch on new static IP**: the first SSH to a freshly-allocated IP needs `-o StrictHostKeyChecking=accept-new`; don't blindly blow away `~/.ssh/known_hosts` entries.
- **Non-interactive cert tools**: some have quirky option-file or flag requirements. See the project recipe — do not assume `--unattended` works.
- **Reverse-proxy misconfig after switching to https URL**: apps that enforce HTTPS redirects from the `url` config need `X-Forwarded-Proto` and `Host` preserved. See `references/modules/tls-letsencrypt.md`.

## Adding a new project or infra

A new project: add `references/projects/<name>.md` covering required services, config file paths, mail config shape, and any install/upgrade quirks. Follow the structure of the existing ghost.md.

A new infra: add `references/infra/<name>.md` covering provisioning (create instance, static IP, SSH key), firewall defaults, user/paths conventions. Follow lightsail.md.

Cross-cutting modules (new SMTP provider, new forwarder): add under `references/modules/`. Keep them project- and infra-agnostic.
