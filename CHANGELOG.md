# Changelog

All notable user-visible changes to open-forge. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **For users**: after a new release lands, run `/plugin marketplace update zhangqi444/open-forge` in Claude Code to pick up changes. The marketplace doesn't push updates — you pull when you want them. GitHub Releases are tagged for each version (subscribable atom feed: <https://github.com/zhangqi444/open-forge/releases.atom>).
>
> **For contributors**: per [CLAUDE.md § Versioning](CLAUDE.md), every `plugin.json` version bump should add an entry here. Group by version; describe in user-visible terms (what improves for someone who self-hosts via the skill), not in commit-message terms.

## [0.24.0] — 2026-05-03

**Architectural completeness pass — fills the two operating-principle gaps (backups + monitoring) and registers gstack as a recommended companion.**

### Added

- `references/modules/monitoring.md` — cross-cutting monitoring module with five patterns (Uptime Kuma default, Healthchecks.io for cron jobs, Grafana+Prometheus+Loki for serious self-host, Beszel for multi-host, application-level health endpoints). Recipes can now reference a single source for "is this still working?" patterns instead of inventing per-recipe observability.
- `garrytan/gstack` documented as recommended companion skill in CLAUDE.md and AGENTS.md, with a per-command mapping table (which gstack slash command fits which open-forge workflow step). Optional but encouraged for AI sessions / maintainers working on the repo.

## [0.23.1] — 2026-05-03

### Added

- `ARCHITECTURE.md` — system-shape doc (actors, data flow, state stores, quality gates, cadence) complementing CLAUDE.md (policy). Single page that explains how the catalog grows as a maintenance system.
- README.md prose count refreshed (`950+` → `1,100+`); curated bundles (AI homelab, privacy stack) linked.
- AGENTS.md and CLAUDE.md cross-link to ARCHITECTURE.md.

## [0.23.0] — 2026-05-02

**Backups module + curated bundles — closes the architectural-hole half.**

### Added

- `references/modules/backups.md` — cross-cutting backups module with four patterns (restic to S3-compatible default, cloud-native snapshots, BorgBackup + borgmatic, application-level backup tools). Recipe-integration pattern + DR-drill protocol + 6 cross-cutting gotchas.
- `references/bundles/` — new curated multi-software bundle directory:
  - `ai-homelab.md`: Ollama + Open WebUI + AnythingLLM + Aider with cross-software wiring (env vars, Compose stanzas) for users wanting a private AI homelab.
  - `privacy-stack.md`: Pi-hole + Vaultwarden + Headscale OR wg-easy for users wanting network-wide ad-block + password vault + remote access.
  - `README.md`: when-to-use guidance + bundle-authoring pattern.
- SKILL.md routes goal-shaped requests ("set up an AI homelab") to bundles before falling through to single-software selection.
- `references/modules/credentials.md` post-process step (build-dist.sh) fixes broken in-bundle hyperlinks for non-Claude-Code platforms (closes [#40](https://github.com/zhangqi444/open-forge/issues/40)).

### Fixed

- BookStack recipe: GitHub-primary → Codeberg-primary per upstream's repo migration (closes [#41](https://github.com/zhangqi444/open-forge/issues/41)).

## [0.22.0] — 2026-04-30

**Phase 4 — agent-platform support (OpenClaw + Hermes).**

### Added

- `docs/platforms/openclaw.md` and `docs/platforms/hermes.md` — install/invoke/tool-translation guides for autonomous agent platforms. Same `agentskills.io` open-standard SKILL.md frontmatter for both.
- `dist/openclaw/SKILL.md` + `dist/hermes/SKILL.md` — drop-in skill bundles for `~/.openclaw/workspace/skills/open-forge/` and `~/.hermes/skills/open-forge/`.
- **Agent-mode rules** in SKILL.md and `references/modules/credentials.md`: Pattern 5 (direct credential paste) **DISABLED** when running inside a messaging-channel agent (WhatsApp / Telegram / Slack / etc.) — credentials must come via file path / env var / cloud-CLI session / secrets-manager reference. Group-channel deploy conversations refused. Async polling for time-elapsed waits (DNS propagation, TLS issuance) replaces blocking prompts.
- `scripts/build-dist.sh` extended with `build_openclaw()` and `build_hermes()` functions.

## [0.21.0] — 2026-04-30

**Phase 3 — distribution bundles + build script for 5 AI coding platforms.**

### Added

- `docs/platforms/{codex,cursor,aider,continue,generic}.md` — per-platform usage guides (~550 lines).
- `scripts/build-dist.sh` — single bash script that generates platform-specific bundles from canonical sources (CLAUDE.md / SKILL.md / credentials.md / feedback.md). Run `./scripts/build-dist.sh all` to regenerate; CI's `dist-bundles-up-to-date` enforces freshness.
- `dist/` directory with committed snapshots for codex / cursor / aider / continue / generic so casual users grab them without cloning + building.
- SKILL.md tool references genericized — Claude Code-specific tool names (`AskUserQuestion`, `WebFetch`, `mcp__github__*`) read as capabilities with platform-specific equivalents in parentheses.
- Operationalization: CLAUDE.md § *Processing incoming issues* now requires regenerating dist/ when patches touch CLAUDE.md / SKILL.md / `references/modules/`. CI workflow `.github/workflows/dist-bundles.yml` enforces.

## [0.20.1] — 2026-04-30

**Credential handling — five patterns over chat paste.**

### Added

- `references/modules/credentials.md` — full pattern catalog: (1) local file path, (2) env var name, (3) cloud-CLI session, (4) secrets-manager reference (`op://`, `bw://`, `vault://`), (5) direct paste (last resort with risk acknowledgement).
- SKILL.md and CLAUDE.md require the skill to **always offer all five patterns** when asking for sensitive input. Never accept SSH key contents (always file path); detect accidental pastes via key-shape regex (`re_*`, `sk-*`, `AKIA[0-9A-Z]{16}`); end-of-deploy rotation reminder for any pasted secret.

## [0.20.0] — 2026-04-29

**Issue-driven contribution model + post-deploy feedback flow.**

### Added

- Three GitHub issue templates under `.github/ISSUE_TEMPLATE/`: `recipe-feedback.yml`, `software-nomination.yml`, `method-proposal.yml`. Plus `config.yml` to disable blank issues and route users to the templates.
- CLAUDE.md § *Issue-driven contribution model* + § *Sanitization principles* + § *Processing incoming issues*. Catalog evolves through GitHub issues; AI sessions process them per the strict-doc-policy. Direct human PRs discouraged.
- SKILL.md § *Post-deploy feedback* — at end of every deploy, the skill offers to file a sanitized GitHub issue with deployment notes. Multi-step consent (no auto-post). Sanitization strips identifiers (domains, IPs, SSH keys, API keys, AWS account IDs, emails) before showing the user the draft.
- `references/modules/feedback.md` — full sanitization checklist with regex patterns + draft templates for all three channels + three submission paths (`gh` CLI → GitHub MCP → prefilled URL fallback).

## [0.19.3] — 2026-04-29

**Tier 1 / Tier 2 routing + "Is software in scope?" criteria.**

### Added

- CLAUDE.md § *Is this software in scope?* — explicit inclusion / exclusion criteria + edge-case table (static-site generators, CLI agents, AI inference servers, training libraries, CI runners, databases, storage backends).
- CLAUDE.md § *Two-tier coverage model* — Tier 1 (verified recipes) vs Tier 2 (live-derived from upstream docs at request time, best-effort) with demand-driven graduation criteria. Don't author Tier 1 speculatively from a "popular self-host" list.
- SKILL.md § *Tier 1 vs Tier 2 routing* — tells the skill how to detect tier and announce fallback to the user when a recipe doesn't match.

## [0.19.2] — 2026-04-29

**Strict-doc audit fixes across 6 recipes.**

### Fixed

- `ollama.md`: Windows installer corrected (was incorrectly described as `curl-pipe-bash`; actually PowerShell `irm | iex`).
- `stable-diffusion-webui.md`: AMD-DirectML and Docker community sections now have required ⚠️ blockquote flags.
- `openclaw.md`: npm/pnpm/bun promoted to standalone "Package managers" install method (was inline mention only).
- `open-webui.md`: added uv install section + `docker-compose.api.yaml` and `docker-compose.otel.yaml` variants. Helm chart re-flagged from "community" to "first-party" (the chart repo is `open-webui/helm-charts`, owned by the upstream org).
- `dify.md`: added AWS Marketplace AMI section. Cloud Templates section now has community-maintained blockquote flag.
- `hermes.md`: added Windows installer section (`scripts/install.ps1` + `install.cmd`) per canonical-install-artifacts rule.

## [0.19.1] — 2026-04-29

### Changed

- Plugin description refreshed to include vLLM and Langfuse.

## [0.19.0] — 2026-04-29

### Added

- **Langfuse** — open-source LLM observability + evaluation + prompt management platform. Six-service architecture (web + worker + Postgres + ClickHouse + Redis + MinIO/S3). Docker Compose + Kubernetes Helm + first-party Terraform modules for AWS / GCP / Azure + Railway one-click.

## [0.18.0] — 2026-04-28

### Added

- **vLLM** — production-grade LLM inference server. NVIDIA CUDA + AMD ROCm + Intel XPU/Gaudi + CPU variants. Docker, Kubernetes (raw manifests + first-party Helm chart + LeaderWorkerSet for distributed inference), and PaaS cookbooks (SkyPilot / RunPod / Modal / Cerebrium / dstack / Anyscale / Triton).

## [0.17.2] — 2026-04-29

**ghost.md strict-doc-policy rewrite — 7 first-party + 2 community methods.**

### Changed

- `ghost.md` rewritten from Bitnami-only (community-maintained) to documenting all upstream-blessed install methods per <https://ghost.org/docs/install/>: Ghost-CLI on Ubuntu (recommended production), Docker Compose preview (with self-hosted ActivityPub + Tinybird Analytics), Local install (dev), Install from source (Ghost core dev), DigitalOcean 1-Click marketplace, Linode VPS. Plus community-maintained options (Bitnami blueprint, Docker Hub `ghost` image) properly flagged.

## [0.17.1] — 2026-04-29

### Removed

- **Two upstream-doc hallucinations** caught by the strict-doc-policy audit pass: `dify.md` aaPanel one-click section (URL returned 403; no upstream evidence) and `open-webui.md` `docker-compose.cuda.yaml` reference (file doesn't exist in upstream repo — actual variants are `gpu.yaml`, `amdgpu.yaml`, etc.).

## [0.17.0] — 2026-04-28

### Added

- **Aider** — AI pair-programming CLI. `aider-install` (recommended Python 3.12 isolated env), uv one-liner, pipx, plain pip, Docker (`paulgauthier/aider` + `paulgauthier/aider-full`), GitHub Codespaces, Replit. Pairs with any LLM provider including local Ollama.

## [0.16.0] — 2026-04-28

### Added

- **AnythingLLM** — RAG-focused workspace + agent platform. Docker (canonical), Desktop App (Mac / Windows / Linux), bare-metal source install (flagged "not supported by core team"), plus upstream-published one-click cloud deploys for AWS CloudFormation / GCP Cloud Run / DigitalOcean Terraform / Render / Railway / RepoCloud / Elestio / Northflank.

## [0.15.1] — 2026-04-27

### Fixed

- Retroactive doc-verification fixes per CLAUDE.md strict-doc policy: existing recipes audited and corrected against upstream docs.

## [0.15.0] — 2026-04-27

### Added

- **LibreChat** — multi-provider chat UI for teams. Multi-user with social logins, per-user balance, agents + assistants + MCP, RAG via pgvector. Docker Compose dev + prod, npm / source, first-party Helm chart, plus one-click deploys for Railway / Zeabur / Sealos.

## [0.14.0] — 2026-04-26

### Added

- **Dify** — open-source LLMOps + AI app builder. Docker Compose (canonical, ~12 services), Kubernetes via community Helm, source code, plus cloud templates (Azure / GCP Terraform, AWS CDK for EKS/ECS, Alibaba Computing Nest).

## [0.13.0] — 2026-04-26

### Added

- **ComfyUI** — node-based AI image / video generation. Desktop App (Windows/macOS), Windows portable 7z (NVIDIA / AMD / Intel variants), `comfy-cli`, manual install, plus broad GPU support (NVIDIA CUDA, AMD ROCm Linux + Windows nightly, Intel Arc XPU, Apple Silicon MPS) and community Docker.

## [0.12.0] — 2026-04-25

### Added

- **Stable Diffusion WebUI (Automatic1111 / A1111)** — most-popular open-source AI image generator. Native (`webui.sh` Linux/macOS, `webui-user.bat` Windows, release zip), GPU paths for NVIDIA CUDA / AMD ROCm Linux / AMD DirectML Windows fork / Apple Silicon MPS, plus community-maintained Docker images.

## [0.11.0] — 2026-04-25

### Added

- **Open WebUI** — feature-rich web UI for any OpenAI-compatible LLM. Multi-user, RAG, web search, image gen, voice, MCP. Pairs natively with Ollama. Docker (`:main` / `:cuda` / `:ollama` / `:dev` tags), docker-compose (with bundled or external Ollama), pip (Python 3.11), Kubernetes (community Helm).

## [0.10.0] — 2026-04-25

### Added

- **Ollama** — local-LLM inference server. Foundation layer that pairs with every other AI project. Native (`install.sh` / `install.ps1` / `.dmg` / `.exe`), Docker (CPU + NVIDIA + AMD ROCm + Vulkan), Kubernetes (community Helm), Homebrew, Nix, Pacman.

## [0.9.0] — 2026-04-25

### Added

- **Hermes-Agent** (Nous Research) — self-improving personal AI agent. Native (`scripts/install.sh`), Docker, Nix, manual-dev, Termux (Android), Homebrew. Includes `hermes claw migrate` for OpenClaw users.

## [0.8.0] — 2026-04-25

### Changed

- OpenClaw recipe rewritten to cover every upstream-blessed install method documented under `docs.openclaw.ai/install/*`: AWS Lightsail blueprint, Docker Compose, Podman, Kubernetes (Kustomize, not Helm), native installers (`install.sh` / `install-cli.sh` / `install.ps1`), ClawDock, Ansible, Nix, Bun.

## [0.7.0] — 2026-04-24

### Added

- **Kubernetes / Helm** runtime — covers OpenClaw's last upstream-blessed deployment path.

## [0.6.0] — 2026-04-24

### Added

- Cloud-VM infra adapters: AWS EC2, Hetzner Cloud, DigitalOcean Droplet, GCP Compute Engine.
- **native** runtime module (curl/apt installer + systemd/launchd lifecycle).

## [0.5.0] — 2026-04-23

### Changed

- `openclaw.md` slimmed: software-layer concerns only; references runtime + infra modules for everything else.
- Combo-aware preflight: only require AWS CLI when infra ∈ AWS; nothing extra on localhost.
- SKILL.md and README.md refreshed.

## [0.4.0] — 2026-04-23

### Added

- OpenClaw via Docker on any Linux VPS ("Path C").

## [0.3.0] — 2026-04-22

### Fixed

- Skill trigger for OpenClaw — match user intent more reliably.

## [0.2.0] — 2026-04-22

### Added

- OpenClaw on AWS Lightsail (vendor-bundled blueprint).

## [0.1.0] — 2026-04-22

### Added

- Initial release. Ghost on AWS Lightsail (Bitnami blueprint).

[0.24.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.24.0
[0.23.1]: https://github.com/zhangqi444/open-forge/releases/tag/v0.23.1
[0.23.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.23.0
[0.22.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.22.0
[0.21.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.21.0
[0.20.1]: https://github.com/zhangqi444/open-forge/releases/tag/v0.20.1
[0.20.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.20.0
[0.19.3]: https://github.com/zhangqi444/open-forge/releases/tag/v0.19.3
[0.19.2]: https://github.com/zhangqi444/open-forge/releases/tag/v0.19.2
[0.19.1]: https://github.com/zhangqi444/open-forge/releases/tag/v0.19.1
[0.19.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.19.0
[0.18.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.18.0
[0.17.2]: https://github.com/zhangqi444/open-forge/releases/tag/v0.17.2
[0.17.1]: https://github.com/zhangqi444/open-forge/releases/tag/v0.17.1
[0.17.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.17.0
[0.16.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.16.0
[0.15.1]: https://github.com/zhangqi444/open-forge/releases/tag/v0.15.1
[0.15.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.15.0
[0.14.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.14.0
[0.13.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.13.0
[0.12.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.12.0
[0.11.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.11.0
[0.10.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.10.0
[0.9.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.9.0
[0.8.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.8.0
[0.7.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.7.0
[0.6.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.6.0
[0.5.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.5.0
[0.4.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.4.0
[0.3.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.3.0
[0.2.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.2.0
[0.1.0]: https://github.com/zhangqi444/open-forge/releases/tag/v0.1.0
