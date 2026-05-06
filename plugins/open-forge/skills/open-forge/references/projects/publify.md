---
name: publify
description: Publify recipe for open-forge. Covers self-hosting the Ruby on Rails blogging and publishing platform. Upstream: https://github.com/publify/publify
---

# Publify

Ruby on Rails blogging and web publishing platform — the oldest active Rails open-source project (since 2004, originally "Typo"). Multi-user blog engine with IndieWeb principles: self-host your site, publish on your own site and syndicate elsewhere. Features include Twitter integration, Markdown/SmartyPants text filters, themes, plugins, and advanced SEO. Upstream: <https://github.com/publify/publify>.

**License:** MIT

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Manual Rails deploy (release ZIP or git clone) | https://github.com/publify/publify#install | ✅ | VPS/server with Ruby stack |
| Heroku (with S3 storage) | https://github.com/publify/publify#install-publify-on-heroku | ✅ | PaaS deployment |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| runtime | "Ruby version?" | CRuby 2.5, 2.6, or 2.7 | Required |
| database | "Database?" | MySQL / PostgreSQL / SQLite3 | All |
| database | "DB host/name/user/password?" | Free-text | MySQL/PostgreSQL |
| secrets | "SECRET_KEY_BASE?" | `rails secret` output | Required |
| storage | "File storage backend?" | Local / AWS S3 | S3 needed on Heroku |

## Install (VPS/server)

```bash
# Prerequisites: Ruby 2.5-2.7, Bundler, Node.js/Yarn (for asset compilation), ImageMagick

# 1. Download release or clone
wget https://github.com/publify/publify/releases/latest/download/publify.zip
unzip publify.zip && cd publify
# OR: git clone https://github.com/publify/publify.git && cd publify

# 2. Configure database
cp config/database.yml.mysql config/database.yml   # or .postgresql or .sqlite3
# Edit database.yml with your DB credentials

# 3. Install dependencies
bundle install

# 4. Set SECRET_KEY_BASE (add to .env or environment)
export SECRET_KEY_BASE=$(bundle exec rails secret)

# 5. Setup database and assets
bundle exec rake db:setup
bundle exec rake db:migrate
bundle exec rake db:seed
bundle exec rake assets:precompile

# 6. Start server (development)
bundle exec rails server
# For production: use Puma behind nginx/Apache, or Passenger
```

Access at `http://localhost:3000`. Complete setup via the admin wizard.

## Software-layer concerns

### Ruby and Rails versions

- Ruby: CRuby (MRI) 2.5, 2.6, or 2.7 (Rails 5.2.x requirement)
- Ruby on Rails: 5.2.x
- ImageMagick: required for image handling (`mini_magick` gem)

### Key environment variables

| Variable | Purpose |
|---|---|
| `SECRET_KEY_BASE` | Rails session secret; required in production |
| `DATABASE_URL` | Database connection (alternative to database.yml) |
| `RAILS_ENV` | Set to `production` for production deploys |
| `PROVIDER` | Storage backend: `LOCAL` (default) or `AWS` |
| `AWS_ACCESS_KEY_ID` | S3 access key (AWS only) |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key (AWS only) |
| `AWS_BUCKET` | S3 bucket name (AWS only) |

### Key directories

| Path | Purpose |
|---|---|
| `config/database.yml` | Database configuration |
| `public/files/` | Uploaded files (local storage) |
| `log/` | Rails log files |

### Production server setup

Use Puma as the application server behind nginx or Apache as a reverse proxy. A typical setup:

```bash
# Procfile / systemd
bundle exec puma -C config/puma.rb
```

nginx proxies to Puma socket/port; serve `public/` directly from nginx.

## Upgrade procedure

```bash
# Back up database first
git pull   # or extract new release
bundle install
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake assets:precompile
sudo systemctl restart puma   # or your app server
```

## Gotchas

- **Rails 5.2 / Ruby 2.x.** Publify uses Rails 5.2 and supports Ruby 2.5-2.7. Ruby 3.x is not supported without changes.
- **SECRET_KEY_BASE required in production.** Without it, Rails refuses to start. Set it in the environment or a `.env` file.
- **ImageMagick must be installed.** The `mini_magick` gem calls ImageMagick for image resizing; if it's missing, uploads will fail.
- **master branch is unstable.** Only deploy from tagged releases. The README warns: "Running the master branch in production is not recommended."
- **Heroku requires S3.** Heroku's ephemeral filesystem means local file storage is lost on dyno restart. Use S3 for uploads on Heroku.
- **IndieWeb focus.** Publify follows IndieWeb principles — ideal for personal publishing with your own domain. Not a general-purpose CMS.

## Upstream docs

- GitHub README: https://github.com/publify/publify
- Releases: https://github.com/publify/publify/releases/latest
- Demo: https://publify-demo.fly.dev/
