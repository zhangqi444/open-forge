---
name: galene
description: Galene recipe for open-forge. Covers self-hosting the lightweight videoconferencing server. Upstream: https://github.com/jech/galene
---

# Galene

Lightweight videoconferencing server written in Go. Easy to deploy with moderate server resource requirements — runs well on a small VPS. Uses WebRTC in the browser; no client install required. Supports group rooms, operator permissions, recording, and screen sharing. Upstream: <https://github.com/jech/galene>. Site: <https://galene.org>.

**License:** MIT

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Build from source (Go) + systemd | https://github.com/jech/galene/blob/master/galene-install.md | ✅ | Recommended for production; single Go binary |
| Pre-built binaries (releases) | https://github.com/jech/galene/releases | ✅ | Faster setup; no Go toolchain needed |
| Docker | https://hub.docker.com/r/galene/galene | Community | Containerised deployment |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| server | "Public domain for Galene?" | e.g. galene.example.org | All |
| tls | "Have a Let's Encrypt certificate?" | Yes/No | Determines cert setup |
| groups | "Group name(s) and operator password(s)?" | Free-text | Group config JSON |
| network | "Port Galene listens on?" | Default: 8443 | All |

## Build from source

```bash
# Requires Go 1.21+
git clone https://github.com/jech/galene
cd galene
CGO_ENABLED=0 go build -ldflags='-s -w'
```

Cross-compile for ARM64 (e.g. Raspberry Pi):
```bash
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags='-s -w'
```

## Deploy to server

```bash
# Create dedicated user
useradd -m -s /bin/false galene

# Copy binary and directories to server
rsync -a galene static data groups galene@galene.example.org:

# Install TLS certificate (if using Let's Encrypt)
sudo cp /etc/letsencrypt/live/galene.example.org/fullchain.pem ~galene/data/cert.pem
sudo cp /etc/letsencrypt/live/galene.example.org/privkey.pem ~galene/data/key.pem
sudo chown galene:galene ~galene/data/*.pem
chmod go-rw ~galene/data/key.pem
```

If no certificate is provided, Galene auto-generates a self-signed cert on first start.

## systemd service

`/etc/systemd/system/galene.service`:

```ini
[Unit]
Description=Galene
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/galene
User=galene
Group=galene
ExecStart=/home/galene/galene
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl enable --now galene
```

## Group configuration

Groups are JSON files in the `groups/` directory. Each file defines a room:

```json
{
  "users": {
    "operator": {"password": "secret", "permissions": "op"},
    "presenter": {"password": "pass2", "permissions": "present"}
  },
  "public": true,
  "description": "Night Watch meeting room"
}
```

Save as `groups/my-room.json` — accessible at `https://galene.example.org/group/my-room/`.

## Software-layer concerns

### Key directories

| Directory | Purpose |
|---|---|
| `groups/` | Room configuration JSON files |
| `data/` | TLS certificates (`cert.pem`, `key.pem`) and recordings |
| `static/` | Web UI static files |

### Command-line flags

| Flag | Default | Purpose |
|---|---|---|
| `-http` | `:8080` | HTTP listen address (redirect to HTTPS) |
| `-https` | `:8443` | HTTPS listen address |
| `-recordings` | `./recordings` | Directory for recorded sessions |

### File descriptor limit

Galene opens many file descriptors under load. The systemd unit sets `LimitNOFILE=65536`. For non-systemd setups, run `ulimit -n 65536` before starting.

## Upgrade procedure

```bash
# Build new version
cd galene && git pull
CGO_ENABLED=0 go build -ldflags='-s -w'
# Copy new binary to server
rsync -a galene galene@galene.example.org:
ssh galene@galene.example.org "systemctl restart galene"
```

## Gotchas

- **TLS certificate rotation.** Let's Encrypt certs renew every 90 days. Copy renewed certs to `data/cert.pem` and `data/key.pem` and restart Galene. Automate with a cron job or systemd timer.
- **Self-signed cert.** Galene generates a self-signed cert if none is provided; browsers will show a warning. Use Let's Encrypt for public deployments.
- **File descriptor limit.** Without `ulimit -n 65536`, Galene may fail under load. The systemd unit sets this automatically.
- **No TURN by default.** Users behind strict NAT/firewalls may need a TURN server. Galene supports configuring an external TURN server in `data/config.json`.
- **WebRTC ports.** WebRTC uses UDP for media. Ensure UDP is not firewalled for your Galene server's IP. Galene uses ports in the range configured via `-udp-range` (default: all ephemeral ports).
- **Optional: MediaPipe (background blur).** Requires separately downloading the MediaPipe WASM library into `static/third-party/tasks-vision/`. See installation docs for details.

## Upstream docs

- Installation guide: https://github.com/jech/galene/blob/master/galene-install.md
- Usage and admin: https://github.com/jech/galene/blob/master/galene.md
- FAQ: https://galene.org/faq.html
- GitHub README: https://github.com/jech/galene
- Releases: https://github.com/jech/galene/releases
