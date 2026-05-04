# GrowthBook

Open-source feature flagging, A/B testing, and product analytics platform. GrowthBook provides SDKs in 24 languages, a warehouse-native stats engine (CUPED, Sequential, Bayesian), and a built-in product analytics suite. The core is MIT-licensed; some enterprise directories use the GrowthBook Enterprise License. Upstream: <https://github.com/growthbook/growthbook>. Docs: <https://docs.growthbook.io/self-host>.

GrowthBook runs as a web app (port `3000`) + API (port `3100`) backed by MongoDB.

## Compatible install methods

Verified against upstream README and docs at <https://docs.growthbook.io/self-host>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | `git clone … && docker compose up -d` | ✅ | Recommended self-hosted path. Includes MongoDB. |
| Kubernetes (Helm) | <https://docs.growthbook.io/self-host/kubernetes> | ✅ | Production scale / K8s environments. |
| Docker (single container) | `docker run growthbook/growthbook` | ✅ | Quick eval — bring your own MongoDB. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "External URL for GrowthBook UI (e.g. `https://growthbook.example.com`)?" | Free-text | Production |
| api_host | "External URL for GrowthBook API (e.g. `https://growthbook-api.example.com`)?" | Free-text | Production |
| mongo_uri | "MongoDB connection URI?" | Free-text (`mongodb://...`) | Custom MongoDB only |
| email | "SMTP host for email notifications?" | Free-text | Optional, for alerts |
| s3 | "S3-compatible bucket for uploads?" | Free-text | Optional, for image uploads |

## Software-layer concerns

### Docker Compose quickstart

```bash
git clone https://github.com/growthbook/growthbook.git
cd growthbook
docker compose up -d
```

Visit `http://localhost:3000`. Default compose includes MongoDB.

### Production docker-compose.yml

```yaml
services:
  mongo:
    image: mongo:latest
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: "${MONGO_PASSWORD}"
    volumes:
      - mongodata:/data/db
    restart: unless-stopped

  growthbook:
    image: growthbook/growthbook:latest
    ports:
      - "3000:3000"   # Web UI
      - "3100:3100"   # API / SDK endpoints
    depends_on:
      - mongo
    environment:
      MONGODB_URI: "mongodb://root:${MONGO_PASSWORD}@mongo:27017/growthbook?authSource=admin"
      APP_ORIGIN: "https://growthbook.example.com"
      API_HOST: "https://growthbook-api.example.com"
      JWT_SECRET: "${JWT_SECRET}"
      ENCRYPTION_KEY: "${ENCRYPTION_KEY}"
    volumes:
      - uploads:/usr/local/src/app/packages/back-end/uploads
    restart: unless-stopped

volumes:
  uploads:
  mongodata:
```

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `MONGODB_URI` | MongoDB connection string | Required |
| `APP_ORIGIN` | Public URL of the web UI | Required for production (e.g. `https://growthbook.example.com`) |
| `API_HOST` | Public URL of the API/SDK server | Required for production (e.g. `https://api.growthbook.example.com`) |
| `JWT_SECRET` | JWT signing secret | Required for production. Generate: `openssl rand -hex 32` |
| `ENCRYPTION_KEY` | Encryption key for saved credentials | Required for production. Generate: `openssl rand -hex 32` |
| `EMAIL_ENABLED` | Enable email notifications | `true` / `false` |
| `EMAIL_HOST` | SMTP host | When `EMAIL_ENABLED=true` |
| `EMAIL_PORT` | SMTP port | When `EMAIL_ENABLED=true` |
| `EMAIL_FROM` | From address | When `EMAIL_ENABLED=true` |
| `S3_BUCKET` | S3 bucket for uploads | Optional — alternative to local uploads volume |
| `DISABLE_TELEMETRY` | Opt out of usage analytics | `true` |

### Port layout

| Port | Service |
|---|---|
| `3000` | Web UI (React app + Next.js) |
| `3100` | SDK API (feature flag evaluation endpoints) |

**Important:** SDK API (`3100`) is what your apps call to evaluate feature flags. It must be publicly accessible if your apps are outside the Docker network.

### SDK integration

After setting up GrowthBook, integrate with your app using one of 24 SDKs:

```javascript
// JavaScript SDK
import { GrowthBook } from "@growthbook/growthbook";
const gb = new GrowthBook({
  apiHost: "https://growthbook-api.example.com",
  clientKey: "sdk-xxxx",  // from GrowthBook UI
});
await gb.init();

const isEnabled = gb.isOn("my-feature");
```

### Data directories

| Path | Contents |
|---|---|
| MongoDB `growthbook` database | All feature flags, experiments, metrics, results |
| `/uploads` volume | Uploaded images and screenshots |

### MCP server

GrowthBook ships an MCP server for AI agents:

```bash
# Connect to MCP
npx @growthbook/mcp --apiKey=secret_xxxx --apiHost=https://growthbook-api.example.com
```

Enables AI agents to create features, start experiments, and clean up stale flags.

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`

GrowthBook runs database migrations automatically on startup.

## Gotchas

- **Two ports, two different functions.** Port `3000` = UI; port `3100` = SDK API. Don't confuse them. Your apps call `3100`.
- **MongoDB required.** GrowthBook does not support other databases. Use MongoDB 5.0+.
- **`APP_ORIGIN` and `API_HOST` must be set in production.** Without these, email links and SDK connections will use `localhost` and break.
- **Open Core license.** The MIT core is fully functional. Some directories (`/packages/enterprise/`) are under the GrowthBook Enterprise License and require a paid plan.
- **Warehouse-native stats requires a data source.** The advanced stats engine connects directly to your data warehouse (BigQuery, Snowflake, Databricks, etc.). Configure data sources under Settings → Data Sources.
- **SDK endpoints are unauthenticated by design.** SDK API calls use client keys (not secrets) and are meant to be called from browsers/mobile apps. They return only what features are enabled, not sensitive experiment data.

## Links

- Upstream: <https://github.com/growthbook/growthbook>
- Docs: <https://docs.growthbook.io/self-host>
- SDK docs: <https://docs.growthbook.io/lib>
- Kubernetes/Helm: <https://docs.growthbook.io/self-host/kubernetes>
- Data sources: <https://docs.growthbook.io/app/datasources>
