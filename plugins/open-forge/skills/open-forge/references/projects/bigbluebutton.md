---
name: BigBlueButton
description: "Open-source virtual classroom / web conferencing purpose-built for online learning. Real-time audio/video/screen share, whiteboard annotations, polling, breakout rooms, session recording/playback, Learning Analytics Dashboard. LTI integration with Moodle/Canvas/Sakai. Ubuntu + many moving parts. LGPL-3.0."
---

# BigBlueButton

BigBlueButton (BBB) is the canonical open-source **virtual classroom** — a web conferencing platform purpose-built for education (online tutoring, flipped classrooms, group collaboration, online classes). Think "Zoom for teachers" but with native features for learning: multi-user whiteboard, shared notes, polls, emojis, breakout rooms, a Learning Analytics Dashboard, and session recording with playback.

Most users don't interact with BBB directly — they go through **Greenlight** (the default front-end) or an LTI integration with Moodle, Canvas, Sakai, Schoology, etc.

Features:

- **Real-time A/V** — WebRTC audio, video, screen share
- **Multi-user whiteboard** with slide annotations
- **Shared notes** (Etherpad)
- **Polling + emoji reactions**
- **Breakout rooms** (with automatic return)
- **Chat** (public + private)
- **Session recording + playback** (post-session, generated server-side)
- **Learning Analytics Dashboard** — moderator-visible in-session + post-session
- **Moderator/Viewer roles**
- **LTI 1.3** — plug into Moodle, Canvas, Sakai, D2L, Schoology
- **Greenlight** front-end — upstream-maintained; self-serve rooms

**⚠️ Installation is Ubuntu-specific** — BBB only supports **Ubuntu 22.04 LTS** for BigBlueButton 3.0 (older: 20.04 for 2.7; 18.04 for 2.5/2.6). Do NOT try on Debian/RHEL/Alpine — BBB has many system-integrated components (FreeSWITCH, Nginx, Redis, MongoDB, HTML5 client, Etherpad, BBB-specific services) that the installer wires together against Ubuntu-packaged versions.

- Upstream repo: <https://github.com/bigbluebutton/bigbluebutton>
- Installer repo: <https://github.com/bigbluebutton/bbb-install>
- Greenlight repo: <https://github.com/bigbluebutton/greenlight>
- Website: <https://bigbluebutton.org>
- Docs: <https://docs.bigbluebutton.org>

## Architecture in one minute

BBB is a **multi-service system installed on a single Ubuntu host** (or more for scaling):

- **HTML5 client** (web UI; React/Meteor) — what users see
- **bbb-web** (Java/Grails) — main API
- **Akka apps** (Scala) — real-time messaging, transcoding coord
- **FreeSWITCH** — SIP/WebRTC audio
- **Kurento / mediasoup** — WebRTC SFU for video + screen share
- **Redis** — pub/sub + session state
- **MongoDB** — session data for HTML5 client
- **Etherpad** — shared notes
- **Nginx** — reverse proxy + TLS
- **bbb-recorder** — post-session recording pipeline
- **Greenlight** (Rails) — optional front-end
- **LTI gateway** — plug into Moodle/Canvas/etc.

Public-facing HTTPS port 443 + WebRTC UDP/TCP ports (16384-32768).

## Compatible install methods

| Infra       | Runtime                                               | Notes                                                            |
| ----------- | ----------------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | **`bbb-install.sh`** on **Ubuntu 22.04 LTS**            | **The canonical path**                                              |
| Scale-out   | Multiple BBB servers + Scalelite load balancer            | For 10+ concurrent classrooms                                           |
| Managed     | BlueButton.io, Higher Education hosting providers            | Cost varies                                                                  |
| Docker      | **NOT officially supported**                                    | Community attempts exist but break easily                                         |
| Kubernetes  | NOT officially supported                                         | Same                                                                                  |

## System requirements

Minimum (for ~50 concurrent users on single server):

- Ubuntu 22.04 LTS, 64-bit
- 8 CPU cores (16 for production) + 16 GB RAM
- 500 GB SSD (recordings consume space)
- **Public IPv4** with reverse DNS
- Ports: 443/tcp, 80/tcp (redirect), 3478/tcp+udp (TURN), 16384-32768/udp (WebRTC)
- Root SSH access

BBB is HEAVY. Don't try on a 2GB Pi.

## Inputs to collect

| Input               | Example                        | Phase     | Notes                                                        |
| ------------------- | ------------------------------ | --------- | ------------------------------------------------------------ |
| Hostname            | `bbb.example.edu`                 | DNS       | Must resolve publicly (A + reverse)                              |
| Email for Let's Encrypt | `admin@example.edu`              | TLS       | Used by `bbb-install.sh -e` flag                                      |
| Version             | `3.0`                              | Install   | Check latest at docs.bigbluebutton.org                                       |
| Greenlight (opt)    | `-g`                                 | Install   | Installer adds Greenlight as docker-ized front-end                                |
| Coturn              | Built-in via `-c <fqdn>:<secret>`     | Network   | For users behind strict NAT                                                           |
| Firewall            | UFW or cloud security groups            | Network   | See ports above                                                                            |

## Install

**Single-command install** (only supported path):

```sh
# On fresh Ubuntu 22.04 LTS:
wget -qO- https://raw.githubusercontent.com/bigbluebutton/bbb-install/v3.0.x-release/bbb-install.sh | bash -s -- \
    -v jammy-300 \
    -s bbb.example.edu \
    -e admin@example.edu \
    -g
```

- `-v jammy-300` — BBB 3.0 on Ubuntu 22.04 (jammy). Use `focal-270` for 2.7 on 20.04. Check README for current.
- `-s bbb.example.edu` — FQDN (must resolve to the host)
- `-e admin@example.edu` — email for Let's Encrypt
- `-g` — also install Greenlight front-end
- `-c bbb.example.edu:<secret>` — configure TURN (for users behind symmetric NAT)

Installer takes 20-40 minutes. At the end it prints the BBB admin URL.

## First use

1. If Greenlight installed: browse `https://bbb.example.edu`, create admin user via Greenlight CLI (`docker exec greenlight-v3 bundle exec rake user:create[name,email,password,admin]`)
2. Create a room → share URL → test audio/video
3. For LTI (Moodle/Canvas/etc.): get BBB API secret with `bbb-conf --secret` and configure BBB as external tool in your LMS

## Data & config layout

BBB installs across the filesystem (it's a heavy system install, not containerized):

- `/usr/share/bigbluebutton/` — configs, templates
- `/var/bigbluebutton/` — recordings, uploaded presentations
- `/var/lib/freeswitch/` — FreeSWITCH state
- `/var/log/bigbluebutton/` — per-service logs
- `/usr/local/bigbluebutton/` — HTML5 client, core services
- `/etc/nginx/sites-available/bigbluebutton` — Nginx config

Greenlight (if installed): `/root/greenlight-v3/` (docker-compose dir + Postgres data).

## Backup

```sh
# Recordings (potentially huge!)
rsync -aAXv /var/bigbluebutton/recording/ /backups/bbb-recordings-$(date +%F)/

# Greenlight DB (if used)
docker exec greenlight-v3-postgres pg_dumpall -U postgres | gzip > greenlight-$(date +%F).sql.gz

# BBB configs (immutable, can rebuild from installer if lost)
tar czf bbb-configs-$(date +%F).tgz /usr/share/bigbluebutton /etc/bigbluebutton
```

**Recordings grow FAST** — a 1-hour class can produce 100-300 MB of recording data. Budget accordingly.

## Upgrade

1. Releases: <https://github.com/bigbluebutton/bigbluebutton/releases>
2. BBB upgrades across MAJOR versions (2.x → 3.x) typically require a **fresh install** on a new Ubuntu release. Migrating recordings is manual (copy + re-run recording rebuild).
3. Minor-version upgrades on same Ubuntu: re-run `bbb-install.sh` with the new `-v` flag.
4. **ALWAYS back up before upgrade.**
5. Read <https://docs.bigbluebutton.org/administration/upgrade/> — specific notes per version.

## Scaling (Scalelite)

For 10+ concurrent classrooms or thousands of users:

- Deploy N independent BBB servers
- Front them with **Scalelite** (<https://github.com/blindsidenetworks/scalelite>) — routing layer that picks the least-loaded server per meeting
- Scalelite has Redis + Postgres
- Greenlight / LTI / Moodle talks to Scalelite, not individual BBBs

## Gotchas

- **UBUNTU-ONLY** — do not try on Debian, CentOS, Rocky, Alpine, Arch. BBB is deeply entangled with specific Ubuntu package versions + systemd + Nginx conventions.
- **Public IP + real FQDN required** — BBB cannot run behind NAT without coturn, and even with coturn, some strict-NAT users will have trouble. Cloud VM is typical.
- **Ports 16384-32768/udp must be open** — corporate firewalls that only allow 443/TCP break BBB. Use coturn's TCP fallback on 443 for those users.
- **Let's Encrypt HTTP-01** — installer expects port 80 open from the internet. If behind CDN/WAF, install fails; pre-provision cert manually.
- **Recordings pipeline is the usual pain point** — `bbb-recorder` processes events + audio + video into playback format. Can lag or fail on overloaded servers. Monitor `/var/log/bigbluebutton/recording-*.log`.
- **HTML5 client is Meteor-based** — heavy client-side; low-end devices / old browsers struggle. Chrome/Firefox/Edge recent versions only. Safari support improved in 3.x but still quirky.
- **WebRTC = Chrome/Firefox** — Safari sometimes drops video quality. iOS works in Safari 16+ but not as reliably as Chrome/Android.
- **SIP audio (PSTN dial-in)** requires FreeSWITCH config + a SIP trunk — out-of-scope for the default installer.
- **Default `bbb-install.sh` behavior** — replaces system packages; do NOT run on a shared host running other services.
- **CPU-bound**: transcoding + SFU use a lot of CPU. Rule-of-thumb: 1 core per 10-15 simultaneous cameras.
- **Bandwidth**: 1 Mbps upstream per camera at 720p. A 50-user class with 10 cameras on = 10 Mbps upstream from server. Plan hosting.
- **Classrooms >50 users**: start thinking Scalelite (multi-server).
- **Greenlight 3.x is a full rewrite** from 2.x — data migration is manual; consult Greenlight upgrade docs.
- **LTI 1.1 deprecated** — move to LTI 1.3. Older Moodle plugins may still use 1.1.
- **Classroom vs webinar**: BBB's strength is INTERACTIVE classes (< 100 users). For broadcast/webinar (1000+ viewers), use Jitsi + LiveKit + streaming, or OBS + RTMP.
- **Learning Analytics Dashboard** is admin-visible only during + after the session — privacy-sensitive; check your school's compliance requirements (GDPR, FERPA).
- **Recordings retention** — default policy keeps recordings indefinitely. Configure rotation to avoid disk filling: `bbb-record --list`, `bbb-record --delete <id>`, or scheduled cleanup.
- **Alternative: Jitsi** is simpler, general-purpose, arguably easier to install (Docker-first), but lacks the education-specific features (polls, whiteboard with slide annotations, breakout rooms with auto-return, analytics). Choose based on whether "classroom features" matter.
- **Not for ad-hoc meetings** — Zoom/Meet/Teams are better UX for "quick call with colleague." BBB shines when you actually want whiteboard + slides + polls + breakout.
- **LGPL-3.0 license** — linking exceptions; generally considered business-friendly.
- **Commercial hosting** (BlueButton.io + partners) is a legitimate option if you don't want to operate BBB yourself.
- **Alternatives worth knowing:**
  - **Jitsi Meet** — general video conferencing; simpler; Docker-friendly (separate recipe)
  - **Nextcloud Talk** — if you already run Nextcloud; good for classrooms too
  - **LiveKit** — modern WebRTC SFU; build-your-own-app; not a full platform
  - **Zoom / Google Meet / MS Teams / WebEx** — commercial
  - **OpenMeetings** (Apache) — older Java-based conferencing; less active
  - **Choose BBB if:** you're a school/university/trainer who needs classroom-specific features (whiteboard annotations on slides, polls, breakout rooms, analytics) + willing to run Ubuntu.
  - **Choose Jitsi if:** you want general-purpose video conferencing + Docker-first.

## Links

- Repo: <https://github.com/bigbluebutton/bigbluebutton>
- Install script: <https://github.com/bigbluebutton/bbb-install>
- Greenlight (front-end): <https://github.com/bigbluebutton/greenlight>
- Scalelite (load balancer): <https://github.com/blindsidenetworks/scalelite>
- Website: <https://bigbluebutton.org>
- Docs: <https://docs.bigbluebutton.org>
- Install docs: <https://docs.bigbluebutton.org/administration/install/>
- Recording docs: <https://docs.bigbluebutton.org/administration/customize/#customize-recording>
- LTI integration: <https://docs.bigbluebutton.org/greenlight/gl-lti-integration/>
- Releases: <https://github.com/bigbluebutton/bigbluebutton/releases>
- Developer docs: <https://docs.bigbluebutton.org/development/guide/>
- Community forum: <https://groups.google.com/g/bigbluebutton-users>
