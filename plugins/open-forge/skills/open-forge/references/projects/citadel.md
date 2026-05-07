---
name: citadel
description: Citadel recipe for open-forge. All-in-one groupware server with email, calendar, address book, forums, mailing lists, IM, wiki, RSS. C + Docker. Source: https://www.citadel.org/
---

# Citadel

A comprehensive, all-in-one groupware server. Includes email (SMTP/IMAP/POP3), calendar/scheduling, address books, forums, mailing lists, instant messaging, wiki, blog engines, and RSS aggregation — all in one self-contained package. GPL-3.0 licensed, written in C. Supports Docker. Upstream: <https://www.citadel.org/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | Easy Install script | One-step automated installer |
| Any Linux | Docker Compose | Official Docker image |
| Any Linux | Build from source | C build; Debian/Ubuntu recommended |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Citadel?" | FQDN | e.g. groupware.example.com |
| "Install method?" | Easy Install / Docker | Easy Install is simplest on Debian/Ubuntu |
| "Admin username and password?" | string + secret | First admin account |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "FQDN/hostname for SMTP?" | FQDN | Used in mail headers and SMTP EHLO |
| "Enable HTTPS?" | Yes / No | Recommended; configure TLS cert path |
| "Timezone?" | TZ string | e.g. America/New_York |

## Software-Layer Concerns

- **All-in-one**: Citadel is a monolithic groupware server — email, calendaring, IM, forums, and web all in one process/package. No separate components to wire together.
- **Webcit**: The web interface ("WebCit") is a separate process that proxies to the Citadel server — both must run for browser access.
- **Data directory**: All data stored in `/usr/local/citadel/data/` (or configured path). Must be persistent.
- **Easy Install**: Downloads, compiles, and configures everything automatically — recommended for first-time installs on Debian/Ubuntu.
- **IMAP/POP3/SMTP**: Runs its own mail stack — ensure ports 25, 143, 993, 110, 995 are open and not conflicting with another MTA.
- **ActiveSync**: Citadel includes ActiveSync support for mobile device sync (calendar, contacts, email).
- **No external database**: Uses its own built-in database — no MySQL/PostgreSQL needed.

## Deployment

### Easy Install (Debian/Ubuntu — recommended)

```bash
curl -fsSL https://easyinstall.citadel.org/install | bash
# Or: wget -O- https://easyinstall.citadel.org/install | bash
# Automates: download, compile, configure, start
# Access WebCit at http://your-server:2000/ after install
```

### Docker Compose

```yaml
services:
  citadel:
    image: citadel/citadel:latest
    ports:
      - "25:25"    # SMTP
      - "143:143"  # IMAP
      - "993:993"  # IMAPS
      - "110:110"  # POP3
      - "995:995"  # POP3S
      - "587:587"  # Submission
      - "2000:2000" # WebCit HTTP
      - "2001:2001" # WebCit HTTPS
    volumes:
      - citadel_data:/usr/local/citadel/data
    environment:
      CITADEL_ADMIN_USERNAME: admin
      CITADEL_ADMIN_PASSWORD: changeme
    restart: unless-stopped

volumes:
  citadel_data:
```

Access the web interface at `http://your-server:2000/`

## Upgrade Procedure

1. Docker: `docker compose pull && docker compose up -d` — data volume persists.
2. Easy Install: Re-run the install script — it detects existing installations and upgrades.
3. Always backup `/usr/local/citadel/data/` before upgrading.

## Gotchas

- **Port conflicts**: Citadel runs its own SMTP/IMAP — ensure no other MTA (Postfix, Exim, Dovecot) is running on the same ports.
- **WebCit is separate**: The web interface is its own process — both `citadel` and `webcit` must be running. Easy Install handles this automatically.
- **Ports 2000/2001 for WebCit**: Non-standard ports by default — put a reverse proxy (NGINX/Caddy) in front and forward to 2000/2001 for standard HTTP/HTTPS.
- **Monolithic by design**: All features are built-in and share the same data store. This makes administration simpler but means you get everything whether you want it or not.
- **No external DB**: Citadel uses its own database engine (Berkeley DB historically) — standard DB backup tools don't apply; use Citadel's own export tools.
- **Older C codebase**: Citadel has been around since the 1980s. It works well but the architecture is traditional. Review the roadmap at https://www.citadel.org/roadmap.html for current status.

## Links

- Website: https://www.citadel.org/
- Easy Install: https://easyinstall.citadel.org/
- Documentation: https://www.citadel.org/docs.html
- Source: https://www.citadel.org/source.html
- Screenshots: https://www.citadel.org/screenshots.html
- Docker Hub: https://hub.docker.com/r/citadel/citadel
