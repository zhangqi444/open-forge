---
name: Opengist
description: "Self-hosted pastebin powered by Git. Public/unlisted/private snippets, push via Git over HTTP/SSH, syntax highlighting, OAuth (GitHub/GitLab/Gitea/OIDC), likes + forks. Go. AGPL-3.0. Active + Weblate translations + Helm chart."
---

# Opengist

Opengist is **"GitHub Gist — self-hosted + Git-native + open-source"** — a self-hosted pastebin where every snippet is a Git repository. You can init/clone/pull/push snippets via Git over HTTP or SSH, edit through the web interface, fork others' snippets, revision-history-browse, add topics, embed snippets in other websites, like snippets, and discover via search. Go + SQLite (or Postgres/MySQL). Lightweight but featureful.

Built + maintained by **Thomas Micelli (thomiceli)** + community. **License: AGPL-3.0**. Active; Discord community; Weblate translations; Helm chart; Docker releases; demo at demo.opengist.io.

Use cases: (a) **GitHub Gist replacement** — own your snippet archive (b) **team snippet-sharing** — internal wiki-like code snippets with access controls (c) **syntax-highlighted paste** — anti-pastebin + enhanced (d) **Git-native workflow for snippets** — for when you want to push versions from CLI (e) **embed code in blog posts** — official support (f) **organization internal gists** with OAuth/OIDC (g) **programming-class / tutorial-teacher tool** — collect student submissions as snippets.

Features (from upstream README):

- **Public, unlisted, private** snippets
- **Init/clone/pull/push via Git over HTTP or SSH**
- **Syntax highlighting** for many languages; **Markdown + CSV support**
- **Search code** in snippets
- **Topics** (tags)
- **Embed snippets in other websites**
- **Revision history**
- **Like + Fork**
- **Download as raw or ZIP**
- **OAuth2**: GitHub, GitLab, Gitea, OIDC
- **Restrict or unrestrict anonymous access**
- **Docker + Helm chart**

- Upstream repo: <https://github.com/thomiceli/opengist>
- Homepage: <https://opengist.io>
- Docs: <https://opengist.io/docs>
- Demo: <https://demo.opengist.io>
- Discord: <https://discord.gg/9Pm3X5scZT>
- Docker: <https://github.com/thomiceli/opengist/pkgs/container/opengist>
- Translations: <https://tr.opengist.io/projects/_/opengist/>

## Architecture in one minute

- **Go** — single binary
- **SQLite** default; **Postgres / MySQL** optional
- **Git binary** — required for Git-protocol operations
- **Resource**: modest — 100-300MB RAM
- **Port 6157** default; Git SSH port (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/thomiceli/opengist`**                               | **Primary**                                                                        |
| Docker compose     | For reverse-proxy + DB                                                    | Typical                                                                                   |
| **Helm chart**     | Native k8s deployment                                                                              | **Kubernetes-friendly — rare in self-host space**                                                                                               |
| Binary release     | Go binary + systemd                                                                                   | Bare-metal                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `gist.example.com`                                          | URL          | TLS MANDATORY                                                                                    |
| DB                   | SQLite default; Postgres for scale                          | DB           | SQLite fine for most                                                                                    |
| SSH port             | For Git-push-via-SSH                                        | Network      | Separate from HTTP                                                                                    |
| Admin creds          | First-boot registration                                                                           | Bootstrap    | Strong                                                                                    |
| OIDC config          | (optional) SSO                                                                                  | SSO          | GitHub/GitLab/Gitea/OIDC                                                                                                            |
| Anonymous-access setting | Restrict or unrestrict                                                                                                     | Policy       | If public-internet, restrict                                                                                                                            |

## Install via Docker

```yaml
services:
  opengist:
    image: ghcr.io/thomiceli/opengist:1.12.2    # **pin version** (use latest stable from releases)
    container_name: opengist
    restart: unless-stopped
    ports:
      - "6157:6157"   # web
      - "2222:2222"   # Git SSH
    volumes:
      - ./opengist-data:/opengist
    environment:
      - OG_LOG_LEVEL=info
```

## First boot

1. Start → browse `http://host:6157`
2. Register admin (first registered user)
3. Create first snippet via web UI
4. Try `git clone ssh://git@host:2222/<user>/<snippet-id>` → verify SSH Git
5. Configure OAuth providers if needed
6. Set anonymous-access policy
7. Put behind TLS reverse proxy
8. Configure SSH port-forwarding if exposing Git-over-SSH
9. Back up DB + Git repos

## Data & config layout

- `opengist/` — root data dir with:
  - `repos/` — Git bare repositories (one per snippet)
  - `opengist.db` — SQLite DB (if SQLite backend)
  - `config.yml` — configuration
  - `opengist.log` — logs

## Backup

```sh
# Stop briefly for consistency
sudo tar czf opengist-$(date +%F).tgz opengist-data/
# Postgres: pg_dump separately
```

## Upgrade

1. Releases: <https://github.com/thomiceli/opengist/releases>. Active + semver.
2. Docker: pull + restart; migrations auto-run.
3. Back up BEFORE major version jumps.

## Gotchas

- **PUBLIC-SIGNUP + PUBLIC-SNIPPETS = SPAM + ABUSE VECTOR**:
  - Same pattern as Zipline 98 (file-host) + Slash 97 (URL-shortener): **public self-host tools attract spammer / scammer / malware-hoster abuse**
  - **Public gists** can host phishing HTML, crypto-scam JS, CSAM (low-likelihood but catastrophic), copyright-infringement content
  - **Domain blocklisting** threat if content scraped + flagged
  - **Mitigation**:
    - **Default to invite-only** or disable anonymous signup
    - Rate-limit snippet creation
    - Size limits per snippet
    - Manual moderation / abuse-reporting flow
    - Monitor for phishing keywords in new snippets
- **23rd tool in network-service-legal-risk family** — **"public-paste-host-illegal-content-conduit sub-family"** — related to but distinct from **public-file-upload-host** (Zipline 98) + **URL-shortener-phishing-vector** (Slash 97). Shared parent: **"public-user-generated-content-host sub-family group"** — all 3 face same operational pattern. **13th sub-family** or subsumed into a meta-family.
- **META-FAMILY PROPOSAL: "public-UGC-host-abuse-conduit-risk"** — Slash 97 + Zipline 98 + Opengist 98 all manifest the same underlying risk pattern: **any tool that accepts + redistributes user-generated content publicly** is an abuse vector. Recipe convention: flag ALL public-UGC tools with standard mitigation checklist (invite-only, rate-limit, abuse-report, anti-phishing checks).
- **GIT-OVER-SSH = LEAKS USERNAME + PUBLIC KEYS**: Opengist with Git-SSH exposes your user list + public keys to anyone enumerating. Consider:
  - Restrict SSH port via firewall if private-use
  - Or disable SSH Git in favor of HTTPS-only
- **SYNTAX HIGHLIGHTING RENDERING = XSS-ADJACENT**: rendering arbitrary code with styled HTML = historical XSS vector. Opengist uses Chroma (Go syntax highlighter) + escapes content. But custom Markdown + CSV renderers add attack surface. Keep Opengist updated + audit CSP.
- **MARKDOWN RENDERING = ADDITIONAL XSS SURFACE**: Markdown-to-HTML rendering can include JavaScript via iframes / `<script>` tags if sanitizer is permissive. Modern Opengist should sanitize but monitor for CVEs.
- **EMBEDDING SNIPPETS IN OTHER WEBSITES = CSP/IFRAME** concerns: Opengist provides embeddable widgets. Sites embedding may disagree with Opengist's CSP; ensure CORS + frame-ancestors set appropriately.
- **HUB-OF-CREDENTIALS LIGHT**: Opengist stores:
  - User accounts + SSH public keys + OAuth refresh tokens
  - Snippets (potentially sensitive: API keys, passwords, configs accidentally pasted)
  - **48th tool in hub-of-credentials family — LIGHT (but accidentally-leaked-secrets-in-snippets is a real concern)**
- **ACCIDENTAL SECRETS IN SNIPPETS**: users paste API keys, passwords, tokens in snippets + forget. **Your Opengist is a target because people think it's "just a pastebin".**
  - **Recipe convention: "accidental-secret-leak-risk" callout** — Opengist, pastebin-tools in general
  - Mitigation: git-secrets / trufflehog pre-receive hooks to reject pushed commits with detected secrets
  - Public-search indexing = secrets become discoverable
- **AGPL-3.0**: network-service-disclosure applies — modify + offer as SaaS, you must publish changes. Fine for self-host.
- **HELM CHART = K8s-NATIVE** = rare signal of engineering-maturity in self-host space. Plus sign.
- **TRANSLATIONS VIA WEBLATE** (like Kometa 95, Converse 96, KitchenOwl 96, etc.) — international-care signal.
- **TRANSPARENT-MAINTENANCE**: AGPL-3 + active + docs site + Discord + Weblate + Helm + demo + semver. **40th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Thomas Micelli (thomiceli) + community. **33rd tool in institutional-stewardship — sole-maintainer-with-community (20th tool in that class).**
- **GIT-BACKEND = SIGNATURE FEATURE**: differentiates Opengist from other pastebins. Every snippet is a real Git repo = full history, branching (advanced use), cloneable.
- **DIFF VIEW across revisions** = first-class feature (Git-powered).
- **SQLite DEFAULT + OPTIONAL POSTGRES/MYSQL**: typical Go-app pattern. Start SQLite; migrate if scale demands.
- **ALTERNATIVES WORTH KNOWING:**
  - **GitHub Gist** — commercial SaaS; free; Microsoft-owned
  - **PrivateBin** — privacy-first; client-side-encrypted; ephemeral; PHP
  - **Pastebin.com** — classic commercial; has ads
  - **Snipit** — commercial SaaS
  - **Hastebin** — minimal self-host; 0-feature (URL + paste)
  - **Bin (W3Stack)** — minimal
  - **Shadow** — Go; minimal
  - **Gitea Snippets** — Gitea has a Gist-alike built-in
  - **Gitlab Snippets** — GitLab has snippets
  - **Choose Opengist if:** you want Git-powered + full-featured + self-host + OAuth + AGPL + mature + active.
  - **Choose PrivateBin if:** you want zero-trust + client-side-encrypted + ephemeral.
  - **Choose Hastebin if:** you want bare-minimum.
  - **Choose Gitea if:** you want complete Git-hosting suite + snippets-as-bonus.
- **PROJECT HEALTH**: active + AGPL-3 + Weblate + Helm + Discord + Docker + semver + good-docs. Strong signals.

## Links

- Repo: <https://github.com/thomiceli/opengist>
- Homepage: <https://opengist.io>
- Docs: <https://opengist.io/docs>
- Demo: <https://demo.opengist.io>
- Discord: <https://discord.gg/9Pm3X5scZT>
- Docker: <https://github.com/thomiceli/opengist/pkgs/container/opengist>
- Translations: <https://tr.opengist.io/projects/_/opengist/>
- GitHub Gist (commercial alt): <https://gist.github.com>
- PrivateBin (zero-trust alt): <https://privatebin.info>
- Gitea (snippets built-in): <https://gitea.io>
- Hastebin (minimal alt): <https://github.com/toptal/haste-server>
