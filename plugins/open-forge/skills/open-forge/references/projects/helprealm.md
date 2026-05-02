# HelpRealm

**What it is:** A lightweight self-hosted SaaS-style support ticket system built on Laravel. Customers submit tickets via a workspace contact form, email, or API; agents handle and route tickets through configurable groups. Supports multi-tenant workspaces, email notifications, email replies, FAQ pages, Stripe payments for API access, Gravatar, and an agent/superadmin dashboard. Designed for freelancers and small teams.

**Official URL:** https://github.com/danielbrendel/dnyHelpRealm
**License:** MIT
**Stack:** PHP 8.2+ + Laravel + MySQL/MariaDB; no Docker image provided

> **Note:** No official Docker image. Manual PHP/Laravel deployment only.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | PHP 8.2+ + MySQL/MariaDB | Standard Laravel deployment |
| Shared hosting | PHP 8.2+ + MySQL | Requires PHP extensions and MySQL |

---

## Inputs to Collect

### Pre-deployment (`.env`)
- `APP_URL` — public URL of the instance
- `APP_KEY` — generate with `php artisan key:generate`
- Database: `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`
- Mail config: `MAIL_MAILER`, `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_ENCRYPTION`, `MAIL_FROM_ADDRESS`
- IMAP/mailserv (for email-to-ticket): `MAILSERV_HOST`, `MAILSERV_PORT`, `MAILSERV_PROTOCOL`, `MAILSERV_USERNAME`, `MAILSERV_PASSWORD`, `MAILSERV_CRONPW`
- `APP_PAYFORAPI` — `true` to require Stripe payment for API access; requires Stripe keys if enabled

### Optional
- `APP_DOCUMENTATION_LINK` — link to external docs shown in UI
- `APP_CAPTCHAFORCUSTOMERREPLIES` — enable CAPTCHA on customer reply forms
- `APP_TICKET_CREATION_WAITTIME` — minutes between ticket submissions (anti-spam)

---

## Software-Layer Concerns

**Installation:**
```bash
git clone https://github.com/danielbrendel/dnyHelpRealm.git
cd dnyHelpRealm
composer install
cp .env.example .env
php artisan key:generate
# Edit .env with DB, mail, and app settings
php artisan migrate
php artisan db:seed
```

**Web server:** Point document root to the `public/` directory. Requires URL rewriting (Apache `.htaccess` included; Nginx: `try_files $uri $uri/ /index.php`).

**Cron job (email-to-ticket polling):**
```bash
* * * * * php /path/to/helprealm/artisan schedule:run >> /dev/null 2>&1
```
The scheduler polls the configured IMAP mailbox and creates tickets from incoming emails.

**Multi-tenant:** Each workspace has its own contact form URL and agent pool. Superadmins manage all workspaces.

**Ticket workflow:**
1. Customer submits via contact form, email, or API
2. Ticket lands in the index group
3. Agents route to specialized groups as needed
4. Communication via web thread or email reply
5. Secret thread link lets customers reply without an account

**Upgrade procedure:**
```bash
git pull
composer install
php artisan migrate
```

---

## Gotchas

- **No Docker image** — PHP/Laravel manual deploy; requires PHP 8.2+, MySQL/MariaDB, and a configured mail server
- **IMAP required for email-to-ticket** — configure a dedicated email address for inbound ticket creation
- **`MAILSERV_CRONPW`** — this is a password used to protect the cron-triggered mail polling endpoint; set it to something strong
- **Stripe integration** — `APP_PAYFORAPI=true` requires Stripe keys; leave false for free API access
- **SaaS architecture** — multiple customers/workspaces can share one instance; workspace isolation is enforced at the application level

---

## Links
- GitHub: https://github.com/danielbrendel/dnyHelpRealm
- .env.example: https://github.com/danielbrendel/dnyHelpRealm/blob/master/.env.example
