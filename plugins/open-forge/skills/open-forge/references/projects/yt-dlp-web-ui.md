---
name: yt-dlp-web-ui
description: yt-dlp Web UI recipe for open-forge. Covers Docker Compose deploy. yt-dlp Web UI is a self-hosted web interface for yt-dlp that lets you download videos from YouTube and hundreds of other sites via a browser GUI rather than the command line.
---

# yt-dlp Web UI

Self-hosted web GUI for [yt-dlp](https://github.com/yt-dlp/yt-dlp), allowing you to download videos from YouTube and hundreds of other supported sites via a browser interface instead of the command line. Built with Go (backend) and React (frontend). Upstream: <https://github.com/marcopiovanello/yt-dlp-web-ui>. (Note: project is migrating to a self-hosted Gitea at <https://gitea.aidystopia.xyz/marco/yt-dlp-webui>.)

**License:** MPL-2.0 · **Language:** Go + Node.js (React) · **Default port:** 3033 · **Stars:** ~2,400

> **Migration notice:** The maintainer is migrating the project to a personal Gitea instance. The GitHub repo remains functional but check the Gitea mirror for the latest updates.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/marcopiovanello/yt-dlp-web-ui> | ✅ | **Recommended** — bundles app with yt-dlp. |
| Docker run | <https://hub.docker.com/r/marcobaobao/yt-dlp-webui> | ✅ | Quick single-container start. |
| Binary (Go) | <https://github.com/marcopiovanello/yt-dlp-web-ui/releases> | ✅ | Bare-metal without Docker (requires yt-dlp installed separately). |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| download_dir | "Host directory to save downloaded videos to? (e.g. /data/downloads)" | Free-text | All methods. |
| config_dir | "Host directory for yt-dlp-web-ui config? (e.g. /data/ytdlp-config)" | Free-text | All methods. |
| port | "Host port to expose the web UI on? (default: 3033)" | Free-text | Docker methods. |
| auth | "Enable authentication? (basic auth or token)" | AskUserQuestion | Recommended if exposed beyond localhost. |

## Install — Docker Compose

```bash
mkdir ytdlp-webui && cd ytdlp-webui

mkdir -p downloads config

cat > docker-compose.yml << 'COMPOSE'
services:
  yt-dlp-webui:
    image: marcobaobao/yt-dlp-webui
    restart: unless-stopped
    ports:
      - "3033:3033"
    volumes:
      - ./downloads:/downloads
      - ./config:/config
    healthcheck:
      test: curl -f http://localhost:3033 || exit 1
COMPOSE

docker compose up -d
```

Access the UI at `http://localhost:3033`.

### With custom configuration

Create `config/config.yml` (see upstream docs for full options):

```yaml
# yt-dlp Web UI config
downloadPath: /downloads
# yt-dlp extra args passed to every download
ytdlpFlags: "--no-playlist"
# Authentication (optional)
# auth:
#   username: admin
#   password: secret
```

## Install — Docker run

```bash
docker run -d \
  --name yt-dlp-webui \
  -p 3033:3033 \
  -v /data/downloads:/downloads \
  -v /data/ytdlp-config:/config \
  --restart unless-stopped \
  marcobaobao/yt-dlp-webui
```

## nginx reverse proxy (for HTTPS access)

```nginx
server {
    listen 443 ssl;
    server_name ytdlp.example.com;

    location / {
        proxy_pass http://127.0.0.1:3033;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| yt-dlp version | The Docker image bundles yt-dlp. yt-dlp updates frequently (video site changes) — keep the image updated to maintain download compatibility. |
| Downloads directory | Persists downloaded files. Mount a large volume — video files can be several GB each. |
| Config directory | Persists `config.yml` settings and app state. |
| No auth by default | Anyone who can reach port 3033 can initiate downloads. Add authentication in `config.yml` or restrict via nginx. |
| Disk space | Downloads accumulate — no auto-cleanup. Monitor disk usage. |
| yt-dlp site support | Supports 1000+ sites including YouTube, Vimeo, Twitch, Twitter, etc. Check <https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md>. |
| Cookies | For age-restricted or login-required content, configure `--cookies-from-browser` or a cookie file via yt-dlp flags. |
| ARM support | Multi-arch Docker image available (amd64 + arm64). |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Since yt-dlp frequently needs updates to maintain compatibility with YouTube and other sites, update regularly.

## Gotchas

- **Keep the image updated:** YouTube and other sites frequently change their APIs. yt-dlp releases updates to compensate. An outdated image will fail to download from many sources. Update at least monthly.
- **No auth by default:** The web UI has no authentication out of the box. Do not expose port 3033 to the internet without adding auth (`config.yml` auth block or nginx basic auth).
- **Project migration:** The maintainer announced migration to a personal Gitea. The GitHub repo may stop receiving updates. Check <https://gitea.aidystopia.xyz/marco/yt-dlp-webui> for latest.
- **yt-dlp legal use:** Only download content you have the right to download. Many platforms' Terms of Service prohibit automated downloading. Self-hosting doesn't exempt you from copyright law.
- **Disk management:** The UI doesn't auto-delete old downloads. Set up a cron job or manual cleanup to prevent disk from filling up.

## Upstream links

- GitHub: <https://github.com/marcopiovanello/yt-dlp-web-ui>
- Gitea mirror (maintainer's): <https://gitea.aidystopia.xyz/marco/yt-dlp-webui>
- Docker Hub: <https://hub.docker.com/r/marcobaobao/yt-dlp-webui>
- yt-dlp (the underlying tool): <https://github.com/yt-dlp/yt-dlp>
- Supported sites: <https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md>
