---
name: onionshare
description: OnionShare recipe for open-forge. Desktop + CLI tool for anonymous file sharing, website hosting, and chat over Tor. Not a persistent server — creates ephemeral .onion services on demand. Upstream: https://onionshare.org
---

# OnionShare

Open-source tool to securely and anonymously share files, host websites, and chat using the Tor network. Runs on the user's machine and creates a temporary .onion address for the duration of a session.

6,941 stars · GPL-3.0

Upstream: https://github.com/onionshare/onionshare
Website: https://onionshare.org
Docs: https://docs.onionshare.org/

**Important**: OnionShare is a **desktop/CLI application**, not a persistently-hosted server. It starts a Tor onion service on demand. Recipients must use Tor Browser or a Tor-configured application to access shared content.

## What it is

OnionShare provides four modes:

- **Share files** — Generate a .onion URL; anyone with it and Tor Browser can download
- **Receive files** — Others can upload files to you anonymously via Tor
- **Host a website** — Serve a static site as a .onion site
- **Chat** — Anonymous, serverless group chat over Tor (no account, no server logs)

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Desktop app installer | Windows, macOS | Download from https://onionshare.org — bundles Tor |
| Homebrew cask | macOS | `brew install --cask onionshare` |
| Flatpak | Linux | Recommended desktop install on Linux |
| Snap | Linux | Alternative Linux install |
| .deb package | Debian/Ubuntu | From https://onionshare.org/install.html |
| Python CLI (`onionshare-cli`) | All platforms | Headless / server use |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| mode | "Share files, receive files, host a website, or chat?" | CLI usage |
| persistence | "Use a persistent .onion address across sessions?" | Optional — `--persistent` flag |
| path | "What file or directory to share?" | Share / website modes |

## Desktop install

### Windows and macOS

Download the installer from https://onionshare.org. Bundles Tor — no separate Tor install required.

### macOS (Homebrew)

    brew install --cask onionshare

### Linux (Flatpak — recommended)

    flatpak install flathub org.onionshare.OnionShare

### Linux (Snap)

    snap install onionshare

### Linux (.deb)

Follow instructions at https://docs.onionshare.org/2.6/en/install.html#linux

## CLI install and usage

    pip install onionshare-cli

On Linux, the CLI requires `tor` installed separately (the desktop app bundles it but the CLI does not):

    # Debian/Ubuntu
    apt install tor

### CLI usage

    # Share a file or directory
    onionshare /path/to/file.txt
    onionshare /path/to/directory/

    # Receive files anonymously (others upload to you)
    onionshare --receive

    # Host a static website
    onionshare --website /path/to/website/

    # Anonymous chat
    onionshare --chat

    # Persistent .onion address (same URL on next run)
    onionshare --persistent /path/to/private.key /path/to/file.txt

OnionShare prints the .onion URL when it starts. Share this URL with recipients out-of-band (Signal, email, etc.).

## How it works

1. OnionShare starts a local HTTP server on a random port
2. It connects to the Tor network and registers a v3 onion service pointing to that port
3. Recipients access the .onion URL via Tor Browser
4. When you close OnionShare, the onion service is destroyed (unless `--persistent`)

## Gotchas

- **Tor Browser required for recipients** — the .onion URL is only accessible via Tor Browser or an app configured to use Tor (e.g. torsocks). Regular browsers cannot open .onion addresses.
- **Not a persistent server** — OnionShare runs only while the app is open. For always-on sharing, you need a real server with Tor hidden service configured manually.
- **CLI needs separate Tor** — `onionshare-cli` does not bundle Tor. Install `tor` via your package manager and ensure the tor service is running.
- **Slow speeds** — Tor's multi-hop routing means transfers are significantly slower than direct connections. Not suitable for large files when speed matters.
- **Persistent addresses** — Use `--persistent` with a saved private key file to reuse the same .onion URL. Without it, a new address is generated each run.
- **Low recent activity** — Commit activity in 2025–2026 is low (project appears maintenance-mode). v2.6.3 released February 2025.
- **Tor Browser version** — Ensure recipients use an up-to-date Tor Browser that supports v3 onion addresses (all versions from ~2020 onward do).

## Links

- GitHub: https://github.com/onionshare/onionshare
- Website: https://onionshare.org
- Docs: https://docs.onionshare.org/
- Install guide: https://docs.onionshare.org/2.6/en/install.html
- Tor Browser (for recipients): https://www.torproject.org/download/
