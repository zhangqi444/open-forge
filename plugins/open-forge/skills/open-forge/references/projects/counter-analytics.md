# Counter (counter.dev self-hosted)

**What it is:** A privacy-friendly, minimalist web analytics tool. Tracks page views, referrers, countries, and devices without cookies or persistent user IDs. Single Go binary backed by Redis. Supports multiple users/sites. Self-hosted version of the hosted counter.dev service.

> **Note:** Self-hosted version is in beta. Archiving functionality is not yet implemented.

**Official URL:** https://github.com/ihucos/counter.dev-selfhost
**License:** MIT
**Stack:** Go binary + Redis; no Docker image (binary only)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Binary + Redis | Single binary; Redis required |
| Any Linux VPS | Docker + Redis | Run binary in a minimal container alongside Redis |

---

## Inputs to Collect

### Pre-deployment
- Redis URL — e.g. `redis://localhost:6379`
- Bind address — e.g. `:80` (or behind a reverse proxy on a higher port)
- UTC offset — your timezone offset (e.g. `2` for UTC+2) — set per user at creation

---

## Software-Layer Concerns

**Installation:**
```bash
curl -L https://github.com/ihucos/counter.dev-selfhosted/releases/download/0.2/cntr-linux-amd64 \
  > /usr/local/bin/cntr
chmod +x /usr/local/bin/cntr
```

**Create a user:**
```bash
cntr createuser --redis-url redis://localhost:6379 --utc-offset 2 admin
# Prompts for password
```

**Serve:**
```bash
cntr serve --redis-url redis://localhost:6379 --bind :80
```

**Password reset:**
```bash
cntr chgpwd --redis-url redis://localhost:6379 youruser
```

**Tracking snippet:** After logging in, the UI provides a small JavaScript snippet to embed in your website's `<head>`. No cookies, no cross-site tracking.

**Reverse proxy:** Recommended — run `cntr serve --bind 127.0.0.1:8000` and proxy via nginx/Caddy.

**Redis persistence:** Ensure Redis is configured with either RDB snapshots or AOF for data durability.

**Upgrade procedure:**
1. Download the new binary from the releases page
2. Replace `/usr/local/bin/cntr`
3. Restart the service

---

## Gotchas

- **Beta quality** — archiving/data export not yet implemented
- **Redis is the only database** — no SQL; configure Redis persistence (RDB/AOF) or risk data loss on restart
- **UTC offset is per-user** — set at account creation; affects how daily stats are bucketed
- **No Docker image published** — run the binary directly or wrap it manually in a container
- **Self-hosted vs hosted** — the hosted counter.dev is separate; the self-hosted version may lag behind in features

---

## Links
- GitHub: https://github.com/ihucos/counter.dev-selfhost
- Hosted service (reference): https://counter.dev
- Releases: https://github.com/ihucos/counter.dev-selfhosted/releases
