---
name: open-forge
description: Automate self-hosting of open-source apps on cloud infrastructure the user owns. Use when the user asks to "self-host", "deploy to my own cloud", "install X on AWS/Lightsail/Hetzner/DigitalOcean", "set up my own Ghost blog / Mastodon / WordPress / Nextcloud", wants to deploy the self-hosted personal AI agent **OpenClaw** (openclaw.ai — NOT the Captain Claw platformer game), or names any combination of an open-source app and a cloud provider. Walks the user through provisioning, DNS, TLS, outbound email (SMTP), and inbound email, in phases that are resumable across sessions via a state file at `~/.open-forge/deployments/<name>.yaml`. Supported today: Ghost on AWS Lightsail (Bitnami blueprint), OpenClaw on AWS Lightsail (openclaw_ls_1_0 blueprint). More projects and infras added under `references/projects/` and `references/infra/`.
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

Supported **infras** (under `references/infra/`):

| Cloud | Services |
|---|---|
| AWS | `aws/lightsail.md` (generic Lightsail provisioning; Ghost Bitnami blueprint + OpenClaw blueprint both use it) |
| Any Linux VM you already have | `byo-vps.md` — SSH in, no cloud APIs |
| Your own machine | `localhost.md` — Claude runs commands directly, no SSH |

Supported **runtimes** (under `references/runtimes/`):

| Runtime | Notes |
|---|---|
| Docker | `docker.md` — install Docker on host + lifecycle via docker-compose. Reusable across every infra. |
| Vendor blueprints | Bundled into infra adapters (e.g. Lightsail Ghost-Bitnami, Lightsail OpenClaw) — runtime choice is the vendor's |
| Native installer | Project-specific (e.g. OpenClaw's `curl \| bash`); documented in each project recipe |

Hetzner / DigitalOcean / GCP / EC2 dedicated adapters land as needed — until then, any Linux VM on them works through `byo-vps.md`.

## Selection — ask three questions

Before provisioning, establish three things by asking (or inferring from the user's prompt):

1. **What** to host? → loads `references/projects/<software>.md`
2. **Where** to host? → loads `references/infra/<cloud>/<service>.md` or `references/infra/{byo-vps,localhost}.md`
3. **How** to host? → loads the matching `references/runtimes/<runtime>.md` (skipped if the infra bundles the runtime, e.g. vendor blueprints)

The **how** question is *dynamically generated* from (software, where) — each project lists its "Compatible combos" table in the project recipe, and the options shown are filtered by the user's where answer. If the user's initial prompt already names a clear infra ("deploy to Lightsail" → AWS), announce the inferred choice and continue — don't re-ask. Use `AskUserQuestion` only when genuinely ambiguous.

Then **immediately load `references/modules/preflight.md`** and run its steps. Preflight is combo-aware — it only installs / validates what the chosen tuple actually needs (AWS CLI only when infra ∈ AWS, Docker only when runtime = docker, nothing extra on localhost).

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

## Common pitfalls across infras/projects

- **Stale DNS**: browsers cache 301 responses with long max-age. After any HTTP↔HTTPS or apex↔www redirect change, suggest hard reload or incognito.
- **Host key mismatch on new static IP**: the first SSH to a freshly-allocated IP needs `-o StrictHostKeyChecking=accept-new`; don't blindly blow away `~/.ssh/known_hosts` entries.
- **Non-interactive cert tools**: some have quirky option-file or flag requirements. See the project recipe — do not assume `--unattended` works.
- **Reverse-proxy misconfig after switching to https URL**: apps that enforce HTTPS redirects from the `url` config need `X-Forwarded-Proto` and `Host` preserved. See `references/modules/tls-letsencrypt.md`.

## Adding a new project or infra

A new project: add `references/projects/<name>.md` covering required services, config file paths, mail config shape, and any install/upgrade quirks. Follow the structure of the existing ghost.md.

A new infra: add `references/infra/<name>.md` covering provisioning (create instance, static IP, SSH key), firewall defaults, user/paths conventions. Follow lightsail.md.

Cross-cutting modules (new SMTP provider, new forwarder): add under `references/modules/`. Keep them project- and infra-agnostic.
