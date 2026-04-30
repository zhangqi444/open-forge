---
name: Open Web Analytics
description: "Open-source alternative to Google Analytics. PHP. Track visitors/pageviews/e-commerce/custom-actions. Unlimited websites on one OWA Server. Heatmaps + DOMStream session-recordings + geolocation. WordPress plugin + PHP SDK. GPL. Active (long-standing)."
---

# Open Web Analytics (OWA)

OWA is **"Google Analytics — but self-hosted + PHP + privacy-first + first-party"** — an open-source web-analytics alternative. Tracks visitors, pageviews, e-commerce transactions, custom actions. **First-party JavaScript tracker** (no 3rd-party cookie). Track **unlimited websites** with single OWA Server. Reporting dashboard. **Heatmaps**. **DOMStream session-recordings**. Visitor geolocation. REST API. Multi-user reporting. WordPress plugin integration. PHP SDK for generic PHP apps.

Built + maintained by **Open Web Analytics org (Peter Adams + community)**. License: GPL. Active (long-standing — OSS since ~2004); mature; wiki-based docs; WordPress plugin + PHP SDK auxiliary repos.

Use cases: (a) **replace Google Analytics** — privacy + first-party + self-hosted (b) **WordPress analytics** — via OWA WP plugin (c) **multi-site analytics** — unlimited sites on single server (d) **GDPR-compliant analytics** — first-party, no 3rd-party cookies (e) **session-recording / heatmaps** (rare in OSS — usually commercial Hotjar/FullStory) (f) **e-commerce analytics** — transactions + funnels (g) **custom action tracking** — beyond pageview (h) **long-lived analytics archive** — your data, retained however long you want.

Features (per README):

- **Visitors + pageviews + transactions + custom actions**
- **Unlimited websites** from single OWA Server
- **First-party JavaScript tracker**
- **Reporting dashboard/portal**
- **All reports viewable + customizable**
- **Heatmaps**
- **DOMStream session-recordings**
- **Geolocation**
- **REST API**
- **Multi-user reporting**
- **Extensible via custom modules**

- Upstream repo: <https://github.com/Open-Web-Analytics/Open-Web-Analytics>
- WordPress plugin: <https://wordpress.org/plugins/open-web-analytics/>
- PHP SDK: <https://github.com/Open-Web-Analytics/owa-php-sdk>

## Architecture in one minute

- **PHP** backend
- **MySQL / MariaDB** DB
- **JavaScript** tracker client (first-party)
- **Resource**: moderate — grows with pageview volume
- **Composer** for PHP deps

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Community images                                                | Self-host                                                                        |
| **Bare PHP**       | **PHP + Apache/Nginx + MySQL**                                  | **Primary traditional**                                                                                   |
| **Shared hosting** | cPanel-style with PHP + MySQL                                                                            | Small sites                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `analytics.example.com`                                     | URL          | TLS                                                                                    |
| PHP version          | Recent                                                      | Runtime      | Keep current                                                                                    |
| MySQL/MariaDB creds  | Dedicated DB                                                | DB           |                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Tracker snippet URL  | First-party-to-each-site                                    | Config       | Embedded in client sites                                                                                    |
| GeoIP DB             | MaxMind (opt)                                               | GeoIP        |                                                                                    |
| Retention policy     | How long to keep pageview data                                                                                         | Policy       | **GDPR**                                                                                    |

## Install

Follow: <https://github.com/Open-Web-Analytics/Open-Web-Analytics/wiki/Installation>

Bare PHP:
```sh
# Extract to webroot
# Configure config/owa_config.php with DB creds
# Run install.php via browser
```

Docker (community):
```yaml
services:
  owa:
    image: (community image; check for well-maintained one)
    environment:
      OWA_DB_HOST: db
      OWA_DB_NAME: owa
      OWA_DB_USER: owa
      OWA_DB_PASSWORD: ${DB_PASSWORD}
    ports: ["80:80"]
    depends_on: [db]

  db:
    image: mariadb:11
    environment:
      MARIADB_DATABASE: owa
      MARIADB_USER: owa
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_ROOT_PASSWORD: ${DB_ROOT}
    volumes: [owadb:/var/lib/mysql]

volumes:
  owadb: {}
```

## First boot

1. Install via wiki-guide
2. Create admin account
3. Add first site; get tracker snippet
4. Embed snippet on site; verify pageviews flow
5. Configure retention / GDPR settings
6. Put behind TLS reverse proxy
7. Back up MySQL

## Data & config layout

- MySQL — all pageview + visitor data
- `config/owa_config.php` — main config

## Backup

```sh
mysqldump -u owa -p owa > owa-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/Open-Web-Analytics/Open-Web-Analytics/releases>. Active but slower cadence (mature-project-phase).
2. Follow upgrade guide in wiki
3. DB migrations run on admin-page
4. **Back up before** major versions

## Gotchas

- **96th HUB-OF-CREDENTIALS TIER 2 + DATA-PROTECTION BURDEN**:
  - Collects user-visitor-tracking data (IPs, pages visited, UA, session-replay)
  - **DOMStream session recordings = INTIMATE data** (everything user did on page)
  - **96th tool in hub-of-credentials family — Tier 2**
  - **Sub-family: "analytics/tracking-personal-data-risk"** — NEW
  - **NEW sub-family: "analytics/tracking-personal-data-risk"** (1st — OWA)
- **GDPR COMPLIANCE REQUIREMENTS**:
  - EU user tracking = GDPR Art. 6 + ePrivacy Directive
  - Cookie consent required
  - Session-recording may need explicit opt-in (most-likely DOES — intimate-data)
  - IP-address pseudonymization
  - Retention limits (e.g., 14-24 months max)
  - **Recipe convention: "GDPR-analytics-compliance-requirements" callout** (EXTENSIVE)
  - **NEW recipe convention** (OWA 1st formally)
- **DOMSTREAM SESSION-RECORDINGS = SENSITIVE**:
  - Records what user did on page (scroll, click, type)
  - May capture form-typing (passwords if not scrubbed!)
  - **MUST configure field-masking** for password/form fields
  - **Recipe convention: "session-recording-field-masking mandatory" callout**
  - **NEW recipe convention** (OWA 1st)
- **HEATMAPS = TRACKED CLICK/SCROLL DATA**:
  - Less sensitive than session-recordings but still personal-data
  - Standard GDPR applies
- **LONG-STANDING OSS PROJECT (~2004)**:
  - One of oldest OSS web-analytics tools
  - Predates Piwik (now Matomo)
  - **Recipe convention: "long-standing-OSS-project positive-signal"** — extended
  - **Decade-plus-OSS** extended: prior 3 tools (Gramps+EspoCRM+Silex) + OWA = 4 tools
  - **4-tool milestone**
- **FIRST-PARTY JAVASCRIPT TRACKER**:
  - Tracker served from YOUR domain (not owa.example.com)
  - No 3rd-party cookies — ad-blocker-friendlier
  - **Recipe convention: "first-party-analytics-tracker positive-signal"**
  - **NEW positive-signal convention** (OWA 1st formally; Matomo/Plausible/Umami also do this)
- **PHP = OLD-TECH VIBES**:
  - PHP is fine but needs keeping-up-with-PHP-version
  - **Recipe convention: "PHP-version-update-discipline" callout** — standard for PHP projects
- **WORDPRESS PLUGIN SEPARATE REPO**:
  - WP plugin has separate maintenance
  - **Recipe convention: "multi-repo-project-version-compatibility" callout**
- **PHP SDK AVAILABLE**:
  - For non-WordPress PHP apps
  - **Recipe convention: "auxiliary-SDK-for-integration positive-signal"**
- **ANALYTICS-TOOL-CATEGORY (crowded):**
  - **OWA** — PHP; session-recordings + heatmaps
  - **Matomo (Piwik)** — PHP; most mature OSS analytics
  - **Plausible** — Elixir; privacy-first; simpler
  - **Umami** — Node; privacy-first; simpler
  - **GoAccess** — CLI; log-based
  - **Fathom** (commercial alternative)
- **SESSION-RECORDING RARE IN OSS**:
  - Commercial equivalents: Hotjar, FullStory, LogRocket
  - OWA is rare OSS option
  - **Recipe convention: "rare-OSS-feature positive-signal"**
  - **NEW positive-signal convention** (OWA 1st — session-recording)
- **INSTITUTIONAL-STEWARDSHIP**: Open-Web-Analytics org + Peter Adams + community + WordPress-plugin-maintained. **82nd tool — mature-OSS-org-with-ecosystem-spread sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active (slower) + wiki-docs + WordPress-plugin + PHP-SDK + 20-year-project-history + GPL. **90th tool in transparent-maintenance family** 🎯 **90-TOOL MILESTONE.**
- **EXTENSIBILITY VIA CUSTOM MODULES**:
  - Plugin architecture documented
  - **Recipe convention: "pluggable-modules-for-extensibility positive-signal"**
- **ALTERNATIVES WORTH KNOWING:**
  - **Matomo** — if you want THE mature OSS analytics platform
  - **Plausible / Umami** — if you want lightweight privacy-first
  - **GoAccess** — if you want log-based CLI
  - **Choose OWA if:** you want session-recordings + heatmaps + long-lived OSS tool.
- **PROJECT HEALTH**: active (slower cadence; mature-phase) + WordPress-ecosystem + PHP-SDK + long-history. Decent despite slower-cadence.

## Links

- Repo: <https://github.com/Open-Web-Analytics/Open-Web-Analytics>
- WP plugin: <https://wordpress.org/plugins/open-web-analytics/>
- PHP SDK: <https://github.com/Open-Web-Analytics/owa-php-sdk>
- Matomo (alt): <https://matomo.org>
- Plausible (alt): <https://plausible.io>
- Umami (alt): <https://umami.is>
