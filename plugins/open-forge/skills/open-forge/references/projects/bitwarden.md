---
name: Bitwarden (self-hosted)
description: Official self-hosted Bitwarden password manager server — C#/.NET + SQL Server, deployed via the `bitwarden.sh` installer script that provisions a 10-container stack.
---

# Bitwarden (self-hosted)

Bitwarden is a password/secrets manager. The **official** self-host path is a shell-script installer that generates + manages a Docker Compose stack of roughly ten services (API, Identity, Admin, Web, Icons, Notifications, Events, MSSQL, Nginx, Attachments). License keys are free for personal use but an "organization" license (also free for Families) is required to create groups.

- Upstream repo: <https://github.com/bitwarden/server>
- Install docs: <https://bitwarden.com/help/install-on-premise-linux/>
- Images: <https://github.com/orgs/bitwarden/packages> (GHCR)

**Considering Vaultwarden instead?** A separate, unofficial, Rust-rewrite called Vaultwarden (<https://github.com/dani-garcia/vaultwarden>) is far lighter (single container, SQLite/MySQL/Postgres) and compatible with all Bitwarden clients. It is the community default for single-user / small-team self-hosts. Recipe this one for Vaultwarden: see its own project file. This recipe covers **official** Bitwarden.

## Architecture in one minute

The `bitwarden.sh` installer creates `./bwdata/` with a generated `docker-compose.yml` that runs ~10 services:

- `nginx` — TLS-terminating front door (80/443)
- `web` — static SPA
- `api`, `identity`, `admin`, `events`, `icons`, `notifications`, `attachments` — C# ASP.NET Core microservices
- `mssql` — SQL Server 2022 (Express edition)

Total RAM footprint: **~3–4 GB idle**, mostly SQL Server.

## Compatible install methods

| Infra              | Runtime                              | Notes                                                                      |
| ------------------ | ------------------------------------ | -------------------------------------------------------------------------- |
| Single VM (4+ GB RAM) | Docker + `bitwarden.sh` installer | **The only officially supported path.**                                    |
| Kubernetes         | Helm chart                           | Official chart at <https://github.com/bitwarden/self-host/tree/main/helm>  |
| Windows host       | `bitwarden.ps1` installer            | Same stack, PowerShell wrapper                                             |
| ARM (Raspberry Pi) | Not supported                        | SQL Server image is amd64-only. Use Vaultwarden on ARM.                    |

## Inputs to collect

| Input                     | Example                                          | Phase     | Notes                                                                 |
| ------------------------- | ------------------------------------------------ | --------- | --------------------------------------------------------------------- |
| Public FQDN               | `vault.example.com`                              | DNS       | Must have valid TLS — Bitwarden clients refuse self-signed            |
| Installation ID + Key     | generated at <https://bitwarden.com/host/>        | Install   | **Free, required.** Used to tie your install to license lookups       |
| Admin email               | `admin@example.com`                              | Install   | Gets password reset + admin portal access                             |
| Database password         | auto-generated                                   | Install   | Stored in `./bwdata/env/mssql.override.env`                           |
| SMTP config               | any provider                                     | Runtime   | Required for invites + password reset; set in `./bwdata/env/global.override.env` |
| Open TCP 80 + 443         | firewall                                         | Network   | 80 for HTTP→HTTPS redirect + Let's Encrypt challenge (optional)       |
| amd64 host                | `uname -m`                                       | Host      | SQL Server image has no arm64 build                                   |
| 6 GB+ RAM                 | `free -h`                                        | Host      | SQL Server will OOM on 2 GB VMs                                       |

## Install via the official installer (recommended)

Per <https://bitwarden.com/help/install-on-premise-linux/>:

```sh
# 1. Install Docker and Docker Compose v2 on the host.
# 2. Pre-create a 'bitwarden' user and add them to the docker group:
sudo adduser --system --group --home /opt/bitwarden bitwarden
sudo usermod -aG docker bitwarden

# 3. As the bitwarden user, download the installer:
cd /opt/bitwarden
curl -Lso bitwarden.sh \
  "https://func.bitwarden.com/api/dl/?app=self-host&platform=linux" \
  && chmod +x bitwarden.sh

# 4. Get a free installation ID + key at https://bitwarden.com/host/
# 5. Run the installer (it prompts for domain, email, IDs):
./bitwarden.sh install

# 6. Edit ./bwdata/env/global.override.env — set SMTP, real admin email:
#    globalSettings__mail__smtp__host=...
#    globalSettings__mail__smtp__port=587
#    globalSettings__mail__smtp__ssl=true
#    globalSettings__mail__smtp__username=...
#    globalSettings__mail__smtp__password=...
#    adminSettings__admins=admin@example.com

# 7. Restart to pick up env changes:
./bitwarden.sh restart
```

The installer fetches Let's Encrypt certs on-host (unless you pass `letsencrypt n` and supply your own cert files). First boot takes 5–10 minutes while SQL Server initializes and migrations run.

Browse `https://vault.example.com`, register the first account, log in, visit `/admin` to access the admin portal (email-link login to `adminSettings__admins`).

## Install via Helm (Kubernetes)

```sh
helm repo add bitwarden https://charts.bitwarden.com/
helm repo update

# Create a values.yaml per the chart README; then:
helm install bitwarden bitwarden/self-host -n bitwarden --create-namespace -f values.yaml
```

See <https://github.com/bitwarden/self-host/blob/main/helm/README.md> for required values (installation ID, cert config, storage class, SMTP).

## Data & config layout

- `./bwdata/` — the single state dir the installer manages:
  - `docker-compose.yml` — generated; **re-generated on every `bitwarden.sh update`**
  - `env/global.override.env` — user-editable global config (SMTP, admins, identity URL, feature flags)
  - `env/mssql.override.env` — generated SQL Server config
  - `scripts/` — auxiliary installer scripts
  - `mssql/` — SQL Server data dir
  - `attachments/`, `sends/` — per-tenant user uploads
  - `logs/` — each service logs to its own subdir

## Backup

```sh
# Stop
./bitwarden.sh stop

# Snapshot the entire state dir
sudo tar czf /backups/bwdata-$(date +%F).tgz -C /opt/bitwarden bwdata

# Restart
./bitwarden.sh start
```

For live backups, the installer ships `./bwdata/scripts/backup-db.sh` — it calls `sqlcmd` inside the mssql container to produce a `.bak` file. Combine with a file-system snapshot of `./bwdata/attachments/` and `./bwdata/sends/`.

## Upgrade

1. Releases: <https://github.com/bitwarden/server/releases>
2. As the `bitwarden` user:
   ```sh
   ./bitwarden.sh updateself    # updates the installer script
   ./bitwarden.sh update        # pulls new images + applies migrations
   ```
3. The installer regenerates `docker-compose.yml` and runs DB migrations automatically. Watch output; SQL Server migrations can take several minutes.

## Gotchas

- **SQL Server is amd64-only.** The official stack does not run on arm64 / Raspberry Pi. Use Vaultwarden instead for ARM.
- **RAM-hungry.** SQL Server Express alone wants 2+ GB. Plan for a 4 GB minimum host.
- **`bitwarden.sh update` regenerates `docker-compose.yml`.** All your hand-edits get overwritten. Persistent customization belongs in `./bwdata/env/*.override.env`, not in the compose file.
- **Installation ID + Key are mandatory** (but free). You cannot complete install without them; get them at <https://bitwarden.com/host/>.
- **License-gated features.** Organizations (shared vaults, groups, enterprise SSO, directory sync) require uploading a free Families organization license or a paid Teams/Enterprise license. No license = no shared vaults.
- **Client apps refuse self-signed certs.** You must either use Let's Encrypt (installer default) or a cert from a CA that clients trust.
- **Admin portal email link goes to `adminSettings__admins`** — one entry per line, no space separation. Wrong format = no admin access.
- **Port 80 required during LE renewal** even if you terminate TLS elsewhere — the installer's nginx handles both.
- **Free personal use is not restricted**; there's no "disable paid features" switch. Attempting to create an Organization beyond the free Families tier prompts for a license upload.
- **SQL Server log file can balloon.** Set up `scripts/backup-db.sh` + regular backups, which truncate the log.
- **SQL Server 2022 changed default collation** for new installs — this is fine for new installs but can bite during restores from a 2019 backup.
- **Don't run side-by-side with Vaultwarden on the same domain.** They use the same API paths; clients will behave unpredictably.
- **Directory sync is a separate tool** (`bwdc`) that runs outside the stack. Not included in the Docker deploy.
- **Version skew**: the installer pins a single image version to all services; don't try to upgrade them independently.

## Links

- Install docs: <https://bitwarden.com/help/install-on-premise-linux/>
- Self-host repo (scripts + Helm chart): <https://github.com/bitwarden/self-host>
- Server repo: <https://github.com/bitwarden/server>
- Free install ID: <https://bitwarden.com/host/>
- Docs: <https://bitwarden.com/help/self-hosting/>
- Releases: <https://github.com/bitwarden/server/releases>
- Vaultwarden (lightweight alternative): <https://github.com/dani-garcia/vaultwarden>
