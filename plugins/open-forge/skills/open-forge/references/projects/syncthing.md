---
name: syncthing-project
description: Syncthing recipe for open-forge. MPL-2.0 peer-to-peer file sync. Covers the official Docker image (`syncthing/syncthing`), host-networking requirement for LAN discovery, native packages, and the UID/GID / PUID/PGID convention shared with the linuxserver.io image.
---

# Syncthing (peer-to-peer file sync)

MPL-2.0 continuous file synchronization. Peers discover each other on the LAN (no central server), sync folders bidirectionally, end-to-end encrypted. Works well as a home-server service, backup target, or always-on replication node.

**Upstream README:** https://github.com/syncthing/syncthing/blob/main/README.md
**Docker README (upstream, canonical):** https://github.com/syncthing/syncthing/blob/main/README-Docker.md
**Docs:** https://docs.syncthing.net
**Docker image:** `syncthing/syncthing` (official, Docker Hub)
**Alternative image:** `lscr.io/linuxserver/syncthing` (linuxserver.io — widely used, different conventions)

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | Always-on box at home |
| localhost | native (apt / brew / pkg) | ✅ | First-party packages for all major OSes |
| home-server | Docker | ✅ default | Most common pattern |
| raspberry-pi | Docker (arm64) | ✅ | Works well on Pi 3/4/5 |
| byo-vps | Docker | ⚠️ | Works, but peer-to-peer means no-LAN advantages; you're paying for bandwidth to sync |
| aws/ec2 | Docker | ⚠️ | Same caveat; Syncthing + cloud VPS makes sense as a 24/7 "rendezvous" node, not a personal sync target |
| kubernetes | community chart | ⚠️ | Various charts; none first-party. |

**Unusual property:** Syncthing has no concept of a "server" and "clients." Every peer is equal. You're not self-hosting a service for others to connect to — you're running a node that other nodes sync with.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| data | "Host path for synced files (the `/var/syncthing` volume)?" | Free-text | Where sync folders live inside the container |
| network | "Use host networking (needed for LAN peer discovery)?" | AskUserQuestion: host (default) / bridge | **Host strongly recommended** per upstream README |
| users | "UID/GID for file ownership?" | Free-text (default `1000:1000`) | `PUID` / `PGID` env vars |
| gui | "Expose the Syncthing web GUI on the internet?" | AskUserQuestion: localhost-only / reverse-proxied / direct | Reverse-proxy with TLS + basic auth if external |
| dns | "Domain for GUI (if reverse-proxied)?" | Free-text | |
| tls | "Email for Let's Encrypt notices?" | Free-text | |

## Install methods

### 1. Docker (upstream official image)

Source: https://github.com/syncthing/syncthing/blob/main/README-Docker.md

```bash
docker run -d --network=host \
  -e STGUIADDRESS= \
  -v /wherever/st-sync:/var/syncthing \
  --name syncthing \
  syncthing/syncthing:latest
```

### 2. Docker Compose

From the upstream Docker README:

```yaml
services:
  syncthing:
    image: syncthing/syncthing
    container_name: syncthing
    hostname: my-syncthing
    environment:
      - PUID=1000
      - PGID=1000
      - STGUIADDRESS=
    volumes:
      - /wherever/st-sync:/var/syncthing
    network_mode: host
    restart: unless-stopped
    healthcheck:
      test: curl -fkLsS -m 2 127.0.0.1:8384/rest/noauth/health | grep -o --color=never OK || exit 1
      interval: 1m
      timeout: 10s
      retries: 3
```

### 3. Native packages

Source: https://docs.syncthing.net/users/installation.html (linked from README)

- **Debian/Ubuntu:** `apt-get install syncthing` (stable repo) or add the Syncthing APT repo for latest
- **Fedora/CentOS/RHEL:** `dnf install syncthing`
- **Arch:** `pacman -S syncthing`
- **macOS:** `brew install syncthing` (CLI) or `brew install --cask syncthing` (GUI app)
- **Windows:** `winget install Syncthing.Syncthing` or download an installer from the releases page
- **FreeBSD:** `pkg install syncthing`
- **Systemd service:** `systemctl --user enable --now syncthing.service` (per-user mode)

### 4. Build from source

Go ≥ 1.21 required. From the main repo README: `go run build.go`. Useful for arm64 cross-builds and unusual platforms.

## Software-layer concerns

### Why host networking is non-negotiable

From the upstream Docker README, verbatim:

> Docker's default network mode prevents local IP addresses from being discovered, as Syncthing can only see the internal IP address of the container on the `172.17.0.0/16` subnet. This would likely break the ability for nodes to establish LAN connections properly, resulting in poor transfer rates unless local device addresses are configured manually.
>
> It is therefore strongly recommended to stick to the host network mode.

Without host networking, Syncthing still works — but it relies on the upstream relay infrastructure or global discovery, which is slower and burns Syncthing's shared bandwidth. **Always use `--network=host` on Linux.** On Docker Desktop (macOS/Windows), host networking is semi-broken — accept the limitation or run Syncthing natively on those hosts.

### Volume: `/var/syncthing`

The upstream image's convention is a single catch-all volume. Your sync folders live inside it:

- `/var/syncthing/Sync/` — default "Default Folder"
- `/var/syncthing/config/` — config, certs, database
- `/var/syncthing/data-v2/` — internal index DB

For more organized layouts, you can mount multiple directories, e.g.:

```yaml
volumes:
  - /srv/syncthing/config:/var/syncthing/config
  - /home/user/Documents:/var/syncthing/Documents
  - /home/user/Photos:/var/syncthing/Photos
```

### Key env vars

| Var | Purpose |
|---|---|
| `PUID` / `PGID` | UID/GID to run Syncthing as (default 1000:1000) |
| `UMASK` | File-create mask (default 022) |
| `PCAP` | Linux capabilities, e.g. `cap_chown,cap_fowner+ep` |
| `STGUIADDRESS` | GUI bind address; empty = use config-file value |
| `STNODEFAULTFOLDER` | Set to `true` to skip creating the "Default Folder" |
| `STHASHING` | CPU hashing mode — `standard`/`minio`/`sha256` |

Full env-var reference: https://docs.syncthing.net/users/syncthing.html

### GUI on :8384

Default GUI bind is `0.0.0.0:8384` **inside the container**. With host networking, that's on the host's `:8384` — exposed to your LAN. Set `STGUIADDRESS=127.0.0.1:8384` to limit, or set a username/password in the config file, or reverse-proxy it with basic auth.

### Ports

- `8384/tcp` — GUI / REST API
- `22000/tcp`+`udp` — sync protocol
- `21027/udp` — local discovery (LAN broadcast)

Host networking exposes all of these automatically. Bridge networking requires `-p 8384:8384 -p 22000:22000 -p 22000:22000/udp -p 21027:21027/udp`.

### linuxserver.io image vs official

Many self-hosters use `lscr.io/linuxserver/syncthing` because it follows the linuxserver.io convention consistent with their other images (Plex, Sonarr, Radarr, etc.). Both are valid; the official image is more minimal. Pick one convention across your stack.

## Upgrade procedure

Docker:

```bash
docker pull syncthing/syncthing:latest
docker stop syncthing && docker rm syncthing
docker run ... (re-run install)
```

Or with Compose:

```bash
docker compose pull && docker compose up -d
```

Syncthing handles its own config migrations on startup. Rollback = restore config dir + use older image tag.

Native: follow your OS's package manager's update path; systemd service restarts automatically.

## Gotchas

- **Host networking is essentially required on Linux.** Without it, LAN discovery breaks and transfers happen via relays.
- **No multi-user auth.** Syncthing's web GUI has a single username/password. If you need multiple users with different access, run multiple instances.
- **UIDs must match across hosts (ish).** If you sync a folder between two machines with different UIDs, file ownership diverges after sync — fine for most workflows but trips up setups that care about UIDs (e.g. shared Unix accounts).
- **GUI listens on 0.0.0.0 by default in the Docker image.** With `--network=host` and default config, your sync GUI is exposed to your LAN unauthenticated. **Set a GUI password** on first run or set `STGUIADDRESS=127.0.0.1:8384`.
- **Introducer pattern saves sanity for >3 peers.** Mark one peer as "Introducer" and new devices it trusts get propagated. Otherwise you're pairing each pair manually.
- **Global Discovery + Relay = upstream Syncthing servers.** If you'd rather not phone home, run your own `stdiscosrv` + `strelaysrv` (binaries ship in the same repo). Most self-hosters leave the defaults on.
- **Power loss during sync.** Syncthing is resilient — it uses block-level hashing and resumes — but a folder marked "staggered-versioning" preserves old versions and can eat disk.
- **Docker Desktop on macOS/Windows ≠ host networking.** Host networking doesn't work in Docker Desktop's VM. Either run Syncthing natively on Mac/Windows (easy) or accept that the container is limited to global discovery.
- **`:latest` tag is fine but moves.** Pin a version (`syncthing/syncthing:v2.1.0`) for reproducibility.

## TODO — verify on subsequent deployments

- [ ] Compare `syncthing/syncthing` vs `lscr.io/linuxserver/syncthing` in a head-to-head — which has better defaults for home-server use?
- [ ] Exercise self-hosted `stdiscosrv` + `strelaysrv` (both in-repo) for a fully-private Syncthing cluster.
- [ ] Reverse-proxy the GUI with Caddy + basic auth; verify WS-like REST API stays responsive.
- [ ] k3s chart — identify a maintained community chart.
