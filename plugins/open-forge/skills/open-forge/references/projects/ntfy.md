---
name: ntfy-project
description: ntfy recipe for open-forge. Apache-2.0 / GPLv2 (dual-licensed) simple HTTP-based pub/sub notification service — send push notifications to your phone, desktop, or scripts via PUT/POST. Single Go binary, SQLite-backed, no signups needed. Covers the public `ntfy.sh` free tier, self-hosted Docker Compose deploy with TLS + users + ACLs, Firebase FCM integration for Android (for aggressive Android push), webhook fan-out, and the hosted Pro tier as an alternative.
---

# ntfy

Dual-licensed (Apache 2.0 / GPLv2) simple HTTP-based pub/sub notification service. Upstream: <https://github.com/binwiederhier/ntfy>. Docs: <https://ntfy.sh/docs/>. Public instance: <https://ntfy.sh>. Author: Philipp C. Heckel.

Pronounced "notify." The simplest way to get notifications from scripts / servers / anything with `curl` to your phone or desktop:

```bash
curl -d "Backup succeeded 👍" ntfy.sh/my-unique-topic
```

A second later, your phone beeps (if you've subscribed to `my-unique-topic` in the ntfy app). No API key, no account, no signup — at least on the public instance.

Self-host when you want:

- **Privacy** — your notifications don't transit `ntfy.sh`
- **Unlimited bandwidth / messages**
- **Custom domain** (e.g. `ntfy.example.com`)
- **Enforce ACLs** (who can publish to which topics)
- **Firebase FCM** (required for near-instant Android push via Google's infrastructure)
- **Integration with internal systems** (e-mail → notification, SMTP inbound, webhook outbound)

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Public `ntfy.sh` | <https://ntfy.sh> | ✅ | Instant, zero-setup. No privacy from operator. |
| ntfy Pro ($5/month+) | <https://ntfy.sh/app> | ✅ (paid) | Managed service with reserved topics, higher limits. Supports the project. |
| Docker image (`binwiederhier/ntfy`) | Docker Hub | ✅ Recommended for self-host | Most self-hosters. |
| Binary + systemd | <https://github.com/binwiederhier/ntfy/releases> | ✅ | Bare metal install. Single Go binary + SQLite. |
| Debian / RPM packages | <https://ntfy.sh/docs/install/> | ✅ | Ubuntu / Debian / CentOS / Fedora. |
| Homebrew | `brew install ntfy` | ✅ | macOS. |
| Build from source | Go | ✅ | Contributors. |
| Kubernetes Helm | Community | ⚠️ | No first-party chart but community ones exist. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `binary` / `deb-rpm-pkg` | Drives section. |
| dns | "Public domain?" | Free-text, e.g. `ntfy.example.com` | Required for phones + TLS. |
| tls | "TLS source?" | `AskUserQuestion`: `reverse-proxy (recommended)` / `ntfy-builtin-tls` | Reverse proxy is cleaner. |
| storage | "Data directory?" | Free-text, default `/var/cache/ntfy` | Contains SQLite DB, attachment cache. |
| auth | "Auth mode?" | `AskUserQuestion`: `open (anyone can publish+subscribe)` / `restricted (ACLs + users)` | For public hosting you want restricted. |
| auth | "Default permission?" | `AskUserQuestion`: `read-write` / `read-only` / `deny-all` | Sets the default ACL for unauthenticated / unknown users. |
| admin | "Initial admin user + password?" | Free-text (sensitive) | Created via `ntfy user add` CLI. |
| android | "Enable Firebase FCM for Android push?" | Boolean | Requires a Firebase project + service account JSON. If no, Android app uses direct WebSocket connection (uses more battery). |
| mail | "Enable inbound SMTP (email → ntfy)?" | Boolean | Optional. Set `smtp-server-listen` + friends. |
| webhooks | "Enable outbound webhooks / forward messages?" | Boolean | Optional. Configure per-topic or via `upstream-base-url`. |

## Install — Docker Compose

```yaml
# compose.yaml
services:
  ntfy:
    image: binwiederhier/ntfy:latest       # pin a version in prod, e.g. :v2.13.0
    container_name: ntfy
    restart: unless-stopped
    command: serve
    environment:
      # Match these to /etc/ntfy/server.yml OR use env vars (see docs/config.md)
      TZ: "UTC"
    ports:
      - "127.0.0.1:80:80"                  # bind loopback if reverse-proxied
    volumes:
      - ./ntfy-cache:/var/cache/ntfy
      - ./ntfy-config:/etc/ntfy
      # Mount your server.yml from the config dir
    healthcheck:
      test: ["CMD-SHELL", "wget -q --tries=1 http://localhost:80/v1/health -O - | grep -Eo '\"healthy\"\\s*:\\s*true' || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### server.yml (key settings)

```yaml
# ./ntfy-config/server.yml
base-url: "https://ntfy.example.com"
listen-http: ":80"
cache-file: "/var/cache/ntfy/cache.db"
cache-duration: "12h"
auth-file: "/var/cache/ntfy/auth.db"
auth-default-access: "deny-all"            # for a private instance
behind-proxy: true                          # honor X-Forwarded-* headers
attachment-cache-dir: "/var/cache/ntfy/attachments"
attachment-total-size-limit: "5G"
attachment-file-size-limit: "15M"
attachment-expiry-duration: "3h"

# Optional: Firebase FCM (Android push via Google)
# firebase-key-file: "/etc/ntfy/firebase-service-account.json"

# Optional: inbound SMTP (email → notification)
# smtp-sender-addr: "ntfy@example.com"
# smtp-sender-user: "ntfy"
# smtp-sender-pass: "smtp-password"
# smtp-sender-from: "noreply@example.com"
# smtp-server-listen: "[::]:2525"
# smtp-server-domain: "ntfy.example.com"

# Optional: WebPush (browser push)
# web-push-public-key: "..."
# web-push-private-key: "..."
# web-push-file: "/var/cache/ntfy/webpush.db"
# web-push-email-address: "admin@example.com"
```

Bring up:

```bash
mkdir -p ntfy-cache ntfy-config
# Write server.yml into ntfy-config/
docker compose up -d
docker compose logs -f ntfy
```

## Install — Binary / systemd (Debian / Ubuntu)

```bash
curl -sSL https://archive.heckel.io/apt/pubkey.txt | sudo tee /etc/apt/trusted.gpg.d/archive.heckel.io.asc
sudo apt install apt-transport-https
sudo sh -c "echo 'deb [arch=amd64] https://archive.heckel.io/apt debian main' > /etc/apt/sources.list.d/archive.heckel.io.list"
sudo apt update
sudo apt install ntfy
sudo systemctl enable --now ntfy

# Edit /etc/ntfy/server.yml to configure base-url, auth, etc.
sudo nano /etc/ntfy/server.yml
sudo systemctl restart ntfy
```

## User + ACL setup (for private instances)

```bash
# Add users
sudo ntfy user add --role=admin phil
# → prompts for password
sudo ntfy user add alice        # default role: user
sudo ntfy user add anonymous    # the "unauthenticated" pseudo-user

# Grant access per topic
sudo ntfy access alice alerts rw      # read-write on topic "alerts"
sudo ntfy access alice announcements ro  # read-only
sudo ntfy access anonymous public_topic ro
```

See <https://docs.ntfy.sh/config/#access-control>.

## Publishing messages

```bash
# Simplest (public topic on ntfy.sh)
curl -d "Hello, world" https://ntfy.sh/my-topic

# Self-hosted
curl -d "Backup done" https://ntfy.example.com/backups

# Auth (basic auth)
curl -u alice:password -d "Alert!" https://ntfy.example.com/alerts

# With title + priority + tags
curl -H "Title: Server restart" \
     -H "Priority: urgent" \
     -H "Tags: warning,skull" \
     -d "The DB server is down" \
     https://ntfy.example.com/ops

# Attach a file
curl -T backup.log -H "Filename: backup.log" https://ntfy.example.com/backups

# Action button (open URL / run command on receipt)
curl -H "Actions: view, Open link, https://example.com" \
     -d "Click to view" https://ntfy.example.com/alerts
```

## Subscribing

- **Android app** (<https://f-droid.org/en/packages/io.heckel.ntfy/> or Play Store): enter your `base-url` + topic.
- **iOS app**: same idea (App Store).
- **Web**: Open `https://ntfy.example.com/my-topic` in browser → "Subscribe" → receive push via Web Push.
- **curl stream**:
  ```bash
  curl -s https://ntfy.example.com/my-topic/json
  # → streams NDJSON as messages arrive
  ```
- **Webhook forward**: `curl -N https://ntfy.example.com/my-topic/raw` for plain-text stream.
- **Third-party**: Apprise supports ntfy: `ntfy://topic@ntfy.example.com/`.

## Reverse proxy (Caddy)

```caddy
ntfy.example.com {
    reverse_proxy ntfy:80
}
```

Caddy handles TLS + WebSocket proxying correctly. Nginx needs extra config for WebSocket upgrade headers.

## Firebase FCM setup (Android battery-friendly push)

Without FCM, the Android ntfy app uses a persistent WebSocket for instant delivery — but Android may kill it aggressively for battery. For "wake-locked" notification delivery from a self-hosted instance:

1. Create a Firebase project at <https://console.firebase.google.com>.
2. Generate a service account key (JSON).
3. Mount into container at `/etc/ntfy/firebase-service-account.json`.
4. Set `firebase-key-file` in `server.yml`.
5. Build a custom Android app from upstream source, configured with your Firebase API key (the Google Play version uses `ntfy.sh`'s FCM key, which doesn't know about your server). OR: self-host without FCM and accept that notifications may be delayed when the phone is idle.

**Most self-hosters skip FCM** and accept WebSocket-based delivery — works fine if the phone isn't in Doze mode.

## Inbound email → ntfy

If you set `smtp-server-listen`, ntfy listens for SMTP. Send an email to `<topic>@ntfy.example.com` and it becomes a notification.

Useful for: legacy apps that only speak SMTP (e.g. printer alerts, NAS notifications).

## Data layout

| Path | Content |
|---|---|
| `cache-file` (default `/var/cache/ntfy/cache.db`) | SQLite: messages + metadata, subscriber state |
| `auth-file` (default `/var/cache/ntfy/auth.db`) | SQLite: users + ACLs |
| `attachment-cache-dir` | Attachment files (purged after `attachment-expiry-duration`) |
| `web-push-file` | SQLite: Web Push subscriptions |
| `/etc/ntfy/server.yml` | Main config |
| `/etc/ntfy/firebase-service-account.json` (optional) | FCM creds |

**Backup** = tar the cache + config dirs. SQLite is robust; copy while running is usually safe (or use `.backup` via sqlite3 CLI for consistency).

## Upgrade procedure

### Docker

```bash
docker compose pull
docker compose up -d
```

### Debian

```bash
sudo apt update && sudo apt upgrade ntfy
sudo systemctl restart ntfy
```

ntfy migrates DB schemas on startup. Major-version jumps (v1 → v2) have introduced config-file renames; read release notes.

## Gotchas

- **Public `ntfy.sh` instance is a third party.** Your notification topics (and content) transit `ntfy.sh`. For sensitive alerts (security events, PII), self-host.
- **Topic names are effectively passwords on the free instance.** Anyone who guesses your topic can publish OR subscribe. Use long, random topic names.
- **Self-hosted with `auth-default-access: read-write`** (the insecure default) = anyone can publish to any topic on your server. Set to `deny-all` for private instances.
- **Android push without FCM uses a persistent WebSocket.** Battery impact depends on phone. On phones with aggressive battery optimizers (Samsung, Xiaomi, Huawei), WebSocket may be killed during Doze → delayed notifications. FCM fixes this but requires self-build of the Android app.
- **iOS app requires Apple Push Notifications (APNs).** Self-hosted ntfy iOS push works via a relay hosted by ntfy.sh itself — even self-hosted server users depend on ntfy.sh as a proxy for iOS push. Read <https://docs.ntfy.sh/config/#ios-instant-notifications>.
- **Attachment limits enforce at upload, not total cache.** An aggressive publisher can fill your `attachment-cache-dir` quickly. Set reasonable `attachment-total-size-limit`.
- **Attachment expiry is hours, not days.** Default 3h. Phones that receive an attachment AFTER expiry see a dead link. Tune based on your subscribers' connectivity patterns.
- **Message cache retention.** `cache-duration` (default 12h) controls how long messages are retained for catch-up-when-phone-reconnects. Set longer for flaky mobile networks.
- **Rate limits on `ntfy.sh`**: 60 requests / 1 message-per-hour-average per IP, 5 topics max, 200 total messages / day (last I checked — see current limits at ntfy.sh home). Exceed these = Pro tier or self-host.
- **Web Push requires HTTPS.** Browsers reject Web Push from HTTP origins. Reverse-proxy with TLS, always.
- **`behind-proxy: true`** is mandatory when you're behind a reverse proxy. Without it, rate limits apply per proxy-IP (= your proxy) = all requests look like they come from the proxy = one user can DoS the whole instance.
- **Inbound SMTP listener is a security surface.** If you enable `smtp-server-listen`, it's open on the network. Bind to localhost OR firewall. SMTP has historically been an attack target.
- **`ntfy.sh/app` is the Pro tier upsell.** The OSS server doesn't have a billing UI; that's only on the hosted service.
- **No built-in message encryption.** Topics can be intercepted by the server operator. For E2E, encrypt the payload yourself (e.g. `age` encryption) before publishing, decrypt in a subscriber script.
- **`NTFY_` env var prefix for env-config.** `NTFY_LISTEN_HTTP=:80` etc. overrides YAML. Docs document this; don't mix env + YAML for the same key.
- **CLI for user mgmt is server-side only.** `ntfy user add` must run on the server (same filesystem as the auth DB). No remote admin API for user mgmt (as of recipe write-time).
- **Android / iOS apps cache their subscription list locally** — if you delete a topic server-side, clients may still think they're subscribed until re-opened. Harmless but can confuse "why no notifications?" debugging.
- **Licensing is dual Apache 2.0 / GPLv2** — pick the one that matches your usage; most self-hosters use Apache for flexibility.

## Links

- Upstream repo: <https://github.com/binwiederhier/ntfy>
- Docs: <https://docs.ntfy.sh>
- Install guide: <https://docs.ntfy.sh/install/>
- Config reference: <https://docs.ntfy.sh/config/>
- Publishing guide: <https://docs.ntfy.sh/publish/>
- Subscribing (apps): <https://docs.ntfy.sh/subscribe/phone/>
- Docker Hub: <https://hub.docker.com/r/binwiederhier/ntfy>
- Releases: <https://github.com/binwiederhier/ntfy/releases>
- Android app repo: <https://github.com/binwiederhier/ntfy-android>
- iOS app repo: <https://github.com/binwiederhier/ntfy-ios>
- Public free tier: <https://ntfy.sh>
- ntfy Pro: <https://ntfy.sh/app>
- Discord: <https://discord.gg/cT7ECsZj9w>
- Matrix: <https://matrix.to/#/#ntfy:matrix.org>
