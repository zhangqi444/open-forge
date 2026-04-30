---
name: ZoneMinder
description: "Open-source CCTV / NVR suite — captures, analyzes, records, and monitors IP/USB/analog cameras on Linux. One of the oldest (2003+) still-maintained self-hosted video surveillance projects. Perl + C++ + PHP. GPL-2.0+."
---

# ZoneMinder

ZoneMinder is **one of the oldest open-source CCTV / NVR suites** — captures video from IP cameras, USB cameras, and analog capture cards (BT848/BTTV), records continuously or on motion, presents a web UI for live viewing + playback + PTZ control + multi-monitor montages. First released **2002-2003**; still actively maintained by a small community. It predates modern alternatives (Frigate, Shinobi, MotionEye) and shows its age in UI polish, but remains reliable + fully FOSS + enormous feature footprint.

Features:

- **Multiple capture paths** — IP cameras (ONVIF + RTSP + MJPEG + HTTP), USB webcams (V4L2), analog capture cards (BT848)
- **Continuous recording** — record 24/7
- **Motion detection** — zone-based, configurable sensitivity
- **Event storage** — clips stored on local filesystem
- **Web UI** — live view, timeline, events, montage
- **PTZ control** — for supported cameras
- **Multi-monitor montage** — grid view
- **Authentication** — local users; optional LDAP
- **Plugin system** — event hooks, object detection (via zmeventnotification / MachineLearning plugins)
- **Mobile apps** — zmNinja (third-party, most popular)
- **API**
- **Zone-based detection** — per-camera motion zones with per-zone sensitivity/trigger rules

- Upstream repo: <https://github.com/ZoneMinder/zoneminder>
- Docs: <https://zoneminder.readthedocs.org>
- Website: <https://zoneminder.com>
- Forum: <https://forums.zoneminder.com>
- Wiki: <https://wiki.zoneminder.com>
- Slack: via repo README invite link
- Dockerfiles: <https://github.com/ZoneMinder/zmdockerfiles>

## Architecture in one minute

- **Perl + C++** capture daemons — `zmc` (capture), `zma` (analysis), `zmf` (frame writer)
- **PHP** web frontend
- **MySQL / MariaDB** — metadata (events, zones, users)
- **Filesystem** — event clips + frames (can be massive)
- **Apache** (preferred) or Nginx
- **systemd** services: `zoneminder.service`
- **Resource**: scales roughly by cameras × resolution × framerate. 4 HD cameras @ 15 fps = ~4 GB RAM + multi-core + steady disk I/O

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                        |
| ------------------ | -------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Single VM/host     | **Official Ubuntu PPA (Isaac Connor)**                             | **Upstream-recommended primary path**                                            |
| Single VM          | Debian repo / RHEL via RPM Fusion / Fedora / Arch AUR                      | Distro packages                                                                          |
| Docker             | Community Dockerfiles (`zmdockerfiles` repo)                                            | Works; hardware pass-through tricky                                                                      |
| Raspberry Pi       | 4GB+ Pi; 1-2 cameras at modest res only                                                              | Limited by CPU                                                                                                          |
| Kubernetes         | Rare; hardware + storage make it awkward                                                                            |                                                                                                                                              |
| Bare metal + RAID  | **Typical mature deployment** — dedicated host + big disks                                                                          | Industry-standard CCTV pattern                                                                                                                          |

## Inputs to collect

| Input                 | Example                                        | Phase       | Notes                                                                |
| --------------------- | ---------------------------------------------- | ----------- | -------------------------------------------------------------------- |
| Camera URLs           | `rtsp://user:pass@cam1.lan/Streaming/Channels/101` | Setup       | Per camera                                                                   |
| Storage path          | `/var/cache/zoneminder/events/`                                 | Storage     | **Large** disk expected                                                                |
| Retention             | per-camera + global                                                   | Policy      | Default 7 days; set by disk capacity                                                                                   |
| DB                    | MariaDB                                                                     | DB          | Mostly metadata; not huge                                                                                                 |
| Admin account         | default `admin` / `admin`                                                                 | Bootstrap   | **Change immediately**                                                                                                                                    |
| Timezone              | critical for timestamps                                                                                    | Setup       | Set in PHP config + DB                                                                                                                                                   |
| Network               | cameras + ZM on same VLAN / reachable                                                                                     | Network     | RTSP often UDP-based; firewall accordingly                                                                                                                                                              |

## Install via Ubuntu PPA

```sh
sudo add-apt-repository ppa:iconnor/zoneminder-1.36
sudo apt update
sudo apt install zoneminder mariadb-server
# configure DB per upstream docs
sudo systemctl enable --now zoneminder
```

Apache config + DB bootstrap per <https://zoneminder.readthedocs.io/en/stable/installationguide/ubuntu.html>.

## Install via Docker (community)

Use `zmdockerfiles` repo. Hardware pass-through (USB cams, GPU) requires `--device` mappings; RTSP IP cams don't need device mounts.

## First boot

1. Browse `http://<host>/zm/` → log in `admin`/`admin` → change password + enable authentication
2. `Options → System → ZM_AUTH_HASH_SECRET` → set a random secret
3. Add monitor (camera): **source type = FFMPEG / RTSP**, paste camera URL, set width/height/fps
4. Define zones on the monitor (motion-trigger areas) + exclusion zones (ignore a tree that moves)
5. Set recording mode (Nodect = continuous, Modect = motion, Mocord = both)
6. Verify event recording; check disk usage
7. Configure storage paths + retention
8. Install **zmNinja** mobile app for remote viewing

## Data & config layout

- `/etc/zm/` — config (`conf.d/*`, `zm.conf`)
- `/var/cache/zoneminder/events/` — **event clips and frames (huge)**
- `/var/log/zm/` — logs
- DB — metadata only

## Backup

```sh
# DB (metadata; small)
mysqldump -u root -p zm | gzip > zm-db-$(date +%F).sql.gz
# Config
sudo tar czf zm-config-$(date +%F).tgz /etc/zm/
# Events — usually NOT backed up (too large). Rely on camera + retention policy + RAID.
```

**Retention strategy > backup strategy** for video. Plan for RAID + scheduled purging, not offsite backup for all clips.

## Upgrade

1. Releases: <https://github.com/ZoneMinder/zoneminder/releases>. Active but slower-paced.
2. PPA: `apt update && apt upgrade zoneminder` — stop service first; migrations auto.
3. **Back up DB + config** before major upgrades.
4. Docker: check image update; restart.
5. **Read release notes** — major versions can have schema migrations.

## Gotchas

- **Default `admin` / `admin`** — change immediately; ZoneMinder instances get scanned.
- **Disk I/O is the bottleneck**, not CPU. 10 HD cameras at 15 fps = continuous write workload. Plan for dedicated SSDs or properly sized HDDs; RAID for resilience.
- **Motion detection is old-school pixel-diff**, not ML. False positives on lighting changes, trees, shadows. For modern object-detection (person/car/package), add **zmeventnotification + machine-learning hooks** OR evaluate **Frigate** (modern Coral-TPU-based NVR) instead.
- **UI looks dated** — ZoneMinder's UI is from the 2000s. Functional but not beautiful. If UX matters, evaluate Shinobi/Frigate/Motioneye/UniFi Protect.
- **RTSP compatibility**: most IP cameras work but some quirky. Try both `RTSP/RTP` and `RTSP/RTP over TCP` for stability.
- **ONVIF**: supported but setup-heavy; for consumer cameras, use direct RTSP URL where available.
- **PTZ**: supported for select protocols; test before buying a PTZ camera specifically for ZM.
- **Authentication**: enable ZM_OPT_USE_AUTH. Never expose ZM to internet without auth; preferably also behind VPN/reverse-proxy+auth.
- **Building from source is discouraged** — upstream says this explicitly. Use PPAs/packages.
- **MariaDB tuning**: event table can grow large; `innodb_buffer_pool_size` + periodic `OPTIMIZE TABLE` helpful.
- **Retention**: ZM auto-purges based on disk-free and per-camera policy. Monitor; accidental retention=forever fills disks.
- **Snapshots + saved events**: important events (incidents, evidence) → mark as "archived" so they don't auto-purge.
- **Legal compliance (CCTV signage)**: most jurisdictions require signage + data retention policy + access logs. ZoneMinder logs access but compliance is your responsibility. **GDPR in EU**: surveillance footage is personal data — DPIA + retention minimization required.
- **Modern alternatives**: **Frigate** (Python + Coral-TPU + YOLO-based object detection) has overtaken ZM for many new installs. Worth evaluating before adopting ZoneMinder in 2026.
- **zmNinja** (separate project) is the third-party mobile app — de facto standard. iOS + Android.
- **License**: **GPL-2.0+**.
- **Alternatives worth knowing:**
  - **Frigate** — modern; AI object detection via Coral TPU / GPU; MQTT/Home Assistant integration (separate recipe likely)
  - **Shinobi** — modern NVR; JS-based (separate recipe)
  - **MotionEye / motionEyeOS** — lightweight; Pi-friendly (separate recipe)
  - **Viseron** — modern Python NVR with object detection
  - **Agent DVR** — cross-platform; free tier
  - **Synology Surveillance Station / UniFi Protect / Blue Iris / Milestone** — commercial
  - **iSpy** — Windows NVR
  - **Choose ZoneMinder if:** longstanding, mature, needs USB/analog capture card support + legacy camera support.
  - **Choose Frigate if:** modern AI-based object detection + MQTT + Home Assistant.
  - **Choose Shinobi if:** modern UI + JS-based extensibility.
  - **Choose MotionEye if:** Pi-focused, small deployment.
  - **Choose UniFi Protect / Synology if:** commercial turnkey acceptable.

## Links

- Repo: <https://github.com/ZoneMinder/zoneminder>
- Docker repo: <https://github.com/ZoneMinder/zmdockerfiles>
- Docs (RTD): <https://zoneminder.readthedocs.org>
- Website: <https://zoneminder.com>
- Forum: <https://forums.zoneminder.com>
- Wiki: <https://wiki.zoneminder.com>
- Releases: <https://github.com/ZoneMinder/zoneminder/releases>
- Isaac Connor's PPA (Ubuntu): <https://launchpad.net/~iconnor>
- zmNinja (mobile app): <https://github.com/pliablepixels/zmNinja>
- zmeventnotification (ML hooks): <https://github.com/pliablepixels/zmeventnotification>
- Frigate (modern alt): <https://github.com/blakeblackshear/frigate>
- Shinobi (alt): <https://shinobi.video>
- Viseron (alt): <https://github.com/roflcoopter/viseron>
