---
name: firefox-account-server
description: Firefox Accounts (Mozilla Accounts / FxA) recipe for open-forge. Self-hosted identity and authentication service powering Mozilla product sign-in (Firefox Sync, Mozilla VPN, etc.). Large Node.js monorepo with many microservices. Development setup via Docker Compose; production requires significant ops investment. Source: https://github.com/mozilla/fxa
---

# Firefox Accounts (Mozilla Accounts / FxA)

Self-hosted identity and authentication server that powers Mozilla product sign-in — Firefox Sync, Mozilla VPN, Pocket, and other Mozilla services. Provides account creation, OAuth2, WebCrypto-based Sync encryption, TOTP/2FA, and subscription management. Built as a large Node.js monorepo (`mozilla/fxa`) containing many microservices (auth-server, profile-server, content-server, sync tokenserver, payments, etc.). 

⚠️ **Complexity warning**: Running a full FxA stack in production is a significant infrastructure undertaking. Mozilla's own deployment uses hundreds of services and custom cloud infrastructure. The dev setup via Docker Compose works well for testing/development; production self-hosting is expert-level work. Upstream: https://github.com/mozilla/fxa. Docs: https://mozilla.github.io/ecosystem-platform/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose (dev stack) | Linux / macOS | Official dev setup; all services in containers |
| Manual (production) | Linux | Expert-level; requires Kubernetes or equivalent |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Public domain for FxA?" | e.g. accounts.example.com — used in OAuth redirects |
| email | "SMTP host/user/password?" | For account verification and password reset emails |
| secrets | "Random secrets for signing?" | Generated during setup |
| db | "MySQL host/credentials?" | Auth-server uses MySQL |
| cache | "Redis host?" | Used for session storage |

## Software-layer concerns

### Development setup (Docker Compose)

  # Prerequisites: Node.js 18+, Yarn, Docker, Docker Compose, Git
  # ~8 GB RAM recommended for the full dev stack

  git clone https://github.com/mozilla/fxa.git
  cd fxa

  # Install dependencies (monorepo with Yarn workspaces):
  yarn install

  # Start the full dev stack (all services via Docker Compose):
  cd packages/fxa-dev-launcher    # or see _dev/ folder
  # Follow: https://mozilla.github.io/ecosystem-platform/tutorials/development-setup

  # The dev stack starts containers for:
  #   - auth-server       (core account/session API)
  #   - content-server    (web UI for sign-in/sign-up pages)
  #   - profile-server    (avatar, display name)
  #   - sync tokenserver  (Firefox Sync)
  #   - payments          (subscription management)
  #   - MySQL, Redis, SQS emulator

### Key services and ports (dev stack defaults)

  3030   content-server (web UI)
  9000   auth-server (API)
  1111   profile-server
  8000   sync tokenserver
  9010   oauth-server
  5000   payments server

### Environment / config

  # Each package has its own config file and environment variables.
  # Auth-server key env vars:
  DB_MYSQL_HOST         MySQL host
  DB_MYSQL_USER         MySQL user
  DB_MYSQL_PASSWORD     MySQL password
  REDIS_HOST            Redis host
  EMAIL_SERVICE         SMTP or SES
  PUBLIC_URL            https://accounts.example.com
  DOMAIN                example.com

  # Full config docs: https://mozilla.github.io/ecosystem-platform/reference/configuration

### MySQL schema

  # Auth-server creates its own schema on first run.
  # MySQL 8+ required with utf8mb4 charset.

### Production considerations

  # Mozilla runs FxA on Kubernetes with GCP services (Cloud SQL, MemoryStore, SES).
  # For a minimal production self-host you need at minimum:
  # - MySQL instance (managed recommended)
  # - Redis instance
  # - SMTP relay (SES, Mailgun, etc.)
  # - Reverse proxy with TLS for each service
  # - Shared secret management
  # - Monitoring (FxA exports StatsD/CloudWatch metrics)
  #
  # See deployment guides:
  # https://mozilla.github.io/ecosystem-platform/reference/infrastructure/aws

### Configuring Firefox to use a custom FxA server

  # In Firefox about:config:
  identity.fxaccounts.autoconfig.uri = https://accounts.example.com/.well-known/fxa-client-configuration
  #
  # Or via enterprise policy / user.js:
  // user.js
  user_pref("identity.fxaccounts.autoconfig.uri", "https://accounts.example.com/.well-known/fxa-client-configuration");

### Reverse proxy (nginx) — content-server

  server {
      listen 443 ssl;
      server_name accounts.example.com;
      location / {
          proxy_pass http://127.0.0.1:3030;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-Proto https;
      }
  }

## Upgrade procedure

  cd fxa
  git pull
  yarn install
  # Restart containers or services
  # Check release notes for migration steps: https://github.com/mozilla/fxa/releases

## Gotchas

- **This is a large monorepo**: `fxa` contains 50+ packages. A full `yarn install` takes several minutes and downloads hundreds of MB.
- **Production complexity is very high**: Mozilla runs this on Kubernetes with a dedicated SRE team. Self-hosting in production requires significant expertise in Node.js, MySQL, Redis, and cloud infrastructure.
- **Dev stack uses many ports**: The dev Docker Compose stack opens 10+ ports. Ensure no conflicts on your machine.
- **Firefox must be pointed at your instance**: Firefox hardcodes its FxA endpoint in release builds. You need a custom Firefox build or about:config tweak to use your own server.
- **Email is required**: Account creation requires email verification. A working SMTP relay (SES, Mailgun, etc.) is mandatory.
- **Sync tokenserver is separate**: Firefox Sync storage (the actual encrypted sync data) is handled by a tokenserver + storage backend — this must also be running for Sync to work.
- **Name change**: "Firefox Accounts" was rebranded to "Mozilla Accounts" in 2023. The repo slug remains `fxa`.

## References

- Upstream GitHub: https://github.com/mozilla/fxa
- Documentation hub: https://mozilla.github.io/ecosystem-platform/
- Development setup: https://mozilla.github.io/ecosystem-platform/tutorials/development-setup
- How to run FxA: https://mozilla-services.readthedocs.io/en/latest/howtos/run-fxa.html
