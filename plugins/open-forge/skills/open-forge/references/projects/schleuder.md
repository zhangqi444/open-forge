---
name: schleuder-project
description: Schleuder recipe for open-forge. GPG-encrypted mailing list manager (Ruby gem) for secure group communication. Covers gem install and Debian package install. Based on upstream README at https://0xacab.org/schleuder/schleuder and docs at https://schleuder.org/docs/.
---

# Schleuder

GPG-enabled mailing list manager that lets subscribers communicate end-to-end encrypted (and pseudonymously) among themselves, receive emails from non-subscribers, and send emails to non-subscribers via the list. Intended for activist groups, journalists, and anyone requiring confidential group email. GPL-3.0. Upstream: https://0xacab.org/schleuder/schleuder. Docs: https://schleuder.org/docs/.

Note: The project is actively seeking additional maintainers. Existing functionality is stable; new feature development is slow.

## Compatible install methods

| Method | Platform | When to use |
|---|---|---|
| Ruby gem | Any Linux/Unix | Standard install; works on most distributions |
| Debian/CentOS/Arch package | Debian buster, CentOS 7, Archlinux | Simplest; packages handle dependencies |

Optional companion: schleuder-web — a web UI for list management (separate install; https://0xacab.org/schleuder/schleuder-web).

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "Email domain for lists?" | FQDN (e.g. example.org) | Lists will be created as list@example.org |
| config | "MTA in use?" | Postfix / Exim / other | Schleuder integrates as a transport in Postfix or via alias pipe |
| config | "API superadmin email?" | email | For schleuder-web or CLI management |
| config | "API superadmin password?" | Free-text (sensitive) | schleuder-web API auth |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Ruby >= 2.7 |
| GPG | gnupg >= 2.2, gpgme |
| Database | SQLite3 (default) |
| Dependencies | openssl, icu, libcurl, ruby-bundler |
| Config file | /etc/schleuder/schleuder.yml |
| API | Built-in Sinatra REST API for schleuder-web integration |
| MTA integration | Runs as a transport; Postfix pipe or alias delivery |
| Current stable | v5.0.1 |
| Entropy | Recommend running haveged to prevent blocking during GPG key generation |

## Install: Ruby gem

Source: https://0xacab.org/schleuder/schleuder/-/blob/main/README.md

### 1. Install system dependencies (Debian/Ubuntu example)

```bash
sudo apt install autoconf g++ gcc libsqlite3-dev libssl-dev libxml2-dev \
  libz-dev make ruby-bundler ruby-dev ruby-rubygems gnupg2 haveged
```

### 2. Download and verify the gem

```bash
# Download gem and signature
wget https://schleuder.org/download/schleuder-5.0.1.gem
wget https://schleuder.org/download/schleuder-5.0.1.gem.sig

# Verify signature
gpg --recv-key 0xB3D190D5235C74E1907EACFE898F2C91E2E6E1F3
gpg --verify schleuder-5.0.1.gem.sig
```

### 3. Install the gem

```bash
gem install schleuder-5.0.1.gem
```

### 4. Set up Schleuder

```bash
schleuder install
```

This creates required directories and copies example configs. Follow any permission instructions shown.

### 5. Configure

Edit /etc/schleuder/schleuder.yml to set:
- superadmin email and password
- MTA connection settings
- API settings (for schleuder-web)

Full config reference: https://schleuder.org/schleuder/docs/server-admins.html

### 6. MTA integration (Postfix example)

Add to /etc/postfix/master.cf:
```
schleuder unix - n n - - pipe
  flags=DRhu user=schleuder argv=/usr/local/bin/schleuder-filter ${recipient}
```

Refer to https://schleuder.org/schleuder/docs/server-admins.html for full MTA setup.

## Install: Debian package

Source: https://schleuder.org/schleuder/docs/server-admins.html#installation

Packages are available for Debian buster, CentOS 7, and Archlinux:

```bash
# Debian
echo "deb https://packages.riseup.net/debian buster main" | sudo tee /etc/apt/sources.list.d/schleuder.list
# (Add GPG key per docs)
sudo apt-get update && sudo apt-get install schleuder
```

See installation docs for current package repo URLs and GPG key: https://schleuder.org/schleuder/docs/server-admins.html#installation

## Creating and managing lists

```bash
# Create a new list
schleuder-cli lists new <list@example.org> <admin@example.org> <admin-key-fingerprint>

# Subscribe a member
schleuder-cli subscriptions add <list@example.org> <member@example.org> <member-gpg-fingerprint>

# Check keys expiring / unusable across all lists
schleuder check_keys
```

Full CLI reference: `schleuder help`

## Upgrade procedure

Download the new gem from https://schleuder.org/download/, verify the signature, then:

```bash
gem install schleuder-X.Y.Z.gem
schleuder upgrade-db   # run DB migrations
```

Check the changelog for breaking changes before upgrading.

## Gotchas

- GPG key management is central: Every subscriber needs a GPG key. Managing key expiry across members is the main operational burden.
- haveged is strongly recommended: Schleuder can block during key generation if the system runs low on entropy. Install and start haveged.
- MTA setup is non-trivial: Postfix or Exim must be correctly configured to pipe mail through Schleuder. Follow the server-admin docs closely.
- Seeking maintainers: The project is stable but has reduced maintenance bandwidth. Check https://0xacab.org/schleuder/schleuder/-/issues/540 for current status.
- schleuder-web is a separate install: The web UI is optional and installed independently from https://0xacab.org/schleuder/schleuder-web.
- check_keys cron: Run `schleuder check_keys` regularly (e.g. weekly) to notify list admins of expiring subscriber keys.

## Links

- Upstream repo: https://0xacab.org/schleuder/schleuder
- Docs: https://schleuder.org/docs/
- Server admin guide: https://schleuder.org/schleuder/docs/server-admins.html
- Download: https://schleuder.org/download/
- schleuder-web (optional UI): https://0xacab.org/schleuder/schleuder-web
- Maintainers wanted: https://0xacab.org/schleuder/schleuder/-/issues/540
