---
name: localhost-infra
description: Run on the user's own machine — laptop, desktop, home server, or NAS. Claude executes commands directly via the local shell (no SSH required). Ideal for self-hosted projects (OpenClaw, Ollama, Plex, Home Assistant, Ghost). For public reach, pair with `modules/tunnels.md`.
---

# Localhost — run on the user's own machine

A first-class infra in open-forge. Many self-hosted projects are *designed* to run locally (OpenClaw, Ollama, Plex, Home Assistant); cloud is the alternative. Claude doesn't SSH anywhere — commands run in the user's local shell directly.

## When this is loaded

User picked **localhost** (or "my laptop", "my Mac", "this machine", "no cloud") at the **where** question.

## Inputs to collect

| Phase | Prompt | Tool / format | Notes |
|---|---|---|---|
| preflight | "Which OS?" | Auto-detect via `uname -s` (Darwin / Linux / MINGW or CYGWIN for Windows-via-WSL); confirm with user | Determines package manager + Docker distribution |
| preflight | "Should this be reachable from outside your local network (e.g. messaging-app webhooks, sharing a link)?" | `AskUserQuestion`: `No, local only` / `Yes — set up a tunnel` | If yes, loads `references/modules/tunnels.md` |

No SSH, no IP, no SSH key. Localhost is the simplest infra by far.

## What this adapter does NOT do

- **Does not provision infrastructure.** The user's machine already exists — no cloud VMs or remote servers are created.
- **Does not silently install Docker / Docker Desktop.** This is too disruptive. If Docker is required but missing, Claude offers to open the download page (Docker Desktop for macOS/Windows, Colima/OrbStack for macOS, or native Linux packages) and waits for installation to complete.
- **Does not modify firewall rules autonomously.** macOS / Windows / Linux firewalls block inbound connections by default. For public access, use tunneling (see *Public reach*) instead of opening firewall ports.

## OS-specific package managers

Claude uses these for any prereq install (jq, curl, etc.):

| OS | Manager | Install template |
|---|---|---|
| macOS | Homebrew (`brew`) | `brew install <pkg>` |
| Linux (Debian/Ubuntu) | apt | `sudo apt-get install -y <pkg>` |
| Linux (Fedora/RHEL) | dnf | `sudo dnf install -y <pkg>` |
| Linux (Arch) | pacman | `sudo pacman -S --noconfirm <pkg>` |
| Windows (WSL) | apt inside WSL | `sudo apt-get install -y <pkg>` |
| Windows (native) | winget (preferred) / scoop | `winget install <pkg>` or `scoop install <pkg>` |

Always `command -v <tool>` first; install only if missing AND the user confirms.

## Path conventions

| Concept | Where it usually lives |
|---|---|
| App config | `~/Library/Application Support/<app>/` (macOS), `~/.config/<app>/` (Linux), `%APPDATA%\<app>\` (Windows) |
| App state / data | `~/Library/<app>/` (macOS), `~/.local/share/<app>/` (Linux), `%LOCALAPPDATA%\<app>\` (Windows) |
| Project clone (when one is needed) | `~/<deployment-name>/` or `~/projects/<deployment-name>/` — ask user if they have a preferred dir |

Many projects don't follow XDG Base Dir spec strictly; their docs are the source of truth.

## Public reach — tunneling

Localhost is unreachable from the internet by default. For projects that need it (messaging-app webhooks, sharing a URL with friends, mobile apps that hit your laptop), use `references/modules/tunnels.md` for Cloudflare Tunnel / Tailscale Funnel / ngrok setup.

Common rule: **only set up a tunnel if the user actually needs public reach.** A locally-used chat UI doesn't.

## Resource constraints

Unlike cloud: the user shares their machine with other work. Be considerate:

- **Avoid heavy operations during busy times.** Don't run `pnpm install`, Docker builds, or large downloads if the user mentioned battery concerns, heat issues, or that they're in a meeting.
- **Warn about background daemons.** If the project keeps a daemon running (e.g., OpenClaw gateway, Plex, Home Assistant), inform the user it'll consume RAM/CPU continuously and ask whether to launch it on login.
- **Remember state persistence differences.** Project config directories survive reboots; running daemons do not. For "always running" services, configure the OS's native autostart mechanism:
  - macOS: `launchd` (plist files in `~/Library/LaunchAgents/`)
  - Linux: `systemd` user units (`systemctl --user`)
  - Windows: Task Scheduler or Startup folder
  The project recipe defines the unit/plist file format.

## Verification before marking `provision` done

- The chosen runtime is installed and healthy (`docker compose version`, or `<project> --version`).
- The project's process or container is running.
- The local URL works in a browser (`http://localhost:<port>`).

## Differences from cloud / VPS infras

| Topic | Cloud / VPS | Localhost |
|---|---|---|
| Provisioning | open-forge handles via cloud CLI | User's machine already exists |
| Command execution | Over SSH | Local Bash |
| File paths | Standard Linux (`/home/<user>`) | OS-specific |
| Firewall | Provider firewall + sometimes host firewall | OS firewall, generally untouched |
| Public reach | Static IP + DNS | Tunnel (Cloudflare Tunnel / Tailscale Funnel / ngrok) |
| Cost | Monthly VPS bill | Electricity + the user's own hardware |
| Always-on | Yes | Only when the machine is on |

## Hand-off summary for the user

When setup completes, provide a clear summary of what's running, where, and how to access it:

```
✅ <Project> is now running on your <OS> (<machine name>).

📍 Access:
   - Local:  http://localhost:<port>
   - Remote: <tunnel URL if configured>

⚙️  Configuration:
   - Config: <path>
   - Data:   <data directory path>

🔧  Management:
   - To stop:       <command>
   - To start:     <command>
   - After reboot: <command>  [or — autostart configured ✓]

📊  Resource usage:
   - Memory: <approx. RAM usage>
   - URL:    <status page if available>
```

Replace placeholders with values from the project recipe.
