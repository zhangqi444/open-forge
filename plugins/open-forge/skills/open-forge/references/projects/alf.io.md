---
name: alf.io
description: Alf.io recipe for open-forge. Open-source event attendance management and ticket reservation system. Covers Docker Compose and JAR-based deployment. Upstream: https://github.com/alfio-event/alf.io
---

# Alf.io

Open-source event attendance management and ticket reservation system. Built for event organisers who care about privacy, fair pricing, and security. Handles event creation, ticket sales (free and paid), check-in, invoicing, promo codes, waiting lists, and attendee management. Upstream: <https://github.com/alfio-event/alf.io> — GPL-3.0.

Alf.io is a Java/Spring Boot application backed by PostgreSQL.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/alfio-event/alf.io#running-docker-containers> | Yes | Recommended for self-hosting. All-in-one containerised stack. |
| JAR (standalone) | <https://github.com/alfio-event/alf.io/releases> | Yes | Bare-metal / existing server. Requires Java 17 + external PostgreSQL. |
| Demo | <https://demo.alf.io/authentication> | Yes (demo only) | Pre-configured demo environment for evaluation. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | PostgreSQL password | Sensitive | All |
| db | Database name (default: alfio) | Free-text | All |
| admin | Admin username and password | Free-text / sensitive | All |
| domain | Public hostname (e.g. tickets.example.com) | Free-text | All — used for callback URLs and ticket links |
| smtp | SMTP host, port, user, password | Free-text | Required — ticket confirmation emails, invoices |
| payments | Payment provider(s) to enable (Stripe, PayPal, Mollie, etc.) | Choice | Optional — for paid events |

## Docker Compose method

Upstream: <https://github.com/alfio-event/alf.io/blob/master/docker-compose.yml>

```yaml
version: "3.8"

services:
  alfio-db:
    image: postgres:16-alpine
    container_name: alfio-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: alfio
      POSTGRES_USER: alfio
      POSTGRES_PASSWORD: REPLACE_DB_PASSWORD
    volumes:
      - alfio_db:/var/lib/postgresql/data

  alfio:
    image: alfio/alf.io:latest
    container_name: alfio
    restart: unless-stopped
    depends_on:
      - alfio-db
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: postgres,jdbc-session
      DATASOURCE_URL: jdbc:postgresql://alfio-db:5432/alfio
      DATASOURCE_USERNAME: alfio
      DATASOURCE_PASSWORD: REPLACE_DB_PASSWORD
      ALFIO_PORT: 8080

volumes:
  alfio_db:
```

After starting, navigate to `http://<host>:8080/admin` and complete first-run setup.

## JAR (standalone) method

Requirements: Java 17+, PostgreSQL 10+.

```bash
# Download latest release JAR
wget https://github.com/alfio-event/alf.io/releases/latest/download/alfio-boot.jar

# Set environment and run
SPRING_PROFILES_ACTIVE=postgres,jdbc-session \
DATASOURCE_URL=jdbc:postgresql://localhost:5432/alfio \
DATASOURCE_USERNAME=alfio \
DATASOURCE_PASSWORD=REPLACE_DB_PASSWORD \
java -jar alfio-boot.jar
```

Access: `http://localhost:8080/admin`

## Key features

- **Event management:** Create events with start/end dates, capacity limits, categories, and pricing tiers
- **Ticket sales:** Free events, paid events, donation-based pricing, multi-currency
- **Payment providers:** Stripe, PayPal, Mollie, Saferpay, Revolut, bank transfer
- **Check-in:** QR code scanning via the Alf.io Scan Android/iOS app
- **Promo codes:** Percentage/fixed discounts, limited-use codes
- **Invoicing:** Automatic invoice generation (EU VAT compliant)
- **Waiting list:** Automatically notify waiting list when tickets become available
- **Attendee management:** Custom fields, export CSV, badge printing

## SMTP configuration

In Admin → System Configuration → Email:
- SMTP Host, Port (587 STARTTLS / 465 SSL)
- Auth credentials and From address

Email is required for ticket delivery, order confirmations, and invoices.

## Upgrade procedure

```bash
docker compose pull alfio
docker compose up -d alfio
```

Alf.io runs database migrations automatically on startup.

## Gotchas

- **PostgreSQL only.** Alf.io does not support MySQL, MariaDB, or SQLite. PostgreSQL 10+ required.
- **PostgreSQL user must NOT be superuser.** Row-level security policies enforce data isolation. Superuser bypasses RLS.
- **Public URL must be configured.** Ticket QR codes and payment callbacks use the configured public URL. Set it in Admin → System Configuration.
- **SMTP is required.** Tickets are delivered by email. Without working SMTP, orders complete but tickets cannot be sent.
- **Java 17 required.** Older JDK versions are not supported.
- **Reverse proxy for HTTPS.** Alf.io serves HTTP. Use Nginx/Caddy/Traefik for TLS termination.

## Upstream docs

- GitHub: <https://github.com/alfio-event/alf.io>
- Documentation: <https://alf.io/docs>
- Docker Hub: <https://hub.docker.com/r/alfio/alf.io>
- Demo: <https://demo.alf.io/authentication>
