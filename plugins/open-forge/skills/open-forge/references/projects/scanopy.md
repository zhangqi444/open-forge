---
name: Scanopy
description: "Network documentation via continuous auto-discovery — scans on schedule, produces L2/L3/workloads/applications views that reflect current infrastructure state. Replaces stale draw.io diagrams. Server + Daemon. AGPL-3.0 (Community) / Commercial / Cloud."
---

# Scanopy

Scanopy is **"stop drawing network diagrams; let your infrastructure document itself."** A daemon scans your network on a schedule and produces **four always-current views** from each scan: **L2 (physical — switches/ports/links)**, **L3 (logical — subnets/VLANs/routing)**, **Workloads (bare metal/hypervisors/containers)**, **Applications (services + dependencies)**. Exports to SVG/Mermaid/Confluence; embeddable live maps; feeds into your existing source of truth.

**Positioning**: 
- Unlike static draw.io diagrams (go stale the week saved)
- Unlike IaC state (misses drift + out-of-band resources)  
- Scanopy reflects ACTUAL current state from live scans

Previously named **NetVisor** — legacy image names (`mayanayza/netvisor-server`) still in use during transition.

Features:

- **Automatic discovery** — maps hosts + services via SNMP, LLDP, ARP, Docker, etc.
- **230+ service definitions** — auto-detects DBs, web servers, containers, network gear, enterprise apps
- **Four views from one scan** — L2/L3/workloads/apps
- **Distributed scanning** — deploy daemons across segments for multi-site/multi-VLAN
- **Docker + SNMP native discovery**
- **Scheduled rescans** — docs stay current
- **Multi-user + RBAC** — organizations, roles, shareable live views
- **Export** — SVG, Mermaid, Confluence
- **Embeddable live maps**
- **i18n via Weblate**

Target audiences (per upstream):
- Platform/DevOps teams mapping service dependencies
- Network engineers documenting multi-VLAN/multi-site topologies
- IT operations keeping inventory + topology + deps current
- MSPs providing per-client documentation
- Home labs avoiding manual draw.io

- Upstream repo: <https://github.com/scanopy/scanopy>
- Homepage: <https://scanopy.net>
- Docker Hub (daemon): <https://hub.docker.com/r/mayanayza/scanopy-daemon>
- Docker Hub (server): <https://hub.docker.com/r/mayanayza/scanopy-server>
- Proxmox helper script: <https://community-scripts.github.io/ProxmoxVE/scripts?id=scanopy>
- Discord: <https://discord.gg/b7ffQr8AcZ>
- Weblate translations: <https://hosted.weblate.org/engage/scanopy/>
- Commercial cloud: <https://scanopy.net>

## Architecture in one minute

- **Server** — web UI + DB + API (stores discovered model)
- **Daemon(s)** — perform scans; deploy one per network segment
- **Distributed design** — multiple daemons feeding one server for multi-site
- **Scanning protocols**: SNMP (network gear), LLDP/CDP (L2 topology), ARP (L2/L3 mapping), Docker API (containers), service fingerprinting (apps)
- **No agents on endpoints** — daemon scans remotely
- **Resource**: server small; daemon modest (scan-time CPU bursts)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / Docker | **Docker Compose** (server + daemon)                               | **Upstream-recommended**                                                           |
| Proxmox LXC        | **Community helper script** auto-creates LXC                                  | Proxmox-friendly                                                                             |
| Unraid             | Available via Community Apps (check)                                                     | Homelab-friendly                                                                                     |
| Kubernetes         | Community manifests                                                                           | Works                                                                                                   |
| Distributed        | Multi-site: one server, daemon per segment                                                              | For large orgs                                                                                                          |
| Managed cloud      | **Scanopy Cloud** — free trial + paid tiers                                                                | Commercial                                                                                                              |

## Inputs to collect

| Input                   | Example                                             | Phase        | Notes                                                                       |
| ----------------------- | --------------------------------------------------- | ------------ | --------------------------------------------------------------------------- |
| Domain                  | `scanopy.home.lan`                                      | URL          | TLS via reverse proxy                                                               |
| Daemon placement        | One per subnet/VLAN/site                                      | Topology     | Critical for completeness                                                                      |
| Scan credentials        | SNMP community/SNMPv3, Docker API read, etc.                          | Secrets      | **SNMPv3 preferred over v2c**                                                                       |
| Subnets to scan         | CIDRs per site                                                      | Scope        | Explicit list; avoid scanning unauthorized networks                                                                              |
| Admin                   | first-run creates                                                              | Bootstrap    | Strong password + MFA if available                                                                                          |
| Confluence / other export dest | API tokens                                                              | Integration  | Optional                                                                                                                             |

## Install via Docker Compose

```sh
curl -O https://raw.githubusercontent.com/scanopy/scanopy/refs/heads/main/docker-compose.yml
docker compose up -d
```

This brings up server + daemon on the same host. For multi-site, deploy additional daemons on remote hosts + point at central server.

## First boot

1. Browse → first-run wizard → create admin
2. Configure first daemon → target subnets + scan schedule
3. Provide SNMP community/user (read-only)
4. Run initial scan → verify L2/L3/workloads/apps views populate
5. Drill down — inspect discovered services; tweak service definitions if needed
6. Export test: SVG / Mermaid / Confluence → verify round-trip
7. Deploy additional daemons for other network segments
8. Schedule recurring scans (e.g., nightly)
9. Put behind TLS reverse proxy + lock down admin access

## Data & config layout

- Server DB — model of discovered infrastructure, history, users, RBAC
- Daemon state — minimal; mostly scan queue
- Scan artifacts — stored in server DB
- Credentials for scanning — in daemon config (SNMP communities, Docker API access)

## Backup

```sh
# Scanopy server DB + config
sudo tar czf scanopy-$(date +%F).tgz server-data/
```

Scan credentials are most sensitive element. Encrypt backups.

## Upgrade

1. Releases: <https://github.com/scanopy/scanopy/releases>. Active.
2. Server + daemon can often upgrade independently; generally keep same major version.
3. **Back up before upgrade.**
4. **Legacy image names** (`mayanayza/netvisor-server`, `mayanayza/scanopy-daemon`) — watch README for current image locations as rebrand from NetVisor completes.

## Gotchas

- **SCANNING NETWORKS YOU DON'T OWN IS UNAUTHORIZED ACCESS** in most jurisdictions (US CFAA, UK CMA, EU equivalents, etc.) — criminal statute. Scope Scanopy ONLY to networks YOU own or have written permission to scan. At work, get explicit signoff from security/legal before deploying in production networks.
- **SNMPv3 > SNMPv2c**: v2c uses cleartext community strings (literally a password on the wire). v3 adds auth + privacy. Scan your own gear with v3 if supported. Never scan external networks with v2c over internet.
- **Community strings = credentials**: `public` / `private` defaults are famous CVE-adjacent. Change them; rotate; use v3; restrict via SNMP ACLs on devices.
- **Daemon has read credentials for your infrastructure.** Compromise of daemon = attacker can enumerate your topology + find soft targets. Secure daemon host (same OS hygiene as production). Isolate via ACLs.
- **Discovery accuracy depends on protocol support**: not all network gear supports LLDP; not all Linux boxes expose full SNMP. Expect gaps; fill via manual annotations where Scanopy supports it.
- **Rebrand-in-progress**: NetVisor → Scanopy rename ongoing. Legacy image names (`mayanayza/netvisor-*`, `mayanayza/scanopy-*`) co-exist with new. Check current README for canonical names at time of install.
- **AGPL-3.0 community vs Commercial vs Cloud**:
  - **AGPL**: free for all use + **source disclosure required for network services** (typical AGPL obligation)
  - **Commercial license**: for orgs that can't comply with AGPL (proprietary use) — contact licensing@scanopy.net
  - **Scanopy Cloud**: SaaS; zero self-host
  - Be honest with your org's license compliance capacity before choosing AGPL.
- **Distributed scanning security**: each daemon reports back to server. Auth + TLS between daemon ↔ server critical. Don't expose daemon or server endpoints on untrusted networks without isolation.
- **Export as Mermaid**: great for embedding in Markdown docs + wikis. Stays git-versionable. Pair with silverbullet (batch 73) or any Markdown system.
- **Confluence export**: for orgs standardizing on Confluence wikis, automated network docs = legitimately valuable.
- **Home lab value**: massive. Document your homelab without opening draw.io. Enterprise-grade tool for $0.
- **Commercial competitors**: NetBox (+PyNetBox) for IPAM/DCIM/documentation is the enterprise-standard but manual data entry. Scanopy = auto-discovery feeds NetBox or stands alone.
- **Not a replacement for observability** (Prometheus/Grafana): Scanopy documents structure; observability tools report performance. Complementary.
- **Not APM** (Datadog/New Relic): application-level tracing is different use-case.
- **License**: **AGPL-3.0** (Community) + **Commercial** option + **Cloud**.
- **Project governance**: commercial company (contact licensing@scanopy.net); active + growing; Weblate-localized; Discord-active. Professional team behind.
- **Alternatives worth knowing:**
  - **NetBox** — IPAM/DCIM source-of-truth; industry-standard; manual data entry
  - **Nautobot** — NetBox fork; more extensible
  - **LibreNMS** — network-monitoring + auto-discovery; different focus (performance vs documentation)
  - **Observium** — commercial; similar to LibreNMS
  - **CloudBolt Cruiser** — commercial cloud asset discovery
  - **draw.io** (batch 74) — manual diagramming (what Scanopy replaces)
  - **Choose Scanopy if:** you want auto-discovered, always-current network docs + L2/L3/workload/app views.
  - **Choose NetBox if:** you want IPAM + DCIM with manual governance model.
  - **Choose LibreNMS if:** performance monitoring primary; docs secondary.

## Links

- Repo: <https://github.com/scanopy/scanopy>
- Homepage: <https://scanopy.net>
- Daemon image: <https://hub.docker.com/r/mayanayza/scanopy-daemon>
- Server image: <https://hub.docker.com/r/mayanayza/scanopy-server>
- Proxmox helper: <https://community-scripts.github.io/ProxmoxVE/scripts?id=scanopy>
- Discord: <https://discord.gg/b7ffQr8AcZ>
- Weblate (translations): <https://hosted.weblate.org/engage/scanopy/>
- Releases: <https://github.com/scanopy/scanopy/releases>
- Commercial cloud trial: <https://scanopy.net>
- Licensing contact: `licensing@scanopy.net`
- NetBox (alt): <https://netboxlabs.com/oss/netbox/>
- Nautobot (alt): <https://www.nautobot.com>
- LibreNMS (alt): <https://www.librenms.org>
- draw.io (batch 74, manual alt): <https://github.com/jgraph/drawio>
