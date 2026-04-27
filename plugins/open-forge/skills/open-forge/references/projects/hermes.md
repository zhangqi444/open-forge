---
name: hermes-project
description: Hermes-Agent recipe for open-forge — a self-improving personal AI agent from Nous Research (github.com/NousResearch/hermes-agent). Two services (`gateway` for messaging + OpenAI-compatible API on port 8642, and `dashboard` web UI on port 9119) with persistent state under `~/.hermes/`. Python (uv-based). Covers every upstream-blessed install method documented under `website/docs/getting-started/*` and `user-guide/docker.md` — `scripts/install.sh` (Linux/macOS/WSL2/Termux), Docker (registry image + docker-compose), Nix (flake + NixOS module with native or container modes), manual dev (`setup-hermes.sh` / uv venv), Termux (Android), Homebrew. Pairs with `references/runtimes/{docker,native}.md`, `references/infra/*.md`, and `references/modules/tunnels.md` as needed. Includes guidance for `hermes claw migrate` (import from OpenClaw).
---

# Hermes-Agent

Self-improving AI agent from Nous Research with an integrated learning loop, persistent memory, and multi-platform messaging gateways. Upstream: <https://github.com/NousResearch/hermes-agent> — docs at <https://nousresearch.github.io/hermes-agent/>.

Structurally similar to OpenClaw (and ships an explicit `hermes claw migrate` command for users coming from there) but Python-based instead of Node, with a different deployment surface — no per-cloud-provider deploy guides, no PaaS templates, no Kubernetes path. Five real install methods plus Homebrew packaging.

## Compatible combos

OpenClaw documents two parallel axes (Containers + Hosting) with per-cloud guides; Hermes only documents container/runtime choices. The "where" question is therefore answered by the existing infra adapters under `references/infra/` (Hermes runs on any Linux/macOS host that meets prereqs); the "how" question maps to one of these:

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Native installer** (`scripts/install.sh`) | `runtimes/native.md` + project section below | Default. macOS / Linux / WSL2 / Termux — auto-detected. Installs Python 3.11 + Node 22 + ripgrep + ffmpeg. |
| **Docker** (registry image `nousresearch/hermes-agent`) | `runtimes/docker.md` + project section below | Two services: `gateway` (port 8642) + `dashboard` (port 9119). State at `/opt/data` ↔ host `~/.hermes`. |
| **Nix** (flake) | project section below | `nix run`, `nix profile install`, or NixOS module with native + container modes. |
| **Manual dev** (`setup-hermes.sh` or `uv pip install -e ".[all,dev]"`) | project section below | For contributors. Clone the repo, set up a venv, install with extras. |
| **Termux** (Android via `.[termux]` extra) | project section below | Phone-native CLI agent. Some features unavailable on Android (Docker terminal, voice/whisper). |
| **Homebrew** | project section below | macOS / Linux. Packaging lives at `packaging/homebrew/`. |

For the **where** axis, pick any infra adapter under `references/infra/` (AWS Lightsail / EC2, Azure, Hetzner, DigitalOcean, GCP, Oracle, Hostinger, Raspberry Pi, BYO VPS, localhost). Hermes does not ship per-cloud install guides; it just runs anywhere Python runs.

The dynamic **how** question's options come from this table. On localhost the native installer is the default; on a cloud VPS the Docker compose is upstream's most-documented production path; for declarative / NixOS deployments the flake is the supported path.

## Inputs to collect

After cross-cutting preflight (cloud creds when infra ∈ AWS/Azure/Hetzner/DO/GCP; nothing for localhost; SSH details for byo-vps):

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "Hermes" / "Hermes-Agent" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS / Azure / Hetzner / DigitalOcean / GCP / Oracle Cloud / Hostinger / Raspberry Pi / macOS-VM / BYO VPS / localhost | Loads the matching infra adapter |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: native / Docker / Nix / manual dev / Termux / Homebrew | Filtered by infra (e.g. Termux only on Android-phone-as-host) |
| provision | "Which model provider?" | `AskUserQuestion`: Nous Portal / OpenRouter / Anthropic / OpenAI / GitHub Copilot / Gemini / Ollama (local) / Custom OpenAI-compatible / Other | Hermes supports a long list — see <https://nousresearch.github.io/hermes-agent/docs/integrations/providers> |
| provision | "API key for `<provider>`?" | Free-text (sensitive) | Skipped for OAuth-based providers (Nous Portal, OpenAI Codex, GitHub Copilot, Anthropic via Claude auth). Pasted into `~/.hermes/.env`, not chat-logged. |
| provision | "Which messaging channels?" | `AskUserQuestion`: Telegram / Discord / Slack / WhatsApp / Signal / Email / Home Assistant / None (CLI-only) | Drives `hermes gateway setup` interactive flow |
| provision (Docker only, optional) | "Run dashboard alongside gateway?" | `AskUserQuestion`: Yes / No | Default Yes — the dashboard is on by default in `docker-compose.yml`. |
| provision (Docker only, optional) | "Expose API server beyond localhost?" | `AskUserQuestion`: No / Yes (requires `API_SERVER_KEY`) | Default No — the API server is off unless explicitly enabled. |
| (later) hardening | "Migrate from OpenClaw?" | `AskUserQuestion` | Triggers `hermes claw migrate` if the user has a `~/.openclaw/` directory. |

## Software-layer concerns (apply to every deployment)

### What the gateway and dashboard are

Hermes runs **two** distinct services that share state at `~/.hermes/`:

| Service | Default port | Purpose | Default bind |
|---|---|---|---|
| `gateway` | `8642` | Messaging gateway (Telegram / Discord / Slack / WhatsApp / etc.) + OpenAI-compatible API server (off by default) + dashboard backend | `localhost:8642`, `host` networking in default compose |
| `dashboard` | `9119` | Web UI for config, sessions, memory, skills | **`127.0.0.1` only by default** — explicitly NOT internet-safe (stores API keys) |

Both are `docker compose` services in upstream's `docker-compose.yml`; in native installs they run as separate processes managed by systemd-user (Linux) or launchd (macOS).

The agent's actual reasoning happens inside whichever you start (`hermes` for CLI, `hermes gateway run` for daemon). The `gateway` and `dashboard` are presentation layers around the same core.

### Config files

| Path | Purpose |
|---|---|
| `~/.hermes/.env` | Secrets — API keys, gateway tokens, messaging-platform tokens, allowlists. **`chmod 600`** mandatory. |
| `~/.hermes/config.yaml` | Non-secret runtime config — model, terminal backend, approvals, memory, MCP servers, TTS, etc. |
| `~/.hermes/SOUL.md` | Agent identity / persona |
| `~/.hermes/memories/` | Long-term memory store (per-entry, deduped) |
| `~/.hermes/sessions/` | Session history (resumable via `hermes -c`) |
| `~/.hermes/skills/` | Installed skills (reusable workflows) |
| `~/.hermes/cron/` | Scheduled job definitions |
| `~/.hermes/pairing/` | DM pairing codes + approved users (per-platform JSON) |
| `~/.hermes/mcp-tokens/` | OAuth tokens for MCP servers |
| `~/.hermes/logs/` | Runtime logs |

In Docker, the entire `~/.hermes/` directory bind-mounts to `/opt/data` inside the container.

### Three-layer auth model

Hermes has **three independent** auth boundaries:

1. **Dashboard** — localhost-only by default. No password; physical/SSH-tunnel access is the trust boundary. **Never** publicly expose with `--insecure --host 0.0.0.0`. For remote access, `ssh -L 9119:localhost:9119 <host>`.
2. **OpenAI-compatible API server** (gateway port 8642) — off by default. Enabling requires setting both `API_SERVER_HOST=0.0.0.0` and `API_SERVER_KEY=<random>` in the gateway env. Docs: `website/docs/user-guide/api-server.md`.
3. **Messaging gateway user authorization** — every inbound message from Telegram/Discord/etc. is checked against:
   - Per-platform allow-all flag (`DISCORD_ALLOW_ALL_USERS=true`)
   - DM-pairing approved list (`hermes pairing approve <platform> <code>` after the user gets a pairing code via DM)
   - Platform-specific allowlists (`TELEGRAM_ALLOWED_USERS=12345,67890`)
   - Global allowlist (`GATEWAY_ALLOWED_USERS=12345,67890`)
   - Global allow-all (`GATEWAY_ALLOW_ALL_USERS=true`)
   - Default: **deny**

Default deny is the right posture. If no allowlists are set and `GATEWAY_ALLOW_ALL_USERS` is unset, the gateway logs a startup warning and rejects every inbound message.

### Pairing flow (messaging)

Code-based pairing is the friendliest first-contact path:

1. Unknown user DMs the bot.
2. Bot replies with an 8-character code (e.g. `ABC12DEF`) from a 32-char unambiguous alphabet (no `0`/`O`/`1`/`I`).
3. The bot owner runs `hermes pairing approve <platform> <code>` on the host.
4. The user is permanently approved on that platform.

Codes have a 1-hour TTL, rate-limited at 1 per user per 10 minutes, max 3 pending per platform, and 5 failed approvals trigger a 1-hour lockout. Storage is `chmod 0600` JSON under `~/.hermes/pairing/`.

Disable for a platform with `unauthorized_dm_behavior: ignore` in `config.yaml` (silently drops unauthorized DMs instead of replying with a code).

### Model provider config

Hermes supports a long list of providers. Two ways to configure:

```bash
# Interactive (recommended)
hermes model

# Direct via the CLI's split secret/non-secret store
hermes config set model anthropic/claude-opus-4.6     # → config.yaml
hermes config set OPENROUTER_API_KEY sk-or-...        # → .env
```

Hermes routes the value to the right file automatically. Hard requirement: **the chosen model must support at least 64K context**. Smaller-context models are rejected at startup. For local Ollama/llama.cpp, set the context explicitly (`-c 65536` for Ollama, `--ctx-size 65536` for llama.cpp).

Hosted providers (Claude / GPT / Gemini / Qwen / DeepSeek) all meet this trivially.

### Switching providers

```bash
hermes model            # interactive picker
# Verify with a fresh session — the change takes effect on next chat
hermes
```

For full reference of every provider + its env-var name, see <https://nousresearch.github.io/hermes-agent/docs/integrations/providers>.

### Migration from OpenClaw

Hermes ships a first-class migration tool. If the user has a `~/.openclaw/` directory:

```bash
# Always shows a preview first; confirms before changes
hermes claw migrate

# Or, fully automated with secrets:
hermes claw migrate --preset full --yes

# Preview only:
hermes claw migrate --dry-run
```

What gets imported: persona (`SOUL.md`), memory (`MEMORY.md` / `USER.md`), skills (workspace + managed + cross-project), model + provider config (`agents.defaults.*` + `models.providers.*`), agent behavior (max turns, verbose, reasoning effort, compression), session reset policies, MCP servers, TTS settings, messaging tokens (Telegram / Discord / Slack / WhatsApp / Signal / Matrix / Mattermost), and approval mode + command allowlist.

Things that don't have a direct Hermes equivalent (legacy `IDENTITY.md`, `TOOLS.md`, `HEARTBEAT.md`, OpenClaw cron jobs, OpenClaw plugins/hooks/UI-skin configs) get **archived** at `~/.hermes/migration/openclaw/<timestamp>/archive/` for manual review.

After migration: run a new session (imported skills load there), `hermes status` to verify provider auth, restart the gateway to pick up new tokens (`systemctl --user restart hermes-gateway`), re-pair WhatsApp via QR (`hermes whatsapp` — Baileys QR is not migratable), then `hermes claw cleanup` to rename `~/.openclaw/` → `.pre-migration/` once everything is verified.

This is the single biggest lever for users coming from OpenClaw — make sure the user knows it exists.

---

## Native installer (`scripts/install.sh`)

When the user picks **localhost / any Linux/macOS host → native**. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs, daemon lifecycle (systemd-user / launchd), and reverse-proxy guidance.

Upstream docs: <https://nousresearch.github.io/hermes-agent/docs/getting-started/installation>.

### Install

```bash
# Linux / macOS / WSL2 / Android (Termux) — auto-detected by the installer
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
exec $SHELL -l
hermes version
hermes doctor               # diagnose missing deps before going further
hermes setup                # interactive wizard: model + tools + channels in one flow
```

The installer auto-installs: Python 3.11, Node.js 22, Git, ripgrep, ffmpeg, plus uv. macOS: uses Homebrew. Linux: uses apt/dnf/yum. Termux: see the dedicated Termux section below.

For a fully non-interactive run (Claude pre-stages config later):

```bash
HERMES_NO_PROMPT=1 HERMES_NO_ONBOARD=1 \
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

(Verify these env vars in upstream's `scripts/install.sh` before relying on them — analogous to OpenClaw's `OPENCLAW_NO_PROMPT` but the exact names may differ; treat as TODO until verified.)

### Daemon lifecycle

```bash
# Run interactively (CLI):
hermes
hermes --tui               # newer terminal UI

# Run as a managed daemon:
hermes gateway install     # creates systemd-user unit (Linux) or launchd plist (macOS)
hermes gateway run         # foreground

# Manage (Linux):
systemctl --user status hermes-gateway
systemctl --user restart hermes-gateway
journalctl --user -u hermes-gateway -f
sudo loginctl enable-linger "$USER"     # daemon survives logout (mandatory on headless hosts)

# Manage (macOS):
launchctl list | grep hermes
launchctl kickstart -k gui/$(id -u)/ai.nousresearch.hermes
```

### Access

CLI on the host: just run `hermes`. Dashboard for remote hosts:

```bash
# SSH tunnel to the dashboard's localhost-only port
ssh -L 9119:localhost:9119 <user>@<host>
# then open: http://localhost:9119
```

The dashboard has **no auth** by default and stores API keys — never expose it publicly without putting an authenticated reverse proxy in front. For public reach via the messaging gateway (Telegram bots, etc.), no extra ingress is needed since the gateway connects outbound to the platform.

### Native-specific gotchas (Hermes-only)

- **64K minimum context.** If `hermes model` lets you pick a model that's too small, startup will fail with a context-size rejection. Pick Claude / GPT / Gemini / Qwen / DeepSeek (all easily 64K+); for local Ollama set `-c 65536`, for llama.cpp `--ctx-size 65536`.
- **`hermes doctor` is your friend.** It catches missing ripgrep / ffmpeg / Node version mismatches before the agent fails mid-session. Run it after install and after any system upgrade.
- **`hermes setup` is interactive.** Pause autonomous mode. Pre-stage `~/.hermes/.env` and `~/.hermes/config.yaml` if you want a fully scripted install.
- **Provider auth varies in shape.** Some providers (OpenRouter, Anthropic API) want an API key in `.env`; others (Nous Portal, OpenAI Codex, GitHub Copilot, Anthropic-via-Claude-auth) use OAuth and store tokens elsewhere. Don't assume `<PROVIDER>_API_KEY` is the only path.
- **Sessions live in `~/.hermes/sessions/`** and resume via `hermes -c` or `hermes --continue`. If `--continue` finds nothing, the user is probably on a different profile — `hermes sessions list` to confirm.

---

## Docker (any infra where Docker works)

When the user picks **any cloud → Docker** or **localhost → Docker**. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for the host-level Docker install + lifecycle basics.

Upstream docs: <https://nousresearch.github.io/hermes-agent/docs/user-guide/docker>. Image: `nousresearch/hermes-agent` on Docker Hub.

### Sizing

- Minimum: 1 CPU, 1 GB RAM, 500 MB disk (CLI-only, no browser tools).
- Recommended: 2 CPU, 2–4 GB RAM, 2+ GB disk.
- With browser automation (Playwright + Chromium): ≥ 2 GB RAM and `--shm-size=1g`.

### First run — interactive setup

The first run drops the user into the setup wizard so they can paste API keys and pick a model:

```bash
mkdir -p ~/.hermes
docker run -it --rm \
  -v ~/.hermes:/opt/data \
  nousresearch/hermes-agent setup
```

The wizard writes `~/.hermes/.env` and `~/.hermes/config.yaml` on the host (the volume mounts these into the container at `/opt/data`).

### Production run — gateway + dashboard via docker-compose

Upstream ships `docker-compose.yml` at the repo root. Pair the gateway and dashboard:

```bash
git clone https://github.com/NousResearch/hermes-agent.git ~/hermes-agent
cd ~/hermes-agent

# Set HERMES_UID/GID so files in the bind-mounted volume stay readable on the host
HERMES_UID=$(id -u) HERMES_GID=$(id -g) docker compose up -d

docker compose ps
docker compose logs -f gateway
```

The shipped compose enables `network_mode: host` (gateway needs outbound to messaging platforms; the dashboard's `127.0.0.1` bind keeps it host-local). For a no-host-networking variant, fall back to the explicit `docker run` form upstream documents:

```bash
# Gateway only (port 8642 exposes OpenAI-compat API + dashboard backend)
docker run -d --name hermes --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  -p 127.0.0.1:8642:8642 \
  nousresearch/hermes-agent gateway run

# Dashboard (port 9119, localhost-only)
docker run -d --name hermes-dashboard --restart unless-stopped \
  -v ~/.hermes:/opt/data \
  -p 127.0.0.1:9119:9119 \
  -e GATEWAY_HEALTH_URL=http://host.docker.internal:8642 \
  nousresearch/hermes-agent dashboard
```

Use `docker network create hermes-net` + `--network hermes-net` if you want the dashboard to find the gateway by container name instead of host IP.

### Optional: expose the OpenAI-compatible API server

**Off by default.** To expose:

```yaml
services:
  gateway:
    environment:
      - API_SERVER_HOST=0.0.0.0
      - API_SERVER_KEY=${API_SERVER_KEY}     # mandatory; without this the gateway refuses non-localhost binds
```

`API_SERVER_KEY` must be a strong random secret (`openssl rand -hex 32`). Anyone with the key can call the OpenAI-compatible endpoint and burn LLM tokens — treat as admin-grade.

### Lifecycle

```bash
cd ~/hermes-agent
docker compose ps
docker compose logs -f gateway
docker compose restart gateway
docker compose run --rm gateway hermes pairing list      # one-off CLI commands
docker compose exec gateway hermes doctor
docker compose exec gateway hermes -c                    # interactive resume
```

### Upgrades

```bash
cd ~/hermes-agent
git pull
docker compose pull
docker compose up -d --force-recreate
```

State at `~/.hermes/` survives. The image upgrade picks up the new binary; persistent config + sessions + memory are untouched.

### Pairing approval (Docker)

Same DM-pairing flow as native — runs inside the gateway container:

```bash
docker compose exec gateway hermes pairing list
docker compose exec gateway hermes pairing approve telegram ABC12DEF
```

### Docker-specific gotchas (Hermes-only)

- **`network_mode: host`** in upstream's compose is unusual for Docker apps. It's there because the gateway needs outbound to many platforms and the dashboard binds `127.0.0.1` to be host-local. On macOS / Windows, `host` networking is partially-supported (Docker Desktop emulates it) — verify with `curl http://localhost:9119` after `docker compose up`. If it fails, switch to the explicit `-p` form above.
- **Don't run two gateway containers against the same `~/.hermes/`.** Sessions and memory aren't designed for concurrent writers; symptoms are silent corruption. Dashboard alongside gateway is fine (read-only).
- **`HERMES_UID/GID` is mandatory for clean bind-mount perms.** Without them, files written in the container land as UID 10000 (the image's `hermes` user) which the host owner can't read/edit. The compose entrypoint uses `gosu` + `usermod` to remap on start.
- **Browser automation needs `--shm-size=1g`.** Default 64MB shm crashes Chromium. Add to compose: `shm_size: '1gb'` under the gateway service.
- **Default dashboard is plaintext + no auth.** Stores API keys. **Never** flip the bind to `0.0.0.0` without a TLS-terminating reverse proxy with auth in front (Caddy + basic auth is the simplest). Upstream is explicit about this.
- **First-run `docker run -it ... setup` is interactive.** Pause autonomous mode for the wizard, or pre-write `~/.hermes/.env` + `~/.hermes/config.yaml` on the host and skip the wizard with `docker compose up -d` directly.
- See `references/runtimes/docker.md` for generic Docker gotchas (OOM on build, bind-mount perms, image pull bandwidth).

---

## Nix (flake — `nix run` / `nix profile install` / NixOS module)

Three levels of Nix integration. Pick based on the user's goal:

| Level | Who it's for | What you get |
|---|---|---|
| `nix run` / `nix profile install` | Any Nix user (macOS, Linux) | Pre-built binary with all deps — then use the standard `hermes setup` workflow |
| **NixOS module (native)** | NixOS server deployments | Declarative config, hardened systemd service, sops-nix / agenix secrets |
| **NixOS module (container)** | Agents that need self-modification (`apt`/`pip`/`npm install`) | All of the above, plus a persistent Ubuntu container with `/nix/store` bind-mounted |

Upstream docs: <https://nousresearch.github.io/hermes-agent/docs/getting-started/nix-setup>.

### Quick start (any Nix user)

```bash
# Run directly — builds on first use, cached after
nix run github:NousResearch/hermes-agent -- setup
nix run github:NousResearch/hermes-agent -- chat

# Or install persistently to your profile
nix profile install github:NousResearch/hermes-agent
hermes setup
hermes chat
```

After `nix profile install`, `hermes`, `hermes-agent`, and `hermes-acp` are on PATH. From here it's identical to the standard install — `hermes setup` walks through provider selection, `hermes gateway install` registers the systemd-user / launchd service, config lives at `~/.hermes/`.

### NixOS module — native mode (default)

Add the flake input + import the module:

```nix
# /etc/nixos/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hermes-agent.url = "github:NousResearch/hermes-agent";
  };
  outputs = { nixpkgs, hermes-agent, ... }: {
    nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ hermes-agent.nixosModules.default ./configuration.nix ];
    };
  };
}
```

Minimal `configuration.nix`:

```nix
{ config, ... }: {
  services.hermes-agent = {
    enable = true;
    settings.model.default = "anthropic/claude-sonnet-4";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true;     # puts hermes CLI on system PATH; sets HERMES_HOME
  };
}
```

`nixos-rebuild switch` creates the `hermes` user, generates `~/.hermes/config.yaml` from `settings`, wires up secrets from `environmentFiles`, and starts a hardened systemd unit.

### NixOS module — container mode

Adds one line to swap to a persistent Ubuntu container with the Nix-built binary bind-mounted (so the agent can `apt install`, `pip install`, `npm install` and have those packages persist):

```nix
services.hermes-agent = {
  enable = true;
  container.enable = true;
  container.hostUsers = [ "your-username" ];   # creates ~/.hermes -> stateDir symlink for the host CLI
  addToSystemPackages = true;
};
```

Container mode auto-enables `virtualisation.docker.enable`. For Podman: `container.backend = "podman"; virtualisation.docker.enable = false;` and grant passwordless sudo for `podman` per the upstream Podman note.

The Nix-built binary works inside Ubuntu because `/nix/store` is bind-mounted read-only. The container is only recreated when its identity hash changes (image, extraVolumes, extraOptions, entrypoint script). Code-only changes update a `current-package` symlink — no recreation, no loss of `apt`-installed packages.

### Secrets (sops-nix or agenix)

```nix
{
  sops.secrets."hermes-env" = { format = "yaml"; };
  services.hermes-agent.environmentFiles = [ config.sops.secrets."hermes-env".path ];
}
```

The encrypted file contains `OPENROUTER_API_KEY=sk-or-...`, `TELEGRAM_BOT_TOKEN=123456:ABC...`, etc. Plain files work as a starting point — `sudo install -m 0600 -o hermes ...`. Never put keys inline in the Nix expression; values in `/nix/store` are world-readable.

### Managed-mode CLI guards

When Hermes runs via the NixOS module, mutating CLI commands are **blocked** so the on-disk state can't drift from `configuration.nix`:

| Blocked | Why |
|---|---|
| `hermes setup` / `hermes config edit` / `hermes config set ...` | Config is generated from `settings` — edit the Nix file |
| `hermes gateway install` / `hermes gateway uninstall` | Service is managed by NixOS |

To change config, edit `configuration.nix` and `sudo nixos-rebuild switch`.

### Nix-specific gotchas (Hermes-only)

- **Container-mode writable layer is lost on recreation.** Image / volume / entrypoint changes recreate the container. State at `/data` and `/home/hermes` survives (bind mounts); `apt`/`pip`/`npm` packages in `/usr` and `/usr/local` do **not**. Bake critical packages into a custom `container.image`.
- **GC root protection.** The module creates `${stateDir}/.gc-root` so `nix-collect-garbage` can't remove the running binary. If it breaks, restarting the service recreates it.
- **`addToSystemPackages = true` is required for the host CLI to share state with the service.** Without it, running `hermes` interactively creates a separate `~/.hermes/` from the systemd service's state dir.
- **`container.hostUsers` matters for permissions.** Listed users get a `~/.hermes` symlink to the service stateDir and are added to the `hermes` group. Skip it and the host user can't read service files.
- **Podman + container mode = sudo dance.** NixOS runs the container as root; Docker users have docker-group socket access, Podman users need passwordless sudo for `podman`. The CLI auto-detects.

---

## Manual dev install (`setup-hermes.sh` / uv venv)

For contributors hacking on Hermes itself, or users who want full control over the Python environment without the curl-pipe-bash installer.

Upstream docs: <https://nousresearch.github.io/hermes-agent/docs/getting-started/installation> (under "Development setup").

### Option A — `setup-hermes.sh` (one-shot)

```bash
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
./setup-hermes.sh
```

The script handles venv creation + `uv pip install -e ".[all,dev]"` + post-install steps automatically.

### Option B — manual uv venv (fully explicit)

```bash
# Install uv if not present
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone and set up
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
uv venv venv --python 3.11
source venv/bin/activate
uv pip install -e ".[all,dev]"

# Verify
hermes version
hermes doctor
```

`.[all,dev]` pulls every optional extra (voice, browser, ACP, MCP, …) plus dev tools (pytest, ruff, mypy). For just the runtime extras: `.[all]`. For minimal: `.` (no brackets).

### Running from a checkout

```bash
source venv/bin/activate
hermes setup
hermes
# or in another terminal:
hermes gateway run
```

For developers iterating on the codebase, the editable install (`-e`) means edits to `agent/`, `gateway/`, etc. take effect on the next `hermes` invocation — no reinstall.

### Manual-dev-specific gotchas (Hermes-only)

- **Submodules matter.** `tinker-atropos/` (RL training submodule) and any other submodules need `--recurse-submodules` on clone or `git submodule update --init --recursive` after.
- **Editable install + venv activation.** Running `hermes` outside the venv after an editable install will pick up whatever `hermes` is on your global PATH (probably the curl-installed one, if you have it). Always `source venv/bin/activate` first, or use `venv/bin/hermes` directly.
- **Don't mix dev install with the curl installer's daemon.** If you `hermes gateway install` from a curl-installed Hermes, then `cd hermes-agent && source venv/bin/activate && hermes`, the running daemon is still the old binary. Stop the daemon (`systemctl --user stop hermes-gateway`) before debugging the dev checkout.
- **Tests need `.[dev]`.** `pytest` runs require dev extras. `uv pip install -e ".[dev]"` if you didn't pick `.[all,dev]`.

---

## Termux (Android phone-native CLI)

When the user wants Hermes running directly on their Android phone via [Termux](https://termux.dev/). This is the only fully phone-native AI-agent path open-forge supports.

Upstream docs: <https://nousresearch.github.io/hermes-agent/docs/getting-started/termux>.

### What's supported in the tested path

The Termux bundle (`.[termux]` extra) includes: Hermes CLI, cron, PTY/background terminal, Telegram gateway (best-effort due to Android suspend), MCP, Honcho memory, ACP.

### What's NOT supported on Android

- `.[all]` extras (some packages have no Android wheels)
- `voice` extra — `faster-whisper` → `ctranslate2` has no Android wheel
- Automatic Playwright/browser bootstrap (skipped by the installer)
- Docker terminal backend (Docker isn't available in Termux)
- Gateway as a true managed service (Android may suspend; runs are best-effort)

### Option A — one-line installer

```bash
# In Termux (the installer auto-detects Android)
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

On Termux, the installer uses `pkg` for system packages, creates the venv with `python -m venv`, installs `.[termux]` with pip, and links `hermes` into `$PREFIX/bin` so it stays on PATH. It skips the browser / WhatsApp bootstrap.

### Option B — manual install (when the installer fails or you want to debug)

```bash
# 1. Termux system packages
pkg update
pkg install -y git python clang rust make pkg-config libffi openssl nodejs ripgrep ffmpeg

# 2. Clone with submodules
git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git
cd hermes-agent

# 3. Venv + ANDROID_API_LEVEL (matters for Rust / maturin packages like jiter)
python -m venv venv
source venv/bin/activate
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"
python -m pip install --upgrade pip setuptools wheel

# 4. Install the tested Termux bundle
python -m pip install -e '.[termux]' -c constraints-termux.txt

# 5. Persist on PATH across new Termux shells
ln -sf "$PWD/venv/bin/hermes" "$PREFIX/bin/hermes"

# 6. Verify
hermes version
hermes doctor

# 7. First chat / setup
hermes
# or:
hermes setup
```

### Termux-specific gotchas (Hermes-only)

- **`uv pip` fails on Android.** Use the stdlib venv + `pip` instead (steps above). Don't try to switch back to uv inside Termux.
- **`ANDROID_API_LEVEL` is mandatory** before `pip install` — `jiter` and other maturin/Rust packages need it. Symptom: opaque maturin build errors. Fix: `export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"` then retry.
- **`.[all]` is not supported.** Don't try; `voice` is unfixable on Android (no `ctranslate2` wheel). Use `.[termux]`.
- **Background gateway is best-effort.** Android aggressively suspends Termux. For a stable always-on bot, host on a VPS — phone is for "Hermes on my phone for myself" use cases, not production bots.
- **No Docker terminal backend.** `terminal.backend: local` is the only option. The agent's commands run unconfined on the phone — be careful with destructive prompts.
- **WhatsApp + browser tooling are experimental on Android.** The installer intentionally skips their bootstrap. Treat as TODO.

---

## Homebrew (macOS / Linux)

Upstream packaging lives at `packaging/homebrew/` in the openclaw-agent repo. Whether the formula is in `homebrew-core` or a Nous-Research-maintained tap depends on upstream's current publishing state — check the README before assuming a tap name.

### Install (when published to a tap)

```bash
# If upstream maintains a tap (verify the tap name in the README):
brew tap nousresearch/hermes-agent
brew install hermes-agent

# Or if the formula has been merged into homebrew-core:
brew install hermes-agent

hermes version
hermes setup
```

### Why pick Homebrew over the curl installer

- Cleaner uninstall path (`brew uninstall hermes-agent`).
- Plays nicely with `brew bundle` for declarative dotfile-managed Mac setups.
- Auto-updates via `brew upgrade hermes-agent` when upstream pushes a new bottle.

The downside: Homebrew often lags upstream by hours-to-days, and the formula may not expose every optional extra. For latest-and-greatest on macOS, the curl installer or `nix profile install` are faster.

### Homebrew-specific gotchas (Hermes-only)

- **Verify the tap exists before instructing the user to add it.** Upstream's README is the source of truth — `packaging/homebrew/` in the repo only means the formula source exists, not that it's published anywhere. If `brew tap nousresearch/hermes-agent` fails, fall back to the curl installer.
- **Linuxbrew is supported but uncommon for Hermes.** Most Linux users will be on apt/dnf systems and prefer the curl installer; Homebrew on Linux is mostly used by users who already have it for other reasons.
- **No daemon registration.** Like the curl installer, `hermes gateway install` registers launchd / systemd-user separately — `brew install` alone doesn't start a service.

---

## Per-cloud / per-PaaS pointers

Hermes upstream does not ship per-cloud install guides (only model-provider integration guides for AWS Bedrock + Azure Foundry). The infra adapters under `references/infra/` provide the "where" — Hermes runs on any host that meets the Python 3.11 / Node 22 prereqs.

| Where | Adapter | How |
|---|---|---|
| AWS Lightsail / EC2 | `infra/aws/lightsail.md` or `infra/aws/ec2.md` | `runtimes/native.md` (curl installer) or `runtimes/docker.md` (compose) |
| Azure VM | `infra/azure/vm.md` | same |
| Hetzner Cloud | `infra/hetzner/cloud-cx.md` | same |
| DigitalOcean | `infra/digitalocean/droplet.md` | same |
| GCP Compute Engine | `infra/gcp/compute-engine.md` | same |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | `runtimes/native.md` (no aarch64 image — verify Python wheels) |
| Hostinger | `infra/hostinger.md` | manual install via VPS path; no Hermes-specific 1-Click |
| Raspberry Pi | `infra/raspberry-pi.md` | `runtimes/native.md` (ARM64 Pi 4/5; Python 3.11 from NodeSource-style repo) |
| BYO Linux VPS / on-prem | `infra/byo-vps.md` | same |
| localhost (macOS / Linux / WSL2) | `infra/localhost.md` | any of: native, Docker, Nix, manual dev, Homebrew |
| localhost (Android phone) | `infra/localhost.md` | Termux only |

PaaS adapters under `infra/paas/` (Fly.io, Render, Railway, Northflank, exe.dev) are not currently wired up for Hermes — upstream ships no `fly.toml` / `render.yaml` / one-click templates. Future contribution opportunity: write Hermes-specific Fly / Render configs that mirror the OpenClaw equivalents (Fly especially is a clean fit for the gateway + dashboard split).

---

## Verification before marking `provision` done

- Gateway process alive: `systemctl --user is-active hermes-gateway` (Linux native), `launchctl list | grep hermes` (macOS native), or `docker compose ps` (Docker).
- `hermes doctor` reports no missing components.
- Local probe: `curl -sI http://127.0.0.1:8642/healthz` → `200 OK` (gateway) and `curl -sI http://127.0.0.1:9119/` → `200 OK` (dashboard, if running).
- Dashboard loads in the browser (via SSH tunnel for remote hosts).
- One test message round-trips through the chosen channel — confirms model provider + messaging gateway are both reachable.

---

## Consolidated gotchas

Universal:

- **64K minimum context window.** Hermes rejects models with smaller windows at startup. Hosted Claude / GPT / Gemini / Qwen / DeepSeek all qualify; for local Ollama / llama.cpp set the context size explicitly.
- **Three independent auth boundaries.** Dashboard (no-auth, localhost-only, stores API keys), API server (off by default, `API_SERVER_KEY` mandatory if enabled), messaging gateway user authorization (default deny). Don't conflate them.
- **Default deny on messaging.** No allowlists + no `GATEWAY_ALLOW_ALL_USERS` = every inbound DM is rejected. Configure allowlists or use the DM-pairing flow before expecting messages to land.
- **`hermes setup` is interactive.** Pause autonomous mode for the wizard, or pre-stage `~/.hermes/.env` and `~/.hermes/config.yaml` and skip with `--no-onboard`-style flags (verify exact flag name in upstream `scripts/install.sh`).
- **OpenClaw migration is supported.** If the user is coming from OpenClaw, `hermes claw migrate` is the right starting point — don't reconstruct config by hand.
- **API keys are split across `.env` (secrets) and `config.yaml` (non-secrets).** Use `hermes config set <key> <value>` and let the CLI route to the right file.
- **Model costs compound.** Long agent runs can burn tokens fast. Set spend limits at the provider dashboard before first real use.

Per-method gotchas live alongside each section above:

- **Native** — see *Native-specific gotchas* + `runtimes/native.md` § *Common gotchas*.
- **Docker** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Nix** — see *Nix-specific gotchas*.
- **Manual dev** — see *Manual-dev-specific gotchas*.
- **Termux** — see *Termux-specific gotchas*.
- **Homebrew** — see *Homebrew-specific gotchas*.

---

## TODO — verify on subsequent deployments

- **Exact non-interactive flag names** in `scripts/install.sh` (assumed `HERMES_NO_PROMPT=1`, `HERMES_NO_ONBOARD=1` by analogy to OpenClaw — confirm against the actual script before relying on them in autonomous mode).
- **First end-to-end native install** on Linux + macOS — surface any `hermes doctor` warnings or PATH-after-install issues.
- **First end-to-end Docker compose deploy** — verify `network_mode: host` works on Docker Desktop (macOS / Windows) vs Linux engine.
- **NixOS module** — never exercised; verify `services.hermes-agent.enable = true` flow on a fresh NixOS rebuild, then `nixos-rebuild switch` again to confirm config preservation of user-added keys.
- **Nix container mode** — verify identity-hash recreation behavior matches docs (image change = recreate; setting change = no recreate).
- **Termux** — verify `.[termux]` install on Pixel + Samsung devices; verify `hermes pairing approve telegram <code>` works from Termux.
- **Homebrew** — verify the tap name and whether it's in `homebrew-core`. The README is the source of truth; `packaging/homebrew/` in the repo doesn't imply published.
- **Migration from OpenClaw** — exercise `hermes claw migrate --dry-run` against a real OpenClaw install + verify the per-key mapping in the migration docs is accurate.
- **PaaS templates** — investigate writing Hermes-specific `fly.toml` / `render.yaml` to extend `infra/paas/` coverage. Check if Nous Research has community-contributed deploy templates.
- **64K-context enforcement** — verify the exact failure mode when an undersized model is configured (does it fail at startup, on first message, or get auto-promoted by the model picker?).
- **Two-gateway-against-one-state-dir** corruption mode — what does it actually look like? Documented as "silent corruption" but worth seeing the failure once.
- **`hermes update` flow on each install method** — does the curl-installed binary update cleanly? Does Docker `pull && up -d` preserve all state? Nix flake update + rebuild?
