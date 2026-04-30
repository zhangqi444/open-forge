---
name: Logdy
description: "Lightweight single-binary log viewer that works like grep/awk/sed/jq but with web UI. Zero-dependency Go binary. Runs locally. Multiple input modes (files/stdin/sockets/REST). TypeScript-typed custom parsers. Go library API. MIT. logdyhq org."
---

# Logdy

Logdy is **"grep/awk/sed/jq — but with a web UI + real-time viewing + TypeScript-typed custom parsers"** — a lightweight single-binary log viewer. Pipe logs to it (`tail -f file | logdy`), open browser, see them in a filterable UI. **Runs entirely locally** — security + privacy. **Multiple input modes**: files, stdin, sockets, REST API. **Custom parsers + columns** with TypeScript type-support (in-browser code editor with types!). Also **usable as a Go library**.

Built + maintained by **Logdy HQ org / logdyhq**. License: **MIT**. Active (v0.17.0 Jun 2025); webpage + blog + demo + docs; CI-tested.

Use cases: (a) **real-time log-tail-UI** — `tail -f` but better (b) **debug-session companion** — visual filters (c) **CI-log viewer** — pipe stdin (d) **developer-tool for tailing files** (e) **REST-API log ingestion** — apps send logs in (f) **stdin-from-program** — quick visual debugging (g) **Go library** — embed into your Go app (h) **jq-for-JSON-logs with UI** — TypeScript parser for columns.

Features (per README):

- **Zero-dependency single binary**
- **Embedded Web UI**
- **Real-time viewing + filtering**
- **Secure local operation** (no network required)
- **Multiple input modes**: files, stdin, sockets, REST API
- **Custom parsers** with TypeScript + types
- **Go library** API
- **CI-tested**

- Upstream repo: <https://github.com/logdyhq/logdy-core>
- Webpage: <https://logdy.dev>
- Demo: <https://demo.logdy.dev>
- Docs: <https://logdy.dev/docs/quick-start>
- Blog: <https://logdy.dev/blog>

## Architecture in one minute

- **Go** single binary
- **Embedded web UI** (Vue.js or similar; bundled in binary)
- **Optional in-browser TypeScript parser-editor**
- **Resource**: tiny — <50MB RAM
- **Port**: 8080 (default)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary**         | **Single file**                                                 | **Primary**                                                                        |
| **Go library**     | Embed in app                                                                                                           | Alt                                                                                   |
| **Docker**         | Community                                                                                                              | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Input mode           | file / stdin / socket / REST                                | Config       |                                                                                    |
| Port                 | 8080 default                                                | Network      |                                                                                    |
| Custom parser (opt)  | TypeScript                                                  | Config       | Define columns                                                                                    |

## Install

```sh
# Download binary
curl -L https://github.com/logdyhq/logdy-core/releases/latest/download/logdy-linux-amd64 -o logdy
chmod +x logdy

# Use cases:
tail -f /var/log/app.log | ./logdy
./logdy follow /var/log/app.log --full-read
./logdy socket 1234  # listen on tcp:1234
./logdy rest-api     # POST logs to HTTP endpoint
```

## First boot

1. Download binary
2. Pipe any log source: `command | logdy`
3. Open browser at `http://localhost:8080`
4. Define custom parser for structured logs (if JSON)
5. Use filters + columns
6. Stop with Ctrl-C when done (usually ad-hoc use)

## Data & config layout

- **Ephemeral by default** — no persistence unless you enable it
- Optional saved-parser files

## Backup

**No persistent data** — ad-hoc tool.

## Upgrade

1. Releases: <https://github.com/logdyhq/logdy-core/releases>. Active (v0.17.0 Jun 2025).
2. Download new binary; replace

## Gotchas

- **131st HUB-OF-CREDENTIALS Tier 4/ZERO — LOCAL-ONLY EPHEMERAL**:
  - Logs in-memory during session
  - No persistence
  - BUT: logs flowing through may contain secrets
  - **131st tool in hub-of-credentials family — Tier 4/ZERO**
  - **Zero-credential-hub-tool Tier 4/ZERO: 3 tools** (MAZANOKE+Chitchatter+Logdy) 🎯 **3-TOOL MILESTONE**
- **LOCAL-ONLY SECURITY PROMISE**:
  - README emphasizes "runs entirely locally"
  - Web UI on localhost
  - Don't expose port publicly (logs may contain secrets)
  - **Recipe convention: "localhost-only-binding-discipline callout"** — critical
  - **NEW recipe convention** (Logdy 1st formally)
- **LOG-CONTENT-SECRET-SPILLOVER**:
  - Logs often contain tokens, PII, internal URLs
  - Applies to ALL log-viewing tools
  - **Recipe convention: "log-content-secret-spillover callout"** — reinforces Parseable (113)
  - **Sub-family: "log-tooling-secret-spillover"** — now 2 tools (Parseable+Logdy)
- **IN-BROWSER TYPESCRIPT EDITOR**:
  - Code-editor with type-support in browser
  - Novel feature for log-tools
  - **Recipe convention: "in-browser-TypeScript-editor positive-signal"**
  - **NEW positive-signal convention** (Logdy 1st formally)
- **GO-LIBRARY EMBEDDING**:
  - Use as library in your Go app
  - Embedded logdy for your app's logs
  - **Recipe convention: "dual-binary-plus-library positive-signal"**
  - **NEW positive-signal convention** (Logdy 1st formally)
- **ZERO-DEPENDENCY-SINGLE-BINARY**:
  - No install, no deployment, just download
  - **Zero-dependency-single-binary: 1 tool** 🎯 **NEW MILESTONE**
  - **Recipe convention: "zero-dependency-single-binary positive-signal"**
  - **NEW positive-signal convention** (Logdy 1st formally)
  - Strongest version of "single-binary" we've seen
- **MULTIPLE INPUT MODES**:
  - files, stdin, sockets, REST API
  - 4 modes = flexibility
  - **Recipe convention: "multi-input-mode-flexibility positive-signal"**
  - **NEW positive-signal convention** (Logdy 1st formally)
- **AD-HOC TOOL (NOT DAEMON)**:
  - Used during debug-session; not long-running
  - Different ops-model from services
  - **Recipe convention: "ad-hoc-tool-not-daemon neutral-signal"**
  - **NEW neutral-signal convention** (Logdy 1st formally)
- **MIT-LICENSE**:
  - Permissive; encourages library-embedding
- **STATELESS-TOOL-RARITY**:
  - No state during or after
  - **Stateless-tool-rarity: 13 tools** (+Logdy) 🎯 **13-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: Logdy HQ org + webpage + docs + blog + demo + CI + MIT. **117th tool — commercial-org-developer-tool sub-tier** (soft-new; reuses prior patterns).
- **TRANSPARENT-MAINTENANCE**: active + webpage + blog + docs + demo + CI + releases. **123rd tool in transparent-maintenance family.**
- **LOG-VIEWER-CATEGORY:**
  - **Logdy** — Go binary; web UI; TypeScript parsers
  - **lnav** (The Logfile Navigator) — curses/TUI; mature
  - **GoAccess** — log-analyzer; web-report output
  - **Dozzle** — Docker-logs UI
  - **Grafana Loki + Explore** — persistent-query
- **ALTERNATIVES WORTH KNOWING:**
  - **lnav** — if you prefer terminal-TUI
  - **GoAccess** — if you want static-report output
  - **Dozzle** — if you only need Docker-container logs
  - **Choose Logdy if:** you want web-UI + ad-hoc + TypeScript-parsers + Go-library option.
- **PROJECT HEALTH**: active (v0.17.0 June 2025) + webpage + blog + MIT. Strong.

## Links

- Repo: <https://github.com/logdyhq/logdy-core>
- Website: <https://logdy.dev>
- Demo: <https://demo.logdy.dev>
- lnav (alt): <https://github.com/tstack/lnav>
- Dozzle (alt): <https://github.com/amir20/dozzle>
