---
name: mosparo
description: mosparo recipe for open-forge. Modern spam protection for web forms. Replaces CAPTCHA with rule-based content scanning. Self-hosted, privacy-friendly, accessible. PHP + MySQL/PostgreSQL/SQLite. Source: https://github.com/mosparo/mosparo
---

# mosparo

Modern spam protection tool for web forms. Instead of puzzles or CAPTCHAs, mosparo scans form field content against configurable rules (URLs, keywords, patterns) — the same approach as email spam filters. Self-hosted, privacy-focused (only stores what the user typed + IP + user agent, auto-deleted after 14 days), and accessible to users with disabilities. PHP 8.1+ + MySQL/PostgreSQL/SQLite. MIT licensed.

Upstream: <https://github.com/mosparo/mosparo> | Docs: <https://documentation.mosparo.io>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | PHP 8.1+ web host + MySQL/PostgreSQL/SQLite | Release zip install |
| Any | Docker | From source or community images |
| Linux | From source (Composer + Node.js 18) | Development |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Database: MySQL, PostgreSQL, or SQLite | SQLite works for small sites |
| config | Database credentials (MySQL/PostgreSQL) | |
| config | Web host / domain | e.g. spam.example.com — mosparo should be on its own subdomain |
| config | Document root → `public/` subdirectory | Required for security |

## Software-layer concerns

### PHP requirements

- PHP 8.1.10+
- Extensions: ctype, curl, dom, filter, gd, iconv, intl, json, libxml, openssl, pcre, pdo, pdo_mysql/pdo_pgsql/pdo_sqlite, simplexml

### How mosparo integrates with forms

1. Self-host mosparo on your server
2. Create a "project" in mosparo → get a public key + private key
3. Add mosparo's JavaScript snippet to your HTML form
4. On form submission, verify server-side with the private key + submission UUID via mosparo's API
5. mosparo checks form data against your configured rules and returns pass/fail

Plugins available for WordPress, Contao, Craft CMS, Neos CMS, Symfony, and others.

## Install — ZIP release (recommended)

```bash
# 1. Download latest release
# https://github.com/mosparo/mosparo/releases/latest
# or https://mosparo.io/download/
wget https://github.com/mosparo/mosparo/releases/latest/download/mosparo.zip
unzip mosparo.zip -d /var/www/mosparo

# 2. Set document root to /var/www/mosparo/public
#    (Apache VirtualHost or nginx server block)

# 3. Set permissions
chown -R www-data:www-data /var/www/mosparo
chmod -R 755 /var/www/mosparo

# 4. Open browser → mosparo install wizard
#    http://spam.example.com/
#    Follow wizard: DB setup, admin account, site config
```

Full install guide: https://documentation.mosparo.io/docs/installation/install/normal

## Install — From source (development)

```bash
git clone https://github.com/mosparo/mosparo.git
cd mosparo
composer install
npm install  # Node.js 18 required
yarn build   # or npm run build
# Then configure document root to public/
```

## Upgrade procedure

```bash
# Download new release zip
# Extract, overwrite files (preserve .env)
# Run DB migrations via web UI or CLI: php bin/console doctrine:migrations:migrate
```

## Gotchas

- **Document root must be `public/`** — pointing the web server at the repo root exposes sensitive files. Configure Apache/nginx to serve only the `public/` subdirectory.
- mosparo is a backend validation tool — the JavaScript widget provides a frontend checkbox, but the real spam detection happens server-side when you verify submissions via the API with your private key.
- Rule-based detection requires setup — mosparo doesn't block spam automatically out of the box. You need to add rules (URL blocklists, keyword patterns, etc.) to achieve meaningful spam filtering. Estimate: well-configured rules block 80%+ of spam.
- Data auto-expires after ~14 days — by design, to minimize data retention. Cronjob runs the cleanup.
- Deploy mosparo on a subdomain (e.g. `spam.example.com`) separate from your main site — this matches the recommended setup in the docs.

## Links

- Source: https://github.com/mosparo/mosparo
- Documentation: https://documentation.mosparo.io
- Website: https://mosparo.io
- Integrations/plugins: https://documentation.mosparo.io/docs/integration/
