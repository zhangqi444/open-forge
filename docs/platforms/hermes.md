# Using open-forge with Hermes-Agent

Hermes-Agent ([github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent)) is a self-improving personal AI agent from Nous Research, structurally similar to OpenClaw but Python-based with autonomous skill creation. Skills follow the same SKILL.md frontmatter convention OpenClaw uses (the [agentskills.io](https://agentskills.io) "open standard"), so open-forge ships as a single skill bundle that drops into either ecosystem.

> **Agent-mode caveat:** Same as OpenClaw — **direct credential paste (Pattern 5) is disabled** when open-forge runs inside Hermes. Pasting credentials into messaging channels is meaningfully riskier than into coding-tool chat. The skill only accepts file path / env var / cloud-CLI session / secrets-manager reference. See SKILL.md § *Asking for credentials* for the full agent-mode rules.

## Install

Hermes user skills live at `~/.hermes/skills/`. Imports from OpenClaw go to `~/.hermes/skills/openclaw-imports/`. open-forge ships compatible with both paths:

```bash
# 1. Generate the Hermes skill bundle
git clone https://github.com/zhangqi444/open-forge ~/code/open-forge
cd ~/code/open-forge
./scripts/build-dist.sh hermes
# Outputs: dist/hermes/SKILL.md (with Hermes-flavored frontmatter)

# 2. Drop into your Hermes skills directory
mkdir -p ~/.hermes/skills/open-forge/
cp dist/hermes/SKILL.md ~/.hermes/skills/open-forge/

# 3. Restart Hermes so the skill discovers
hermes gateway restart
```

Verify:

```bash
hermes skills list | grep open-forge
# or via slash command in any channel:
#   /skills
```

## Invoke

From any channel Hermes is paired with:

> *"Self-host OpenClaw on a Hetzner CX22 with the local Ollama provider."*

Hermes recognizes the deploy intent (matches the skill description) and follows the phased workflow.

You can also invoke explicitly via slash command:

> `/open-forge Self-host Mastodon on my Oracle Cloud ARM.`

## Tool translation

| open-forge concept | Hermes equivalent |
|---|---|
| `AskUserQuestion` (structured choice) | Hermes sends a message with numbered options; user replies inline |
| `WebFetch` | Hermes's `fetch` tool (or `curl` via shell) |
| `mcp__github__issue_write` | Hermes's MCP integration with the GitHub MCP server (preferred), or `gh` CLI shell-out |
| Persistent state file | Native fit — Hermes is a long-running daemon |
| OpenClaw migration | If user previously used open-forge on OpenClaw, the state file at `~/.open-forge/deployments/` is portable; `hermes claw migrate` (per Hermes upstream) helps with cross-agent state transfer for general state, but open-forge's per-deployment YAMLs work as-is on Hermes |

## Async-friendly phases

Same as OpenClaw — long-running daemon = natural fit for the phased workflow's time-elapsed waits:

| Phase | Sync mode (Claude Code) | Agent mode (Hermes) |
|---|---|---|
| `dns` propagation wait | User watches `dig` | Hermes polls `dig` and pings user when resolved |
| `tls` cert issuance | User watches certbot | Hermes monitors the certbot log, notifies on completion |
| `provision` instance-boot wait | User retries `ssh` | Hermes auto-retries SSH on a backoff |

## Channel-aware UX

Hermes can route message types to different channels (similar to OpenClaw). Same recommendations:

- Long-form (DNS records, recipe explanations) → email / note
- Quick decisions → primary chat
- Async waits → channel notifications on state change
- Final hand-off (admin URL, rotation reminders) → secure 1:1 channel only

## Self-improvement integration

Hermes has an autonomous skill-creation system that learns from successful task completion. open-forge's [feedback loop](../../plugins/open-forge/skills/open-forge/references/modules/feedback.md) is complementary:

- **Hermes's autonomous skill creation** — captures *agent-side* patterns (which tools the agent invoked, in what order)
- **open-forge's feedback loop** — captures *deployment-side* patterns (which gotchas surfaced, what surprised the user)

After a successful deploy, both can capture data — Hermes learns from the agent's procedural memory; open-forge proposes recipe edits via a sanitized GitHub issue. Don't conflate them.

## Limitations

- **Pattern 5 (direct paste) is disabled** — same hard rule as OpenClaw. File / env / cloud-CLI / secrets-manager only.
- **Hermes's skill-import path** at `~/.hermes/skills/openclaw-imports/` is for skills migrated FROM OpenClaw; new Hermes-native installs of open-forge should go to `~/.hermes/skills/open-forge/` directly.
- **Group channels** unsafe for deploy conversations — same caveat as OpenClaw.
- **Hermes's MCP integration** can use the GitHub MCP server for issue posting; if the user hasn't set this up, fall back to `gh` CLI or prefilled URL.
- **The `hermes claw migrate` command** is for migrating users from OpenClaw to Hermes broadly (memory, settings); it does NOT migrate the open-forge state file specifically. The state file at `~/.open-forge/deployments/` is portable across both agents because open-forge owns its own state storage.

## Example session (Telegram)

```
User (Telegram 14:02):  Self-host Vaultwarden on Hetzner.

Hermes (14:02):         I'll use the open-forge skill. Combo: Hetzner Cloud CX
                        × Docker. I need three things:
                          1. Hetzner API token (file path / env var name /
                             1Password ref — paste is disabled in agent mode)
                          2. Domain you want to use
                          3. Any preference on CX server size (default: cx22)

User (14:03):           Token at HCLOUD_TOKEN env var, domain
                        vault.aria.dev, default size

Hermes (14:03):         [reads $HCLOUD_TOKEN, runs hcloud server create]
                        Server up at <PUBLIC_IP>. Add this DNS record at
                        your registrar:
                          A vault.aria.dev → <PUBLIC_IP>
                        I'll poll every 60s. Will ping you when DNS resolves.

Hermes (14:31):         DNS resolved. Issuing TLS cert via certbot…

Hermes (14:33):         Vaultwarden running at https://vault.aria.dev.
                        Admin token sent via secure note. Rotate after
                        first login.

User (15:45):           That worked. Anything to add to the recipe?

Hermes (15:45):         I observed the DNS-propagation wait took ~28 min for
                        your registrar. The current vaultwarden.md recipe
                        doesn't note Hetzner Robot users may see longer
                        propagation. Want me to draft a recipe-feedback
                        issue with that gotcha? (sanitized — domain, IP,
                        token all redacted; you review before posting)

User (15:46):           Yes

Hermes (15:46):         [drafts redacted issue body in chat for review]
                        ...
```

## Reporting issues / contributing

Hermes's MCP integration (or `gh` CLI shell-out) handles GitHub issue posting. Same flow as on Claude Code — sanitized draft → user review → post. See [`references/modules/feedback.md`](../../plugins/open-forge/skills/open-forge/references/modules/feedback.md).

## Submitting open-forge to agentskills.io

[agentskills.io](https://agentskills.io) is the open-standard skills registry that both Hermes and OpenClaw consume. To publish open-forge:

1. Build the bundle: `./scripts/build-dist.sh hermes` (the file is also valid for OpenClaw — same frontmatter conventions).
2. Submit to agentskills.io via their publishing flow (see their docs at first publication).
3. Both Hermes and OpenClaw users install via their respective `skills install open-forge` command.
