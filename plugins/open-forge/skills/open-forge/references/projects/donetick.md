---
name: Donetick
description: "Collaborative task and chore management. Natural-language task creation; adaptive scheduling learned from history; assignee rotation; photo attachments (S3/R2/MinIO). Go backend. donetick/donetick. Discord + subreddit."
---

# Donetick

Donetick is **"Todoist + a chore-wheel — for families + roommates + teams"** — open-source collaborative task + chore manager. **Natural-language input**: "Change water filter every 6 months" → auto-extracts dates + recurrence. **Adaptive scheduling** — learns from when you actually complete recurring tasks. **Assignee rotation** — auto-distribute (round-robin, least-completed, random). **Subtasks** with smart reset on recurring tasks. **Photo attachments** (S3, R2, MinIO, local). **Time tracking + session insights**.

Built + maintained by **donetick/donetick** org. Active CI; Discord community; Reddit subreddit. Go backend (implied by `go-release.yml` workflow).

Use cases: (a) **family chore-wheel** — auto-rotated (b) **roommate-task-assignment** — fair distribution (c) **maintenance-task-tracker** — water filters, oil changes (d) **solo productivity** — Todoist-replacement (e) **small-team task-sharing** (f) **kid-allowance chore-tracker** (g) **with-photo-proof chore-completion** (h) **time-tracked household work**.

Features (per README):

- **Collaborative** — solo, group, share, assign
- **Natural-language** task input
- **Adaptive scheduling** from completion history
- **Due-date vs completion-date** recurrence choice
- **Assignee rotation** (3 modes)
- **Time tracking + sessions**
- **Subtasks with smart reset**
- **Labels + priorities** (P1-P4)
- **Photo attachments** (S3-compat)

- Upstream repo: <https://github.com/donetick/donetick>
- Discord: <https://discord.gg/6hSH6F33q7>
- Subreddit: <https://www.reddit.com/r/donetick>

## Architecture in one minute

- **Go** backend
- **SQLite or Postgres** likely (check compose)
- **Optional S3-compatible storage** for photos
- **Resource**: low
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`donetick/donetick`**                                         | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tasks.example.com`                                         | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Group/family setup   | Optional                                                    | Social       |                                                                                    |
| S3 credentials       | Only if photo-feature                                       | Integration  | Object storage keys                                                                                    |

## Install via Docker

```yaml
services:
  donetick:
    image: donetick/donetick:latest        # **pin version**
    ports: ["2021:2021"]
    volumes:
      - ./donetick-data:/data
    environment:
      DT_JWT_SECRET: ${JWT_SECRET}
    restart: unless-stopped
```

## First boot

1. Start
2. Create admin account
3. Create group (for family/team)
4. Invite members
5. Create first natural-language task: "Take out trash every Monday at 6pm"
6. Verify parsed correctly
7. Configure S3 (if using photos)
8. Put behind TLS

## Data & config layout

- `/data/` — SQLite DB + config

## Backup

```sh
sudo tar czf donetick-$(date +%F).tgz donetick-data/
# Photos if using S3: back up S3 bucket separately
```

## Upgrade

1. Releases: <https://github.com/donetick/donetick/releases>. Active.
2. Docker pull + restart
3. SQLite migrations auto

## Gotchas

- **138th HUB-OF-CREDENTIALS Tier 2 — FAMILY-SCHEDULE-AGGREGATOR**:
  - Family routines, chore-rotation, completion-patterns
  - Links family-members
  - Photo evidence of tasks (possibly identifying photos of homes, kids)
  - S3 credentials if photo-feature used
  - **138th tool in hub-of-credentials family — Tier 2**
- **NATURAL-LANGUAGE-PARSER-SECURITY**:
  - NL parser is local (no cloud LLM shown)
  - But could grow with "AI features" later
  - **Recipe convention: "natural-language-parser-vendor-independence positive-signal"**
  - **NEW positive-signal convention** (Donetick 1st formally)
- **ADAPTIVE-SCHEDULING-LEARNS-HABITS**:
  - Models when YOU actually complete tasks
  - Behavior-fingerprinting of users
  - Mostly benign but data-rich
  - **Recipe convention: "behavioral-learning-system neutral-signal"**
  - **NEW neutral-signal convention** (Donetick 1st formally)
- **PHOTO-ATTACHMENTS-OF-HOMES**:
  - Chore-completion photos may show interior, kids, valuables
  - **Recipe convention: "user-uploaded-photos-PII-risk callout"**
  - **NEW recipe convention** (Donetick 1st formally)
- **ASSIGNEE-ROTATION-FAIRNESS**:
  - Round-robin + least-completed + random
  - "Fair" algorithmically
  - **Recipe convention: "algorithmic-fairness-chore-distribution positive-signal"**
  - **NEW positive-signal convention** (Donetick 1st formally)
- **JWT-SECRET-ROTATION**:
  - **JWT-secret-rotation-discipline: 2 tools** (ByteStash+Donetick) 🎯 **2-TOOL MILESTONE**
- **S3-COMPATIBLE-STORAGE-INTEGRATION**:
  - 4 backends supported (AWS, R2, MinIO, others)
  - User-provided credentials
  - **Object-storage-native-architecture: 2 tools** (Parseable+Donetick) 🎯 **2-TOOL MILESTONE**
- **LOCAL-STORAGE-WIP**:
  - README notes local is WIP
  - Rely on S3 for production
  - **Recipe convention: "local-storage-WIP-use-S3 callout"**
  - **NEW recipe convention** (Donetick 1st formally)
- **MULTI-COMMUNITY-CHANNELS**:
  - Discord + subreddit
  - **Multi-community-channel-presence: 1 tool** 🎯 **NEW family** (Donetick)
- **INSTITUTIONAL-STEWARDSHIP**: donetick org + Discord + subreddit + CI + Go-release + Docker Hub + active. **124th tool — org-with-Discord-and-subreddit sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + Discord + subreddit + screenshots + releases. **130th tool 🎯 130-TOOL MILESTONE in transparent-maintenance family**.
- **TASK/CHORE-MANAGER-CATEGORY:**
  - **Donetick** — family-chores; rotation; natural-language
  - **Vikunja** — general-purpose; Kanban
  - **Tasks.md** — markdown-based; files-first
  - **Grocy** — household-management (chores + inventory + more)
  - **Nextcloud Tasks** — NC-ecosystem
- **ALTERNATIVES WORTH KNOWING:**
  - **Grocy** — if you also want groceries + inventory
  - **Vikunja** — if you want general Kanban
  - **Choose Donetick if:** you want family-chores + natural-language + rotation.
- **PROJECT HEALTH**: active + Discord + subreddit + CI + Go + S3-support. Strong.

## Links

- Repo: <https://github.com/donetick/donetick>
- Discord: <https://discord.gg/6hSH6F33q7>
- Grocy (alt): <https://github.com/grocy/grocy>
- Vikunja (alt): <https://kolaente.dev/vikunja/vikunja>
- Tasks.md (alt): <https://github.com/BaldissaraMatheus/Tasks.md>
