---
name: bittorrent-tracker-project
description: bittorrent-tracker recipe for open-forge. Covers Node.js CLI server as documented at https://github.com/webtorrent/bittorrent-tracker.
---

# bittorrent-tracker

Simple, robust BitTorrent tracker (client and server) implementation in Node.js. Supports HTTP, UDP (BEP 15), and WebSocket (WebTorrent) tracker protocols. Includes a built-in web stats UI at `/stats`. Upstream: <https://github.com/webtorrent/bittorrent-tracker>. Part of the WebTorrent project: <https://webtorrent.io/>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| npm global CLI | <https://github.com/webtorrent/bittorrent-tracker#usage> | Quick server on any Node.js host |
| Node.js API (programmatic) | <https://github.com/webtorrent/bittorrent-tracker#server> | Embed in a Node app with custom filter/auth logic |

> Note: No official Docker image is published by upstream. Community Docker images exist but are not maintained by the project.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should the tracker listen on?" | Number (default `8000`) | HTTP and WebSocket share the same port; UDP uses the same port number independently |
| preflight | "Enable HTTP tracker?" | Yes/No (default yes) | `--http` flag |
| preflight | "Enable UDP tracker?" | Yes/No (default yes) | `--udp` flag |
| preflight | "Enable WebSocket (WebTorrent) tracker?" | Yes/No (default yes) | `--ws` flag |
| preflight | "Client announce interval (ms)?" | Number (default `600000` = 10 min) | `--interval` flag |
| proxy | "Behind a reverse proxy? (trust X-Forwarded-For?)" | Yes/No | `--trust-proxy` flag |

## CLI usage (from upstream README)

Install globally:
```bash
npm install -g bittorrent-tracker
```

Start with all tracker types:
```bash
bittorrent-tracker --port 8000
```

Start with specific types:
```bash
bittorrent-tracker --http --udp --ws --port 8000
```

View all options:
```bash
bittorrent-tracker --help
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Ports | HTTP + WebSocket on TCP `<port>`; UDP tracker also on `<port>`. Expose all three if needed. |
| Stats UI | Available at `http://<host>:<port>/stats` (HTML) or `/stats.json` (JSON). No auth — protect with reverse proxy if public-facing. |
| Announce interval | Default 10 min (600 000 ms). Lower values increase tracker load; raise for large swarms. |
| Torrent filtering | Implement a `filter(infoHash, params, cb)` function in the Node.js API to whitelist/blacklist torrents or implement private tracker logic. Not available via CLI. |
| Persistence | The tracker stores peer state in-memory only. Peers re-announce on restart. No disk persistence by design. |
| Reverse proxy | Set `--trust-proxy` when behind Nginx/Caddy; without it, all peers appear to come from the proxy IP. |

## Upgrade procedure

Per <https://github.com/webtorrent/bittorrent-tracker/releases>:

1. `npm install -g bittorrent-tracker@latest`
2. Restart the tracker process (peers will re-announce within one interval).

## Gotchas

- **UDP port must be TCP-open too**: some firewalls block UDP `8000` even when TCP `8000` is allowed. Open both protocols.
- **No built-in TLS**: run behind Nginx/Caddy for HTTPS. WebSocket clients need `wss://` if the front-end is HTTPS.
- **In-memory only**: restarting the tracker drops all peer records. Clients will re-register at their next announce cycle (up to `interval` ms later).
- **No official Docker image**: upstream does not publish one. If containerizing, pin to a specific npm version tag.
- **Private tracker**: filtering requires the Node.js programmatic API — the CLI does not expose a filter hook.

## Links

- Upstream README: <https://github.com/webtorrent/bittorrent-tracker>
- npm package: <https://www.npmjs.com/package/bittorrent-tracker>
- WebTorrent project: <https://webtorrent.io/>
- BEP 15 (UDP tracker protocol): <http://www.bittorrent.org/beps/bep_0015.html>
