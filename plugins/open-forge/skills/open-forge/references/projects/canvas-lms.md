---
name: canvas-lms
description: Canvas LMS recipe for open-forge. Covers Docker (canvas-docker) and full production install. Modern open-source LMS maintained by Instructure; powers thousands of universities and K-12 schools worldwide. Sourced from https://github.com/instructure/canvas-lms and https://github.com/instructure/canvas-lms/wiki.
---

# Canvas LMS

Modern, open-source Learning Management System (LMS) developed and maintained by [Instructure Inc.](https://www.instructure.com/). Powers thousands of universities, K-12 schools, and corporate training programs worldwide. Features include course management, assignments, gradebook, video conferencing, quizzes, analytics, mobile apps, LTI integrations, and accessibility compliance (WCAG 2.1). Upstream: https://github.com/instructure/canvas-lms. Wiki: https://github.com/instructure/canvas-lms/wiki. AGPLv3.

Canvas is a complex, enterprise-grade application. Self-hosted production deployments require significant infrastructure (PostgreSQL, Redis, Cassandra optional, object storage).

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| canvas-docker | https://github.com/instructure/canvas-docker | Local dev and evaluation |
| Production install | https://github.com/instructure/canvas-lms/wiki/Production-Start | Full production deployment |
| Quick Start (dev) | https://github.com/instructure/canvas-lms/wiki/Quick-Start | Development only |
| Instructure Cloud (hosted) | https://www.instructure.com/canvas | Managed SaaS; out of scope |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker evaluation or full production install?" | Drives path |
| domain | "Canvas domain?" | Required for SSL, email links |
| database | "PostgreSQL credentials?" | Required |
| storage | "S3/MinIO for file storage?" | Required for production (avoid local disk) |
| mail | "SMTP server for notifications?" | Required for user invitations, grades |
| admin | "Admin email address?" | First admin account |

## canvas-docker (dev/evaluation)

```sh
git clone https://github.com/instructure/canvas-docker.git
cd canvas-docker
docker-compose up -d
```

First-run generates a default admin. Access at http://localhost.

See https://github.com/instructure/canvas-docker for full instructions.

## Key infrastructure components

| Component | Purpose | Notes |
|---|---|---|
| PostgreSQL 14+ | Primary database | Required |
| Redis 7+ | Cache, sessions, queues | Required |
| S3 / MinIO | File and media storage | Required for production |
| Nginx | Reverse proxy + SSL | Recommended |
| Delayed Job workers | Background job processing | Required |
| Cassandra | Analytics data | Optional; for Learning Mastery/Outcomes |

## Production install overview (Ubuntu 22.04)

```sh
# 1. Install dependencies
sudo apt-get install -y ruby3.1 ruby3.1-dev zlib1g-dev libxml2-dev libsqlite3-dev \
    postgresql libpq-dev libxmlsec1-dev curl make g++ nodejs npm redis-server

# 2. Clone Canvas
git clone https://github.com/instructure/canvas-lms.git canvas
cd canvas
git checkout prod  # production branch

# 3. Install gems and JS
bundle install --path vendor/bundle
npm install
npm run build-css && npm run build

# 4. Configure
cp config/database.yml.example config/database.yml
cp config/redis.yml.example config/redis.yml
cp config/domain.yml.example config/domain.yml
cp config/outgoing_mail.yml.example config/outgoing_mail.yml
cp config/security.yml.example config/security.yml
# Edit each config file with actual credentials

# 5. Generate encryption keys
bundle exec rake db:create db:migrate
bundle exec rake canvas:compile_assets

# 6. Create admin and populate
bundle exec rake db:initial_setup

# 7. Configure file storage (config/storage.yml)
# Set S3/MinIO bucket and credentials

# 8. Start services
bundle exec script/delayed_job run
# Configure Nginx + Passenger or Puma
```

Full production docs: https://github.com/instructure/canvas-lms/wiki/Production-Start

## Key configuration files

| File | Purpose |
|---|---|
| config/database.yml | PostgreSQL connection |
| config/redis.yml | Redis connection |
| config/domain.yml | Canvas domain (affects URLs, OAuth) |
| config/outgoing_mail.yml | SMTP for email notifications |
| config/storage.yml | File storage (local, S3, Swift) |
| config/security.yml | Encryption keys (never lose this!) |

## Upgrade procedure

```sh
git pull origin prod
bundle install
npm install && npm run build
bundle exec rake db:migrate
bundle exec rake canvas:compile_assets
# Restart Puma/Passenger and delayed_job workers
```

Major version upgrades: read CHANGELOG and upgrade one major version at a time.

## Gotchas

- **AGPLv3 license** — If you modify Canvas and serve it over a network, you must release your modifications under AGPLv3.
- **Security keys** — `config/security.yml` contains encryption keys for user sessions and encrypted data. Losing this file means losing access to encrypted data; back it up securely and never rotate without a migration plan.
- **S3/object storage required for production** — Local file storage is not suitable for production; attachments and media must be stored in S3-compatible storage.
- **Complex asset pipeline** — Canvas uses a Ruby on Rails asset pipeline plus Webpack for JavaScript. Assets must be compiled (`canvas:compile_assets`) before deployment; this takes significant time (15-30 min).
- **Delayed Job workers** — Background jobs (email, grade calculations, imports) require `delayed_job` worker processes; production deployments need at least 2-4 workers running via Supervisor.
- **LTI integrations** — Canvas supports LTI 1.3 for third-party tool integrations (Zoom, Turnitin, etc.); configure under Admin → Developer Keys.
- **Mobile apps** — Instructure Canvas mobile apps (iOS/Android) connect to self-hosted instances; available on App Store / Google Play.

## Links

- GitHub: https://github.com/instructure/canvas-lms
- Production install wiki: https://github.com/instructure/canvas-lms/wiki/Production-Start
- canvas-docker: https://github.com/instructure/canvas-docker
- LTI developer guide: https://canvas.instructure.com/doc/api/file.lti_dev_key_config.html
- REST API: https://canvas.instructure.com/doc/api/
