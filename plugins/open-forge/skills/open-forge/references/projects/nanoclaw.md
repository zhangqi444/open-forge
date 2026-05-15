---
name: nanoclaw-project
description: NanoClaw recipe for open-forge. MIT-licensed minimalist AI-assistant framework — explicitly positioned as a lightweight alternative to OpenClaw by nanocoai. Core idea: one Node host process + per-session Docker containers running Claude agents via Anthropic's Claude Agent SDK, credential injection through OneCLI Agent Vault (no raw keys in containers), two SQLite files per session (inbound.db / outbound.db) for message passing. Skill-based architecture — no config files, customization via Claude Code editing the code. Channels (Discord/Slack/Telegram/WhatsApp/iMessage/Matrix/etc) and alternative providers (Codex/OpenCode/Ollama) installed on-demand from `channels` / `providers` branches. Not a classical server app; installs on user workstation (macOS/Linux/WSL2) via bootstrap script.
---

# NanoClaw

MIT-licensed AI-assistant framework. Upstream: <https://github.com/nanocoai/nanoclaw>. Docs: <https://docs.nanoclaw.dev>. Website: <https://nanoclaw.dev>.

**Positioning:** Built explicitly as a minimalist alternative to [OpenClaw](https://github.com/openclaw/openclaw). From the README:

> OpenClaw has nearly half a million lines of code, 53 config files, and 70+ dependencies. Its security is at the application level (allowlists, pairing codes) rather than true OS-level isolation. Everything runs in one Node process with shared memory. NanoClaw provides that same core functionality, but in a codebase small enough to understand: one process and a handful of files. Claude agents run in their own Linux containers with filesystem isolation, not merely behind permission checks.

**Design philosophy** (from upstream):

- **Small enough to understand** — one Node host process + a few source files, no microservices.
- **Secure by isolation** — agents run in Linux containers; filesystem access is explicitly mounted, not permission-checked.
- **Built for the individual user** — "bespoke, not generic." Each user forks + customizes.
- **No configuration files** — customization means modifying code (Claude Code does this for you).
- **AI-native, hybrid by design** — scripted deterministic setup path with Claude Code hand-off when steps need judgment.
- **Skills over features** — trunk ships registry + infra; channels/providers land on separate branches and install on demand.
- **Best harness, best model** — natively uses Claude via Anthropic's Claude Agent SDK; drop-in providers for Codex / OpenCode / Ollama.

**Not a classical self-hosted server.** NanoClaw installs on a user workstation (macOS / Linux / Windows via WSL2). It doesn't serve a web UI — it's a messaging-channel-fronted assistant. Think "Claude Code that lives on your workstation and responds to Telegram / Discord / WhatsApp" rather than "Nextcloud."

## Architecture

```
messaging apps → host process (router) → inbound.db → container (Bun, Claude Agent SDK) → outbound.db → host process (delivery) → messaging apps
```

Two SQLite files per session, each with exactly one writer → no cross-mount contention, no IPC, no stdin piping. Channels and alternative providers self-register at startup.

Key files (from upstream):

- `src/index.ts` — entry point: DB init, channel adapters, delivery polls, sweep
- `src/router.ts` — inbound routing: messaging group → agent group → session → `inbound.db`
- `src/delivery.ts` — polls `outbound.db`, delivers via adapter
- `src/host-sweep.ts` — 60s sweep: stale detection, due-message wake, recurrence
- `src/session-manager.ts` — resolves sessions
- `src/container-runner.ts` — spawns per-agent-group containers; OneCLI credential injection
- `src/db/` — central DB (users, roles, agent groups, messaging groups, wiring)
- `src/channels/` — channel adapter infra
- `src/providers/` — host-side provider config (`claude` baked in)
- `container/agent-runner/` — Bun agent-runner: poll loop, MCP tools, provider abstraction
- `groups/<folder>/` — per-agent-group filesystem (`CLAUDE.md`, skills, container config)

## What it supports

- **Messaging channels** (via `/add-<channel>` skills): WhatsApp, Telegram, Discord, Slack, Microsoft Teams, iMessage, Matrix, Google Chat, Webex, Linear, GitHub, WeChat, email via Resend.
- **Alternative agent providers**: Claude Agent SDK (default), `/add-codex` (OpenAI Codex), `/add-opencode` (OpenRouter / Google / DeepSeek / more via OpenCode config), `/add-ollama-provider` (local open-weight models).
- **Scheduled / recurring tasks** that run Claude and message back.
- **Web access** (search + fetch) for agents.
- **Flexible isolation** model: per-channel-agent, per-session, or shared-across-channels. See `docs/isolation-model.md`.
- **Per-agent workspace** — each agent group has its own `CLAUDE.md`, memory, container, mount allowlist.
- **OneCLI Agent Vault integration** — credentials injected at request time; agents never hold raw keys.
- **Docker Sandboxes (optional)** — micro-VM isolation on macOS.
- **Apple Container** (macOS-native) — opt-in alternative to Docker via `/convert-to-apple-container`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Bootstrap script (`nanoclaw.sh`) | <https://github.com/nanocoai/nanoclaw> | ✅ Only documented path | The standard install. Works on fresh machine. |
| Manual (clone + `pnpm install`) | Implicit — read `nanoclaw.sh` | ⚠️ Advanced | Contributors. Not officially documented. |
| Windows native | ❌ Not supported | Use WSL2. |

There are no multi-user / K8s / VPS deployment methods (yet) — it's a workstation-first tool.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "OS?" | `AskUserQuestion`: `macos` / `linux` / `windows-wsl2` | Windows native is not supported. |
| preflight | "Docker runtime?" | `AskUserQuestion`: `docker-desktop (macos/windows)` / `docker-engine (linux)` / `apple-container (macos-native, opt-in)` | Apple Container is macOS-only. |
| ai | "Anthropic API credential?" | Free-text (sensitive) | Claude Agent SDK needs this. Managed via OneCLI Agent Vault. |
| channel | "Initial channel?" | `AskUserQuestion`: `telegram` / `discord` / `whatsapp` / `local-cli` | Pairing step in bootstrap. |
| name | "Agent name?" | Free-text (trigger word). Default `@Andy` | Used as the mention trigger in channels. |

## Install — Bootstrap script

```bash
git clone https://github.com/nanocoai/nanoclaw.git nanoclaw-v2
cd nanoclaw-v2
bash nanoclaw.sh
```

Per the README, `nanoclaw.sh` does the following:

1. Installs Node.js 20+ + pnpm 10+ if missing.
2. Installs Docker (Desktop on macOS/Windows, Engine on Linux) if missing.
3. Registers your Anthropic credential with OneCLI.
4. Builds the agent container.
5. Pairs your first channel (Telegram / Discord / WhatsApp / local CLI).
6. If any step fails → hands off to Claude Code to diagnose + resume.

After setup, message your channel with the trigger word:

```
@Andy send me an overview of the sales pipeline every weekday morning at 9am
@Andy review git history for the past week each Friday and note drift
@Andy every Monday at 8am, compile news on AI developments and message me a briefing
```

From any channel you own or administer:

```
@Andy list all scheduled tasks across groups
@Andy pause the Monday briefing task
@Andy join the Family Chat group
```

## Adding channels + providers

Instead of configuring a feature, install a skill:

```bash
# Inside your NanoClaw install, via Claude Code
/add-telegram
/add-discord
/add-slack
/add-whatsapp
# ...

# Alternative providers
/add-codex         # OpenAI Codex (ChatGPT subscription or API key)
/add-opencode      # OpenRouter / Google / DeepSeek / Anthropic / more via OpenCode
/add-ollama-provider  # Local open-weight models via Ollama
```

Each skill copies exactly the modules it needs into your fork, wires the registration, and pins dependencies. Your fork stays minimal — only the channels and providers you asked for.

## Customizing behavior

No config files. To make changes, tell Claude Code:

- "Change the trigger word to @Bob"
- "Remember in the future to make responses shorter and more direct"
- "Add a custom greeting when I say good morning"
- "Store conversation summaries weekly"

Or run `/customize` for guided changes. Because the codebase is small (one process + handful of files), Claude can safely modify it without risk of ripple effects.

## Debugging

Ask Claude Code:

- "Why isn't the scheduler running?"
- "What's in the recent logs?"
- "Why did this message not get a response?"

Run `claude` then `/debug` for a guided session.

## Data layout

The `nanoclaw.sh` installer creates the install under your clone dir. Typical layout:

| Path | Content |
|---|---|
| `src/` | Host process source (router, delivery, sweep, session manager) |
| `container/agent-runner/` | Bun runner inside the container |
| `groups/<agent-group>/` | Per-agent workspace (`CLAUDE.md`, mounted into container) |
| `groups/<agent-group>/inbound.db` | Session inbound messages (host writes, container reads) |
| `groups/<agent-group>/outbound.db` | Session outbound messages (container writes, host reads) |
| Central DB | Users, roles, agent groups, messaging groups, channel wiring |

**Backup** = tar the whole install dir. Since every user's install is a custom fork, preserve your fork's git history too.

## Upgrading

Upstream is a git-first project; the workflow is fork-and-pull:

```bash
cd nanoclaw-v2
git fetch upstream
git log upstream/main ^main --oneline      # see what's new
git merge upstream/main                    # or cherry-pick security fixes only
```

The README explicitly states: **only security fixes, bug fixes, and clear improvements** will be accepted to base configuration. Everything else (new capabilities, OS support, hardware) should be contributed as skills on `channels` / `providers` branches.

Changelog: <https://github.com/nanocoai/nanoclaw/blob/main/CHANGELOG.md>. Full release history: <https://docs.nanoclaw.dev/changelog>.

## Gotchas

- **Not a server.** NanoClaw is a workstation tool. Don't try to deploy on a headless VPS (though technically possible with Docker + a messaging channel). It's designed to run on your laptop / desktop.
- **Windows-native is not supported.** WSL2 required. Works fine there; just don't try to run the shell script in Windows CMD / PowerShell.
- **Claude Code required** for setup error recovery + `/customize` + `/debug` + all `/add-<channel>` skills. Install from <https://claude.ai/download> before running the bootstrap.
- **Anthropic API credential is the critical secret.** Managed by OneCLI Agent Vault — the containers never see your raw API key, but the vault on your host does. Protect it accordingly.
- **Custom fork is the intended model.** Pull from upstream is a MERGE not a REBASE. Your modifications are expected; don't expect clean `git pull`.
- **Fork drift risk.** If you aggressively customize via Claude Code, upstream security fixes may be harder to merge. Periodic cleanup / re-sync expected.
- **No multi-user support.** One NanoClaw install = one user (you). For multi-user team use, each member runs their own fork.
- **Docker containers have resource costs.** One container per agent group per session. On a laptop with many groups and channels, this can get heavy. Monitor Docker resource usage.
- **OneCLI Agent Vault is a separate project** (<https://github.com/onecli/onecli>) — you're trusting two upstreams. Read both repos if security matters.
- **Apple Container (macOS)** is newer / less battle-tested than Docker Desktop. Fine for early adopters; stick with Docker Desktop if you want stability.
- **Docker Sandboxes (micro-VM)** adds another layer of isolation at cost of slower container startup + more memory. See `docs/docker-sandboxes.md`.
- **Per-agent-group container isolation** means agents CAN'T natively share data. If you want unified memory across channels, use the shared-session mode via `/manage-channels`. See `docs/isolation-model.md`.
- **Scheduled tasks depend on host uptime.** Close your laptop → scheduled tasks don't fire until you re-open. Not a cron server.
- **`CLAUDE.md` per agent group** is where agent personality / rules live. It's a real file in the mounted workspace — Claude reads it every invocation.
- **MCP tools available inside the container** — agents can use search, fetch, code editing, etc. Standard Claude Code toolset.
- **Trunk ships the registry + Chat SDK bridge only** — channel adapters themselves live on `channels` branch. If you check out `main` and expect Telegram to work, you'll be confused; run `/add-telegram` first.
- **Licensing is MIT** — permissive. Fork, modify, distribute freely.
- **If comparing to OpenClaw**, the tradeoff is simplicity vs. polish. OpenClaw is more mature, has native multi-node clustering, deeper skills ecosystem, approval workflows, etc. NanoClaw is minimal + auditable + container-isolated by default.

## Links

- Upstream repo: <https://github.com/nanocoai/nanoclaw>
- Docs: <https://docs.nanoclaw.dev>
- Website: <https://nanoclaw.dev>
- Security model: <https://docs.nanoclaw.dev/concepts/security>
- Architecture: `docs/architecture.md` in the repo
- Isolation model: `docs/isolation-model.md`
- Docker Sandboxes: `docs/docker-sandboxes.md`
- Changelog: <https://github.com/nanocoai/nanoclaw/blob/main/CHANGELOG.md>
- OneCLI (credential vault dependency): <https://github.com/onecli/onecli>
- Anthropic Claude Agent SDK: <https://docs.anthropic.com>
- Claude Code (required): <https://claude.ai/download>
- Discord: <https://discord.gg/VDdww8qS42>
- OpenClaw (the reference point): <https://github.com/openclaw/openclaw>
