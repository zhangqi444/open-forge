---
name: tuwunel
description: Tuwunel recipe for open-forge. Covers Docker and binary install. Tuwunel is a high-performance Matrix homeserver written in Rust — the successor to conduwuit (a fork of Conduit). Actively developed, sponsored by the Swiss government.
---

# Tuwunel

High-performance Matrix homeserver written in Rust. The official successor to conduwuit (itself a fork of Conduit). Actively developed with daily commits and full-time staff; sponsored by the Swiss government 🇨🇭 where it is deployed for citizens. Fully implements the Matrix specification. Compatible with all Matrix clients (Element, FluffyChat, etc.), bridges, and bots. Much lower resource usage than Synapse. Upstream: <https://github.com/matrix-construct/tuwunel>. Docs: <https://matrix-construct.github.io/tuwunel/>. Website: <https://tuwunel.chat>.

**License:** Apache-2.0 · **Language:** Rust · **Default port:** 6167 (internal) / 8448 (federation) · **Stars:** ~2,000

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | `jevolk/tuwunel:latest` (Docker Hub) or `ghcr.io/matrix-construct/tuwunel:latest` | ✅ | **Recommended** — easiest, multi-arch. |
| Debian/Ubuntu package | GitHub releases | ✅ | System service on Debian/Ubuntu. |
| Binary | GitHub releases | ✅ | Bare-metal / any Linux. |
| Nix/NixOS | `services.matrix-tuwunel` NixOS module | ✅ | NixOS deployments. |
| AUR (Arch) | `tuwunel` | Community | Arch Linux. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| server_name | "Matrix server name? (e.g. example.com — avoid subdomains, you cannot change this later)" | Free-text | Required. |
| registration_token | "Registration token to restrict sign-ups? (recommended — set a strong random value)" | Free-text | Recommended. |
| federation | "Enable federation with other Matrix servers?" | AskUserQuestion: Yes / No | Optional. |
| element_web | "Also deploy Element Web client alongside the homeserver?" | AskUserQuestion: Yes / No | Optional. |

> **⚠️ server_name is permanent:** Choose carefully. You cannot change your `server_name` after users have registered. Use a root domain (e.g. `example.com`) and delegate with `.well-known` if you want the server on a subdomain.

## Install — Docker Compose

```bash
mkdir tuwunel && cd tuwunel

cat > docker-compose.yml << 'COMPOSE'
services:
  homeserver:
    image: jevolk/tuwunel:latest
    restart: unless-stopped
    ports:
      - "8008:6167"
    volumes:
      - tuwunel-db:/var/lib/tuwunel
    environment:
      TUWUNEL_SERVER_NAME: "your.server.name"   # EDIT THIS
      TUWUNEL_DATABASE_PATH: /var/lib/tuwunel
      TUWUNEL_PORT: 6167
      TUWUNEL_ADDRESS: 0.0.0.0
      TUWUNEL_MAX_REQUEST_SIZE: 20000000        # ~20 MB
      TUWUNEL_ALLOW_REGISTRATION: "true"
      TUWUNEL_REGISTRATION_TOKEN: "YOUR_STRONG_TOKEN"
      TUWUNEL_ALLOW_FEDERATION: "true"
      TUWUNEL_TRUSTED_SERVERS: '["matrix.org"]'

volumes:
  tuwunel-db:
COMPOSE

docker compose up -d
```

## Reverse proxy (Caddy — recommended)

Caddy auto-provisions TLS certificates and handles Matrix federation port (8448):

```
# /etc/caddy/Caddyfile
your.server.name, your.server.name:8448 {
    reverse_proxy localhost:8008
}
```

```bash
caddy reload --config /etc/caddy/Caddyfile
```

### nginx example

```nginx
server {
    listen 443 ssl http2;
    server_name your.server.name;

    ssl_certificate /etc/letsencrypt/live/your.server.name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your.server.name/privkey.pem;

    location / {
        proxy_pass http://localhost:8008;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
# Federation port
server {
    listen 8448 ssl http2;
    server_name your.server.name;
    # ... same ssl + proxy_pass config
}
```

## Well-known delegation (optional)

If your `server_name` is `example.com` but Tuwunel runs on `matrix.example.com`, serve these files from `example.com`:

**`https://example.com/.well-known/matrix/server`:**
```json
{"m.server": "matrix.example.com:443"}
```

**`https://example.com/.well-known/matrix/client`:**
```json
{"m.homeserver": {"base_url": "https://matrix.example.com"}}
```

## Install — Debian package

```bash
# Download the .deb from GitHub releases
VERSION=v1.6.1
wget https://github.com/matrix-construct/tuwunel/releases/download/${VERSION}/tuwunel_${VERSION}_amd64.deb
sudo dpkg -i tuwunel_${VERSION}_amd64.deb

# Configure
sudo nano /etc/tuwunel/tuwunel.toml
# Set server_name and database_path at minimum

sudo systemctl enable --now tuwunel
```

## Key configuration options

| Env var / config key | Description | Default |
|---|---|---|
| `TUWUNEL_SERVER_NAME` | Your Matrix domain — **permanent, choose carefully** | (required) |
| `TUWUNEL_DATABASE_PATH` | RocksDB database directory | (required) |
| `TUWUNEL_PORT` | Internal listen port | `6167` |
| `TUWUNEL_ALLOW_REGISTRATION` | Allow new user registrations | `false` |
| `TUWUNEL_REGISTRATION_TOKEN` | Token required to register (recommended) | (none) |
| `TUWUNEL_ALLOW_FEDERATION` | Connect to other Matrix servers | `true` |
| `TUWUNEL_MAX_REQUEST_SIZE` | Max upload size in bytes | `20000000` |
| `TUWUNEL_LOG` | Log level | `info` |

Full config reference: <https://matrix-construct.github.io/tuwunel/configuration.html>

## Adding Element Web (optional)

```yaml
# Add to docker-compose.yml services:
  element-web:
    image: vectorim/element-web:latest
    restart: unless-stopped
    ports:
      - "8009:80"
    volumes:
      - ./element_config.json:/app/config.json
    depends_on:
      - homeserver
```

Create `element_config.json`:
```json
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://your.server.name",
      "server_name": "your.server.name"
    }
  }
}
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| RocksDB storage | Uses RocksDB (not SQLite like Synapse). Fast and efficient. Data stored in `database_path`. |
| server_name is permanent | Cannot be changed after users register — it becomes part of every user's Matrix ID (`@user:server_name`). |
| TLS required for federation | Federation with other Matrix servers requires your homeserver to be reachable over HTTPS with a valid TLS cert on port 443 or 8448. |
| Registration tokens | Strongly recommended — open registration (`allow_registration=true` without a token) attracts spam accounts rapidly. |
| Docker image tags | `latest` = most recent release (~monthly). `preview` = higher-confidence weekly builds. `main` = every reviewed merge (~daily). |
| Memory usage | Much lighter than Synapse — typically 100–500 MB RAM for small/medium servers vs Synapse's 1–4+ GB. |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# Debian package
wget https://github.com/matrix-construct/tuwunel/releases/download/vX.Y.Z/tuwunel_vX.Y.Z_amd64.deb
sudo dpkg -i tuwunel_*.deb
sudo systemctl restart tuwunel
```

## Gotchas

- **server_name is forever:** Once users are registered, the Matrix IDs (`@user:server_name`) are permanently tied to this domain. You cannot migrate to a different server_name.
- **Registration token strongly recommended:** Without `TUWUNEL_REGISTRATION_TOKEN`, your open-registration server will be abused for spam within hours. Always set a token.
- **Federation needs public HTTPS:** For your server to federate with matrix.org and others, it must be reachable at `https://your.server.name:443` or `:8448` with a valid cert. Local/LAN installs won't federate.
- **Caddy is the easiest TLS option:** Caddy automatically handles Let's Encrypt certificate provisioning and renewal. It's the recommended reverse proxy in the upstream docs.
- **Successor to conduwuit:** If you were running conduwuit, Tuwunel is the official continuation. Migration should be straightforward (same database format).
- **Not Synapse:** Tuwunel is not a drop-in replacement for Synapse's admin API. Some admin tools designed specifically for Synapse may not be compatible.

## Upstream links

- GitHub: <https://github.com/matrix-construct/tuwunel>
- Docs: <https://matrix-construct.github.io/tuwunel/>
- Configuration reference: <https://matrix-construct.github.io/tuwunel/configuration.html>
- Docker deployment guide: <https://matrix-construct.github.io/tuwunel/deploying/docker.html>
- Releases: <https://github.com/matrix-construct/tuwunel/releases>
- Docker Hub: <https://hub.docker.com/r/jevolk/tuwunel>
- GHCR: <https://github.com/matrix-construct/tuwunel/pkgs/container/tuwunel>
- Demo: <https://try.tuwunel.chat>
- Matrix support chat: <https://matrix.to/#/#tuwunel:grin.hu>
