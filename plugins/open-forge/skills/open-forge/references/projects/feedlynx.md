# Feedlynx

> Lightweight "read later" link collector that generates an Atom/RSS feed — save links from your browser, iOS, or Android, then subscribe to your personal feed in any feed reader. Single binary, file-based storage, no database.

**Official URL:** https://github.com/wezm/feedlynx  
**Browser extension:** https://github.com/wezm/feedlynx-ext

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Binary (Rust) | Pre-compiled binaries for Linux x86_64 and aarch64 |
| FreeBSD / macOS / Windows | Binary | Cross-platform; pre-built binaries available |
| Any Linux VPS/VM | Systemd service | Recommended for persistent deployment |

---

## Inputs to Collect

### Phase: Pre-Deploy (Required)
| Input | Description | Example |
|-------|-------------|---------|
| `FEEDLYNX_PRIVATE_TOKEN` | Secret token to authenticate link-add requests (32+ chars) | generate with `feedlynx gen-token` |
| `FEEDLYNX_FEED_TOKEN` | Token embedded in the feed URL path (32+ chars) | generate with `feedlynx gen-token` |
| `FEED_PATH` | Path to the Atom feed XML file (created if missing) | `/var/lib/feedlynx/feed.xml` |

### Phase: Optional
| Input | Description | Default |
|-------|-------------|---------|
| `FEEDLYNX_ADDRESS` | Bind address | `127.0.0.1` |
| `FEEDLYNX_PORT` | Listening port | `8001` |
| `FEEDLYNX_LOG` | Log level (`off`, `error`, `warn`, `info`, `debug`, `trace`) | `info` |

---

## Software-Layer Concerns

### Installation
```bash
# Download pre-compiled binary from releases
wget https://github.com/wezm/feedlynx/releases/latest/download/feedlynx-x86_64-unknown-linux-musl.tar.gz
tar xzf feedlynx-*.tar.gz
chmod +x feedlynx
sudo mv feedlynx /usr/local/bin/

# Generate tokens
feedlynx gen-token  # run twice — one for PRIVATE_TOKEN, one for FEED_TOKEN
```

### Running
```bash
FEEDLYNX_PRIVATE_TOKEN=your-32-char-private-token \
FEEDLYNX_FEED_TOKEN=your-32-char-feed-token \
FEEDLYNX_ADDRESS=0.0.0.0 \
FEEDLYNX_PORT=8001 \
feedlynx /var/lib/feedlynx/feed.xml
```

On startup, Feedlynx prints the feed URL:
```
[INFO  feedlynx] HTTP server running on: http://0.0.0.0:8001
[INFO  feedlynx::server] feed available at /feed/YOUR_FEED_TOKEN
```

Subscribe to `https://yourdomain.com/feed/YOUR_FEED_TOKEN` in your feed reader.

### Systemd Service
```ini
[Unit]
Description=Feedlynx link collector
After=network.target

[Service]
Environment=FEEDLYNX_PRIVATE_TOKEN=your-private-token
Environment=FEEDLYNX_FEED_TOKEN=your-feed-token
Environment=FEEDLYNX_ADDRESS=127.0.0.1
Environment=FEEDLYNX_PORT=8001
ExecStart=/usr/local/bin/feedlynx /var/lib/feedlynx/feed.xml
Restart=on-failure
User=feedlynx

[Install]
WantedBy=multi-user.target
```

### API Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Server info page |
| `/add` | POST | Add a link (form: `url`, `token`, optional `title`) |
| `/feed/FEED_TOKEN` | GET | The Atom feed |

### Data Directories
| Path | Purpose |
|------|---------|
| `FEED_PATH` (e.g. `/var/lib/feedlynx/feed.xml`) | Single XML file — the entire feed; back this up |

### Feed Trimming
- Entries older than 30 days are eligible for removal
- Feed is capped at 50 entries — oldest excess entries removed when a new link is added

### Ports
- Default: `8001` — proxy with Nginx/Caddy for HTTPS (recommended for external access)

---

## Upgrade Procedure

1. Stop the service: `systemctl stop feedlynx`
2. Download and replace the binary with the new release
3. Start: `systemctl start feedlynx`
4. No database migration — feed file format is stable

---

## Gotchas

- **Tokens must be 32+ chars** — shorter tokens are rejected at startup; use `feedlynx gen-token` to generate valid tokens
- **Feed token is public** — the feed URL contains the feed token; it's a bearer token for read access; treat it as moderately sensitive (like an RSS feed auth token)
- **Private token secures writes** — the `FEEDLYNX_PRIVATE_TOKEN` is required in every POST to `/add`; keep it secret
- **No Docker image** — Feedlynx ships as a binary; run it via systemd or a process supervisor; no official Docker image
- **YouTube embeds** — links to YouTube URLs automatically get a video embed in the feed entry
- **Feed auto-trims** — entries are pruned automatically; there is no way to mark items as "read" — subscribe in a feed reader that tracks read status

---

## Links
- GitHub: https://github.com/wezm/feedlynx
- Browser extension: https://github.com/wezm/feedlynx-ext
- Android integration: https://github.com/wezm/feedlynx/wiki/Android-Integration
- iOS Shortcut: https://www.icloud.com/shortcuts/1629cde707ca432ead72403ffd9f4dbc
