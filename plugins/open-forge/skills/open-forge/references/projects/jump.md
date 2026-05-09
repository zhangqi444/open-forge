---
name: jump
description: jump recipe for open-forge. Covers Docker Compose and Docker CLI deploy for this self-hosted startpage and real-time server status page. Source: https://github.com/daledavies/jump. License: MIT.
---

# Jump

Self-hosted startpage and real-time status page for your server. Designed to be simple, stylish, fast, and secure. Written in PHP 8.1+; ships as a Docker container. Upstream: <https://github.com/daledavies/jump>. Docker Hub: <https://hub.docker.com/r/daledavies/jump>.

Jump displays a customisable list of bookmarks with real-time availability monitoring, auto-fetched favicons, tag-based multi-page navigation, a search box with configurable search engines, and optional integrations for Open Weather Map and Docker autodiscovery. Serves on port 8080 internally; map to any host port.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended. Persistent, with volume-mapped config dirs. |
| Docker CLI | Quick start without a Compose file. |
| Kubernetes (Helm) | Community-maintained Helm chart; see note below. |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "What host port should Jump be served on?" (default: 8123) | All Docker methods |
| preflight | "Custom site name?" (optional, defaults to empty) | Optional |
| weather | "Open Weather Map API key? (leave blank to skip weather)" | Optional |
| weather | "Latitude and longitude for your location? (e.g. 51.509865,-0.118092)" | Required if using OWM |

---

## Method — Docker Compose

> **Source:** <https://github.com/daledavies/jump#docker-compose>

### docker-compose.yml

```yaml
services:
  jump:
    image: daledavies/jump:latest
    container_name: jump
    restart: unless-stopped
    ports:
      - "8123:8080"
    volumes:
      - ./backgrounds:/backgrounds
      - ./favicon:/favicon
      - ./search:/search
      - ./sites:/sites
    environment:
      SITENAME: "My Server"
      # OWMAPIKEY: "your-openweathermap-api-key"
      # LATLONG: "51.509865,-0.118092"
      # CHECKSTATUS: "true"     # enable real-time site status checks (default)
      # SHOWCLOCK: "true"       # show clock (default)
      # NOINDEX: "true"         # robots noindex (default)
```

```bash
docker compose up -d jump
```

On first start, Jump populates the mounted volume directories with default files (background images, default `sites.json`, default `search.json`). Edit these files to customise your startpage.

---

## Method — Docker CLI

> **Source:** <https://github.com/daledavies/jump#docker>

```bash
docker run -d \
  --name jump \
  --restart unless-stopped \
  -p 8123:8080 \
  --volume "$(pwd)/backgrounds":/backgrounds \
  --volume "$(pwd)/favicon":/favicon \
  --volume "$(pwd)/sites":/sites \
  --volume "$(pwd)/search":/search \
  --env SITENAME="My Server" \
  --env OWMAPIKEY="your-openweathermap-api-key" \
  --env LATLONG="51.509865,-0.118092" \
  docker.io/daledavies/jump
```

---

## Configuration

### Adding sites (sites/sites.json)

Edit `./sites/sites.json` to define your bookmarks. Jump creates a default file on first start:

```json
{
    "default": {
        "nofollow": true,
        "newtab": false
    },
    "sites": [
        {
            "name": "Jellyfin",
            "url": "https://jellyfin.example.com",
            "icon": "jellyfin.png",
            "tags": ["media"]
        },
        {
            "name": "Nextcloud",
            "url": "https://cloud.example.com",
            "tags": ["home", "files"]
        },
        {
            "name": "Gitea",
            "url": "https://git.example.com",
            "nofollow": false,
            "newtab": true
        }
    ]
}
```

Place custom icons in the `./favicon/` volume directory. Jump also auto-fetches favicons from the upstream site if no local icon is specified.

### Custom search engines (search/search.json)

Edit `./search/search.json` to override the default list of search engines accessible from the search box.

### Docker autodiscovery

Jump can automatically list running Docker containers as sites without `sites.json`. Mount the Docker socket and set `DOCKERSOCKET`:

```yaml
environment:
  DOCKERSOCKET: /var/run/docker.sock
  DOCKERONLYSITES: "true"    # omit sites.json entirely
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Label containers with `jump.url`, `jump.name`, `jump.icon`, `jump.description`, and `jump.tags` to control how they appear. See <https://github.com/daledavies/jump#docker-integration> for the full label reference.

Alternatively, use a Docker proxy (e.g. Tecnativa/docker-socket-proxy) and set `DOCKERPROXYURL` instead of `DOCKERSOCKET`. `DOCKERSOCKET` and `DOCKERPROXYURL` are mutually exclusive.

---

## Verify

```bash
curl -sI http://localhost:8123/    # should return HTTP 200
```

Open `http://<host>:8123` in a browser to see the startpage.

---

## Lifecycle

```bash
docker compose pull jump           # update image
docker compose up -d jump          # restart with new image
docker compose logs -f jump        # tail logs
docker compose stop jump           # stop
```

---

## Key environment variables

| Variable | Default | Description |
|---|---|---|
| `SITENAME` | `""` | Custom site name shown in the header. |
| `SHOWCLOCK` | `true` | Show the clock widget. |
| `AMPMCLOCK` | `false` | Use 12-hour clock format. |
| `SHOWGREETING` | `true` | Show the greeting message (good morning/evening). |
| `CUSTOMGREETING` | — | Override the greeting text. |
| `SHOWSEARCH` | `true` | Show the search box. |
| `ALTLAYOUT` | `false` | Use the alternative site list layout. |
| `BGBLUR` | — | Background image blur percentage (e.g. `50`). |
| `BGBRIGHT` | — | Background image brightness percentage (e.g. `90`). |
| `UNSPLASHAPIKEY` | — | Unsplash API key for random background images. |
| `OWMAPIKEY` | — | Open Weather Map API key for weather. Requires `LATLONG`. |
| `LATLONG` | — | Default location latitude/longitude (e.g. `51.509865,-0.118092`). |
| `METRICTEMP` | `true` | Metric (°C) temperature. Set `false` for Fahrenheit. |
| `CHECKSTATUS` | `true` | Enable real-time site availability monitoring. |
| `STATUSCACHE` | — | Duration in minutes to cache status results. |
| `NOINDEX` | `true` | Include robots `noindex` meta tag. |
| `DOCKERSOCKET` | — | Docker socket path for Docker autodiscovery (e.g. `/var/run/docker.sock`). |
| `DOCKERPROXYURL` | — | Docker proxy URL for autodiscovery (mutually exclusive with `DOCKERSOCKET`). |
| `DOCKERONLYSITES` | `false` | Use only Docker autodiscovery; ignore `sites.json`. |
| `LANGUAGE` | `en` | Language code for the UI. |
| `CACHEBYPASS` | `false` | Bypass all caches (for testing). |

---

## Kubernetes (Helm)

A community-maintained Helm chart is available at <https://artifacthub.io/packages/helm/djjudas21/jump>. The chart supports all the same environment variables plus a YAML-based site and search configuration (no need to mount `sites.json`/`search.json` as volume files). See the chart's `values.yaml` for details.

```bash
helm repo add djjudas21 https://djjudas21.github.io/charts/
helm install my-jump djjudas21/jump -f values.yaml
```

---

## Gotchas

- **Volume directories are populated on first start.** If a volume mount target is empty, Jump copies in default files. If the directory already has files, Jump uses yours. Don't mount a non-empty host directory that you want Jump to initialise — move the files out first.
- **`OWMAPIKEY` and `LATLONG` must be set together.** Setting one without the other causes the weather integration to fail silently.
- **`DOCKERSOCKET` and `DOCKERPROXYURL` are mutually exclusive.** Set exactly one if you use Docker autodiscovery.
- **Custom icons go in the `./favicon/` volume directory,** not inside the container. Use filenames that match the `"icon"` field in `sites.json`.
- **Status checks are per-site HTTP probes.** Jump issues a GET or HEAD request to each site URL; the indicator goes red if the host does not respond within a timeout. This is not a ping — it requires the service to be reachable over HTTP(S) from the Jump container.
