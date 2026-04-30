<p align="center">
  <img src="assets/icon.svg" width="120" height="120" alt="open-forge" />
</p>

<h1 align="center">open-forge</h1>

<p align="center">
  <a href="https://github.com/zhangqi444/open-forge/releases"><img src="https://img.shields.io/badge/plugin-v0.20.0-F97316?style=flat-square&labelColor=0F172A" alt="Plugin version" /></a>
  <a href="https://github.com/zhangqi444/open-forge/tree/main/plugins/open-forge/skills/open-forge/references/projects"><img src="https://img.shields.io/badge/verified%20recipes-180+-EA580C?style=flat-square&labelColor=0F172A" alt="Verified recipes" /></a>
  <a href="#install"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-D77756?style=flat-square&labelColor=0F172A" alt="Built for Claude Code" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/zhangqi444/open-forge?style=flat-square&labelColor=0F172A&color=22D3EE" alt="MIT License" /></a>
  <a href="https://github.com/zhangqi444/open-forge/stargazers"><img src="https://img.shields.io/github/stars/zhangqi444/open-forge?style=flat-square&labelColor=0F172A&color=FACC15" alt="GitHub stars" /></a>
</p>

> **Self-host any open-source app on your own infrastructure — guided by Claude Code.**
> No more reading READMEs and copy-pasting bash for hours.

```
> "Self-host Ghost on a Hetzner CX22 with a Resend SMTP relay."

  [open-forge] Loading verified recipe ghost.md (v0.20.0).
  [open-forge] Combo: Hetzner Cloud CX × Docker.
  [open-forge] I have everything I need except your domain and Resend API key.

  Domain you want to host Ghost on?
```

## Install

In Claude Code:

```
/plugin marketplace add zhangqi444/open-forge
/plugin install open-forge@open-forge
```

Then say what you want to deploy:

> *"Self-host Vaultwarden on my Raspberry Pi."*
>
> *"Run Open WebUI + Ollama on my laptop, expose via Cloudflare Tunnel."*
>
> *"Deploy Mastodon on a Hetzner VPS — I'll bring my own SMTP."*

## What makes it different from raw Claude Code

- **Captured gotchas** — recipes include the surprises that aren't in any README. Bitnami's `bncert-tool` won't accept `--unattended`. MySQL on Ubuntu 22+ rejects socket-auth that Ghost needs. Ghost-CLI's sudo username can't actually be `ghost`. The 1001st deploy is faster than the first because the previous 1000 contributed.
- **Resumable** — phased workflow + state file at `~/.open-forge/deployments/<name>.yaml`. If TLS fails at 11pm, resume from the `tls` phase tomorrow.
- **Self-improving** — every deploy can feed back into the catalog via a sanitized GitHub issue you opt in to. An AI agent re-verifies against upstream and patches the recipe for the next user.

## What you can deploy

**~180 verified recipes** with captured gotchas + ongoing maintenance. A taste:

| Category | Examples |
|---|---|
| **AI stack** | Ollama · vLLM · Open WebUI · LibreChat · AnythingLLM · Aider · Dify · Langfuse · ComfyUI · A1111 |
| **Publishing** | Ghost · WordPress · Docusaurus · Outline · BookStack · Wiki.js |
| **Productivity** | Nextcloud · Joplin · Logseq · Trilium · Plane · Twenty CRM |
| **Photos & media** | Immich · PhotoPrism · Jellyfin · Navidrome |
| **Dev tools** | Gitea · Coolify · Portainer · Code-Server |
| **Monitoring** | Grafana · Prometheus · Uptime Kuma · Netdata · SigNoz |
| **Security** | Vaultwarden · Authelia · Authentik · Keycloak |
| **Networking** | Pi-hole · AdGuard Home · NetBird · Headscale · wg-easy |
| **Communication** | Mastodon · Mattermost · Rocket.Chat · Jitsi Meet |
| **Automation** | n8n · Windmill · Activepieces · Node-RED |

Full list: [`references/projects/`](plugins/open-forge/skills/open-forge/references/projects/).

**Don't see what you want?** The skill falls back to a **live-derived recipe** — fetches upstream docs at request time and reuses the runtime + infra modules. Best-effort, not authoritative; you'll see a banner before it starts.

## Where you can deploy

**17 infra adapters × 4 runtimes** — write once, reuse everywhere.

- **Cloud VMs**: AWS (Lightsail · EC2) · Azure · Hetzner · DigitalOcean · GCP · Oracle Cloud (Always-Free ARM) · Hostinger
- **Bare metal / home**: Raspberry Pi · macOS VM (Lume) · any Linux VM you already have · your own machine
- **Kubernetes**: any cluster (EKS · GKE · AKS · DOKS · k3s · kind · Docker-Desktop)
- **PaaS**: Fly.io · Render · Railway · Northflank · exe.dev
- **Runtimes**: Docker · Podman · Native · Kubernetes (Kustomize-first; Helm where upstream ships one)

## Contributing

**File an issue, don't open a PR.** [Issue templates](.github/ISSUE_TEMPLATE/) cover three channels:

- **Recipe feedback** — the skill drafts this for you at end of deploy (sanitized; you opt in)
- **Software nomination** — request a recipe for an app the catalog doesn't have
- **Method proposal** — an upstream install method an existing recipe doesn't cover

An AI agent reads [`CLAUDE.md`](CLAUDE.md) as its runbook, re-verifies every change against upstream docs, and patches the catalog. Why issues, not PRs? Central verification keeps the catalog consistent, and the skill sanitizes drafts before posting so credentials don't leak into commit history.

For the architectural details (3-axis model, strict-doc-verification policy, two-tier coverage, sanitization rules), see [`CLAUDE.md`](CLAUDE.md).

## License

[MIT](LICENSE) — fork freely, attribution appreciated.
