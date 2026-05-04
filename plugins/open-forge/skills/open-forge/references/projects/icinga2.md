---
name: icinga2
description: Icinga 2 recipe for open-forge. Open-source monitoring system for network resources, service availability, and performance data. Requires Icinga Web 2 for the UI.
---

# Icinga 2

Open-source monitoring system that checks availability of network resources, notifies on outages, and generates performance data. Scalable across multiple locations. Requires [Icinga Web 2](https://icinga.com/products/) for the web interface. Upstream: <https://github.com/Icinga/icinga2>. Docs: <https://icinga.com/docs/icinga2/latest/>.

> **Note:** Icinga 2 (monitoring engine) and Icinga Web 2 (UI) are separate components. A full stack also includes a database backend (MySQL/PostgreSQL via IDO module) and optionally Icinga Director for config management.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (jordanopensource image) | Quickest containerized setup |
| Debian/Ubuntu package (`apt`) | Official recommended production install |
| RHEL/CentOS package (`dnf`) | Official recommended production install |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Database type: MySQL or PostgreSQL?" | For IDO (Icinga Data Output) module |
| preflight | "Database password for Icinga IDO?" | |
| preflight | "Icinga Web 2 admin password?" | |
| preflight | "Domain for Icinga Web?" | For reverse-proxy TLS |

## Package install (Debian/Ubuntu)

Upstream docs: <https://icinga.com/docs/icinga2/latest/doc/02-installation/>

```bash
# Add Icinga repo
apt install -y curl gnupg
curl -fsSL https://packages.icinga.com/icinga.key | gpg --dearmor -o /usr/share/keyrings/icinga-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-$(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/icinga.list
apt update

# Install Icinga 2 + IDO MySQL + Icinga Web 2
apt install -y icinga2 icingacli icingaweb2 mariadb-server icinga2-ido-mysql

# Enable IDO module
icinga2 feature enable ido-mysql

# Setup wizard
icingacli setup wizard
```

## Software-layer concerns

- Icinga 2 daemon: `/usr/sbin/icinga2`, managed via systemd
- Config dir: `/etc/icinga2/` — main config, zones, hosts, services
- IDO module writes check results to MySQL/PostgreSQL; required for Icinga Web 2
- API port: `5665` (Icinga 2 cluster + REST API)
- Icinga Web 2 served via Apache/NGINX on port `80`/`443`
- Icinga Director: optional module for database-driven config management (GUI-based); recommended for large environments

## Monitoring basics

- Hosts defined in `/etc/icinga2/conf.d/hosts/` or via Icinga Director
- Services inherit from service templates; common checks: `ping`, `http`, `ssh`, `disk`, `load`
- Notifications: email, Slack, PagerDuty via notification scripts in `/etc/icinga2/scripts/`

## Upgrade procedure

1. `apt update && apt upgrade icinga2 icingaweb2`
2. Check changelog for IDO schema migrations: `icinga2 feature list`
3. Run `icingacli setup config directory --group www-data` if web config dir permissions change

## Gotchas

- **Two-component stack**: Icinga 2 alone gives no UI — you must also install Icinga Web 2
- IDO module is required for Icinga Web 2 to display history and reporting
- Port `5665` must be open between Icinga master and satellite/agent nodes in distributed setups
- No official first-party Docker image from Icinga; community images exist but lag releases
- Icinga Director requires its own DB schema and a background daemon (`icingacli director daemon`)

## Links

- GitHub (Icinga 2): <https://github.com/Icinga/icinga2>
- GitHub (Icinga Web 2): <https://github.com/Icinga/icingaweb2>
- Installation docs: <https://icinga.com/docs/icinga2/latest/doc/02-installation/>
- Full docs: <https://icinga.com/docs/icinga2/latest/>
