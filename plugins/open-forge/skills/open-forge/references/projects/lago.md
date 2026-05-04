# Lago

Open-source metering, billing, and revenue infrastructure for product-led companies. Handles usage-based billing, subscriptions, hybrid pricing, invoicing, and payment orchestration. API-first, payment-agnostic (Stripe, Adyen, GoCardless, etc.). Trusted by PayPal, Mistral AI, Groq, Laravel. AGPL v3. Upstream: <https://github.com/getlago/lago>. Docs: <https://doc.getlago.com>.

Lago runs as multiple services: Rails API (`api`) on port `3000`, React frontend (`front`) on port `80`, PostgreSQL, Redis, PDF renderer, and data API.

## Compatible install methods

Verified against upstream README at <https://github.com/getlago/lago#self-hosted>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | `git clone https://github.com/getlago/lago && docker compose up` | ✅ | Standard self-hosted path. |
| Helm (Kubernetes) | <https://doc.getlago.com/guide/lago-self-hosted/helm> | ✅ | Production K8s deploy. |
| Lago Cloud | <https://getlago.com/pricing> | ✅ (hosted) | Fastest start — no infra to manage. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain_api | "Public URL for Lago API (e.g. `http://lago-api.example.com:3000`)?" | Free-text | Production |
| domain_front | "Public URL for Lago UI (e.g. `http://lago.example.com`)?" | Free-text | Production |
| rsa_key | "RSA private key (auto-generate)?" | Auto-generated via `openssl genrsa 2048 | openssl base64 -A` | All |
| db_password | "PostgreSQL password?" | Free-text (sensitive) | All |
| secret_key | "Rails SECRET_KEY_BASE (generate: `openssl rand -hex 64`)?" | Free-text (sensitive) | All |
| encryption_keys | "Encryption keys (3× `openssl rand -hex 32`)?" | Free-text (sensitive) | All |

## Software-layer concerns

### Quickstart

```bash
# Clone the repo
git clone --depth 1 https://github.com/getlago/lago.git
cd lago

# Generate RSA key (required for JWT signing)
echo "LAGO_RSA_PRIVATE_KEY=\"$(openssl genrsa 2048 | openssl base64 -A)\"" >> .env
source .env

# Start everything
docker compose up
```

Visit `http://localhost` for the UI. API is at `http://localhost:3000`.

### Required secrets to generate before first run

```bash
# RSA private key (for JWT)
openssl genrsa 2048 | openssl base64 -A

# Rails secret key base
openssl rand -hex 64

# Encryption keys (need 3)
openssl rand -hex 32   # LAGO_ENCRYPTION_PRIMARY_KEY
openssl rand -hex 32   # LAGO_ENCRYPTION_DETERMINISTIC_KEY
openssl rand -hex 32   # LAGO_ENCRYPTION_KEY_DERIVATION_SALT
```

Add these to your `.env` file.

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `LAGO_RSA_PRIVATE_KEY` | JWT signing key | **Required** — generate with openssl |
| `LAGO_API_URL` | Public API URL | Default: `http://localhost:3000` |
| `LAGO_FRONT_URL` | Public frontend URL | Default: `http://localhost` |
| `SECRET_KEY_BASE` | Rails session encryption | **Required** — generate with `openssl rand -hex 64` |
| `LAGO_ENCRYPTION_PRIMARY_KEY` | Data encryption primary key | **Required** |
| `LAGO_ENCRYPTION_DETERMINISTIC_KEY` | Data encryption deterministic key | **Required** |
| `LAGO_ENCRYPTION_KEY_DERIVATION_SALT` | Key derivation salt | **Required** |
| `DATABASE_URL` | PostgreSQL connection string | Auto-set from compose |
| `REDIS_URL` | Redis connection string | Auto-set from compose |
| `LAGO_USE_AWS_S3` | Use S3 for file storage | `true` / `false` |
| `LAGO_AWS_S3_BUCKET` | S3 bucket name | When S3 enabled |
| `LAGO_FROM_EMAIL` | SMTP from address | For invoice emails |
| `LAGO_SMTP_ADDRESS` | SMTP host | For invoice emails |
| `LAGO_SMTP_PORT` | SMTP port | Default: `587` |
| `LAGO_DISABLE_SIGNUP` | Disable new org signup | `true` for closed installs |
| `LAGO_CREATE_ORG` | Create initial org on startup | `true` to auto-create |
| `LAGO_ORG_USER_EMAIL` | Initial org admin email | When `LAGO_CREATE_ORG=true` |
| `LAGO_ORG_USER_PASSWORD` | Initial org admin password | When `LAGO_CREATE_ORG=true` (sensitive) |
| `LAGO_LICENSE` | Enterprise license key | For enterprise features |

### Port layout

| Port | Service |
|---|---|
| `80` | Lago UI (React frontend via nginx) |
| `3000` | Lago API (Rails) |
| `3001` | PDF renderer (invoice PDFs) |
| `8080` | Data API (analytics/reporting) |

### Architecture (services)

| Service | Role |
|---|---|
| `api` | Rails backend — billing logic, REST API |
| `front` | React frontend — web UI |
| `worker` | Sidekiq background workers — async billing jobs |
| `clock` | Scheduled job runner (subscriptions, renewals, invoicing) |
| `pdf` | Puppeteer-based PDF renderer for invoices |
| `data-api` | Analytics/revenue data API |
| `db` | PostgreSQL 15 (with partman for time-series) |
| `redis` | Job queue + cache |

### API usage

Lago is fully API-first. Core workflows:

```bash
# Get your API key from Settings → API Keys in the UI
API_KEY="your-api-key"
BASE_URL="http://localhost:3000"

# Create a billable metric (track usage)
curl -X POST "$BASE_URL/api/v1/billable_metrics" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"billable_metric": {"name": "API Calls", "code": "api_calls", "aggregation_type": "count_agg"}}'

# Ingest a usage event
curl -X POST "$BASE_URL/api/v1/events" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"event": {"transaction_id": "txn_001", "code": "api_calls", "external_customer_id": "cust_123"}}'
```

### Data directories

| Path | Contents |
|---|---|
| `lago_postgres_data` volume | PostgreSQL database |
| `lago_redis_data` volume | Redis data |
| `lago_storage_data` volume | Local file storage (invoices, attachments) |

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`

Lago runs Rails migrations automatically on API startup.

## Gotchas

- **RSA key is required.** The `LAGO_RSA_PRIVATE_KEY` must be set before first run. Lago will fail to start without it.
- **3 encryption keys, not 1.** You need `PRIMARY_KEY`, `DETERMINISTIC_KEY`, and `KEY_DERIVATION_SALT` — three separate 32-byte hex values.
- **`LAGO_API_URL` and `LAGO_FRONT_URL` must match your actual deployment.** These are baked into invoice PDFs and email links. Wrong values = broken links in emails to customers.
- **Clock service is critical.** The `clock` service triggers subscription renewals, invoice generation, and payment retries. Do not skip it.
- **AGPL v3 license.** If you modify Lago and use it in a networked service, you must release your modifications under AGPL. Lago Cloud (their hosted service) has a commercial license.
- **Enterprise features require a license.** Some features (SSO, advanced RBAC, audit logs) require a `LAGO_LICENSE` key from Lago.
- **S3 recommended for production file storage.** The default local volume is fine for testing; use S3-compatible storage for production (invoices, receipts).

## Links

- Upstream: <https://github.com/getlago/lago>
- Website: <https://getlago.com>
- Docs: <https://doc.getlago.com>
- Self-hosted guide: <https://doc.getlago.com/guide/lago-self-hosted/docker>
- API reference: <https://doc.getlago.com/api-reference>
- Helm chart: <https://doc.getlago.com/guide/lago-self-hosted/helm>
