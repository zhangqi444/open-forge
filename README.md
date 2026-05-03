<p align="center">
  <img src="assets/icon.svg" width="120" height="120" alt="open-forge" />
</p>

<h1 align="center">open-forge</h1>

<p align="center">
  <a href="https://github.com/zhangqi444/open-forge/releases"><img src="https://img.shields.io/badge/plugin-v0.20.1-F97316?style=flat-square&labelColor=0F172A" alt="Plugin version" /></a>
  <a href="https://deepwiki.com/zhangqi444/open-forge"><img src="https://deepwiki.com/badge.svg" alt="Ask DeepWiki" /></a>
  <a href="https://github.com/zhangqi444/open-forge/tree/main/plugins/open-forge/skills/open-forge/references/projects"><img src="https://img.shields.io/github/directory-file-count/zhangqi444/open-forge/plugins/open-forge/skills/open-forge/references/projects?type=file&extension=md&style=flat-square&labelColor=0F172A&color=EA580C&label=verified%20recipes" alt="Verified recipes" /></a>
  <a href="#install"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-D77756?style=flat-square&labelColor=0F172A" alt="Built for Claude Code" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/zhangqi444/open-forge?style=flat-square&labelColor=0F172A&color=22D3EE" alt="MIT License" /></a>
  <a href="https://github.com/zhangqi444/open-forge/stargazers"><img src="https://img.shields.io/github/stars/zhangqi444/open-forge?style=flat-square&labelColor=0F172A&color=FACC15" alt="GitHub stars" /></a>
</p>

> **Self-host any open-source app on your own infrastructure — guided by Claude Code.**
> A self-improving recipe catalog that gets better every time anyone deploys.

```
> "Self-host OpenClaw on AWS Lightsail with Bedrock pre-wired."

  [open-forge] Loading verified recipe openclaw.md (v0.20.1).
  [open-forge] Combo: AWS Lightsail OpenClaw blueprint (vendor-bundled, Bedrock IAM included).
  [open-forge] I'll need your AWS profile and the domain you want.

  AWS profile name?
```

> *(OpenClaw — the self-hosted personal AI agent at [openclaw.ai](https://openclaw.ai) — is the project's signature use case; works the same way for any of the [1,100+ verified recipes](#coverage).)*

## Install

In **Claude Code**:

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

**Other AI coding tools and agent platforms** — see [`docs/platforms/`](docs/platforms/):

| Platform | How |
|---|---|
| [Codex](docs/platforms/codex.md) (ChatGPT / CLI) | System-prompt embedding or workspace files |
| [Cursor](docs/platforms/cursor.md) | `.cursor/rules/` bundle |
| [Aider](docs/platforms/aider.md) | `--read` files + `CONVENTIONS.md` |
| [Continue.dev](docs/platforms/continue.md) | Context provider + slash command |
| [OpenClaw](docs/platforms/openclaw.md) (personal AI agent at openclaw.ai) | Workspace skill at `~/.openclaw/workspace/skills/open-forge/` |
| [Hermes-Agent](docs/platforms/hermes.md) (Nous Research) | User skill at `~/.hermes/skills/open-forge/` |
| [Generic agents](docs/platforms/generic.md) | Any LLM that can read files + run shell |

**Agent-mode caveat:** When running inside an autonomous agent (OpenClaw / Hermes / messaging-channel agents), credential **paste is disabled** — the skill only accepts file paths, env vars, cloud-CLI sessions, or secrets-manager refs. Pasting credentials into messaging channels (WhatsApp / Telegram / etc.) is meaningfully riskier than into coding-tool chat. Group-channel deploy conversations are also refused.

**On Windows?** See [`docs/windows-setup.md`](docs/windows-setup.md) for WSL2 + Docker Desktop setup and common Windows gotchas (stale Git proxy, line endings, WSL integration).

Then say what you want to deploy:

> *"Set up OpenClaw on my Raspberry Pi with the local Ollama provider."*
>
> *"Run OpenClaw on a Hetzner CX22 + Docker, paired with Open WebUI."*
>
> *"Self-host Vaultwarden on my laptop, expose via Cloudflare Tunnel."*
>
> *"Deploy Mastodon on a Hetzner VPS — I'll bring my own SMTP."*

## A self-improving catalog (the key idea)

Raw Claude Code starts from zero every session. `open-forge` *accumulates* — every deploy can feed gotchas back into the catalog so the next user starts further ahead.

```
   you deploy ─► skill captures gotchas ─► you review + opt in to share
        ▲                                         │
        │                                         ▼
        └─ improved recipe ◄─ AI agent patches ◄─ sanitized issue
```

**The loop:**

1. **You deploy.** Skill walks you through provisioning, DNS, TLS, SMTP, hardening — recording state for resume.
2. **Skill drafts a sanitized issue** at the end with the gotchas it observed and proposed recipe edits. Domains, IPs, API keys, AWS account IDs are stripped before you see the draft.
3. **You review and opt in** (or don't — never auto-posted). One click; takes seconds.
4. **An AI agent processes the issue** — re-fetches upstream docs, applies the [strict doc-verification policy](CLAUDE.md), patches the recipe, opens a PR, bumps the version.
5. **The next user gets the improved recipe.**

That's why captured tribal knowledge already includes things like *"OpenClaw's three installers (`install.sh`, `install-cli.sh`, `install.ps1`) don't share state — pick one and stick with it"*, *"the Lightsail OpenClaw blueprint runs the gateway as a systemd USER unit with `loginctl enable-linger` so it survives no-login sessions"*, *"on Windows, OpenClaw's `iwr | iex` failures are non-fatal to the shell — silent partial installs are common, always check the explicit success line"*, and *"Bitnami's `bncert-tool` won't accept `--unattended`"* — none of which are in any upstream README.

## Other reasons it's better than raw Claude Code

- **Resumable across sessions** — phased workflow + state file at `~/.open-forge/deployments/<name>.yaml`. If TLS fails at 11pm, resume from the `tls` phase tomorrow.
- **Consistent across clouds** — "install Docker on Ubuntu" is written once and reused for Hetzner / DO / Lightsail / localhost. Swap clouds without re-deriving.
- **Source-attributed** — every install method cites the upstream URL it derives from. When upstream drifts, the link is the recovery path.

## Coverage

- **Software**: 1,100+ verified recipes for popular self-hostable apps — AI stack (Ollama · vLLM · Open WebUI · …), publishing (Ghost · WordPress · …), productivity (Nextcloud · Joplin · …), photos & media (Immich · Jellyfin · …), monitoring, security, networking, communication, automation. Plus **curated bundles** ([AI homelab](plugins/open-forge/skills/open-forge/references/bundles/ai-homelab.md), [privacy stack](plugins/open-forge/skills/open-forge/references/bundles/privacy-stack.md)) for goal-shaped requests, and **live-derived fallback** for anything else with public docs (best-effort; you'll see a banner before it starts).
- **Where**: any cloud VM (AWS · Azure · GCP · Hetzner · DigitalOcean · Oracle Always-Free ARM · Hostinger), your own machine, Raspberry Pi, macOS VM (Lume), any Kubernetes cluster (EKS · GKE · AKS · DOKS · k3s · kind), or PaaS (Fly.io · Render · Railway · Northflank · exe.dev).
- **How**: Docker · Podman · Native · Kubernetes (Kustomize-first; Helm where upstream ships one).

📖 **Browse the catalog**: [deepwiki.com/zhangqi444/open-forge](https://deepwiki.com/zhangqi444/open-forge) — auto-generated wiki view of every recipe, infra adapter, and module. Stays current with the repo.

Or just ask Claude — *"self-host X on Y"* — and it'll match.

## Contributing

**File an issue, don't open a PR.** [Issue templates](.github/ISSUE_TEMPLATE/) cover three channels:

- **Recipe feedback** — the skill drafts this for you at end of deploy (sanitized; you opt in)
- **Software nomination** — request a recipe for an app the catalog doesn't have
- **Method proposal** — an upstream install method an existing recipe doesn't cover

An AI agent reads [`CLAUDE.md`](CLAUDE.md) as its runbook, re-verifies every change against upstream docs, and patches the catalog. Why issues, not PRs? Central verification keeps the catalog consistent, and the skill sanitizes drafts before posting so credentials don't leak into commit history.

For how the catalog is maintained as a system (actors, data flow, state stores, quality gates), see [`ARCHITECTURE.md`](ARCHITECTURE.md). For policy details (3-axis model, strict-doc-verification policy, two-tier coverage, sanitization rules), see [`CLAUDE.md`](CLAUDE.md).

## License

[MIT](LICENSE) — fork freely, attribution appreciated.
