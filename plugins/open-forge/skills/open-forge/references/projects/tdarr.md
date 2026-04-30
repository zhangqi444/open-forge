---
name: Tdarr
description: "Distributed transcoding automation for media libraries — FFmpeg/HandBrake video transcode/remux with plugin-based conditional rules, GPU + CPU workers, parallelization. Server + Node architecture. Node.js + Mongo. Proprietary (free for self-host + free tier) with paid Pro features."
---

# Tdarr

Tdarr is **"automated video library transcoding at scale"** — point it at your movie/TV library, define conditional rules ("anything still H.264 → re-encode to HEVC"; "anything without English audio → skip"; "anything with truehd → passthrough"), and Tdarr distributes the work across **GPU and CPU workers on the same or different machines**. Companion to Sonarr/Radarr workflows: **Sonarr downloads → Tdarr normalizes → Plex/Jellyfin serves**.

Built + maintained by **HaveAGitGat** — solo/small-team. **Proprietary license** but **free to use** for self-hosting. Some features gated behind paid tiers (historically: premium plugins, priority support). Tested on dummy libraries of **1,000,000 files** — enterprise-grade scale.

Architecture: **Tdarr_Server** (central brain, web UI, job queue) + **Tdarr_Node** (workers; one or many; cross-platform). Spare PC in the basement? Run a Node on it. Gaming PC idle at night? Run a Node. Tdarr auto-balances.

Use cases: (a) shrink library size (H.264 → HEVC: 40-50% savings) (b) unify codec for playback compatibility (c) strip unwanted audio tracks / subtitles (d) remux to preferred container (.mkv) (e) health-check (scan for corruption) (f) batch operations across millions of files.

Features:

- **Cross-platform Nodes** — Windows, Linux (amd64, arm, arm64), macOS, Docker
- **Server + Node architecture** — central + distributed workers
- **GPU + CPU workers** — plus Health-Check CPU/GPU workers (4 worker types)
- **Hardware transcoding** (Nvidia NVENC/NVDEC, Intel QuickSync, AMD)
- **Plugin system** — conditional transcoding rules; community plugin library
- **Plugin stacks** — chain plugins; complex decision trees
- **HandBrake OR FFmpeg** — your choice per library
- **7-day / 24-hour scheduler** — limit when workers run
- **Folder watcher** — auto-pick up new files
- **Worker stall detector** — detect hung jobs
- **Load balancing** across libraries + drives
- **Hundreds of file properties** — search + filter
- **Library stats** + **worker verdict history** + **job reports**
- **Web UI** for everything

- Upstream repo: <https://github.com/HaveAGitGat/Tdarr>
- Homepage: <https://tdarr.io>
- Docs: <https://docs.tdarr.io>
- Downloads: <https://home.tdarr.io/download>
- Installation: <https://docs.tdarr.io/docs/installation/windows-linux-macos>
- Plugins repo: <https://github.com/HaveAGitGat/Tdarr_Plugins>
- Reddit: <https://www.reddit.com/r/Tdarr/>
- Discord: <https://discord.gg/GF8X8cq>
- Related desktop: <https://github.com/HaveAGitGat/HBBatchBeast>

## Architecture in one minute

- **Server** process: web UI + job queue + plugin engine
- **Node** processes: workers that pull jobs from Server over HTTP
- **MongoDB** internal — metadata about files + jobs
- **FFmpeg + HandBrake** — both bundled in Docker images
- **Resource**: Server = modest; Nodes = as much CPU/GPU as you throw at them (they're the workers)
- **Disk I/O**: read source + write transcoded = 2x source size temp usage per file

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`haveagitgat/tdarr`** (server+node combo) OR separate         | **Upstream-primary**                                                               |
| Docker (separate)  | `haveagitgat/tdarr_server` + `haveagitgat/tdarr_node`                      | Recommended for multi-host                                                                 |
| Native binaries    | Windows / Linux / macOS                                                              | Install on existing workstations                                                                    |
| GPU-enabled        | Nvidia: Container Toolkit; Intel iGPU: device passthrough                                              | Required for hardware transcoding                                                                             |
| unRAID / Synology  | Widely-deployed community-documented                                                                                 | Native                                                                                                  |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Media library path   | `/media/library`                                            | Storage      | Mounted read-write (or via transcode-cache pattern)                                                                    |
| Server URL           | `http://tdarr.local:8265`                                   | Network      | Node(s) connect here                                                                                    |
| Cache directory      | `/temp` on fast SSD                                                             | Storage      | Temporary transcode output — SSD strongly recommended                                                                                           |
| GPU access           | Nvidia `--gpus all` + device mapping                                                            | Hardware     | Per node                                                                                                              |
| Plugin set           | Community plugins from Tdarr_Plugins repo                                                                        | Config       | Start with example; customize                                                                                              |
| Schedule             | "Run workers 10pm-8am only"                                                                                                    | Throttling   | Avoid daytime interference                                                                                                                 |

## Install via Docker Compose

```yaml
services:
  tdarr:
    image: haveagitgat/tdarr:latest                  # **pin version** in prod
    restart: unless-stopped
    ports: ["8265:8265", "8266:8266"]                # Server UI + Node HTTP
    environment:
      serverIP: 0.0.0.0
      serverPort: 8265
      webUIPort: 8265
      internalNode: "true"
      inContainer: "true"
      ffmpegVersion: 6
      nodeName: InternalNode
    volumes:
      - ./tdarr/server:/app/server
      - ./tdarr/configs:/app/configs
      - ./tdarr/logs:/app/logs
      - ./tdarr/transcode-cache:/temp
      - /mnt/media:/media                             # your library
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia                          # if using Nvidia GPU
              capabilities: [gpu]
```

## First boot

1. Deploy Server
2. Browse `http://host:8265` → UI
3. Library tab → Add Library → point at `/media`
4. Configure transcode + health-check settings (plugin stack)
5. Workers tab → start some workers (CPU + GPU)
6. Watch "Fresh scan" kick off → then jobs start queuing
7. (opt) Deploy additional Nodes on other machines pointing at Server
8. Configure schedule to avoid daytime impact
9. Back up `/app/configs` + Mongo DB

## Data & config layout

- `/app/server/` — Mongo data + app state
- `/app/configs/` — library configs, plugin stacks, worker settings
- `/app/logs/` — logs
- `/temp/` — transcode cache (safe to delete if job stalls)
- Your media library — where transcoded files replace originals

## Backup

```sh
# Stop for consistency or use Mongo dump
docker compose stop tdarr
sudo tar czf tdarr-server-$(date +%F).tgz tdarr/server tdarr/configs
docker compose start tdarr
```

## Upgrade

1. Releases: <https://docs.tdarr.io/docs/releases/changing-version>. Active.
2. Docker: bump tag; Server + Nodes should match versions.
3. **Back up before major upgrades.**
4. Plugin repo may have breaking changes — re-test your plugin stack after upgrade.

## Gotchas

- **Transcoding DESTROYS source files** by default if your plugin stack is configured to replace them. **READ THE "Saves" setting carefully.** Options:
  - **Replace original** — cheapest disk use; BUT a bad plugin = destroyed original
  - **Keep original + new** — safer but doubles storage
  - **Move to different directory** — good for pipelines
  - **TEST YOUR PLUGIN STACK ON A COPY FIRST.** Tdarr runs at scale; a buggy rule can munge thousands of files.
- **Transcoding is LOSSY** for most codecs (H.264 → HEVC is not bit-exact). You're trading quality for size. Use **CRF values** not fixed bitrates for reasonable quality. Also: re-encoding an ALREADY-lossy file = further loss. Do it once; keep the re-encoded version forever.
- **HDR + surround audio gotchas**: HDR10/Dolby Vision metadata can be DROPPED by a naive FFmpeg re-encode. TrueHD/Atmos passthrough needs explicit plugin logic. Use plugin stacks that explicitly preserve HDR + Atmos.
- **GPU encoding quality**: NVENC + QuickSync are FAST but lower-quality per-bitrate than CPU x265. For archival → prefer CPU encoding. For shrinkage-for-streaming → GPU is fine.
- **Nvidia NVENC session limits**: consumer Nvidia GPUs (GeForce) are historically limited to 3-5 concurrent encode sessions by driver. Tdarr will queue beyond; won't actually run them in parallel. Nvidia's "patch" to remove the limit is at your own risk. Quadro/datacenter cards have no limit.
- **Transcoding load is INTENSE.** Running Tdarr + Plex simultaneously on the same GPU = Plex transcoding for playback fights Tdarr background jobs for GPU. Use schedule to avoid overlap, OR dedicate GPUs to different tools.
- **Disk I/O-heavy**: reading + writing full-size video files constantly. SSD cache for `/temp` is a night-and-day improvement vs HDD cache.
- **Pirated media + legal risk**: Tdarr doesn't download content; it only processes what you have. BUT the *arr-stack-context (Sonarr, Radarr, Prowlarr, Usenet, torrents) that Tdarr is usually deployed alongside can involve unlicensed content. Transcoding your own legal rips = fine; normalizing pirated content at scale = copyright liability. Not a tool concern per se but worth naming.
- **Health-check workers** scan for file corruption — USEFUL signal. Broken video files in your library ruin playback; Tdarr finds them.
- **Plugin marketplace is community-driven** — quality varies. Start with official plugins; verify before custom.
- **Mongo + large libraries**: DB grows. Million-file library = non-trivial MongoDB footprint (GB of metadata).
- **Not for live streaming** — Tdarr is batch-mode. For live transcode use Plex/Jellyfin directly.
- **Licensing opacity**: Tdarr is proprietary source-available; "free to use" for self-hosting. Paid features historically (plugin workflows, premium support) — verify current licensing at <https://tdarr.io/>. Not AGPL; not OSS. Plan accordingly if you need legal certainty (e.g., "is this part of our compliance-cleared stack?").
- **Project health**: HaveAGitGat solo-led + active + donation-funded + paid-tier. Large homelab user base. Solid + sustained.
- **Alternatives worth knowing:**
  - **Unmanic** — FOSS alternative; Python; active
  - **FileBot** — commercial media-management; different scope
  - **Manual FFmpeg scripts** — roll your own; no UI
  - **Plex/Jellyfin live transcoding** — on-demand not batch
  - **HandBrake batch CLI** — minimal; rolls-your-own queueing
  - **Choose Tdarr if:** want a web UI + plugin system + distributed workers + battle-tested at scale.
  - **Choose Unmanic if:** want fully-OSS FFmpeg-batch without proprietary licensing.
  - **Choose manual FFmpeg if:** control-freak with a small library.

## Links

- Repo: <https://github.com/HaveAGitGat/Tdarr>
- Plugins repo: <https://github.com/HaveAGitGat/Tdarr_Plugins>
- Homepage: <https://tdarr.io>
- Docs: <https://docs.tdarr.io>
- Download: <https://home.tdarr.io/download>
- Install: <https://docs.tdarr.io/docs/installation/windows-linux-macos>
- Releases: <https://docs.tdarr.io/docs/releases/changing-version>
- Reddit: <https://www.reddit.com/r/Tdarr/>
- Discord: <https://discord.gg/GF8X8cq>
- HBBatchBeast (related desktop): <https://github.com/HaveAGitGat/HBBatchBeast>
- Unmanic (alt): <https://unmanic.app>
- HandBrake (engine): <https://handbrake.fr>
- FFmpeg (engine): <https://ffmpeg.org>
