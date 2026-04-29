---
name: Postal
description: Open-source mail delivery platform — an on-prem alternative to Sendgrid/Mailgun/Postmark. Sends transactional + marketing email, tracks opens/clicks, handles bounces and suppression lists. Ruby on Rails + MariaDB + RabbitMQ. MIT.
---

# Postal

Postal is a full-featured outbound mail relay. You define "mail servers" (tenants), each with sending domains, SPF/DKIM keys, webhooks, and API credentials. Applications push mail via SMTP or HTTP API; Postal queues, signs, delivers, retries, and reports back. Includes a web console for inspecting message queues, bounce reasons, click/open tracking, and credentials management.

- Upstream repo: <https://github.com/postalserver/postal>
- Install tools: <https://github.com/postalserver/install>
- Docs: <https://docs.postalserver.io>
- Image: `ghcr.io/postalserver/postal`

## Architecture in one minute

Postal is a multi-service Rails app wrapped in a custom `postal` CLI installer. Four container roles (all from the same image with different commands):

1. **`web`** — Rails web console + HTTP send API on TCP 5000
2. **`smtp`** — SMTP-in receiver on TCP 25 (submission) + outbound
3. **`worker`** — Background queue processor (retries, tracking pings, webhooks)
4. **`runner`** — One-shot CLI container (migrations, `postal make-user`, etc.)

Plus the external prerequisites Postal does NOT ship in its Compose:

- **MariaDB 10.5+** — main DB + per-mail-server message databases
- **RabbitMQ** — job queue

The `postal` CLI (from `postalserver/install`) reads `/opt/postal/config/postal.yml` and generates + runs the effective docker-compose.

## Compatible install methods

| Infra                  | Runtime                                     | Notes                                                                   |
| ---------------------- | ------------------------------------------- | ----------------------------------------------------------------------- |
| Single VM (8+ GB RAM)  | `postal` CLI + Docker (v3 path)             | **Recommended.** Upstream-supported                                     |
| Single VM              | Hand-rolled Docker Compose                  | Possible; `postalserver/install` templates show the shape                |
| Kubernetes             | Community charts                            | No official Helm chart; see community issues for setups                 |
| Bare metal             | Ruby + MariaDB + RabbitMQ                   | Largely unmaintained as a path since v3                                 |

## Inputs to collect

| Input                  | Example                           | Phase     | Notes                                                                |
| ---------------------- | --------------------------------- | --------- | -------------------------------------------------------------------- |
| Hostnames              | `postal.example.com` (web), `mx.example.com` (MX), `spf.example.com`, `rp.example.com`, `track.example.com`, `routes.example.com` | DNS | Postal needs ~6 DNS names; most can be CNAMEs to one host |
| TLS cert (web)         | Let's Encrypt or own CA           | TLS       | For the web console + click/open tracking URLs                       |
| MariaDB credentials    | strong password                   | DB        | Postal auto-creates per-mail-server DBs (`postal-server-*`) as needed |
| RabbitMQ credentials   | strong password                   | Queue     | Default `guest/guest` is fine only for 100%-internal deployments     |
| Static IP + PTR        | `203.0.113.42` → `mx.example.com` | **Deliverability** | PTR (reverse DNS) matching your HELO name is mandatory or you'll land in spam folders |
| SMTP port 25 inbound+outbound | open in firewall + no ISP block | Network | Residential ISPs block 25 — deliverability requires a VPS          |
| SPF/DKIM records       | per-domain                        | DNS       | Postal generates the DKIM key; you publish the DNS record             |
| Admin email            | `postmaster@example.com`          | Bootstrap | First user created via `postal make-user`                            |

## Install via the `postal` CLI (upstream path)

Per <https://docs.postalserver.io/getting-started/installation>:

```sh
# 1. Pre-requisites (MariaDB + RabbitMQ + Docker). Ubuntu convenience script:
curl https://raw.githubusercontent.com/postalserver/install/main/prerequisites/install-ubuntu.v3.sh | bash
# ⚠️ this installs DBs with weak passwords — fine for testing, NOT for production.

# 2. Install the `postal` CLI
sudo curl -o /usr/local/bin/postal https://raw.githubusercontent.com/postalserver/install/main/bin/postal
sudo chmod +x /usr/local/bin/postal

# 3. Bootstrap config
sudo mkdir -p /opt/postal/config
sudo postal bootstrap postal.example.com

# 4. Edit /opt/postal/config/postal.yml — set web_hostname, DB creds, DNS block
sudo vim /opt/postal/config/postal.yml

# 5. Initialize DB + start services
sudo postal initialize
sudo postal start

# 6. Create the first admin user
sudo postal make-user
```

Browse `https://postal.example.com` → log in → create a mail server → add a sending domain → publish the DNS records Postal displays → send test email.

The `postal` CLI wraps `docker compose` — see <https://github.com/postalserver/install/blob/main/templates/docker-compose.v3.yml> for the template it renders.

### Caddy in front (auto-TLS)

Upstream ships an example Caddyfile at <https://github.com/postalserver/install/blob/main/examples/Caddyfile>:

```caddy
postal.example.com {
    reverse_proxy 127.0.0.1:5000
}
track.example.com {
    reverse_proxy 127.0.0.1:5000
}
```

Caddy terminates TLS; Postal's `web` container stays on host-network `:5000`.

## Postal CLI commands

- `postal start` / `postal stop` / `postal restart`
- `postal logs <service>`
- `postal upgrade` — pull newer image, run migrations
- `postal make-user` — create admin user
- `postal console` — Rails console (use carefully)
- `postal bootstrap <hostname>` — regenerate config skeleton
- `postal initialize` — first-time DB setup

## Data & config layout

- `/opt/postal/config/postal.yml` — main config (secrets, hostnames, DBs, DNS)
- `/opt/postal/config/signing.key` — DKIM private key (**back this up!**)
- `/opt/postal/config/fast-server.crt` + `.key` — optional fast-server TLS
- MariaDB databases:
  - `postal` — users, orgs, servers, domains, credentials
  - `postal-server-<id>` — per-mail-server message logs, click data
- RabbitMQ state — transient job queue (no long-term value)

## Backup

```sh
# 1. All MariaDB databases (critical — contains message metadata + config)
mysqldump --all-databases --single-transaction -u root -p | gzip > postal-db-$(date +%F).sql.gz

# 2. Config + DKIM key (losing signing.key breaks DKIM for every existing domain)
tar czf postal-config-$(date +%F).tgz /opt/postal/config

# 3. Attachments (if configured to store locally rather than S3) — per postal.yml paths
```

**Restore drill:** practice before you need it. DKIM key loss = full re-publication of DNS records for every domain.

## Upgrade

1. Release notes: <https://github.com/postalserver/postal/releases>.
2. `sudo postal stop && sudo postal upgrade && sudo postal start`.
3. The `postal upgrade` command runs pending DB migrations automatically.
4. Major version jumps (e.g. v2 → v3) require a specific procedure — v3 moved from a bare-metal Ruby install to Docker. Read the migration guide before jumping.

## Gotchas

- **ISP blocks port 25.** Most residential + many cloud ISPs block outbound TCP 25. On AWS/GCP/Azure you must *request* unblock (which is often denied). Use a VPS provider that allows SMTP (Hetzner, OVH, a handful of US hosts). Without outbound :25 Postal delivers nothing.
- **Reverse DNS (PTR) matters.** Your outbound IP's PTR record must match the HELO hostname Postal uses. Wrong PTR = 50% of recipients mark you as spam or reject outright.
- **SPF, DKIM, DMARC publication is manual.** Postal shows you the DNS records to publish — Gmail/Outlook simply won't deliver unless they're live. Verify with <https://mxtoolbox.com> before sending real mail.
- **`postal make-user` is bootstrap-only.** After the first user exists, create more through the web UI. `make-user` skips some validation and is primarily for rescue.
- **`signing.key` == email signing identity.** Back it up. Rotate deliberately (requires republishing every domain's DKIM TXT record).
- **DB mode: shared vs per-server.** Default is shared (one MariaDB for everything). Per-server DB mode (`message_db.per_server: true`) isolates large tenants but multiplies DB count and backup complexity.
- **RabbitMQ default `guest/guest` listens only on localhost** — fine for a single-box compose, but if you split RabbitMQ out, change the password and restrict bind.
- **Postal v2 → v3 migration is one-way.** v2 ran on a local Ruby install; v3 is Docker-only. Have a tested MariaDB dump before upgrading.
- **Bounce processing needs a working return-path.** The `return_path_domain` (e.g. `rp.example.com`) must resolve + accept inbound SMTP on :25 back to your Postal instance. Misconfiguration = no bounce handling = suppression lists don't grow = continued delivery attempts to bad addresses.
- **No multi-tenant billing / rate limits built in.** Postal is delivery infrastructure; it tracks send volume but doesn't enforce per-tenant quotas. If you're hosting for customers, add quotas at your API-gateway layer.
- **Click/open tracking requires HTTPS on `track.example.com`.** If you can't get TLS there, disable tracking on a per-domain basis — mixed-content-warning links will scare users.
- **Attachments stored in DB by default** — large attachments inflate the DB. Switch to S3-backed attachment storage for busy installs (config in `postal.yml`).
- **`runner` container uses `profiles: ["tools"]`** so it doesn't start by default. Invoke via `docker compose run --rm runner postal <cmd>`.
- **Alternative: Mailcow / Mailu** are inbound + outbound full mail stacks. Postal is **outbound-only** (transactional/marketing sender), not a replacement for a receiving mail server.

## Links

- Main repo: <https://github.com/postalserver/postal>
- Install tools: <https://github.com/postalserver/install>
- Docs: <https://docs.postalserver.io>
- Getting started: <https://docs.postalserver.io/getting-started>
- Configuration: <https://docs.postalserver.io/getting-started/configuration>
- Release notes: <https://github.com/postalserver/postal/releases>
- Discord: <https://discord.postalserver.io>
- Compose template: <https://github.com/postalserver/install/blob/main/templates/docker-compose.v3.yml>
- Example Caddyfile: <https://github.com/postalserver/install/blob/main/examples/Caddyfile>
