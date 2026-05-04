# Hyperswitch

Open-source composable payments infrastructure. Connect to 50+ payment processors via a single API, with intelligent routing, PCI-compliant vault, revenue recovery, and A/B testing — without vendor lock-in. Written in Rust. Apache 2.0. 43K+ GitHub stars. Upstream: <https://github.com/juspay/hyperswitch>. Docs: <https://docs.hyperswitch.io>.

Hyperswitch runs as a Rust API server backed by PostgreSQL and Redis, with an optional React control plane (Hyperswitch Control Center). The quickstart uses Docker Compose.

## Compatible install methods

Verified against upstream docs at <https://docs.hyperswitch.io/hyperswitch-open-source/deploy-hyperswitch-on-aws>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (local) | `docker compose up -d` | ✅ | Development + evaluation. |
| AWS CDK (one-click) | <https://docs.hyperswitch.io/hyperswitch-open-source/deploy-hyperswitch-on-aws> | ✅ | Production AWS deploy. |
| Kubernetes / Helm | <https://docs.hyperswitch.io/hyperswitch-open-source/going-live/self-hosting/kubernetes> | ✅ | Production K8s. |
| Hyperswitch Cloud | <https://app.hyperswitch.io/register> | ✅ (hosted) | Managed SaaS — free tier. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| admin_api_key | "Admin API key (generate: `openssl rand -hex 32`)?" | Free-text (sensitive) | All |
| db_password | "PostgreSQL password?" | Free-text (sensitive) | All |
| domain | "Public domain for Hyperswitch (e.g. `pay.example.com`)?" | Free-text | Production |
| encryption_key | "Encryption master key for card vault (32-byte hex)?" | Free-text (sensitive) | Production |

## Software-layer concerns

### Docker Compose quickstart

```bash
git clone https://github.com/juspay/hyperswitch
cd hyperswitch

# Start the stack (pulls images, runs migrations automatically)
docker compose up -d

# Wait for all services to be healthy (~2 min on first run)
docker compose ps

# The API will be available at:
# http://localhost:8080
```

### Services

| Service | Image | Role |
|---|---|---|
| `hyperswitch-server` | `docker.io/juspaydotin/hyperswitch-router:latest` | Core API — payment routing, processing |
| `hyperswitch-control-center` | `docker.io/juspaydotin/hyperswitch-control-center:latest` | React dashboard (port 9000) |
| `hyperswitch-web` | `docker.io/juspaydotin/hyperswitch-web:latest` | Payment SDK static server |
| `pg` | `postgres:latest` | Primary data store |
| `redis-standalone` | `redis:7` | Cache + session |
| `migration_runner` | `debian:trixie-slim` | Runs DB migrations on startup |

### Key environment variables (via `config/docker_compose.toml`)

| Variable | Purpose |
|---|---|
| `master_enc_key` | AES-256 encryption key for stored credentials — **set before first run** |
| `admin_api_key` | API key for admin operations — **change from default** |
| `secrets.jwt_secret` | JWT signing secret |
| `database.url` | PostgreSQL connection string |
| `redis.host` | Redis host |
| `email.smtp.*` | SMTP config for notification emails |

For production, copy `config/docker_compose.toml` → `config/deployment.toml` and override via `ROUTER__<SECTION>__<KEY>` environment variables.

### Connecting a payment processor

After the server is running:

1. Get your admin API key from config
2. Create a merchant account:
```bash
curl -X POST http://localhost:8080/accounts \
  -H "api-key: your-admin-api-key" \
  -H "Content-Type: application/json" \
  -d '{"merchant_id": "my_store", "merchant_name": "My Store"}'
```

3. Add a payment connector (example: Stripe):
```bash
curl -X POST http://localhost:8080/account/my_store/connectors \
  -H "api-key: your-merchant-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "connector_type": "payment_processor",
    "connector_name": "stripe",
    "connector_account_details": {
      "auth_type": "HeaderKey",
      "api_key": "sk_test_..."
    }
  }'
```

### Payments modules

| Module | Purpose |
|---|---|
| **Payment Router** | Core — route payments across 50+ processors |
| **Vault** | PCI-compliant storage for cards and payment methods |
| **Revenue Recovery** | Smart retry logic to recover failed payments |
| **Cost Observability** | Monitor payment costs, detect downgrades and fees |
| **Intelligent Routing** | ML-based routing to maximize approval rates |

### Supported connectors (50+)

Stripe, Adyen, Braintree, PayPal, Checkout.com, Klarna, Razorpay, Worldpay, Cybersource, Square, Mollie, NMI, Nuvei, Forte, Bluesnap, and many more. Full list: <https://docs.hyperswitch.io/hyperswitch-open-source/connector-integrations>

### Data directories

| Volume | Contents |
|---|---|
| `pg_data` | All payment, merchant, and routing data |
| `redisinsight_store` | Redis Insight data (optional monitoring UI) |

## Upgrade procedure

```bash
cd hyperswitch
git pull
docker compose pull
docker compose up -d
```

Migrations run automatically via the `migration_runner` service on startup.

## Gotchas

- **`master_enc_key` cannot be changed after first run.** It encrypts stored credentials. Generate a strong key before first startup.
- **`admin_api_key` must be changed.** Default is insecure — rotate before exposing to network.
- **PCI compliance is your responsibility.** Hyperswitch provides the vault and tooling, but you must ensure your infrastructure and processes meet PCI DSS requirements for cardholder data.
- **Heavy resource requirements.** The full stack (API + control center + PG + Redis) needs at least 4 GB RAM for comfortable operation.
- **Connectors require test/live credentials.** Hyperswitch provides routing but you must have accounts with the payment processors you want to connect.
- **Control Center is optional.** The `hyperswitch-control-center` service is the dashboard UI. You can run headless (API only) without it.
- **`ONE_CLICK_SETUP` environment variable.** Set to `true` in the `prestart-hook` service for a batteries-included local demo with seed data.
- **License: Apache 2.0.** Fully open-source, including commercial use.

## Links

- Upstream: <https://github.com/juspay/hyperswitch>
- Docs: <https://docs.hyperswitch.io>
- Self-hosting guide: <https://docs.hyperswitch.io/hyperswitch-open-source/going-live/self-hosting>
- AWS deploy: <https://docs.hyperswitch.io/hyperswitch-open-source/deploy-hyperswitch-on-aws>
- Kubernetes deploy: <https://docs.hyperswitch.io/hyperswitch-open-source/going-live/self-hosting/kubernetes>
- Connector list: <https://docs.hyperswitch.io/hyperswitch-open-source/connector-integrations>
- Control Center: <https://github.com/juspay/hyperswitch-control-center>
