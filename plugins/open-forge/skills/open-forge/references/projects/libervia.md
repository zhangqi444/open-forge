---
name: libervia
description: Libervia recipe for open-forge. Web frontend for Salut à Toi (SàT), a multi-frontend XMPP communication platform. Self-hosted web client for XMPP messaging, blog, file sharing. AGPL-3.0. Based on upstream at https://repos.goffi.org/libervia-web.
---

# Libervia

Web frontend for the Salut à Toi (SàT) XMPP communication platform. SàT is a multi-frontend XMPP application supporting messaging, blogging, file sharing, and social features. Libervia provides the browser-based interface. Built in Python (Twisted). AGPL-3.0. Upstream: https://repos.goffi.org/libervia-web. Backend: https://repos.goffi.org/libervia-backend.

## Compatible install methods

| Method | When to use |
|---|---|
| pip / source (Twisted) | Standard Python install |
| Distribution packages | Available for some distros |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| xmpp | "XMPP domain?" | FQDN | e.g. xmpp.yourdomain.com |
| xmpp | "XMPP server (Prosody/Ejabberd/etc.) already running?" | Yes/No | SàT backend connects to an XMPP server |
| config | "Libervia web port?" | Number (default 8080) | |
| network | "Domain for Libervia web frontend?" | FQDN | Proxy behind nginx/Caddy for HTTPS |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python (Twisted async framework) |
| Architecture | Libervia-web (frontend) + libervia-backend (SàT core) — two separate repos |
| Protocol | XMPP (connects to Prosody, Ejabberd, or other XMPP server) |
| Features | Messaging, blogging (XMPP PubSub), file sharing, social timeline |
| Port | 8080 (default web frontend) |
| Repos | Gitea at repos.goffi.org (behind Anubis bot protection — browser access required) |

## Install

Upstream documentation: https://repos.goffi.org/libervia-backend and https://repos.goffi.org/libervia-web

> **Note:** The upstream repos at repos.goffi.org use Anubis proof-of-work bot protection. Automated fetches (curl, scripts) are blocked. Browse to the repos directly for current install instructions.

General approach:

**1. Install the backend (libervia-backend / SàT):**

```bash
pip install sat
# or from source:
git clone https://repos.goffi.org/libervia-backend
cd libervia-backend
pip install .
```

Configure the backend to connect to your XMPP server.

**2. Install the web frontend (libervia-web):**

```bash
pip install libervia
# or from source:
git clone https://repos.goffi.org/libervia-web
cd libervia-web
pip install .
```

**3. Run:**

```bash
sat start
libervia serve
```

See upstream docs for full configuration including XMPP server setup, TLS, and port configuration.

## Upgrade procedure

```bash
pip install --upgrade sat libervia
# Restart sat and libervia services
```

## Gotchas

- Two repos required: libervia-backend (the SàT core) and libervia-web (the frontend) are separate repositories. Both must be installed and running.
- XMPP server prerequisite: Libervia connects to an XMPP server (Prosody recommended). You need a working XMPP server before Libervia is useful.
- Upstream behind Anubis: repos.goffi.org uses proof-of-work bot protection. Direct README/install-guide fetches from scripts are blocked. Use a browser.
- Twisted framework: The backend uses Twisted, a Python async framework. Some distros have older Twisted packages — using pip install from PyPI is recommended.
- Project scope: SàT/Libervia is a full XMPP application platform, not just a chat client. Installation is more involved than simpler XMPP web clients like Converse.js.

## Links

- Libervia web frontend: https://repos.goffi.org/libervia-web
- SàT backend: https://repos.goffi.org/libervia-backend
- Project website: https://www.salut-a-toi.org/
- XMPP standards: https://xmpp.org/
