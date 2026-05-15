---
name: WeKan
description: Open-source kanban board (Meteor/Node.js + MongoDB). Trello-like UI with real-time collaboration, privacy-focused, MIT licensed.
---

# WeKan

WeKan is a collaborative kanban board with real-time updates, built on Meteor + MongoDB. It runs self-hosted via Docker, Snap, bare metal, or as a Sandstorm app. The docker-compose path is the most common for small-team self-hosting.

- Upstream repo: <https://github.com/wekan/wekan>
- Project site: <https://wekan.fi>
- Install matrix: <https://wekan.fi/install/>
- Docker images (three registries, same content):
  - `ghcr.io/wekan/wekan`
  - `quay.io/wekan/wekan`
  - `wekanteam/wekan` (Docker Hub)

## Compatible install methods

| Infra          | Runtime                             | Notes                                                               |
| -------------- | ----------------------------------- | ------------------------------------------------------------------- |
| Single VM      | Docker + Compose (MongoDB)          | Default path; upstream ships `docker-compose.yml`                   |
| Single VM      | Docker + Compose (FerretDB)         | Alternative; upstream ships `docker-compose-ferretdb.yml`           |
| Single host    | Snap package                        | Upstream-supported; different upgrade model                         |
| Kubernetes     | Community Helm chart                 | Not upstream-official                                               |
| Bare metal     | Meteor build from source            | Documented at wekan.fi/install but rarely used for production       |

## Resource requirements

Upstream baseline from the README:

- **≥ 1 GB RAM** for the WeKan app minimum
- **≥ 4 GB RAM** recommended for production servers
- **Monitor disk** — MongoDB corrupts if the disk fills. Alert on free space.

## Inputs to collect

| Input                    | Example                                    | Phase   | Notes                                                               |
| ------------------------ | ------------------------------------------ | ------- | ------------------------------------------------------------------- |
| `ROOT_URL`               | `https://wekan.example.com`                | Runtime | **Required**. Full origin incl. scheme; must match the user-facing URL exactly |
| `MONGO_URL`              | `mongodb://wekandb:27017/wekan`            | Runtime | Default points at the bundled `wekandb` service                      |
| Port mapping             | `80:8080` (or `3000:8080` behind a proxy)  | Runtime | Don't publish 8080 if you use an nginx/Caddy reverse proxy          |
| `MAIL_URL`, `MAIL_FROM`  | `smtps://user:pass@smtp.example.com:465`   | Runtime | Required for invites, password reset, notifications                 |
| `OAUTH2_*` or `LDAP_*`   | per provider                               | Runtime | Optional SSO; see env block in upstream compose for the full list    |
| S3 (optional)            | `S3='{"s3":{...}}'`                        | Runtime | File upload offload; local disk is the default                      |
| Admin email (first user) | `admin@example.com`                        | Runtime | First registered user becomes admin; set `WITH_API=true` for API    |

## Install via Docker Compose

Upstream's canonical file is extremely heavily commented — read through it to find the relevant sections. Minimal working stack:

```yaml
services:
  wekandb:
    image: mongo:7
    container_name: wekan-db
    restart: always
    command: >
      sh -c '
        mongod --oplogSize 128 --replSet rs0 --bind_ip_all --quiet &
        until mongosh --host 127.0.0.1 --quiet --eval "
          try { rs.status(); quit(0); }
          catch (e) {
            rs.initiate({_id:\"rs0\", members:[{_id:0,host:\"wekandb:27017\"}]});
            quit(1);
          }" >/dev/null 2>&1; do sleep 2; done
        wait
      '
    networks: [wekan-tier]
    expose: ["27017"]
    volumes:
      - wekan-db:/data/db
      - wekan-db-dump:/dump

  wekan:
    image: ghcr.io/wekan/wekan:v9.18   # pin — see https://github.com/wekan/wekan/releases
    container_name: wekan-app
    restart: always
    networks: [wekan-tier]
    ports:
      - 80:8080
    environment:
      - WRITABLE_PATH=/data
      - MONGO_URL=mongodb://wekandb:27017/wekan
      - ROOT_URL=https://wekan.example.com
      - METEOR_REACTIVITY_ORDER=oplog,polling
      # - MAIL_URL=smtps://user:pass@smtp.example.com:465
      # - MAIL_FROM=WeKan <wekan@example.com>
    depends_on: [wekandb]
    volumes:
      - wekan-files:/data:rw

volumes:
  wekan-db:
  wekan-db-dump:
  wekan-files:

networks:
  wekan-tier:
    driver: bridge
```

The full upstream example at <https://github.com/wekan/wekan/blob/main/docker-compose.yml> documents every optional env var (OAuth2, LDAP, CAS, S3, accessibility settings, Matomo integration) — **read it end to end** before customizing. There are ~190 env vars.

```sh
docker compose up -d
# Browse ROOT_URL → register the first account, which becomes admin.
```

## MongoDB replica-set requirement

**WeKan requires MongoDB running as a single-node replica set** (`rs0`) for change-stream reactivity. The upstream compose command initializes `rs0` automatically on first boot; don't "simplify" by removing the replSet setup or real-time updates break.

## Data & config layout

- Volume `wekan-db` → `/data/db` — MongoDB data (boards, cards, users)
- Volume `wekan-db-dump` → `/dump` — backup landing zone
- Volume `wekan-files` → `/data` inside wekan-app — `WRITABLE_PATH` for local file uploads (if S3 not configured)
- Configuration is entirely env-var driven — no persistent config file on disk

## Backup

```sh
# MongoDB dump — preferred, corruption-proof
docker compose exec -T wekandb mongodump --archive --gzip --db wekan > wekan-db-$(date +%F).archive.gz

# Restore:
docker compose exec -T wekandb mongorestore --archive --gzip < wekan-db-$(date +%F).archive.gz

# Uploads
docker run --rm -v compose_wekan-files:/data -v "$PWD":/backup alpine \
  tar czf /backup/wekan-files-$(date +%F).tgz -C /data .
```

Upstream's backup docs: <https://github.com/wekan/wekan/tree/main/docs/Backup>.

## Upgrade

Upstream's canonical upgrade sequence (from the compose file header comments):

1. `docker compose stop`
2. `docker rm wekan-app` (**app container only** — don't remove `wekan-db`!)
3. Update the `image:` tag in `docker-compose.yml` (or pull `latest` if you live dangerously)
4. `docker compose up -d`

**Major MongoDB upgrades** (3.x → 4.x → 5.x → 6.x → 7.x) may need `mongodump`/`mongorestore` with `--noIndexRestore` — see <https://github.com/wekan/wekan/tree/main/docs/Backup>.

## Gotchas

- **MongoDB replica set is mandatory.** "Simplified" compose files circulating online that run `mongod` without `--replSet rs0` will boot but real-time board updates silently break.
- **Removing `wekan-db` container deletes your data** unless the `wekan-db` *volume* is persisted. Always confirm `docker volume ls` before `docker compose down -v`.
- **`ROOT_URL` mismatch = broken sign-in + OAuth.** Set it to the exact origin users browse to, including `https://`.
- **First registered user is admin.** Disable open registration (`DISABLE_REGISTRATION=true`) after you've created the admin and invited known users.
- **The upstream compose ships `image: ghcr.io/wekan/wekan:latest`.** Pin to a version tag (<https://github.com/wekan/wekan/releases>) — the `latest` tag does move across majors.
- **MongoDB 7 + `METEOR_REACTIVITY_ORDER=oplog,polling`** is the upstream-recommended setting while change-streams performance issues are fixed (see comment in compose referencing issue #6307). Leave it unless you know you need pure change-streams.
- **CentOS 7 seccomp issue** — see issues #4585/#4587. Needs `security_opt: - seccomp:unconfined`. Not a problem on modern hosts.
- **S3 env var format is JSON-in-a-string.** Quote carefully: `S3='{"s3":{"key":"...","secret":"...","bucket":"...","region":"..."}}'`.
- **FerretDB alternative** (`docker-compose-ferretdb.yml`) replaces MongoDB with a Postgres-backed MongoDB-protocol shim. Useful if you don't want to maintain Mongo, but slightly less battle-tested for WeKan.
- **CSP + iframe:** if embedding WeKan inside another app, you may need `HTTP_FORWARDED_COUNT=1` set and CSP/frame-ancestors configured in your reverse proxy.

## Links

- Repo: <https://github.com/wekan/wekan>
- Canonical compose: <https://github.com/wekan/wekan/blob/main/docker-compose.yml>
- FerretDB compose: <https://github.com/wekan/wekan/blob/main/docker-compose-ferretdb.yml>
- FAQ: <https://github.com/wekan/wekan/blob/main/docs/FAQ/FAQ.md>
- Install matrix: <https://wekan.fi/install/>
- Releases: <https://github.com/wekan/wekan/releases>
- Backup docs: <https://github.com/wekan/wekan/tree/main/docs/Backup>
