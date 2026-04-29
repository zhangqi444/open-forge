---
name: headscale-project
description: Headscale recipe for open-forge. BSD-3-Clause open-source implementation of the Tailscale coordination server — gives you a Tailnet without depending on login.tailscale.com. Single Go binary + SQLite (default) or PostgreSQL. Each Tailscale client needs to be told `--login-server=<your-headscale-url>` to join. This recipe covers the upstream-recommended container install, the mandatory public HTTPS endpoint, DERP relay configuration, OIDC/pre-auth-key node registration, the ACL policy file, and the operational quirks (user model rework in v0.23, API-key rotation, bundled DERP vs external DERP).
---

# Headscale

BSD-3-Clause open-source, self-hosted implementation of the Tailscale coordination server. Upstream: <https://github.com/juanfont/headscale>. Docs: <https://headscale.net>. Container images: `ghcr.io/juanfont/headscale` and `docker.io/headscale/headscale`.

**What it is:** the control plane. When a Tailscale client runs `tailscale up --login-server=https://headscale.example.com`, Headscale handles the node registration, ACL enforcement, key exchange, and DERP coordination — everything `login.tailscale.com` does for the managed service.

**What it's NOT:** the actual WireGuard mesh. Data traffic between your nodes flows directly (or via DERP relays when NAT-traversal fails), not through Headscale itself. Headscale is a low-traffic control-plane service.

**Compatibility:** Official Tailscale clients (macOS, Windows, iOS, Android, Linux) all support `--login-server`. Works as a drop-in Tailscale replacement for a single tailnet. Multi-tailnet, Funnel, and Taildrop are NOT supported in self-host (Tailscale-cloud-only).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Container (`ghcr.io/juanfont/headscale`) | <https://headscale.net/stable/setup/install/container/> | ✅ Recommended | Upstream's primary documented install. |
| Native binary (prebuilt) | GitHub Releases | ✅ | Embedded / bare-metal systemd deploy. |
| Native binary (Debian/Ubuntu `.deb`) | GitHub Releases | ✅ | Installs `headscale.service` systemd unit + conf. |
| Build from source (`go build`) | Upstream repo | ✅ | Dev / custom builds. Requires Go 1.24+. |
| Community Helm charts | Community | ⚠️ | Not upstream-maintained; verify before relying. |

**Docs disclaimer:** the container install page explicitly says it's "community documentation" that upstream doesn't actively verify. The binary + systemd path is more canonically maintained.

## Architecture

Headscale's full setup involves:

- **Headscale server** — HTTP control API (default `:8080`) + metrics (`:9090`) + optional gRPC for CLI.
- **Public HTTPS endpoint** — Tailscale clients require TLS. Reverse proxy mandatory.
- **Embedded DERP or external DERP servers** — fallback relay when NAT-traversal fails between peers.
- **Database** — SQLite default (file-backed); PostgreSQL for HA / large tailnets.
- **ACL policy file** — YAML/HuJSON, reloaded on SIGHUP.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `container` / `deb-package` / `binary` | Drives section. |
| dns | "Public HTTPS URL for Headscale?" | Free-text, e.g. `https://headscale.example.com` | **REQUIRED.** Tailscale clients refuse plaintext. Public DNS A/AAAA record must already resolve. |
| tls | "Reverse proxy (Caddy / nginx / Traefik)?" | `AskUserQuestion` | Headscale has built-in Let's Encrypt but upstream recommends a reverse proxy for flexibility. |
| db | "Database? SQLite / PostgreSQL" | `AskUserQuestion` | SQLite is fine for <500 nodes; PostgreSQL for multi-region HA or very large tailnets. |
| networking | "IP prefixes for the tailnet?" | Free-text, defaults `100.64.0.0/10`, `fd7a:115c:a1e0::/48` | The IPv4/IPv6 CGNAT ranges that get handed out. Change only if you must. |
| derp | "DERP strategy?" | `AskUserQuestion`: `embedded` / `external Tailscale DERP` / `self-hosted headscale-derp` | Embedded works for small tailnets; external Tailscale DERP map is public and free. |
| auth | "Node registration method?" | `AskUserQuestion`: `pre-auth keys` / `OIDC` / `CLI interactive` | OIDC needs a separate IdP (Authelia, Authentik, Keycloak, Zitadel, Google, GitHub). |
| oidc | "OIDC issuer + client ID + client secret?" | Free-text (sensitive) | If OIDC is selected. |
| users | "Initial user name?" | Free-text | Headscale v0.23+ has real users (before that, "namespaces"). Nodes belong to users. |

## Install — Container (upstream-recommended)

```bash
# 1. Create config + data dirs
mkdir -p ./headscale/config ./headscale/lib
cd ./headscale

# 2. Download example config for your version
HS_VERSION=0.27.0   # check https://github.com/juanfont/headscale/releases
curl -o config/config.yaml \
  "https://raw.githubusercontent.com/juanfont/headscale/v${HS_VERSION}/config-example.yaml"

# 3. Edit config/config.yaml — at minimum:
#    server_url: https://headscale.example.com
#    listen_addr: 0.0.0.0:8080
#    metrics_listen_addr: 0.0.0.0:9090
#    private_key_path: /var/lib/headscale/private.key
#    noise.private_key_path: /var/lib/headscale/noise_private.key
#    database.type: sqlite
#    database.sqlite.path: /var/lib/headscale/db.sqlite
#    derp.server.enabled: true        # or false if using external DERP
#    derp.urls: [https://controlplane.tailscale.com/derpmap/default]

# 4. Run
docker run -d \
  --name headscale \
  --restart unless-stopped \
  --read-only \
  --tmpfs /var/run/headscale \
  -v "$(pwd)/config:/etc/headscale:ro" \
  -v "$(pwd)/lib:/var/lib/headscale" \
  -p 127.0.0.1:8080:8080 \
  -p 127.0.0.1:9090:9090 \
  --health-cmd "headscale health" \
  ghcr.io/juanfont/headscale:v${HS_VERSION} \
  serve
```

### Docker Compose equivalent

```yaml
services:
  headscale:
    image: ghcr.io/juanfont/headscale:v0.27.0
    restart: unless-stopped
    container_name: headscale
    read_only: true
    tmpfs:
      - /var/run/headscale
    ports:
      - "127.0.0.1:8080:8080"
      - "127.0.0.1:9090:9090"
    volumes:
      - ./config:/etc/headscale:ro
      - ./lib:/var/lib/headscale
    command: serve
    healthcheck:
      test: ["CMD", "headscale", "health"]
```

Front with a reverse proxy for `https://headscale.example.com → 127.0.0.1:8080`.

## Install — Debian/Ubuntu `.deb` + systemd

```bash
HS_VERSION=0.27.0
ARCH=amd64
curl -LO "https://github.com/juanfont/headscale/releases/download/v${HS_VERSION}/headscale_${HS_VERSION}_linux_${ARCH}.deb"
sudo apt install "./headscale_${HS_VERSION}_linux_${ARCH}.deb"

# Edit /etc/headscale/config.yaml — same fields as container install
sudo systemctl enable --now headscale
sudo systemctl status headscale
sudo journalctl -u headscale -f
```

Package ships:

- `/etc/headscale/config.yaml` — copy of `config-example.yaml`
- `/var/lib/headscale/` — data dir (SQLite DB lives here)
- `/usr/lib/systemd/system/headscale.service`

## Reverse proxy (Caddy)

```caddy
headscale.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

**nginx must forward WebSocket/HTTP2:**

```nginx
server {
    server_name headscale.example.com;
    listen 443 ssl http2;
    # ...cert config...

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_read_timeout 86400;
    }
}
```

## First-run — create user + register a node

```bash
# 1. Create a user
docker exec headscale headscale users create alice

# 2. Generate a pre-auth key (reusable, 24h expiry)
docker exec headscale headscale preauthkeys create --user alice --expiration 24h --reusable

# Returns something like: abc123def456...

# 3. On a node (any OS), install Tailscale client, then:
sudo tailscale up \
  --login-server=https://headscale.example.com \
  --auth-key=abc123def456...

# 4. Verify
docker exec headscale headscale nodes list
```

### OIDC login (alternative to pre-auth keys)

Add to `config.yaml`:

```yaml
oidc:
  only_start_if_oidc_is_available: true
  issuer: "https://auth.example.com/application/o/headscale/"
  client_id: "headscale"
  client_secret: "<from IdP>"
  scope: ["openid", "profile", "email"]
  allowed_domains:
    - example.com
  strip_email_domain: true
```

Nodes run `tailscale up --login-server=...` without `--auth-key`, get a browser URL, complete OIDC, node is registered.

## ACL policy

`config.yaml` references `acl_policy_path`. Example `policy.hujson`:

```hujson
{
  "groups": {
    "group:admins": ["alice@example.com"],
    "group:devs": ["bob@example.com"],
  },
  "acls": [
    {
      "action": "accept",
      "src": ["group:admins"],
      "dst": ["*:*"],
    },
    {
      "action": "accept",
      "src": ["group:devs"],
      "dst": ["tag:dev-servers:22,80,443"],
    },
  ],
}
```

Reload after editing: `docker exec headscale kill -HUP 1`.

## Data layout

| Path (host) | Path (container) | Content |
|---|---|---|
| `./config/config.yaml` | `/etc/headscale/config.yaml` | Server config. |
| `./config/policy.hujson` | Referenced from config | ACL rules. |
| `./lib/db.sqlite` | `/var/lib/headscale/db.sqlite` | Users, nodes, routes, pre-auth keys. **Critical.** |
| `./lib/private.key` | `/var/lib/headscale/private.key` | Server's WireGuard private key. **Critical — irreplaceable.** |
| `./lib/noise_private.key` | `/var/lib/headscale/noise_private.key` | Server's Noise private key. **Critical.** |

### Backup

```bash
# Stop the server, snapshot the whole lib/ dir + config, restart
docker stop headscale
sudo tar -czf headscale-backup-$(date +%F).tar.gz config/ lib/
docker start headscale
```

**Losing `private.key` or `noise_private.key` = every existing node must be re-registered.** Nodes identify the server by its key; a new key = a new server from their perspective.

## Upgrade procedure

```bash
# 1. Read release notes FIRST. v0.23 had a user-model schema migration; major-version bumps
#    have broken config formats before.
#    https://github.com/juanfont/headscale/releases

# 2. Backup (see above)

# 3. Pin a new version + restart
docker rm -f headscale
docker run -d ... ghcr.io/juanfont/headscale:v0.28.0 serve  # new version

# …or for .deb:
sudo apt install ./headscale_0.28.0_linux_amd64.deb
sudo systemctl restart headscale
```

Auto-migrations run on startup. Check logs for migration messages:

```bash
docker logs headscale | grep -iE 'migrat|schema'
```

## Gotchas

- **Public HTTPS is mandatory.** Tailscale clients refuse plaintext connections to the coordination server. No LAN-only installs; your Headscale must have a real cert from a real CA. Let's Encrypt via reverse proxy is the path of least resistance.
- **`server_url` in config must match the public URL the client will use.** Mismatch = clients connect but the key-exchange response references the wrong URL and re-auth loops. Include scheme + host + port if non-default: `server_url: https://headscale.example.com`.
- **Private keys are irreplaceable.** Losing `lib/private.key` + `lib/noise_private.key` = every node on your tailnet must be manually re-registered. Treat these like an SSH host key. Back them up on day 1.
- **v0.23 broke the user model.** "Namespaces" became "users." Pre-v0.23 configs fail to start after upgrade. Upstream has a migration guide but it's a one-way move.
- **DERP relay choice matters for reachability.** Options: (a) embedded DERP (built into Headscale — OK for small tailnets but your one Headscale host becomes a single point for NAT-traversal fallback), (b) use Tailscale's public DERP map (free, global), (c) self-host `headscale-derp` (the embedded DERP server as a standalone binary). Most self-hosters use (b) unless they have strict "no-Tailscale-infra" requirements.
- **No Taildrop, no Funnel, no multi-tailnet.** Those are Tailscale-cloud-only features. Self-host users who need file-transfer use `scp` / `rsync` over the tailnet instead.
- **Pre-auth keys vs OIDC vs CLI registration are exclusive PER NODE.** A node registers once with one method; changing methods requires removing and re-adding the node.
- **ACL policy file format is HuJSON (Human JSON)**, not strict JSON. Allows comments + trailing commas. Upstream provides both `.hujson` and `.yaml` — they're equivalent.
- **Routes (subnet advertising) need manual approval.** When a node advertises `--advertise-routes=192.168.1.0/24`, the route stays pending until you `headscale routes enable <id>`. Not automatic for security.
- **`headscale nodes list` output includes ephemeral internal IPs** — the `100.64.x.x` CGNAT addresses assigned from the `ip_prefixes` config. Node must have accepted them; check with `tailscale status` on the client.
- **Embedded DERP + firewall = silent 20-second NAT-traversal timeout.** If you enable embedded DERP, port 3478/UDP and the DERP HTTPS port (usually `:443`) must reach the public internet. Common misconfiguration on firewalled hosts.
- **No web UI in upstream.** Third-party web UIs exist (headplane, headscale-admin, headscale-webui) — none are officially blessed. CLI is the primary management surface.
- **Tailscale-client version drift.** Newer Tailscale clients can require newer Headscale server versions (protocol changes). Upstream tracks a compat matrix at <https://github.com/juanfont/headscale/blob/main/docs/about/releases.md>.

## Links

- Upstream repo: <https://github.com/juanfont/headscale>
- Docs site: <https://headscale.net>
- Install guides: <https://headscale.net/stable/setup/install/>
- Configuration reference: <https://headscale.net/stable/ref/configuration/>
- ACL policy reference: <https://headscale.net/stable/ref/acls/>
- OIDC setup: <https://headscale.net/stable/ref/oidc/>
- Releases: <https://github.com/juanfont/headscale/releases>
- Config example: <https://github.com/juanfont/headscale/blob/main/config-example.yaml>
- Discord: <https://discord.gg/headscale>
