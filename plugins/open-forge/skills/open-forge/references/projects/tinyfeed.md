# tinyfeed

A CLI tool (and Docker image) that generates a single static HTML page from a collection of RSS, Atom, or JSON feeds. No database, no config file — just a command, a list of feed URLs, and an output HTML file. Supports custom templates and stylesheets for full visual customization. Daemon mode re-generates periodically. Ideal for a lightweight personal feed aggregator page served by any web server.

- **GitHub:** https://github.com/TheBigRoomXXL/tinyfeed
- **Docker image:** `thebigroomxxl/tinyfeed`
- **Docs:** https://feed.lovergne.dev/
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any host | Docker | Run as one-shot or daemon; no persistent state |
| Any host | Binary / Go install | Single static binary; cron or systemd for scheduling |

---

## Inputs to Collect

### Deploy Phase (CLI flags — no config file)
| Flag | Required | Description |
|------|----------|-------------|
| feed URLs | Yes | One or more RSS/Atom/JSON feed URLs as positional arguments |
| -o / --output | No | Output HTML file path (default: stdout) |
| --daemon / interval | No | Re-generate every N seconds (daemon mode) |
| --template | No | Path to custom Go template file |
| --stylesheet | No | URL or path to external CSS stylesheet |
| --order-by | No | Sort items by: date, updated, feed, author |
| --title | No | Page title |

All configuration is passed as CLI flags — there is no config file format.

---

## Software-Layer Concerns

### Config
- No config file — all options are CLI flags
- Feed list can be passed as arguments or piped

### Data Directories
- No persistent data; output is a static HTML file written to disk (or stdout)

### Ports
- None — tinyfeed only generates HTML; serving is handled by your existing web server (nginx, Caddy, Apache)

---

## Usage Examples

```bash
# One-shot: generate a feed page
docker run thebigroomxxl/tinyfeed \
  https://hnrss.org/frontpage \
  https://lobste.rs/rss \
  -o /output/index.html

# With docker, mount output directory
docker run -v $(pwd)/public:/output thebigroomxxl/tinyfeed \
  https://hnrss.org/frontpage \
  https://lobste.rs/rss \
  -o /output/index.html

# Daemon mode: regenerate every 3600 seconds
docker run -v $(pwd)/public:/output thebigroomxxl/tinyfeed \
  --daemon 3600 \
  -o /output/index.html \
  https://hnrss.org/frontpage

# Via binary (after go install)
tinyfeed -o ./public/index.html \
  https://hnrss.org/frontpage \
  https://lobste.rs/rss
```

Serve the output directory with any web server. With cron (no daemon mode):
```cron
*/30 * * * * docker run thebigroomxxl/tinyfeed https://example.com/feed -o /srv/www/feed/index.html
```

---

## Upgrade Procedure

```bash
docker pull thebigroomxxl/tinyfeed
# Re-run with same arguments
```

---

## Gotchas

- **Not a feed reader:** tinyfeed generates a static page — there's no server, no user accounts, no read/unread state, and no JavaScript required in the output
- **No config file:** All options are CLI flags; to manage many feeds, wrap in a shell script or use a process supervisor
- **Serve with a web server:** tinyfeed only generates HTML; expose the output directory via nginx, Caddy, or similar
- **Custom templates use Go template syntax:** See docs for available data fields; the generated page is fully customizable
- **OPML export:** tinyfeed includes a built-in OPML template to export your feed collection — see docs
- **User-Agent is tinyfeed/v1:** Some feeds may block unknown user agents; tinyfeed identifies itself to improve compatibility

---

## References
- GitHub: https://github.com/TheBigRoomXXL/tinyfeed
- Documentation: https://feed.lovergne.dev/
- Installation guide: https://feed.lovergne.dev/installation/
- Usage guide: https://feed.lovergne.dev/usage/
- Docker Hub: https://hub.docker.com/r/thebigroomxxl/tinyfeed
