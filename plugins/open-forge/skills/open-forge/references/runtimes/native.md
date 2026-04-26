---
name: native-runtime
description: Cross-cutting runtime module for native (non-containerized) deployments. Loaded whenever the user picks the native installer / curl-pipe-bash / package-manager / PowerShell-installer / local-prefix path on any infra (Lightsail Ubuntu, EC2, Hetzner, DO, GCP, BYO VPS, Raspberry Pi, localhost — Linux/macOS/Windows). Owns OS prereqs, daemon lifecycle (systemd / launchd / Scheduled Tasks), reverse-proxy guidance, and common gotchas. Project recipes own their own installer command, config paths, and app-specific service unit.
---

# Native runtime

Reusable across every Linux / macOS / Windows host where the project ships a native installer (no container). The project recipe specifies *what* to run (installer URL, config paths, the service unit's exact `ExecStart`); this module specifies *how* — install OS prereqs, manage the daemon's lifecycle, set up a reverse proxy, troubleshoot common native-install issues.

## When this module is loaded

User answered the **how** question with anything native:

- "Lightsail Ubuntu + native installer", "EC2 + native", "Hetzner CX + native"
- "BYO VPS + native"
- "localhost + native" (macOS, Linux, Windows-via-WSL2, or native Windows PowerShell)
- "Raspberry Pi + native"

Skipped when the runtime is bundled by the infra (e.g. Lightsail vendor blueprint) or when the user picked Docker / Podman / Kubernetes.

## Three installer modes

Most projects with a `curl | bash` story actually ship *three* installer scripts — pick the right one:

| Mode | Platform | When to use |
|---|---|---|
| **Global** (`install.sh`) | macOS / Linux / WSL2 | Default — installs Node + project globally via npm. Good for single-user VPS or laptop where you can write to `/usr/local/`. |
| **Local prefix** (`install-cli.sh`) | macOS / Linux / WSL2 | No root. Installs Node + project under `~/.openclaw` (or a custom `--prefix`). Good for shared hosts, CI, restricted environments, or running multiple versions side-by-side. |
| **Windows PowerShell** (`install.ps1`) | Native Windows (PS 5+) | Installs Node via winget/Chocolatey/Scoop; project via npm. Also works inside WSL2 but Linux installer is preferred there. |

Project recipes name the URLs explicitly (e.g. `https://openclaw.ai/install.sh`, `https://openclaw.ai/install-cli.sh`, `https://openclaw.ai/install.ps1`); this module describes the surrounding host concerns.

## Host requirements

- **Linux**: kernel ≥ 4.x, systemd (for daemon supervision), `curl`, `bash`, Node 22+ (most installers fetch a pinned Node themselves). ARM and x86_64 both supported by most upstream installers; verify with the project's matrix.
- **macOS** (only valid for `infra/localhost.md`): Homebrew preinstalled by the user; `launchd` is built-in for autostart. Apple Silicon and Intel both supported by most installers.
- **Windows**: PowerShell 5+; native install via `install.ps1`, or run inside WSL2 (which acts like Linux). Daemon autostart on native Windows uses **Scheduled Tasks** (the installer creates them); no systemd.
- **Disk**: ≥ 5 GB free for global installs; ≥ 1 GB for local-prefix mode.
- **RAM**: project-dependent. Native runs lighter than Docker because no container overhead.

## Install OS prereqs

The installer scripts most projects ship (`curl … | bash`) assume `curl`, `tar`, and a C/C++ toolchain are present. Install once before running the project installer:

### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates build-essential
```

### RHEL / Fedora / Amazon Linux

```bash
sudo dnf install -y curl ca-certificates @development-tools
# or older: sudo yum groupinstall -y 'Development Tools'
```

### Alpine

```bash
sudo apk add --no-cache curl ca-certificates build-base
```

### macOS

```bash
xcode-select --install        # one-time; installs Apple's CLI tools (clang, make, …)
# Homebrew should already be installed; if not: https://brew.sh
```

### Windows (native, no WSL)

PowerShell 5+ is bundled with Windows 10/11. Most native-Windows installers will install Node via one of these (in order of preference):

```powershell
# winget — built into Windows 11 and recent 10
winget install OpenJS.NodeJS.LTS

# Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iwr https://community.chocolatey.org/install.ps1 -useb | iex
choco install nodejs-lts -y

# Scoop
iwr -useb get.scoop.sh | iex
scoop install nodejs-lts
```

The project's `install.ps1` typically tries `winget` → `chocolatey` → `scoop` automatically. Git for Windows is also required if the installer falls back to a git checkout — install ahead of time: `winget install Git.Git`.

### Windows (WSL2)

Inside WSL2, follow the Debian/Ubuntu path above — WSL2 looks like Linux to installers. The `install.sh` script is preferred over `install.ps1` from inside WSL.

Project recipes will list any **additional** prereqs (e.g. `python3`, `imagemagick`, `ffmpeg`). Install those with the matching package manager — never fall back to `pip`/`npm` global installs without the user's approval.

## Run the project installer

Project recipes own the exact command. Generic patterns:

```bash
# Global curl | bash (most common — macOS / Linux / WSL2)
curl -fsSL --proto '=https' --tlsv1.2 https://<project>.example/install.sh | bash

# Local prefix (no root; installs to ~/.<project>/ or --prefix <path>)
curl -fsSL --proto '=https' --tlsv1.2 https://<project>.example/install-cli.sh | bash
# or pin a custom prefix:
curl -fsSL --proto '=https' --tlsv1.2 https://<project>.example/install-cli.sh | bash -s -- --prefix /opt/<project>

# Native Windows (PowerShell 5+)
iwr -useb https://<project>.example/install.ps1 | iex
# or with flags:
& ([scriptblock]::Create((iwr -useb https://<project>.example/install.ps1))) -NoOnboard

# Package manager
sudo apt-get install -y <project>          # Debian/Ubuntu
brew install <project>                     # macOS

# Binary release
curl -fsSL -o /tmp/<project> https://github.com/<org>/<project>/releases/latest/download/<project>-linux-x86_64
sudo install -m 0755 /tmp/<project> /usr/local/bin/<project>
```

Always announce in one sentence before piping a remote script to a shell. Some users want to inspect first — offer `curl -fsSL <url> -o /tmp/install.sh && less /tmp/install.sh` (or PowerShell's `iwr -useb <url> -OutFile install.ps1; Get-Content install.ps1 | more`) as an alternative.

Common non-interactive flags (most upstream installers support):

| Flag | Effect |
|---|---|
| `--no-onboard` / `-NoOnboard` / `OPENCLAW_NO_ONBOARD=1` | Skip the post-install setup wizard (useful in autonomous flows where Claude pre-stages config) |
| `--no-prompt` / `OPENCLAW_NO_PROMPT=1` | Disable any interactive prompts during install |
| `--dry-run` / `-DryRun` | Print actions without applying — confirm before committing |
| `--install-method git\|npm` | Pick installation source (npm registry vs git checkout) |
| `--version <ver>` | Pin a specific version, dist-tag, or git ref |

## Daemon lifecycle

Most projects ship a service unit. Three flavors:

### systemd (Linux)

System-wide unit (root-owned, starts at boot regardless of user login):

```bash
sudo systemctl status <project>
sudo systemctl start <project>
sudo systemctl stop <project>
sudo systemctl restart <project>
sudo systemctl enable <project>      # autostart on boot
sudo journalctl -u <project> -f      # live logs
```

User unit (runs as the logged-in user; needs `loginctl enable-linger` for no-login persistence):

```bash
systemctl --user status <project>
systemctl --user restart <project>
journalctl --user -u <project> -f

# One-time, so the user unit survives no-login sessions:
sudo loginctl enable-linger "$USER"
```

User units are common when the project's data lives under `$HOME` and root isn't needed. The Lightsail OpenClaw blueprint uses this pattern.

### launchd (macOS)

```bash
launchctl load -w ~/Library/LaunchAgents/<project>.plist     # enable + start
launchctl unload ~/Library/LaunchAgents/<project>.plist      # stop + disable
launchctl list | grep <project>                              # status
```

Logs go to wherever the plist's `StandardOutPath` / `StandardErrorPath` point — usually `~/Library/Logs/<project>.log`.

### Scheduled Tasks (native Windows)

Most Windows installers create a Scheduled Task that runs at user login. Manage with PowerShell:

```powershell
Get-ScheduledTask -TaskName "<project>*"
Start-ScheduledTask -TaskName "<project>"
Stop-ScheduledTask -TaskName "<project>"
Disable-ScheduledTask -TaskName "<project>"

# Logs (if the project writes to event log)
Get-WinEvent -LogName Application -MaxEvents 50 | Where-Object { $_.ProviderName -like "*<project>*" }
```

For projects that don't auto-create a task, manual creation:

```powershell
$action = New-ScheduledTaskAction -Execute "C:\Path\To\<project>.exe" -Argument "gateway run"
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName "<project>" -Action $action -Trigger $trigger -RunLevel Limited
```

Native Windows has no exact systemd-linger equivalent — Scheduled Tasks tied to user login require the user to log in at least once after reboot. For true headless persistence, run inside WSL2 with `loginctl enable-linger`, or run the project as a Windows Service via `nssm` / `sc.exe` (project recipe specific).

### Foreground (no daemon)

Some installers don't ship a unit. Run the binary in a `tmux` / `screen` session as a stopgap, then offer to write a unit file. Don't leave the user with "open a terminal and remember to keep it running" as the long-term answer.

## Reverse proxy (when public-facing)

Native installs typically bind to `127.0.0.1:<port>`. For public reach you need a reverse proxy that terminates TLS and forwards to the local port. Choices:

| Proxy | Why pick it |
|---|---|
| **Caddy** | Easiest TLS — automatic Let's Encrypt with no config. Single binary. Recommended default. |
| **nginx** | Ubiquitous, well-documented, more knobs. Requires `certbot` for TLS. |
| **Apache** | Default on some vendor blueprints (Lightsail OpenClaw, Bitnami). Already in place — don't rip out. |

Generic Caddy setup (Linux):

```bash
sudo apt-get install -y caddy   # Debian/Ubuntu via Caddy's apt repo; see https://caddyserver.com/docs/install
sudo tee /etc/caddy/Caddyfile <<EOF
<domain> {
  reverse_proxy 127.0.0.1:<port>
}
EOF
sudo systemctl reload caddy
```

Caddy fetches the cert on first request to `<domain>`. Make sure the DNS A record points at the host first.

For nginx + certbot, see `references/modules/tls-letsencrypt.md`. For Apache (Bitnami / Lightsail OpenClaw), the blueprint's vhost is already wired — use `certbot --apache` to swap the snakeoil cert for a real one.

## Upgrades

Project-specific. Generic patterns:

```bash
# curl | bash installers — re-running picks up the latest version
curl -fsSL https://<project>.example/install.sh | bash

# package manager
sudo apt-get update && sudo apt-get install -y --only-upgrade <project>
brew upgrade <project>

# binary release — replace the binary, then restart the service
sudo install -m 0755 /tmp/<project>-new /usr/local/bin/<project>
sudo systemctl restart <project>
```

Always restart the service after a binary swap. Persistent state under `$HOME` / `/var/lib/<project>` / `/etc/<project>` survives upgrades.

## Firewall

Native services typically listen on `127.0.0.1:<port>` and need a reverse proxy on `:80` / `:443`. Open those at the *infra* layer (Lightsail firewall, Hetzner Cloud Firewall, `ufw`, etc.). Don't open the project's app port (`18789`, `2368`, …) directly to the internet — bypassing the proxy bypasses TLS.

For host-level firewall on a BYO VPS without provider firewall:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'      # opens 80 + 443
sudo ufw enable
```

## Common gotchas

- **PATH not refreshed after install.** Many installers drop a binary in `~/.local/bin` or `/usr/local/bin` and rely on shell rc to pick it up. After install, run `exec $SHELL -l` (or open a new shell) before invoking the binary. Symptom: `command not found` immediately after a successful install. On Windows, `npm config get prefix` shows where the global binary lives — add that directory to user PATH and reopen PowerShell.
- **Node / Python version pinning.** Installers that bundle a runtime (Node 22, Python 3.11) often pin a specific version. If the user has `nvm` / `pyenv` / a system Node, the wrong one can shadow the bundled one after `exec $SHELL -l`. Verify with `which <runtime> && <runtime> --version` and `<project> --version`. Mitigations: project-specific shims, asdf, or `update-alternatives`.
- **systemd user unit dies on reboot without linger.** `systemctl --user enable <project>` alone doesn't survive logout. Pair with `sudo loginctl enable-linger "$USER"` once.
- **`sudo` doesn't inherit user DBUS.** Symptoms like `Failed to connect to bus: No medium found` when running `sudo systemctl --user …` or any command that talks to the user's DBUS — run as the unprivileged user instead, or `sudo -i -u <user>` to get a full login env.
- **Reboot loses the running daemon, not the data.** Config and state under `$HOME` / `/var/lib/<project>` survive. The service comes back only if `enable`d (and lingered, for user units). Verify after a deliberate reboot, not just right after install.
- **No automatic TLS** — unlike vendor blueprints (Lightsail) or tunnels (Cloudflare/Tailscale), bare native installs don't ship with a cert. Pair with `references/modules/tls-letsencrypt.md` (or Caddy, which automates it).
- **Permissions on `/usr/local/bin`** — on some macOS installs, `/usr/local/bin` isn't writable without `sudo`. Homebrew handles this; manual `install -m 0755` may need `sudo`.
- **Local-prefix mode + global mode collide.** If the user installed once with `install.sh` (global) and again with `install-cli.sh` (local prefix), there are now two binaries on PATH and the wrong one wins depending on shell rc order. Either uninstall the old one or alias the prefix binary explicitly.
- **WSL2 vs native Windows path confusion.** A WSL2 install lives in the Linux filesystem and isn't visible to native PowerShell, and vice versa. Pick one and stick with it; if the user is on Windows, ask which they want before running an installer.
- **Windows: `iwr | iex` errors are non-fatal to the shell.** A failure in the piped script reports a terminating error but doesn't close the PowerShell window. Always check `$?` or look for an explicit success line — silent partial installs happen.
- **`SHARP_IGNORE_GLOBAL_LIBVIPS=1`** is the installer default to avoid building Sharp against system libvips. If a project legitimately needs system libvips, override with `SHARP_IGNORE_GLOBAL_LIBVIPS=0` before running the installer.

## Reference

- systemd service docs: <https://www.freedesktop.org/software/systemd/man/systemd.service.html>
- launchd docs (macOS): <https://www.launchd.info/>
- Windows Scheduled Tasks: <https://learn.microsoft.com/en-us/windows/win32/taskschd/task-scheduler-start-page>
- Caddy: <https://caddyserver.com/docs/>
