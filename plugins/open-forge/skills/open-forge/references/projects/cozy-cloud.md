---
name: cozy-cloud
description: Cozy Cloud recipe for open-forge. Personal cloud platform for files, notes, contacts, passwords, and documents with sync and app store. Go (cozy-stack) + CouchDB. Source: https://github.com/cozy/cozy-stack
---

# Cozy Cloud

A personal cloud platform bringing files, notes, contacts, passwords, and documents into one private space. Supports app installation from an app store, device sync, OAuth2, and data connectors that import data from remote services. GPL-3.0 licensed, core server ("cozy-stack") written in Go, backed by CouchDB. Upstream: <https://github.com/cozy/cozy-stack>. Self-hosting guide: <https://docs.cozy.io/en/tutorials/selfhosting/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | APT binary packages | Recommended for self-hosting — Cozy provides packages |
| Any Linux | Docker + CouchDB | Containerised setup |
| Any Linux | Go binary from source | Requires Go ≥1.25 |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Cozy?" | FQDN | e.g. cozy.example.com — Cozy creates sub-instances as subdomains |
| "CouchDB host, user, password?" | connection details | CouchDB 3 required |
| "SMTP server?" | host:port + credentials | For email notifications |
| "Admin passphrase?" | secret | For the cozy-stack admin API |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "File storage path?" | Directory | Where uploaded files are stored |
| "Reverse proxy?" | NGINX / Caddy | Required — cozy-stack listens on localhost |
| "Wildcard TLS cert?" | Yes / No | Cozy uses subdomains per instance — wildcard cert or DNS-01 challenge needed |

## Software-Layer Concerns

- **CouchDB 3 required**: Cozy uses CouchDB as its primary database — must be installed and running before cozy-stack starts.
- **Subdomain-per-instance**: Each Cozy instance lives at `<instance>.example.com`. Requires wildcard DNS (`*.example.com → server IP`) and wildcard TLS cert.
- **cozy-stack admin API**: Separate admin HTTP endpoint (default port 6060) — protected by admin passphrase, not exposed publicly.
- **App store**: Cozy apps (Drive, Photos, Contacts, etc.) are installed from the registry — internet access needed for app installation.
- **Data connectors**: Can pull data from third-party services (banks, utility companies, etc.) — requires internet access from the server.
- **Dependencies**: Reverse proxy, SMTP server, CouchDB 3, Git, ImageMagick, Ghostscript, rsvg-convert.
- **Multiple instances**: One cozy-stack process can host multiple Cozy instances (one per user) — suitable for small family deployments.

## Deployment

### Debian/Ubuntu (recommended)

Follow the official self-hosting guide at https://docs.cozy.io/en/tutorials/selfhosting/ — Cozy provides Debian packages via their APT repo.

```bash
# Install CouchDB 3
curl -L https://couchdb.apache.org/repo/keys.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/couchdb.gpg
echo "deb https://apache.jfrog.io/artifactory/couchdb-deb/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/couchdb.list
sudo apt update && sudo apt install couchdb

# Install cozy-stack (check https://docs.cozy.io for current repo)
# Then configure /etc/cozy/cozy.yaml:
# couchdb.url, fs.url (storage path), mail, admin.secret

# Start
sudo systemctl enable --now cozy-stack

# Create instance
cozy-stack instances add --apps drive,photos,contacts --passphrase "yourpassword" your-name.example.com
```

### Docker (CouchDB)

```yaml
services:
  couchdb:
    image: couchdb:3
    environment:
      COUCHDB_USER: cozy
      COUCHDB_PASSWORD: cozypassword
    volumes:
      - couchdb_data:/opt/couchdb/data
    restart: unless-stopped

  cozy:
    image: cozy/cozy-stack:latest
    ports:
      - "127.0.0.1:8080:8080"
      - "127.0.0.1:6060:6060"
    volumes:
      - cozy_storage:/data/cozy-storage
      - ./cozy.yaml:/etc/cozy/cozy.yaml:ro
    depends_on:
      - couchdb
    restart: unless-stopped

volumes:
  couchdb_data:
  cozy_storage:
```

## Upgrade Procedure

1. APT: `sudo apt update && sudo apt upgrade cozy-stack` — config preserved.
2. Docker: `docker compose pull && docker compose up -d`.
3. Check migration notes at https://github.com/cozy/cozy-stack/releases.
4. Backup CouchDB and storage before upgrading.

## Gotchas

- **Wildcard DNS + TLS required**: Each user instance is a subdomain — `user.example.com`. Standard single-domain certs won't work. Use Let's Encrypt DNS-01 challenge for `*.example.com`.
- **CouchDB must be running first**: cozy-stack will fail to start if CouchDB is unreachable.
- **Admin port 6060**: Never expose to the internet — it's the privileged management API.
- **App store needs internet**: Installing apps requires the server to reach the Cozy registry. Offline-only installs cannot install new apps.
- **Storage grows significantly**: Files, photos, and email backups can accumulate — plan storage accordingly.
- **cozy.yaml config**: The configuration file drives all runtime behaviour — document changes carefully and back up before upgrades.

## Links

- cozy-stack source: https://github.com/cozy/cozy-stack
- Self-hosting guide: https://docs.cozy.io/en/tutorials/selfhosting/
- Full documentation: https://docs.cozy.io/en/cozy-stack/
- App store (Cozy registry): https://store.cozy.io/
- Website: https://cozy.io/
