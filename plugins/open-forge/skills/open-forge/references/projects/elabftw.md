---
name: elabftw
description: eLabFTW recipe for open-forge. Electronic lab notebook for research teams — store experiments, manage a reagent/protocol database, trusted timestamping, calendar, and REST API. Source: https://github.com/elabftw/elabftw
---

# eLabFTW

Electronic lab notebook (ELN) for research teams. Lets researchers store and organize experiments, maintain a database of reagents, protocols, equipment, and cell lines, apply trusted timestamping, export records as PDF/ZIP, and manage equipment booking via a calendar. Supports multiple teams on one installation, a REST API, and 21 languages. Upstream: https://github.com/elabftw/elabftw. Docs: https://doc.elabftw.net.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| elabctl (Docker wrapper) | Docker on Linux | Recommended. Official management tool that wraps docker-compose. |
| Docker Compose (manual) | Docker | Direct compose setup for custom deployments. |
| Managed hosting | deltablot.email | Paid hosting by the developers. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Server hostname or IP?" | Used in the generated elabftw.yml config |
| tls | "HTTPS — Let's Encrypt or self-signed?" | elabctl can auto-provision Let's Encrypt certs |
| setup | "Admin email?" | First sysadmin account created post-install |
| storage | "Uploads directory?" | Default: /var/elabftw/web — stores user-uploaded files |

## Software-layer concerns

### elabctl install (recommended)

  # Install elabctl (as root or with sudo):
  curl -sL https://get.elabftw.net -o /usr/local/bin/elabctl
  chmod +x /usr/local/bin/elabctl

  # Initialize configuration:
  elabctl install
  # Interactive wizard: sets server name, TLS mode, ports, storage paths
  # Generates /etc/elabftw/elabftw.yml

  # Start the service:
  elabctl start

  # Access the web UI at https://<your-server>/
  # Create the first admin account via the registration page

### elabctl common commands

  elabctl start       - start all containers
  elabctl stop        - stop all containers
  elabctl restart     - restart containers
  elabctl update      - pull latest images and restart
  elabctl backup      - create a backup archive
  elabctl logs        - view container logs
  elabctl php-logs    - view PHP/application logs

### What elabctl manages

elabctl runs a docker-compose stack with:
  - eLabFTW PHP application container
  - MySQL database container
  - nginx/TLS container (handles HTTPS)

### Post-install steps

1. Open https://<host>/ in browser
2. Register the first sysadmin account (no invitation needed for first user)
3. Log in as sysadmin > Admin panel > Create teams
4. Invite team members or enable self-registration
5. Configure SMTP for email notifications: Sysadmin panel > SMTP

### Key config (elabftw.yml / environment variables)

  # Key env vars (set by elabctl wizard, editable in /etc/elabftw/elabftw.yml):
  DB_HOST=mysql
  DB_NAME=elabftw
  DB_USER=elabftw
  DB_PASSWORD=<generated>
  SECRET_KEY=<generated>
  SERVER_NAME=elabftw.example.com
  DISABLE_HTTPS=false                # set true if terminating TLS at a reverse proxy
  ENABLE_LETSENCRYPT=true            # or false for self-signed
  UPLOADS_STORAGE_BACKEND=local      # or s3

### Trusted timestamping

eLabFTW supports RFC 3161 trusted timestamping via external TSA (e.g. DigiCert, FreeTSA). Configure in Sysadmin > Timestamping. Timestamps create a legally verifiable proof that an experiment existed at a given time.

## Upgrade procedure

  elabctl update
  # This pulls the latest Docker images and restarts containers.
  # Database migrations run automatically on startup.

## Gotchas

- **First registration = sysadmin**: the first account created after install becomes the system administrator. Complete setup promptly on a new installation.
- **elabctl requires Docker**: it is a convenience wrapper around docker-compose. Install Docker first.
- **DISABLE_HTTPS for reverse proxy**: if you place nginx/Caddy in front, set DISABLE_HTTPS=true in elabftw.yml so the inner nginx doesn't conflict.
- **Backup before update**: always run `elabctl backup` before `elabctl update`. Backups go to /var/elabftw/backups/ by default.
- **AGPL-3.0 license**: source must remain open. Modifications must also be AGPL. Fine for self-hosted research use.
- **Multi-team, single install**: one eLabFTW instance can serve many independent research teams. Teams are isolated from each other.
- **Storage backend**: default is local filesystem. For large institutions, S3-compatible object storage is supported.

## References

- Upstream GitHub: https://github.com/elabftw/elabftw
- Documentation: https://doc.elabftw.net
- elabctl (installer): https://github.com/elabftw/elabctl
- Demo: https://demo.elabftw.net
- Docker Hub: https://hub.docker.com/r/elabftw/elabimg
