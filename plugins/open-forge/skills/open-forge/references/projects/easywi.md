---
name: easywi
description: Easy-WI recipe for open-forge. Web panel for managing game servers, voice servers (TeamSpeak 3), and a lending/billing CMS. PHP + MySQL. Shell installer. GPL-3.0. Source: https://github.com/easy-wi/developer
---

# Easy-WI

Web interface for managing game server daemons, TeamSpeak 3 voice servers, and TSDNS. Includes a CMS with a fully automated game- and voice-server lending service, reseller accounts, and a REST API for WHMCS/Magento integration. Multilingual (English, German, Danish, Italian). PHP 7.4+, MySQL. Shell installer for Debian/Ubuntu. GPL-3.0 licensed.

Upstream: https://github.com/easy-wi/developer | Installer: https://github.com/easy-wi/installer | Releases: https://github.com/easy-wi/developer/releases/latest

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian 8–11 | Shell installer | Stable installer |
| Ubuntu 16–22 | Shell installer | Stable installer |
| CentOS 7 | Shell installer | Supported (CentOS 8/9 not currently supported) |
| Any | Manual (PHP + MySQL) | For custom setups |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | Root/sudo access | Installer requires sudo |
| config | Web domain/IP | URL or IP where the Easy-WI panel will be hosted |
| config | MySQL root password | Installer sets up the database |
| config | Admin credentials | Created during install |
| config (optional) | WHMCS / Magento URL | If integrating with a billing system via REST API |
| config (game servers) | Game root server SSH details | Game servers are managed via SSH/proftpd; must be configured post-install |

## Software-layer concerns

- Two-layer setup: the Easy-WI web panel runs on the management server; game/voice server daemons run on separate root servers (connected via SSH/proftpd)
- Requirements: PHP 7.4+ with extensions openssl, json, hash, ftp, SimpleXML, curl, gd, PDO, pdo_mysql; game module additionally needs sudo, cron, proftpd, bash
- Cron required: monitoring, auto-correction, and scheduled tasks depend on a cron job running on the management server
- REST API: Easy-WI exposes a REST API for integration with WHMCS, Magento, or custom billing solutions
- CentOS 8/9: currently unsupported due to WebServer ID issues; use Debian or Ubuntu

## Install -- Shell installer (recommended)

Stable installer (Debian 10/11, Ubuntu 20/21/22):

```bash
wget -O installer.tar.gz https://github.com/easy-wi/installer/archive/3.3.tar.gz
tar zxf installer.tar.gz && mv ./installer-*/easy-wi_install.sh ./
rm -r installer.tar.gz installer-*/
sudo bash ./easy-wi_install.sh
```

Developer/unstable installer (updated to JDK-17):

```bash
wget --no-check-certificate \
  https://raw.githubusercontent.com/easy-wi/installer/master/easy-wi_install.sh
sudo bash ./easy-wi_install.sh
```

The installer is interactive and guides you through web server, database, and admin setup.

## Upgrade procedure

1. Download the latest release from https://github.com/easy-wi/developer/releases/latest
2. Back up your database and config files
3. Follow the upgrade guide in the release notes
4. Re-run relevant parts of the installer or apply the provided update scripts

## Gotchas

- Separate servers for panel and game/voice daemons: Easy-WI is a management layer -- game servers run on separate machines and are registered in the panel post-install.
- CentOS 8/9 unsupported: use Debian 10/11 or Ubuntu 20/22 for the management server.
- Installer requires interactive terminal: the shell installer asks questions during setup; run it in a real TTY (not a non-interactive shell).
- proftpd required for game module: the game server root servers need proftpd installed for file transfer operations.
- JDK-17: the stable installer (3.3) uses an older JDK. Use the unstable/developer installer if you need JDK-17 support for voice server management.

## Links

- Source: https://github.com/easy-wi/developer
- Installer: https://github.com/easy-wi/installer
- Releases: https://github.com/easy-wi/developer/releases/latest
- Discord: https://discord.gg/quJvvfF
- WHMCS addon: https://github.com/easy-wi/whmcs
