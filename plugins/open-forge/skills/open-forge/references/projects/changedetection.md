---
name: changedetection-project
description: changedetection.io recipe for open-forge. Apache-2.0 self-hosted web page change monitor — detect changes on any URL and get alerts via Apprise (80+ notification providers: Discord / Telegram / Email / Slack / Matrix / custom webhook / etc). Filters via XPath / JSONPath / jq / CSS selectors / regex. Optional Playwright/Selenium/sockpuppetbrowser for JS-rendered pages. Optional LiteLLM integration for LLM-powered "notify only when X changes" rules. Covers single-container deploy, compose with sockpuppetbrowser for JS pages, reverse proxy behind USE_X_SETTINGS, notification URL examples, and the hosted-subscription alternative.
---

# changedetection.io

Apache-2.0 self-hosted website change monitor. Upstream: <https://github.com/dgtlmoon/changedetection.io>. Docs: <https://changedetection.io>. Wiki: <https://github.com/dgtlmoon/changedetection.io/wiki>.

Monitors URLs for changes and sends you notifications. Ideal for:

- Price drops on products
- Back-in-stock alerts
- PDF / document updates
- Government bulletins
- Job board postings
- JSON API response changes (with `jq` filter)
- Career page updates
- Website defacement monitoring
- Regulatory / legal changes
- Concert ticket availability
- "Anything changes on this page"

Pair it with notification routes (Apprise: 80+ services) for push alerts.

## Core features

- **XPath / JSONPath / jq / CSS selectors / regex** — pinpoint the element that matters, ignore the rest (navigation / footer / ads).
- **"Visual Selector" tool** — point-and-click element picking (requires playwright fetcher).
- **Browser Steps** — scripted interactions (login, click buttons, fill forms) before taking the snapshot.
- **Restock / price detection** — auto-extracts product metadata + alerts on price drops / back-in-stock.
- **Conditional rules** — AND/OR logic, "only notify if price < $50."
- **AI-powered rules** (subscription-tier or self-hosted via LiteLLM) — plain-English intent: "notify only when the item comes back in stock."
- **AI change summaries** — natural-language diff descriptions.
- **Scheduled checks** — timezone-aware, limit by day-of-week / time-of-day.
- **Apprise notifications** — 80+ services (Discord, Slack, Email, Telegram, SMS, etc.).
- **RSS feeds** generated per watch.
- **Chrome extension** — add-current-page workflow from browser.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`dgtlmoon/changedetection.io` / `ghcr.io/dgtlmoon/changedetection.io`) | ✅ Recommended | Most self-hosters. |
| Docker Compose w/ sockpuppetbrowser | <https://github.com/dgtlmoon/changedetection.io/blob/master/docker-compose.yml> | ✅ | When monitoring JS-rendered pages (SPAs). |
| pip install (Python) | PyPI: `changedetection.io` | ✅ | Non-Docker hosts. |
| Windows | Wiki install guide | ✅ | Win users. |
| Hosted subscription ($8.99/month) | <https://changedetection.io> | ✅ (paid) | Don't want to self-host; get proxies + included Chrome fetcher. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-standalone` / `docker-compose` / `docker-compose-playwright` / `pip` | Drives section. |
| preflight | "Need JavaScript rendering?" | Boolean | If yes → add sockpuppetbrowser (Playwright) OR selenium container. |
| ports | "Web UI port?" | Default `5000` | |
| storage | "Datastore path?" | Free-text, default `./datastore` or a named volume | Persist across restarts. |
| dns | "Public hostname?" | Free-text, optional | If reverse-proxied, set `BASE_URL` + `USE_X_SETTINGS=1`. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | LAN-only = skip; public = required. |
| auth | "Enable password protection?" | Boolean | Set via UI at `/settings/password`. No default password. |
| notifications | "Default notification URLs?" | Free-text (Apprise format) | Optional. Can configure per-watch later. |
| llm | "Enable LLM-powered rules (optional)?" | `AskUserQuestion`: `openai` / `anthropic` / `gemini` / `ollama-local` / `none` | Requires an LLM provider via LiteLLM. Self-host with Ollama keeps it all local. |

## Install — Docker standalone

```bash
docker run -d \
  --restart always \
  --name changedetection.io \
  -p 127.0.0.1:5000:5000 \
  -v datastore-volume:/datastore \
  dgtlmoon/changedetection.io
```

Open `http://localhost:5000/`. Bind `127.0.0.1` (not `0.0.0.0`) unless you intend public access; add a reverse proxy + auth for internet exposure.

## Install — Docker Compose (with Playwright for JS pages)

Adapted from upstream `docker-compose.yml`:

```yaml
services:
  changedetection:
    image: ghcr.io/dgtlmoon/changedetection.io
    container_name: changedetection
    hostname: changedetection
    restart: unless-stopped
    volumes:
      - changedetection-data:/datastore
    environment:
      # Optional: render JS-heavy pages via sockpuppetbrowser
      - PLAYWRIGHT_DRIVER_URL=ws://browser-sockpuppet-chrome:3000
      # Base URL used in notifications (avoid sending localhost links)
      - BASE_URL=https://changedetection.example.com
      # If behind a reverse proxy, honor X-Forwarded-* headers
      - USE_X_SETTINGS=1
      # Hide Referer so monitored sites don't see your CD hostname
      - HIDE_REFERER=true
    ports:
      - "5000:5000"
    depends_on:
      browser-sockpuppet-chrome:
        condition: service_started

  browser-sockpuppet-chrome:
    image: dgtlmoon/sockpuppetbrowser:latest
    container_name: browser-sockpuppet-chrome
    restart: unless-stopped
    hostname: browser-sockpuppet-chrome
    environment:
      - SCREEN_WIDTH=1920
      - SCREEN_HEIGHT=1024
      - SCREEN_DEPTH=16
      - MAX_CONCURRENT_CHROME_PROCESSES=10

volumes:
  changedetection-data:
```

```bash
docker compose up -d
```

## Install — pip (non-Docker)

```bash
python3 -m venv ~/.venv/changedetection
source ~/.venv/changedetection/bin/activate
pip install changedetection.io
changedetection.io -d ./datastore -p 5000
# Visit http://localhost:5000/
```

systemd unit:

```ini
# /etc/systemd/system/changedetection.service
[Unit]
Description=changedetection.io
After=network.target

[Service]
Type=simple
User=changedetection
Group=changedetection
ExecStart=/opt/changedetection-venv/bin/changedetection.io -d /var/lib/changedetection -p 5000
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

## First-login setup

1. Open `http://<host>:5000/`.
2. **Settings → Password → Set a password.** No default password exists; anyone with access can use the instance until you set one.
3. Settings → Notifications → Add default Apprise URLs (optional).
4. Add your first watch: click **Add a new watch** → paste URL → Save.
5. After the first fetch, click the watch → **Filters & Triggers** tab → set XPath / CSS / jq filter to target the part you care about.
6. **Notifications** tab on the watch: add per-watch notification overrides.

## Filters

| Filter type | Syntax | Example |
|---|---|---|
| CSS selector | standard CSS | `.product-price` |
| XPath 1.0 / 2.0 | XPath expression | `//div[@id='price']/text()` |
| JSONPath | `jsonpath://` | `jsonpath:$.items[*].price` |
| jq | `jq:` | `jq:.items | map(.price) | min` |
| Regex | `re://...` (extract) | |

For JSON APIs, `jq` is the most powerful — use logic like `jq:.products[] | select(.stock == "in")`.

## Notifications (Apprise URLs)

Just a sample of the 80+ supported:

| Service | URL scheme |
|---|---|
| Discord webhook | `discord://webhook_id/webhook_token` |
| Slack | `slack://TokenA/TokenB/TokenC/#channel` |
| Telegram bot | `tgram://bottoken/ChatID` |
| Email (SMTP) | `mailto://user:pass@example.com?to=you@example.com` |
| Matrix | `matrixs://user:password@matrix.example.com/#room:example.com` |
| Microsoft Teams | `msteams://TokenA/TokenB/TokenC/` |
| Gotify | `gotify://host/token` |
| Pushover | `pover://user@token` |
| ntfy | `ntfy://topic` |
| Generic webhook (JSON) | `json://yourserver.com/webhook` |
| Syslog | `syslog://` |
| Many more | See <https://github.com/caronc/apprise#popular-notification-services> |

Set globally in Settings → Notifications, OR per-watch in the watch's Notifications tab.

### Templating notification content

Notification body supports Jinja2 templates with variables like `{{watch_url}}`, `{{diff_added}}`, `{{diff_removed}}`, `{{preview_url}}`.

## LLM-powered rules (optional, new)

Set in Settings → AI:

- **OpenAI:** `gpt-4o-mini` etc. Paste API key.
- **Google Gemini:** `gemini-flash-1.5`.
- **Anthropic:** `claude-3-haiku`.
- **Ollama (local):** `http://ollama:11434` + model name. 100% local.

Then per-watch, set plain-English rules ("notify only when price drops below $50"). The AI evaluates each detected change against the rule and suppresses non-matching notifications.

> _Note (upstream, as of 2026-06): this feature is also available in the hosted subscription tier._

## Data layout

| Path | Content |
|---|---|
| `/datastore/` | All state: watches, history, diffs, settings, screenshots |
| `/datastore/bookmarks.json` | Watch list |
| `/datastore/<uuid>/` | Per-watch: snapshots, diff history, screenshots |
| `/datastore/proxies.json` | Proxy list (optional) |

**Backup** = tar `/datastore/` while container stopped. It's everything.

## Reverse proxy (Caddy)

```caddy
changedetection.example.com {
    reverse_proxy changedetection:5000 {
        header_up X-Forwarded-Prefix /
    }
}
```

With `USE_X_SETTINGS=1` env on the changedetection container, it honors these headers and generates correct URLs in notifications/RSS.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose logs changedetection
```

Upstream is actively developed; read release notes for schema changes: <https://github.com/dgtlmoon/changedetection.io/releases>.

## Gotchas

- **No default password.** On first launch, the instance is un-authenticated — anyone who can reach port 5000 can use it. **Bind to `127.0.0.1` during setup**, set a password in Settings, THEN expose. Alternatively use a reverse-proxy with auth.
- **JavaScript-heavy pages need a browser fetcher.** Without sockpuppetbrowser / Playwright / Selenium, dynamic SPAs (React/Vue/Angular) return empty pages. Docker Compose with sockpuppetbrowser is the easiest path.
- **Restock / price detection heuristics can misread.** The "Re-stock & Price detection" mode uses JSON-LD + microdata + fallback heuristics. For accuracy, set explicit CSS/XPath filters and parse the price yourself with jq/regex.
- **Some sites actively block automated scraping.** Cloudflare / PerimeterX / Kasada / Datadome will see the Playwright fingerprint and serve you challenge pages. changedetection.io can't magically defeat these — use rotating proxies (paid feature OR bring-your-own proxy list).
- **Rate-limiting can get you blocked.** Default check frequency is conservative but "every 60 seconds on 50 watches on the same domain" will earn you a ban. Vary check times, space watches out, use `time:` tags.
- **`USE_X_SETTINGS=1` needed behind reverse proxies.** Without it, CD generates `http://localhost:5000` URLs in notifications + RSS. If you see "localhost" URLs, you forgot this setting.
- **`BASE_URL` is separate** — used inside notification bodies. Set it to your public URL.
- **Storage grows with history.** Every change stores a snapshot; old snapshots aren't pruned by default. Configure Settings → History → retention.
- **Browser Steps ≠ cron job.** Steps are executed on every check; heavy logins on a 1-minute check frequency = hammered upstream. Keep Browser Steps simple / schedule checks conservatively.
- **Apprise URL syntax is strict.** One wrong character silently fails. Use Settings → Notifications → Send test to verify before saving.
- **Screenshot support requires a browser fetcher** (Playwright / sockpuppetbrowser / Selenium). HTTP fetcher alone can't do screenshots.
- **Proxy config is JSON-file based** (`proxies.json`) + UI dropdown. Proxy auth issues manifest as blank diffs — test with a simple watch first.
- **The "AI-powered rules" feature requires an LLM provider key.** Costs money unless using Ollama locally. LLM errors silently degrade to "notify always" — watch for unexpected notification floods.
- **ChangeDetection is not a DoS tool.** If you set 1-second intervals on 100 watches, you'll self-DoS AND get blocked. The "fast non-JS fetcher" is fast but not infinitely free.
- **No multi-user.** One password = one "user." For team use, share the password OR put a reverse-proxy auth layer with per-user accounts in front (which NPM / Authelia / oauth2-proxy can do).
- **JSON diffs are character-based by default**; set JSONPath or jq filter to avoid noise from reformatted-but-equivalent JSON.
- **RSS URL per watch** is stable and includes a secret token. Useful for integrating with FreshRSS / Miniflux.
- **Self-hosted is pretty much at feature-parity with the subscription** except some AI features and the included hosted proxies. If you're fine managing your own proxies, self-host is the same product.

## Links

- Upstream repo: <https://github.com/dgtlmoon/changedetection.io>
- Hosted service: <https://changedetection.io>
- Docker Hub: <https://hub.docker.com/r/dgtlmoon/changedetection.io>
- Wiki: <https://github.com/dgtlmoon/changedetection.io/wiki>
- Apprise (notification library): <https://github.com/caronc/apprise>
- sockpuppetbrowser: <https://github.com/dgtlmoon/sockpuppetbrowser>
- Reverse proxy guide: <https://github.com/dgtlmoon/changedetection.io/wiki/Running-changedetection.io-behind-a-reverse-proxy>
- Filter help: <https://github.com/dgtlmoon/changedetection.io/wiki/JSON-Selector-Filter-help>
- Proxy config: <https://github.com/dgtlmoon/changedetection.io/wiki/Proxy-configuration>
- Releases: <https://github.com/dgtlmoon/changedetection.io/releases>
- Discord: linked from README
