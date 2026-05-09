---
name: cloudflare-ddns
description: cloudflare-ddns recipe for open-forge. Covers Docker Compose and Docker CLI deploy for this feature-rich Cloudflare DDNS updater. Detects public IPv4/IPv6 addresses and updates Cloudflare DNS records automatically. Source: https://github.com/favonia/cloudflare-ddns. License: Apache-2.0 with LLVM exceptions.
---

# Cloudflare DDNS

Feature-rich, robust Cloudflare DDNS updater with a small Docker image. Automatically detects your machine's public IP addresses and updates Cloudflare DNS A/AAAA records. Supports wildcard domains, internationalized domain names, IPv4/IPv6, WAF lists, and notification integrations (Healthchecks, Uptime Kuma, shoutrrr). Written in Go. Upstream: <https://github.com/favonia/cloudflare-ddns>. Docker Hub: <https://hub.docker.com/r/favonia/cloudflare-ddns>.

By default the updater checks IP addresses every 5 minutes and updates DNS records only when the IP has actually changed. It uses Cloudflare's own debugging page (`cloudflare.trace`) as the IP detection source over HTTPS, minimising privacy impact and making forgery attacks harder.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended. Run persistently alongside the rest of your stack. |
| Docker CLI | Quick one-liner; same image, no Compose file needed. |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "What domains do you want to keep updated? (comma-separated, e.g. example.org,www.example.org)" | All methods |
| preflight | "Cloudflare API token (Zone - DNS - Edit permission)" | All methods — see below |
| preflight | "Do you need to proxy these domains through Cloudflare? (true/false, default false)" | All methods |
| preflight | "IPv4 only, IPv6 only, or both? (default: both)" | All methods |

### Generating a Cloudflare API token

1. Open <https://dash.cloudflare.com/profile/api-tokens>.
2. Create a token using the **Edit zone DNS** template.
3. Scope it to the specific zone(s) that host your domains.
4. Copy the token — it cannot be viewed again after creation.

The token needs the **Zone - DNS - Edit** permission. If you also use WAF lists, add **Account - Account Filter Lists - Edit**.

---

## Method — Docker Compose

> **Source:** <https://github.com/favonia/cloudflare-ddns#deployment-with-docker-compose>

The recommended production path. Runs as a hardened, non-root, read-only container.

### docker-compose.yml

```yaml
services:
  cloudflare-ddns:
    image: favonia/cloudflare-ddns:1
    # "1" tracks the latest stable v1.x release.
    # Use "1.x.y" to pin a specific version; "latest" is not recommended in production.
    network_mode: host
    # host networking makes IPv6 detection easier; remove if you don't need IPv6
    restart: always
    user: "1000:1000"
    read_only: true
    cap_drop: [all]
    security_opt: [no-new-privileges:true]
    environment:
      - CLOUDFLARE_API_TOKEN=YOUR-CLOUDFLARE-API-TOKEN
      - DOMAINS=example.org,www.example.org
      # - PROXIED=true     # uncomment to enable Cloudflare proxying for new records
      # - IP6_PROVIDER=none  # uncomment if your network is IPv4-only
```

```bash
docker compose pull cloudflare-ddns
docker compose up -d cloudflare-ddns
```

### Storing the token as a Docker secret

To avoid putting the token in the Compose file or `.env`:

```yaml
services:
  cloudflare-ddns:
    image: favonia/cloudflare-ddns:1
    network_mode: host
    restart: always
    user: "1000:1000"
    read_only: true
    cap_drop: [all]
    security_opt: [no-new-privileges:true]
    environment:
      - CLOUDFLARE_API_TOKEN_FILE=/run/secrets/cloudflare_api_token
      - DOMAINS=example.org,www.example.org
    secrets:
      - cloudflare_api_token

secrets:
  cloudflare_api_token:
    file: ./secrets/cloudflare_api_token.txt
```

Store the token in `./secrets/cloudflare_api_token.txt` (one line, no trailing newline).

---

## Method — Docker CLI

> **Source:** <https://github.com/favonia/cloudflare-ddns#quick-start>

```bash
docker run \
  --network host \
  --restart always \
  --user 1000:1000 \
  --read-only \
  --cap-drop all \
  --security-opt no-new-privileges:true \
  -e CLOUDFLARE_API_TOKEN=YOUR-CLOUDFLARE-API-TOKEN \
  -e DOMAINS=example.org,www.example.org \
  -e PROXIED=true \
  favonia/cloudflare-ddns:1
```

---

## Verify

```bash
docker compose logs cloudflare-ddns
# Look for lines like:
# Updated example.org A record to 1.2.3.4
# No update needed for example.org (current IP matches)
```

On a successful first run you should see the detected IP addresses and a confirmation that the DNS records were created or are already up to date.

---

## Lifecycle

```bash
docker compose pull cloudflare-ddns         # update image
docker compose up -d cloudflare-ddns        # restart with new image
docker compose logs -f cloudflare-ddns      # tail logs
docker compose stop cloudflare-ddns         # stop
```

---

## Key environment variables

| Variable | Default | Description |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | — | Required. Cloudflare API token (Zone - DNS - Edit). |
| `CLOUDFLARE_API_TOKEN_FILE` | — | Alternative: path to a file containing the token. |
| `DOMAINS` | `""` | Comma-separated FQDNs to manage for both A and AAAA records. |
| `IP4_DOMAINS` | `""` | Domains to manage only for A (IPv4) records (additive with DOMAINS). |
| `IP6_DOMAINS` | `""` | Domains to manage only for AAAA (IPv6) records (additive with DOMAINS). |
| `PROXIED` | `false` | Fallback proxy setting for newly created DNS records. Does not change existing records. |
| `TTL` | `1` | Fallback TTL for DNS records (1 = Cloudflare "automatic"). |
| `IP4_PROVIDER` | `cloudflare.trace` | How to detect the public IPv4 address. Use `none` to disable IPv4 management. |
| `IP6_PROVIDER` | `cloudflare.trace` | How to detect the public IPv6 address. Use `none` to disable IPv6 management. |
| `UPDATE_CRON` | `@every 5m` | Cron schedule for re-checking IP addresses. Use `@once` to run once and exit. |
| `HEALTHCHECKS` | — | Healthchecks.io ping URL to notify on successful updates. |
| `UPTIMEKUMA` | — | Uptime Kuma push URL to notify on successful updates. |

Full settings reference: <https://github.com/favonia/cloudflare-ddns#all-settings>.

---

## Gotchas

- **`network_mode: host` is optional but recommended for IPv6.** Without it, the updater detects the Docker bridge network's IP instead of the host's. For IPv4-only setups, you can remove `network_mode: host`.
- **`PROXIED=true` does not change existing records.** It only sets the fallback for newly created records. Change existing records manually in the Cloudflare dashboard.
- **Use `IP6_PROVIDER=none` on IPv4-only networks.** Otherwise the updater logs IPv6 detection failures and may report them to monitoring services.
- **`exec /bin/ddns: operation not permitted` error.** Some Docker + kernel combinations don't work with `security_opt: no-new-privileges:true`. Remove that line to work around it.
- **`CF_API_TOKEN` (without `CLOUDFLARE_` prefix) is deprecated** and will be removed in v2. Prefer `CLOUDFLARE_API_TOKEN`.
- **CGNAT / ISP-level NAT.** If your router shows a `100.64.x.x` WAN address, you're behind CGNAT — DDNS won't help. Consider Cloudflare Tunnel instead.
