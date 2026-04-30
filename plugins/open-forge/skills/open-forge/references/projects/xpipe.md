---
name: XPipe
description: Desktop connection hub for SSH, Docker, Podman, Kubernetes, VMware, Proxmox, RDP, VNC, Tailscale, and ~20 other infrastructure types. NOT a self-hostable server — it's a fat desktop client (Windows/macOS/Linux) that talks directly to your existing tools. Proprietary freemium + MIT core.
---

# XPipe

XPipe is a **desktop application**, not a server. It's the "IDE for your infrastructure" — a JavaFX-based Windows/macOS/Linux GUI that integrates with your locally-installed command-line tools (SSH, docker, kubectl, etc.) and presents a unified graph of everything you can connect to: servers via SSH, containers via Docker/Podman, VMs via Proxmox/KVM/VMware, remote desktops via RDP/VNC, tunneled networks via Tailscale/Netbird/Teleport.

Listed in selfh.st for being self-managed (your credentials stay local, no cloud), but **you don't "install it on a VM"** — you run it on your workstation. There's no Docker image, no systemd service, no web UI. This is an honest pivot recipe.

- Upstream repo: <https://github.com/xpipe-io/xpipe>
- Website: <https://xpipe.io>
- Docs: <https://docs.xpipe.io/>
- Installation: <https://docs.xpipe.io/guide/installation>
- Managed (team) installation: <https://docs.xpipe.io/guide/managed-installation>

## Important: XPipe is a desktop client

Upstream's own README is explicit:

> Note that this is a desktop application that should be run on your local desktop workstation, **not on any server or containers**. It will be able to connect to your server infrastructure from there.

If you're looking for a web-based SSH / VNC / terminal gateway that runs on a server, XPipe is **not it**. Alternatives that fit that bill:

- **Guacamole** — Apache's clientless HTML5 RDP/VNC/SSH gateway (browser-based)
- **Sshwifty** — web-based SSH client you self-host
- **next-terminal** — Chinese-language fortress server with audit logging, browser UI
- **Teleport** — access-plane for SSH/K8s/DB (heavy-duty; separate recipe)

This recipe documents how to install XPipe locally, because that's the actual upstream-supported path.

## Compatible install methods

| Platform | Method                                                | Notes                                                               |
| -------- | ----------------------------------------------------- | ------------------------------------------------------------------- |
| Windows  | `.msi` installer (x86-64 or ARM64)                   | Auto-updates; from <https://github.com/xpipe-io/xpipe/releases>     |
| Windows  | Portable `.zip`                                       | No installer, no auto-update                                         |
| Windows  | `choco install xpipe` / `winget install xpipe-io.xpipe` / `scoop install extras/xpipe` | Package managers  |
| macOS    | `.pkg` installer (x86-64 or ARM64)                    | Auto-updates                                                         |
| macOS    | `.dmg` portable                                       | No auto-update                                                       |
| macOS    | `brew install --cask xpipe-io/tap/xpipe`              | Homebrew                                                             |
| Linux    | `bash <(curl -sL https://github.com/xpipe-io/xpipe/raw/master/get-xpipe.sh)` | Autodetects apt/dnf/yum/zypper/rpm/pacman + signs repo |
| Linux    | `.deb` (amd64/arm64)                                  | `sudo apt install <file>` (NOT `dpkg -i`; needs dependency resolution) |
| Linux    | `.rpm` (amd64/arm64)                                  | Signed with `crschnick.asc`                                          |
| Linux    | AUR (`yay -S xpipe`)                                  | Arch                                                                 |
| Docker   | ❌ **Not supported**                                 | Upstream explicitly warns against                                    |
| Server   | ❌ **Not intended**                                  | JavaFX GUI needs a display                                           |

## Editions

| Edition      | Price             | Notes                                                                                 |
| ------------ | ----------------- | ------------------------------------------------------------------------------------- |
| Community    | Free              | Most features; MIT license for the core                                               |
| Professional | $8/mo per user (check upstream for current pricing) | Advanced features (custom identities, team sync, audit) |
| Enterprise   | Contact sales     | SSO, central config, support                                                          |

## Install on Windows

```powershell
# Via winget (simplest)
winget install xpipe-io.xpipe --source winget

# Or chocolatey
choco install xpipe
```

MSI installer: download from <https://github.com/xpipe-io/xpipe/releases/latest>.

## Install on macOS

```sh
# Via Homebrew tap
brew install --cask xpipe-io/tap/xpipe

# Or download the .pkg from releases and double-click
```

## Install on Linux

```sh
# Autodetect-everything installer (recommended)
bash <(curl -sL https://github.com/xpipe-io/xpipe/raw/master/get-xpipe.sh)

# Debian / Ubuntu manually
wget https://github.com/xpipe-io/xpipe/releases/latest/download/xpipe-installer-linux-x86_64.deb
sudo apt install ./xpipe-installer-linux-x86_64.deb

# Fedora / RHEL
rpm --import https://xpipe.io/signatures/crschnick.asc
sudo dnf install https://github.com/xpipe-io/xpipe/releases/latest/download/xpipe-installer-linux-x86_64.rpm
```

### Linux caveats

- Needs a working display server (X11 or Wayland + XWayland). Headless Linux = won't launch.
- Fonts: uses system fonts — on minimal servers, falls back to square boxes.
- Hardware acceleration via OpenGL; WSL users should prefer Windows native installer.

## Managed / Enterprise install

For team deployments (central provisioning, shared identity store):

<https://docs.xpipe.io/guide/managed-installation>

- **XPipe Git Sync** — share connection definitions via a private git repo
- **XPipe Daemon** — headless mode for scripted operations (background daemon for CLI use)
- **XPipe CLI** — `xpipe` command-line for scripting (`xpipe run-script <connection> <script>`)

The daemon/CLI IS installable headlessly — but it's a helper for the desktop app, not a standalone server.

## Data & config layout

Per-user:

- **Linux**: `~/.xpipe/` — connections (encrypted), settings, cache
- **macOS**: `~/Library/Application Support/io.xpipe.app/`
- **Windows**: `%APPDATA%\xpipe\`

Connections can optionally sync via git repo (Professional feature).

## Backup

```sh
# Linux
tar czf xpipe-$(date +%F).tgz ~/.xpipe/

# macOS
tar czf xpipe-$(date +%F).tgz ~/Library/Application\ Support/io.xpipe.app/
```

Connection credentials are encrypted with a machine-bound key — restoring on a different machine requires re-entering credentials. Use the Git Sync feature (paid) for portable connection definitions.

## Upgrade

1. Releases: <https://github.com/xpipe-io/xpipe/releases>.
2. Installer versions auto-update by default (opt-in prompt on launch).
3. Portable / package-manager versions: update via the package manager (`winget upgrade xpipe`, `brew upgrade`, `apt upgrade`).
4. No DB / schema migrations to worry about.
5. Major releases occasionally change config schema; XPipe migrates on first launch.

## Gotchas

- **NOT a self-hostable server.** If you added XPipe to a server-provisioning recipe, you're doing it wrong. Run on your workstation; have XPipe connect to your servers.
- **Requires a graphical display.** No headless Linux. WSL needs a Linux GUI layer (WSLg / X server on Windows).
- **Proprietary closed-core with open-source components.** The repo mixes Apache-2.0-licensed subprojects with a proprietary shell. Do not assume "on GitHub" = "fully FOSS". Check `LICENSE` per module.
- **Credentials are stored locally.** No central server by design — credentials are encrypted with a machine key. Losing your machine = losing the connection library (unless you opted into git-sync).
- **Paid-tier features are gated at runtime.** Professional license unlocks features that silently stop working if your subscription lapses.
- **Telemetry is opt-in** per upstream. Check privacy settings.
- **Java runtime is bundled.** Installer is ~200 MB because it ships a JRE. Saves you from "install Java first" pain but image is large.
- **Linux installer runs under the user account**, not system-wide. Systemd user-unit for the XPipe daemon is an option for users who want it auto-starting.
- **RDP / VNC sessions** open external clients (xfreerdp, TigerVNC Viewer) — you need those installed separately on your workstation.
- **Kubernetes support** requires `kubectl` on your workstation. XPipe doesn't ship its own kubectl.
- **Tailscale / Netbird / Teleport** support requires those clients installed and logged in locally. XPipe is a UI over their CLIs.
- **If you need a web-based SSH gateway** for shared team access with audit logs, look at:
  - **Apache Guacamole** — HTML5 RDP/VNC/SSH, truly browser-based, self-hosted
  - **Teleport** — access-plane with SSO, RBAC, audit logs
  - **Sshwifty** — lightweight browser SSH
- **Git Sync feature** (Professional) turns a private git repo into a connection library — effectively makes your connection database portable across devices. This is the closest thing XPipe has to "server-hosted state".
- **XPipe CLI + Daemon** enables some server-side scripted use cases (`xpipe --daemon` + `xpipe connection list`), but requires a display session on the daemon host if any GUI prompts occur (identity confirmations, etc.). Headless-only daemon use is limited.

## Links

- Repo: <https://github.com/xpipe-io/xpipe>
- Website: <https://xpipe.io>
- Docs: <https://docs.xpipe.io/>
- Installation: <https://docs.xpipe.io/guide/installation>
- Managed / team installation: <https://docs.xpipe.io/guide/managed-installation>
- CLI docs: <https://docs.xpipe.io/guide/cli>
- Releases: <https://github.com/xpipe-io/xpipe/releases>
- Homebrew tap: <https://github.com/xpipe-io/homebrew-tap>
- Pricing: <https://xpipe.io/pricing>
- Alternative (web SSH gateway): Guacamole <https://guacamole.apache.org/>
- Alternative (access plane): Teleport <https://goteleport.com/>
- Alternative (lightweight web SSH): Sshwifty <https://github.com/nirui/sshwifty>
