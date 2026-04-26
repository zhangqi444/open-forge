---
name: native-runtime
description: Cross-cutting runtime module for native (non-containerized) deployments. Loaded whenever the user picks the native installer / curl-pipe-bash / package-manager path on any infra (Lightsail Ubuntu, EC2, Hetzner, DO, GCP, BYO VPS, localhost). Owns OS prereqs, daemon lifecycle, reverse-proxy guidance, and common gotchas. Project recipes own their own installer command, config paths, and app-specific service unit.
---

# Native runtime

Reusable across every Linux/macOS host where the project ships a native installer (no container). The project recipe specifies *what* to run (installer URL, config paths, the service unit's exact `ExecStart`); this module specifies *how* — install OS prereqs, manage the daemon's lifecycle, set up a reverse proxy, troubleshoot common native-install issues.

## When this module is loaded

User answered the **how** question with anything native:

- "Lightsail Ubuntu + native installer", "EC2 + native", "Hetzner CX + native"
- "BYO VPS + native"
- "localhost + native" (macOS / Linux home directory install)

Skipped when the runtime is bundled by the infra (e.g. Lightsail vendor blueprint) or when the user picked Docker.

## Host requirements

- **Linux**: kernel ≥ 4.x, systemd (for daemon supervision), `curl`, `bash`. ARM and x86_64 both supported by most upstream installers; verify with the project's matrix.
- **macOS** (only valid for `infra/localhost.md`): Homebrew preinstalled by the user; `launchd` is built-in for autostart.
- **Windows** (only valid for `infra/localhost.md`): native installs are project-by-project; many projects only ship Linux/macOS native and recommend WSL or Docker on Windows.
- **Disk**: ≥ 5 GB free for most native installs (much smaller than Docker-based — no image cache).
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

Project recipes will list any **additional** prereqs (e.g. `nodejs`, `python3`, `imagemagick`). Install those with the matching package manager — never fall back to `pip`/`npm` global installs without the user's approval.

## Run the project installer

Project recipes own the exact command. Generic patterns:

```bash
# curl | bash (most common)
curl -fsSL https://<project>.example/install.sh | bash

# package manager
sudo apt-get install -y <project>          # Debian/Ubuntu
brew install <project>                     # macOS

# binary release
curl -fsSL -o /tmp/<project> https://github.com/<org>/<project>/releases/latest/download/<project>-linux-x86_64
sudo install -m 0755 /tmp/<project> /usr/local/bin/<project>
```

Always announce in one sentence before piping a remote script to a shell. Some users want to inspect first — offer `curl -fsSL <url> -o /tmp/install.sh && less /tmp/install.sh` as an alternative.

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

- **PATH not refreshed after install.** Many installers drop a binary in `~/.local/bin` or `/usr/local/bin` and rely on shell rc to pick it up. After install, run `exec $SHELL -l` (or open a new shell) before invoking the binary. Symptom: `command not found` immediately after a successful install.
- **Node / Python version pinning.** Installers that bundle a runtime (Node 22, Python 3.11) often pin a specific version. If the user has `nvm` / `pyenv` / a system Node, the wrong one can shadow the bundled one after `exec $SHELL -l`. Verify with `which <runtime> && <runtime> --version` and `<project> --version`. Mitigations: project-specific shims, asdf, or `update-alternatives`.
- **systemd user unit dies on reboot without linger.** `systemctl --user enable <project>` alone doesn't survive logout. Pair with `sudo loginctl enable-linger "$USER"` once.
- **`sudo` doesn't inherit user DBUS.** Symptoms like `Failed to connect to bus: No medium found` when running `sudo systemctl --user …` or any command that talks to the user's DBUS — run as the unprivileged user instead, or `sudo -i -u <user>` to get a full login env.
- **Reboot loses the running daemon, not the data.** Config and state under `$HOME` / `/var/lib/<project>` survive. The service comes back only if `enable`d (and lingered, for user units). Verify after a deliberate reboot, not just right after install.
- **No automatic TLS** — unlike vendor blueprints (Lightsail) or tunnels (Cloudflare/Tailscale), bare native installs don't ship with a cert. Pair with `references/modules/tls-letsencrypt.md` (or Caddy, which automates it).
- **Permissions on `/usr/local/bin`** — on some macOS installs, `/usr/local/bin` isn't writable without `sudo`. Homebrew handles this; manual `install -m 0755` may need `sudo`.

## Reference

- systemd service docs: <https://www.freedesktop.org/software/systemd/man/systemd.service.html>
- launchd docs (macOS): <https://www.launchd.info/>
- Caddy: <https://caddyserver.com/docs/>
