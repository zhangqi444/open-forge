---
name: open-forge
description: Automate self-hosting of open-source apps on cloud infrastructure the user owns. Use when the user asks to "self-host", "deploy to my own cloud", "install X on AWS/Lightsail/Hetzner/DigitalOcean", "set up my own Ghost blog / Mastodon / WordPress / Nextcloud", or names a combination of an open-source app and a cloud provider. Walks the user through provisioning, DNS, TLS, outbound email (SMTP), and inbound email, in phases that are resumable across sessions via a state file at `~/.open-forge/deployments/<name>.yaml`. Supported today: Ghost on AWS Lightsail (Bitnami). More projects and infras added under `references/projects/` and `references/infra/`.
---

# open-forge

## Overview

Walk a user from "I have a cloud account and a domain" to "working app at `https://my.domain` with TLS and mail." Load the appropriate project recipe and infra adapter based on the user's stated intent; run phases sequentially; record state so the user can resume later.

## What's supported

Check `references/projects/` and `references/infra/` for available recipes/adapters. As of this writing:

| Project | Infra adapters |
|---|---|
| Ghost (Bitnami blueprint) | Lightsail |

If the user names an unsupported combination, say so plainly and offer to fall back to the closest supported one, or to skip (and hand-roll).

## Selection — first thing to do

Before any provisioning, establish three things:

1. **Project** → load `references/projects/<project>.md`
2. **Infra** → load `references/infra/<infra>.md`
3. **Deployment name** (short hyphen-case, e.g. `my-blog`) → used as the state file key and often as the instance name

If any are missing or ambiguous, ask the user. Do not guess on infra — the adapter dictates every provisioning command downstream.

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

## Inputs collected during preflight

Per-infra adapter and per-project recipe may require more. Common across v1:

- Cloud profile + region (infra-specific)
- Deployment name
- Domain + canonical preference (`www` vs apex)
- Let's Encrypt email (for expiration notices)
- SMTP provider choice + API key + From address + display name
- Inbound forwarder choice + destination inbox (optional)

Collect only what's needed for the chosen project + infra. Do not over-ask.

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
