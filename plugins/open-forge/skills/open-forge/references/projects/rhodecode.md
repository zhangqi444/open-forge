---
name: rhodecode
description: RhodeCode recipe for open-forge. Self-hosted unified Git, Mercurial, and Subversion repository management with code review, pull requests, and LDAP/SAML auth. Deployed via rcstack (Docker-based installer). Based on upstream README at https://code.rhodecode.com/rhodecode-enterprise-ce and docs at https://docs.rhodecode.com.
---

# RhodeCode

Self-hosted unified repository management for Git, Subversion, and Mercurial. Features pull requests, code review with live chat, LDAP/ActiveDirectory/SAML 2.0/Crowd authentication, IP restrictions, SSH key management, full-text search, snippets (Gist), artifact storage, and CI/webhook integrations. Deployed via rcstack (Traefik + multi-container Docker stack). AGPL-3.0 (Community Edition). Upstream: https://code.rhodecode.com/rhodecode-enterprise-ce. Docs: https://docs.rhodecode.com.

## Compatible install methods

| Method | When to use |
|---|---|
| rcstack (Docker + Traefik, official) | Standard; recommended by upstream |
| Source / manual | Advanced; not covered in official quick-start |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Register at rhodecode.com to get installer instructions" | URL | https://rhodecode.com/download (free registration for CE) |
| config | "Domain for RhodeCode?" | FQDN | Used by Traefik for routing and TLS |
| config | "Run as which user?" | Unix username | Upstream recommends a dedicated rhodecode user with sudo for Docker |
| storage | "Data directory?" | Host path | Repositories and config stored here |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python |
| Stack | rcstack orchestrates: RhodeCode CE app, VCS server, Celery workers, Celery Beat, Traefik reverse proxy |
| Database | PostgreSQL (managed by rcstack) |
| Protocols | HTTP/HTTPS, SSH |
| Port 80/443 | Traefik handles TLS termination |
| Port 10020 | RhodeCode app (internal) |
| Auth plugins | LDAP, ActiveDirectory, SAML 2.0, Atlassian Crowd, HTTP headers, PAM, Token, OAuth |
| VCS support | Git, Mercurial, Subversion |
| Architectures | Check docs.rhodecode.com for current platform support |

## Install: rcstack (official)

Source: https://docs.rhodecode.com/5.x/rcstack/install/installation.html

**1. Register and get rcstack installer**

Register at https://rhodecode.com/download for free access to the rcstack CLI.

**2. Download rcstack and initialise**

```bash
# Run as dedicated user (recommended), e.g. rhodecode
mkdir docker-rhodecode && cd docker-rhodecode
curl -L -s -o rcstack https://dls.rhodecode.com/get-rcstack && chmod +x rcstack

# Initialise (downloads images and prompts for config)
./rcstack init
# Or as root on behalf of the rhodecode user:
# sudo -i -u rhodecode ./rcstack init
```

**3. Check status**

```bash
./rcstack status
```

Expected output shows running containers: Traefik router, RhodeCode app, VCS server, Celery workers.

**4. Access**

Navigate to http://yourdomain/ (or https:// if TLS configured). First-run wizard creates the admin account.

## Upgrade procedure

```bash
./rcstack upgrade
```

Follow https://docs.rhodecode.com for version-specific upgrade notes.

## Gotchas

- Registration required: RhodeCode CE is free but the rcstack installer requires a free account at rhodecode.com. No offline/anonymous install path is documented.
- Dedicated user recommended: Run as a non-root user (e.g. rhodecode) with sudo access for Docker. Do not run rcstack as root directly.
- Traefik is included: rcstack bundles Traefik as the reverse proxy. If you already have a reverse proxy on ports 80/443, you'll need to reconfigure to avoid port conflicts.
- Three VCS protocols, different setup: Git is the simplest; Mercurial requires hg on the server; SVN requires additional config. See https://docs.rhodecode.com for per-VCS setup.
- Dual-license: Community Edition is AGPL-3.0. Enterprise Edition (closed-source) adds additional auth plugins and support. Feature comparison at https://rhodecode.com/open-source.
- Not a GitHub drop-in: RhodeCode has a distinct UI and workflow. Plan migration carefully if moving from GitHub/GitLab.

## Links

- Source (CE): https://code.rhodecode.com/rhodecode-enterprise-ce
- Docs: https://docs.rhodecode.com
- Quick-start: https://docs.rhodecode.com/5.x/rcstack/install/installation.html
- Download / register: https://rhodecode.com/download
- Open source info: https://rhodecode.com/open-source
- Feature list: https://rhodecode.com/features
