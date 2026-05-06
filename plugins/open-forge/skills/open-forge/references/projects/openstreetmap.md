---
name: openstreetmap
description: OpenStreetMap website recipe for open-forge. Ruby on Rails app powering the OpenStreetMap website, API, and map browsing — for running your own OSM instance or contributing to the platform. Docker dev or Passenger production deploy. Upstream: https://github.com/openstreetmap/openstreetmap-website
---

# OpenStreetMap Website

The Ruby on Rails application that powers OpenStreetMap.org — the collaborative project to create a free editable map of the world. Self-host your own OSM instance for a private map database, custom geographic data platform, or development/testing of the OSM stack.

2,709 stars · GPL-2.0

Upstream: https://github.com/openstreetmap/openstreetmap-website
Website: https://www.openstreetmap.org
Docs: https://github.com/openstreetmap/openstreetmap-website/blob/master/doc/INSTALL.md
Related software: https://wiki.openstreetmap.org/wiki/Software

## What it is

openstreetmap-website is the full OSM web platform:

- **Map browsing** — Tile-based map browsing with layers
- **Editing API v0.6** — XML and JSON API for map data (compatible with JOSM, iD, Potlatch)
- **User accounts** — Registration, profiles, diary entries, messaging
- **GPX uploads** — Track upload, browsing, and API
- **Changeset management** — View and revert map edits
- **Notes** — User-submitted map notes for reporting issues
- **OAuth 2.0** — Authentication for API clients
- **Multi-language** — Translation via Translatewiki, 50+ languages

Note: This is the **web app only** — tile rendering requires additional software (e.g. mod_tile + renderd + Mapnik). The default dev install uses public tile and geocoding services.

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Dev containers | Official DOCKER.md; simplest dev setup |
| Dev containers | VSCode devcontainer | See DEVCONTAINER.md |
| Bare metal | Ruby + PostgreSQL + PostGIS | Manual install; see MANUAL_INSTALL.md |
| Production | Phusion Passenger + Nginx | Recommended production stack |

## Inputs to collect

### Phase 1 — Pre-install
- PostgreSQL + PostGIS database credentials
- OSM data to import (or start with empty database)
- Domain name for production
- Whether tile rendering is needed (requires additional setup)

### Phase 2 — Config (config/settings.local.yml)
  server_url: "https://osm.example.com"
  server_protocol: "https"
  status: "online"
  email_from: "OpenStreetMap <noreply@example.com>"
  oauth_10_support: false

## Software-layer concerns

### Dependencies
- Ruby 3.2+
- PostgreSQL 13+ with PostGIS extension
- ImageMagick (image processing)
- libxml2 (XML parsing)
- Node.js (asset compilation)

### Docker development install
  git clone https://github.com/openstreetmap/openstreetmap-website
  cd openstreetmap-website
  # See DOCKER.md for full instructions
  docker compose up -d db
  docker compose run --rm web bundle exec rails db:create
  docker compose run --rm web bundle exec rails db:migrate
  docker compose up web

Access at http://localhost:3000

### Config paths
- config/settings.yml — default settings (do not modify)
- config/settings.local.yml — local overrides (create this)
- config/database.yml — database connection
- config/storage.yml — file storage config

### Production with Passenger
  # Install Passenger + Nginx
  # Set RAILS_ENV=production
  bundle exec rails assets:precompile
  bundle exec i18n export
  # Configure Passenger to serve public/ directory

### Database import (OSM data)
Use osm2pgsql to import .osm.pbf data into PostgreSQL for tile rendering.
The website's own DB uses the Rails schema (not the osm2pgsql schema).

## Upgrade procedure

1. git pull
2. bundle install
3. bundle exec rails db:migrate
4. bundle exec rails assets:precompile (production)
5. Restart Passenger or web server

## Gotchas

- Tile rendering is separate — this repo is the web app; tiles come from a tile server (public OpenStreetMap tiles by default, or your own renderd/mod_tile setup)
- PostGIS required — standard PostgreSQL is not enough; must have PostGIS extension installed
- Production != development — production requires Passenger (not `rails server`), asset precompilation, and proper config
- CGIMap for performance — the included map API is memory-intensive and slow; replace with CGIMap (https://github.com/zerebubuth/openstreetmap-cgimap) for production
- Large data imports — importing even a small country's OSM data requires substantial disk space (10-100+ GB); plan accordingly
- This is for running OSM itself — most users who want to display maps should use Nominatim, tile servers, or OSM map libraries (Leaflet, MapLibre), not this repo

## Links

- Upstream README: https://github.com/openstreetmap/openstreetmap-website/blob/master/README.md
- Docker install: https://github.com/openstreetmap/openstreetmap-website/blob/master/DOCKER.md
- Manual install: https://github.com/openstreetmap/openstreetmap-website/blob/master/doc/MANUAL_INSTALL.md
- OSM Software wiki: https://wiki.openstreetmap.org/wiki/Software
- CGIMap: https://github.com/zerebubuth/openstreetmap-cgimap
