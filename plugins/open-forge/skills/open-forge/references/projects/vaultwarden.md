---
name: vaultwarden-project
description: Vaultwarden recipe for open-forge. AGPL-3.0 Rust reimplementation of the Bitwarden Client API — lightweight self-hosted password manager compatible with all official Bitwarden clients (mobile, desktop, browser extensions). Covers the single-container Docker deploy (the upstream-recommended install), the reverse-proxy + HTTPS requirement (the Web Crypto API demands a secure context), admin-panel bootstrap via ADMIN_TOKEN, SQLite/MySQL/Postgres backends, and the upstream disclaimer (NOT affiliated with Bitwarden Inc).
---

# Vaultwarden

AGPL-3.0 Rust server that implements the Bitwarden Client API. Self-host your password manager and point official Bitwarden apps at it. Upstream: <https://github.com/dani-garcia/vaultwarden>. Wiki (authoritative config docs): <https://github.com/dani-garcia/vaultwarden/wiki>.

**Upstream disclaimer** (from README): *"This project is not associated with Bitwarden or Bitwarden, Inc."* One Vaultwarden maintainer is a Bitwarden employee contributing on personal time, but the project is independent. Bug reports go to Vaultwarden, NOT Bitwarden support.

Vaultwarden is a single Rust binary. Built-in support for SQLite (default), MySQL, or PostgreSQL. Listens on port `80` inside the container (historically port `8000`; the container's `EXPOSE` is `80`). Ships with a modified Bitwarden web vault client bundled in.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker container (`ghcr.io` / `docker.io` / `quay.io`) | <https://github.com/dani-garcia/vaultwarden/pkgs/container/vaultwarden> · <https://hub.docker.com/r/vaultwarden/server> | ✅ | The upstream-recommended install. |
| Docker Compose | Example in `README.md` | ✅ | Same container + a compose file — what most people deploy. |
| Podman | CLI args identical to Docker | ✅ (README docs it) | If you prefer rootless / daemonless. |
| Build from source (`cargo build`) | <https://github.com/dani-garcia/vaultwarden/wiki/Building-binary> | ✅ | Bare metal, custom features (e.g. `s3` feature for S3 data folder). |
| Community packages (Nix, AUR, Proxmox LXC, Umbrel, CasaOS, TrueNAS SCALE apps, etc.) | <https://github.com/dani-garcia/vaultwarden/wiki/Third-party-packages> | ⚠️ Community-maintained | Ecosystem integrations — may lag upstream. Upstream disclaims support. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Docker / Podman / bare metal?" | `AskUserQuestion`: `Docker (recommended)` / `Podman` / `Bare-metal from source` | Drives which install section runs. |
| dns | "What's the FQDN for Vaultwarden?" (e.g. `vw.example.com`) | Free-text | Sets `DOMAIN` — **must include scheme**, e.g. `https://vw.example.com`. Attachment downloads, email links, and WebAuthn all break without `DOMAIN` set correctly. |
| tls | "HTTPS required. Terminate TLS where?" | `AskUserQuestion`: `Caddy (auto-TLS)` / `Nginx + certbot` / `Traefik` / `Built-in Rocket TLS` (discouraged) / `HTTP for localhost only` | Web Crypto API requires a secure context; plaintext HTTP works ONLY on `http://localhost`. |
| storage | "Data dir on the host?" (default `/vw-data/`) | Free-text | Bind-mounted to `/data/` in the container. SQLite DB + icons + attachments live here. |
| db | "Database backend?" | `AskUserQuestion`: `SQLite (default, recommended)` / `MySQL` / `PostgreSQL` | SQLite is fine for single-user / small team. MySQL/Postgres for scale. |
| admin | "Enable admin panel via ADMIN_TOKEN?" (recommended) | `AskUserQuestion`: `Yes — generate Argon2 hash` / `Skip` | Admin UI at `/admin`. Generate token with `vaultwarden hash` (interactive) or `echo -n "${PLAIN_TOKEN}" \| argon2 "${SALT}" -e -id -k 65540 -t 3 -p 4`. |
| signups | "Allow open signups?" | `AskUserQuestion`: `No — invitation-only` / `Yes, any email` / `Yes, but whitelist domains` | Sets `SIGNUPS_ALLOWED` + optionally `SIGNUPS_DOMAINS_WHITELIST`. Default is open — **turn it off after your own account is created** or anyone on the internet can sign up. |
| smtp | "Set up SMTP for invites / password reset / 2FA email?" | `AskUserQuestion`: `Yes — provider…` / `Skip` | Without SMTP, invitations and email 2FA won't work. |
| push | "Enable mobile push notifications (requires Bitwarden-issued installation ID/key)?" | `AskUserQuestion`: `Yes — register at bitwarden.com/host` / `Skip` | Requires registering your self-host with Bitwarden to get `PUSH_INSTALLATION_ID` + `PUSH_INSTALLATION_KEY`. Without it, mobile clients poll instead of getting pushed notifications. |

Write to state so resume skips re-prompting.

## Install — Docker (the recommended path)

Per upstream README's `## Usage` section.

```bash
# 1. Pull + run (single container)
docker pull vaultwarden/server:1.36.0

mkdir -p /vw-data
docker run -d \
  --name vaultwarden \
  --restart unless-stopped \
  --env DOMAIN="https://${CANONICAL_HOST}" \
  --volume /vw-data/:/data/ \
  --publish 127.0.0.1:8000:80 \
  vaultwarden/server:1.36.0
```

Binding to `127.0.0.1:8000` (NOT `0.0.0.0:8000`) is intentional — the reverse proxy on the same host will front it over HTTPS. Never expose Vaultwarden's plaintext port publicly.

### Docker Compose equivalent

```yaml
# compose.yaml
services:
  vaultwarden:
    image: vaultwarden/server:1.36.0
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://${CANONICAL_HOST}"
      SIGNUPS_ALLOWED: "false"
      ADMIN_TOKEN: "${ARGON2_ADMIN_TOKEN_HASH}"
      # Optional SMTP:
      # SMTP_HOST: smtp.example.com
      # SMTP_PORT: 587
      # SMTP_SECURITY: starttls
      # SMTP_FROM: vaultwarden@example.com
      # SMTP_USERNAME: apikey
      # SMTP_PASSWORD: "${SMTP_PASSWORD}"
    volumes:
      - ./vw-data/:/data/
    ports:
      - 127.0.0.1:8000:80
```

```bash
docker compose up -d
docker compose logs -f vaultwarden   # wait for "Rocket has launched from http://0.0.0.0:80"
```

### Image tag matrix

Upstream publishes multiple tag shapes — see <https://github.com/dani-garcia/vaultwarden/wiki/Which-container-image-to-use>. Common picks:

| Tag | Base | Use when |
|---|---|---|
| `latest` | Debian | Default. Tracks the most recent stable release. |
| `alpine` | Alpine Linux | Smaller image, musl libc. Sometimes behind Debian on niche fixes. |
| `<version>` (e.g. `1.30.5`) | Debian | Pin a specific release for reproducibility. |
| `<version>-alpine` | Alpine | Pinned Alpine variant. |
| `testing` | Debian | Pre-release; for brave maintainers. |

### Registries

Three mirrors, same content:

- `ghcr.io/dani-garcia/vaultwarden:latest` (GitHub Container Registry)
- `docker.io/vaultwarden/server:1.36.0` (Docker Hub)
- `quay.io/vaultwarden/server:1.36.0` (Red Hat Quay)

Pick whichever has fewer pull-rate issues.

## Reverse proxy + HTTPS (mandatory)

Vaultwarden itself can terminate TLS (Rocket framework supports it), but upstream recommends a reverse proxy. Why it matters: the web vault client uses the Web Crypto API, which requires a secure context. Web Crypto will refuse to work on plaintext HTTP except on `http://localhost`. Without HTTPS, **the web vault is broken** — it'll load but cipher decrypt fails.

Upstream's proxy example index: <https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples>.

### Caddy

```caddy
vw.example.com {
    reverse_proxy localhost:8000
    # Caddy auto-provisions Let's Encrypt certs.
    # For the `/notifications/hub` WebSocket — Caddy's reverse_proxy
    # handles Upgrade/Connection headers by default.
}
```

### Nginx

The upstream wiki publishes a full nginx snippet; key parts:

```nginx
server {
    listen 443 ssl http2;
    server_name vw.example.com;

    ssl_certificate     /etc/letsencrypt/live/vw.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vw.example.com/privkey.pem;

    client_max_body_size 525M;   # attachments can be large

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket for real-time sync
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

If your proxy runs on a different host from Vaultwarden, set `IP_HEADER=X-Real-IP` (or whichever header your proxy sets) so rate-limiting sees client IPs instead of the proxy's.

## Admin panel

Enable by setting `ADMIN_TOKEN` in the env. **Must be an Argon2id hash** (plaintext tokens work but upstream warns against them; hashes are mandatory from v1.29+).

```bash
# Interactive helper (baked into the binary)
docker exec -it vaultwarden vaultwarden hash

# Or compute manually (requires `argon2` CLI):
echo -n "${PLAIN_ADMIN_TOKEN}" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
```

Copy the output `$argon2id$v=19$...` string into `ADMIN_TOKEN`. Access the panel at `https://${CANONICAL_HOST}/admin` and log in with the **plaintext** token.

From the admin panel you can: invite users, toggle signups, configure SMTP, manage users/orgs, view diagnostics. Most `.env` settings can be overridden here — overrides persist to `${DATA_FOLDER}/config.json`.

## Config surface

Config lives in env vars (templated from `.env.template` — 669 lines of annotated options upstream at <https://github.com/dani-garcia/vaultwarden/blob/main/.env.template>). Most-used groups:

| Group | Key envs |
|---|---|
| **Domain** | `DOMAIN` (mandatory) |
| **Database** | `DATABASE_URL`, `DATABASE_MAX_CONNS`, `ENABLE_DB_WAL` |
| **Signups/invites** | `SIGNUPS_ALLOWED`, `SIGNUPS_DOMAINS_WHITELIST`, `INVITATIONS_ALLOWED`, `EMERGENCY_ACCESS_ALLOWED` |
| **Admin** | `ADMIN_TOKEN` (Argon2 hash), `DISABLE_ADMIN_TOKEN` |
| **Web vault** | `WEB_VAULT_ENABLED` |
| **SMTP** | `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURITY` (`off`/`starttls`/`force_tls`), `SMTP_FROM`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `USE_SENDMAIL` |
| **Mobile push** | `PUSH_ENABLED`, `PUSH_INSTALLATION_ID`, `PUSH_INSTALLATION_KEY`, `PUSH_RELAY_URI` (EU users: `https://api.bitwarden.eu`) |
| **Proxy** | `IP_HEADER` (e.g. `X-Real-IP`) |
| **YubiKey / Duo** | `YUBICO_CLIENT_ID`, `YUBICO_SECRET_KEY`, `DUO_IKEY`, `DUO_SKEY`, `DUO_HOST` |
| **SSO (v1.32+)** | `SSO_ENABLED`, `SSO_AUTHORITY`, `SSO_CLIENT_ID`, `SSO_CLIENT_SECRET` |

### SMTP security modes

- `SMTP_SECURITY=off` — plaintext, port 25 (almost never right)
- `SMTP_SECURITY=starttls` — port 587, opportunistic → required TLS upgrade
- `SMTP_SECURITY=force_tls` — port 465, implicit TLS (same as Ghost's `secure: true`)

### Push notifications

Mobile clients won't get real-time push without `PUSH_ENABLED=true` + registering at <https://bitwarden.com/host>. Registration is free but links your self-host to Bitwarden's relay. EU-region users must swap the `PUSH_RELAY_URI` + `PUSH_IDENTITY_URI` to the `bitwarden.eu` variants.

## Upgrade

```bash
# Docker
docker pull vaultwarden/server:1.36.0
docker stop vaultwarden && docker rm vaultwarden
# Re-run the same `docker run` command above (or `docker compose pull && docker compose up -d`)
```

**Always back up `/vw-data/` before upgrading.** DB schema migrations run automatically on startup and are generally forward-only — a failed migration can leave the DB in a state that the previous image can't read.

```bash
# Simple backup
sudo tar czf /var/backups/vaultwarden-$(date +%Y%m%d-%H%M%S).tar.gz /vw-data/
```

For SQLite (the default), the wiki recommends the `.sqlite3` online-backup approach rather than `cp`ing `db.sqlite3` (which can miss WAL data):

```bash
sudo sqlite3 /vw-data/db.sqlite3 ".backup '/var/backups/vw-$(date +%Y%m%d).sqlite3'"
```

## Gotchas

- **DOMAIN must include the scheme.** `DOMAIN=vw.example.com` is wrong. `DOMAIN=https://vw.example.com` is right. WebAuthn / email links / attachments fail silently if the scheme is wrong or missing.
- **HTTPS is effectively mandatory.** Web Crypto API refuses plaintext except on `http://localhost`. If you see "decryption failed" or "invalid token" errors in the web vault, it's almost always HTTPS misconfiguration.
- **`SIGNUPS_ALLOWED=true` is the default.** Turn it off *immediately* after creating your own account. Public instances get enumerated.
- **ADMIN_TOKEN must be hashed (Argon2id) in recent versions.** Plaintext `ADMIN_TOKEN=somesecret` still works on older images but upstream warns it's deprecated. Use `vaultwarden hash` to generate.
- **Bind `127.0.0.1:8000:80`, NOT `0.0.0.0:8000:80`.** Plaintext on `0.0.0.0` is a data-exfil vector; always front with a reverse proxy.
- **`/notifications/hub` is a WebSocket.** Any reverse proxy needs `Upgrade`/`Connection` headers forwarded, or real-time sync silently breaks. `ENABLE_WEBSOCKET=true` is the default.
- **Attachments default to 525 MB max.** If uploads fail, check the proxy's `client_max_body_size` (nginx) / `MaxRequestBodySize` (IIS) / `request_body_size` (Caddy default is unlimited).
- **Mobile push requires Bitwarden-issued credentials.** No way around it — upstream uses Bitwarden's relay. EU users: use the `bitwarden.eu` URIs.
- **Third-party packages are unsupported.** Issues opened against Proxmox LXC / Umbrel / CasaOS / TrueNAS Vaultwarden deployments typically get closed "please try the official Docker image first." Know the deployment shape before asking for help.
- **SSO is new-ish (v1.32+).** If the user wants SSO / SAML, confirm their Vaultwarden version supports it; older builds won't have the env vars.
- **Do NOT use the name `bitwarden_rs`.** The project was renamed from `bitwarden_rs` to `vaultwarden` in v1.21.0 (April 2021). Old Docker images / Helm charts with `bitwarden_rs` in the name are abandoned.

## Upstream references

- Repo: <https://github.com/dani-garcia/vaultwarden>
- Wiki (authoritative for everything): <https://github.com/dani-garcia/vaultwarden/wiki>
- `.env.template` (full config reference): <https://github.com/dani-garcia/vaultwarden/blob/main/.env.template>
- Which container tag to use: <https://github.com/dani-garcia/vaultwarden/wiki/Which-container-image-to-use>
- Proxy examples: <https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples>
- Enabling HTTPS: <https://github.com/dani-garcia/vaultwarden/wiki/Enabling-HTTPS>
- Enabling admin page: <https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page>
- Enabling mobile push: <https://github.com/dani-garcia/vaultwarden/wiki/Enabling-Mobile-Client-push-notification>
- Backing up your instance: <https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault>
- Releases: <https://github.com/dani-garcia/vaultwarden/releases>

## TODO — verify on first deployment

- Confirm `vaultwarden hash` subcommand is still the blessed way to generate ADMIN_TOKEN hashes (may have moved in future versions).
- Verify the current `client_max_body_size` default for attachments (may change with feature updates).
- Check whether SSO has stabilised out of experimental status and update gotcha.
- Verify `PUSH_RELAY_URI` registration flow at <https://bitwarden.com/host> still works for self-hosters.
