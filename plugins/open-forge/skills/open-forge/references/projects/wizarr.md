---
name: Wizarr
description: "Automatic user-invitation system for Plex/Jellyfin/Emby/AudiobookShelf/Komga/Kavita/Romm. Time-limited invites + SSO + Overseerr/Ombi integration + Discord. Check license. Active (relaunched). wizarrrr org + community."
---

# Wizarr

Wizarr is **"Overseerr / Jellyseerr — but for INVITATIONS (not requests)"** — an automatic user-invitation + management system for your self-hosted media servers. Create a unique invite link → share → recipient is automatically added to Plex/Jellyfin/Emby/AudiobookShelf/Komga/Kavita/Romm + walked through getting set up (installing apps, linking to request systems, joining Discord). Time-limited memberships; pre/post-invite wizard steps; customizable HTML snippets.

Built + maintained by **wizarrrr org** + community. License: check LICENSE file. Active — README announces "Development Relaunched"; Discord; releases; regular updates.

Use cases: (a) **family Plex server on-boarding** — invite mom + dad; they're guided through app-install + login (b) **friends-Plex-server** — streamline onboarding of 10+ users (c) **time-limited trials** — 7-day free-trial invites that auto-expire (d) **Overseerr/Ombi hand-off** — route new users to request systems (e) **multi-media-server household** — Plex + Jellyfin + Audiobookshelf unified invites (f) **reduce "it-doesn't-work" support tickets** — guided setup (g) **Discord-community integration** — invited-user auto-Discord-invite (h) **monetization layer for paid-Plex-servers** — time-limited with payment gate (separate tool integration).

Features (per README):

- **Automatic invitations** for Plex, Jellyfin, Emby, AudiobookShelf, Komga, Kavita, Romm
- **Secure, user-friendly invitation process**
- **SSO support**
- **Multi-tiered invitation access**
- **Time-limited memberships**
- **Pre/post-invite wizard steps**
- **App setup guides** (Plex app, Jellyfin app, etc.)
- **Request system integration** — Overseerr, Ombi
- **Discord invite** support
- **Customizable HTML** snippets

- Upstream repo: <https://github.com/wizarrrr/wizarr>
- Discord: <https://discord.gg/NYxwcjCK9x>
- Releases: <https://github.com/wizarrrr/wizarr/releases>

## Architecture in one minute

- **Python + Flask** (typical)
- **SQLite** — DB
- **Resource**: low — 100-200MB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| Source             | Python typical                                                                    | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `invite.example.com`                                        | URL          | TLS recommended                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| **Plex token**       | Admin account API token                                     | **CRITICAL** | **Grants user-management over Plex**                                                                                    |
| **Jellyfin token**   | Admin API key                                               | **CRITICAL** | **Grants user-management over Jellyfin**                                                                                    |
| Emby / ABS / Komga / Kavita / Romm keys | Per-server                                                                                   | Integration  |                                                                                    |
| Overseerr / Ombi     | API keys                                                                                   | Integration  | For request-system routing                                                                                    |
| Discord webhook / bot| For Discord invites                                                                                                   | Integration  |                                                                                    |
| SMTP (optional)      | For email-based invites                                                                                                      | Email        |                                                                                                                                            |

## Install via Docker

```yaml
services:
  wizarr:
    image: ghcr.io/wizarrrr/wizarr:latest        # **pin version**
    ports: ["5690:5690"]
    volumes:
      - wizarr-data:/data/database
    environment:
      APP_URL: https://invite.example.com
    restart: unless-stopped

volumes:
  wizarr-data: {}
```

## First boot

1. Start container → browse web UI
2. Complete onboarding wizard
3. Connect Plex account → OAuth flow
4. Connect Jellyfin/Emby/etc. with API keys
5. Configure Overseerr/Ombi (if used)
6. Configure Discord integration (if used)
7. Create invite link → test with a friend
8. Set default time-limit + access tier
9. Customize post-invite wizard HTML
10. Back up DB

## Data & config layout

- `/data/database/` — SQLite DB with invites, integrations, users
- Integration tokens (Plex, Jellyfin, etc.) stored in DB

## Backup

```sh
docker compose exec wizarr sqlite3 /data/database/wizarr.db ".backup /data/database/wizarr-backup.db"
sudo tar czf wizarr-$(date +%F).tgz wizarr-data/
```

## Upgrade

1. Releases: <https://github.com/wizarrrr/wizarr/releases>. Active.
2. Docker pull + restart; migrations auto-run
3. README: development-relaunched → check CHANGELOG for changes from any dormancy period

## Gotchas

- **INTEGRATION TOKENS = MULTI-PLATFORM ADMIN ACCESS**:
  - Plex admin-token = can add/remove/manage users on your Plex server
  - Jellyfin admin-key = same for Jellyfin
  - Aggregated: Wizarr has ADMIN-equivalent access to ALL connected media servers
  - **79th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL** — for homelabs running multiple media-servers
  - **Sub-category: "media-server-orchestrator"** — tool that can admin multiple media servers aggregated
  - **NEW CROWN-JEWEL Tier 1 sub-category: "media-server-orchestrator"** — 1st tool named (Wizarr)
  - **CROWN-JEWEL Tier 1: 19 tools; 17 sub-categories**
- **INVITATION-LINK GUESSABILITY**:
  - Invite URLs must be high-entropy; short/guessable = unauthorized-access-to-media-server
  - **Recipe convention: "invitation-link-URL-entropy-requirement" callout**
  - **NEW recipe convention** (Wizarr 1st for invite-tools)
- **TIME-LIMITED MEMBERSHIPS = AUTOMATIC REMOVAL**:
  - Wizarr can auto-remove expired users
  - Test this carefully — wrong config = active users suddenly removed
  - **Recipe convention: "auto-expire-test-carefully" callout**
- **OVERSEERR/OMBI INTEGRATION = REQUEST-SYSTEM CHAIN**:
  - Wizarr routes new users to Overseerr for content-requests
  - If Overseerr-token leaks via Wizarr → attacker can submit requests (mass-import-DMCA-attack)
  - **Credential-cascading-risk pattern** (reinforces earlier)
- **DISCORD INVITE AUTOMATION**:
  - Wizarr can auto-invite to Discord
  - Discord rate-limits rules
  - If Wizarr-token/bot-token leaks → Discord-server compromise
- **TIME-LIMITED INVITES FOR TRIALS / PAID-PLEX**:
  - Some run paid Plex servers (legal gray — Plex TOS + copyright)
  - Wizarr is tool-agnostic but enables this flow
  - **Recipe convention: "commercial-use-of-self-hosted-media TOS/copyright-risk" callout**
  - **NEW recipe convention**
- **LEGAL-PLEX-LIMITATION**:
  - Plex personal/Plex Pass accounts generally limited in friend-count
  - Plex TOS may not allow large-scale sharing
  - **Recipe convention: "Plex-TOS-sharing-limits" callout** (for Plex-integrated tools)
- **"DEVELOPMENT RELAUNCHED" = PRIOR DORMANCY**:
  - README explicitly announces a relaunch
  - Signals prior period of low-activity
  - **Recipe convention: "project-relaunched-after-dormancy" callout**
  - **NEW recipe convention** — Wizarr 1st
- **UGC / INVITED USERS = VETTING**:
  - Anyone you invite has Plex/Jellyfin account on YOUR server
  - They can see all media, request new media, submit issues
  - **Vet-before-invite** — don't hand out Wizarr links publicly
- **SSO SUPPORT**:
  - Offload auth to your SSO
  - Reduces password-management
  - But: SSO trust boundary
- **INSTITUTIONAL-STEWARDSHIP**: wizarrrr org + community + Discord-engagement. **65th tool — community-project-with-discord-engagement sub-tier** — similar to "founder-with-multichannel-community-engagement" (Papermerge 103) but org-level.
- **TRANSPARENT-MAINTENANCE**: active (relaunched) + Discord + releases + multi-service-integration + customizable-HTML. **73rd tool in transparent-maintenance family.**
- **INVITE-TOOLS-CATEGORY:**
  - **Wizarr** — broadest: Plex + Jellyfin + Emby + more
  - **Jellycarr** — Jellyfin-specific
  - **Plex Access** — Plex's built-in (limited friend feature)
  - **Manual-invite workflows** — most people do this
- **ALTERNATIVES WORTH KNOWING:**
  - Plex's own "Friends" — if Plex-only + small-scale
  - Jellyfin admin UI — if Jellyfin-only + small-scale
  - **Choose Wizarr if:** you want multi-server + time-limited + guided onboarding + Discord-integration.
- **PROJECT HEALTH**: active + relaunched + Discord + releases. Signals renewed investment.

## Links

- Repo: <https://github.com/wizarrrr/wizarr>
- Discord: <https://discord.gg/NYxwcjCK9x>
- Overseerr: <https://overseerr.dev>
- Ombi: <https://ombi.io>
- Plex: <https://www.plex.tv>
- Jellyfin: <https://jellyfin.org>
- Emby: <https://emby.media>
- Audiobookshelf: <https://www.audiobookshelf.org>
