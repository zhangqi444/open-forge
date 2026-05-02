# Jellyfin Rewind

A Spotify Wrapped-style year-in-review for your Jellyfin media server. Loads your music playback stats directly from Jellyfin, processes everything client-side, and generates an animated summary of your listening year — top artists, albums, tracks, listening trends. No data leaves your device. Works best with the Playback Reporting plugin installed on Jellyfin. Available as a hosted web app or self-hostable Docker container/static files.

- **GitHub:** https://github.com/Chaphasilor/jellyfin-rewind
- **Docker image:** `chaphasilor/jellyfin-rewind` (DockerHub)
- **Public instance (HTTPS):** https://jellyfin-rewind.netlify.app
- **Public instance (HTTP):** http://jellyfin-rewind-http.chaphasilor.xyz
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker run | Single container; port 80; no persistent data |
| Any web server | Static files | Extract zip from GitHub Releases, serve with nginx/Apache |
| None | Public hosted | Use netlify.app or HTTP instance — no self-hosting needed for internet-accessible Jellyfin |

---

## Inputs to Collect

### Runtime (entered in the web UI — not config files)
| Input | Required | Description |
|-------|----------|-------------|
| Jellyfin server URL | Yes | Full URL to your Jellyfin instance (e.g. https://jellyfin.example.com) |
| Jellyfin username | Yes | Your Jellyfin account username |
| Jellyfin password | Yes | Your Jellyfin account password |

No environment variables or config files required — everything is entered interactively in the browser.

---

## Software-Layer Concerns

### Architecture
- Purely client-side SPA (static HTML/JS)
- Talks directly to the Jellyfin API from the browser
- No backend, no database, no server-side state

### Data Directories
- No persistent volumes needed

### Ports
- 80 — Static web server

---

## Minimal docker run

```bash
docker run -d --name jellyfin-rewind -p 8080:80 chaphasilor/jellyfin-rewind
# Access at http://localhost:8080
```

Or with Docker Compose:
```yaml
services:
  jellyfin-rewind:
    image: chaphasilor/jellyfin-rewind
    container_name: jellyfin-rewind
    ports:
      - "8080:80"
    restart: unless-stopped
```

Or use the public instances if your Jellyfin is internet-accessible — no self-hosting needed at all.

---

## Upgrade Procedure

```bash
docker pull chaphasilor/jellyfin-rewind
docker compose up -d jellyfin-rewind
```

No data to migrate; fully stateless.

---

## Gotchas

- **Browser security rules limit connections:** Browsers block mixed-content (HTTPS page → HTTP Jellyfin) and cross-origin-isolated requests (HTTPS page → local IP); self-host Jellyfin Rewind on the same network as your Jellyfin server to avoid these restrictions
- **HTTPS Jellyfin + HTTPS Rewind = best experience:** Both accessible over the internet with HTTPS is the smoothest setup; use the public netlify.app instance in this case
- **Local Jellyfin = must self-host Rewind locally:** If Jellyfin uses a local IP (192.168.x.x) or mDNS (.local), self-host Jellyfin Rewind on the same local network
- **Playback Reporting plugin greatly improves stats:** Install the Playback Reporting plugin on your Jellyfin server for richer data; without it statistics are limited to Jellyfin's basic built-in tracking
- **Download your Rewind report:** At the end of the Rewind session, download the generated report JSON — it can enhance next year's stats
- **Seasonal app:** Jellyfin Rewind is designed as an end-of-year event (typically December 31st); releases are annual
- **Music-focused:** Primarily designed for music listening stats; video/movie stats may be limited

---

## References
- GitHub: https://github.com/Chaphasilor/jellyfin-rewind
- GitHub Releases (Docker image tags + zip archives): https://github.com/Chaphasilor/jellyfin-rewind/releases
- DockerHub: https://hub.docker.com/r/chaphasilor/jellyfin-rewind
