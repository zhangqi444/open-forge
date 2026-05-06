---
name: reader
description: Recipe for reader — a Python feed reader library and web app (Atom/RSS/JSON feeds). pip install, optional Flask web UI, SQLite storage.
---

# reader

Python feed reader library and optional web application. Designed to let developers build feed reader apps without framework dependencies or boilerplate. Supports Atom, RSS, and JSON feeds with full-text search, read/unread tracking, tagging, OPML import/export, statistics, and a plugin system. Comes with an optional Flask-based web UI and a CLI. Uses SQLite for storage. Upstream: <https://github.com/lemon24/reader>. Docs: <https://reader.readthedocs.io/>.

License: BSD-3-Clause. Platform: Python 3.8+, SQLite. Port: `8080` (web app).

## Compatible install methods

| Method | When to use |
|---|---|
| pip (library only) | Embedding reader in your own Python app |
| pip with `[app]` extra | Running the built-in Flask web app |
| pip with `[cli]` extra | CLI usage |
| Docker | Containerised web app deploy |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| storage | "Path for the SQLite database file?" | Default `./db.sqlite` |
| network | "Host and port for the web app?" | Default `localhost:8080` |
| auth | "Restrict web app access (basic auth / reverse proxy)?" | No built-in auth — use a reverse proxy for public exposure |

## Library install (embedding in your app)

```bash
pip install reader
```

```python
from reader import make_reader

reader = make_reader('db.sqlite')
reader.add_feed('https://example.com/feed.rss')
reader.update_feeds()

entries = list(reader.get_entries())
print([e.title for e in entries])

# Mark as read
reader.mark_entry_as_read(entries[0])
```

## Web app (Flask UI)

```bash
# Install with web app extras
pip install reader[app]

# Serve locally on http://localhost:8080/
python -m reader web

# Or specify database and host/port
READER_DB=/data/reader.db python -m reader --db /data/reader.db web --port 8080 --host 0.0.0.0
```

## CLI

```bash
pip install reader[cli]

# Add a feed
python -m reader add https://example.com/feed.rss

# Update all feeds
python -m reader update

# List unread entries
python -m reader list --unread
```

## Docker (community pattern)

reader does not publish an official Docker image. Minimal pattern:

`Dockerfile`:
```dockerfile
FROM python:3.12-slim
RUN pip install reader[app]
EXPOSE 8080
VOLUME ["/data"]
ENV READER_DB=/data/reader.db
CMD ["python", "-m", "reader", "--db", "/data/reader.db", "web", "--host", "0.0.0.0", "--port", "8080"]
```

```bash
docker build -t reader .
docker run -d -p 8080:8080 -v $(pwd)/data:/data reader
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | SQLite (single file) — persist this file |
| Default port | `8080` (web app) |
| Feed update | Manual via CLI/code or scheduled via cron/Celery |
| Search | Full-text search built-in (SQLite FTS5) |
| OPML | Import/export supported via CLI and API |
| Plugins | Extend via Python callables; see docs |
| No built-in auth | Web app has no login. Place behind nginx with basic auth or VPN |

## Scheduled feed updates (cron)

```cron
# Update all feeds every 30 minutes
*/30 * * * * /usr/local/bin/python -m reader --db /data/reader.db update
```

## Upgrade procedure

```bash
pip install --upgrade reader
# No DB migration needed — reader handles schema upgrades automatically
```

## Gotchas

- **No built-in authentication**: The web app serves feeds to anyone who can reach it on the network. Do not expose port 8080 publicly without a reverse proxy adding authentication.
- **Manual or cron-based feed updates**: reader does not run a background fetcher by default. You must call `reader.update_feeds()` (in code), run `python -m reader update` (CLI), or schedule it via cron/systemd timer.
- **SQLite concurrent writes**: reader uses SQLite; if you run both the web app and frequent background updates simultaneously, SQLite's write locking may cause brief waits. For very high-frequency updates, this is a consideration.
- **Library vs. app**: reader is primarily a library. The web UI is deliberately minimal and opinionated. If you want a full-featured read-later app with polish, consider Miniflux or FreshRSS instead.
- **Python version**: Requires Python 3.8+. Recommended: Python 3.11 or later.

## Upstream links

- Source: <https://github.com/lemon24/reader>
- Docs: <https://reader.readthedocs.io/>
- PyPI: <https://pypi.org/project/reader/>
- CLI reference: <https://reader.readthedocs.io/en/latest/cli.html>
- Web app docs: <https://reader.readthedocs.io/en/latest/app.html>
