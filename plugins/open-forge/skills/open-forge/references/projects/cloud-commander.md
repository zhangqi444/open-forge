---
name: Cloud Commander
description: "File manager for web with console and editor. Node.js. Gitter. Codacy. coderaiser. Patreon-sponsored. Long-running (v19+). MIT likely. Norton Commander-style two-panel UI."
---

# Cloud Commander

Cloud Commander is **"Total Commander / Midnight Commander — in the browser"** — a web-based file manager with integrated console + editor. Two-panel UI (Norton Commander-style). Works as a web-accessible file-manager for remote servers without exposing shell. Has a demo site.

Built + maintained by **coderaiser** (sole; long-running — v19.15+). License: check (MIT likely). Patreon-sponsored. Gitter community. Codacy code-quality badge. CI active.

Use cases: (a) **web-file-manager for home server** — no SSH (b) **admin access to NAS without terminal** (c) **quick file edits via browser** (d) **non-technical-user file access** (e) **replace cPanel File Manager** (f) **guest server-access** (without shell) (g) **Norton-Commander-feel enjoyers** (h) **quick console-access via web**.

Features (per README):

- **Two-panel file manager**
- **Web console** (shell-in-browser)
- **File editor** (CodeMirror or similar)
- **Multiple themes**
- **Heroku one-click deploy** template
- **Docker + npm installable**

- Upstream repo: <https://github.com/coderaiser/cloudcmd>
- Website: <https://cloudcmd.io>
- Demo: <https://cloudcmd-zdp6.onrender.com>
- Patreon: <https://patreon.com/coderaiser>

## Architecture in one minute

- **Node.js** + Express
- **Zero database** — filesystem-backed
- **Resource**: low — <100MB
- **Port**: 8000 default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **npm**            | `npm i -g cloudcmd`                                             | **Easiest**                                                                        |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |
| **Heroku**         | Deploy button                                                                                                          | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `files.example.com`                                         | URL          | **TLS MANDATORY** + Auth                                                                                    |
| Auth creds           | Basic-auth or via config                                    | Auth         | **Not secure by default — LOCK DOWN**                                                                                    |
| Root path            | Which dir to expose                                         | Storage      | **Don't expose /**                                                                                    |
| Console access       | Toggle on/off                                               | Config       | **Console = SHELL — severe**                                                                                    |

## Install via npm

```sh
npm i cloudcmd -g
cloudcmd --root=/srv/files --auth=true --username=admin --password='StrongPass'
# Then browse to http://localhost:8000
```

## First boot

1. Install
2. **ENABLE AUTH** before starting publicly
3. **SCOPE --root** to a specific safe directory
4. **DISABLE --console** if you don't need it (or restrict)
5. Start
6. Put behind TLS reverse proxy
7. Consider additional auth layer (OAuth-proxy)

## Data & config layout

- `~/.cloudcmd.json` — config
- No DB

## Backup

No app state to back up — the files it manages are your main data.

## Upgrade

1. Releases: <https://github.com/coderaiser/cloudcmd/releases>
2. `npm i -g cloudcmd@latest`
3. Restart

## Gotchas

- **148th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — FILE-SYSTEM + SHELL-ACCESS GATEWAY**:
  - Console = shell-as-process-user
  - File manager = read/write/delete on managed root
  - Compromise = server takeover
  - **148th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "web-file-manager + shell-console-combo"** (1st — Cloud Commander; distinct — web-as-shell gateway)
  - **CROWN-JEWEL Tier 1: 47 tools / 44 sub-categories**
- **CONSOLE = SHELL = RCE-BY-DESIGN**:
  - The console feature is literal shell access
  - If you expose publicly without iron-tight auth = RCE
  - **Recipe convention: "web-console-is-RCE-by-design callout"**
  - **NEW recipe convention** (Cloud Commander 1st formally) — HIGHEST-severity
- **DEFAULT-AUTH-DISABLED**:
  - Must explicitly enable
  - Easy to forget
  - **Recipe convention: "default-auth-disabled-forget-trap callout"**
  - **NEW recipe convention** (Cloud Commander 1st formally)
- **ROOT-PATH-DISCIPLINE**:
  - Accidentally setting root=/ = full-host file access
  - **Recipe convention: "root-path-scope-discipline callout"**
  - **NEW recipe convention** (Cloud Commander 1st formally)
- **PATREON-SPONSORSHIP**:
  - Alternative to OpenCollective/Ko-Fi
  - **Patreon-sponsored: 1 tool** 🎯 **NEW FAMILY** (Cloud Commander)
- **LONG-RUNNING SOLE-MAINTAINER (v19+)**:
  - Decade+ by one person
  - Bus-factor 1
  - **Decade-plus-OSS: 7 tools** (+Cloud Commander) 🎯 **7-TOOL MILESTONE**
  - **Recipe convention: "decade-plus-sole-maintainer-dev-tool callout"** — bus-factor reminder
  - **NEW callout convention** (Cloud Commander 1st formally)
- **GITTER-LEGACY-COMMUNITY**:
  - **Gitter-legacy-community-channel: 2 tools** (Docspell+Cloud Commander) 🎯 **2-TOOL MILESTONE**
- **CODACY-CODE-QUALITY-BADGE**:
  - Third-party code-quality-score
  - **Recipe convention: "Codacy-code-quality-badge positive-signal"**
  - **NEW positive-signal convention** (Cloud Commander 1st formally)
- **HEROKU-DEPLOY-BUTTON**:
  - One-click deploy
  - **PikaPods-one-click / Heroku-deploy-button: 2 tools** (Immich Power Tools + Cloud Commander) 🎯 **2-TOOL MILESTONE**
- **NODEI-NPM-INFO-IMAGE**:
  - Classic npm-info badge
  - **Recipe convention: "npm-package-badge neutral-signal"**
- **INSTITUTIONAL-STEWARDSHIP**: coderaiser sole + v19+ (decade-proven) + Gitter + Codacy + Patreon + Heroku-deploy + demo + website + blog. **134th tool — decade-plus-sole-maintainer-dev-tool sub-tier** (NEW).
- **TRANSPARENT-MAINTENANCE**: active + CI + Codacy + Gitter + Patreon + blog + demo + v19-cadence. **140th tool 🎯 140-TOOL MILESTONE in transparent-maintenance family**.
- **WEB-FILE-MANAGER-CATEGORY:**
  - **Cloud Commander** — Norton-style; web-console
  - **FileBrowser** — modern; no-console by default
  - **nextcloud Files** — part of Nextcloud
  - **Tiny File Manager** — PHP; very simple
- **ALTERNATIVES WORTH KNOWING:**
  - **FileBrowser** — if you want modern + no-shell (safer)
  - **Nextcloud** — if you want full ecosystem
  - **Choose Cloud Commander if:** you want shell + file-manager + Norton-feel.
- **PROJECT HEALTH**: active (v19+) + decade-plus + sole-maintainer + multi-channel-community. Strong but bus-factor concerns.

## Links

- Repo: <https://github.com/coderaiser/cloudcmd>
- Website: <https://cloudcmd.io>
- Demo: <https://cloudcmd-zdp6.onrender.com>
- FileBrowser (alt): <https://github.com/filebrowser/filebrowser>
