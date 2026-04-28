# open-forge

Self-host open-source apps on your own cloud, guided by Claude Code.

Given a project and a cloud provider, open-forge walks you through provisioning, DNS, TLS, outbound email (SMTP), and inbound email. It captures the non-obvious gotchas that usually cost hours the first time: proxy misconfigurations, non-interactive certbot flags, mail config quirks, DNS propagation, etc.

## Supported today

Supported software:

| Software | What it is |
|---|---|
| Ghost | Self-hosted blogging platform |
| OpenClaw | Self-hosted personal AI agent (openclaw.ai) |
| Hermes-Agent | Self-improving personal AI agent from Nous Research |
| Ollama | Local-LLM inference server (foundation layer for self-hosted AI) |
| Open WebUI | Feature-rich web UI for any OpenAI-compatible LLM (pairs with Ollama) |
| Stable Diffusion WebUI (A1111) | Most-popular open-source AI image generator (text-to-image, ControlNet, LoRA) |
| ComfyUI | Node-based AI image / video generation (workflow graphs; power-user alternative to A1111) |
| Dify | Open-source LLMOps + AI app builder (visual workflows, RAG, multi-tenant) |

Supported **where**:

| Where | How |
|---|---|
| **AWS Lightsail** | OpenClaw blueprint (Bedrock pre-wired) · Ubuntu + Docker · Ubuntu + native · Ghost Bitnami blueprint |
| **AWS EC2** | Ubuntu / Amazon Linux + Docker · + native |
| **Azure VM** (Bastion-hardened, no public IP) | Ubuntu + Docker · + native |
| **Hetzner Cloud** | CX-line VM + Docker · + native |
| **DigitalOcean** | Droplet + Docker · + native |
| **GCP Compute Engine** | VM + Docker · + native |
| **Oracle Cloud** | Always-Free A1.Flex ARM + native (via Tailscale) |
| **Hostinger** | Managed (1-Click) or VPS (Docker Manager via hPanel) |
| **Raspberry Pi** | Pi 4 / Pi 5 (64-bit) + native |
| **macOS VM** (Lume on Apple Silicon) | Sandboxed macOS + native (for iMessage via BlueBubbles) |
| Any Linux VM you already have (other providers, bare metal) | Docker · Podman · native |
| **Any Kubernetes cluster** (EKS / GKE / AKS / DOKS / k3s / kind / Docker Desktop) | Kustomize manifests (or community Helm charts for projects that ship them) |
| **Fly.io** · **Render** · **Railway** · **Northflank** · **exe.dev** | PaaS one-click templates from the upstream repos |
| **Your own machine** (macOS / Linux / Windows / WSL2) | Docker Desktop · Podman · native (`install.sh` / `install-cli.sh` / `install.ps1`) |

Three-question flow: what to host, where to host, how to host. Claude asks only what's genuinely ambiguous — if your prompt already names a clear cloud, the first question is skipped.

## Install

In Claude Code:

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

## Use

Tell Claude what you want to deploy:

> "I want to self-host Ghost on AWS Lightsail."

The `open-forge` skill will take it from there — collecting inputs, running AWS CLI + SSH commands, guiding you through DNS and SMTP setup, and recording state so you can resume across sessions.

## How it works

- **Phased workflow**: preflight → provision → DNS → TLS → outbound email → inbound email → hardening. Each phase is verifiable and resumable.
- **State file**: `~/.open-forge/deployments/<name>.yaml` records inputs, outputs, and completed phases.
- **Progressive disclosure**: the skill loads only the references it needs for your chosen project + infra combo.
- **Autonomous with `--dry-run`**: runs AWS CLI / SSH directly by default; pass `--dry-run` to print commands without executing.

## Repo layout

```
open-forge/
├── .claude-plugin/marketplace.json     # marketplace manifest
└── plugins/
    └── open-forge/                     # the plugin
        ├── .claude-plugin/plugin.json
        └── skills/open-forge/
            ├── SKILL.md
            ├── references/
            │   ├── projects/           # per-project recipes (ghost.md, openclaw.md, ...)
            │   ├── infra/              # per-infra adapters (aws/, hetzner/, digitalocean/, gcp/, byo-vps.md, localhost.md)
            │   ├── runtimes/           # docker.md, podman.md, native.md, kubernetes.md
            │   └── modules/            # cross-cutting (preflight, dns, tls, smtp, inbound, tunnels)
            └── scripts/
```

## Contributing

To add a new project: drop a `references/projects/<name>.md` recipe.
To add a new infra: drop a `references/infra/<name>.md` adapter.
See existing files for the expected shape.

## License

MIT
