# open-forge

> **Self-host any open-source app on your own infrastructure — guided by Claude Code.**
> No more "read a README, copy-paste 30 lines of bash, debug for hours."

`open-forge` is a Claude Code plugin that turns deployment from a documentation scavenger hunt into a guided chat. Tell Claude what you want to deploy and where; the skill handles provisioning, DNS, TLS, outbound email (SMTP), inbound email, and the non-obvious gotchas that usually cost hours the first time — proxy misconfigurations, non-interactive `certbot` flags, MySQL socket-vs-password auth, race conditions during admin bootstrap, redirect-loop triggers after enabling HTTPS, and more.

```
> "Self-host Ghost on a Hetzner CX22 with a Resend SMTP relay."

  [open-forge] Loading verified recipe ghost.md (v0.20.0).
  [open-forge] Combo: Hetzner Cloud CX × Docker.
  [open-forge] I have everything I need except your domain and Resend API key.

  Domain you want to host Ghost on?
```

## Why this is better than just asking Claude

Claude already knows how to run `docker compose up`. What `open-forge` adds:

- **Captured tribal knowledge.** ~180 recipes verified against upstream docs include the gotchas that aren't in any README — Bitnami's `bncert-tool` not supporting `--unattended`, Apache reverse-proxy needing `ProxyPreserveHost` after enabling HTTPS, MySQL on Ubuntu 22+ defaulting to socket-auth that Ghost rejects, and so on.
- **Resumable across sessions.** Every deployment writes a state file at `~/.open-forge/deployments/<name>.yaml`. If TLS fails at 11pm, resume from the `tls` phase tomorrow without re-running provisioning.
- **Consistent across clouds.** The "install Docker on Ubuntu" step is written once and reused for Hetzner / DO / Lightsail Ubuntu / localhost. You can swap clouds without re-deriving the install.
- **Source-attributed.** Every install method cites the exact upstream URL it derives from. When a recipe goes stale, the link is the recovery path; community-maintained methods are flagged with a warning blockquote.
- **Self-improving.** The skill drafts a sanitized GitHub issue at the end of every deploy with proposed recipe edits. You review, approve, post — the catalog gets better for the next user.

## Install

In Claude Code:

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

## Use

Tell Claude what you want to deploy:

> *"I want to self-host Ghost on AWS Lightsail."*
>
> *"Set up Mastodon on a Hetzner VPS — I'll bring my own SMTP."*
>
> *"Deploy Vaultwarden on my Raspberry Pi."*
>
> *"Run Open WebUI + Ollama on my laptop, expose it via Cloudflare Tunnel."*

The skill takes it from there — collects inputs, runs cloud CLI + SSH commands, walks you through DNS and SMTP, records state so you can resume across sessions.

## Verified recipes (~180)

A curated catalog of self-hostable apps with verified install paths, captured gotchas, and ongoing maintenance via the [feedback loop](#feedback-loop-the-catalog-grows-from-your-deploys). A taste:

| Category | Examples |
|---|---|
| **AI stack** | Ollama, vLLM, Open WebUI, LibreChat, AnythingLLM, Aider, OpenClaw, Hermes-Agent, Dify, Langfuse, ComfyUI, Stable Diffusion WebUI |
| **Publishing & docs** | Ghost, WordPress, Docusaurus, Outline, BookStack, Wiki.js, Etherpad |
| **Productivity** | Nextcloud, AppFlowy, Joplin, Logseq, Trilium, Memos, Plane, Twenty CRM |
| **Photos & media** | Immich, PhotoPrism, Jellyfin, Navidrome, Koel |
| **Dev & deploy** | Gitea, Coolify, Dokku, Portainer, Code-Server, Storybook |
| **Monitoring** | Grafana, Prometheus, Loki, Uptime Kuma, Netdata, SigNoz, Beszel |
| **Security & auth** | Vaultwarden, Authelia, Authentik, Keycloak, Infisical |
| **Networking** | Pi-hole, AdGuard Home, NetBird, Headscale, wg-easy |
| **Communication** | Mastodon, Mattermost, Rocket.Chat, Zulip, Jitsi Meet |
| **Automation & data** | n8n, Windmill, Activepieces, Huginn, Node-RED, Apache Superset, Metabase |

Full list: [`plugins/open-forge/skills/open-forge/references/projects/`](plugins/open-forge/skills/open-forge/references/projects/).

### Don't see your software?

The skill falls back to a **live-derived recipe** — fetches upstream docs at request time, applies the same strict-doc-verification policy, and reuses the existing infra + runtime modules. Best-effort, not authoritative; you'll see a banner like:

> *"This software isn't in our verified catalog — I'll fetch upstream docs live and reuse the runtime / infra modules. Treat my output as best-effort."*

If the live deploy goes well, the skill will offer to nominate the software for the verified catalog.

## Where + how

Verified support across **17 infra adapters** and **4 runtime modules** — write once, reuse everywhere.

### Where to host

| Cloud / location | Adapter |
|---|---|
| **AWS** | Lightsail (Ghost-Bitnami + OpenClaw blueprints + Ubuntu) · EC2 |
| **Azure VM** | Bastion-hardened (no public IP) |
| **Hetzner Cloud** | CX-line VM (`hcloud` CLI) |
| **DigitalOcean** | Droplet (`doctl` CLI) |
| **GCP Compute Engine** | VM (`gcloud` CLI) |
| **Oracle Cloud** | Always-Free A1.Flex ARM (Tailscale reach) |
| **Hostinger** | Managed (1-Click) or VPS (Docker Manager via hPanel) |
| **Raspberry Pi** | Pi 4 / Pi 5 (64-bit ARM) |
| **macOS VM** (Lume on Apple Silicon) | Sandboxed macOS — for iMessage via BlueBubbles |
| **Any Linux VM you already have** | SSH-only adapter; works for Vultr, Linode, on-prem, etc. |
| **Your own machine** | macOS / Linux / Windows / WSL2 — Claude runs commands locally |
| **Any Kubernetes cluster** | EKS / GKE / AKS / DOKS / k3s / kind / Docker-Desktop k8s |
| **PaaS** | Fly.io · Render · Railway · Northflank · exe.dev — one-click templates from upstream repos |

### How to host (when the infra gives you the choice)

| Runtime | Notes |
|---|---|
| **Docker** | The recommended default. Works wherever Docker is supported. |
| **Podman** | Rootless Docker-compatible alternative; Quadlet (systemd-user) supported. |
| **Native** | OS package manager / installer scripts. systemd / launchd / Scheduled-Tasks lifecycle. |
| **Kubernetes** | Kustomize-first (project recipes default to upstream's `scripts/k8s/deploy.sh` shape); Helm where upstream ships a chart. |

The "how" question is **dynamically generated** from your software + cloud choice — different combos expose different runtimes.

## Phased workflow

Each phase is **verifiable and resumable**. Claude completes, verifies, and records state before moving on.

```
preflight  →  provision  →  dns  →  tls  →  smtp  →  inbound  →  hardening  →  feedback
```

After `hardening`, the skill offers to file a sanitized GitHub issue with the deployment notes — see below.

## Feedback loop (the catalog grows from your deploys)

Catalog evolution happens through GitHub issues, not human pull requests. The skill drafts a sanitized issue at the end of every deploy; you review, approve, and post; AI sessions process the issues into recipe patches per the [strict doc-verification policy](CLAUDE.md#strict-doc-verification-policy-mandatory-before-writing-any-recipe).

Three input channels (all via [GitHub issue templates](.github/ISSUE_TEMPLATE/)):

| Template | When to use |
|---|---|
| **Recipe feedback** | You deployed via the skill and want to suggest recipe edits — gotchas you hit, install steps that surprised you, sections that were outdated. The skill drafts these automatically. |
| **Software nomination** | You want a software added to the verified catalog (after a successful live-derived deploy, the skill offers this). |
| **Method proposal** | You know an upstream-supported install method that an existing recipe doesn't cover. |

The skill **never auto-posts** — you see the redacted draft, review it, and explicitly approve before submission. Sanitization strips domains, IPs, SSH key paths, API keys, AWS account IDs, and emails before showing the draft.

## Contributing

**Don't open PRs.** [File an issue](https://github.com/zhangqi444/open-forge/issues/new/choose) instead. The structured templates encode the strict-doc policy; AI sessions process the queue and author patches.

If you're a maintainer working on the plugin itself, see [`CLAUDE.md`](CLAUDE.md) for the development conventions, the strict-doc-verification policy, the issue-processing workflow, and the architectural model.

## How it works (for the curious)

`open-forge` is built on a **3-layer model** asked in 3 questions:

| # | Question | Layer | Lives in |
|---|---|---|---|
| 1 | **What** to host? | software | `references/projects/<sw>.md` |
| 2 | **Where** to host? | infra | `references/infra/<cloud>/*.md` |
| 3 | **How** to host? | runtime | `references/runtimes/<runtime>.md` |

Reusability is the test: "install Docker on Ubuntu" is the same on Hetzner / DO / Lightsail / localhost — written once in the runtime layer. Project recipes are 80% software-specific concerns + a one-line link to the runtime.

Cross-cutting modules (`references/modules/`) cover preflight, DNS, TLS via Let's Encrypt, SMTP providers (Resend / SendGrid / Mailgun), inbound forwarders (ImprovMX), tunnels (Cloudflare / Tailscale / ngrok), and the post-deploy feedback flow.

For the full architectural treatment + the strict-doc-verification policy + the issue-driven contribution model, see [`CLAUDE.md`](CLAUDE.md).

## Repo layout

```
open-forge/
├── CLAUDE.md                                 # development policy + architecture
├── README.md                                 # you are here
├── .github/ISSUE_TEMPLATE/                   # the three input channels
│   ├── recipe-feedback.yml
│   ├── software-nomination.yml
│   └── method-proposal.yml
├── .claude-plugin/marketplace.json           # marketplace manifest
└── plugins/open-forge/                       # the plugin
    ├── .claude-plugin/plugin.json            # version
    └── skills/open-forge/
        ├── SKILL.md                          # end-user-Claude entrypoint
        └── references/
            ├── projects/                     # ~180 verified recipes
            ├── infra/                        # 17 cloud / VPS / localhost adapters
            ├── runtimes/                     # docker / podman / native / kubernetes
            └── modules/                      # preflight / dns / tls / smtp / inbound / tunnels / feedback
```

## License

[MIT](LICENSE) — fork freely, attribution appreciated.
