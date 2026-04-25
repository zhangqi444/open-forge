---
name: localhost-infra
description: Run on the user's own machine — laptop, desktop, home server. Claude executes commands directly via Bash (no SSH). Default upstream path for many self-hosted projects (OpenClaw's `curl | bash` installer is designed for local; a hobby Ghost can run on a Mac). For public reach, pair with `modules/tunnels.md`.
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

- **Does not provision anything.** The user's machine already exists.
- **Does not install Docker / Docker Desktop.** Too disruptive to push silently. If the chosen runtime is Docker and Docker is missing, Claude offers to open the Docker Desktop / colima / OrbStack download page and waits for the user to install + restart their shell.
- **Does not modify firewall rules autonomously.** macOS / Windows firewalls block inbound by default; if a tunnel is needed, that's the path (see *Public reach*), not opening firewall ports.

## OS-specific package managers

Claude uses these for any prereq install (jq, curl, etc.):

| OS | Manager | Install template |
|---|---|---|
| macOS | Homebrew (`brew`) | `brew install <pkg>` |
| Linux (Debian/Ubuntu) | apt | `sudo apt-get install -y <pkg>` |
| Linux (Fedora/RHEL) | dnf | `sudo dnf install -y <pkg>` |
| Linux (Arch) | pacman | `sudo pacman -S --noconfirm <pkg>` |
| Windows (WSL) | apt inside WSL | same as Debian/Ubuntu |
| Windows (native) | winget / scoop | `winget install <pkg>` or `scoop install <pkg>` |

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

Different from cloud: the user is also using their machine. Be considerate:

- Don't run `pnpm install` / Docker builds when the user mentioned battery / heat / "I'm in a meeting".
- If the project keeps a daemon running (OpenClaw gateway, Plex), tell the user it'll consume RAM/CPU continuously and ask whether to launch on login.
- Project config dirs survive reboots; running daemons don't. For "always running" set up the OS's native autostart (launchd on macOS, systemd user units on Linux, Task Scheduler on Windows). Project recipe owns the unit/plist file shape.

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

## Hand-off lines for the user

When set-up completes, give the user a clear "what's running, where, how to access it" summary:

```
✅ <Project> is running on your <OS>.
- Access: http://localhost:<port>
- Config: <path>
- To stop: <command>
- To start again after reboot: <command>  [or — autostart configured]
```

Match the project recipe's outputs to this template.
