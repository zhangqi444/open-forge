---
name: cup
description: Cup recipe for open-forge. Covers Docker (server mode) and binary installs for this lightweight Docker container image update checker. Source: https://github.com/sergi0g/cup. Docs: https://cup.sergi0g.dev/docs.
---

# Cup

Lightweight, blazing-fast tool to check whether your running Docker containers have newer upstream image versions available. Ships a CLI and an optional persistent web server. Written in Rust; single ~5 MB binary. Upstream: <https://github.com/sergi0g/cup>. Docs: <https://cup.sergi0g.dev/docs>.

Cup reads the Docker socket, queries the relevant registries (Docker Hub, ghcr.io, Quay, lscr.io, Gitea, and others), and reports which images have patch/minor/major updates waiting. It intentionally does **not** trigger automatic updates — use a cron job or the `/api/v3/json` endpoint to feed your own automation.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker — server (web UI + API) | Run persistently alongside your stack; dashboard on `:8000`; JSON API for integrations. |
| Docker — one-shot CLI | Run on demand to print a report; no persistent process. |
| Binary | Prefer a native binary with no Docker overhead. |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which install method — Docker server, Docker CLI, or binary?" | Drives which section below |
| server | "Which host port should the Cup web UI bind to?" (default: `8000`) | Docker server method |
| server | "Enable basic auth? If so, provide a username and password." | Optional for Docker server method |

---

## Method — Docker server (web UI + API)

> **Source:** <https://cup.sergi0g.dev/docs/installation/docker> and <https://cup.sergi0g.dev/docs/usage/server>.

Runs `cup serve` inside a container. Exposes a web dashboard and a JSON API endpoint.

### docker run

```bash
docker run -d \
  --name cup \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -p 8000:8000 \
  ghcr.io/sergi0g/cup \
  serve
```

Access the dashboard at `http://<host>:8000`.

The JSON API is available at `http://<host>:8000/api/v3/json` — useful for feeding dashboards (e.g. Homepage widget) or triggering downstream actions via a cron job or webhook.

### docker-compose.yml

```yaml
services:
  cup:
    image: ghcr.io/sergi0g/cup
    container_name: cup
    restart: unless-stopped
    command: serve
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "8000:8000"
```

### Use a different port

Pass `-p` to `serve`:

```bash
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -p 9000:9000 \
  ghcr.io/sergi0g/cup \
  serve -p 9000
```

Or in Compose:

```yaml
command: serve -p 9000
ports:
  - "9000:9000"
```

### Verify

```bash
curl http://localhost:8000/api/v3/json    # should return JSON update report
```

### Lifecycle

```bash
docker pull ghcr.io/sergi0g/cup          # update
docker restart cup                        # restart
docker logs -f cup                        # logs
```

---

## Method — Docker one-shot CLI

> **Source:** <https://cup.sergi0g.dev/docs/usage/cli>.

Run a single update check and print results to stdout. No persistent container.

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/sergi0g/cup \
  check
```

For JSON output (useful in scripts):

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/sergi0g/cup \
  check -r
```

Pipe into `jq` to extract only images with pending updates:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  ghcr.io/sergi0g/cup \
  check -r | jq '[.images[] | select(.has_update)]'
```

---

## Method — Binary

> **Source:** <https://cup.sergi0g.dev/docs/installation/binary>.

Download the pre-built binary from the [latest GitHub release](https://github.com/sergi0g/cup/releases/latest) for your platform (Linux x86_64, ARM64, ARMv7; macOS; Windows).

```bash
# Example: Linux x86_64
LATEST=$(curl -sI https://github.com/sergi0g/cup/releases/latest | awk -F'tag/' '/location/{print $2}' | tr -d '\r')
curl -Lo cup "https://github.com/sergi0g/cup/releases/download/${LATEST}/cup-x86_64-unknown-linux-musl"
chmod +x cup
sudo mv cup /usr/local/bin/

cup check            # one-shot report
cup serve            # persistent server on :8000
```

---

## Configuration

Cup is configured via a `cup.json` file. Mount it into the container at `/cup.json`.

### Example cup.json

```json
{
  "server": {
    "theme": "dark"
  },
  "images": {
    "ignore": ["registry.example.com/*"]
  }
}
```

Key configuration options (see <https://cup.sergi0g.dev/docs/configuration> for the full reference):

| Key | Purpose |
|---|---|
| `server.theme` | Web UI theme: `light` / `dark` / `system` |
| `images.ignore` | Glob patterns for images to exclude from checks |
| `images.include` / `images.exclude` | Fine-grained include/exclude lists |
| `registries.auth` | Registry credentials for private images |
| `server.username` / `server.password` | Basic auth for the web UI |

Mount the config file:

```bash
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /path/to/cup.json:/cup.json:ro \
  -p 8000:8000 \
  ghcr.io/sergi0g/cup \
  serve
```

---

## Integrations and community resources

- **Homepage widget** — <https://cup.sergi0g.dev/docs/community-resources/homepage-widget>
- **Home Assistant sensor** — <https://cup.sergi0g.dev/docs/community-resources/home-assistant>
- **Docker Compose examples** — <https://cup.sergi0g.dev/docs/community-resources/docker-compose>
- **JSON API** — `GET /api/v3/json` returns the full update report; suitable for Uptime Kuma custom monitors, n8n automations, etc.
- **Agent mode** — multi-host setup where one Cup instance acts as an agent feeding a central server. See <https://cup.sergi0g.dev/docs/configuration/agent>.

---

## Gotchas

- **Cup only reports; it does not apply updates.** Run `docker pull` + `docker compose up -d` separately (or use Watchtower / Diun) to actually update.
- **Docker socket access.** Mount the socket read-only (`ro`). If running rootless Docker, adjust the socket path accordingly.
- **Rate limits.** Cup is designed to minimise registry API calls and avoid exhausting Docker Hub pull limits. Avoid running `cup check` on a tight cron schedule for large fleets.
- **Registry credentials for private images.** Add auth tokens under `registries.auth` in `cup.json`. See <https://cup.sergi0g.dev/docs/configuration>.
- **NOTICE.md.** The project README links to a `NOTICE.md` with development updates; check it if the project status changes.
