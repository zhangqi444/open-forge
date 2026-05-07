---
name: rss2email
description: rss2email recipe for open-forge. Fetch RSS/Atom feeds and email new entries to any address. CLI tool written in Python. Supports OPML, SMTP, sendmail, and LMTP delivery. Source: https://github.com/rss2email/rss2email
---

# rss2email

Command-line tool that fetches RSS and Atom feeds and emails new entries to any email address. Simple, scriptable, and designed to run from cron. Supports OPML import, multiple delivery methods (sendmail, SMTP, LMTP), per-feed configuration, and HTML-to-text conversion. Written in Python. Archived/maintenance mode upstream as of 2025.

Upstream: <https://github.com/rss2email/rss2email>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux/macOS | Python 3.6+ | Install via pip |
| Debian/Ubuntu | .deb package | Available in distro repos |
| Fedora | .rpm package | Available in distro repos |
| NixOS | nix | Available in nixpkgs |
| Any | Docker (unofficial) | No official image; can run in any Python container |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Destination email address | Where new feed entries will be sent |
| preflight | Mail delivery method: sendmail or SMTP | sendmail requires a local MTA; SMTP uses an outbound relay |
| config (SMTP) | SMTP server and port | e.g. smtp.example.net:587 |
| config (SMTP) | SMTP username and password | If server requires auth |
| config (SMTP) | TLS/SSL required? | smtp-ssl = True for SMTPS; STARTTLS used automatically when auth enabled |
| feeds | RSS/Atom feed URLs | One or more; can also import from OPML |

## Software-layer concerns

### Config and data file locations

- Config: `~/.config/rss2email/config` (XDG) or `config` in source dir
- Data: `~/.local/share/rss2email/feeds.json` (XDG) or `feeds.json` in source dir

Both locations are created automatically on first run.

### Key config options (config file, [DEFAULT] section)

```ini
[DEFAULT]
# Destination address
to = me@example.com

# Delivery method: smtp | sendmail | lmtp
email-protocol = smtp
smtp-server = smtp.example.net:587
smtp-auth = True
smtp-username = username@example.com
smtp-password = yourpassword
# smtp-ssl = True   # uncomment for SMTPS (port 465)

# From address (used in envelope)
from = rss2email@example.com

# Send HTML email (True) or plain text (False)
html-mail = False

# Date format for subject
date-header-format = %a, %d %b %Y %H:%M:%S
```

## Install

```bash
# Via pip (recommended)
pip install rss2email

# Or on Debian/Ubuntu
sudo apt install rss2email

# Verify
r2e --version
```

## Usage

```bash
# Initialize (creates config and data files)
r2e new me@example.com

# Add a feed
r2e add eff https://www.eff.org/rss/updates.xml

# First run — mark all existing entries as seen without emailing
r2e run --no-send

# Regular run — emails new entries since last run
r2e run

# List subscribed feeds
r2e list

# Remove a feed by index
r2e delete 0

# Import from OPML
r2e opmlimport my-subscriptions.opml
```

## Cron setup

```bash
# Run every hour
crontab -e
# Add:
0 * * * * r2e run 2>> ~/.local/share/rss2email/run.log
```

## Upgrade procedure

```bash
pip install --upgrade rss2email
```

Config and data files are preserved across upgrades (they live outside the package directory).

## Gotchas

- First run will see ALL existing entries as new — always run with `--no-send` on first run, then run normally afterwards.
- sendmail (or postfix/exim) must be installed and configured if using sendmail delivery. On most VPS/servers, SMTP is simpler.
- STARTTLS is used automatically when smtp-auth = True and smtp-ssl = False — no extra config needed for port 587 with STARTTLS.
- Per-feed config overrides: each feed section in the config file can override DEFAULT settings (e.g. different `to` address per feed).
- The project is in maintenance mode — no new features, but it still works reliably for its core use case.

## Links

- Upstream: https://github.com/rss2email/rss2email
- Full README: https://raw.githubusercontent.com/rss2email/rss2email/HEAD/README.rst
