---
name: Wallos
description: "Self-hosted personal subscription tracker — log recurring payments (Netflix, Spotify, domains, SaaS) with due-date reminders, multi-currency, categories, statistics. Notifications via email/Discord/Pushover/Telegram/Gotify/webhook. OIDC auth. AGPL-3.0."
---

# Wallos

Wallos is a focused, delightfully simple **subscription tracker** — list all your recurring payments (Netflix, Spotify, cloud storage, domain renewals, SaaS tools, gym, streaming), see what's due when, total monthly + yearly spend by category and currency, and get reminders before renewals bite.

If Sure/Firefly III/Actual are "full-blown personal finance apps," Wallos is "just the recurring subscriptions view, done very well." Great companion to a full PF tool — or enough on its own if you don't want budget envelopes.

Features:

- **Subscriptions** — logos, costs, renewal dates, categories, payment methods
- **Multi-currency** with Fixer API FX conversion (free tier)
- **Categories** — customizable (Streaming, Cloud, Dev Tools, Fitness, ...)
- **Statistics** — monthly/yearly charts; by category / by currency
- **Notifications** — email, Discord, Pushover, Telegram, Gotify, webhooks
- **Logo search** — auto-find a brand's logo if you don't have one
- **Mobile view** — responsive; PWA-friendly
- **Multi-language** (20+ locales)
- **Multi-user** household support (user admin in newer releases)
- **OIDC / OAuth** (single-sign-on: Authelia, Authentik, Keycloak, Pocket ID)
- **AI recommendations** via ChatGPT, Gemini, or local Ollama (optional)
- **Import / export** JSON

- Upstream repo: <https://github.com/ellite/Wallos>
- Demo: <https://demo.wallosapp.com> (user `demo` / `demo`)
- Docker Hub: <https://hub.docker.com/r/bellamy/wallos>
- Discord: <https://discord.gg/anex9GUrPW>

## Architecture in one minute

- **PHP 8+** (LAMP stack style)
- **SQLite** by default — single file, zero setup
- **nginx** or Apache with PHP-FPM (packaged in Docker image)
- **No Redis / no queue** — lightweight scheduled tasks
- **Fixer API** (optional) — FX rates; free tier is sufficient for personal use
- **Footprint**: ~50-100 MB RAM; runs on a Pi Zero happily

## Compatible install methods

| Infra          | Runtime                                          | Notes                                                          |
| -------------- | ------------------------------------------------ | -------------------------------------------------------------- |
| Single VM      | **Docker (`bellamy/wallos`)**                       | **Simplest**                                                       |
| Bare metal     | PHP + SQLite on any LAMP/LEMP                          | Works; upstream docs cover it                                        |
| Raspberry Pi   | arm64 Docker                                                   | Great fit; tiny                                                              |
| Shared host    | Drop files into PHP hosting                                         | Possible if SQLite writable                                                        |
| Kubernetes     | Tiny Deployment + PVC                                                      | Overkill; works                                                                          |

## Inputs to collect

| Input              | Example                      | Phase     | Notes                                                              |
| ------------------ | ---------------------------- | --------- | ------------------------------------------------------------------ |
| Domain             | `subs.example.com`             | URL       | Reverse proxy with TLS                                                |
| Data volume        | `./db:/var/www/html/db`            | Storage   | Where SQLite file + uploaded logos live                                        |
| First user         | created in web UI                      | Bootstrap | First signup is admin                                                                |
| Fixer API key (opt)| from <https://fixer.io>                        | FX        | Free 100 req/mo; upgrade for frequent conversion                                         |
| SMTP (opt)         | host/port/user/pass                              | Email     | For renewal reminders                                                                                |
| OIDC config (opt)  | issuer + client_id + client_secret                   | SSO       | Authelia/Authentik/Pocket ID/Keycloak                                                                           |
| Timezone           | `America/Los_Angeles`                                      | Locale    | Reminder timing                                                                                                           |

## Install via Docker

```sh
docker run -d --name wallos \
  --restart unless-stopped \
  -p 8282:80 \
  -v /opt/wallos/db:/var/www/html/db \
  -v /opt/wallos/logos:/var/www/html/images/uploads/logos \
  -e TZ=America/Los_Angeles \
  bellamy/wallos:latest    # pin a specific version in prod
```

## Install via Docker Compose

```yaml
services:
  wallos:
    image: bellamy/wallos:latest    # pin specific tag for prod
    container_name: wallos
    restart: unless-stopped
    ports:
      - "8282:80"
    volumes:
      - ./db:/var/www/html/db
      - ./logos:/var/www/html/images/uploads/logos
    environment:
      TZ: America/Los_Angeles
      USERNAME: admin         # optional: set admin user on first start
      PASSWORD: <strong>      # optional
      MAX_UPLOAD_SIZE: 5M
```

## Install bare metal

```sh
# Prereqs: PHP 8+, SQLite, web server
git clone https://github.com/ellite/Wallos.git /var/www/wallos
cd /var/www/wallos
# Ensure db/ and images/uploads/logos are writable by PHP
chown -R www-data:www-data db images/uploads
# Point nginx/apache docroot at /var/www/wallos
```

## First boot

1. Browse `https://subs.example.com/`
2. Register → first user is admin
3. Settings → Currencies → add your currencies + set main
4. (Optional) Settings → Fixer API → paste key for auto FX conversion
5. Subscriptions → Add Subscription — brand name, amount, currency, billing cycle, next payment date, category
   - Logo search auto-finds the brand logo
6. Categories → customize (Streaming, Productivity, Domains, …)
7. Settings → Notifications → configure email/Discord/Telegram/Pushover/Gotify/webhook
8. Statistics → see total monthly + yearly spend by category + currency

## Data & config layout

- `db/wallos.db` — SQLite (all data: subs, users, settings, categories)
- `images/uploads/logos/` — user-uploaded brand logos
- `images/uploads/` — other uploads (avatars, payment method icons)
- **That's it** — Wallos is delightfully minimal

## Backup

```sh
# Stop during backup for consistency (SQLite)
docker compose stop wallos
tar czf wallos-$(date +%F).tgz db/ logos/
docker compose start wallos
```

Or use `sqlite3 db/wallos.db ".backup db/wallos-$(date +%F).db"` for hot backup.

## Upgrade

1. Releases: <https://github.com/ellite/Wallos/releases>. Active.
2. Docker: bump tag → `docker compose pull && docker compose up -d`. SQLite migrations run automatically.
3. Bare metal: `git pull` → run any migration scripts per release notes.
4. Back up `db/` first.

## Gotchas

- **Backup your SQLite file** — it's the only source of truth. Losing `db/wallos.db` = losing all subscription history.
- **First-user-is-admin** — there's no onboarding wizard to assign roles; the first register wins. Register quickly after exposing to the internet or some bot might beat you to it. Better: set `USERNAME` + `PASSWORD` env to pre-seed.
- **Disable public registration** after first boot via admin settings (Settings → Users → "Allow Registration" off) unless you want a multi-household instance.
- **Fixer API free tier**: 100 requests/month. Fine for daily rate sync; don't poll aggressively. Upgrade or switch to another FX provider if you exceed.
- **Currencies and base currency** — each subscription is stored in its native currency. Wallos converts to your "main currency" on the fly. If FX rates fail to update, numbers look wrong — check the Fixer key.
- **Notifications schedule** — set how many days before renewal to notify. Default is often too quiet (1 day); 3-7 days is practical for cancellation windows.
- **Email deliverability** — configure SMTP correctly (DKIM/SPF via your provider); local postfix relays often land in spam.
- **Multi-user + household** — each user has their own subs; admin sees all. Useful for tracking shared subs separately.
- **OIDC** (since newer releases) — great for SSO with Authelia / Authentik / Pocket ID. Disable local login if SSO is mandatory.
- **AI recommendations** — feature sends subscription list to an LLM (ChatGPT/Gemini/local Ollama) and asks "which might you cancel?". Opt-in; local Ollama keeps data private.
- **Logo search** scrapes public logos. If an obscure brand isn't found, upload manually (any SVG/PNG).
- **Payment methods** — you can track "paid via Chase Visa ...1234" for accounting. Don't store full card numbers (and Wallos doesn't ask for them).
- **No tax / categorization for accounting** — Wallos is for awareness + reminders, not tax prep.
- **Mobile**: web is responsive; PWA; no native app.
- **Not a replacement for a full PF app** — if you want budgets, transactions, net worth, use Firefly III/Actual/Sure. Wallos *complements* those tools.
- **License**: AGPL-3.0.
- **Popular pairing**: Wallos + Firefly III / Actual + Ghostfolio = subscriptions + budget + portfolio — all OSS, all self-hosted.
- **Alternatives worth knowing:**
  - **Bobby** (iOS) / **Subscriptly** / **Billi** / **Mobills** — mobile subscription trackers
  - **Trackmysubs** — web SaaS
  - **Subscription Tracker** (various open apps) — simpler
  - **Firefly III / Actual / Sure** — full PF apps with their own subs tracking
  - **Maybe self-built spreadsheet** — many people track in Google Sheets
  - **Choose Wallos if:** you want a dedicated, pretty, self-hosted subscription dashboard.
  - **Choose a full PF app if:** you want one tool for budget + transactions + subs.
  - **Choose a spreadsheet if:** you have <10 subs and don't want to operate a service.

## Links

- Repo: <https://github.com/ellite/Wallos>
- Demo: <https://demo.wallosapp.com>
- Docker Hub: <https://hub.docker.com/r/bellamy/wallos>
- Releases: <https://github.com/ellite/Wallos/releases>
- Discord: <https://discord.gg/anex9GUrPW>
- GitHub sponsors: <https://github.com/sponsors/ellite>
- Fixer API: <https://fixer.io>
- OIDC example (Authelia): <https://www.authelia.com>
- OIDC example (Authentik): <https://goauthentik.io>
- API docs: <https://github.com/ellite/Wallos/blob/main/api/README.md>
