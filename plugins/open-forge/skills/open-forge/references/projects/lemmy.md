---
name: Lemmy
description: Self-hosted, federated (ActivityPub) Reddit alternative. Link aggregator + threaded discussions + communities, joins the "Threadiverse" alongside other Lemmy + Mbin + Piefed instances. Rust backend, Inferno (React-like) frontend. AGPL-3.0.
---

# Lemmy

Lemmy is the federated Reddit replacement that powers Beehaw, lemmy.ml, lemmy.world, and hundreds of other instances. You join an instance, post links + threads in communities, and your posts federate out to followers on other Lemmy / Mbin / Piefed servers. Unlike Reddit, there's no central moderator, no algorithm, no ads — each admin runs their instance under their own rules.

Rust backend (`lemmy_server`) + Inferno web UI (`lemmy-ui`) + pict-rs for images + Postgres + optional Postfix for outbound mail.

- Upstream repo: <https://github.com/LemmyNet/lemmy>
- Web UI repo: <https://github.com/LemmyNet/lemmy-ui>
- Docs: <https://join-lemmy.org/docs/>
- Install guide (Docker): <https://join-lemmy.org/docs/administration/install_docker.html>
- Ansible playbook: <https://github.com/LemmyNet/lemmy-ansible>

## Architecture in one minute

Five services in the production compose:

1. **`lemmy`** (Rust, `dessalines/lemmy`) — federation, API, ActivityPub inbox/outbox
2. **`lemmy-ui`** (Node.js, `dessalines/lemmy-ui`) — SSR frontend
3. **`pict-rs`** (`asonix/pictrs`) — image thumbnailing + storage
4. **`postgres`** (`pgautoupgrade/pgautoupgrade:18-alpine`) — main DB, uses pgautoupgrade for painless major bumps
5. **`postfix`** (`mwader/postfix-relay`) — outbound SMTP for password-reset etc.
6. **`proxy`** (nginx) — routes `/` → lemmy-ui, `/api` + `/pictrs` → lemmy, federation paths via Accept header negotiation
7. Optional: `pictrs-safety` — CSAM filtering sidecar

Ports: 80/443 public, everything else internal.

## Compatible install methods

| Infra      | Runtime                                          | Notes                                                                  |
| ---------- | ------------------------------------------------ | ---------------------------------------------------------------------- |
| Single VM  | **Lemmy Ansible playbook** (`LemmyNet/lemmy-ansible`) | **Strongly recommended.** Wraps the Docker compose with sensible vars  |
| Single VM  | Docker Compose (upstream from the lemmy-ansible templates) | Hand-rolled; works but you'll re-invent the ansible wheel      |
| Kubernetes | Community Helm charts (not upstream-maintained)  | Niche; stateful services make it less natural                          |
| Managed    | Hosted by someone else (beehaw.org, lemmy.world) | SaaS                                                                   |

## Inputs to collect

| Input                  | Example                               | Phase     | Notes                                                            |
| ---------------------- | ------------------------------------- | --------- | ---------------------------------------------------------------- |
| Domain                 | `lemmy.example.com`                   | DNS       | **PERMANENT** — baked into federated actor URLs; never changes   |
| `lemmy.hjson`          | see upstream template                 | Runtime   | Config — DB URL, federation settings, site name                   |
| Postgres creds         | strong password                       | DB        | Default template has `lemmy/password` — rotate                    |
| Admin account          | created via signup after first boot   | Bootstrap | First user to sign up becomes site admin                         |
| SMTP                   | via `postfix` container or external   | Email     | Password reset, 2FA, moderation notifications                     |
| CAPTCHA                | hCaptcha / reCAPTCHA / Cloudflare Turnstile | Signup | Public instances need this or get bot-flooded                    |
| Image storage          | pict-rs volume, eventually S3 backend | Data      | Local by default; S3 backend in pict-rs 0.5+                      |
| `PICTRS__SERVER__API_KEY` | strong                             | Security  | Default in upstream dev compose is `my-pictrs-key` — rotate       |

## Install via Lemmy Ansible (upstream-recommended)

From <https://github.com/LemmyNet/lemmy-ansible>:

```sh
# 1. Clone ansible repo
git clone https://github.com/LemmyNet/lemmy-ansible.git
cd lemmy-ansible

# 2. Copy sample inventory + vars
cp inventory/hosts.example inventory/hosts
cp examples/vars.yml inventory/host_vars/<your-host>.yml

# 3. Edit inventory/host_vars/<your-host>.yml — set:
#    domain: lemmy.example.com
#    lemmy_docker_image: dessalines/lemmy:0.19.x
#    lemmy_docker_ui_image: dessalines/lemmy-ui:0.19.x
#    postgres_password: <strong>
#    pictrs_api_key: <strong, openssl rand -hex 32>
#    federated_instances: []  (or allowlist)
#    email: admin@example.com
#    site_name: "My Lemmy"

# 4. Install deps
ansible-galaxy install -r requirements.yml

# 5. Run
ansible-playbook -i inventory/hosts lemmy.yml --become
```

The playbook writes `docker-compose.yml`, `lemmy.hjson`, `nginx_internal.conf`, and `customPostgresql.conf` on your host, then brings up the stack.

TLS: you can either let ansible run certbot for you, or set `letsencrypt_*: false` and reverse-proxy externally (Cloudflare Tunnel, Caddy, etc.).

## Install via upstream Docker Compose (manual)

Upstream docs: <https://join-lemmy.org/docs/administration/install_docker.html>. Summary of the pieces:

```yaml
# docker-compose.yml (minimal production skeleton)
services:
  proxy:
    image: nginx:1-alpine
    ports: ["80:8536"]
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on: [pictrs, lemmy-ui]
    restart: unless-stopped

  lemmy:
    image: dessalines/lemmy:0.19.x      # pin patch version
    volumes:
      - ./lemmy.hjson:/config/config.hjson:ro
    depends_on: [postgres, pictrs]
    restart: unless-stopped

  lemmy-ui:
    image: dessalines/lemmy-ui:0.19.x
    environment:
      - LEMMY_UI_BACKEND=lemmy:8536
      - LEMMY_UI_HTTPS=true            # true in prod, behind TLS-terminating proxy
    depends_on: [lemmy]
    restart: unless-stopped

  pictrs:
    image: asonix/pictrs:0.5
    user: "991:991"
    environment:
      - PICTRS__SERVER__API_KEY=<strong>
      - PICTRS__MEDIA__VIDEO_CODEC=vp9
    volumes:
      - ./volumes/pictrs:/mnt
    restart: unless-stopped

  postgres:
    image: pgautoupgrade/pgautoupgrade:18-alpine
    environment:
      - POSTGRES_USER=lemmy
      - POSTGRES_PASSWORD=<strong>
      - POSTGRES_DB=lemmy
    volumes:
      - ./volumes/postgres:/var/lib/postgresql
      - ./customPostgresql.conf:/etc/postgresql.conf:ro
    command: postgres -c config_file=/etc/postgresql.conf
    restart: unless-stopped

  postfix:
    image: mwader/postfix-relay
    environment:
      - POSTFIX_myhostname=lemmy.example.com
    restart: unless-stopped
```

Plus an `nginx.conf` that routes `/` → lemmy-ui, `/api/v3` + `/pictrs` + federation paths → lemmy — use the reference from the ansible templates: <https://github.com/LemmyNet/lemmy-ansible/blob/main/templates/nginx_internal.conf>.

## Data & config layout

- `lemmy.hjson` — canonical config (DB URL, site info, federation, rate limits, pict-rs URL)
- `volumes/postgres/` — Postgres data
- `volumes/pictrs/` — image blobs + pict-rs sled DB
- `nginx_internal.conf` — federation routing + accept-header negotiation
- `customPostgresql.conf` — tuned for your RAM (via pgtune)

**`lemmy.hjson`** is the single source of truth — everything else flows from it. Keep a copy in version control (excluding secrets).

## Backup

```sh
# DB
docker compose exec -T postgres pg_dump -U lemmy lemmy | gzip > lemmy-db-$(date +%F).sql.gz

# Images (large for active instances)
tar czf lemmy-pictrs-$(date +%F).tgz ./volumes/pictrs

# Config
tar czf lemmy-config-$(date +%F).tgz lemmy.hjson nginx_internal.conf customPostgresql.conf
```

For active instances, pict-rs storage balloons fast — 100 GB+ common after 6 months. Consider enabling pict-rs's S3 backend (pict-rs 0.5+) and keeping only a SQLite index locally.

## Upgrade

1. Releases: <https://github.com/LemmyNet/lemmy/releases>.
2. Update image tags in vars.yml / docker-compose.yml.
3. Re-run the ansible playbook OR `docker compose pull && docker compose up -d`.
4. **Major version bumps (0.18 → 0.19) require schema migration.** Watch logs: `docker compose logs lemmy | head -100` — the binary refuses to start if migrations fail.
5. **Never skip major versions.** 0.17 → 0.19 is not supported; go through 0.18 first.
6. `pgautoupgrade` handles Postgres major bumps automatically on first start of the new image tag.
7. Federation may lag during upgrades — activity queue backs up, clears once the service is back.

## Gotchas

- **Domain is PERMANENT.** Upstream warning: the domain is written into every federated activity, user URL, and community URL. Changing it = breaking federation for every other instance that knows you. Pick the final domain before first start.
- **Default image tag in dev compose is `nightly`** (for lemmy-ui) and `pgautoupgrade:18-alpine` (for Postgres). The dev compose is NOT for production — use lemmy-ansible or pinned versions from releases.
- **Default Postgres password `password` in dev compose.** Production via ansible sets a strong random password; manual compose users MUST change it.
- **Default pict-rs API key `my-pictrs-key` in dev compose.** Rotate. It gates image upload on behalf of users.
- **First user to sign up becomes site admin.** Bootstrap race — bring the instance up on a private DNS, register your admin, THEN expose public DNS. Or edit the `admins` table post-registration.
- **CAPTCHA is mandatory for public signup.** Without hCaptcha / similar, bot spam is instant. Lemmy's built-in CAPTCHA is weak; use an external one.
- **Federation allowlist vs blocklist.** Decide early:
  - **Allowlist mode**: you federate only with explicitly listed instances — safe, but isolates your users
  - **Blocklist mode** (default): you federate with everyone except listed instances — mainstream, but exposes users to CSAM risk and blockable instances
- **CSAM risk.** Fediverse platforms have ongoing battles with bad actors flooding images. Enable `pictrs-safety` (CLIP-based classifier sidecar) for image moderation, or use a CSAM-filtered S3 backend.
- **pict-rs 0.5 can migrate to S3.** Set `PICTRS__STORE__TYPE=object_storage` + S3 credentials. Keeps your host disk usage bounded.
- **Federation debt.** Every post, comment, and vote from other instances enqueues for processing. Backlogs of 100k+ activities after outages are common — recovery = letting the queue drain for hours.
- **Email deliverability.** Postfix relay container works, but without DKIM/SPF/PTR records, password-reset emails land in spam. Plan DNS accordingly.
- **AGPL-3.0.** Running a modified Lemmy as a public service requires offering source.
- **Mobile apps** (Jerboa, Voyager, Mlem) use the API — same endpoints as web UI. Public API = no auth needed for reads; writes require token.
- **`customPostgresql.conf`** is tuned by the ansible playbook via pgtune. Manual setups should tune shared_buffers + effective_cache_size for their host RAM, or large queries crawl.
- **Rate limits are in `lemmy.hjson`.** Defaults are reasonable but can be overwhelmed by federation bursts. Tune `captcha`, `image_uploads_per_hour`, `message_limit` based on instance size.
- **Threadiverse not just Lemmy.** Lemmy federates with Mbin (formerly Kbin) and Piefed. Same ActivityPub protocol; roughly compatible user/community URLs.
- **Alternatives worth knowing:**
  - **Mbin** — Lemmy-compatible but with additional magazine/micro-blog features
  - **Piefed** — Python reimplementation, newer, smaller
  - **Discourse** — non-federated but mature forum alternative

## Links

- Repo: <https://github.com/LemmyNet/lemmy>
- Web UI repo: <https://github.com/LemmyNet/lemmy-ui>
- pict-rs: <https://git.asonix.dog/asonix/pict-rs>
- Docs: <https://join-lemmy.org/docs/>
- Install (Docker): <https://join-lemmy.org/docs/administration/install_docker.html>
- Install (Ansible): <https://join-lemmy.org/docs/administration/install_ansible.html>
- Ansible repo: <https://github.com/LemmyNet/lemmy-ansible>
- Releases: <https://github.com/LemmyNet/lemmy/releases>
- Instance list: <https://join-lemmy.org/instances>
- Moderation + federation: <https://join-lemmy.org/docs/administration/federation_getting_started.html>
- Config reference: <https://join-lemmy.org/docs/administration/configuration.html>
