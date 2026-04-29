---
name: cobalt-project
description: cobalt recipe for open-forge. AGPL-3.0 media downloader — paste a URL, get the file. Stateless by design (no cache, no persistence). Upstream ships a Docker Compose with `ghcr.io/imputnet/cobalt:11` + Watchtower auto-updater. Covers the canonical compose install, the API-only vs API+web split, the mandatory Cloudflare Turnstile / API-key bot-protection for public instances, reverse-proxy requirements, optional YouTube session generator sidecar, and the `nscd` workaround for bare-metal on Ubuntu 22.04.
---

# cobalt

AGPL-3.0 fast media downloader. Paste a link → get the media file. No ads, no trackers, no account, no cache — operates as a "fancy proxy" for public content on YouTube, Twitter/X, TikTok, Instagram, Reddit, SoundCloud, Bilibili, and 40+ other services. Upstream: <https://github.com/imputnet/cobalt>. Hosted version: <https://cobalt.tools>.

**Stateless by design.** cobalt never stores downloaded content — it streams through the tunnel and discards. That changes the ops model:

- No persistent storage to back up (config is a single compose file + optional cookies.json).
- No DB, no Redis, no queue. Horizontal scaling is just "more containers behind a load balancer."
- Privacy-positive: nothing lingers if the host is seized / logs are subpoenaed.

**Ethics note (from upstream README):** *"cobalt is a tool that makes downloading public content easier. It takes zero liability. The end user is responsible for what they download… cobalt is in no way a piracy tool and cannot be used as such. It can only download free & publicly accessible content."*

## Stack shape

From upstream's canonical compose (`docs/examples/docker-compose.example.yml`):

- **cobalt** — the API server (`ghcr.io/imputnet/cobalt:11`, port 9000)
- **watchtower** — auto-updates cobalt (scoped to cobalt label only)
- **yt-session-generator** (optional) — generates YouTube poToken + visitor_data to unblock YouTube throttling

The upstream Docker image is API-only — the web frontend at `cobalt.tools` is a separate Svelte app in the same monorepo (`web/`). Most self-hosters run just the API and either use the hosted `cobalt.tools` as the UI (pointing it at their API) or skip the UI and go API-direct.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (+ Watchtower) | <https://github.com/imputnet/cobalt/blob/main/docs/examples/docker-compose.example.yml> | ✅ Recommended | The upstream-blessed install. |
| `docker run` | Same image | ✅ | Throwaway test. Compose is cleaner. |
| Bare metal (Node.js 18+) | <https://github.com/imputnet/cobalt/blob/main/docs/run-an-instance.md> | ✅ | Local dev only per upstream. Production should use Docker. |
| Kubernetes | Community | ⚠️ | No upstream chart; trivial to write given stateless shape. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `bare-metal` | Drives the section. |
| preflight | "Public or private instance?" | `AskUserQuestion`: `public` / `LAN / private` | Public mandates Turnstile and/or API keys; private can skip bot protection. |
| dns | "API domain? (e.g. `api.cobalt.example.com`)" | Free-text | Set as `API_URL`. **Trailing slash required**: `https://api.example.com/`, not `https://api.example.com`. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `Caddy` / `nginx` / `Traefik` / `skip` | cobalt does not terminate TLS itself. |
| bot-protection | "Bot protection mode?" | `AskUserQuestion`: `Turnstile` / `API keys` / `both` / `none` | "None" is fine on private instances; public instances will get hammered otherwise. |
| turnstile | "Cloudflare Turnstile sitekey + secret?" | Free-text (sensitive) | Free Cloudflare account + new Turnstile widget at dash.cloudflare.com. |
| api-keys | "Path to API keys JSON?" | Free-text | `API_KEY_URL=file://keys.json` loads from disk. |
| cookies | "Cookies file for auth-gated services?" | Boolean + path | Only if downloading content that requires login (e.g. Instagram age-gated). `COOKIE_PATH=/cookies.json`. |
| yt | "Enable YouTube session generator sidecar?" | Boolean | Helps with YouTube poToken / throttling. `YOUTUBE_SESSION_SERVER=http://yt-session-generator:8080/`. |

## Install — Docker Compose (upstream-recommended)

```bash
mkdir cobalt && cd cobalt
# Download upstream's example compose
curl -O https://raw.githubusercontent.com/imputnet/cobalt/main/docs/examples/docker-compose.example.yml
mv docker-compose.example.yml docker-compose.yml
```

Edit `docker-compose.yml`:

- Replace `https://api.url.example/` with your actual API URL (with trailing slash).
- If using Turnstile / API keys / cookies, add the relevant env vars (see below).

```bash
docker compose up -d
docker compose logs -f cobalt
```

Reference — upstream's canonical compose:

```yaml
services:
  cobalt:
    image: ghcr.io/imputnet/cobalt:11
    init: true
    read_only: true
    restart: unless-stopped
    container_name: cobalt
    ports:
      - 9000:9000/tcp
      # For reverse-proxy setup, prefer:
      # - 127.0.0.1:9000:9000
    environment:
      API_URL: "https://api.url.example/"
      # COOKIE_PATH: "/cookies.json"          # if using cookies
      # TURNSTILE_SITEKEY: "..."              # from Cloudflare Turnstile
      # TURNSTILE_SECRET: "..."
      # API_KEY_URL: "file://keys.json"       # if using API keys
      # API_AUTH_REQUIRED: "1"                # enforce API keys for ALL requests
    labels:
      - com.centurylinklabs.watchtower.scope=cobalt
    # volumes:
    #   - ./cookies.json:/cookies.json

  watchtower:
    image: ghcr.io/containrrr/watchtower
    restart: unless-stopped
    command: --cleanup --scope cobalt --interval 900 --include-restarting
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

### Reverse proxy (Caddy)

```caddy
api.cobalt.example.com {
    reverse_proxy 127.0.0.1:9000
}
```

Using the web UI from `cobalt.tools` against your self-hosted API: open `cobalt.tools`, click the settings gear, paste your `API_URL`. No other configuration.

## Bot protection for public instances

Upstream strongly recommends one or both of these on public instances. Otherwise bots will saturate your bandwidth within hours.

### Option A — Cloudflare Turnstile (free)

1. Log into <https://dash.cloudflare.com/> (free account is fine).
2. Turnstile → Add widget → name it, add your domain, get sitekey + secret.
3. Set env vars:
   ```yaml
   environment:
     TURNSTILE_SITEKEY: "1x00000000000000000000BB"
     TURNSTILE_SECRET: "1x0000000000000000000000000000000AA"
   ```
4. Restart: `docker compose up -d --force-recreate cobalt`.

Users of the web UI will silently pass the challenge; bots get blocked.

Full guide: <https://github.com/imputnet/cobalt/blob/main/docs/protect-an-instance.md>.

### Option B — API keys (file://)

```json
// keys.json (mounted into the container)
{
  "your-friend": {
    "name": "alex",
    "limit": 100,
    "ips": ["203.0.113.5"]
  }
}
```

```yaml
environment:
  API_KEY_URL: "file://keys.json"
  API_AUTH_REQUIRED: "1"   # require a key for ALL requests
volumes:
  - ./keys.json:/keys.json:ro
```

Clients pass the key as `Authorization: Api-Key <key>`. See <https://github.com/imputnet/cobalt/blob/main/docs/protect-an-instance.md> and `docs/api-env-variables.md#api_key_url`.

## Key environment variables

From <https://github.com/imputnet/cobalt/blob/main/docs/api-env-variables.md>:

| Var | Default | Purpose |
|---|---|---|
| `API_URL` | *(required)* | Public-facing URL with trailing slash. |
| `API_PORT` | `9000` | Bind port inside the container. |
| `API_LISTEN_ADDRESS` | `0.0.0.0` | Bind address. `127.0.0.1` when using host networking + reverse proxy. |
| `API_INSTANCE_COUNT` | *(auto)* | Number of Node.js worker processes per container. |
| `API_REDIS_URL` | | Optional Redis for cross-instance rate limiting. |
| `COOKIE_PATH` | | Path to cookies.json for auth-gated services. |
| `TURNSTILE_SITEKEY` / `TURNSTILE_SECRET` | | Cloudflare Turnstile. |
| `API_KEY_URL` | | `file://…` or `http(s)://…` to the key registry. |
| `API_AUTH_REQUIRED` | | `1` to require a key for every request. |
| `CORS_WILDCARD` | `1` | Set to `0` + `CORS_URL=https://web.example` for tighter origin control. |
| `DURATION_LIMIT` | `10800` (3h) | Max media duration in seconds. |
| `RATELIMIT_WINDOW` / `RATELIMIT_MAX` | `60` / `20` | Per-IP rate limit: 20 requests / 60s window. |
| `DISABLED_SERVICES` | | Comma-separated list, e.g. `bilibili,youtube`. |
| `FORCE_LOCAL_PROCESSING` | `never` | Set to `always` to never redirect to upstream CDN (privacy-stronger but bandwidth-heavier). |

## Install — Bare metal (dev only per upstream)

```bash
git clone https://github.com/imputnet/cobalt
cd cobalt/api
pnpm install
cat > .env <<EOF
API_URL=http://localhost:9000/
EOF
pnpm start
```

**Ubuntu 22.04 workaround:** `ffmpeg-static` fails to resolve DNS without `nscd`:

```bash
sudo apt install nscd
sudo service nscd start
```

(See upstream issue: <https://github.com/imputnet/cobalt/issues/101#issuecomment-1494822258>.)

## Upgrade procedure

Watchtower handles this automatically when the upstream image tag updates. To upgrade manually:

```bash
docker compose pull
docker compose up -d
```

Upstream is on **major version 11** (pinned as `ghcr.io/imputnet/cobalt:11`). When v12 releases, they'll break API compatibility — you'll need to edit the image tag. Pin to the major version (`:11`) for auto-updates within that major, upgrade deliberately to the next major. Don't use `:latest`.

## Cookies file (auth-gated services)

Some services (Instagram private posts, age-gated YouTube) require login. cobalt reads cookies from a JSON file:

```json
// cookies.example.json
{
  "instagram": ["sessionid=abc..."],
  "youtube": ["VISITOR_INFO1_LIVE=xyz..."]
}
```

Example: <https://github.com/imputnet/cobalt/blob/main/docs/examples/cookies.example.json>.

**Exporting cookies** — use a browser extension like "Get cookies.txt LOCALLY" (Chrome/Firefox), then transform to cobalt's JSON format. Keep this file out of version control — it's a session-level credential.

## Gotchas

- **The downloaded-file host is YOUR IP if `FORCE_LOCAL_PROCESSING=always`.** Default behavior (`never`) is that cobalt returns a tunnel URL that the client fetches from an upstream CDN directly. If you force local processing, all bandwidth flows through your instance — which can be a LOT. Watch egress.
- **`API_URL` needs a trailing slash.** `https://api.example.com` breaks tunnel URL generation; `https://api.example.com/` works.
- **Public instance with no bot protection = bot magnet.** Inside hours you'll see anomalous traffic. Turn on Turnstile or API keys BEFORE publishing the URL anywhere.
- **Major-version pinning matters.** `:11` is upstream's recommendation; `:latest` can jump a major version and break your clients' integrations without notice.
- **`DISABLED_SERVICES`** is the nuclear option for abuse. If cobalt users are hammering one service and getting you IP-blocked, disable it and keep the rest functional.
- **Rate limits are per-IP, not per-API-key.** Behind Cloudflare / a reverse proxy, set `X-Forwarded-For` correctly at the proxy or every request will look like it's from the proxy's IP (effectively rate-limiting your whole instance as if it were one user).
- **YouTube is always fragile.** Google changes YouTube's player periodically; cobalt ships updates, but there will be windows where YouTube downloads 503. The `yt-session-generator` sidecar helps but is not a silver bullet.
- **Stateless = scales horizontally, but also = losing all in-flight downloads on restart.** If a client is mid-tunnel when Watchtower recreates the container, they get a dropped transfer. Off-peak update scheduling or a `--pause-on-healthy` flag are not built in — consider disabling Watchtower and updating manually during quiet hours.
- **`read_only: true` in the compose means no filesystem writes.** If you need to write anything (cookies, temp files), mount that path explicitly as a writable volume.
- **Ubuntu 22.04 + ffmpeg-static DNS bug.** Install `nscd` on bare metal hosts; not needed in the Docker image.
- **AGPL-3.0 obligations.** If you run a modified cobalt as a public service, you must offer the modified source to users. The official image is unmodified so hosting `:11` as-is is fine.
- **Not a piracy tool — but abuse reports happen.** DMCA complaints won't land because cobalt doesn't host content, but your IP may end up on service block lists. Nothing you can do — it's inherent to the tunneling model.

## Links

- Upstream repo: <https://github.com/imputnet/cobalt>
- Hosted: <https://cobalt.tools>
- Run-an-instance: <https://github.com/imputnet/cobalt/blob/main/docs/run-an-instance.md>
- Protect-an-instance: <https://github.com/imputnet/cobalt/blob/main/docs/protect-an-instance.md>
- Env variables: <https://github.com/imputnet/cobalt/blob/main/docs/api-env-variables.md>
- API docs: <https://github.com/imputnet/cobalt/blob/main/docs/api.md>
- Example compose: <https://github.com/imputnet/cobalt/blob/main/docs/examples/docker-compose.example.yml>
- Cookies example: <https://github.com/imputnet/cobalt/blob/main/docs/examples/cookies.example.json>
- Discord: <https://discord.gg/pQPt8HBUPu>
