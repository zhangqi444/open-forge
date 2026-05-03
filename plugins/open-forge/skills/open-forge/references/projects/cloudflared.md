---
name: cloudflared (Cloudflare Tunnel)
description: Cloudflare's tunneling daemon. Exposes a self-hosted service to the internet via an outbound connection to Cloudflare's edge — no inbound ports, no firewall holes, no public IP required. Free for most use cases; does tie you to Cloudflare as DNS/CDN. Apache-2.0.
---

# cloudflared (Cloudflare Tunnel)

`cloudflared` is the client binary for **Cloudflare Tunnel** (formerly Argo Tunnel). You run it next to your app (on a VPS, Pi, home server, laptop) and it opens an outbound QUIC/HTTP/2 connection to Cloudflare's edge. Cloudflare then routes traffic from `yourapp.example.com` → Cloudflare edge → tunnel → your local service. Your home IP is never exposed; you don't need port forwarding or a public IP; traffic rides Cloudflare's DDoS protection and WAF.

Popular for:

- Self-hosters behind CGNAT / residential ISP with no port forwarding
- Adding Cloudflare Access (zero-trust auth) in front of home services
- Avoiding opening ports on a VPS firewall
- Exposing dev machines / Pi clusters temporarily (`try.cloudflare.com`)

Trade-off: you need a domain on Cloudflare, and all traffic to your app goes through Cloudflare. If Cloudflare is down, your service is unreachable.

- Upstream repo: <https://github.com/cloudflare/cloudflared>
- Docs: <https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/>
- Docker image: <https://hub.docker.com/r/cloudflare/cloudflared>
- Tunnel dashboard: <https://one.dash.cloudflare.com/> → Networks → Tunnels

## Architecture in one minute

Two pieces:

1. **A "tunnel" resource in your Cloudflare account** — has an ID, a name, a credentials file (JWT), and ingress rules (which hostnames/paths map to which local services)
2. **`cloudflared` process on your machine** — reads the credentials, opens outbound connections to Cloudflare edge, proxies requests to local services based on ingress rules

Two management modes:

- **Remote-managed** (newer, recommended): you edit ingress rules in the Cloudflare dashboard; `cloudflared` pulls them
- **Locally-managed** (classic): you edit `config.yml` on your machine; `cloudflared` is the source of truth

## Compatible install methods

| Infra / Use case         | Runtime                                           | Notes                                                               |
| ------------------------ | ------------------------------------------------- | ------------------------------------------------------------------- |
| Docker host              | Docker (`cloudflare/cloudflared:<VERSION>`)       | **Recommended** alongside docker-compose stacks                      |
| Linux (deb / rpm)        | Package from pkg.cloudflare.com                   | Systemd unit included                                                |
| macOS                    | `brew install cloudflared`                        | Homebrew                                                             |
| Windows                  | MSI or `winget install cloudflare.cloudflared`    |                                                                      |
| Raspberry Pi             | ARM binary                                        | Single binary; run under systemd                                     |
| Kubernetes               | Helm chart or manifest with `cloudflared` sidecar | One-tunnel-per-cluster or per-namespace                              |
| Ephemeral / testing      | `cloudflared tunnel --url http://localhost:8080`  | TryCloudflare — ngrok-style throwaway URL; no account needed         |

## Inputs to collect

| Input                  | Example                                        | Phase     | Notes                                                              |
| ---------------------- | ---------------------------------------------- | --------- | ------------------------------------------------------------------ |
| Cloudflare account     | with a zone/domain                             | DNS       | Domain must be on Cloudflare (nameservers delegated)                |
| Tunnel name            | `home-lab`                                     | Tunnel    | Used for identification                                             |
| Tunnel token / creds   | from dashboard or `cloudflared tunnel login`   | Runtime   | JWT stored as `~/.cloudflared/<TUNNEL_ID>.json`                     |
| Public hostname        | `app.example.com`                              | DNS       | Cloudflare creates CNAME to `<TUNNEL_ID>.cfargotunnel.com`          |
| Local service URL      | `http://localhost:3000`                        | Ingress   | What `cloudflared` proxies to                                       |
| TUNNEL_TOKEN env var   | from dashboard (remote-managed mode)           | Runtime   | Single string; encodes account + tunnel ID + credentials             |

## Install via Docker (remote-managed — easiest)

This is the upstream-recommended path for most users:

1. In Cloudflare dashboard: **Zero Trust → Networks → Tunnels → Create a tunnel**
2. Name it (e.g. `home`), pick "Cloudflared" connector
3. Copy the install command — contains a long `--token <TUNNEL_TOKEN>` JWT
4. Run it:

```yaml
# docker-compose.yml
services:
  cloudflared:
    image: cloudflare/cloudflared:2026.3.0    # pin; NEVER :latest in prod
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel --no-autoupdate run
    environment:
      - TUNNEL_TOKEN=${TUNNEL_TOKEN}           # pass via .env or secret
    # no ports — only outbound!
```

5. In the dashboard, add **Public Hostnames** under the tunnel:
   - `app.example.com` → `http://my-app:3000` (service name from your compose network)
   - `grafana.example.com` → `http://grafana:3000`
6. Cloudflare automatically creates the DNS CNAMEs.

The `cloudflared` container must be on the same docker network as the services it proxies to.

## Install via Docker (locally-managed)

Classic mode — your `config.yml` is source of truth:

```sh
# 1. One-time: authenticate on a machine with a browser
cloudflared tunnel login
#  → opens browser, you pick the zone, creates ~/.cloudflared/cert.pem

# 2. Create a tunnel
cloudflared tunnel create home
#  → creates ~/.cloudflared/<UUID>.json (credentials)

# 3. Route DNS
cloudflared tunnel route dns home app.example.com
cloudflared tunnel route dns home grafana.example.com

# 4. Write config.yml
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: home
credentials-file: /etc/cloudflared/<UUID>.json

ingress:
  - hostname: app.example.com
    service: http://my-app:3000
  - hostname: grafana.example.com
    service: http://grafana:3000
  - service: http_status:404         # MUST be last
EOF
```

Then compose:

```yaml
services:
  cloudflared:
    image: cloudflare/cloudflared:2026.3.0
    restart: unless-stopped
    command: tunnel --config /etc/cloudflared/config.yml run home
    volumes:
      - ~/.cloudflared:/etc/cloudflared:ro
```

## Install via deb/rpm (systemd)

```sh
# Debian / Ubuntu
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared

# Run as service with token (remote-managed)
sudo cloudflared service install <TUNNEL_TOKEN>
sudo systemctl enable --now cloudflared
```

## TryCloudflare (ephemeral, no account)

```sh
cloudflared tunnel --url http://localhost:3000
# → prints a random https://xyz-abc.trycloudflare.com URL
```

For testing / demos only; URL changes each run; not stable.

## Data & config layout

Per-user:

- `~/.cloudflared/cert.pem` — origin certificate (zone-level auth)
- `~/.cloudflared/<TUNNEL_UUID>.json` — tunnel credentials (JWT)
- `~/.cloudflared/config.yml` — locally-managed ingress config (if used)

System install:

- `/etc/cloudflared/` — config + credentials
- `/var/log/cloudflared.log` — logs

Remote-managed mode: only needs `TUNNEL_TOKEN`. No files persist.

## Backup

For remote-managed tunnels: the tunnel config lives in Cloudflare. Back up: your `TUNNEL_TOKEN` + hostname list. Losing the token = re-create the tunnel.

For locally-managed: back up `~/.cloudflared/` (contains credentials + cert.pem). Losing these = re-authenticate + re-create tunnel.

## Upgrade

1. Releases: <https://github.com/cloudflare/cloudflared/releases> (multiple per month).
2. Docker: `docker compose pull && docker compose up -d`.
3. **Cloudflare supports versions within one year of release.** Older than that = breaking changes land that may disconnect your tunnel without warning. Set a calendar reminder to upgrade every 6-9 months.
4. Systemd: `sudo apt upgrade cloudflared && sudo systemctl restart cloudflared`.
5. `--no-autoupdate` in compose disables the binary's auto-update — you want this in Docker (let the image tag drive upgrades).

## Gotchas

- **Cloudflare-only.** Your domain MUST have nameservers delegated to Cloudflare. No workaround.
- **All traffic goes through Cloudflare.** You're trusting them with your TLS termination. E2E encryption requires cloudflared-to-origin HTTPS (supported via `service: https://...` + `originRequest.noTLSVerify` options).
- **Free plan limits.** Unlimited bandwidth for HTTP(S) through Tunnel. TCP/UDP (SSH, RDP, arbitrary) also works but requires `cloudflared access` on the client side, or WARP client.
- **Version-lifecycle policy.** From README: "Cloudflare currently supports versions of cloudflared that are within one year of the most recent release." Stale versions can be forcibly deprecated.
- **`--no-autoupdate`** is essential in Docker. The in-binary updater will try to rewrite itself on a read-only rootfs and silently fail.
- **TryCloudflare URLs are ephemeral and rate-limited.** Not for production.
- **TUNNEL_TOKEN = account-level secret.** Compromise = attacker can impersonate your origin via Cloudflare. Store as a Docker secret, not in `.env` committed to git.
- **One tunnel can serve many hostnames.** No need for one tunnel per service; add multiple public hostnames under one tunnel in the dashboard.
- **Ingress-rule order matters.** First match wins. Always end with `service: http_status:404` as a catch-all in locally-managed mode.
- **Service names must be resolvable.** From inside the cloudflared container, `http://my-app:3000` works only if `my-app` is on the same docker network.
- **Cloudflare WAF + Rate Limiting** apply to your tunnel hostnames. Unexpected blocks on legitimate traffic? Check WAF event log in the dashboard.
- **Access (zero-trust) policies** are layered on separately from Tunnel. A "protected" app needs a Cloudflare Access application + policies in the dashboard.
- **WebSocket / gRPC / SSE** are supported but have connection count limits on the free tier (varies).
- **Long-lived connections** (SSE, WebSocket): QUIC transport handles them well; connection migration is transparent.
- **IPv6 and QUIC.** cloudflared prefers QUIC (UDP/7844); falls back to HTTP/2 (TCP/7844) on networks that block UDP.
- **Outbound firewall rules:** allow UDP/7844 + TCP/7844 outbound to Cloudflare IPs. Most home networks allow this by default.
- **Logging:** `--loglevel debug` is noisy but essential for diagnosing "why isn't my tunnel routing?"
- **Alternatives worth knowing:**
  - **Tailscale Funnel** — same idea for Tailscale users, no Cloudflare dependency
  - **ngrok** — simpler but paid for static URLs
  - **frp / frps** — self-hosted on both ends (needs a public VPS)
  - **Pangolin** — self-hosted Cloudflare Tunnel alternative (open source)
  - **bore / rathole** — minimalist self-hosted tunneling
  - **Zrok** — open-source successor to ngrok on OpenZiti
- **License.** cloudflared is Apache-2.0 open source. The service (Cloudflare Tunnel) is proprietary SaaS.

## Links

- Repo: <https://github.com/cloudflare/cloudflared>
- Docker Hub: <https://hub.docker.com/r/cloudflare/cloudflared>
- Docs (get started): <https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/>
- Docs (downloads): <https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/>
- Docs (update / EOL policy): <https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/update-cloudflared/>
- Ingress reference: <https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/configure-tunnels/local-management/ingress/>
- Zero Trust Access: <https://developers.cloudflare.com/cloudflare-one/policies/access/>
- Releases: <https://github.com/cloudflare/cloudflared/releases>
- TryCloudflare: <https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/>
