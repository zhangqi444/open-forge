---
name: ghost-project
description: Ghost recipe for open-forge. Covers every upstream-blessed install method documented under https://ghost.org/docs/install/ — Ghost-CLI on Ubuntu (recommended production), Docker Compose preview (with self-hosted ActivityPub + Tinybird Analytics), Local install (dev), Install from source (Ghost core dev), DigitalOcean 1-Click marketplace, Linode VPS — plus community-maintained options (Bitnami blueprint, Docker Hub `ghost` image). Each section cites the upstream URL it derives from per CLAUDE.md § Strict doc-verification policy.
---

# Ghost

Open-source publishing platform built on Node.js + MySQL/SQLite. Upstream: <https://github.com/TryGhost/Ghost>. Install methods index: <https://ghost.org/docs/install/>.

Ghost itself is a Node app listening on port `2368`. What varies across install methods is which webserver fronts it (NGINX vs Caddy vs Apache), which database it uses (MySQL vs SQLite), how TLS is provisioned (Ghost-CLI runs Let's Encrypt + NGINX automatically; Docker preview uses Caddy on-demand; Bitnami uses `bncert-tool` + Apache), and which optional services are bundled (the new Docker preview ships self-hosted ActivityPub + Tinybird Analytics out of the box; Ghost-CLI does not).

## Compatible install methods

Verified against the upstream `TryGhost/Docs` repo's `install/` tree per CLAUDE.md § *Strict doc-verification policy*. Each method below has its own section with the upstream URL cited at the section head.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Ghost-CLI on Ubuntu | <https://ghost.org/docs/install/ubuntu/> | ✅ | Recommended production. Ubuntu 22.04/24.04 + NGINX + Node + MySQL 8 + systemd. |
| Docker Compose (preview) | <https://ghost.org/docs/install/docker/> | ✅ | New Ghost 6.0+ tooling. Optional self-hosted ActivityPub + Tinybird Analytics. Caddy webserver. |
| Local install (dev) | <https://ghost.org/docs/install/local/> | ✅ | Development on Mac/Win/Linux with SQLite. Not for production. |
| Install from source | <https://ghost.org/docs/install/source/> | ✅ | Working on Ghost core itself (fork → `pnpm dev`). Not for production. |
| DigitalOcean 1-Click | <https://ghost.org/docs/install/digitalocean/> | ✅ (DO is upstream's "official hosting partner") | Marketplace droplet — runs Ghost-CLI under the hood. |
| Linode VPS | <https://ghost.org/docs/install/linode/> | ✅ | Thin wrapper: provision a Linode Ubuntu VPS, then follow the Ubuntu guide. |
| Ghost(Pro) managed hosting | <https://ghost.org/pricing/> | ✅ | Out of scope for open-forge — paid managed service, no install. |
| Bitnami blueprint | <https://bitnami.com/stack/ghost> | ⚠️ Community-maintained | Pre-baked single-node Apache + Node + MySQL. AWS Lightsail / others. **Not in upstream's install index.** |
| Docker Hub `ghost` image | <https://ghost.org/docs/install/docker-community/> · <https://hub.docker.com/_/ghost> | ⚠️ Community-maintained | Older image at `docker-library/ghost`. Upstream recommends the new ghost-docker preview instead. |

## Inputs to collect

Phase-keyed prompts. Ask each at the phase where it's needed — not all upfront.

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion`, options from the table above | Drives which method section the recipe loads. |
| dns | "What's the domain you want to host Ghost on?" | Free-text | All methods that expose Ghost publicly. |
| dns | "Use `www.<domain>` or apex (`<domain>`) as canonical?" | `AskUserQuestion`: `www` / `apex` | All public-facing methods. Some (Docker preview's Caddy redirect blocks, Bitnami's `bncert-tool`) have method-specific gotchas — see those sections. |
| tls | "Email for Let's Encrypt expiration notices?" | Free-text | All public-facing methods (Ghost-CLI, Docker preview, DO, Linode, Bitnami). Cert auto-renews; this is the warning channel if it ever breaks. |
| smtp | "Which outbound email provider?" | `AskUserQuestion`: `Resend` / `SendGrid` / `Mailgun` / `Other (specify)` / `Skip outbound` | All methods (Ghost requires SMTP for membership / newsletter / password-reset). Loads the matching `references/modules/smtp-*.md`. |
| smtp | "API key for `<provider>`?" | Free-text (sensitive — rotate after) | Resend keys start `re_`; SendGrid `SG.`; Mailgun varies. |
| smtp | "From address?" | Free-text | Must be on a verified domain at the provider. |
| smtp | "From display name?" | Free-text | E.g. `Aria Zhang`. Plain string — Claude wraps it correctly in JSON / env config. |
| inbound (optional) | "Set up inbound forwarding (e.g. `hello@<domain>` → your Gmail)?" | `AskUserQuestion`: `Yes — ImprovMX` / `Skip` | Loads `references/modules/inbound-improvmx.md`. |
| inbound | "Where should `<alias>@<domain>` forward to?" | Free-text | Existing inbox the user reads. |

Method-specific extras (e.g. Bitnami's `blueprint_id` / `bundle_id`, DigitalOcean's droplet size) are listed in the relevant method section.

After each prompt, write the value into the state file under `inputs.*` so a resume can skip re-asking.

## Mail configuration (cross-cutting JSON shape)

Ghost-CLI installs (Ubuntu, Local, DigitalOcean, Linode) and the Bitnami blueprint configure mail in `config.production.json`. The Docker preview maps the same fields onto `MAIL_*` env vars in `.env`. Canonical JSON shape:

```json
"mail": {
  "transport": "SMTP",
  "from": "'<Display Name>' <<from-address>>",
  "options": {
    "host": "<smtp-host>",
    "port": 465,
    "secure": true,
    "auth": {
      "user": "<smtp-user>",
      "pass": "<smtp-pass>"
    }
  }
}
```

Per-provider specifics: see `references/modules/smtp-*.md` (Resend, SendGrid, Mailgun) and upstream's <https://ghost.org/docs/config/#mail>.

### Verifying SMTP

Once configured, in Ghost admin: **Settings → Email newsletter → Send test email**, or add a member and publish a test post. Confirm arrival in the inbox AND the provider's dashboard / log.

Common failures:

- Wrong `user` — many providers use a literal string like `"resend"` or `"apikey"`, not the account email.
- Wrong port — `465` = implicit TLS `secure:true`; `587` = STARTTLS `secure:false`.
- Unverified sending domain at the provider.

If it fails, check Ghost's log:

- Ghost-CLI / Bitnami: `tail -n 200 <ghost-content-dir>/logs/*.log`
- Docker preview: `docker compose logs ghost`

---

## Method — Ghost-CLI on Ubuntu

> **Source:** <https://ghost.org/docs/install/ubuntu/> (TryGhost/Docs `install/ubuntu.mdx`).

_Section content added in a subsequent commit (Task B of the granular fix plan)._

---

## Method — Docker Compose (preview)

> **Source:** <https://ghost.org/docs/install/docker/> (TryGhost/Docs `install/docker.mdx`). Tooling repo: <https://github.com/TryGhost/ghost-docker>.

_Section content added in a subsequent commit (Task C of the granular fix plan)._

---

## Method — Local install (dev)

> **Source:** <https://ghost.org/docs/install/local/> (TryGhost/Docs `install/local.mdx`).

_Section content added in a subsequent commit (Task D of the granular fix plan)._

---

## Method — Install from source (Ghost core dev)

> **Source:** <https://ghost.org/docs/install/source/> (TryGhost/Docs `install/source.mdx`).

_Section content added in a subsequent commit (Task E of the granular fix plan)._

---

## Method — DigitalOcean 1-Click marketplace

> **Source:** <https://ghost.org/docs/install/digitalocean/> (TryGhost/Docs `install/digitalocean.mdx`). Marketplace listing: <https://marketplace.digitalocean.com/apps/ghost>.

_Section content added in a subsequent commit (Task F of the granular fix plan)._

---

## Method — Linode VPS

> **Source:** <https://ghost.org/docs/install/linode/> (TryGhost/Docs `install/linode.mdx`).

_Section content added in a subsequent commit (Task G of the granular fix plan)._

---

## Method — Bitnami blueprint (community-maintained)

> ⚠️ **Community-maintained.** Bitnami is not affiliated with TryGhost, and this method is **not** listed in upstream's install index at <https://ghost.org/docs/install/>. The Bitnami Ghost stack ships as an AWS Lightsail blueprint (and other marketplace channels). Verify Bitnami's own docs (<https://docs.bitnami.com/>) for current versions, paths, and gotchas at deploy time — they may have changed since this section was written.

The Bitnami Ghost blueprint bundles Ghost, Node, MySQL, and Apache as a reverse proxy. Ghost itself listens on `127.0.0.1:2368`; Apache terminates TLS and proxies to it.

### Bitnami-specific inputs

After preflight (which gathers AWS profile/region/deployment name), the cross-cutting prompts above cover domain / TLS / SMTP. Bitnami additionally needs:

| Field | Value |
|---|---|
| `blueprint_id` | `ghost_5` (latest Ghost major the blueprint ships with — version may be `6.x` in practice) |
| `bundle_id` | `nano_3_0` works for a personal blog; upgrade to `micro_3_0`+ for real traffic |

### Initial admin credentials

Right after provision, the initial admin email + password live in a file on the instance:

```bash
ssh -i "$KEY_PATH" "bitnami@$PUBLIC_IP" 'sudo cat /home/bitnami/bitnami_credentials'
```

Save the admin URL for the state file:

```
outputs.admin_url: https://<canonical-host>/ghost
```

Remind the user to change the password during the **hardening** phase.

### Paths

| Thing | Path |
|---|---|
| App root | `/opt/bitnami/ghost/` |
| Config | `/opt/bitnami/ghost/config.production.json` |
| Apache HTTPS vhost | `/opt/bitnami/apache/conf/vhosts/ghost-https-vhost.conf` |
| Apache HTTP vhost | `/opt/bitnami/apache/conf/vhosts/ghost-vhost.conf` |
| ctlscript | `/opt/bitnami/ctlscript.sh` |

### Restart command

After any config change:

```bash
sudo /opt/bitnami/ctlscript.sh restart
```

Takes 10–20s. Ghost logs to `/opt/bitnami/ghost/logs/` (check if it fails to start).

### TLS via bncert-tool

Bitnami ships a Let's Encrypt helper called `bncert-tool`. It does **not** support `--mode unattended` — attempting that prints "Unattended mode is not supported yet" and exits.

**Use `--mode text` with an option file.** Piping `yes` does not work — the flags get ignored and the tool re-prompts.

Write the option file:

```bash
cat > /tmp/bncert.opts <<EOF
domains=${APEX} ${CANONICAL_HOST}
email=${LETSENCRYPT_EMAIL}
accept_tos=1
enable_https_redirection=1
enable_www_to_nonwww_redirection=0
enable_nonwww_to_www_redirection=1
EOF
```

Note: redirect direction flags in the option file are finicky and sometimes do not override the tool's interactive default. Verify after the fact with `curl -sI`. If the canonical ended up reversed from what was asked, either re-run the tool or accept it and document.

Run:

```bash
sudo /opt/bitnami/bncert-tool --mode text --optionfile /tmp/bncert.opts
```

The tool rewrites the Apache vhosts and obtains + installs the cert. Ports 80/443 must be reachable from the internet first — DNS must already resolve to the instance.

Verify:

```bash
curl -sI "https://${CANONICAL_HOST}/"
```

Expect `HTTP/1.1 200` or `301/302` with a valid certificate.

### Switch Ghost's URL to https

Ghost stores its canonical URL in `config.production.json`. After TLS is working, update it:

```bash
ssh … 'sudo jq ".url = \"https://'"${CANONICAL_HOST}"'\"" /opt/bitnami/ghost/config.production.json > /tmp/ghost-config.json \
       && sudo mv /tmp/ghost-config.json /opt/bitnami/ghost/config.production.json \
       && sudo chown bitnami:daemon /opt/bitnami/ghost/config.production.json'
sudo /opt/bitnami/ctlscript.sh restart
```

#### ⚠️ Apache reverse-proxy fix (critical — do this at the same time)

If Apache proxies requests to Ghost without forwarding the original scheme/host, Ghost sees the request as HTTP and redirects back to `https://127.0.0.1:2368/` — the site dies with a redirect loop or dropped connections.

Edit `/opt/bitnami/apache/conf/vhosts/ghost-https-vhost.conf`. Directly before the `ProxyPass / http://127.0.0.1:2368/` line, add:

```apache
ProxyPreserveHost On
RequestHeader set X-Forwarded-Proto "https"
```

Restart Apache:

```bash
sudo /opt/bitnami/ctlscript.sh restart apache
```

Verify the site loads in a browser and the admin UI at `/ghost` does not bounce. Stale 301s from the broken state can stick around in the browser — suggest a hard reload or incognito window.

### Bitnami mail configuration

The cross-cutting JSON shape above goes into `/opt/bitnami/ghost/config.production.json`. Apply with `jq`, not hand-editing — `config.production.json` is JSON and a stray comma breaks Ghost on startup:

```bash
# Build new mail block in a temp file, then splice it in
sudo jq --slurpfile m /tmp/mail.json '.mail = $m[0]' \
  /opt/bitnami/ghost/config.production.json > /tmp/ghost-config.json \
  && sudo mv /tmp/ghost-config.json /opt/bitnami/ghost/config.production.json \
  && sudo chown bitnami:daemon /opt/bitnami/ghost/config.production.json
sudo /opt/bitnami/ctlscript.sh restart
```

### Bitnami database

Bitnami provisions MySQL on localhost with a generated password. Ghost is already wired up; normally no action is needed. If you need direct DB access, the creds are in `config.production.json` under `database.connection`.

### Bitnami gotchas summary

- **bncert-tool**: text mode + option file, no `--unattended`, don't pipe `yes`.
- **Redirect direction**: option-file `enable_*_redirection` flags sometimes ignored — verify with `curl -sI`.
- **Apache proxy after https URL**: must add `ProxyPreserveHost On` + `X-Forwarded-Proto "https"` or Ghost dies with loops.
- **JSON config**: always edit with `jq`, restore ownership to `bitnami:daemon`.
- **Restart timing**: `ctlscript.sh restart` takes 10–20s; site 502s briefly during restart.
- **Stale 301s in browser**: after any redirect change, hard reload or incognito.

---

## Method — Docker Hub community image

> **Source:** <https://ghost.org/docs/install/docker-community/> (TryGhost/Docs `install/docker-community.mdx`). Image: <https://hub.docker.com/_/ghost>. Maintained by the docker-library community at <https://github.com/docker-library/ghost>.

_Section content added in a subsequent commit (Task H of the granular fix plan)._

---

## TODO — verify on subsequent deployments

- **Tasks B–H of the granular fix plan**: fill in the placeholder method sections in subsequent commits (Ghost-CLI Ubuntu, Docker Compose preview, Local, Source, DigitalOcean 1-Click, Linode, Docker Hub community).
- **First Ghost-CLI Ubuntu deploy**: verify the install-question list, NGINX vhost paths, and systemd unit name match what's on real Ubuntu 22.04 / 24.04 in 2026.
- **First Docker Compose preview deploy**: verify the `ghost-docker` repo structure + `.env.example` fields haven't drifted; verify Tinybird workspace creation flow end-to-end.
- **First DigitalOcean 1-Click deploy**: confirm a base droplet still spins the Ghost-CLI flow on first SSH (per upstream `digitalocean.mdx`).
- **First Linode deploy**: confirm "follow Ubuntu guide" minimal-wrapper still applies; record any Linode-specific firewall / image gotchas.
- **Bitnami Apache reverse-proxy fix**: verify it's still required on the latest Bitnami `ghost_5` blueprint (may be fixed upstream by Bitnami).
- **Docker Hub community image**: confirm the latest tag layout (`5-alpine` vs `6-alpine` etc.) and document migration semantics if a user starts here then later moves to the ghost-docker preview.
