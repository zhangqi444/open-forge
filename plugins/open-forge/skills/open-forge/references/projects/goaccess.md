---
name: goaccess-project
description: GoAccess recipe for open-forge. Covers Docker and binary/package install as documented at https://goaccess.io/get-started.
---

# GoAccess

Real-time web log analyzer and interactive viewer. Runs as a terminal UI or serves a live HTML dashboard via WebSocket. Written in C — single binary with minimal dependencies. Supports Apache, Nginx, Amazon S3, ELB, CloudFront, and any custom log format. Upstream: <https://github.com/allinurl/goaccess>. Official site: <https://goaccess.io/>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker | <https://hub.docker.com/r/allinurl/goaccess> | Easiest path; no C build environment needed |
| Package manager (apt/yum/brew) | <https://goaccess.io/download> | Native install on Debian/Ubuntu/RHEL/macOS |
| Build from source | <https://goaccess.io/get-started> | Latest features or custom `--with-*` compile flags |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Where are your web server access logs?" | Host path | Bind-mounted into container at `/srv/logs` |
| preflight | "What is the log format?" | Choice: COMBINED / VCOMBINED / COMMON / CLF / W3C / CLOUDFRONT / AWSS3 / CUSTOM | Most Nginx and Apache setups use `COMBINED` |
| preflight | "Output mode?" | Choice: live HTML dashboard / static HTML file / terminal | Live mode needs WebSocket port open; static just writes a file |
| preflight | "Which port for the live HTML dashboard?" | Number (default `7890`) | Only needed for real-time HTML output |

## Docker — live HTML dashboard (from upstream docs)

```bash
docker run --rm -it \
  -p 7890:7890 \
  -v /var/log/nginx:/srv/logs:ro \
  allinurl/goaccess \
  --no-global-config \
  --log-format=COMBINED \
  /srv/logs/access.log \
  --real-time-html \
  --port=7890 \
  --ws-url=ws://yourdomain.com:7890 \
  --output=/dev/stdout
```

Visit `http://localhost:7890` for the live dashboard.

## Docker — static HTML report

```bash
docker run --rm \
  -v /var/log/nginx:/srv/logs:ro \
  -v $(pwd)/report:/srv/report \
  allinurl/goaccess \
  --no-global-config \
  --log-format=COMBINED \
  /srv/logs/access.log \
  --output=/srv/report/index.html
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Log access | Mount log directory read-only (`ro`) into the container at `/srv/logs` |
| Log format | Must match your webserver's actual log format. Nginx default is `COMBINED`; W3C IIS logs use `W3C`. |
| Real-time mode | Uses a built-in WebSocket server (`--port=<n>`). Set `--ws-url=ws://<host>:<port>` to match the public URL. |
| Persistence | GoAccess can persist parsed data to disk with `--persist` and `--restore` flags (on-disk DB). Useful for incremental log processing. |
| Config file | `/etc/goaccess/goaccess.conf` — set defaults here to avoid long CLI flags. |
| WebSocket auth | JWT-based auth supported via `--ws-auth-token` and external JWT verification for production dashboards. |
| Multiple logs | Pass multiple log files: `goaccess access.log access.log.1 access.log.2.gz ...` — GoAccess handles gzipped files natively. |

## Upgrade procedure

Per <https://goaccess.io/download>:

**Docker:** `docker pull allinurl/goaccess` then relaunch with the same flags.

**Package manager:**
- Debian/Ubuntu: `sudo apt-get update && sudo apt-get install goaccess`
- macOS: `brew upgrade goaccess`

No database migrations — GoAccess on-disk persistence uses its own flat format; reparsing from logs is always safe.

## Gotchas

- **`--ws-url` must match the public URL**: if behind a reverse proxy, set `--ws-url` to the public WebSocket URL (`wss://your-domain.com/ws`), not `localhost`. Without this, the browser's WebSocket connection will fail.
- **Log rotation**: in real-time mode, GoAccess does not auto-follow rotated log files. Use `--log-format` + a fresh run after rotation, or pipe via `tail -f`.
- **Multiple virtual hosts**: use `--virtual-hosts` flag to break down stats per vhost.
- **Large logs**: parsing multi-GB log files can take minutes the first time. Use `--persist` + `--restore` to cache parsed state.
- **`--no-global-config` in Docker**: without this flag, GoAccess tries to read `/etc/goaccess/goaccess.conf` which doesn't exist in the container image — causing a confusing error.

## Links

- Upstream README: <https://github.com/allinurl/goaccess>
- Official site & docs: <https://goaccess.io/>
- Man page: <https://goaccess.io/man>
- Docker Hub: <https://hub.docker.com/r/allinurl/goaccess>
- Download/install: <https://goaccess.io/download>
