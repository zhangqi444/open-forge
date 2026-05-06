---
name: gerrit
description: Gerrit recipe for open-forge. Code review and project management tool for Git repositories, supporting inline comments, change workflows, submit rules, and LDAP/SSO auth. Used at Google and many large open source projects. Source: https://github.com/GerritCodeReview/gerrit
---

# Gerrit

Code review and project management tool for Git-based projects. Shows changes in a side-by-side diff view with inline commenting. Manages a central Git repository where any authorized reviewer can approve and submit changes. Used at Google and by major open source projects (Android, Chromium, Eclipse). Upstream: https://github.com/GerritCodeReview/gerrit. Docs: https://gerrit-review.googlesource.com/Documentation/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (official image) | Docker | Recommended for most self-hosters. gerritcodereview/gerrit on Docker Hub. |
| WAR file (Java) | Java 17+ on Linux | Traditional install. Download gerrit.war, run java -jar gerrit.war init. |
| Kubernetes | K8s | Community Helm charts available. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Gerrit site directory?" | e.g. /srv/gerrit — all data, config, plugins stored here |
| setup | "Canonical web URL?" | e.g. https://gerrit.example.com — set as gerrit.canonicalWebUrl in gerrit.config |
| auth | "Authentication type?" | HTTP, LDAP, OpenID, OAuth2, SAML, or DEVELOPMENT_BECOME_ANY_ACCOUNT (dev only) |
| setup | "Admin user?" | First user to create and grant admin group membership |

## Software-layer concerns

### Docker (recommended)

  # Create site directory
  mkdir -p /srv/gerrit/{git,db,index,logs,etc,plugins,static,tmp}

  docker run -d \
    --name gerrit \
    -p 8080:8080 \
    -p 29418:29418 \
    -v /srv/gerrit:/var/gerrit \
    -e CANONICAL_WEB_URL=http://localhost:8080 \
    gerritcodereview/gerrit

  # Port 8080: HTTP web UI and REST API
  # Port 29418: Gerrit SSH (for git clone/push and SSH commands)

### Docker with custom gerrit.config

  # On first start, Gerrit auto-initializes /var/gerrit
  # Then edit /srv/gerrit/etc/gerrit.config and restart:

  docker restart gerrit

### Key gerrit.config settings

  [gerrit]
    basePath = git
    canonicalWebUrl = https://gerrit.example.com/

  [database]
    type = h2                    # default; use NoteDb for Gerrit 3.x (built-in)
    database = db/ReviewDB

  [auth]
    type = LDAP                  # or HTTP, OAUTH, SAML
    allowRegisterNewEmail = true

  [ldap]
    server = ldap://ldap.example.com
    accountBase = ou=users,dc=example,dc=com
    groupBase = ou=groups,dc=example,dc=com

  [httpd]
    listenUrl = http://*:8080/

  [sshd]
    listenAddress = *:29418

### WAR file install

  # Download gerrit.war from https://gerrit-releases.storage.googleapis.com/
  java -jar gerrit.war init -d /srv/gerrit
  # Interactive wizard: configure auth, database, listen addresses
  # Start:
  /srv/gerrit/bin/gerrit.sh start

### Admin setup (first run)

1. Open http://<host>:8080 — first user to sign in becomes admin
2. Go to Admin > Repositories to create your Git repos
3. Set up project ACLs in All-Projects (inherited by all repos)
4. Add SSH keys for developers: Settings > SSH Keys

### Plugin directory

Common plugins: reviewers, download-commands, delete-project, webhooks.
Place .jar files in /srv/gerrit/plugins/ and restart.

## Upgrade procedure

  docker pull gerritcodereview/gerrit
  docker stop gerrit && docker rm gerrit
  # Re-run docker run with same volume mounts
  # Gerrit runs schema migrations automatically on startup

  # Or for WAR install:
  java -jar new-gerrit.war init -d /srv/gerrit   # runs migrations interactively

## Gotchas

- **First user = admin**: whichever account signs in first becomes administrator. In DEVELOPMENT_BECOME_ANY_ACCOUNT mode (dev only), this is trivially exploitable — never use in production.
- **NoteDb (Gerrit 3.x)**: older versions used ReviewDB (H2/PostgreSQL). Gerrit 3.x uses NoteDb (stored in Git notes). No external DB needed for 3.x.
- **Git SSH on port 29418**: developers need this port for git clone/push via SSH. Open it in your firewall or remap to 22.
- **Bazel build for source**: building from source requires Bazel and takes significant time/RAM. Use the Docker image unless you're modifying Gerrit itself.
- **No built-in HTTPS**: run behind nginx/Caddy for TLS. Set canonicalWebUrl to the https:// address and configure the reverse proxy to forward headers.
- **Submit rules**: Gerrit's default workflow requires Code-Review +2 to merge. Submit rules can be customized per project using Prolog rules or submit requirements.

## References

- Upstream GitHub: https://github.com/GerritCodeReview/gerrit
- Documentation: https://gerrit-review.googlesource.com/Documentation/
- Docker Hub: https://hub.docker.com/r/gerritcodereview/gerrit
- Install guide: https://gerrit-review.googlesource.com/Documentation/install.html
- Docker install: https://gerrit-review.googlesource.com/Documentation/install-docker.html
