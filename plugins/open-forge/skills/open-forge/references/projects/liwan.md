# Liwan

**What it is:** A lightweight, privacy-first web analytics platform. Single self-contained binary (no separate database), cookie-free, no cross-site tracking. Track pageviews and custom events across multiple websites with real-time dashboards. Written in Rust.

**Official URL:** https://github.com/explodingcamera/liwan
**Website:** https://liwan.dev
**Demo:** https://demo.liwan.dev/p/liwan.dev
**Container:** `ghcr.io/explodingcamera/liwan:latest`
**License:** Apache-2.0
**Stack:** Rust + DuckDB (embedded); tracker script <1 KB

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker / Docker Compose | Recommended |
| Any Linux VPS / bare metal | Binary (no Docker) | Single binary, no dependencies |
| Homelab (Pi, low-spec) | Binary or Docker | Lightweight; runs on Raspberry Pi |

---

## Inputs to Collect

### Pre-deployment
- `base_url` — public URL of the Liwan instance (e.g. `https://liwan.example.com`) — required for correct link generation
- `data_dir` — directory where DuckDB database and GeoIP data are stored (default: `./data`)
- Admin password — set on first run via CLI or web UI

### Runtime
- Entity name(s) — logical name per tracked website/property (used in the tracking script tag)
- Optional: MaxMind GeoIP license key for country-level analytics

---

## Software-Layer Concerns

**Docker quick start:**
```bash
docker run -d \
  --name liwan \
  -p 9042:9042 \
  -v ./liwan-data:/data \
  -e LIWAN__BASE_URL=https://liwan.example.com \
  ghcr.io/explodingcamera/liwan:latest
```

**Default port:** `9042`

**Tracking script** — add to your website's `<head>`:
```html
<script
  type="module"
  src="https://liwan.example.com/tracker.js"
  data-entity="my-site"
></script>
```

**Config:** `liwan.toml` (TOML) or environment variables prefixed with `LIWAN__` (double underscore separator). Key fields:
- `base_url` — public URL
- `data_dir` — data storage path (default: `./data`)
- `port` — listen port (default: `9042`)
- `use_forward_headers` — set `true` when behind a reverse proxy

**GeoIP:** Optional MaxMind integration for country analytics. Provide `maxmind_license_key` and edition in `[geoip]` config block.

**Reverse proxy:** Add `use_forward_headers = true` and configure `trusted_proxies` to get accurate visitor IPs behind Nginx/Caddy.

**Upgrade procedure:**
1. `docker pull ghcr.io/explodingcamera/liwan:latest`
2. `docker stop liwan && docker rm liwan`
3. Re-run with same volume mount

---

## Gotchas

- **No separate database process** — DuckDB is embedded; the `data_dir` volume is your entire database — back it up
- **`base_url` must be correct** — wrong URL causes tracker script and dashboard links to break
- **Cookie-free by design** — no consent banners needed; uses privacy-preserving fingerprinting instead
- **Multi-site support** — one Liwan instance can track multiple websites via different entity names
- **Custom events supported** — use the `liwan-tracker` JS package for non-pageview events (form submissions, clicks, etc.)
- **Behind reverse proxy** — must set `use_forward_headers = true` or all visitors will appear as the proxy IP

---

## Links
- GitHub: https://github.com/explodingcamera/liwan
- Website: https://liwan.dev
- Demo: https://demo.liwan.dev/p/liwan.dev
- Container: https://github.com/explodingcamera/liwan/pkgs/container/liwan
