# pyShelf

**What it is:** Terminal-based, lightweight self-hosted ebook server. No X server required — runs as a headless systemd service. Recursively scans your ebook library, aggregates cover images, and serves a web UI with fuzzy search (by title, author, or tag), download support, and automated collections based on folder structure.

**GitHub:** https://github.com/th3r00t/pyShelf  
**Supported formats:** epub, mobi

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | systemd service | Installed via curl install script |
| Any Linux VPS/VM | Manual | Python + Node.js stack |

> No Docker image maintained by the project — bare metal / systemd deployment only.

---

## Prerequisites

- `git`
- `curl`

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/th3r00t/pyShelf/refs/heads/master/install.sh | sudo bash
```

Installs as a systemd service, enabled by default.

---

## Service Management

```bash
systemctl start pyShelf
systemctl restart pyshelf
systemctl stop pyshelf
```

---

## Software-Layer Concerns

- **No X server required** — fully headless; scans and serves without a display
- **Folder-based collections** — book collections are derived automatically from directory structure
- **Formats supported:** epub, mobi
- **Fuzzy search specifiers:**
  - `tag:fiction`
  - `author:Clancy`
  - `title:"The Hunt for Red October"`
  - or just a plain search term like `The Expanse`

---

## Upgrade Procedure

1. Pull latest source: `git pull` in the installation directory
2. Restart service: `systemctl restart pyshelf`

---

## Gotchas

- **No Docker image** — must be installed directly on a Linux host via the install script
- Only epub and mobi formats supported — PDF, CBZ, and other formats are not supported
- The install script requires `sudo` — review before running in production
- Web UI designed for desktop and mobile; screenshots show a card-based grid layout

---

## Links

- GitHub: https://github.com/th3r00t/pyShelf
- Discord: https://discord.gg/H9TbNJS
