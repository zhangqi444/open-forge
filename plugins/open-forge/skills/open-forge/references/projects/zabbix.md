---
name: Zabbix
description: "Enterprise-class, open-source distributed monitoring solution — servers, network devices, services, cloud infra, containers, databases, APIs. Agent + agentless. Real-time problem detection, correlation, root-cause analysis, alerts, dashboards, SLAs. C + PHP + Postgres/MySQL. AGPL-3.0."
---

# Zabbix

Zabbix is **the enterprise-class open-source monitoring solution** — a direct competitor to Nagios/Icinga/SolarWinds/Datadog/New Relic/PRTG in the "monitor all the things" space. Monitors network devices, servers, services, VMs, containers, cloud services, databases, APIs, Java ecosystems, webpages, business apps. Used by thousands of organizations including governments, telcos, banks, and enterprise IT departments globally.

Not the newest kid on the block (founded **2001**); fully AGPL-3.0; **commercial support** available from Zabbix SIA; highly optimized for large-scale distributed monitoring.

Key capabilities:

- **Resource discovery** — auto-find network devices, server resources, onboard/offboard automatically
- **Metric acquisition** — agent-based or agent-less (SNMP, IPMI, JMX, ODBC, SSH, Telnet, HTTP, HTTP/2, API polling)
- **Templates** — 1000+ built-in templates for common targets (Linux, Windows, Cisco, Juniper, F5, MySQL, Postgres, Apache, Nginx, VMware, Kubernetes, Docker, AWS, Azure, Oracle, SAP, etc.)
- **Root cause analysis** — correlates multiple alerts, identifies the root
- **Real-time problem detection** — configurable severity (Not Classified / Information / Warning / Average / High / Disaster)
- **Incident handling** — alerts via email, SMS, Slack, Teams, JIRA, PagerDuty, Telegram, Webex, Discord, custom scripts, and more
- **Dashboards** — graphs, lists, geomaps, network topology maps, SLA reports
- **Multi-tenancy + distributed** — Zabbix proxies monitor remote sites/datacenters behind firewalls; central Zabbix server aggregates
- **SLA calculation** — service SLAs computed from host problem state
- **Metric streaming** — stream to HTTP endpoints (Kafka, ELK, others)
- **User scripts + auto-remediation** — respond to alerts automatically (restart service, rotate log, etc.)
- **Auditing** — full audit log of admin actions
- **SAML / LDAP / SSO**
- **API** (JSON-RPC)

- Upstream repo: <https://github.com/zabbix/zabbix>
- Website: <https://www.zabbix.com>
- Docs: <https://www.zabbix.com/documentation/current/en/>
- Download: <https://www.zabbix.com/download>
- Templates: <https://www.zabbix.com/integrations>
- Community forum: <https://www.zabbix.com/forum>
- Zabbix SIA (commercial): <https://www.zabbix.com/services>

## Architecture in one minute

- **Zabbix Server** — C daemon; the brains; collects + correlates + alerts
- **Zabbix Proxy** (optional) — distributed polling (monitor remote sites, reduce load on central server)
- **Zabbix Agent** (optional) — C daemon on monitored host (low overhead); also agent-less monitoring via SNMP/IPMI/HTTP
- **Web UI** — PHP + Apache/Nginx
- **Database** — PostgreSQL / MySQL / MariaDB / Oracle; TimescaleDB recommended for large-scale time-series
- **Resource**: small deployments (100 hosts) ~4 GB RAM + 2 cores; large (10k+ hosts) needs tuning, TimescaleDB, + proxies

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                         |
| ------------------ | --------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **Official deb/rpm packages**                                       | **Upstream-recommended for production**                                           |
| Single VM          | **Docker Compose** (multiple official images)                                | Fine for small deployments                                                                   |
| Cluster            | Server + multiple Proxies + shared DB                                                         | Production HA pattern                                                                                        |
| Kubernetes         | Community Helm charts + official images                                                                    | Works; not yet idiomatic                                                                                                  |
| Raspberry Pi       | Agent only is great; Server marginal                                                                                 | Use agent on Pi to monitor Pi                                                                                                       |
| Cloud              | AWS/Azure/GCP images in marketplace                                                                                                | Supported                                                                                                                                      |
| Managed            | **Zabbix Cloud** (SaaS, commercial)                                                                                                           | Paid option                                                                                                                                                 |

## Inputs to collect

| Input                | Example                                | Phase       | Notes                                                                         |
| -------------------- | -------------------------------------- | ----------- | ----------------------------------------------------------------------------- |
| Server DB            | Postgres with TimescaleDB                       | DB          | MySQL works; Postgres+Timescale is Zabbix's preferred for scale                        |
| Server listen port   | `10051`                                                | Network     | Proxies + agents push/pull here                                                                     |
| Web UI URL           | `https://zabbix.example.com`                                   | URL         | Apache/Nginx + PHP-FPM                                                                                      |
| Admin                | `Admin` / `zabbix` default → change immediately                         | Bootstrap   | **Default creds are widely known**                                                                                      |
| SMTP / Slack / PD    | per notification channel                                                | Alerting    | Configure before putting into production                                                                                                |
| Active agent hosts   | install Zabbix agent on each                                                         | Monitoring  | Or use agent-less (SNMP etc.)                                                                                                                                |
| Proxy (remote sites) | per-site Zabbix proxy                                                                                | Scale       | For multi-site                                                                                                                                          |
| TLS                  | PSK or cert-based                                                                                               | Security    | Agent↔Server encrypted traffic (not default — enable)                                                                                                                            |

## Install via Docker Compose

Zabbix publishes official multi-container images. Simplified:

```yaml
services:
  zabbix-db:
    image: postgres:16
    environment:
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_DB: zabbix
    volumes:
      - ./pg:/var/lib/postgresql/data
  zabbix-server:
    image: zabbix/zabbix-server-pgsql:alpine-7.4-latest     # pin to exact version in prod
    environment:
      DB_SERVER_HOST: zabbix-db
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_DB: zabbix
    ports:
      - "10051:10051"
    depends_on:
      - zabbix-db
  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql:alpine-7.4-latest
    environment:
      DB_SERVER_HOST: zabbix-db
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_DB: zabbix
      ZBX_SERVER_HOST: zabbix-server
      PHP_TZ: America/Los_Angeles
    ports:
      - "8080:8080"
    depends_on:
      - zabbix-server
```

Put Nginx/Caddy in front for TLS. Browse `https://zabbix.example.com/`.

## First boot

1. Log in as `Admin` / `zabbix` → **change password immediately**
2. **Configuration → Hosts → Create host** — add your first target
3. Assign a **Template** (e.g., "Linux by Zabbix agent") → auto-populates items + triggers
4. Install Zabbix agent on target host (`apt install zabbix-agent2`; configure `Server=<zabbix-host>`)
5. Verify data flowing in (Monitoring → Latest data)
6. **Media types** → configure Slack / email / PagerDuty
7. **Actions** → route alerts to the right people based on severity/host
8. **Dashboards** → build your "single pane of glass"

## Data & config layout

- `/var/lib/zabbix/` — server state (limited)
- `/etc/zabbix/` — config files (`zabbix_server.conf`, `zabbix_agentd.conf`, etc.)
- Database — **all** historical metrics + config + alerts + audit
- `/usr/share/zabbix/` — PHP web files

## Backup

```sh
# Postgres dump (CRITICAL — all metrics, config, audit)
pg_dump -U zabbix zabbix | gzip > zabbix-db-$(date +%F).sql.gz
# Config
sudo tar czf zabbix-conf-$(date +%F).tgz /etc/zabbix/
```

**Historical metrics can be enormous** (10+ TB for large deployments). Partitioning via TimescaleDB is standard + tiered retention (hot / warm / cold).

## Upgrade

1. Releases: <https://github.com/zabbix/zabbix/releases>. LTS (6.0, 7.0 LTS) + non-LTS (6.2, 6.4).
2. **Stay on LTS** for production.
3. Database schema migrations on major upgrades — **test on staging**.
4. Rolling upgrade: Server → Web → Proxies → Agents (agents backward-compat with older servers).
5. **Back up DB + config** before every upgrade.

## Gotchas

- **Default creds (`Admin`/`zabbix`)** — change IMMEDIATELY. They're widely published, scanner-bots try them everywhere.
- **Enable agent↔server encryption** (PSK or cert). By default, agent-server traffic is **plaintext** on :10051 — an attacker on the network can sniff or inject metrics.
- **Database sizing**: raw-history retention default is 90 days; trends 365 days. On large deployments this grows fast. Plan TimescaleDB + housekeeper tuning + partitioning.
- **TimescaleDB**: strongly recommended for Postgres-backed large deployments. Enables chunking + compression + drop-chunk retention policies. Install the extension + configure in Zabbix.
- **Housekeeper lag**: Zabbix's background housekeeper can fall behind on busy DBs → DB bloats → queries slow → alerts lag. Monitor housekeeper stats; partition tables.
- **Proxies for remote sites**: `Zabbix Proxy` polls locally + queues + forwards to server. Essential for firewalled / WAN-disconnected branches. Choose Active vs Passive proxy mode carefully.
- **Template complexity**: templates include items + triggers + macros + discovery rules. Simple hosts import easily; complex ones may over-collect — tune retention thresholds.
- **Low-level discovery (LLD)** dynamically creates items (per-interface, per-partition, per-container). Powerful but can explode metric counts — set filter rules.
- **Map templates (network topology)**: manual curation; no auto-draw for arbitrary topologies. Large network maps require planning.
- **Notification noise**: default templates fire on many minor triggers. **Tune thresholds for your environment** before going live; otherwise alert fatigue sets in within a week.
- **Multi-tenancy**: via user groups + host groups + permissions. Not true multi-tenancy (shared DB), but workable for MSPs.
- **Maintenance windows**: schedule to suppress alerts during planned work.
- **Triggers have dependencies**: parent trigger "network down" suppresses child triggers "service down on host" — avoids alert storms.
- **API (JSON-RPC)** — extensive; use for automation (provisioning hosts, bulk ops).
- **Performance at scale**: tuning guide is essential >1k hosts. Poller threads, DB vacuum, value cache, etc.
- **Backwards compat**: Zabbix servers accept metrics from older agents (usually one major version back). Agents don't accept from older servers.
- **License**: **AGPL-3.0**.
- **Commercial support**: Zabbix SIA (Latvia-based) sells support + training + consulting + Zabbix Cloud hosting. Recommended for mission-critical.
- **Agent 2 vs classic agent**: Agent 2 is newer, better for plugins + Docker/K8s monitoring. Classic agent is lighter for constrained devices.
- **Active vs Passive agent**: Active = agent pushes (better for firewalled hosts); Passive = server polls (better for simpler setups).
- **Alternatives worth knowing:**
  - **Prometheus + Grafana + Alertmanager** — modern cloud-native monitoring; pull model; time-series DB (separate recipe likely)
  - **Nagios Core / Nagios XI** — classic; Zabbix is generally considered more modern
  - **Icinga 2** — Nagios fork; modernized
  - **Checkmk** — enterprise monitoring; community + raw + enterprise editions; Nagios roots
  - **LibreNMS** — network-focused SNMP monitoring (separate recipe)
  - **Observium** — network monitoring; free community + paid
  - **Datadog / New Relic / Splunk** — commercial SaaS
  - **Dynatrace / AppDynamics** — commercial APM-focused
  - **Netdata** — lightweight real-time monitoring (separate recipe likely)
  - **Choose Zabbix if:** enterprise-scale multi-site + deep templates + AGPL; proven at massive scale.
  - **Choose Prometheus/Grafana if:** cloud-native + container-centric + time-series-first.
  - **Choose Checkmk if:** you want a more polished UI + commercial option with Nagios roots.
  - **Choose LibreNMS/Observium if:** network-device-focused.
  - **Choose Datadog/New Relic if:** commercial SaaS + modern APM.

## Links

- Repo: <https://github.com/zabbix/zabbix>
- Website: <https://www.zabbix.com>
- Docs: <https://www.zabbix.com/documentation/current/en/>
- Installation: <https://www.zabbix.com/documentation/current/en/manual/installation>
- Download: <https://www.zabbix.com/download>
- Templates / integrations: <https://www.zabbix.com/integrations>
- Docker images: <https://hub.docker.com/u/zabbix>
- Community forum: <https://www.zabbix.com/forum>
- Commercial services: <https://www.zabbix.com/services>
- Zabbix Cloud: <https://www.zabbix.com/zabbix_cloud>
- TimescaleDB (for Zabbix): <https://www.timescale.com/blog/monitoring-zabbix-on-timescaledb/>
- Prometheus (alt): <https://prometheus.io>
- Checkmk (alt): <https://checkmk.com>
- LibreNMS (alt): <https://www.librenms.org>
- Icinga (alt): <https://icinga.com>
