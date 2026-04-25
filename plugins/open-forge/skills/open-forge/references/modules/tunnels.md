---
name: tunnels
description: Cross-cutting module for giving a localhost (or otherwise-private) service public reach without exposing the user's home IP or fiddling with NAT/port-forwarding. Three options: Cloudflare Tunnel, Tailscale Funnel, ngrok. Loaded when the user picks `localhost` infra and answers yes to "should this be reachable from outside?"
---

# Tunnels — make a private service publicly reachable

For projects deployed on `infra/localhost.md` (or any setup behind NAT) that need an internet-facing URL — typically for messaging-app webhooks (Telegram bot, Discord, Slack), mobile apps that hit a backend, or just sharing a link with someone.

Three options, ranked by typical fit:

| Option | Free tier | Custom domain | Best for |
|---|---|---|---|
| **Cloudflare Tunnel** | Yes (unlimited bandwidth) | Yes (your registered domain) | Production-feel, custom domain, free |
| **Tailscale Funnel** | Yes (private network shares with public access on top) | `*.ts.net` subdomain | Tailscale users; staying inside a single mesh |
| **ngrok** | Yes (random URL) | Paid | Quick demos, ephemeral testing |

## Decide with the user

```
AskUserQuestion: "Which tunnel?"
Options:
  - Cloudflare Tunnel — own domain, free, ~5min setup (recommended)
  - Tailscale Funnel — easiest if you already use Tailscale
  - ngrok — fastest for a one-off demo
```

Skip if the user already has a preferred option.

## Cloudflare Tunnel (recommended for production-feel)

Prereqs:

- A domain managed in Cloudflare DNS (free tier is fine; nameservers need to be Cloudflare's).
- The user logs in once via browser to authorize.

Install + run:

```bash
# macOS
brew install cloudflared

# Linux
sudo curl -fsSL -o /usr/local/bin/cloudflared \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$(dpkg --print-architecture 2>/dev/null || uname -m)
sudo chmod +x /usr/local/bin/cloudflared
```

Authorize + create a named tunnel:

```bash
cloudflared tunnel login                          # opens browser, user picks domain
cloudflared tunnel create <deployment-name>       # creates tunnel + UUID
cloudflared tunnel route dns <deployment-name> <subdomain>.<domain>  # creates DNS record
```

Configure `~/.cloudflared/config.yml`:

```yaml
tunnel: <UUID-from-create>
credentials-file: /Users/<you>/.cloudflared/<UUID>.json

ingress:
  - hostname: <subdomain>.<domain>
    service: http://localhost:<local-port>
  - service: http_status:404
```

Run:

```bash
cloudflared tunnel run <deployment-name>
```

For always-on:

- macOS: `cloudflared service install` (uses launchd)
- Linux: `sudo cloudflared service install` (uses systemd)

Cloudflare terminates TLS at their edge — the user gets a real Let's Encrypt-or-better cert at `https://<subdomain>.<domain>` automatically.

## Tailscale Funnel

Prereqs:

- Tailscale installed and signed in on the host.
- Funnel must be enabled in the Tailscale admin (`https://login.tailscale.com/admin/settings/features`).

Run:

```bash
tailscale funnel <local-port>      # exposes http://localhost:<port> at https://<machine>.<tailnet>.ts.net
tailscale funnel status            # confirm
```

URL is fixed (`<machine>.<tailnet>.ts.net`) — no custom domain on the free tier. TLS is automatic.

For always-on, Funnel is sticky across reboots after the first activation.

## ngrok (quick demos only)

Install:

```bash
brew install ngrok        # macOS
# or download from ngrok.com
```

Authorize (one-time):

```bash
ngrok config add-authtoken <token>   # from ngrok dashboard
```

Run:

```bash
ngrok http <local-port>
```

URL is a random `*.ngrok.io` (or `*.ngrok-free.app`) subdomain, regenerated each restart unless on a paid plan with a reserved domain. Fine for "send my friend a link to test" — bad for messaging-app webhooks that need a stable URL.

## Verify

After the tunnel is up, in a separate browser/terminal:

```bash
curl -sI https://<the-public-url>/   # expect 2xx/3xx through to the local service
```

If the project requires a webhook (Telegram bot, Discord, etc.), register the webhook URL with the messaging platform and send a test message.

## Security notes

- A tunnel makes a previously-private service publicly reachable. Make sure the project's auth is in place first (gateway tokens, basic auth, OAuth, etc.). Don't expose admin UIs without auth in front.
- Cloudflare Tunnel + Tailscale Funnel both terminate TLS for you. ngrok also does. The user generally doesn't need to set up Let's Encrypt themselves.
- For Cloudflare Tunnel: the connection from your machine is *outbound* to Cloudflare's edge — no inbound port-forwarding required, no public IP needed, your home/office firewall stays untouched.
