---
name: Tirreno
description: "Open-source security framework for application fraud and threat detection. PHP/Apache + PostgreSQL. tirrenotechnologies/tirreno. Real-time threat dashboard, rule engine, risk scoring, SDKs, account takeover/bot/fraud detection."
---

# Tirreno

**Open-source application security framework for threat, fraud, and abuse detection.** Ingest events from your application via API/SDK; get a real-time threat dashboard with risk scores, user behaviour analysis, and a rule engine for automatic account suspension. Detects account takeover, credential stuffing, bot activity, multi-accounting, promo abuse, and more — from inside your application, not at the network perimeter.

Built + maintained by **Tirreno Technologies**. See repo license.

- Upstream repo: <https://github.com/tirrenotechnologies/tirreno>
- Website: <https://www.tirreno.com>
- Live demo: <https://play.tirreno.com> (admin / tirreno)
- Docker Hub: <https://hub.docker.com/r/tirreno/tirreno>

## Architecture in one minute

- **PHP 8.x / Apache** (with `mod_rewrite` + `mod_headers`)
- **PostgreSQL 12+** database
- Port **8585** (web UI + API)
- Cron job required: `/cron` endpoint every 10 minutes
- SDKs: PHP, Python, Node.js, WordPress
- Low-dependency design — "hand-written, few-dependency, low-tech PHP"
- Resource: **low** — PHP + PostgreSQL; ~3 GB PostgreSQL storage per 1 million events

## Compatible install methods

| Infra        | Runtime                     | Notes                                                                     |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| **Docker**   | `tirreno/tirreno`           | **Easiest** — one-liner: `curl -sL tirreno.com/t.yml \| docker compose -f - up -d` |
| **Zip/PHP**  | Apache + PHP + PostgreSQL   | Download ZIP from tirreno.com; 5-minute install wizard                    |
| **Composer** | `composer create-project tirreno/tirreno` | Via Packagist                                              |
| **Heroku**   | Heroku button               | One-click Heroku deploy                                                   |

## Inputs to collect

| Input                   | Example               | Phase   | Notes                                                          |
| ----------------------- | --------------------- | ------- | -------------------------------------------------------------- |
| PostgreSQL credentials  | host, user, pass, db  | Storage | PostgreSQL 12+                                                 |
| Admin email + password  | set during install    | Auth    | Created via `/signup/` after install wizard                    |
| Cron schedule           | `*/10 * * * *`        | Ops     | Required for risk score updates + rule evaluation              |

## Install via Docker (one-liner)

```bash
curl -sL tirreno.com/t.yml | docker compose -f - up -d
```

Then visit `http://localhost:8585/signup/` to create the admin account.

## Install via ZIP (manual)

1. Download ZIP from <https://www.tirreno.com/download/>
2. Extract to web server document root
3. Visit `http://localhost:8585/install/index.php` → complete install wizard (DB credentials)
4. **Delete the `install/` directory** after successful setup
5. Visit `http://localhost:8585/signup/` → create admin account
6. Configure cron: `*/10 * * * * /usr/bin/php /path/to/tirreno/index.php /cron`

## First boot

1. Deploy + run install wizard.
2. Delete `install/` directory.
3. Create admin account via `/signup/`.
4. Integrate SDK into your application:
   ```php
   // PHP SDK example
   $tracker = new TirrenoTracker(['api_key' => 'your-key', 'endpoint' => 'https://tirreno.host']);
   $tracker->track(['event' => 'login', 'user_id' => $userId, 'ip' => $ip]);
   ```
5. Events start flowing → dashboard shows real-time data.
6. Configure rules (preset or custom) for auto-suspension/flagging thresholds.
7. Set up the review queue for manual account investigation.
8. Put behind TLS.

## Preset detection rules

| Category | Examples |
|----------|---------|
| Account takeover | Unusual login location, impossible travel, session anomalies |
| Credential stuffing | High-volume login attempts from single IP/ASN |
| Bot detection | Superhuman speed, headless browser patterns |
| Content spam | High-velocity posting, duplicate content patterns |
| Multi-accounting | Shared device fingerprints, shared IPs |
| Promo abuse | Repeated coupon use from related accounts |
| Fraud prevention | Payment anomalies, risky region + behaviour combos |
| API protection | Rate limit bypasses, scraping patterns |
| Dormant account | Sudden activity on long-dormant accounts |
| Insider threat | Unusual data access patterns for known users |

## SDK languages

| Language | Repository |
|----------|-----------|
| PHP | <https://github.com/tirrenotechnologies/tirreno-php-tracker> |
| Python | <https://github.com/tirrenotechnologies/tirreno-python-tracker> |
| Node.js | <https://github.com/tirrenotechnologies/tirreno-nodejs-tracker> |
| WordPress | <https://github.com/tirrenotechnologies/tirreno-wordpress-tracker> |

## Storage estimation

Approximately **3 GB PostgreSQL storage per 1 million events**. For high-traffic applications, plan storage and consider PostgreSQL table partitioning or archival.

## Gotchas

- **Delete `install/` after setup.** The installation wizard is a security risk if left accessible. Delete the `install/` directory immediately after completing setup. Tirreno doesn't auto-delete it.
- **Cron job is required.** Without the cron running every 10 minutes (`/cron` endpoint), risk scores don't update, rule evaluations don't run, and the review queue doesn't populate. This is not optional in production.
- **PHP 8.0–8.3 supported.** Tirreno explicitly supports PHP 8.0 to 8.3. PHP 8.4 may work but isn't listed — verify compatibility.
- **Apache with mod_rewrite/mod_headers.** Tirreno requires Apache, not nginx (without manual rewrite config). The Docker image includes Apache.
- **Application-layer security, not network perimeter.** Tirreno works by receiving events that your application sends via SDK. It can't detect threats it doesn't receive events for — you must instrument your app's login, registration, and key actions.
- **Review queue for manual actions.** Tirreno can auto-suspend high-risk accounts (via rules), but the review queue is for borderline cases requiring human judgement. Build a workflow for reviewing the queue regularly.
- **Air-gap capable.** All processing is local — no data leaves your server. Suitable for sensitive or regulated environments.

## Backup

```sh
pg_dump tirreno > tirreno-$(date +%F).sql
```

## Upgrade

Download the latest ZIP and overwrite application files (not the database or config). Check the changelog for any migration steps.

## Project health

Active PHP development, Docker Hub, 4 SDK languages, Docker one-liner, live demo. Maintained by Tirreno Technologies.

## Application-security-family comparison

- **Tirreno** — PHP+PostgreSQL, SDK-based event ingestion, rule engine, risk scoring, fraud detection, self-hosted
- **Plausible (analytics)** — event tracking for analytics, not security
- **OWASP AppSensor** — Java, application intrusion detection; similar concept; less active
- **Fail2ban** — network-level IP blocking; not application-layer
- **Arkose Labs / DataDome** — commercial bot detection SaaS; not self-hosted

**Choose Tirreno if:** you want a self-hosted application security platform to detect account takeover, bots, and fraud from inside your application — without sending data to a third-party SaaS.

## Links

- Repo: <https://github.com/tirrenotechnologies/tirreno>
- Website: <https://www.tirreno.com>
- Live demo: <https://play.tirreno.com>
- Docker Hub: <https://hub.docker.com/r/tirreno/tirreno>
- Docs: see website
