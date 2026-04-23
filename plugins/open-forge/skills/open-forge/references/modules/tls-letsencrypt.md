---
name: tls-letsencrypt
description: Cross-cutting guidance for obtaining a Let's Encrypt certificate and fixing the reverse proxy afterwards. Read during the `tls` phase of open-forge. Project-specific details (which tool to run, which config file to edit) live in the project recipe.
---

# Let's Encrypt — cross-cutting notes

Per-project recipes document *which* tool issues the cert (e.g. `bncert-tool` for Bitnami, `certbot` for vanilla Ubuntu, `caddy` for Caddy setups). This file documents concerns that span all of them.

## Preconditions

Do not attempt to issue a cert until:

- DNS resolves for every hostname the cert will cover (apex AND `www`, at minimum).
- Port 80 is open and reachable from the public internet (ACME HTTP-01 challenge).
- The web server on port 80 is serving something (even a 200 for `/.well-known/acme-challenge/` path is fine; most tools handle this automatically).

## Non-interactive mode pitfalls

Every issuance tool has its own non-interactive quirks. Do not assume `--yes` or `--unattended` works.

- **Bitnami `bncert-tool`**: `--mode unattended` does NOT exist. Use `--mode text --optionfile <path>`. See `references/projects/ghost.md` for an example option file.
- **`certbot`**: `--non-interactive --agree-tos --email <e>` works. Requires `-d <domain>` for each SAN.
- **Piping `yes` to any of these**: usually fails. The tools read structured prompts, not a stream of "y".

## Domains to include

Include both apex and the canonical subdomain in the cert, even if only one is canonical. The redirect host needs a valid cert too.

```
-d example.com -d www.example.com
```

## The reverse-proxy trap

After issuing the cert and switching the app's configured URL from `http://` to `https://`, many apps enforce an HTTPS redirect. If the reverse proxy in front of them terminates TLS but proxies plain HTTP to the app without forwarding the original scheme, the app sees HTTP and redirects — producing a redirect loop or bounce to `https://127.0.0.1:<port>/`.

Fix: on the HTTPS vhost, forward the original scheme and preserve the Host header.

For Apache:

```apache
ProxyPreserveHost On
RequestHeader set X-Forwarded-Proto "https"
```

For Nginx:

```nginx
proxy_set_header Host $host;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

Restart the web server after editing. Then verify:

```bash
curl -sI "https://<canonical-host>/"
# Expect 2xx or 3xx with a valid cert, not a loop.
```

## Canonical + redirect verification

After issuance and the proxy fix, all of these should succeed:

```bash
curl -sI "http://<apex>/"          # → 301 to https://<canonical>
curl -sI "http://www.<apex>/"      # → 301 to https://<canonical>
curl -sI "https://<non-canonical-host>/"  # → 301 to https://<canonical>
curl -sI "https://<canonical>/"    # → 200/302 with a valid cert
```

If a browser shows stale behavior after the fix, the culprit is almost always a cached 301 with a long `max-age`. Suggest a hard reload or incognito session.

## Renewal

Let's Encrypt certs expire in 90 days. Most tools install a cron / systemd timer automatically:

- Bitnami: `bncert-tool` installs an auto-renew systemd unit.
- certbot: installs a cron job in `/etc/cron.d/certbot` or a systemd timer.
- Caddy: handles renewal natively.

Confirm during hardening. If renewal is missing, add a simple cron:

```
0 3 * * * root certbot renew --quiet
```

Mention the Let's Encrypt expiration-notice email (already collected as `inputs.letsencrypt_email`) — if renewal silently breaks, that's the warning channel.
