---
name: AzuraCast
description: "Self-hosted all-in-one web radio management suite — Icecast + Liquidsoap + admin web UI + scheduling + listener stats + SHOUTcast/Icecast/HLS streams. Beta-labeled but widely deployed. PHP + Vue. AGPL-3.0. Upstream 100% human-coded (no AI PRs accepted)."
---

# AzuraCast

AzuraCast is **"your own internet radio station in a box"** — a self-hosted web radio management suite that bundles **Icecast / SHOUTcast / Liquidsoap / MariaDB / Redis / nginx / PHP / Vue** into one installer. Upload music, build playlists, schedule time-slots, add live DJs with StreamerBlaster auth, publish stream URLs (public Icecast / HLS), embed a web player, track listener stats — all from one web admin. From an AM-FM hobbyist running a single-genre stream on a $5 VPS up to multi-station commercial + educational radio operators.

Built + maintained by **AzuraCast org** (Buster Neece + community; Ethical Source-labeled). **AGPL-3.0**. **Beta-labeled** but widely deployed in production for years; "beta" reflects upstream's caution + rapid development, not instability. Mastodon-present; transparent community.

**Upstream policy note (respected):** AzuraCast's README states **"AzuraCast is 100% human-coded. We do not accept pull requests from AI assistants, nor do we allow AI to write our own code."** This is a *contribution policy* (they control their codebase + don't want AI-generated PRs). It is NOT an anti-scraping / anti-documentation directive — they publish extensive public docs + welcome users. This recipe documents AzuraCast for operators evaluating self-hosting; any code changes upstream must come from humans per their policy.

Use cases: (a) **community / hobby internet radio** (b) **school / college radio** self-host (c) **podcast network** aggregation (d) **custom music stream** for a business / cafe / gym (e) **online DJ booth** with live-streaming support (f) **event / festival live-stream** setup.

Features (from upstream docs):

- **Stations** — multiple independent streams on one instance
- **Stream formats**: Icecast (MP3/AAC/Opus/FLAC/OGG Vorbis), SHOUTcast, HLS
- **Auto-DJ** — schedule playlists + jingles + ads
- **Liquidsoap** — scriptable audio routing (deep flexibility)
- **Live DJ streaming** — StreamerBlaster auth + scheduled slots
- **Listener analytics** — real-time + historical
- **Podcasts** — host + publish podcasts alongside live radio
- **Requests** — listener song requests (optional)
- **Centralcast mode** — sync multiple AzuraCast nodes
- **Embed player** — drop-in web player for your site
- **Remote relays** — scale streams via Icecast relays
- **SSO / admin roles** — multi-user management

- Upstream repo: <https://github.com/AzuraCast/AzuraCast>
- Homepage: <https://www.azuracast.com>
- Docs: <https://www.azuracast.com/docs>
- Installation: <https://www.azuracast.com/docs/getting-started/installation/>
- Requirements: <https://www.azuracast.com/docs/getting-started/requirements/>
- Demo: <https://demo.azuracast.com> (`demo@azuracast.com` / `demo`)
- Troubleshooting: <https://www.azuracast.com/docs/help/troubleshooting/>
- Mastodon: <https://floss.social/@AzuraCast>

## Architecture in one minute

- **PHP** (Symfony-ish) backend + **Vue** frontend
- **Liquidsoap** — the audio-routing scripting engine
- **Icecast / SHOUTcast** — stream servers
- **MariaDB + Redis** — DB + cache
- **nginx** — reverse proxy
- Delivered as a **monolithic-ish Docker stack** via installer
- **Resource**: moderate — 2GB RAM recommended; CPU depends on transcoding + listener count

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Installer script   | **`curl \| bash` per upstream docs** — sets up Docker stack    | **Upstream-primary**                                                               |
| Docker Compose     | Upstream docker-compose.yml                                               | For advanced users                                                                         |
| Ansible / Terraform | Community playbooks                                                                     | For repeatable deploys                                                                                 |
| VPS 1-click        | Some hosts offer turnkey images                                                                                 | Watch freshness                                                                                                      |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `radio.example.com`                                         | URL          | TLS required                                                                                    |
| Admin email + password | At installer                                                            | Bootstrap    | Strong password                                                                                    |
| Music library        | Upload via web UI or SFTP into data volume                                      | Content      | Disk space: plan for your music catalog                                                                                    |
| Stream port(s)       | Default Icecast 8000                                                                               | Network      | Open in firewall                                                                                                              |
| DB credentials       | Internal to stack                                                                                              | Auto        | Installer handles                                                                                                                      |
| Redis                | Internal to stack                                                                                                    | Auto        | Installer handles                                                                                                                                      |

## Install (recommended: installer script)

Per <https://www.azuracast.com/docs/getting-started/installation/>.

Typical path: `curl -sL https://raw.githubusercontent.com/AzuraCast/AzuraCast/main/docker.sh | bash` — downloads + runs the Docker-based installer. **Always read install scripts before piping to bash in production.**

Alternative: manual Docker Compose per upstream docs.

## First boot

1. Complete installer
2. Browse to domain → create first admin user
3. Create your first station: name, genre, logo, stream format
4. Upload music → build playlists → schedule rotation
5. (opt) Configure live-DJ streaming
6. Test stream with Icecast URL in VLC / browser player
7. Embed the web player on your external site
8. Back up DB + music library

## Data & config layout

- **Data volume** — music files, uploaded media, podcast episodes (LARGE over time)
- **MariaDB** — station configs, playlists, listener stats, user accounts
- **Redis** — cache + sessions
- **Liquidsoap configs** — per-station, auto-generated + manually-editable
- **Icecast configs** — per-station auth

## Backup

```sh
# Built-in backup: AzuraCast has a backup tool:
./docker.sh backup /path/to/backup.tar.gz
# Or manual mysqldump + tar of music dir
```

**Music library is the LARGE part** — deduplicate externally if you mirror a big collection.

## Upgrade

1. Releases: <https://github.com/AzuraCast/AzuraCast/releases>. Active + frequent.
2. `./docker.sh update` per upstream.
3. **Back up FIRST** for any non-patch version.
4. Upstream docs note rolling-release updates; read changelog before major upgrades.

## Gotchas

- **"Beta software" label** — upstream continues to call AzuraCast beta despite production use. This is cautious honesty, not a signal to avoid. Thousands of stations in production. Treat as "active-development with good stability + frequent updates" rather than "unstable".
- **Human-coded-contributions policy** (from README): *"AzuraCast is 100% human-coded. We do not accept pull requests from AI assistants, nor do we allow AI to write our own code."* This policy applies to CODE CONTRIBUTIONS. Operators self-hosting AzuraCast are users, not contributors. **If you want to fix a bug upstream, plan human-authored work and attribution.** This is a unique upstream stance in 2025+; respect it.
  - **Same family as "author-preference signals"**: Dockhand batch 85 (anti-scraping) ≠ AzuraCast (anti-AI-PR-contributions). Different scopes; AzuraCast explicitly keeps their docs public for users to read.
- **Music licensing = legal minefield** — same as any radio operator faces:
  - **Royalties**: streaming copyrighted music to public audiences requires licenses from PROs (SoundExchange in US, PRS/PPL in UK, SACEM in FR, GEMA in DE, JASRAC in JP, etc.). AzuraCast does NOT handle these; you do.
  - **Public radio online** = "non-interactive webcast" under DMCA § 114 (US) — specific rules on song-repeat limits + announcement requirements. Non-compliant = DMCA exposure.
  - **Podcast music** = stricter than live radio (traditionally requires sync licenses).
  - **Jurisdiction-dependent** — research YOUR local laws before broadcasting copyrighted music. **Not a tool problem — a legal problem AzuraCast doesn't prevent you from having.**
  - **Safest path**: **Creative-Commons music** (CC-BY, CC-BY-SA) via Free Music Archive / ccMixter / dedicated CC-music catalogs. AzuraCast is GREAT for CC stations — the entire pipeline just works + no royalties.
  - **Same legal-risk-tool class** as Bitmagnet (batch 85), 13ft (83), AnonAddy (79), Unbound (80), Fider (82), MicroBin (81). **7th tool in network-service-legal-risk family.**
- **Bandwidth cost**: streaming audio to N listeners = N × stream bitrate. 128 kbps MP3 × 100 concurrent listeners = ~12.8 Mbps outbound sustained. A small VPS can run out of monthly bandwidth quickly on a popular stream. Use **Icecast relays** to offload.
- **Live-DJ streaming** requires inbound RTMP/Icecast source connection — opens an auth-surface + network ports. Harden with strong StreamerBlaster credentials per DJ.
- **Listener privacy**: AzuraCast records listener IPs + user-agents for analytics. GDPR-relevant if your audience includes EU listeners — publish a privacy notice + disclose analytics.
- **DB grows steadily** with listener analytics + song history. Prune old analytics data if your instance runs for years.
- **Monolithic-ish Docker stack** = easier install + harder to compose with your existing infra. If you run a tightly-managed Kubernetes shop, AzuraCast's "here's a whole stack" model won't fit cleanly. Accept the monolith or evaluate Libretime (alternative with more-flexible deploy).
- **Stream URL structure** + **CORS**: embedding AzuraCast's player on an external domain needs CORS configured. Upstream docs cover this; watch for "Mixed Content" errors if embedding over HTTPS from HTTP stream.
- **Icecast passwords + source creds** are stored in DB — hub-of-credentials tier (**9th tool in hub-of-credentials family**: Nexterm / myDrive / Webtop / xyOps / Ombi / pad-ws / redis-commander / Chartbrew / AzuraCast).
- **Multi-user role/permissions**: good RBAC (admin, station manager, DJ, etc.). Check current matrix in docs for your compliance needs.
- **Ethical-source badge**: AzuraCast displays an "Ethical Open Source" badge. Standard-not-yet-universal; non-OSI-approved license class would be a concern, but AzuraCast is straight AGPL-3.0 — the badge is author-values-signal, not a license restriction.
- **Project health**: active repo + Mastodon presence + long history + Ethical-Source-aligned + AGPL. Strong + sustainable.
- **Alternatives worth knowing:**
  - **Libretime** — open-source radio automation (Airtime fork); similar scope; different stack
  - **Airtime Pro** — commercial SaaS
  - **Icecast + Liquidsoap + custom UI** — roll-your-own (AzuraCast is basically this, wrapped)
  - **mAirList** — commercial
  - **Radio.co** / **Live365** — commercial SaaS radio hosting
  - **Choose AzuraCast if:** you want all-in-one + actively-developed + AGPL + mature features.
  - **Choose Libretime if:** you want Airtime-lineage + alternative stack.
  - **Choose roll-your-own Liquidsoap if:** you're deeply technical + want maximum flexibility.

## Links

- Repo: <https://github.com/AzuraCast/AzuraCast>
- Homepage: <https://www.azuracast.com>
- Docs: <https://www.azuracast.com/docs>
- Installation: <https://www.azuracast.com/docs/getting-started/installation/>
- Requirements: <https://www.azuracast.com/docs/getting-started/requirements/>
- Troubleshooting: <https://www.azuracast.com/docs/help/troubleshooting/>
- Demo: <https://demo.azuracast.com>
- Mastodon: <https://floss.social/@AzuraCast>
- Liquidsoap (engine): <https://www.liquidsoap.info>
- Icecast (engine): <https://icecast.org>
- Libretime (alt): <https://libretime.org>
- Free Music Archive (CC music source): <https://freemusicarchive.org>
- ccMixter (CC music source): <http://ccmixter.org>
