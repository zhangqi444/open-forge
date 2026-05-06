---
name: wildduck
description: WildDuck recipe for open-forge. Covers Docker Compose install. WildDuck is a scalable no-SPOF IMAP/POP3 mail server backed by MongoDB and Redis, designed for multi-user deployments.
---

# WildDuck

Scalable, no-SPOF IMAP/POP3 mail server. Stores all email data — messages, folders, metadata — in sharded + replicated MongoDB, making it horizontally scalable and resilient to single-node failure. Follows Gmail's product philosophy. Provides an HTTP API for account management and programmatic email operations. Part of the Zone Mail Suite (ZMS). Upstream: <https://github.com/zone-eu/wildduck>. Website: <https://wildduck.email>. Docs: <https://docs.wildduck.email>.

**License:** EUPL-1.2 · **Language:** Node.js · **Default ports:** 143 (IMAP), 110 (POP3), 993 (IMAPS), 995 (POP3S), 8080 (API) · **Stars:** ~2,100

> **Complexity note:** WildDuck is a production-grade mail server designed for ISP/hosting-scale deployments. It requires MongoDB and Redis. It does **not** include SMTP (sending) — pair it with Haraka, Nodemailer, or ZoneMTA for outbound mail. Not recommended for single-user homelab setups — consider Stalwart Mail, Maddy, or Mailu for simpler deployments.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/zone-eu/wildduck> | ✅ | **Recommended** — includes MongoDB + Redis. |
| Manual (npm) | <https://docs.wildduck.email/docs/general/install> | ✅ | Bare-metal installs. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| api_token | "API access token (generate with: openssl rand -hex 32)" | Free-text | Required. |
| domain | "Mail domain? (e.g. mail.example.com)" | Free-text | All methods. |
| smtp | "Which SMTP server will handle outbound mail? (ZoneMTA / Haraka / external)" | AskUserQuestion | All methods. |

## Install — Docker Compose

```bash
git clone https://github.com/zone-eu/wildduck.git
cd wildduck
```

Create a `.env` file:

```bash
cat > .env << 'EOF'
WILDDUCK_API_TOKEN=your-secret-api-token-here
EOF
```

Start the stack:

```bash
docker-compose up -d
```

This launches:
- **wildduck** — IMAP/POP3 server + API
- **redis** — session storage and pub/sub
- **mongo** — email and account storage

Check status:
```bash
docker-compose logs -f wildduck
```

### Minimal Docker Compose (explicit)

```yaml
services:
  wildduck:
    image: ghcr.io/zone-eu/wildduck:latest
    restart: always
    ports:
      - "8080:8080"   # API
      - "143:143"     # IMAP
      - "110:110"     # POP3
      - "993:993"     # IMAPS
      - "995:995"     # POP3S
    depends_on:
      - redis
      - mongo
    environment:
      APPCONF_dbs_mongo: mongodb://mongo:27017/wildduck
      APPCONF_dbs_redis: redis://redis:6379/3
      APPCONF_api_host: 0.0.0.0
      APPCONF_api_accessToken: YOUR_API_TOKEN_HERE

  redis:
    image: redis:alpine
    restart: always
    volumes:
      - redis-data:/data

  mongo:
    image: mongo:7
    restart: always
    volumes:
      - mongo-data:/data/db

volumes:
  redis-data:
  mongo-data:
```

## API — account management

WildDuck uses an HTTP API (port 8080) to manage users, mailboxes, and messages:

```bash
API_TOKEN="your-api-token"
API="http://localhost:8080"

# Create a user account
curl -X POST "$API/users" \
  -H "X-Access-Token: $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"john","password":"secret","name":"John Doe"}'

# List users
curl "$API/users" -H "X-Access-Token: $API_TOKEN"

# Get user addresses
curl "$API/users/USER_ID/addresses" -H "X-Access-Token: $API_TOKEN"
```

Full API reference: <https://docs.wildduck.email/docs/category/wildduck-api>

## Connecting email clients

Once WildDuck is running, configure your email client:

| Setting | Value |
|---|---|
| IMAP server | your-server-ip |
| IMAP port | 143 (STARTTLS) or 993 (SSL) |
| POP3 port | 110 (STARTTLS) or 995 (SSL) |
| Username | The username you created via API |
| Password | The password you set via API |

## Outbound SMTP

WildDuck handles **receiving** mail (IMAP/POP3). For **sending** mail, you need a separate SMTP component:

- **[ZoneMTA](https://github.com/zone-eu/zone-mta)** — recommended, from the same team as WildDuck
- **[Haraka](https://haraka.github.io)** — plugin-based Node.js SMTP server
- **Nodemailer** — for application-level sending

## Software-layer concerns

| Concern | Detail |
|---|---|
| MongoDB required | WildDuck stores all emails and metadata in MongoDB. For production, use a replica set for durability. |
| Redis required | Used for session management, pub/sub between WildDuck instances, and caching. |
| No SMTP included | WildDuck is IMAP/POP3 only. You must add a separate SMTP server for sending. |
| Horizontal scaling | Multiple WildDuck instances can share one MongoDB + Redis cluster — this is the no-SPOF design. |
| TLS/SSL | TLS for IMAP/POP3 requires a certificate. Mount certs into the container and configure via `APPCONF_imap_*` env vars. |
| API token | The `api_accessToken` protects the management API. Treat it like a root password. |
| Email storage | MongoDB stores the full email content including attachments. Plan for storage growth proportional to mailbox usage. |
| Antispam | WildDuck doesn't include spam filtering. Pair with Rspamd or SpamAssassin upstream. |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the changelog for migration steps: <https://github.com/zone-eu/wildduck/releases>

## Gotchas

- **No outbound SMTP:** WildDuck only receives mail. Sending requires a separate SMTP server (ZoneMTA, Postfix, etc.). This is a common source of confusion.
- **MongoDB replica set for production:** The single-node `mongo` in Docker Compose is fine for development. In production, use a replica set to avoid data loss on MongoDB restart.
- **API token is your admin key:** The `api_accessToken` is the only authentication for the management API. Store it securely and don't expose port 8080 publicly without firewall rules.
- **Port 143/993 conflicts:** If you're running another mail server on the host, port 143 and 993 will conflict. Use a dedicated VM or adjust port mappings.
- **EUPL-1.2 license:** WildDuck uses the European Union Public License. This is a copyleft license with network-use provisions — review if you're building a commercial service on top of it.
- **Complexity vs alternatives:** For small deployments (1–10 users), Stalwart Mail, Maddy, or Mailu are significantly simpler. WildDuck's strength is large-scale multi-tenant deployments (100+ users).

## Upstream links

- GitHub: <https://github.com/zone-eu/wildduck>
- Website: <https://wildduck.email>
- Docs: <https://docs.wildduck.email>
- Installation guide: <https://docs.wildduck.email/docs/general/install>
- API reference: <https://docs.wildduck.email/docs/category/wildduck-api>
- GHCR image: <https://github.com/zone-eu/wildduck/pkgs/container/wildduck>
- ZoneMTA (SMTP companion): <https://github.com/zone-eu/zone-mta>
