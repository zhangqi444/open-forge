---
name: InvoiceShelf
description: "Open-source invoicing solution for individuals & businesses. Docker. Laravel + VueJS. InvoiceShelf/InvoiceShelf. Invoices + estimates + expenses + payments + customer portal + multi-company."
---

# InvoiceShelf

**Open-source invoicing solution for individuals & businesses.** Track expenses, payments, create professional invoices & estimates. Laravel + VueJS web app; React Native mobile companions. Forked from Crater (project inspiration).

Maintained by the **InvoiceShelf team**. Commercial entity behind it operates at invoiceshelf.com; software is fully open.

- Upstream repo: <https://github.com/InvoiceShelf/InvoiceShelf>
- Docker compose repo: <https://github.com/InvoiceShelf/docker>
- Docs: <https://docs.invoiceshelf.com>
- API docs: <https://api-docs.invoiceshelf.com>
- Website: <https://invoiceshelf.com>
- Discord: <https://discord.gg/eHXf4zWhsR>

## Architecture in one minute

- **Laravel (PHP 8.4+)** backend + **Vue.js** SPA frontend
- Storage: **SQLite** (default variant), **MySQL**, or **PostgreSQL** — three compose variants maintained upstream
- Port **8080** inside container; upstream example maps `8090:8080`
- Auth: Laravel Sanctum (cookie-based SPA sessions)
- Resource: **low-to-medium** (PHP-FPM + a DB)
- Multi-tenancy via **multiple companies** inside one install

## Compatible install methods

| Infra         | Runtime                               | Notes                                                                                   |
| ------------- | ------------------------------------- | --------------------------------------------------------------------------------------- |
| **Docker**    | `invoiceshelf/invoiceshelf`           | **Primary.** Three compose variants: SQLite, MySQL, PostgreSQL — pick one               |
| Docker Hub    | `invoiceshelf/invoiceshelf:nightly`   | Rolling nightly — use tagged releases for production                                    |

## Inputs to collect

| Input                         | Example                             | Phase    | Notes                                                                                                             |
| ----------------------------- | ----------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `APP_URL`                     | `https://invoice.example.com`       | URL      | **Must** match what users type in the browser, including scheme + port                                            |
| `SESSION_DOMAIN`              | `invoice.example.com`               | URL      | Host only, no scheme                                                                                              |
| `SANCTUM_STATEFUL_DOMAINS`    | `invoice.example.com`               | URL      | Comma-separated if multiple; Sanctum rejects session cookies otherwise                                            |
| DB choice                     | SQLite / MySQL / PostgreSQL         | Storage  | Pick one of the three compose variants                                                                             |
| DB creds (MySQL/PG only)      | user + pw + db                      | Storage  | Set in `.env` + compose                                                                                           |
| SMTP                          | Provider API key / user+pw          | Notify   | Required to email invoices to customers                                                                            |
| Admin email + password        | Install wizard                      | Auth     | First-run wizard creates the owner                                                                                 |
| Company info                  | Name, address, tax ID, currency     | Config   | Wizard prompts during first-run setup                                                                              |

## Install via Docker (SQLite variant)

Simplest path — single container, no external DB.

```yaml
# docker-compose.yml
services:
  webapp:
    image: invoiceshelf/invoiceshelf:nightly   # pin to a tagged release for prod
    container_name: invoiceshelf
    ports:
      - "8090:8080"
    volumes:
      - invoiceshelf_storage:/var/www/html/storage/
      - invoiceshelf_modules:/var/www/html/Modules/
    environment:
      - APP_NAME=InvoiceShelf
      - APP_ENV=production
      - APP_DEBUG=false
      - APP_URL=http://localhost:8090
      - SESSION_DOMAIN=localhost
      - SANCTUM_STATEFUL_DOMAINS=localhost
    networks:
      - invoiceshelf

volumes:
  invoiceshelf_storage:
  invoiceshelf_modules:

networks:
  invoiceshelf:
```

```sh
docker compose up -d
```

Visit `http://<host>:8090` and run the **installation wizard**.

## Install via Docker (MySQL or PostgreSQL variants)

Upstream compose files at <https://github.com/InvoiceShelf/docker>:

- `docker-compose.yml` — MySQL variant (entry point)
- `docker-compose.sqlite.yml` — SQLite variant (shown above)
- `docker-compose.pgsql.yml` — PostgreSQL variant

Pull the variant matching your DB, edit `APP_URL` / `SESSION_DOMAIN` / `SANCTUM_STATEFUL_DOMAINS` + DB env vars, then `docker compose up -d`.

## First boot

1. Deploy container(s).
2. Visit `APP_URL` → **installation wizard** walks through:
   - Environment check (PHP version, extensions)
   - DB connection test
   - Admin user creation
   - Company profile (name, address, tax ID, base currency)
3. **Configure SMTP** in Settings → Mail → send test email before mailing real customers.
4. Add bank / payment details (for "Pay with..." links on invoices).
5. Customize invoice template (logo, colors, footer text).
6. Create first customer + first invoice; preview + email it.
7. Put behind TLS.
8. Back up DB + storage volume + modules volume.

## Data & config layout

- `/var/www/html/storage/` — uploaded invoice attachments, generated PDFs, logs, cache
- `/var/www/html/Modules/` — installed addon modules (future marketplace)
- DB (SQLite file inside `storage/database/`, or external MySQL/PG) — invoices, estimates, customers, expenses, payments

## Backup

```sh
# SQLite variant — single container, one volume
docker compose stop webapp
sudo tar czf invoiceshelf-$(date +%F).tgz /var/lib/docker/volumes/<project>_invoiceshelf_storage/_data \
                                          /var/lib/docker/volumes/<project>_invoiceshelf_modules/_data
docker compose start webapp

# MySQL / PostgreSQL variants — pg_dump / mysqldump the DB container separately
```

Contents: **every invoice, customer PII, tax ID, bank details, full financial history.** Tier-1 sensitive. Encrypt backups, off-site, tested-restore.

## Upgrade

1. Releases: <https://github.com/InvoiceShelf/InvoiceShelf/releases>
2. **Starting v2.2.0 requires PHP 8.4+** — the in-app updater blocks upgrade if server PHP doesn't satisfy; pull a new image with the right PHP.
3. `docker compose pull && docker compose up -d`
4. The web UI has an **automatic update** option (in-app updater) — upstream supports it; still make a backup first.

## Gotchas

- **`APP_URL` / `SESSION_DOMAIN` / `SANCTUM_STATEFUL_DOMAINS` must match reality.** Laravel + Sanctum validate cookie domains strictly. If users see the app on `https://invoice.example.com` but `APP_URL` says `http://localhost:8090`, login breaks with cryptic "CSRF token mismatch" or blank 419 pages. Upstream issue #213 has the authoritative guidance.
- **Pin the Docker tag.** `invoiceshelf:nightly` is a rolling tag — use a semver release (`invoiceshelf/invoiceshelf:v2.2.x`) for production to avoid surprise upgrades.
- **Pick one DB variant and stick with it.** Migrating SQLite → MySQL/PG post-install requires manual dump+import; no upstream migration tool. Choose upfront.
- **PHP 8.4+ from v2.2.0.** The in-app updater blocks you if server PHP is too old. Docker images bundle the right PHP; manual installs on shared hosting are the common failure case.
- **SMTP is required for the product's core workflow** (emailing invoices to customers). Without it, you're a fancy PDF generator. Configure a provider (Resend/SendGrid/Mailgun) + verify the sending domain.
- **Invoice PDFs contain PII + financial info** — customer addresses, tax IDs, bank details. The `storage/` volume holds them. Secure the backup target appropriately.
- **The mobile app is "coming soon"** per the README — React Native repo exists but no public binaries yet.
- **Payment processing is roadmap, not shipped.** Stripe integration is unchecked on the roadmap. Invoices have "mark as paid" but don't collect payments directly (yet).
- **Multi-company inside one install.** Handy for contractors with multiple LLCs / freelancers juggling side projects — no need to run multiple InvoiceShelf instances.
- **Forked from Crater.** If you're searching older tutorials / issue threads, "crater-invoice" material often transfers. The codebases diverged in 2022.
- **In-app automatic update** is a non-trivial feature — it pulls new PHP code + runs migrations from inside a running container. Docker deploys should generally prefer pulling a new image + restart over the in-app updater (fewer moving parts).

## Project health

Active development, Discord, docs site, API docs, three Docker variants, mobile-app work in progress, forked from the widely-used Crater project. Multiple maintainers + contributor community.

## Invoicing-SaaS-alternative family

- **InvoiceShelf** — Laravel + Vue, three DB variants, multi-company, Crater fork
- **Crater** — original fork parent; less actively maintained now
- **Invoice Ninja** — bigger product, more complex, includes payments
- **Akaunting** — full accounting (invoices + expenses + reports) at a larger scope
- **Firefly III** — personal finance, not invoicing-focused
- **BookStack** — unrelated (wiki); common search confusion

**Choose InvoiceShelf if:** you want clean invoice + estimate + expense workflow, multi-company support, and don't need payments / full accounting yet.

## Links

- Repo: <https://github.com/InvoiceShelf/InvoiceShelf>
- Docker compose repo: <https://github.com/InvoiceShelf/docker>
- Docs: <https://docs.invoiceshelf.com>
- API docs: <https://api-docs.invoiceshelf.com>
- Crater (fork parent): <https://github.com/crater-invoice-inc/crater>
- Invoice Ninja (alt): <https://www.invoiceninja.com>
- Akaunting (alt): <https://akaunting.com>
