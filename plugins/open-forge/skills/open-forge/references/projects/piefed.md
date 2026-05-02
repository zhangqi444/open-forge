---
name: piefed
description: Recipe for PieFed — federated discussion and link aggregation platform (Lemmy/Reddit alternative). Python/Flask, Docker Compose with PostgreSQL, requires domain + SSL. AGPL-3.0.
---

# PieFed

Federated discussion and link aggregation platform — a Lemmy/Mbin alternative. Upstream: https://codeberg.org/rimu/pyfedi

Python/Flask app with ActivityPub federation. Similar to Reddit/Lemmy — communities, posts, comments, voting. Designed for easy setup and management with few dependencies. AGPL-3.0. Interoperable with Lemmy, Mbin, and the wider fediverse.

Install docs: https://codeberg.org/rimu/pyfedi/src/branch/main/INSTALL-docker.md
Join an existing instance: https://piefed.social

## Prerequisites

- Registered domain name (**required** — SERVER_NAME cannot be changed after federation starts without wiping data)
- SSL/HTTPS (via reverse proxy: nginx, Caddy, Cloudflare Zero Trust Tunnel, Tailscale, etc.)
- Docker + Docker Compose

## Compatible combos

| Method | Notes |
|---|---|
| Docker Compose | Recommended — includes PostgreSQL, Redis, app containers |
| Manual (bare metal) | See INSTALL.md in the repo |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain name | e.g. piefed.example.com — cannot change after first federation without wiping DB |
| preflight | SECRET_KEY | Random string, 32+ characters |
| smtp (opt) | Mail settings | For email verification, notifications |
| preflight | Cloudflare (opt) | CF token for automatic SSL if using Cloudflare |

## Software-layer concerns

**Config:** `.env.docker` file (copy from `env.docker.sample`). Key vars:
- `SECRET_KEY` — random 32+ char string; keep this stable
- `SERVER_NAME` — domain name only, no http:// prefix. **Cannot change after federation without wiping all data.**

**Database init required:** After first `docker compose up`, you must run `flask init-db` inside the container to create the admin account:
```bash
sudo docker exec -it piefed_app1 sh
export FLASK_APP=pyfedi.py
flask init-db
```

**Directories must be created first:** Run `./docker-dirs.sh` before `docker compose up` to create `pgdata/`, `media/`, `logs/`, `tmp/` with correct permissions.

**Port:** 8030 (mapped to container's 5000).

**Federation requirement:** If your instance needs to federate with other instances, you need a publicly reachable domain. Testing with `127.0.0.1:8030` works but won't federate.

**Customizing compose:** Use `compose.override.yaml` rather than editing `compose.yaml` directly — makes upgrades cleaner.

## Setup steps

```bash
git clone https://codeberg.org/rimu/pyfedi.git
cd pyfedi/
git checkout v1.5.x    # use latest release branch

sudo cp env.docker.sample .env.docker
sudo nano .env.docker  # set SECRET_KEY and SERVER_NAME

./docker-dirs.sh       # create required directories

export DOCKER_BUILDKIT=1
sudo docker compose up --build

# In a new terminal, initialize the database:
sudo docker exec -it piefed_app1 sh
export FLASK_APP=pyfedi.py
flask init-db
# Enter username, email, password for admin account
```

## Upgrade procedure

```bash
git pull
git checkout <new-release-branch>
sudo docker compose up --build -d
```

Check Codeberg releases for migration notes. Database migrations run automatically via Flask on startup.

## Gotchas

- **SERVER_NAME is permanent** — changing it after federation requires wiping the database. Choose carefully before your instance goes live.
- **Domain required for federation** — without a publicly reachable domain + SSL, other fediverse instances cannot connect to yours.
- **DB init step is mandatory** — the app will show "Internal Server Error" until `flask init-db` is run on first launch.
- **`./docker-dirs.sh` must run first** — skipping this causes permission errors on container startup.
- **AGPL-3.0 license** — modifications offered as a network service must be released under AGPL-3.0.

## Links

- Upstream repository: https://codeberg.org/rimu/pyfedi
- Docker install guide: https://codeberg.org/rimu/pyfedi/src/branch/main/INSTALL-docker.md
- Main instance + community: https://piefed.social
- Matrix developer chat: https://matrix.to/#/#piefed-developers:matrix.org
