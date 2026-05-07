---
name: open-forge
description: "Self-host any open-source app on the user's own infrastructure (cloud VM, VPS, Raspberry Pi, localhost, k8s, PaaS). Walks the user through provisioning, DNS, TLS, SMTP, and hardening in phased + resumable workflows. 1913+ verified recipes plus live-derived fallback for the long tail."
metadata:
  {
    "openclaw":
      {
        "emoji": "🛠️",
        "requires": { "bins": ["bash", "curl", "ssh"] },
        "agent_mode": true,
        "credentials_paste_disabled": true,
        "source": "https://github.com/zhangqi444/open-forge",
        "docs": "https://deepwiki.com/zhangqi444/open-forge"
      }
  }
---

# open-forge — self-host any open-source app

---
name: open-forge
description: Automate self-hosting of open-source apps on cloud infrastructure the user owns. Use when the user asks to "self-host", "deploy to my own cloud", "install X on AWS / Lightsail / EC2 / Azure / Hetzner / DigitalOcean / GCP / Oracle Cloud / Hostinger / Raspberry Pi / Kubernetes / Fly.io / Render / Railway / Northflank / exe.dev", "set up my own Ghost blog / Mastodon / WordPress / Nextcloud", wants to deploy the self-hosted personal AI agent **OpenClaw** (openclaw.ai — NOT the Captain Claw platformer game) or **Hermes-Agent** (Nous Research's self-improving AI agent at github.com/NousResearch/hermes-agent), wants to run **Ollama** (local-LLM inference server at ollama.com — pairs with every AI agent / chat UI as an OpenAI-compatible provider), wants to run **Open WebUI** (feature-rich self-hosted ChatGPT-like UI at github.com/open-webui/open-webui — pairs natively with Ollama and any OpenAI-compatible backend; adds RAG, web search, image gen, voice, multi-user), wants to run **Stable Diffusion WebUI** / **Automatic1111** / **A1111** (the most-popular open-source AI image generator at github.com/AUTOMATIC1111/stable-diffusion-webui — text-to-image, img2img, inpainting, ControlNet, LoRA; pairs with Open WebUI as an image-gen backend), wants to run **ComfyUI** (node-based AI image / video generation at github.com/comfyanonymous/ComfyUI — power-user alternative to A1111 with workflow graphs; same models, different UX; pairs with Open WebUI as image-gen backend), wants to deploy **Dify** (open-source LLMOps + AI app builder at github.com/langgenius/dify — visual workflow builder, RAG, multi-tenant; the "build a SaaS-grade AI app" platform, different category from chat UIs), wants to deploy **LibreChat** (multi-provider chat UI with deep enterprise plumbing at github.com/danny-avila/LibreChat — alternative to Open WebUI for teams; multi-user with social logins, per-user balance + transactions, agents + MCP, dedicated rag_api), wants to deploy **AnythingLLM** (RAG-focused workspace + agent platform at github.com/Mintplex-Labs/anything-llm — drop-in PDFs + URLs + GitHub repos, ask questions over them; built-in LanceDB; Desktop App + Docker + 8 cloud one-clicks), wants to install **Aider** (AI pair-programming CLI at github.com/Aider-AI/aider — runs in the terminal next to a git repo, edits files via diffs, auto-commits; pairs with any LLM provider including Ollama for local), wants to deploy **vLLM** (production-grade LLM inference server at github.com/vllm-project/vllm — high-throughput multi-tenant serving with PagedAttention + tensor parallelism + prefix caching; NVIDIA / AMD / Intel / CPU; Docker / Kubernetes / Helm / PaaS), wants to deploy **Langfuse** (open-source LLM engineering platform at github.com/langfuse/langfuse — observability, evals, prompt management, datasets, scoring; v3 six-service architecture with Postgres + ClickHouse + Redis + S3; Docker Compose, Kubernetes Helm chart, first-party Terraform modules for AWS / GCP / Azure, Railway one-click), or names any combination of an open-source app and a cloud provider. Walks the user through provisioning, DNS, TLS, outbound email (SMTP), and inbound email, in phases that are resumable across sessions via a state file at `~/.open-forge/deployments/<name>.yaml`. Supported today: Ghost on AWS Lightsail (Bitnami blueprint); OpenClaw via every upstream-blessed path documented at docs.openclaw.ai/install/* — AWS Lightsail blueprint, Docker Compose, Podman, Kubernetes (Kustomize), native installers (install.sh / install-cli.sh / install.ps1), ClawDock, Ansible, Nix, Bun, plus per-host adapters for AWS EC2 / Azure / Hetzner / DigitalOcean / GCP / Oracle Cloud / Hostinger / Raspberry Pi / macOS-VM (Lume) / BYO Linux server / localhost / Fly.io / Render / Railway / Northflank / exe.dev. More projects and infras added under `references/projects/` and `references/infra/`.
---

# open-forge

## Overview

Walk a user from "I have a cloud account and a domain" to "working app at `https://my.domain` with TLS and mail." Load the appropriate project recipe and infra adapter based on the user's stated intent; run phases sequentially; record state so the user can resume later.

> **Platform note:** this skill is designed for Claude Code but the content is platform-agnostic. Tool names like `AskUserQuestion`, `WebFetch`, and `mcp__github__*` are Claude Code-specific — read them as *capabilities* (structured-choice prompt, URL fetch, GitHub API) and use whichever equivalent your platform exposes. See [`docs/platforms/`](../../../../docs/platforms/) in the repo for per-platform integration guides (Codex / Cursor / Aider / Continue / generic).

## Operating principle

**Claude does the work; the user makes the choices.** open-forge replaces the traditional "read a README, copy-paste 30 lines of bash, debug for hours" experience with a guided chat where Claude executes everything via the user's local CLI tools (aws, ssh, jq, curl) and only stops to ask when input is genuinely required.

What this means in practice:

- **Run, don't print.** When a recipe contains a bash block, *Claude executes it*. Announce it in one sentence first ("Opening port 22 in the Lightsail firewall now."), then run. Don't paste the block into chat for the user to run.
- **Ask for choices and credentials only.** Things only the user can decide or provide: AWS profile name, domain choice, canonical www-vs-apex, SMTP API key, model provider preference. Everything else (which jq command to run, which sed pattern to apply, which IAM script URL to fetch) Claude figures out from the recipe.
- **One question at a time when possible.** Use a structured-choice prompt for multiple-choice / single-select (Claude Code: `AskUserQuestion`; on other platforms, ask in prose with options listed). Reserve free-text questions for things like API keys and domain names. Avoid wall-of-questions forms.
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

The **how** question is *dynamically generated* from (software, where) — each project lists its "Compatible combos" table in the project recipe, and the options shown are filtered by the user's where answer. If the user's initial prompt already names a clear infra ("deploy to Lightsail" → AWS), announce the inferred choice and continue — don't re-ask. Ask a structured-choice question only when genuinely ambiguous.

Then **immediately load `references/modules/preflight.md`** and run its steps. Preflight is combo-aware — it only installs / validates what the chosen tuple actually needs (AWS CLI only when infra ∈ AWS, Docker only when runtime = docker, nothing extra on localhost).

### Goal-shaped requests → curated bundles

If the user describes a *goal* rather than a single piece of software (e.g. *"set up an AI homelab"*, *"I want a privacy stack for my home network"*), check [`references/bundles/`](references/bundles/) for a matching curated bundle before falling through to single-software routing. Bundles are recipe-of-recipes that pair commonly-co-deployed apps with cross-software wiring already worked out.

| Bundle | Goal | Constituent recipes |
|---|---|---|
| `bundles/ai-homelab.md` | Private LLM + chat UI + RAG workspace + pair-programming | Ollama · Open WebUI · AnythingLLM · Aider |
| `bundles/privacy-stack.md` | Network-wide ad blocking + password vault + mesh VPN | Pi-hole · Vaultwarden · Headscale · wg-easy |

Single-software requests still go through the standard 3-question selection. Bundles are an *additional* entry point for goal-shaped intents.

## Tier 1 vs Tier 2 routing

open-forge ships a finite catalogue of verified recipes (Tier 1) plus a documented fallback for the long tail (Tier 2). When the user names a piece of software, decide which tier you're in **before** loading anything.

### Tier 1 — verified recipe exists

If `references/projects/<name>.md` matches the user's software, you're in Tier 1. Load it, follow it, and stay in the standard workflow below.

### Tier 2 — no recipe; derive from upstream live

If no recipe matches, **don't refuse — fall back to Tier 2**:

1. **Announce in one sentence**: *"This software isn't in our verified recipe set — I'll fetch upstream docs live and reuse the runtime / infra modules. Treat my output as best-effort, not authoritative."*
2. **Fetch upstream the same way Tier 1 does**:
   - Fetch the upstream README first via the platform's URL-fetch capability (Claude Code: `WebFetch`; Cursor: `@Web`; Aider/generic: `curl` via shell). If 403/404, fall back to `raw.githubusercontent.com/<org>/<repo>/<branch>/README.md`, or `git clone` the docs repo locally if the docs site is Cloudflare-protected.
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

Each recipe and adapter has its own **"Inputs to collect"** section listing exactly what it needs and at which phase. Collect just-in-time per phase, not all upfront. Use a structured-choice prompt where the platform supports one (Claude Code: `AskUserQuestion`; otherwise prose with options listed).

## Asking for credentials

Whenever the skill needs sensitive input — API keys, DB passwords, OAuth client secrets, cloud creds, SSH key paths — load the *Credentials handling* section below and offer the **five patterns** (priority order):

| # | Pattern | What user gives |
|---|---|---|
| 1 | Local file path | path to file containing the secret (skill `cat`s it) |
| 2 | Env var name | name of an env var the user pre-exported (skill reads `$<NAME>`) |
| 3 | Cloud-CLI session | "I've already run `aws sso login` for profile `<name>`" |
| 4 | Secrets-manager ref | `op://Personal/Resend/api-key`, `vault://...`, `bw://...` (skill calls matching CLI) |
| 5 | Direct paste | **last resort** — skill surfaces risk, accepts after explicit yes, reminds to rotate at hardening |

**Never silently accept a paste.** When the skill detects sensitive input is needed, it should:

1. **Offer the five patterns** with the credential class noted (e.g. *"I need a Resend API key — pick how to provide it: file path, env var, secrets-manager ref, or paste (last resort)"*).
2. **Validate** before using:
   - File path → `test -r <path>` + check mode is `≤ 600` (offer `chmod 600` if wider).
   - Env var → `test -n "$<NAME>"` (refuse if empty; if user `export`ed after Claude Code started, ask them to restart).
   - Cloud-CLI → smoke-command (e.g. `aws sts get-caller-identity --profile <name>`).
   - Secrets-manager → smoke-command (`op read --no-newline <ref>`, `vault kv get`, etc.).
   - Paste → require explicit risk acknowledgement first.
3. **Detect accidental pastes**: if the user was prompted for a path but pasted a string matching `re_*` / `sk-*` / `AKIA[0-9A-Z]{16}` / etc., stop and ask: *"That looks like the key itself, not a path. Did you mean to paste directly? (see risks)"*.
4. **Never accept SSH key contents.** Always ask for the path; skill uses `ssh -i <path>`.
5. **End-of-deploy rotation reminder** if the user pasted any secret during the deploy: surface during the `hardening` phase with a list of (credential, dashboard URL) pairs. Pasted secrets remain in session history; rotating now bounds the exposure.

### Agent-mode rules (OpenClaw / Hermes / any messaging-channel agent)

When this skill runs inside a long-running personal AI agent (OpenClaw, Hermes-Agent, or any agent that talks to the user via WhatsApp / Telegram / Slack / iMessage / email / etc.), apply these stricter rules **on top of** the base five-pattern flow above:

- **Pattern 5 (direct paste) is DISABLED.** Pasting credentials into messaging channels is meaningfully riskier than into coding-tool chat — chat history syncs to the user's phone, may be backed up to cloud (iCloud / Google Drive), and often persists indefinitely. Refuse a paste with: *"I can't accept credentials pasted into a messaging channel. Use a file path, env var, cloud-CLI session, or secrets-manager reference instead. See the *Credentials handling* section below for options."* If the user insists, refuse again — don't compromise.
- **Reject deploy conversations from group channels.** Group chats leak everything to all members (credentials, IPs, admin URLs). When invoked from a group context, respond: *"Self-host deploys involve sensitive info. Switch to a 1:1 DM and ask again."* Then stop.
- **Use async polling for time-elapsed waits**, not blocking prompts. `dns` propagation, `tls` cert issuance, `provision` instance-boot — all become *"I'll poll and ping you when ready"* rather than *"press enter when DNS propagates."* Agents have a daemon; use it.
- **Channel-aware response routing.** Long-form content (DNS records to add at registrar, full recipe explanations, admin-bootstrap URLs) should go via secure / structured channels (email, signed note, secure-share link) when the agent supports them, not the chat. Quick decisions (yes/no, pick from list) stay in chat. Final hand-off (admin URL, rotation reminders) → secure 1:1 only.

See [`docs/platforms/openclaw.md`](../../../../docs/platforms/openclaw.md) and [`docs/platforms/hermes.md`](../../../../docs/platforms/hermes.md) for the full agent-mode integration guides.

See the *Credentials handling* section below for the full pattern details, per-credential-class recommendations, and failure-mode handling.

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

Load the *Post-deploy feedback flow* section below for the full sanitization rules + draft templates + submission paths. Summary:

1. **Opt-in prompt**:
   - Recipe feedback: *"Want to share what you learned with the open-forge project? I can draft a sanitized GitHub issue with the gotchas + suggested edits — you review, then post."*
   - Software nomination (Tier 2 deploy): *"This software isn't in the Tier 1 catalogue yet. Want to nominate it? I'll draft an issue with the rationale + upstream URLs."*
   - User must explicitly opt in (no auto-post).
2. **Self-summarize the session**:
   - Which recipe + combo was used, plugin version.
   - Which phases ran, which retried, which failed.
   - Where the user got prompted unexpectedly (gaps in the recipe).
   - Any gotchas Claude observed (commands that failed, error messages, deviations from the documented path).
3. **Draft the issue** in the format from the *Post-deploy feedback flow* section below:
   - Specific recipe-edit suggestions (preferred: as a diff), not free-prose.
   - All identifiers redacted per CLAUDE.md § *Sanitization principles*.
4. **Show the redacted draft in chat — full text — before any submission attempt.**
5. **Standing reminder**: *"GitHub issues are public and permanent. Once posted, this can't be unposted. Review every line; if anything looks identifiable to you, edit before posting. By submitting, you grant a non-revocable license to use this content in the recipe; the project bears no liability for your decision to share."*
6. **Confirm post?** — explicit "yes" required. If user edits the draft, re-show + re-confirm.
7. **Submit via the first available path**:
   - `gh issue create --title "..." --body "..." --label recipe-feedback,recipe:<name>` if the user has `gh` authenticated.
   - Platform-native GitHub integration if available (Claude Code: `mcp__github__issue_write`; Cursor / generic: GitHub MCP server if installed).
   - Fallback: print a prefilled URL (`https://github.com/zhangqi444/open-forge/issues/new?template=recipe-feedback.yml&title=...&body=...`) and ask the user to open + submit in browser.

### Sanitization is mandatory

Per CLAUDE.md § *Sanitization principles* — strip every domain, IP, SSH key path, API key, AWS account ID, email address, state-file content, and anything from the user's clipboard / env vars before showing the draft. Use the patterns + replacements documented in the *Post-deploy feedback flow* section below.

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


---

# Credentials handling (agent-mode rules apply)

---
name: credentials
description: How the skill asks for credentials safely — five patterns prioritized from "secret never enters chat" to "last-resort paste with explicit risk acknowledgement." Loaded by SKILL.md § Asking for credentials. Applies to API keys, SSH keys, DB passwords, OAuth client secrets, cloud account creds, anything sensitive.
---

# Credentials module — five patterns, prioritized

Pasting raw credentials into Claude Code is risky:

- The secret enters the session history (visible to other tools loaded in the same session, may persist in logs).
- May be relayed via MCP servers depending on the user's setup.
- Shows up in transcripts the user might later share for support.
- Some terminals / IDEs persist input across restarts.

The skill defaults to safer patterns. Direct chat paste is **last resort** and only after explicit risk acknowledgement.

**Hard rule:** every time the skill needs a sensitive input, it offers the user the five patterns below — letting them pick — and surfaces the risk if they pick paste. Don't silently accept a paste; don't pretend Claude Code is a vault.

---

## The five patterns (priority order)

### 1. Local file path (recommended for personal use)

User stores the secret in a file under their home directory; tells the skill the path; skill reads via `cat`.

**When to suggest first:** for one-off API keys (Resend, SendGrid, Mailgun, OpenAI, Anthropic, etc.) that the user already has in a `.env`, `.secrets`, or password-manager export.

**Skill prompt:**

> *"Path to a file containing the key (e.g. `~/.secrets/resend`)? I'll read it via `cat`."*

**Skill execution:**

```bash
RESEND_KEY=$(cat ~/.secrets/resend)   # or however the user names it
# Use $RESEND_KEY in subsequent commands; never echo it back to the user
```

**Properties:**

- Secret never enters chat.
- File survives across Claude Code sessions; user can use the same path next time.
- User is responsible for the file's permissions (`chmod 600` recommended; mention if the file's mode is `644` or wider).

---

### 2. Environment variable name (recommended for shell users)

User exports the secret as an env var **before** starting Claude Code (or in their shell `rc`); tells the skill the var name.

**When to suggest first:** when the user already has secrets in a `.envrc` / `.bashrc` / `~/.config/fish/config.fish` they `source` regularly.

**Skill prompt:**

> *"Name of an env var holding the key (e.g. `RESEND_API_KEY`)? I'll read `$RESEND_API_KEY` from my shell."*

**Skill execution:**

```bash
# Verify the var exists in Claude's shell
test -n "$RESEND_API_KEY" || { echo "RESEND_API_KEY not set; export it before continuing"; exit 1; }
# Use it
curl ... -H "Authorization: Bearer $RESEND_API_KEY" ...
```

**Properties:**

- Secret never enters chat.
- Session-scoped if exported in the current shell only; persistent if in `rc` files.
- The env var **must** exist in the shell Claude Code launched from. If the user `export`s after Claude Code starts, Claude won't see it (you'll need them to restart Claude Code or pass it inline).

---

### 3. Cloud-CLI session auth (default for AWS / GCP / Azure / GitHub)

User authenticates the cloud CLI ahead of time (e.g. `aws sso login`, `gcloud auth application-default login`, `az login`, `gh auth login`); skill uses the resulting profile / session.

**When to suggest first:** any time the credential is for a cloud account that ships its own CLI auth flow. Don't ask for raw cloud access keys if SSO / browser auth is available.

| Provider | Pre-skill setup | What skill uses |
|---|---|---|
| AWS | `aws sso login --profile <name>` (or `aws configure` for static keys) | `aws --profile <name> ...` |
| GCP | `gcloud auth application-default login` + `gcloud config set project <id>` | `gcloud` / `gsutil` / Terraform default-application-credentials |
| Azure | `az login` | `az ...` (uses cached session) |
| GitHub | `gh auth login` | `gh ...` (uses stored token, scoped) |
| DigitalOcean | `doctl auth init` | `doctl ...` |
| Hetzner | `hcloud context create` | `hcloud --context <name> ...` |
| Cloudflare | `wrangler login` | `wrangler ...` |

**Skill prompt:**

> *"Have you run `aws sso login` for the profile you want to use? If yes, what's the profile name?"*

**Properties:**

- No secret material in chat or in any file the skill reads.
- Auth is browser-mediated, MFA-friendly.
- Sessions expire (good — bounded blast radius); skill handles re-auth gracefully if the session lapses mid-deploy.

---

### 4. Secrets-manager reference (advanced)

User stores secrets in 1Password / Bitwarden / Vault / AWS Secrets Manager / GCP Secret Manager; gives the skill a CLI-resolvable reference; skill calls the secret-manager CLI to fetch only when needed.

**When to suggest first:** when the user mentions they "have it in 1Password" or similar; or for users with proper secret-management practices.

| Secret manager | Reference shape | Skill execution |
|---|---|---|
| 1Password | `op://Personal/Resend/api-key` | `op read 'op://Personal/Resend/api-key'` |
| Bitwarden | item name + field | `bw get password '<item-name>'` |
| HashiCorp Vault | `secret/data/<path>#<field>` | `vault kv get -field=<field> secret/<path>` |
| AWS Secrets Manager | secret name + JSON key | `aws secretsmanager get-secret-value --secret-id <name> --query SecretString --output text \| jq -r .<key>` |
| GCP Secret Manager | resource name | `gcloud secrets versions access latest --secret=<name>` |
| `pass` (Linux) | path | `pass <path>` |

**Skill prompt:**

> *"1Password / Bitwarden / Vault reference? I'll fetch via the matching CLI when I need it."*

**Properties:**

- Secret never enters chat or any persistent file.
- Resolved just-in-time; not cached in shell vars longer than necessary.
- User must have the matching CLI installed + authenticated.

---

### 5. Direct chat paste (last resort — risk acknowledgement required)

User types the secret directly into chat. Skill **must** surface the risks before accepting.

**When this happens:** user explicitly says they want to paste, or none of patterns 1-4 work for their situation (e.g. they're trying out the skill with a one-shot key and don't want to set up file storage).

**Required risk acknowledgement (paraphrase, don't elide):**

> *"⚠️ If you paste the key here, it will live in this Claude Code session's history. It may also be visible to other tools loaded in the session and could appear in any transcripts you share later for support. After this deploy completes, I'll remind you to rotate the key in the provider's dashboard. Still want to paste? (yes / pick a safer path)"*

**If user confirms:**

- Accept the paste.
- Use the value immediately; don't echo it back.
- At the end of the deploy, surface a reminder: *"You pasted `<provider>` API key into chat earlier. Rotate it in `<provider's dashboard URL>` now that the deploy is complete."*

**Properties:**

- Convenient but contaminates session history.
- The rotation reminder is mandatory — without it, the user may forget the key is exposed.

---

## Per-credential-class recommendations

Different credential types pair best with different patterns. Surface the recommendation when the credential class is known.

| Credential class | Default suggestion | Alternative |
|---|---|---|
| **API keys** (Resend, SendGrid, OpenAI, etc.) | Pattern 1 (file path) or 2 (env var) | Pattern 4 (secrets manager) |
| **AWS / GCP / Azure / GH cloud auth** | Pattern 3 (CLI session) | Pattern 4 if user prefers explicit secret refs |
| **SSH keys** (cloud instance auth) | The path itself is what skill needs (not the contents — never the contents). Pattern 1, but specifically the file is the key file (`~/.ssh/id_ed25519`); skill uses `ssh -i <path>` | n/a — never accept SSH key contents pasted into chat |
| **DB passwords** | Pattern 1, 2, or 4 | Pattern 5 only if it's a one-shot generated password the user is about to throw away anyway |
| **OAuth client secrets** | Pattern 4 (long-lived; should be vaulted) | Pattern 1 with `chmod 600` |
| **Random secrets generated for the deploy** (`openssl rand -hex 32` etc.) | Generate inline; never echo to user; store in the state file or pass directly to the upstream tool | n/a |

---

## Skill prompt template

When the skill reaches a phase that needs a credential, use this template:

```
[Phase: <smtp / provision / etc.>] I need <credential class>.

Pick how to provide it:

  1. **File path** — paste the path to a file containing the secret (e.g. `~/.secrets/resend`)
  2. **Env var name** — paste the name of an env var I should read (e.g. `RESEND_API_KEY`)
  3. **Cloud-CLI session** — say which profile / context if you've already done `<provider> login`
  4. **Secrets-manager ref** — paste a `op://`, `vault://`, `bw://`, etc. reference
  5. **Paste directly** — least safe; key enters chat history; you'll be reminded to rotate after

Which? (default: 1 if you have a file, 2 if you exported an env var)
```

After the user picks, validate before proceeding:

- File path → `test -r <path>` first; refuse if mode is wider than 600 (offer to `chmod 600`).
- Env var → `test -n "$<NAME>"`; refuse if empty.
- Cloud-CLI session → run a smoke command (`aws sts get-caller-identity --profile <name>`); refuse if it errors.
- Secrets-manager ref → run a smoke command (`op read --no-newline <ref>` etc.); refuse if it errors or empty.
- Paste → require the risk acknowledgement before accepting.

---

## End-of-deploy: rotation reminders

If the user picked pattern 5 (direct paste) for any credential during the deploy, surface a rotation reminder during the `hardening` phase:

```
[Hardening] Rotation reminder — you pasted these keys into chat during this deploy:

  • Resend API key (used in smtp phase)  → rotate at https://resend.com/api-keys
  • <other-provider> key                 → rotate at <provider's dashboard URL>

Pasted secrets remain in this Claude Code session's history. Rotating now means
even if the session leaks later, the keys are already invalid.
```

If the user picked patterns 1-4 for everything, no rotation reminder is needed (the secrets never entered chat).

---

## Agent-mode rules (OpenClaw / Hermes / messaging-channel agents)

When this skill runs inside a long-running personal AI agent (OpenClaw, Hermes-Agent, or any agent that talks via WhatsApp / Telegram / Slack / iMessage / email), the rules tighten:

- **Pattern 5 (direct paste) is DISABLED.** Messaging channels persist chat history far longer than coding-tool sessions, sync to phones, often back up to cloud — pasting credentials there is meaningfully riskier. Refuse with: *"I can't accept credentials pasted into a messaging channel. Use a file path, env var, cloud-CLI session, or secrets-manager reference instead."* If the user insists, refuse again. No exceptions.
- **Reject deploy conversations from group channels** entirely. Group chats leak to all members. Respond once: *"Self-host deploys involve sensitive info — switch to a 1:1 DM."* Then stop until the user re-asks from a private channel.
- **Final hand-off content** (admin bootstrap URLs, generated passwords, rotation reminders) → secure 1:1 channel only, never group / public / shared.

The base five-pattern flow above still applies; agent-mode just removes Pattern 5 from the offered options and adds the group-channel guard.

## Failure modes

- **User insists on pasting "to keep it simple."** Respect their consent after risk acknowledgement, but surface the rotation reminder twice (once mid-deploy, once at hardening). **In agent mode, refuse instead** — don't accept paste regardless of insistence.
- **User pastes by accident** (meant to paste a path, pasted the key itself). Detect via key-shape regex (`re_[A-Za-z0-9_]+`, `sk-ant-`, `AKIA[0-9A-Z]{16}`, etc.); if a paste looks like a key when the prompt expected a path, stop and ask: *"That looks like the key itself, not a path. Did you mean to paste the key directly? (if so, see risks above; if not, paste the path)."*
- **Env var not present in Claude's shell.** User exported it after starting Claude Code. Ask them to restart Claude Code with the var set, or fall back to a different pattern.
- **File mode is too permissive** (e.g. `0644`). Refuse to read; offer to run `chmod 600 <path>` first.
- **Secrets-manager CLI not installed.** Detect via `command -v op` etc.; if missing, fall back to a different pattern, don't try to install a secret manager mid-deploy.
- **CLI session expired mid-deploy.** Common with AWS SSO. Skill detects the expiry, says *"AWS session expired; please re-run `aws sso login --profile <name>` and tell me when ready."*, then resumes from the failed phase.


---

# Post-deploy feedback flow

---
name: feedback
description: Post-deploy feedback module — sanitization rules + draft templates + submission paths for the three GitHub-issue input channels (recipe-feedback / software-nomination / method-proposal). Loaded by SKILL.md § Post-deploy feedback.
---

# Feedback module — drafting + submitting GitHub issues

This module is loaded after a deploy completes (or is abandoned) when the user opts in to share what they learned. Implements the multi-step consent flow described in CLAUDE.md § *Sanitization principles* and SKILL.md § *Post-deploy feedback*.

**Hard rule:** never post without showing the redacted draft + getting explicit "yes" from the user. The skill is the user's submitter; consent gates everything.

---

## Sanitization checklist

Apply BEFORE drafting. Scan the deployment session — including chat transcript, any tool outputs Claude has in context, any state-file references — and replace identifiers per the table.

### Strip-list (regex patterns + replacements)

| Class | Detection | Replacement |
|---|---|---|
| **Domains** (apex, www, admin) | Anything matching the user's `${CANONICAL_HOST}` / `${APEX}` / `${ADMIN_DOMAIN}` collected during inputs, plus generic FQDNs in URL paths the user typed | `${CANONICAL_HOST}` / `${APEX}` / `${ADMIN_DOMAIN}` |
| **Public IPv4** | `\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b` (excluding RFC-1918 ranges if you want to allow them as `${PRIVATE_IP}`) | `${PUBLIC_IP}` |
| **Private IPv4** | `\b(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)[0-9.]+\b` | `${PRIVATE_IP}` (or strip if it leaks network topology) |
| **IPv6** | Standard IPv6 patterns | `${PUBLIC_IPV6}` / `${PRIVATE_IPV6}` |
| **SSH key paths** | Anything matching `~/.ssh/[^ ]+`, `/home/[^/]+/\.ssh/[^ ]+`, `*.pem`, `*.priv`, `id_(rsa|ed25519|ecdsa)` | `${KEY_PATH}` |
| **SSH key contents** | `-----BEGIN [A-Z ]+ KEY-----` blocks | `<REDACTED-SSH-KEY>` |
| **Resend API key** | `re_[A-Za-z0-9_]+` | `<REDACTED-RESEND-KEY>` |
| **SendGrid API key** | `SG\.[A-Za-z0-9._-]+` | `<REDACTED-SENDGRID-KEY>` |
| **OpenAI API key** | `sk-[A-Za-z0-9]{20,}` | `<REDACTED-OPENAI-KEY>` |
| **Anthropic API key** | `sk-ant-[A-Za-z0-9_-]{20,}` | `<REDACTED-ANTHROPIC-KEY>` |
| **Slack tokens** | `xox[bp]-[A-Za-z0-9-]+` | `<REDACTED-SLACK-TOKEN>` |
| **GitHub PAT** | `ghp_[A-Za-z0-9]{36}` / `github_pat_[A-Za-z0-9_]+` | `<REDACTED-GH-PAT>` |
| **AWS access key ID** | `AKIA[0-9A-Z]{16}` | `<REDACTED-AWS-KEY>` |
| **AWS secret key** | After `aws_secret_access_key`, 40-char base64 | `<REDACTED-AWS-SECRET>` |
| **AWS account ID** | 12 consecutive digits in AWS context (ARN, account-id field) | `${AWS_ACCOUNT}` |
| **AWS profile name** | Whatever the user collected as `aws_profile` during inputs | `${AWS_PROFILE}` |
| **GCP service-account JSON** | `"type": "service_account"` blocks | `<REDACTED-GCP-SA>` |
| **Generic Bearer token** | `Bearer [A-Za-z0-9._~+/=-]{20,}` | `<REDACTED-BEARER>` |
| **Email addresses** | RFC-822 pattern; especially the LE email + SMTP from-address + any user identity email | `${EMAIL}` |
| **State-file contents** | Anything from `~/.open-forge/deployments/<name>.yaml` raw | Reference by deployment name only, never paste contents |
| **MySQL/Postgres password** | After `password=` / `--password ` / `IDENTIFIED BY ` | `<REDACTED-DB-PASSWORD>` |
| **OAuth client secrets** | After `client_secret` / `CLIENT_SECRET` | `<REDACTED-CLIENT-SECRET>` |
| **Random bytes from `openssl rand -hex N`** that the user generated as a secret | Long hex strings used as secrets | `<REDACTED-RANDOM-SECRET>` |

### Manual review pass (after regex)

After regex-based sanitization, do a final read-through looking for:

- **Hostnames in URL paths** that contain the user's domain (sed/regex may have missed embedded URLs).
- **Username conventions** that are personally identifiable (e.g. `qi-experiment` as an AWS profile).
- **Stack-trace lines** containing absolute filesystem paths (`/home/<user>/...`).
- **Anything pasted from the user's clipboard or env vars** that wasn't covered by the strip-list.

If you can't confidently classify something as safe, **redact it** — the user's final review is a safety net, not the only line of defense.

### What you may keep

| Class | OK to keep | Why |
|---|---|---|
| Recipe filenames (`ghost.md`, `openclaw.md`) | ✅ | Public; needed for context |
| Plugin version (`0.20.0`) | ✅ | Public; needed for triage |
| Combo names (`Ghost-CLI on Ubuntu`, `DigitalOcean droplet`) | ✅ | Public; needed for context |
| Generic error messages quoted from upstream tools | ⚠️ | OK if no identifiers; redact paths and IPs from stack traces |
| `${VAR}` placeholders | ✅ | These are the redactions; they're fine |
| Public repo URLs (upstream docs you're proposing to add) | ✅ | Public |

---

## Draft templates

Each template renders into the matching `.github/ISSUE_TEMPLATE/*.yml` form. The structure mirrors the form fields so the user pastes the body and the form auto-validates the sanitization checkboxes.

### Channel 1 — recipe feedback (default at end of deploy)

```markdown
**Recipe**: <recipe-filename>
**Combo**: <infra adapter> / <runtime>
**Plugin version**: <version-from-plugin.json>
**Outcome**: <one-of: Deploy succeeded with notes / Deploy succeeded after retries / Deploy failed; recovered manually / Deploy failed; abandoned / Recipe was outdated>

## What the recipe missed

<Concrete description: what surprised you, what failed, what required manual intervention. Sanitized.>

## Suggested edit (optional — diff format preferred)

```diff
@@ <section header from the recipe> @@
- <line that was wrong / missing>
+ <line that should be there>
```

## Sanitization confirmation
- [x] All domains, IP addresses, SSH key paths, API keys, AWS account IDs, and email addresses stripped from this issue body.
- [x] I understand this issue is public and permanent. I grant a non-revocable license to use this content in the open-forge recipe.
```

### Channel 2 — software nomination (Tier 2 → Tier 1)

```markdown
**Software name**: <project>
**Upstream repo**: <github URL>
**Upstream install-method index**: <docs / repo path / wiki URL>
**Intended deploy combo**: <infra> / <runtime>

## Why Tier 1?

<What's painful about this software's install that compounds across deploys?
Per the demand-driven graduation criteria in CLAUDE.md, a Tier 1 recipe earns
its keep when the captured tribal knowledge saves the next user real pain.>

## In-scope check (per CLAUDE.md § Is this software in scope?)

This software is: <one-of: deployable service / static-site generator / AI inference server / CI runner / storage backend / not sure>

## Confirmation
- [x] I have read the *Is this software in scope?* and *Demand-driven graduation criteria* sections in CLAUDE.md.
- [x] This software has at least one upstream-documented install method or canonical install artifact in-repo.
```

### Channel 3 — method proposal

```markdown
**Recipe to extend**: <recipe-filename>
**Method name**: <e.g. "Snap package", "Helm chart">
**Upstream URL documenting this method**: <URL>
**Source type**: <First-party — published by upstream / Community-maintained>

## Canonical install command(s)

```bash
<paste verbatim from upstream>
```

## Why this method matters

<When would a user pick this method over the existing options in the recipe?>

## Confirmation
- [x] I have verified the upstream URL above shows this install method on the current upstream version.
- [x] No credentials, IPs, or other identifiers in this issue.
```

---

## Submission paths (try in order)

The skill never opens a browser silently or POSTs without explicit user confirmation. Three submission paths in priority order:

### 1. `gh` CLI (preferred when available)

```bash
# Check if gh is authenticated for the right account
gh auth status

# If yes, submit
gh issue create \
  --repo zhangqi444/open-forge \
  --title "<title from template>" \
  --body-file /tmp/feedback-draft.md \
  --label recipe-feedback,recipe:<name>
```

Strengths: works headlessly in chat; respects user's existing GitHub auth.

Caveats: user must have `gh` installed + authenticated. If `gh auth status` errors, fall through to path 2.

### 2. GitHub MCP server (if available)

If `mcp__github__issue_write` is available in the tool list, use it:

```
mcp__github__issue_write({
  method: "create",
  owner: "zhangqi444",
  repo: "open-forge",
  title: "<title>",
  body: "<full body>",
  labels: ["recipe-feedback", "recipe:<name>"]
})
```

Strengths: no `gh` install needed; uses the MCP server's auth.

Caveats: only works if the MCP server is configured with appropriate scopes.

### 3. Prefilled URL (always-available fallback)

When neither `gh` nor the GitHub MCP works, generate a URL the user opens in a browser:

```
https://github.com/zhangqi444/open-forge/issues/new?template=recipe-feedback.yml&title=<URL-encoded-title>&body=<URL-encoded-body>
```

Print the URL in chat with the instruction:

> *"I can't post for you in this environment. Open this URL in a browser, review one more time, and click Submit:*
>
> *<URL>*
>
> *The form has the same sanitization checkboxes from the template — they'll be checked based on what you've already confirmed in chat."*

URL-encode the title + body. GitHub URL length limit is ~8 KB total; if the body is longer, truncate the body and put the rest in a `<details>` block (or warn the user to paste it manually).

---

## Liability + license boilerplate (paste at end of every issue body)

Append this exact block as the final paragraph of every issue body before submission:

```markdown
---

> By submitting this issue, I grant a non-revocable license to the open-forge project to use this content in recipes and documentation. The open-forge project bears no liability for my choice to share. I have reviewed the issue body for credentials and personal information per CLAUDE.md § *Sanitization principles*.
```

This is in addition to the checkboxes in the issue-template form — it's an extra paper trail in the issue body itself.

---

## When the deploy aborted before completion

If the user wants to file feedback about a deploy that failed mid-phase (e.g. preflight passed, provisioning failed at the security-group step), the `Outcome` field should be *"Deploy failed; abandoned"* and the body should include:

- Which phase failed.
- What the error was (sanitized — strip stack traces of paths/IPs).
- What workaround the user attempted (if any).
- Whether the user wants the recipe edited to handle this case, or whether they think it was an upstream / cloud-account issue (out of recipe scope).

These are often the highest-value feedback issues — they catch recipes that succeed in the maintainer's environment but fail in others.

---

## Failure modes to watch for

- **User says "post it" too quickly.** Respect their consent, but flag any line you weren't 100% sure about: *"Posting now. One last thing — line 14 mentions a username `qi-experiment` that might be your AWS profile name. Was that intentional?"*
- **Drafts that quote upstream error messages with embedded user data.** Common with Bitnami's `bncert-tool` output, AWS CLI errors quoting account IDs in ARNs.
- **State-file leaks.** If the user asks Claude to read `~/.open-forge/deployments/<name>.yaml` while drafting, do **not** paste contents — reference by deployment name only.
- **Multiple rapid yes-clicks.** If the user says "yes, yes, yes, post" to skip the review, slow down: re-show the draft once, get confirmation, then submit. Speed is not a user safety feature.
