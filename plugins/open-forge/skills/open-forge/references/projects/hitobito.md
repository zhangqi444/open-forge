---
name: hitobito
description: Hitobito recipe for open-forge. Open source web app for managing complex group hierarchies — members, roles, events, courses, mailings, and communication. Used by scouts, sports clubs, and multi-tier organisations. Ruby on Rails + PostgreSQL. Source: https://github.com/hitobito/hitobito
---

# Hitobito

Open source web application for managing complex group hierarchies with members, roles, events, courses, mailings, and communication. Designed for organisations with layered structures — national associations, regional chapters, local groups — where members have different roles at different levels. Used by scout organisations, sports clubs, and federated nonprofits. Ruby on Rails with PostgreSQL and Memcached. Deployment via Docker (dev kit) or Phusion Passenger + Apache. Upstream: https://github.com/hitobito/hitobito. Docs: https://hitobito.readthedocs.io (German). AGPLv3.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose (dev kit) | Linux / macOS | Official dev setup via hitobito/development |
| Phusion Passenger + Apache | Linux | Production install per deployment guide |
| Devcontainer / Codespaces | Linux / macOS | Quickest local start |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Public hostname?" | RAILS_HOST_NAME — used in email links |
| db | "PostgreSQL host/name/user/password?" | RAILS_DB_* env vars |
| cache | "Memcached host:port?" | MEMCACHE_SERVERS, default localhost:11211 |
| secret | "SECRET_KEY_BASE?" | Random 128-char hex string |
| email | "SMTP or sendmail config?" | RAILS_MAIL_DELIVERY_METHOD + RAILS_MAIL_DELIVERY_CONFIG |
| auth | "Root user email?" | RAILS_ROOT_USER_EMAIL — initial superadmin |

## Software-layer concerns

### Method 1: Docker development kit (recommended for testing)

  # Clone the development kit:
  git clone https://github.com/hitobito/development.git hitobito-dev
  cd hitobito-dev

  # Initialize the hit CLI helper:
  bin/dev-env.sh

  # Start the environment (first run seeds the database — takes a while):
  hit up

  # Access hitobito at http://localhost:3000

### Method 2: Production install (Phusion Passenger + Apache)

  # Prerequisites:
  # - Ruby >= 2.5 (use rbenv or rvm)
  # - Apache2 + Phusion Passenger
  # - PostgreSQL 16+
  # - Memcached
  # - Node.js (for asset compilation)

  # Clone the repo:
  git clone https://github.com/hitobito/hitobito.git /var/www/hitobito
  cd /var/www/hitobito

  # Install Ruby gems:
  bundle install --deployment

  # Set environment variables (see config below):
  cp config/settings.yml config/settings.local.yml
  # Edit settings.local.yml for your organisation's wagon (plugin)

  # Database setup:
  RAILS_ENV=production bundle exec rake db:create db:migrate db:seed

  # Compile assets:
  RAILS_ENV=production bundle exec rake assets:precompile

### Key environment variables (production)

  SECRET_KEY_BASE             128-char random hex (generate: openssl rand -hex 64)
  RAILS_HOST_NAME             Public domain name (e.g. members.example.org)
  RAILS_HOST_SSL              true or false
  RAILS_DB_NAME               PostgreSQL database name
  RAILS_DB_USERNAME           PostgreSQL user
  RAILS_DB_PASSWORD           PostgreSQL password
  RAILS_DB_HOST               PostgreSQL host
  RAILS_MAIL_DELIVERY_METHOD  smtp or sendmail
  RAILS_MAIL_DELIVERY_CONFIG  address: smtp.example.com, port: 587, user_name: ..., password: ...
  RAILS_MAIL_DOMAIN           Domain for mailing lists
  MEMCACHE_SERVERS            Memcached address(es), e.g. localhost:11211
  RAILS_ROOT_USER_EMAIL       Initial superadmin email (from wagon's settings.yml)

### Apache + Phusion Passenger vhost example

  <VirtualHost *:443>
      ServerName members.example.org
      DocumentRoot /var/www/hitobito/public

      PassengerRuby /path/to/ruby
      PassengerAppEnv production
      PassengerMaxPoolSize 4

      <Directory /var/www/hitobito/public>
          Options -MultiViews
          AllowOverride None
          Require all granted
      </Directory>
  </VirtualHost>

### Wagon (plugin) architecture

  # Hitobito core has no built-in group types.
  # Your organisation's structure is defined in a "wagon" (plugin).
  # hitobito_generic is the reference example:
  #   https://github.com/hitobito/hitobito_generic
  #
  # Wagons define group types, role types, and permissions.
  # Configure the active wagon in Gemfile.wagon and config/settings.yml.

### Root user setup

  # The root user email is defined in the wagon's settings.yml:
  # root_email: root@example.com
  # After seeding, use "Forgot Password" at the login page to set a password.

### Background jobs (required)

  # Hitobito uses delayed_job for async tasks (emails, exports):
  RAILS_ENV=production bundle exec rake jobs:work
  # Or run as a systemd service.

### Ports

  3000/tcp   # Dev server
  80/443     # Production via Apache/Passenger

## Upgrade procedure

  cd /var/www/hitobito
  git pull
  bundle install --deployment
  RAILS_ENV=production bundle exec rake db:migrate
  RAILS_ENV=production bundle exec rake assets:precompile
  # Restart Passenger: touch tmp/restart.txt

## Gotchas

- **Wagon required**: Hitobito core is useless without a wagon defining your group structure. Use `hitobito_generic` as a starting point or find your organisation's official wagon.
- **Root user password reset**: There's no installer with a password field. Use the "Forgot Password" link after first run to set the root user's password.
- **Background jobs must run**: Email delivery, exports, and async tasks use `delayed_job`. If the job worker isn't running, emails silently queue up and never send.
- **Memcached required**: Hitobito uses Memcached for session storage and caching. Install and configure it before starting the app.
- **PostgreSQL 16+ required**: Older PostgreSQL versions may work but are not officially supported. Use PostgreSQL 16+.
- **German documentation**: Most official documentation and the user guide are in German. English resources are limited to the developer docs.
- **Asset precompilation needed**: After any code change or gem update in production, run `rake assets:precompile` before restarting.
- **Dev kit uses Docker**: The development kit (hitobito/development) uses Docker Compose and a custom `hit` CLI. This is the easiest way to explore the app before committing to a production install.

## References

- Upstream GitHub: https://github.com/hitobito/hitobito
- Development kit: https://github.com/hitobito/development
- Documentation: https://hitobito.readthedocs.io
- Deployment guide (German): https://github.com/hitobito/hitobito/blob/master/doc/operator/01_deployment.md
- Generic wagon example: https://github.com/hitobito/hitobito_generic
- Website: https://hitobito.com
