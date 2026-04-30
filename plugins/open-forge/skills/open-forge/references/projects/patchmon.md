---
name: PatchMon
description: "Enterprise-grade Linux patch + server-mgmt platform. Outbound-only agents (no inbound firewall). Single Go binary with embedded React UI. Multi-OS (Linux apt/dnf/yum/apk/pacman + FreeBSD pkg + Windows). AGPL-v3. AI-DECLARATION badge (assist level). Patchmon org + commercial cloud."
---

# PatchMon

PatchMon is **"Pulseway / ManageEngine Patch Manager / Landscape — but OSS + AGPL + outbound-only agents + single-binary"** — enterprise-grade patch + server management for Linux fleet (also FreeBSD + Windows agent support). **Outbound-only agents** (no inbound firewall changes, no SSH/WinRM exposure, no VPN required). **Single binary** — Go + embedded React UI in one container (no Node runtime at deploy time). **AGPL v3** self-host + commercial managed cloud at patchmon.net/cloud.

Built + maintained by **PatchMon org** + Discord + commercial cloud. License: **AGPL-3.0**. Active; public roadmap; docs; **AI-DECLARATION: assist badge** (transparent about AI-assisted code contributions!).

Use cases: (a) **Linux-fleet patch-compliance** — CVE scanning + update-status (b) **SOC2/ISO compliance** — patch-management-evidence (c) **NAT'd/isolated hosts** — outbound-only agents work behind firewall (d) **heterogeneous OS fleet** — one tool for apt/dnf/yum/apk/pacman/pkg/Windows (e) **auditing-pkg-versions** across fleet (f) **enterprise-grade OSS alternative** to commercial patch-mgmt (g) **Landscape-replacement for Ubuntu enterprise** (h) **lightweight agent** — no heavy daemons.

Features (per README):

- **Outbound-only agents** (NAT + firewall-friendly)
- **Multi-OS**: Linux (apt/dnf/yum/apk/pacman) + FreeBSD (pkg) + Windows
- **Single binary** (Go + embedded React)
- **One container** deployment (no Node at deploy)
- **Real-time visibility** — package health, compliance, system status
- **AGPL-3.0 OSS + commercial cloud**
- **Discord + docs + roadmap**

- Upstream repo: <https://github.com/PatchMon/PatchMon>
- Website: <https://patchmon.net>
- Commercial Cloud: <https://patchmon.net/cloud>
- Docs: <https://patchmon.net/docs>
- Discord: <https://patchmon.net/discord>
- AI-DECLARATION: <https://github.com/PatchMon/PatchMon/blob/main/AI-DECLARATION.md>

## Architecture in one minute

- **Go** server (single binary with embedded React UI)
- **PostgreSQL** DB
- **Agents**: small, outbound-only, connect via HTTPS
- **Resource**: low — 100-300MB RAM server; agents <10MB RAM
- **Port**: server web UI + agent ingest

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary server**                                                                        |
| **Binary**         | Go binary                                                                            | Alt server                                                                                   |
| **PatchMon Cloud** | Commercial hosted                                                                                                     | Pay                                                                                   |
| **Agent (per-host)** | Binary install on monitored Linux/BSD/Windows hosts                                                                 | REQUIRED per host                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Server domain        | `patchmon.example.com`                                      | URL          | TLS MANDATORY — agents rely on it                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| **Agent tokens**     | Per-host enrollment                                         | **CRITICAL** | **Compromise = fake-agent data-injection**                                                                                    |
| Notification channels | Email / Slack / webhook                                                                                               | Notifications |                                                                                    |
| Fleet list           | Hosts to enroll                                                                                                        | Config       |                                                                                    |

## Install via Docker

Follow: <https://patchmon.net/docs>

```yaml
services:
  patchmon:
    image: ghcr.io/patchmon/patchmon:latest        # **pin version**
    environment:
      DATABASE_URL: postgresql://patchmon:${DB_PASSWORD}@db:5432/patchmon
    volumes:
      - patchmon-data:/data
    ports: ["8080:8080"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: patchmon
      POSTGRES_USER: patchmon
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes:
  patchmon-data: {}
  pgdata: {}
```

## First boot

1. Start server → browse web UI
2. Create admin account; enable MFA
3. Generate first agent-enrollment-token
4. Install agent on first host (test on non-critical host first)
5. Verify host reports in
6. Configure notification channels
7. Add fleet gradually
8. Put behind TLS reverse proxy
9. Back up PostgreSQL

## Data & config layout

- PostgreSQL — hosts, packages, agent-state, audit
- `/data/` — agent enrollment tokens + config

## Backup

```sh
docker compose exec db pg_dump -U patchmon patchmon > patchmon-$(date +%F).sql
sudo tar czf patchmon-data-$(date +%F).tgz patchmon-data/
```

## Upgrade

1. Releases: <https://github.com/PatchMon/PatchMon/releases>. Active.
2. Read release notes — agent-server version-compatibility matters
3. Staged rollout for large fleets

## Gotchas

- **109th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — FLEET-PATCH-MGMT sub-category**:
  - PatchMon holds: fleet-agent-enrollment tokens + package-inventory (CVE-exploitable-versions-visible) + compliance-state
  - Agent-token compromise = inject-false-compliance-data
  - Inventory-DB compromise = attacker-knows-which-CVEs-to-use on your fleet
  - **109th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "fleet-patch-management + CVE-inventory"** (1st — PatchMon)
  - **CROWN-JEWEL Tier 1: 29 tools / 26 sub-categories**
- **OUTBOUND-ONLY AGENT ARCHITECTURE = EXCELLENT**:
  - No inbound ports on hosts
  - NAT-friendly, firewall-friendly
  - Reduced attack surface on hosts
  - **Recipe convention: "outbound-only-agent-architecture positive-signal"** — reinforces (Netdata/Tailscale similar)
  - **NEW positive-signal convention** (PatchMon 1st formally)
- **SINGLE-BINARY WITH EMBEDDED UI**:
  - Go + React embedded → no Node at deploy
  - Simpler ops, smaller attack surface
  - **Recipe convention: "single-binary-embedded-frontend positive-signal"**
  - **NEW positive-signal convention** (PatchMon 1st formally)
- **AI-DECLARATION BADGE = TRANSPARENT-AI-USE**:
  - "AI-DECLARATION: assist" badge on README
  - Links to AI-DECLARATION.md explaining AI usage in project
  - **EXTREMELY RARE** — honest disclosure of AI-tooling
  - **Recipe convention: "AI-DECLARATION-transparent-AI-use positive-signal"** — exceptional
  - **NEW positive-signal convention** (PatchMon 1st formally) — aligns with user's BookWyrm (108) "no-AI-code-contribution-norm" but OPPOSITE stance (explicit-assist-ok vs no-AI) — BOTH are transparency-positive
  - Distinct from BookWyrm: PatchMon discloses AI-use; BookWyrm rejects AI-use. Both are honest.
  - **Recipe convention: "AI-use-transparency-policy positive-signal"** — broader category
- **COMMERCIAL-PARALLEL-WITH-OSS-CORE**:
  - PatchMon OSS + PatchMon Cloud commercial
  - Reinforces precedent (Dittofeed+Fasten+KrakenD+Laudspeaker+PatchMon = 5 tools) 🎯 **5-TOOL MILESTONE**
- **AGPL v3 NETWORK-SERVICE**:
  - **19th tool in AGPL-network-service-disclosure**
- **MULTI-OS-MULTI-PKG-MANAGER**:
  - apt + dnf + yum + apk + pacman + pkg + Windows
  - 7 package managers
  - **Recipe convention: "multi-package-manager-support positive-signal"**
  - **NEW positive-signal convention** (PatchMon 1st formally)
- **CVE-CROWN-JEWEL INVERSE RELATIONSHIP**:
  - Knowing which CVEs apply to which hosts = security-ops critical
  - Also = attacker's roadmap if compromised
  - **Recipe convention: "CVE-inventory-is-double-edged" callout**
  - **NEW recipe convention** (PatchMon 1st formally)
- **FLEET-SCALE BACKUP + MIGRATION**:
  - Large fleets = thousands of agent-records
  - **Recipe convention: "fleet-scale-operational-tooling-discipline" callout**
- **PUBLIC ROADMAP**:
  - GitHub Projects roadmap visible
  - **Recipe convention: "public-project-roadmap"** extended — 2 tools (Defguard 108 + PatchMon) 🎯
- **INSTITUTIONAL-STEWARDSHIP**: PatchMon org + commercial-parallel + Discord + docs + AI-transparency + AGPL. **95th tool — commercial-org-with-transparent-AI-practices sub-tier** (**NEW sub-tier** — rare stance).
  - **NEW sub-tier: "commercial-org-with-transparent-AI-practices"** (1st — PatchMon)
- **TRANSPARENT-MAINTENANCE**: active + Discord + docs + roadmap + releases + AI-DECLARATION + commercial-cloud + single-binary. **103rd tool in transparent-maintenance family.**
- **PATCH-MGMT-CATEGORY:**
  - **PatchMon** — OSS + AGPL + multi-OS + outbound
  - **Landscape** (Canonical commercial) — Ubuntu-focused
  - **Pulseway / ManageEngine** (commercial enterprise)
  - **Ansible + custom playbooks** — script-based
  - **Foreman** (Red Hat) — broader scope + lifecycle mgmt
  - **Chef / Puppet** — broader config-mgmt
- **ALTERNATIVES WORTH KNOWING:**
  - **Ansible** — if you want full CM + custom patch-playbooks
  - **Foreman** — if you want broader Red Hat ecosystem
  - **Landscape** — if you're Ubuntu-enterprise
  - **Choose PatchMon if:** you want OSS + AGPL + multi-OS + outbound-only + enterprise-grade monitoring.
- **PROJECT HEALTH**: active + commercial-backed + AGPL + docs + Discord + AI-transparent. EXCELLENT.

## Links

- Repo: <https://github.com/PatchMon/PatchMon>
- Website: <https://patchmon.net>
- AI-DECLARATION: <https://github.com/PatchMon/PatchMon/blob/main/AI-DECLARATION.md>
- Foreman (alt): <https://theforeman.org>
- Landscape (Canonical): <https://ubuntu.com/landscape>
