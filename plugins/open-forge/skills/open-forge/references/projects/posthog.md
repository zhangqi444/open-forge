---
name: posthog-project
description: PostHog recipe for open-forge. MIT-licensed (with `ee/` directory under separate license) product analytics, session replay, feature flags, A/B experiments, error tracking, surveys, data warehouse, and LLM analytics — all-in-one platform. Self-host via the upstream `deploy-hobby` script that bootstraps a 10+ service Docker stack (Postgres, ClickHouse, Redis, Kafka, Zookeeper, MinIO, Nginx+Certbot, Plugin server, Temporal, worker containers). Upstream explicitly describes self-host as "hobby deploy" and **recommends migrating to PostHog Cloud above ~100k events/month**. Not a casual self-host; 8GB RAM minimum.
---

# PostHog

MIT-licensed (with `ee/` dir under a separate license) all-in-one product analytics platform. Upstream: <https://github.com/PostHog/posthog>. Docs: <https://posthog.com/docs>. Cloud: <https://us.posthog.com> / <https://eu.posthog.com>.

Features include:

- Product analytics (event-based, autocapture or manual)
- Web analytics (GA-style dashboard)
- Session replay (record + play back real user sessions)
- Feature flags + experiments
- Error tracking
- Surveys
- Data warehouse + pipelines (CDP)
- LLM analytics

## ⚠️ Self-host is "hobby deploy" per upstream

From upstream README:

> *Self-hosting the open-source hobby deploy (Advanced)*
> *... you can deploy a hobby instance in one line on Linux with Docker (recommended 4GB memory):*
>
> ```
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/posthog/posthog/HEAD/bin/deploy-hobby)"
> ```
>
> *Open source deployments should scale to approximately 100k events per month, after which we recommend [migrating to a PostHog Cloud](https://posthog.com/docs/migrate/migrate-to-cloud).*
>
> *We do not provide customer support or offer guarantees for open source deployments.*

The `deploy-hobby` script (inspected directly) actually warns:

> *⚠️ You REALLY need 8GB or more of memory to run this stack ⚠️*

So plan on **8+ GB RAM, 4+ CPU cores, 50+ GB disk** for a real hobby deploy. The stack includes:

- PostHog web (Django)
- PostHog plugin-server (Node.js)
- PostHog capture workers
- ClickHouse (the analytics DB — memory-hungry)
- Postgres (application DB)
- Redis
- Kafka + Zookeeper (event pipeline)
- MinIO (object storage for session replays)
- Nginx + Certbot (TLS termination)
- Temporal (workflow engine for async jobs)

## When NOT to self-host

- "I want a quick Umami/Plausible-style pageview tracker" → use Umami/Plausible, not PostHog. PostHog's value is the combined analytics + replay + flags + experiments; if you only want pageviews, the ops weight isn't worth it.
- "I have a VPS with 2 GB RAM" → ClickHouse alone wants 4 GB minimum.
- "I need production reliability" → use PostHog Cloud. Self-host has no customer support and no uptime guarantees.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `deploy-hobby` bootstrap script | <https://github.com/PostHog/posthog/blob/master/bin/deploy-hobby> | ✅ Hobby-recommended | The canonical self-host. Writes `/etc/posthog`, provisions Docker Compose stack, runs Certbot. |
| Manual Docker Compose | `docker-compose.*.yml` files in the repo | ✅ | You know what you're doing and want to customize. |
| Helm chart | <https://github.com/PostHog/charts> | ⚠️ Not maintained equivalently | PostHog's Helm chart exists but is deprecated for new deployments; upstream pushes Cloud. |
| `posthog-foss` | <https://github.com/PostHog/posthog-foss> | ✅ | Pure-FOSS fork with all proprietary (`ee/`) features stripped. |
| PostHog Cloud | <https://us.posthog.com/signup> | ✅ | The upstream-recommended path for most. First 1M events free/month. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Is this host 8GB+ RAM, 4+ CPU, 50+ GB disk?" | Boolean | **Hard requirement.** PostHog stack is heavy. Reject if no. |
| preflight | "Install method?" | `AskUserQuestion`: `deploy-hobby (recommended)` / `manual-compose` / `foss` | Drives section. |
| dns | "Public domain?" | Free-text | **Required** — the script runs Certbot on first boot, which needs a real domain + port 80 reachable. |
| admin | "Initial admin email + password?" | Free-text (sensitive) | Set via env `ADMIN_EMAIL` / `ADMIN_PASSWORD`, OR via the web signup flow on first visit. |
| version | "Image tag?" | `AskUserQuestion`: `latest (hobby default)` / `pin-specific-version` | `latest` is what the hobby script installs by default; pin for reproducibility. |

## Install — `deploy-hobby` (upstream-recommended)

```bash
# On a fresh Ubuntu 22.04 / Debian 12 VPS, as a user with sudo
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/posthog/posthog/HEAD/bin/deploy-hobby)"
```

The script:

1. Prompts for PostHog version tag (default `latest`).
2. Prompts for the domain name (e.g. `posthog.example.com`).
3. Prompts whether to enable TLS via Let's Encrypt (yes, enter an email for Certbot).
4. Installs Docker + Docker Compose if missing.
5. Generates random `POSTHOG_SECRET` and `ENCRYPTION_SALT_KEYS` (saved in `/etc/posthog/.env`).
6. Writes the full `docker-compose.yml` to `/etc/posthog/`.
7. Runs `docker compose up -d`.
8. Waits for all services to be healthy (takes 5-10 min on first boot).
9. Prints the URL to visit to create the first admin user.

**Before running it**, ensure:

- DNS A record for your domain points at this server
- Port 80 + 443 open to the internet (Certbot validates via port 80)
- Swap enabled if RAM is tight (ClickHouse really wants 8GB)

### Review the script before execution

Per upstream docs (and basic safety): inspect `deploy-hobby` before piping it to bash. It does real things (apt-get install, modifies `/etc/`, writes systemd units).

```bash
curl -fsSL https://raw.githubusercontent.com/posthog/posthog/HEAD/bin/deploy-hobby -o deploy-hobby.sh
less deploy-hobby.sh
# Review, then:
bash deploy-hobby.sh
```

## Install — Manual Docker Compose

If you want to customize (external Postgres, external ClickHouse, non-Let's-Encrypt TLS, etc.):

```bash
git clone https://github.com/PostHog/posthog.git
cd posthog
cp .env.template .env
# Edit .env to set DOMAIN, POSTHOG_SECRET, ENCRYPTION_SALT_KEYS, database creds
docker compose -f docker-compose.hobby.yml up -d
```

The `docker-compose.base.yml` + `docker-compose.hobby.yml` structure lets you override individual services.

## Install — `posthog-foss` (pure-FOSS fork)

If you need 100% FOSS (no proprietary `ee/` code), use the stripped mirror:

```bash
git clone https://github.com/PostHog/posthog-foss.git
# Follow the same deploy-hobby style bootstrap from this repo
```

## Environment variables (essential)

From `.env.template`:

| Var | Required? | Purpose |
|---|---|---|
| `SITE_URL` | ✅ | Public URL, e.g. `https://posthog.example.com`. Used in emails + OAuth callbacks. |
| `POSTHOG_SECRET` | ✅ | Django secret key. Generate `openssl rand -hex 28`. |
| `ENCRYPTION_SALT_KEYS` | ✅ | Salt for encrypted DB fields. Generate `openssl rand -hex 16`. **Rotating breaks existing encrypted data.** |
| `POSTGRES_PASSWORD` | ✅ | App DB password. |
| `CLICKHOUSE_USER` / `CLICKHOUSE_PASSWORD` | ✅ | ClickHouse creds. |
| `SENTRY_DSN` | ❌ | Optional — where to send PostHog's own exceptions. |
| `DISABLE_SECURE_SSL_REDIRECT` | ❌ | Set to `1` if you DO NOT have TLS (e.g. behind Tailscale) to stop the redirect loop. |
| `TRUST_ALL_PROXIES` | ❌ | Set to `1` if behind a reverse proxy — enables correct client IP detection. |
| `ADMIN_EMAIL` | ❌ (first boot only) | Auto-creates initial admin on first boot. |

## Adding the tracker to your website

After first login in the PostHog admin UI, you get a project + a write-only "API key." Drop the JS snippet in your site's `<head>`:

```html
<script>
    !function(t,e){var o,n,p,r;e.__SV||(window.posthog=e,e._i=[],e.init=function(i,s,a){function g(t,e){var o=e.split(".");2==o.length&&(t=t[o[0]],e=o[1]),t[e]=function(){t.push([e].concat(Array.prototype.slice.call(arguments,0)))}}(p=t.createElement("script")).type="text/javascript",p.crossOrigin="anonymous",p.async=!0,p.src=s.api_host.replace(".i.posthog.com","-assets.i.posthog.com")+"/static/array.js",(r=t.getElementsByTagName("script")[0]).parentNode.insertBefore(p,r);var u=e;for(void 0!==a?u=e[a]=[]:a="posthog",u.people=u.people||[],u.toString=function(t){var e="posthog";return"posthog"!==a&&(e+="."+a),t||(e+=" (stub)"),e},u.people.toString=function(){return u.toString(1)+".people (stub)"},o="init capture register register_once register_for_session unregister unregister_for_session getFeatureFlag getFeatureFlagPayload isFeatureEnabled reloadFeatureFlags updateEarlyAccessFeatureEnrollment getEarlyAccessFeatures on onFeatureFlags onSessionId getSurveys getActiveMatchingSurveys renderSurvey canRenderSurvey getNextSurveyStep identify setPersonProperties group resetGroups setPersonPropertiesForFlags resetPersonPropertiesForFlags setGroupPropertiesForFlags resetGroupPropertiesForFlags reset get_distinct_id getGroups get_session_id get_session_replay_url alias set_config startSessionRecording stopSessionRecording sessionRecordingStarted captureException loadToolbar get_property getSessionProperty createPersonProfile opt_in_capturing opt_out_capturing has_opted_in_capturing has_opted_out_capturing clear_opt_in_out_capturing".split(" "),n=0;n<o.length;n++)g(u,o[n]);e._i.push([i,s,a])},e.__SV=1)}(document,window.posthog||[]);
    posthog.init('<YOUR_API_KEY>', {api_host: 'https://posthog.example.com'})
</script>
```

Replace `<YOUR_API_KEY>` with the project key from PostHog's admin UI, and set `api_host` to your self-hosted URL.

## Data layout

All data lives in Docker volumes managed by Compose. Critical volumes:

| Volume | Content | Backup? |
|---|---|---|
| `postgres-data` | Application DB: users, projects, feature flags, dashboards, etc. | ✅ Yes, daily. |
| `clickhouse-data` | Events, persons, session replay events. **This is where 99% of disk goes.** | ✅ Yes — and expect TBs for busy installs. |
| `object_storage` (MinIO) | Session replay recordings. | ✅ Back up or switch to S3. |
| `kafka-data` / `zookeeper-data` | Ephemeral event queue — safe to lose, stack rebuilds state. | ❌ Don't bother. |
| `redis-data` | Cache. | ❌ Don't bother. |

Backup the Postgres DB + ClickHouse + MinIO together. Session replay recordings without events = worthless; events without recordings = partial insights.

## Upgrade procedure

Upstream advice for hobby deploys (paraphrased): pin a version, upgrade by changing `POSTHOG_APP_TAG` in `.env`, pull, up.

```bash
cd /etc/posthog
# 1. Back up ALL volumes first
docker compose stop
sudo tar -czf posthog-backup-$(date +%F).tar.gz \
    /var/lib/docker/volumes/posthog_postgres-data \
    /var/lib/docker/volumes/posthog_clickhouse-data \
    /var/lib/docker/volumes/posthog_object_storage
docker compose start

# 2. Bump version in .env, pull, up
vi .env   # change POSTHOG_APP_TAG=<new-version>
docker compose pull
docker compose up -d
docker compose logs -f web   # watch migrations

# 3. Migrations run automatically on web container boot.
#    ClickHouse migrations (stored in the `posthog_async_migrations` table)
#    may take minutes-to-hours on big event tables.
```

**Major upgrades can require async migrations** that run in the background and can take hours on event-heavy deploys. Release notes call these out. Monitor the Async Migrations page in admin UI.

## Gotchas

- **Self-host scales to ~100k events/month, per upstream.** Past that, performance degrades without significant ops work. Don't try to self-host 10M events/month on a single VPS — PostHog Cloud handles billions/month because it's a managed multi-tenant ClickHouse cluster.
- **8 GB RAM minimum** — ignore the "4 GB recommended" in the README comment; the actual warning in `deploy-hobby` is 8 GB. ClickHouse + Kafka + Postgres + multiple Python workers are all hungry.
- **ClickHouse + Kafka + Zookeeper are operationally expensive to run yourself.** If one of them falls over, you may need to read ClickHouse docs to recover. Self-host PostHog → you're now a (accidental) ClickHouse operator.
- **`deploy-hobby` writes to `/etc/posthog`.** If that directory exists or has prior state, the script may refuse or overwrite. Start on a clean VPS.
- **Certbot runs during bootstrap.** Requires DNS pointing at the server AND port 80 open BEFORE running the script. Behind a reverse proxy (where you already have TLS), decline the Certbot step and configure TLS at the proxy.
- **`POSTHOG_SECRET` + `ENCRYPTION_SALT_KEYS` rotation breaks data.** Rotating `ENCRYPTION_SALT_KEYS` makes all encrypted DB fields (OAuth tokens, integration secrets, etc.) unreadable. Don't rotate casually.
- **`ee/` directory is NOT MIT.** If you care about pure FOSS, use `posthog-foss` which strips that directory. Otherwise, the main `posthog/posthog` image contains proprietary enterprise features that are "free to run but not under MIT."
- **Session replay storage balloons.** Each replayed session is tens of MB at scale. MinIO (default) fills your disk; switch to S3 for anything beyond a toy deploy by setting `OBJECT_STORAGE_*` env vars.
- **Autocapture can record sensitive data.** By default, PostHog's JS SDK captures clicks, form fills (masked), URL changes, etc. Review what it picks up; use `posthog.init({ mask_all_text: true, mask_all_element_attributes: true })` for privacy-sensitive apps. Server-side event capture (via SDK `capture` calls) gives you full control and avoids accidental PII.
- **No customer support.** Open source = community Discord, GitHub Discussions. When ClickHouse dies at 3am, you're on your own.
- **The Helm chart is not the preferred path.** Upstream has explicitly deprioritized Kubernetes self-host in favor of Cloud. Helm works but expect rough edges.
- **`/etc/posthog/docker-compose.yml` is generated, not tracked.** If you need custom changes, put them in an `override` file (`docker-compose.override.yml`) next to the generated compose — upgrades won't stomp it. Don't edit the generated file directly.
- **First login = first user = root org admin.** No default credentials; you sign up via the web UI. Firewall your domain until you've claimed the admin account if the server is exposed to the internet.
- **The whole stack is HTTP-only inside the network.** Only the Nginx + Certbot layer does TLS. Don't expose ClickHouse or Kafka ports externally (default compose binds them to `127.0.0.1`, which is correct — verify).

## Links

- Upstream repo: <https://github.com/PostHog/posthog>
- FOSS mirror: <https://github.com/PostHog/posthog-foss>
- Docs: <https://posthog.com/docs>
- Self-hosting docs: <https://posthog.com/docs/self-host>
- Hobby deploy guide: <https://posthog.com/docs/self-host/deploy/hobby>
- Troubleshooting: <https://posthog.com/docs/self-host/deploy/troubleshooting>
- Disclaimer (really, read it): <https://posthog.com/docs/self-host/open-source/disclaimer>
- Migrate to Cloud: <https://posthog.com/docs/migrate/migrate-to-cloud>
- Hobby install script (read before running!): <https://raw.githubusercontent.com/PostHog/posthog/master/bin/deploy-hobby>
- Community: <https://posthog.com/community>
