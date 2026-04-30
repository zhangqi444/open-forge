# Using open-forge with OpenClaw

OpenClaw ([openclaw.ai](https://openclaw.ai)) is a self-hosted personal AI agent — a long-running daemon that talks to you via WhatsApp / Telegram / Slack / iMessage / etc. open-forge can run as an OpenClaw **skill**, letting users say *"self-host Vaultwarden on my Hetzner box"* from any messaging channel and have OpenClaw orchestrate the deploy on whatever host it's running on.

> **Agent-mode caveat:** When open-forge runs inside an autonomous agent like OpenClaw, **direct credential paste (Pattern 5)** is disabled. Pasting an API key into WhatsApp / Telegram / Slack is meaningfully riskier than pasting into a coding-tool chat (chat history syncs to phones, may be cloud-backed up, often persists indefinitely). The agent will only accept credentials via file path / env var / cloud-CLI session / secrets-manager reference. See SKILL.md § *Asking for credentials* for the full agent-mode rules.

## Install

OpenClaw skills live at `~/.openclaw/workspace/skills/<skill>/SKILL.md` per [docs.openclaw.ai/skills](https://docs.openclaw.ai/skills/) (Workspace skill type). open-forge ships a pre-built skill bundle:

```bash
# 1. Generate the OpenClaw skill bundle from canonical sources
git clone https://github.com/zhangqi444/open-forge ~/code/open-forge
cd ~/code/open-forge
./scripts/build-dist.sh openclaw
# Outputs: dist/openclaw/SKILL.md (with OpenClaw frontmatter)

# 2. Drop into your OpenClaw workspace
mkdir -p ~/.openclaw/workspace/skills/open-forge/
cp dist/openclaw/SKILL.md ~/.openclaw/workspace/skills/open-forge/

# 3. Restart the OpenClaw gateway so the skill loads
openclaw gateway restart
```

OpenClaw auto-discovers the new skill on next message. Verify:

```bash
openclaw skills list | grep open-forge
```

## Invoke

From any channel OpenClaw is paired with:

> *"Self-host Vaultwarden on my Hetzner CX22."*

OpenClaw recognizes the deploy intent (the skill description matches), loads `~/.openclaw/workspace/skills/open-forge/SKILL.md` into context, and follows the phased workflow.

For more explicit triggering:

> *"Use the open-forge skill to deploy Mastodon on my Oracle Cloud ARM."*

## Tool translation

| open-forge concept | OpenClaw equivalent |
|---|---|
| `AskUserQuestion` (structured choice) | OpenClaw sends a message via the active channel listing options as a numbered list; user replies with the number or the text |
| `WebFetch` | OpenClaw's built-in fetch capability (or `curl` via the `bash` tool) |
| `mcp__github__issue_write` | OpenClaw's `gh-issues` skill (one of the bundled skills) — composes via `gh` CLI under the hood |
| Persistent state file (`~/.open-forge/deployments/<name>.yaml`) | Native fit — OpenClaw is a long-running daemon; resume across days/weeks works automatically |

## Async-friendly phases

Agent mode actually fits open-forge's phased workflow *better* than coding-tool mode in places — because the agent runs as a daemon, time-elapsed waits become natural:

| Phase | Sync mode (Claude Code) | Agent mode (OpenClaw) |
|---|---|---|
| `dns` "wait for propagation" | User watches `dig` until it resolves | OpenClaw polls `dig` on a 30-second loop and pings user when ready: *"DNS resolved! Continuing to TLS phase."* |
| `tls` "wait for cert issuance" | User watches Let's Encrypt | OpenClaw monitors via the `acme.sh` / `certbot` log and notifies on success/failure |
| `provision` "wait for instance to boot" | User polls `ssh` | OpenClaw retries SSH every 10s and proceeds when reachable |

## Channel-aware UX

OpenClaw can route different message types to different channels (WhatsApp for chat, email for "screenshot the DNS records you added at your registrar," voice for confirmations). The skill respects channel preferences:

- **Long-form output** (DNS records to add at registrar, recipe explanations) → email or note
- **Quick decisions** (yes/no, pick from list) → primary chat channel
- **Async waits** (DNS propagation, TLS issuance) → channel notification when state changes
- **Final hand-off** (admin URL, rotation reminders) → secure channel (not public group chats)

## Limitations

- **Pattern 5 (direct paste) is disabled** in agent mode. Period. Forces the user to provide credentials via file / env / cloud-CLI / secrets-manager. Adds friction; reduces leak risk.
- **Multi-user OpenClaw deployments** (rare, but possible) need extra care — the skill's state file is per-deployment-name, but OpenClaw doesn't natively partition state by user. If multiple users share an OpenClaw instance, namespacing is the user's responsibility.
- **Public group chats** are not safe contexts for deploy conversations — credentials, IPs, admin URLs all leak to the room. open-forge in OpenClaw should refuse to operate from group channels and ask the user to switch to a 1:1 DM.
- **OpenClaw's onboard wizard runs once at install time**; the skill's per-deploy inputs are collected via the channel as messages, not via `openclaw onboard`.

## Example session (WhatsApp)

```
User (WhatsApp 9:14am):  Self-host Vaultwarden on my Hetzner CX22.

OpenClaw (9:14am):       I'll use the open-forge skill. Combo: Hetzner Cloud
                         CX × Docker. I need:
                           1. Hetzner API token (file path / env var / 1Password
                              ref — paste is disabled in agent mode)
                           2. Domain you want to use

User (9:15am):           Token at ~/.config/hcloud/token, domain vault.aria.dev

OpenClaw (9:15am):       Reading token from ~/.config/hcloud/token… got it.
                         Provisioning CX22 server now (this takes 30-60 seconds)…

OpenClaw (9:16am):       Server up at <PUBLIC_IP>. DNS records to add at your
                         registrar:
                           A vault.aria.dev → <PUBLIC_IP>
                         I'll poll DNS every 60s and ping you when it resolves.

OpenClaw (9:42am):       DNS resolved (took 27 minutes). Continuing TLS phase…

OpenClaw (9:44am):       TLS cert issued. Vaultwarden running at
                         https://vault.aria.dev. Bootstrap admin at
                         https://vault.aria.dev/admin (token at <link sent
                         via email>; rotate after first login).

User (10:30am):          Done.

OpenClaw (10:30am):      Want to share what you learned? I can draft a recipe-
                         feedback issue for vaultwarden.md (sanitized; you
                         review before posting).
```

## Reporting issues / contributing

OpenClaw can run `gh issue create` directly (via the `gh-issues` skill or the `bash` tool). The post-deploy feedback flow at the end of every deploy works the same way as on Claude Code — sanitized draft → user review → post. See [`references/modules/feedback.md`](../../plugins/open-forge/skills/open-forge/references/modules/feedback.md).

## Submitting open-forge to ClawHub

[ClawHub](https://docs.openclaw.ai/skills/clawhub) is OpenClaw's skill registry. To publish open-forge there:

1. Build the skill bundle: `./scripts/build-dist.sh openclaw`.
2. Follow ClawHub's submission flow (see ClawHub docs at first publication time — out of scope for this guide).
3. Once published, users install via `openclaw skill install open-forge` instead of the manual workspace copy.
