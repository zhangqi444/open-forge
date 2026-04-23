---
name: ghost-project
description: Ghost recipe for open-forge. Assumes the Bitnami Ghost blueprint (single-node, Apache + Node + MySQL pre-installed). Covers admin password retrieval, URL switch, mail config, bncert-tool invocation, and the Apache reverse-proxy fix required after enabling HTTPS.
---

# Ghost (Bitnami blueprint)

The Bitnami Ghost blueprint bundles Ghost, Node, MySQL, and Apache as a reverse proxy. Ghost itself listens on `127.0.0.1:2368`; Apache terminates TLS and proxies to it.

## Inputs to collect

After preflight (which gathers AWS profile/region/deployment name), Ghost-specific prompts. Ask each at the phase where it's needed — not all upfront.

| Phase | Prompt | Tool / format | Notes |
|---|---|---|---|
| dns | "What's the domain you want to host Ghost on?" | Free-text | Must be one the user controls at their registrar |
| dns | "Use `www.<domain>` or apex (`<domain>`) as canonical?" | `AskUserQuestion`, options: `www` / `apex` | `www` is safer with bncert-tool's defaults; see *TLS via bncert-tool* gotchas |
| tls | "Email for Let's Encrypt expiration notices?" | Free-text | Cert auto-renews; this is just the warning channel if it ever breaks |
| smtp | "Which outbound email provider?" | `AskUserQuestion`, options: `Resend` / `SendGrid` / `Mailgun` / `Other (specify)` / `Skip outbound` | Loads the matching `references/modules/smtp-*.md` |
| smtp | "API key for `<provider>`?" | Free-text (sensitive — rotate after) | Resend keys start `re_`; SendGrid `SG.`; Mailgun varies |
| smtp | "From address?" | Free-text | Must be on a verified domain at the provider |
| smtp | "From display name?" | Free-text | E.g. `Aria Zhang`. Plain string — Claude wraps it correctly in the JSON |
| inbound (optional) | "Set up inbound forwarding (e.g. `hello@<domain>` → your Gmail)?" | `AskUserQuestion`, options: `Yes — ImprovMX` / `Skip` | If yes, loads `references/modules/inbound-improvmx.md` |
| inbound | "Where should `<alias>@<domain>` forward to?" | Free-text | Existing inbox the user reads |

After each prompt, write the value into the state file under `inputs.*` so a resume can skip re-asking.

## Blueprint + bundle

| Field | Value |
|---|---|
| `blueprint_id` | `ghost_5` (latest Ghost major the blueprint ships with — version may be `6.x` in practice) |
| `bundle_id` | `nano_3_0` works for a personal blog; upgrade to `micro_3_0`+ for real traffic |

## Initial admin credentials

Right after provision, the initial admin email + password live in a file on the instance:

```bash
ssh -i "$KEY_PATH" "bitnami@$PUBLIC_IP" 'sudo cat /home/bitnami/bitnami_credentials'
```

Save the admin URL for the state file:

```
outputs.admin_url: https://<canonical-host>/ghost
```

Remind the user to change the password during the **hardening** phase.

## Paths

| Thing | Path |
|---|---|
| App root | `/opt/bitnami/ghost/` |
| Config | `/opt/bitnami/ghost/config.production.json` |
| Apache HTTPS vhost | `/opt/bitnami/apache/conf/vhosts/ghost-https-vhost.conf` |
| Apache HTTP vhost | `/opt/bitnami/apache/conf/vhosts/ghost-vhost.conf` |
| ctlscript | `/opt/bitnami/ctlscript.sh` |

## Restart command

After any config change:

```bash
sudo /opt/bitnami/ctlscript.sh restart
```

Takes 10–20s. Ghost logs to `/opt/bitnami/ghost/logs/` (check if it fails to start).

## TLS via bncert-tool

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

## Switch Ghost's URL to https

Ghost stores its canonical URL in `config.production.json`. After TLS is working, update it:

```bash
ssh … 'sudo jq ".url = \"https://'"${CANONICAL_HOST}"'\"" /opt/bitnami/ghost/config.production.json > /tmp/ghost-config.json \
       && sudo mv /tmp/ghost-config.json /opt/bitnami/ghost/config.production.json \
       && sudo chown bitnami:daemon /opt/bitnami/ghost/config.production.json'
sudo /opt/bitnami/ctlscript.sh restart
```

### ⚠️ Apache reverse-proxy fix (critical — do this at the same time)

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

## Mail configuration

Ghost's mail block in `config.production.json`. For SMTP providers, shape:

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

See `references/modules/smtp-*.md` for per-provider specifics.

Apply with `jq`, not hand-editing — `config.production.json` is JSON and a stray comma breaks Ghost on startup:

```bash
# Build new mail block in a temp file, then splice it in
sudo jq --slurpfile m /tmp/mail.json '.mail = $m[0]' \
  /opt/bitnami/ghost/config.production.json > /tmp/ghost-config.json \
  && sudo mv /tmp/ghost-config.json /opt/bitnami/ghost/config.production.json \
  && sudo chown bitnami:daemon /opt/bitnami/ghost/config.production.json
sudo /opt/bitnami/ctlscript.sh restart
```

### Verifying SMTP

In Ghost admin: **Settings → Email newsletter → Send test email**, or add a member and publish a test post. Confirm arrival in the inbox and in the provider's dashboard/log.

If the test fails, check Ghost's log:

```bash
sudo tail -n 200 /opt/bitnami/ghost/logs/*.log
```

Common failures: wrong `user` (many providers use a literal string like `"resend"` or `"apikey"`, not the account email), wrong port (465 = implicit TLS `secure:true`; 587 = STARTTLS `secure:false`), unverified sending domain.

## Database

Bitnami provisions MySQL on localhost with a generated password. Ghost is already wired up; normally no action is needed. If you need direct DB access, the creds are in `config.production.json` under `database.connection`.

## Gotchas summary

- **bncert-tool**: text mode + option file, no `--unattended`, don't pipe `yes`.
- **Redirect direction**: option-file `enable_*_redirection` flags sometimes ignored — verify with `curl -sI`.
- **Apache proxy after https URL**: must add `ProxyPreserveHost On` + `X-Forwarded-Proto "https"` or Ghost dies with loops.
- **JSON config**: always edit with `jq`, restore ownership to `bitnami:daemon`.
- **Restart timing**: `ctlscript.sh restart` takes 10–20s; site 502s briefly during restart.
- **Stale 301s in browser**: after any redirect change, hard reload or incognito.
