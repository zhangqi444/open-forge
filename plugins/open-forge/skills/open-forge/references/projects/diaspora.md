# diaspora*

Privacy-aware, federated social network. diaspora* is a decentralized social network where users control their own data by running their own "pod" (server instance). Pods communicate with each other using the Diaspora protocol, also compatible with ActivityPub/Mastodon federation.

**Official site:** https://diasporafoundation.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu 20.04/22.04 | Native (Ruby on Rails) | Primary supported install method |
| Any Linux host | Docker (community images) | No official Docker image; use community scripts |
| Debian / Raspberry Pi | Native | ARM supported via native install |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain name (required — diaspora\* uses the domain as part of user identity, e.g. `user@example.com`)
- Database: PostgreSQL (recommended) or MySQL/MariaDB
- Email/SMTP config for notifications
- Whether to federate publicly or run a private pod
- Storage: local filesystem or S3-compatible (for media uploads)

### Phase 2 — Deployment
- `environment.url` — public HTTPS URL of the pod
- Database credentials (`database.yml`)
- SMTP settings (`diaspora.toml`)
- Redis connection (required for background jobs via Sidekiq)
- S3 config (optional, for media storage)

---

## Software-Layer Concerns

### Installation (Ubuntu)

Follow the official installation guide — diaspora\* requires Ruby, Node.js, and several system packages:

```bash
# Install dependencies
sudo apt-get install build-essential libssl-dev libreadline-dev \
  libxml2-dev libxslt1-dev imagemagick libmagickwand-dev \
  libpq-dev nodejs redis-server postgresql

# Clone and install
git clone https://github.com/diaspora/diaspora.git
cd diaspora

# Install Ruby via rbenv (see wiki for exact version)
# Install bundler and gems
bundle install --without development test

# Configure
cp config/diaspora.toml.example config/diaspora.toml
cp config/database.yml.example config/database.yml
# Edit both files with your settings

# Initialize DB
RAILS_ENV=production bin/rake db:create db:migrate

# Precompile assets
RAILS_ENV=production bin/rake assets:precompile
```

### Key Config Files

**`config/diaspora.toml`** — main configuration:
```toml
[configuration.environment]
url = "https://example.com"
certificate_authorities = "/etc/ssl/certs/ca-certificates.crt"

[configuration.server]
rails_environment = "production"

[configuration.mail]
enable = true
sender_address = "no-reply@example.com"
smtp.host = "localhost"
smtp.port = 25
```

**`config/database.yml`** — database connection:
```yaml
common: &common
  adapter: postgresql
  host: "localhost"
  port: 5432
  username: "diaspora"
  password: "your-password"
```

### Services to Run
| Service | Command | Purpose |
|---------|---------|---------|
| Web | `bundle exec unicorn -c config/unicorn.rb -E production` | HTTP app server |
| Sidekiq | `bundle exec sidekiq` | Background job processing (federation, notifications) |
| Redis | `redis-server` | Required by Sidekiq |

Use `bin/diaspora.sh` to start all services together, or run individual systemd units.

### Systemd Units
The wiki provides [systemd unit templates](https://wiki.diasporafoundation.org/Installation/Debian_Jessie_and_Ubuntu_Vivid#Start_diaspora*_on_boot_with_systemd).

---

## Upgrade Procedure

```bash
cd diaspora
git pull
RAILS_ENV=production bundle install --without development test
RAILS_ENV=production bin/rake db:migrate
RAILS_ENV=production bin/rake assets:precompile
# Restart web and Sidekiq processes
```

Always check the [Changelog](https://github.com/diaspora/diaspora/blob/develop/Changelog.md) before upgrading.

---

## Gotchas

- **Domain is permanent** — the pod URL is baked into all user identities (`user@yourdomain.com`). Changing the domain later is not supported.
- **HTTPS required** — diaspora\* requires a valid TLS certificate for federation. Use Let's Encrypt + Nginx.
- **Redis is mandatory** — Sidekiq workers use Redis for job queuing; no Redis = no federation or email delivery.
- **No official Docker image** — the upstream project does not maintain a Docker image. Community images exist but may lag behind.
- **Federation with Mastodon:** diaspora\* supports ActivityPub federation; diaspora\* users can follow Mastodon accounts.
- **Resource requirements:** A small pod (< 50 users) needs at least 2 GB RAM for Rails + Sidekiq.

---

## References
- GitHub: https://github.com/diaspora/diaspora
- Official site: https://diasporafoundation.org/
- Installation wiki: https://wiki.diasporafoundation.org/Installation
- Pod list: https://diaspora.fediverse.observer
- Changelog: https://github.com/diaspora/diaspora/blob/develop/Changelog.md
