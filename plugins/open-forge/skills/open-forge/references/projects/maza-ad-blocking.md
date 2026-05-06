---
name: maza-ad-blocking
description: Maza ad blocking recipe for open-forge. Covers using the local hosts-file ad blocker bash script. Upstream: https://github.com/tanrax/maza-ad-blocking
---

# Maza ad blocking

Local hosts-file ad blocker — like Pi-hole but on your own machine, requiring no browser extensions or separate hardware. A pure bash script that blocks ads in all browsers and applications by updating `/etc/hosts` with known ad/tracking domains. Compatible with macOS, Linux, BSD, and WSL. Upstream: <https://github.com/tanrax/maza-ad-blocking>.

**License:** Apache-2.0

> **Note:** Maza is a **local machine tool**, not a server application. It modifies `/etc/hosts` on the machine it runs on. For network-wide ad blocking, consider Pi-hole or AdGuard Home instead.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `curl` one-liner to `/usr/local/bin` | https://github.com/tanrax/maza-ad-blocking#install-or-update | ✅ | All platforms; simplest method |

## Requirements

| Requirement | macOS | Linux/BSD/WSL |
|---|---|---|
| bash 4.0+ | `brew install bash` | Usually pre-installed |
| curl | Pre-installed | Pre-installed |
| gsed (GNU sed) | `brew install gnu-sed` | Not needed (uses native sed) |

## Installation

```bash
curl -o maza https://raw.githubusercontent.com/tanrax/maza-ad-blocking/master/maza \
  && sudo rm -rf /usr/local/bin/maza \
  && chmod +x maza \
  && sudo mv maza /usr/local/bin
```

Verify install:
```bash
maza --version
```

## Usage

| Command | Action |
|---|---|
| `sudo maza update` | Download/refresh the blocklist of ad/tracking domains |
| `sudo maza start` | Enable blocking (applies entries to `/etc/hosts`) |
| `sudo maza stop` | Disable blocking (removes entries from `/etc/hosts`) |
| `sudo maza status` | Show current state (enabled/disabled) |

**Typical workflow:**
```bash
sudo maza update   # run weekly to refresh blocklists
sudo maza start    # enable blocking
```

## Automation

Auto-update the block list weekly via cron:

```cron
@weekly sudo maza update && sudo maza start
```

## Blocking custom domains

Add entries to `/etc/hosts.maza.custom`:
```
0.0.0.0 tracker.example.com
0.0.0.0 ads.example.com
```

Maza merges custom entries with the downloaded list when you run `maza start`.

## Whitelist (unblock specific domains)

Add domains to the whitelist file at `~/.config/maza/whitelist`:
```
example-ad-network.com
```

## Alternative blocklists

By default, Maza uses the StevenBlack hosts list. To use a different list, edit `~/.config/maza/config`:
```
BLOCKLIST_URL=https://example.com/hosts
```

## dnsmasq (wildcard/subdomain blocking)

For wildcard subdomain blocking (e.g. `*.ads.example.com`), use Maza with dnsmasq:

```bash
# Install dnsmasq (macOS)
brew install dnsmasq

# Generate dnsmasq blocklist
sudo maza update --dnsmasq
```

This lets Maza function like a Pi-hole server on the local machine — add the machine's IP as the DNS server on your router to block ads network-wide.

## Software-layer concerns

### Key files

| Path | Purpose |
|---|---|
| `/etc/hosts` | Modified by Maza to add/remove block entries |
| `~/.config/maza/` | Configuration directory |
| `~/.config/maza/config` | Blocklist URL, dnsmasq settings |
| `~/.config/maza/whitelist` | Domains to never block |
| `/etc/hosts.maza.custom` | Custom domains to always block |

## Upgrade procedure

```bash
# Re-run the install one-liner to overwrite the current binary
curl -o maza https://raw.githubusercontent.com/tanrax/maza-ad-blocking/master/maza \
  && sudo rm -rf /usr/local/bin/maza \
  && chmod +x maza \
  && sudo mv maza /usr/local/bin
```

## Gotchas

- **Local machine only.** Maza only blocks ads on the machine it's installed on. It does not provide network-wide blocking.
- **Requires root/sudo.** Writing to `/etc/hosts` requires elevated privileges.
- **macOS: bash 4.0+** The macOS default bash is 3.x (due to GPL licensing). Install `bash` via Homebrew and update the shebang or invoke explicitly.
- **macOS: gsed required.** GNU sed behaves differently from BSD sed. Install with `brew install gnu-sed`.
- **dnsmasq for wildcard blocking.** Standard `/etc/hosts` does not support wildcards. Use the dnsmasq integration for subdomain blocking.
- **DNS cache.** After `maza start/stop`, flush your OS DNS cache for changes to take effect immediately (e.g. `sudo dscacheutil -flushcache` on macOS, `sudo systemctl restart systemd-resolved` on Linux).

## Upstream docs

- GitHub README: https://github.com/tanrax/maza-ad-blocking
- Hacker News discussion: https://news.ycombinator.com/item?id=22717650
