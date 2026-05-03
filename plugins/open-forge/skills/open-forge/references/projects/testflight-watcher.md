---
name: testflight-watcher-project
description: Monitors Apple TestFlight beta slots and sends Pushover notifications when seats become available. Upstream: https://github.com/MaximilianGT500/testflight-watcher
---

# TestFlight Watcher

Monitors Apple TestFlight beta programs and sends push notifications via [Pushover](https://pushover.net/) when test seats become available. Configurable check interval and notification priority. Optional web server for managing accepted invites. Upstream: <https://github.com/MaximilianGT500/testflight-watcher>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Node.js (manual) | [GitHub README](https://github.com/MaximilianGT500/testflight-watcher#installation) | ✅ | Primary documented method |
| Docker (via Dockerfile) | [GitHub](https://github.com/MaximilianGT500/testflight-watcher) | ✅ | Containerised install |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| config | Pushover user key | string | All |
| config | Pushover app token | string | All |
| config | TestFlight URLs to monitor (JSON array) | JSON | All |
| config | OTP secret (`OTP_SECRET`) | string | All |
| config | Check interval in seconds (default 30) | number | All |
| config | Notification priority (default 1) | number | Optional |

## Node.js install

Source: <https://github.com/MaximilianGT500/testflight-watcher>

```bash
git clone https://github.com/MaximilianGT500/testflight-watcher.git
cd testflight-watcher
npm install
node setup.js   # or: npm run setup
node index.js   # or: npm start
```

## Configuration (.env)

```env
PUSHOVER_USER_KEY=your_pushover_user_key
PUSHOVER_APP_TOKEN=your_pushover_app_token
TESTFLIGHT_URLS='[{"name":"App 1","url":"https://testflight.apple.com/join/abcd1234"}]'
OTP_SECRET=ChangeThisString
OTP_VALIDITY=300
USER_AGENT=Testflight-Watcher/0.0.2
PORT=3000
HTTP_URL=http://localhost:3000
PUSHOVER_PRIORITY=1
CHECK_INTERVAL=30
```

| Variable | Default | Description |
|---|---|---|
| `PUSHOVER_USER_KEY` | required | Your Pushover user key |
| `PUSHOVER_APP_TOKEN` | required | Your Pushover app token |
| `TESTFLIGHT_URLS` | required | JSON array of `{name, url}` objects |
| `OTP_SECRET` | required | Secret for OTP-protected web UI |
| `OTP_VALIDITY` | `300` | OTP validity in seconds |
| `USER_AGENT` | `Testflight-Watcher/…` | User-agent for TestFlight requests |
| `PORT` | `3000` | Web server port |
| `HTTP_URL` | `http://localhost:3000` | Public URL of the web server |
| `PUSHOVER_PRIORITY` | `1` | Notification priority (Pushover scale) |
| `CHECK_INTERVAL` | `30` | Polling interval in seconds |

## Requirements

- Node.js v12 or higher
- 128 MB RAM, 0.5–1 CPU thread
- Internet connection
- Pushover account

## Upgrade procedure

```bash
git pull
npm install
npm start
```

## Gotchas

- Requires a [Pushover](https://pushover.net/) account and app — no other notification channels are documented.
- The OTP web UI is for managing/deleting already-accepted beta invites.
- No Docker Compose file in upstream README; use the Dockerfile directly if containerising.

## References

- GitHub: <https://github.com/MaximilianGT500/testflight-watcher>
- Pushover: <https://pushover.net/>
