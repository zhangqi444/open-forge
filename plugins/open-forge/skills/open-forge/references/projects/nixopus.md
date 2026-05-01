---
name: Nixopus
description: "Open-source deployment platform with AI agent for deploy, monitor, and heal. Shell installer. nixopus/nixopus. Multi-server, framework-agnostic, chat interface, editor extension, Nixopus Cloud option."
---

# Nixopus

**Open-source deployment platform with an autonomous AI agent.** The agent handles the full deployment lifecycle: analyzes your codebase, generates configs, deploys your app, monitors it, and (in development) fixes failures by creating PRs. Multi-server orchestration, framework-agnostic, chat interface, VS Code extension, and automatic HTTPS. Self-host on your own infrastructure or use Nixopus Cloud.

Built + maintained by the **Nixopus team**.

- Upstream repo: <https://github.com/nixopus/nixopus>
- Docs: <https://docs.nixopus.com>
- Website: <https://nixopus.com>
- Cloud: <https://nixopus.com> (managed SaaS)
- Discord: <https://discord.gg/skdcq39Wpv>

## Architecture in one minute

- AI agent (LLM-powered) + deployment orchestrator
- Multi-server: connect multiple machines; deploy to any of them
- **Shell installer** — bootstraps everything on an Ubuntu server with one command
- LLM provider: OpenRouter (default), Anthropic, or configurable
- Automatic SSL + routing + domain management via the platform
- Chat interface: instruct the agent in natural language from the dashboard or your editor
- VS Code extension: deploy directly from your editor

## Compatible install methods

| Infra              | Runtime                      | Notes                                                                                |
| ------------------ | ---------------------------- | ------------------------------------------------------------------------------------ |
| **Shell installer**| `curl install.nixopus.com \| sudo bash` | **Primary** — bootstraps server in one command                          |
| **Nixopus Cloud**  | <https://nixopus.com>        | Managed SaaS; no server required                                                     |

## Prerequisites (self-hosting)

- Ubuntu server (any modern LTS)
- Publicly accessible domain (for HTTPS)
- OpenRouter or Anthropic API key (for the AI agent)
- `sudo` access on the server

## Install (self-hosted)

**Basic install** (prompts for domain + email interactively):

```bash
curl -fsSL install.nixopus.com | sudo bash
```

**With options pre-set:**

```bash
curl -fsSL install.nixopus.com | sudo \
  DOMAIN=panel.example.com \
  ADMIN_EMAIL=admin@example.com \
  OPENROUTER_API_KEY=sk-or-xxxxx \
  bash
```

**Using Anthropic instead of OpenRouter:**

```bash
curl -fsSL install.nixopus.com | sudo \
  LLM_PROVIDER=anthropic \
  ANTHROPIC_API_KEY=sk-ant-xxxxx \
  bash
```

The installer handles: dependency installation, service setup, domain + SSL configuration, and starting all Nixopus services.

## First boot

1. Run the installer (above).
2. Visit your configured domain (`https://panel.example.com`).
3. Log in with the admin credentials set during install.
4. **Connect a server** (can be the same machine) — Nixopus SSH-connects to it to deploy.
5. **Connect your GitHub** — link your repositories.
6. Use the **chat interface** ("deploy my-app from repo X") to trigger a deployment.
7. The AI agent analyzes the repo, generates a config, and deploys with HTTPS.
8. Monitor deployment status in the dashboard.

## How it works

1. **Connect your repo** — link GitHub; select a repository.
2. **Tell the agent to deploy** — from the dashboard chat or VS Code extension; agent analyzes the codebase and generates the right config.
3. **Go live** — app gets a URL with HTTPS; automatic SSL, routing, domain management.
4. **Agent keeps watching** *(in development)* — if something fails, agent reads logs, creates a PR with a fix, redeploys.

## Inputs to collect

| Input                     | Example                          | Phase    | Notes                                                                             |
| ------------------------- | -------------------------------- | -------- | --------------------------------------------------------------------------------- |
| Domain                    | `panel.example.com`              | Network  | DNS A-record → server; auto-provisioned TLS                                      |
| Admin email               | `admin@example.com`              | Auth     | Used for Let's Encrypt + admin account                                            |
| LLM API key               | OpenRouter or Anthropic key      | AI       | Powers the deployment agent; billed per use by your LLM provider                 |
| GitHub account            | OAuth                            | Repo     | For repository access; connected in the dashboard                                 |
| Target servers            | SSH access to deploy targets     | Infra    | Can be the same machine running Nixopus or additional servers                    |

## Gotchas

- **LLM API costs.** The AI agent calls an LLM for every deployment analysis, config generation, and (when ready) failure diagnosis. OpenRouter's cheapest models cost fractions of a cent per call, but monitor usage — a busy install can accumulate costs.
- **Curl-pipe-to-bash install.** The standard security concern applies: review the install script at `install.nixopus.com` before running as root. The project is open source — the script is inspectable.
- **Ubuntu-specific installer.** The bootstrap script is tested on Ubuntu. Other Debian-based distros may work; RHEL/Alpine/other: unknown. Use Docker or a VM if needed.
- **Publicly accessible domain is required.** SSL provisioning (Let's Encrypt) requires the domain to resolve to the server's public IP. Air-gapped or LAN-only installs need manual TLS.
- **"Agent keeps watching" is in development.** The auto-fix-and-redeploy feature is listed as "in development" — don't plan around it for production yet.
- **Multi-server: SSH key exchange.** When you add a target server, Nixopus SSH-connects to it. Make sure the Nixopus server can reach target servers on port 22, and that you've authorized its SSH key.
- **Framework-agnostic.** The agent infers the stack (Node/Python/Go/PHP/etc.) from the repo. For unusual stacks or monorepos, you may need to guide the agent with more specific prompts.
- **Nixopus Cloud vs self-host.** Cloud is the "no-installation" path — useful for eval before committing to self-hosting. Self-hosting gives you full control and no per-deployment SaaS fees.

## Project health

Active development, shell installer, Discord, docs site, VS Code extension, cloud option, AI agent integration. Multi-contributor team. Open source (check LICENSE for terms).

## AI-deployment-platform-family comparison

- **Nixopus** — shell-install, AI agent (deploy + monitor + heal), multi-server, GitHub integration, chat interface
- **Coolify** — Docker-based, no AI agent, more mature, broader app support
- **Dokku** — Heroku-on-your-server, CLI-driven, no AI
- **Caprover** — Docker swarm, web UI, no AI
- **Render/Railway** — SaaS, AI-adjacent, not self-hosted

**Choose Nixopus if:** you want an AI-driven deployment platform that can analyze your repo, generate configs, deploy, and eventually auto-heal — and you're comfortable with an early-stage but ambitious project.

## Links

- Repo: <https://github.com/nixopus/nixopus>
- Docs: <https://docs.nixopus.com>
- Website: <https://nixopus.com>
- Discord: <https://discord.gg/skdcq39Wpv>
- Coolify (mature alt): <https://coolify.io>
