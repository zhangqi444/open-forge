---
name: Jotty
description: "Self-hosted checklists + notes app. Formerly rwMarkable. Client-side encryption option. Discord + Reddit + Telegram communities. fccview/jotty. jotty.page."
---

# Jotty

Jotty (formerly **rwMarkable**) is **"Keep / Todoist — but self-hosted + simple + optionally encrypted"** — a lightweight alternative for managing personal checklists + notes. Easy to deploy. Data stays on your server. Client-side encrypt/decrypt-able.

Built + maintained by **fccview**. Former name rwMarkable. jotty.page website. Multi-community: Discord + Reddit (r/jotty) + Telegram. Docker-deployable. MIT likely.

Use cases: (a) **personal checklists** (b) **quick notes** (c) **family shared checklists** (d) **secret notes with client-side encryption** (e) **self-hosted Keep alternative** (f) **minimal-setup note-taking** (g) **lightweight task management** (h) **homelab scratch-pad**.

Features (per README):

- **Checklists + notes**
- **Self-hosted**
- **Client-side encrypt/decrypt** for privacy
- **Easy deploy**
- **Multi-community** (Discord + Reddit + Telegram)

- Upstream repo: <https://github.com/fccview/jotty>
- Website: <https://jotty.page>
- Discord: <https://discord.gg/invite/mMuk2WzVZu>
- Reddit: <https://www.reddit.com/r/jotty>
- Telegram: <https://t.me/jottypage>

## Architecture in one minute

- Node.js + Next.js likely
- SQLite typical
- Client-side encryption available
- **Resource**: low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `jotty.example.com`                                         | URL          | TLS                                                                                    |
| Admin user/pass      | Bootstrap                                                   | Auth         |                                                                                    |
| Storage              | Notes + checklists                                          | Storage      |                                                                                    |

## Install via Docker

Per jotty.page. Typical pattern:
```yaml
services:
  jotty:
    image: fccview/jotty:latest        # **pin**
    ports: ["3000:3000"]
    volumes:
      - ./jotty-data:/data
    restart: unless-stopped
```

## First boot

1. Start
2. Create admin
3. Try: create checklist, add items
4. Try: create note, toggle client-side-encrypt
5. **Remember encryption-password**  — lost-password = lost-data
6. Put behind TLS
7. Back up `/data`

## Data & config layout

- `/data/` — SQLite + configs

## Backup

```sh
sudo tar czf jotty-$(date +%F).tgz jotty-data/
# Client-side-encrypted notes are safe in backup
```

## Upgrade

1. Releases: <https://github.com/fccview/jotty/releases>
2. Docker pull + restart

## Gotchas

- **181st HUB-OF-CREDENTIALS Tier 3 — PERSONAL-NOTES**:
  - Holds: user notes + checklists, auth creds
  - Client-side-encryption available = server-stores-ciphertext mode (like Enclosed)
  - **181st tool in hub-of-credentials family — Tier 3**
- **CLIENT-SIDE-ENCRYPTION-OPTIONAL**:
  - Users can toggle E2E per-note
  - Lost-passphrase = lost-data
  - **Recipe convention: "optional-client-side-encryption-passphrase-discipline callout"**
  - **NEW recipe convention** (Jotty 1st formally)
- **RENAMED-FROM-RWMARKABLE**:
  - Former name in README
  - **Recipe convention: "project-rebrand-legacy-repo-URL"** — reinforces Obico (125)
- **TRIPLE-COMMUNITY (Discord + Reddit + Telegram)**:
  - **Multi-community-channel-presence: 4 tools** (Donetick+Open Archiver+Manyfold+Jotty) 🎯 **4-TOOL MILESTONE**
  - **Telegram-community-channel: 1 tool** 🎯 **NEW FAMILY** (Jotty — distinct from Matrix/Discord/IRC)
  - **Reddit-community-channel: 2 tools** (Swing Music+Jotty) 🎯 **2-TOOL MILESTONE**
- **DOMAIN-AS-BRAND (jotty.page)**:
  - .page TLD as brand
  - **Recipe convention: "dot-page-TLD-branding neutral-signal"**
  - **NEW neutral-signal convention** (Jotty 1st formally)
- **MARKDOWN-KNOWLEDGE-BASE META-FAMILY**:
  - **Markdown-knowledge-base META-FAMILY: 7 tools** (+Jotty) 🎯 **7-TOOL MILESTONE** (continuing Tasks.md family)
- **INSTITUTIONAL-STEWARDSHIP**: fccview + website + triple-community + Docker. **167th tool — multi-channel-sole-dev-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + triple-community + releases + Docker. **173rd tool in transparent-maintenance family.**
- **NOTES-CHECKLIST-CATEGORY:**
  - **Jotty** — simple; client-side-encrypt; triple-community
  - **Joplin** — mature; Evernote-alternative
  - **Memos** — micro-blog + notes
  - **AppFlowy** — Notion-alternative
  - **Trilium / TriliumNext** — hierarchical knowledge base
  - **Vikunja** — task-management heavy
- **ALTERNATIVES WORTH KNOWING:**
  - **Joplin** — if you want mature + E2E + sync
  - **Memos** — if you want micro-blog
  - **AppFlowy** — if you want Notion-replacement
  - **Choose Jotty if:** you want simple + lightweight + optional-encrypt + multi-community.
- **PROJECT HEALTH**: active + multi-community + website. Strong for sole-dev-ish project.

## Links

- Repo: <https://github.com/fccview/jotty>
- Website: <https://jotty.page>
- Joplin (alt): <https://github.com/laurent22/joplin>
- Memos (alt): <https://github.com/usememos/memos>
