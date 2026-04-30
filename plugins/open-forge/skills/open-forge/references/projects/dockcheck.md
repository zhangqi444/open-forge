---
name: dockcheck
description: "Bash CLI for Docker image update checks + automated updates + notifications. GPLv3. mag37 sole. Multiple funding. v0.7.8 active. 20+ notification plugins via Apprise. Selective updates. Image backups. No Docker Hub pull-limit for checks."
---

# dockcheck

dockcheck is **"Watchtower — but Bash + more selective + notify-only mode + 20+ notification plugins + Apprise-integrated"** — a Bash CLI to automate Docker image updates OR notify-when-updates-available. Fine-grained: include/exclude containers, image backups before update, selective updates, Apprise/notification plugins, prune-on-done. **CHECKS do NOT hit Docker Hub pull-limit** (only actual pulls do), making it production-friendly.

Built + maintained by **mag37** (sole). License: **GPL-v3**. Active (v0.7.8 recent); Ko-fi + LiberaPay + GitHub Sponsors + PayPal funding (4 venues!); Podman fork at sudo-kraken/podcheck.

Use cases: (a) **homelab update-manager** — notify before updating (b) **production manual-update workflow** — check then manually trigger (c) **watchtower-replacement** — Bash vs Go container (d) **selective updates** — some containers never auto-update (e) **image-backup discipline** — rollback if update breaks (f) **multi-notification channel** — Apprise gives 90+ integrations (g) **compose-stack-aware updates** — down+up stacks (h) **range-selection updates** — pick specific subset.

Features (per README):

- **Check-only mode** (no pull → no Docker Hub pull-limit hit)
- **Auto-update mode** (with config)
- **Include/exclude container lists**
- **Image backups before update**
- **Custom labels** to control behavior
- **Apprise integration** (90+ notification services: Slack, Discord, Telegram, email, XMPP, Matrix, etc.)
- **File-based notifications** (JSON output)
- **Pruning** after update
- **Stack-aware restarts** (down+up)
- **Selective ranges** for interactive update

- Upstream repo: <https://github.com/mag37/dockcheck>
- Podman fork: <https://github.com/sudo-kraken/podcheck>
- Funding: Ko-fi, LiberaPay, GitHub Sponsors, PayPal

## Architecture in one minute

- **Bash 4.3+** single script (~3k lines)
- **No daemon** — run on-demand or via cron
- **URL list** for image sources
- **Depends on**: `docker`, `curl`, optionally `skopeo` for deep checks

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Bash**           | `dockcheck.sh` single file                                      | **Primary**                                                                        |
| **cron**           | Schedule                                                                                                               | Common                                                                                   |
| **systemd timer**  | Alt to cron                                                                                                            | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Host                 | Docker host                                                 | Install      | Bash-ran locally or via SSH                                                                                    |
| Container policy     | Include/exclude lists                                       | Config       | Which containers dockcheck touches                                                                                    |
| Notification URLs    | Apprise-format URLs                                         | Config       | E.g., `discord://webhook-id/token`                                                                                    |
| Backup policy        | Whether to keep prior images                                | Config       |                                                                                    |
| Cron schedule        | e.g., `0 3 * * *`                                           | Schedule     | Daily check                                                                                    |

## Install

```sh
curl -L https://github.com/mag37/dockcheck/raw/main/dockcheck.sh -O
chmod +x dockcheck.sh
./dockcheck.sh -h
```

Example check-only cron:
```
0 3 * * * /path/to/dockcheck.sh -n -m 'discord://webhook-id/token'
```

(`-n` = notify only, no update)

## First boot

1. Download script; chmod
2. Run `-h` to see options
3. First run: `-n` (notify-only) to see what it finds
4. Configure Apprise URLs for notifications
5. Set cron
6. After confidence: consider `-a` (auto-update) with backup enabled (`-b`)
7. Always have image-backup on first production use

## Data & config layout

- Script is stateless — no persistent config unless you use a config file
- Backups (if enabled) — disk space grows with each update
- URL list (`urls.list`) — configurable sources

## Backup

```sh
# Image backups (if enabled) — pruning policy matters
docker image ls | grep backup
```

## Upgrade

1. Releases: <https://github.com/mag37/dockcheck/releases>. Active (v0.7.8+).
2. `curl -L ...` to fetch latest
3. Changelog in README — read before upgrade

## Gotchas

- **122nd HUB-OF-CREDENTIALS TIER 1 — HOST-ROOT (DOCKER SOCKET ACCESS)**:
  - dockcheck needs Docker socket access = host-root
  - **122nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Docker-socket-mount-privilege-escalation: 5 tools** (+dockcheck) 🎯 **5-TOOL MILESTONE**
  - Unlike containers that just need socket, dockcheck IS the mass-update-tool (can destroy all containers with one bad update)
- **AUTO-UPDATE WITHOUT REVIEW = RISKY**:
  - Automatic pulls can break apps with breaking-changes in new images
  - Best practice: notify-mode + manual trigger
  - **Recipe convention: "auto-update-without-pin-risk callout"** — universal for update-tools
  - **NEW recipe convention** (dockcheck 1st formally)
- **IMAGE-BACKUP-BEFORE-UPDATE (POSITIVE-SIGNAL)**:
  - `-b` flag keeps prior image as backup
  - Disk space trade-off but excellent rollback
  - **Recipe convention: "image-backup-before-update positive-signal"**
  - **NEW positive-signal convention** (dockcheck 1st formally)
- **NOTIFY-ONLY MODE AS DEFAULT RECOMMENDATION**:
  - Encourages humans-in-loop
  - **Recipe convention: "notify-only-mode-default-recommendation positive-signal"**
  - **NEW positive-signal convention** (dockcheck 1st formally)
- **APPRISE 90+ NOTIFICATIONS**:
  - **Apprise-multi-channel-notification: 2 tools** (Yamtrack 110 + dockcheck) 🎯 **2-TOOL MILESTONE**
- **PODMAN FORK (podcheck)**:
  - Community-maintained Podman variant
  - **Recipe convention: "Podman-companion-fork positive-signal"**
  - **NEW positive-signal convention** (dockcheck 1st formally)
- **MULTIPLE FUNDING VENUES (Ko-fi + LiberaPay + GitHub Sponsors + PayPal)**:
  - 4 funding channels — unusual breadth
  - **Multi-funding-venue-diversity: 1 tool** 🎯 **NEW MILESTONE**
  - **Recipe convention: "multi-funding-venue-diversity positive-signal"**
  - **NEW positive-signal convention** (dockcheck 1st formally — 4 venues is rare)
- **BASH 4.3+ MINIMUM**:
  - Older macOS ships Bash 3.2 — users may need brew-install
  - **Recipe convention: "bash-4-plus-required-macOS-friction" callout**
  - **NEW recipe convention** (dockcheck 1st formally)
- **GPL-v3 LICENSE**:
  - Copyleft; embeds protect the tool ecosystem
  - **Recipe convention: "GPL-v3-license positive-signal"** — standard-ish
- **DOCKER HUB PULL-LIMIT DISCIPLINE**:
  - Anonymous pulls = 100/6h; auth'd = 200/6h
  - Check-only doesn't hit it; actual-pull does
  - **Recipe convention: "Docker-Hub-pull-limit-awareness" callout**
  - **NEW recipe convention** (dockcheck 1st formally)
- **XMPP NOTIFICATION (rare)**:
  - Federated/decentralized IM
  - **Recipe convention: "XMPP-notification-decentralized positive-signal"**
  - **NEW positive-signal convention** (dockcheck 1st formally — rare)
- **RELATED TOOLS:**
  - **Watchtower** — Go; container-based; auto-update; popular
  - **Diun** — Docker-image-update-notifier; Go
  - **podcheck** (fork) — Podman-flavor dockcheck
  - **Renovate** — broader: updates code+Docker
  - **dependabot** — GitHub native
- **INSTITUTIONAL-STEWARDSHIP**: mag37 sole + 4-funding-venues + community-fork + active + changelog-detailed. **108th tool — sole-maintainer-with-multi-funding sub-tier** (NEW).
  - **NEW sub-tier: "sole-maintainer-with-multi-funding-venues"** (1st — mag37/dockcheck)
- **TRANSPARENT-MAINTENANCE**: active + detailed-changelog + v0.7.8 + 4-funding + Apprise-integration + releases. **115th tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Watchtower** — if you want container-based + hands-off
  - **Diun** — if you want just-notifications
  - **Renovate** — if you want code-integrated updates
  - **Choose dockcheck if:** you want Bash + selective + Apprise + notify-first.
- **PROJECT HEALTH**: active + detailed-changelog + 4-funding-venues + Podman-fork + community. EXCELLENT.

## Links

- Repo: <https://github.com/mag37/dockcheck>
- Podman fork: <https://github.com/sudo-kraken/podcheck>
- Watchtower (alt): <https://github.com/containrrr/watchtower>
- Diun (alt): <https://github.com/crazy-max/diun>
- Apprise: <https://github.com/caronc/apprise>
