---
name: pufferpanel
description: PufferPanel recipe for open-forge. Covers self-hosting the open-source game server management panel. Upstream: https://github.com/pufferpanel/pufferpanel
---

# PufferPanel

Web-based game server management panel. Create, manage, and share multiple game servers from one central web interface. Supports Minecraft (Java/Bedrock), Terraria, Factorio, Rust, Valheim, and many more via templates. Assign servers to users, give players access to their own servers. Upstream: <https://github.com/pufferpanel/pufferpanel>. Docs: <https://docs.pufferpanel.com>.

**License:** Apache-2.0

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| DEB package (Debian/Ubuntu) | https://docs.pufferpanel.com/en/latest/installing.html | ✅ | Recommended for Linux VPS/server |
| RPM package (RHEL/Fedora) | https://docs.pufferpanel.com/en/latest/installing.html | ✅ | Red Hat-based distros |
| Docker | https://docs.pufferpanel.com/en/latest/docker.html | ✅ | Containerised panel |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| server | "Server's public IP or domain?" | IP or FQDN | All; used in panel config |
| admin | "Admin user email and password?" | Free-text | Initial user setup |
| network | "Port for PufferPanel web UI?" | Default: 8080 | All |

## Install (Debian/Ubuntu — recommended)

```bash
# Download latest DEB from GitHub releases
wget https://github.com/pufferpanel/pufferpanel/releases/download/v3.0.7/pufferpanel_3.0.7_amd64.deb
sudo dpkg -i pufferpanel_3.0.7_amd64.deb

# Enable and start the service
sudo systemctl enable --now pufferpanel

# Create the first admin user
sudo pufferpanel user add --admin --email admin@example.com --username admin --password yourpassword
```

Access the panel at `http://yourserver:8080`.

## Install (RPM — RHEL/Fedora)

```bash
wget https://github.com/pufferpanel/pufferpanel/releases/download/v3.0.7/pufferpanel-3.0.7-1.x86_64.rpm
sudo rpm -i pufferpanel-3.0.7-1.x86_64.rpm
sudo systemctl enable --now pufferpanel
sudo pufferpanel user add --admin --email admin@example.com --username admin --password yourpassword
```

## Docker

```yaml
services:
  pufferpanel:
    image: pufferpanel/pufferpanel:3.0.7
    restart: unless-stopped
    ports:
      - 8080:8080
      - 5657:5657   # game server daemon port
    volumes:
      - /var/lib/pufferpanel:/var/lib/pufferpanel
```

See: https://docs.pufferpanel.com/en/latest/docker.html

## Software-layer concerns

### Key directories (DEB/RPM install)

| Path | Purpose |
|---|---|
| `/etc/pufferpanel/` | Configuration files |
| `/var/lib/pufferpanel/` | Server data, game files, panel database |
| `/var/log/pufferpanel/` | Log files |

### Ports

| Port | Purpose |
|---|---|
| 8080 | PufferPanel web UI (HTTP) |
| 5657 | Game server daemon (SFTP-like access) |
| Various | Game servers themselves (per-game, configured in templates) |

Open game server ports in your firewall based on the game templates you create.

### Reverse proxy (nginx example)

```nginx
server {
    listen 443 ssl;
    server_name panel.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

WebSocket (`Upgrade`) headers are required for the console/terminal feature.

### Game templates

PufferPanel uses JSON templates to define how to install and run each game. Community templates available at: https://github.com/pufferpanel/templates

## Upgrade procedure

```bash
# Debian/Ubuntu
wget https://github.com/pufferpanel/pufferpanel/releases/download/<version>/pufferpanel_<version>_amd64.deb
sudo dpkg -i pufferpanel_<version>_amd64.deb
sudo systemctl restart pufferpanel
```

## Gotchas

- **WebSocket required.** The panel console uses WebSockets; the reverse proxy must forward `Upgrade`/`Connection` headers. Consoles won't work without this.
- **Create admin user after install.** The panel starts without any users; run `pufferpanel user add --admin` before logging in.
- **Game server ports vary.** Each game server opens its own ports. Open the relevant ports in your firewall for each game.
- **Docker volume persistence.** When using Docker, mount `/var/lib/pufferpanel` to a host volume; otherwise game server data is lost on container recreate.
- **Port 5657 (daemon).** Required for SFTP-like file access. Expose it if you need file management from the panel.
- **v3 breaking change.** PufferPanel v3 is a major rewrite from v2. There is a migration guide at https://docs.pufferpanel.com/en/latest/migrate.html.

## Upstream docs

- Installation guide: https://docs.pufferpanel.com/en/latest/installing.html
- Docker guide: https://docs.pufferpanel.com/en/latest/docker.html
- v2 → v3 migration: https://docs.pufferpanel.com/en/latest/migrate.html
- GitHub README: https://github.com/pufferpanel/pufferpanel
- Releases: https://github.com/pufferpanel/pufferpanel/releases
