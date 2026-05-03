# Betula

> Single-user federated bookmark manager with Fediverse support — publish, tag, and archive bookmarks; follow other Betula instances; accept followers from Mastodon and other ActivityPub software. Single binary, single SQLite file, zero external dependencies.

**Official URL:** https://betula.mycorrhiza.wiki  
**Source:** https://codeberg.org/bouncepaw/betula  
**GitHub mirror:** https://github.com/bouncepaw/betula

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Single binary | Download pre-built binary; no Docker needed |
| Any Linux VPS/VM | Docker | Community images available; check Codeberg |
| Raspberry Pi / ARM | Single binary | Go binary; cross-compiled builds available |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DOMAIN` | Public domain for your Betula instance | `links.example.com` |
| `data_dir` | Directory to store the SQLite database | `./betula-data` |

### Phase: In-App Setup (web UI)
All configuration is done through the web interface after first launch:
- Admin username and password
- Instance name and description
- Federation settings (enable/disable ActivityPub)
- Miniflux integration (optional)

---

## Software-Layer Concerns

### Installation (Binary)
```bash
# Download latest release from Codeberg releases page
wget https://codeberg.org/bouncepaw/betula/releases/download/v1.6.0/betula-linux-amd64
chmod +x betula-linux-amd64

# Run (creates betula.db in current directory)
./betula-linux-amd64 -addr :8080
```

### Systemd Service
```ini
[Unit]
Description=Betula bookmark manager
After=network.target

[Service]
ExecStart=/usr/local/bin/betula -addr :8080 -db /var/lib/betula/betula.db
Restart=on-failure
User=betula

[Install]
WantedBy=multi-user.target
```

### Key Flags
| Flag | Default | Description |
|------|---------|-------------|
| `-addr` | `:8080` | Listen address and port |
| `-db` | `./betula.db` | Path to SQLite database file |

### Data Directories
| Path | Purpose |
|------|---------|
| `betula.db` | All bookmarks, tags, followers, archives — **single file; back this up** |

### Ports
- Default: `8080` — proxy with Nginx/Caddy and terminate TLS (required for ActivityPub federation)

### Federation
- Betula instances federate via ActivityPub
- Follow other Betula instances to see their bookmarks in your Timeline
- Mastodon and other Fediverse users can follow your Betula instance
- HTTPS is required for federation to work

### Archive Feature
Betula can save archive copies of bookmarked pages. Archive storage grows over time; ensure the data directory has sufficient disk space.

---

## Upgrade Procedure

1. Stop the running Betula process
2. Download the new binary from the Codeberg releases page
3. Replace the old binary
4. Start Betula — database migrations (if any) run automatically on startup
5. The single `betula.db` file carries all data across versions

---

## Gotchas

- **HTTPS required for federation** — ActivityPub requires a publicly reachable HTTPS endpoint; HTTP-only instances cannot federate with Mastodon or other Betula instances
- **Single-user only** — Betula is designed for one person; there is no multi-user mode
- **Domain is permanent** — the instance domain is embedded in ActivityPub identities; changing it breaks all federation links
- **Archive disk usage** — if you enable page archiving, the database/archive directory grows with every archived bookmark; monitor disk space
- **Mycomarkup** — bookmark descriptions use Mycomarkup (a lightweight wiki markup), not Markdown; syntax is similar but different

---

## Links
- Website: https://betula.mycorrhiza.wiki
- Source (Codeberg): https://codeberg.org/bouncepaw/betula
- Releases: https://codeberg.org/bouncepaw/betula/releases
- Mastodon: https://fosstodon.org/@betula
- NLnet funding: https://nlnet.nl/project/Betula
