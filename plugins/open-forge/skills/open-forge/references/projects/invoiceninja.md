# Invoice Ninja

Open-source invoicing, billing, and payment management platform. Supports clients, invoices, quotes, recurring billing, expense tracking, time tracking, projects, and payment gateway integrations (Stripe, PayPal, etc.). Built with Laravel + Flutter (mobile/desktop). v5 is the current stable version. Upstream: <https://github.com/invoiceninja/invoiceninja>. Docs: <https://invoiceninja.github.io/docs/self-host-installation/>.

> **License note:** Invoice Ninja is open-source (Elastic License 2.0 for v5). A $30/year white-label license removes Invoice Ninja branding from client-facing pages.

## Compatible install methods

Verified against upstream Docker repo at <https://github.com/invoiceninja/dockerfiles>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (Debian image) | `git clone -b debian https://github.com/invoiceninja/dockerfiles` | ✅ | Recommended. Includes Chrome for PDF generation. |
| Docker Compose (Alpine image) | `git clone https://github.com/invoiceninja/dockerfiles` | ✅ | Lighter image, no built-in Chrome. |
| Cloudron | <https://cloudron.io/store/com.invoiceninja.cloudronapp.html> | Community | Cloudron app store. |
| Softaculous | <https://www.softaculous.com/apps/ecommerce/Invoice_Ninja> | Community | One-click shared hosting. |
| Yunohost | <https://github.com/YunoHost-Apps/invoiceninja_ynh> | Community | Yunohost. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "App URL for Invoice Ninja (e.g. `http://invoiceninja.example.com`)?" | Free-text | All |
| app_key | "Laravel APP_KEY (generate one)?" | `base64:...` string | All — **required** |
| admin_email | "Initial admin email?" | Email | All |
| admin_password | "Initial admin password?" | Free-text (sensitive) | All |
| db_password | "MySQL password?" | Free-text (sensitive) | All |
| db_root_password | "MySQL root password?" | Free-text (sensitive) | All |

## Software-layer concerns

### Generate APP_KEY first

The `APP_KEY` must be generated before starting containers:

```bash
docker run --rm -it invoiceninja/invoiceninja-debian php artisan key:generate --show
# Outputs: base64:XXXXX...
```

Copy the entire string into your `.env` at `APP_KEY=base64:...`.

### Clone and configure (Debian image — recommended)

```bash
git clone https://github.com/invoiceninja/dockerfiles.git -b debian
cd dockerfiles/debian
# Edit .env
```

### .env file

```bash
APP_URL=http://invoiceninja.example.com
APP_KEY=base64:<generate-this>
APP_DEBUG=false
REQUIRE_HTTPS=false      # Set to true if behind HTTPS proxy

DB_HOST=mysql
DB_DATABASE=invoiceninja
DB_USERNAME=invoiceninja
DB_PASSWORD=<db-password>
DB_ROOT_PASSWORD=<db-root-password>

IN_USER_EMAIL=admin@example.com    # Initial admin account
IN_PASSWORD=<admin-password>       # Remove after first start

REDIS_HOST=redis
```

### docker-compose.yml (from upstream)

```yaml
services:
  app:
    image: invoiceninja/invoiceninja-debian:latest
    restart: unless-stopped
    env_file:
      - ./.env
    volumes:
      - app_public:/var/www/html/public
      - app_storage:/var/www/html/storage
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx:/etc/nginx/conf.d:ro
      - app_public:/var/www/html/public:ro
      - app_storage:/var/www/html/storage:ro
    depends_on:
      - app

  mysql:
    image: mysql:8
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USERNAME}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]

  redis:
    image: redis:alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  app_public:
  app_storage:
  mysql_data:
  redis_data:
```

### PDF generation

The Debian image includes **Chrome** (Chromium) for high-quality PDF invoice generation. This is the primary reason to prefer the Debian image over Alpine.

> **Gotcha:** For PDF generation to work when using localhost, the domain name **must end in `.test`** (due to Chrome's DNS resolver). For any real domain (`.com`, `.example.com`), this is not an issue.

### After initial startup

1. Remove `IN_USER_EMAIL` and `IN_PASSWORD` from `.env` after the admin account is created.
2. Log in at `http://your-domain` with the credentials you set.
3. Complete the setup wizard (company name, logo, etc.).

### Data directories

| Path | Contents |
|---|---|
| `app_storage` volume | Uploaded files, generated PDFs, logs |
| `app_public` volume | Public assets (shared with nginx) |
| `mysql_data` volume | MySQL database |

### Payment gateway integrations

Invoice Ninja supports many payment gateways — configure under Settings → Payment Gateways:

- Stripe
- PayPal
- Square
- Braintree
- Authorize.Net
- GoCardless (SEPA/ACH)
- Checkout.com
- WePay

### API

Invoice Ninja has a full REST API. Generate API tokens at Settings → API Tokens. Docs: <https://api-docs.invoicing.co>.

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`

Laravel migrations run automatically. Back up MySQL before major version upgrades.

**v4 → v5:** Not a direct upgrade. Install v5 separately and use the migration tool in v4 at Settings → Account Management.

## Gotchas

- **APP_KEY is permanent.** Never change `APP_KEY` after initial setup — it encrypts stored data. If lost, encrypted data (payment credentials, etc.) cannot be recovered.
- **Remove `IN_USER_EMAIL`/`IN_PASSWORD` after first run.** These auto-create the admin account on first start. Leave them in and they'll be applied every restart (resetting the password).
- **NGINX is a separate container.** The `app` container is PHP-FPM only — it doesn't serve HTTP directly. The `nginx` container is required.
- **Chrome memory usage.** The Debian image includes Chromium for PDF generation, which uses significant RAM during PDF rendering. Budget at least 1 GB RAM for the app container.
- **`REQUIRE_HTTPS=true` breaks non-HTTPS setups.** Only set this if you have a proper TLS terminator in front.
- **v5 requires PHP 8.1+.** The Docker images include the right PHP version. Only relevant if installing on bare metal.

## Links

- Upstream: <https://github.com/invoiceninja/invoiceninja>
- Docker repo: <https://github.com/invoiceninja/dockerfiles>
- Self-host docs: <https://invoiceninja.github.io/docs/self-host-installation/>
- API docs: <https://api-docs.invoicing.co>
- Payment gateways: <https://invoiceninja.github.io/docs/payment-gateways/>
