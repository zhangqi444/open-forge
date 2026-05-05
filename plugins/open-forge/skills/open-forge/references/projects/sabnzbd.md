# SABnzbd

Open-source binary newsreader for Usenet. SABnzbd automates the full Usenet download pipeline: add an NZB file, and it downloads, verifies, repairs (par2), extracts (unrar/7zip), and files away the content automatically — with zero required manual interaction.

**Official site:** https://sabnzbd.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker (LinuxServer) | `lscr.io/linuxserver/sabnzbd`; recommended |
| Any Linux host | Python (native) | `pip install sabnzbd` or package manager |
| macOS / Windows | Installer | Desktop installer from sabnzbd.org |
| Kubernetes | Helm (community) | Community charts available |

---

## Inputs to Collect

### Phase 1 — Planning
- Usenet provider credentials (host, port, username, password, SSL)
- Number of connections (per provider plan)
- Download directory and incomplete directory paths
- Whether to use hardlinks/atomic moves (separate volumes vs shared volume)

### Phase 2 — Deployment
- PUID / PGID for file ownership (LinuxServer image)
- Timezone (`TZ`)
- Port mapping (default `8080`)

---

## Software-Layer Concerns

### Docker Compose (LinuxServer)

```yaml
services:
  sabnzbd:
    image: lscr.io/linuxserver/sabnzbd:latest
    container_name: sabnzbd
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: UTC
    volumes:
      - ./config:/config
      - /data/downloads:/downloads
      - /data/incomplete:/incomplete-downloads
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### Volume Layout (Recommended for *arr Stack)

For hardlink support (avoiding double disk usage during post-processing), use a shared top-level volume:

```yaml
volumes:
  - /data:/data  # SABnzbd downloads to /data/usenet/; *arr apps see /data/
```

Map SABnzbd categories to subdirectories under the shared volume root.

### Key Config Options (Web UI: Settings → General)
| Setting | Description |
|---------|-------------|
| `host` | Bind address (set `0.0.0.0` for Docker) |
| `port` | Web UI port (default `8080`) |
| `username` / `password` | Web UI authentication |
| `api_key` | API key for *arr integration |
| `nzb_key` | Separate key for NZB uploads |

### Usenet Server Config (Settings → Servers)
| Field | Notes |
|-------|-------|
| Host | Provider server hostname |
| Port | Usually 119 (plain) or 563 (SSL) |
| SSL | Enable for encrypted connections |
| Connections | Per your plan; don't exceed provider limit |
| Priority | Set multiple servers: primary + fill/backup |

### Post-Processing
SABnzbd auto-runs par2 verification/repair and unrar extraction after download. Configure post-processing scripts in **Settings → Folders → Post-Processing Scripts**.

### API (for *arr integration)
```
http://<host>:8080/api?mode=<action>&apikey=<api_key>
```
Sonarr/Radarr/Lidarr connect to SABnzbd via this API for automated download queue management.

---

## Upgrade Procedure

```bash
docker pull lscr.io/linuxserver/sabnzbd:latest
docker compose up -d
```

Backups: config is in `./config/sabnzbd.ini`. Back it up before major version upgrades.

---

## Gotchas

- **Hardlinks require same filesystem**: Download volume and final library must be on the same filesystem for hardlinks/atomic moves to work. Use a shared `/data` mount with subfolders for SABnzbd and *arr apps.
- **Incomplete and complete on same drive**: Put `incomplete-downloads` and `downloads` on the same disk for direct-write optimization (v5.0+ feature).
- **API key vs NZB key**: The API key controls all operations; the NZB key is for upload-only (safer to share with browser extensions).
- **SSL cert check**: Disable SSL cert check only if using trusted internal newsservers; leave enabled for public providers.
- **Par2 repair**: Large NZBs with significant corruption require significant CPU and time. Consider `par2cmdline-turbo` for faster repair.
- **Category paths**: Set up categories (TV, Movies, Music) with mapped download paths so *arr apps can pick up completed downloads automatically.
- **v5.0 breaking change**: Post-processing scripts now always execute even for failed jobs — check job status in your scripts (`%F` / `%T` parameters).

---

## References
- GitHub: https://github.com/sabnzbd/sabnzbd
- Docs / Wiki: https://sabnzbd.org/wiki/
- LinuxServer Docker: https://docs.linuxserver.io/images/docker-sabnzbd/
- *arr integration guide: https://wiki.servarr.com/
