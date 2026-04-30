---
name: xyOps
description: "Integrated job scheduler + workflow automation + server monitoring + alerting + incident ticketing — 'cron + Nagios + PagerDuty + simple ITSM in one self-hosted platform'. Free self-host tier + paid Pro/Enterprise. Node.js. BSD-licensed."
---

# xyOps

xyOps is **"what if cron, monitoring, alerting, and ticketing were the same product?"** — a self-hosted platform that combines **job scheduling + visual workflow editor + server monitoring + alerting + incident ticketing** into one integrated feedback loop. When an alert fires, the email includes the running jobs on that server + a one-click snapshot of every process / CPU / network-connection. When a job fails, xyOps can open a ticket with full context. The thesis: silos between "scheduler" and "monitor" and "ticketing" are artificial; integrating them saves the operator's most precious resource (context-switching time).

Built + maintained by **pixlcore** (Joe Huckaby's company; long-time developer behind **Cronicle**, Tunnel X, and other open-source work). xyOps is the spiritual successor (and architectural evolution) of **Cronicle** — pixlcore's widely-used self-hosted cron replacement. **BSD-licensed** (maximum permissive) for self-host + **Professional/Enterprise paid tiers** for commercial support / SSO / air-gapped install.

**Note from README**: "we do not accept feature PRs, but there are lots of other ways you can contribute". Similar maintenance-mode-transparency pattern to Wakapi (batch 81). Upstream is explicit about direction control while remaining open-source.

Use cases: (a) **fleet-wide cron management** with UI (b) **monitoring + alerting** without deploying Prometheus+Grafana+Alertmanager stack (c) **complex pipelines** (file-drop triggers job that triggers alert that opens ticket) (d) **team-shared job runbook** with audit trail (e) **small-to-mid ops teams** wanting one tool instead of five.

Features:

- **Job scheduling** — way beyond cron (UI-driven, complex triggers)
- **Visual workflow editor** — connect events, triggers, actions, monitors
- **Monitor everything** — custom monitors + notifications
- **Smart alerts** — rich alerting with complex trigger logic
- **Fleet-aware** — 5 servers or 5000
- **Snapshots** — click an alert, see process list + CPU + network at fire time
- **Ticketing** — job failures auto-open tickets with context
- **Simple setup** — self-hosting designed-for-quickness
- **No telemetry** — upstream is explicit about no phone-home

- Upstream repo: <https://github.com/pixlcore/xyops>
- Homepage: <https://xyops.io>
- Docs: <https://docs.xyops.io>
- Self-hosting: <https://docs.xyops.io/hosting>
- Pricing / Pro: <https://xyops.io/pricing>
- Sponsors: <https://github.com/sponsors/pixlcore>
- Predecessor (Cronicle): <https://github.com/jhuckaby/Cronicle>

## Architecture in one minute

- **Node.js** server + UI
- **Stores state** in local files (historically — check current) or pluggable storage
- **Agent** pattern for fleet monitoring (installed on each managed server)
- **Resource**: modest — 200-500MB RAM for server; agents are lightweight
- **Plugin / event system** — extensibility via custom plugins

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | Upstream Docker image (check current availability)                                | Simplest                                                                                   |
| Bare-metal         | Node.js install; standard pixlcore pattern                                                | Cronicle-style installer                                                                   |
| Single VM          | Server + agents on managed hosts                                                                     | Classic pattern                                                                                        |
| Kubernetes         | Standard Docker deploy                                                                                         | Community                                                                                                            |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `ops.example.com`                                               | URL          | TLS required — this tool stores server creds + SSH keys                                                                      |
| Admin user           | Initial setup wizard                                                    | Bootstrap    | Strong password; 2FA if available                                                                          |
| Data dir             | persistent storage for jobs + logs + snapshots                                                | Storage      | Consider SSD for log retention performance                                                                                     |
| Agent install        | Each managed host                                                                                           | Fleet        | Requires root or specific user                                                                                              |
| Alert destinations   | Email / Slack / Discord / custom webhook                                                                                     | Notifications | Configure BEFORE monitors fire                                                                                                   |
| Ticketing config     | Internal xyOps ticketing OR external (Jira / Linear / GitHub Issues)                                                                                              | Incidents    | Decide integration model                                                                                                                 |

## Install

Per <https://docs.xyops.io/hosting> — upstream's authoritative self-hosting guide.

Typical pixlcore-style install:
```sh
curl -s https://pixlcore.com/software/xyops/install.js | node
```
(Verify exact install path in docs — do not run unverified install scripts on production. Read first.)

## First boot

1. Complete setup wizard → admin user + password
2. Configure storage + data directory
3. Install agents on managed servers
4. Define first monitor (e.g., "disk usage > 80%")
5. Define first job (e.g., "nightly backup")
6. Configure alert destinations (email/Slack)
7. Configure ticketing (internal or external)
8. Put behind TLS reverse proxy
9. Back up data directory + config
10. Test: deliberately fail a job → verify alert → verify ticket opens with context

## Data & config layout

- Data directory (per config) — jobs, monitors, tickets, logs, snapshots
- Agents — minimal local state; report to server
- Secrets — admin passwords, SSH keys for remote job execution (if used)

## Backup

```sh
# Stop server for consistency, tar the data dir
sudo systemctl stop xyops
sudo tar czf xyops-$(date +%F).tgz /path/to/xyops/data
sudo systemctl start xyops
```

Include agent configs if they have local state.

## Upgrade

1. Releases: <https://github.com/pixlcore/xyops/releases>. Active.
2. Follow upstream upgrade procedure.
3. **Back up data dir FIRST.**
4. Agent version should match server (check upstream compat matrix).

## Gotchas

- **Integrated = less flexibility than best-of-breed.** Combining scheduler + monitoring + alerting + ticketing into one tool = great integration win, but each component will have LESS depth than Prometheus + Grafana + Alertmanager + PagerDuty + Jira individually. The tradeoff: operator simplicity vs component power. Honest framing.
- **Hub-of-credentials threat-model** applies — xyOps stores SSH keys / tokens / monitoring credentials / potentially DB creds for the systems it manages. Same **crown-jewel class** as Nexterm (batch 81), myDrive (82), Webtop (83). Hardening required:
  - **MFA enforced** on admin accounts
  - **TLS mandatory**
  - **Network-isolated** (VPN / private subnet) for access
  - **Audit logs** to external SIEM
  - **Secret at rest encryption** — check if xyOps encrypts stored credentials
- **"No telemetry" promise** — upstream is explicit about not phoning home. Positive signal (privacy-respecting) + unusual enough to be worth highlighting. Consistent with pixlcore's OSS philosophy.
- **"No feature PRs" explicit policy.** Contributions other than features are welcome (bug fixes, docs, examples). Direction control by the maintainer. Same class as Wakapi (81). Implication: if you need a specific feature, either wait, fork, or pay for a paid-tier feature request. Transparent upstream communication = positive signal + constraining for ecosystem growth.
- **Cronicle comparison**: xyOps is pixlcore's next-generation successor to Cronicle. Cronicle = simpler, narrower (cron + job scheduling); xyOps = broader scope (monitoring + tickets + workflows). If you're a Cronicle user, xyOps is the upgrade path per upstream. If you just need cron with a UI, Cronicle is still simpler.
- **Fleet scale claim**: "5 or 5000 servers". Verify for your fleet size via their docs — test at your scale before committing. Agent + Server network topology at 5000 hosts is significantly different from 50.
- **BSD license** = permissive. Fork-friendly + commercial-friendly. Rare for an actively-developed tool with paid tiers.
- **Commercial-tier-funds-upstream pattern** (well-established in this recipe corpus now):
  - **Free self-host** — all app features
  - **Professional Plan** — commercial support + private ticketing + 24-hr SLA
  - **Enterprise Plan** — SSO, air-gapped install, 1-hr SLA, live chat
  - Consistent with Cerbos Hub (81), Baserow Premium (78), Fider Cloud via TryGhost (82), many others. **xyOps pattern = Professional/Enterprise tier** (tier-type #1 "feature-gate" — SSO/air-gap-gated behind Enterprise).
- **Air-gapped install** as an Enterprise feature → signals pixlcore has customers with strict network isolation (defense / finance / regulated industries). Good signal for production-grade.
- **Ticketing scope**: xyOps does INTERNAL ticketing. If your team already uses Jira/Linear/GitHub, decide: (a) let xyOps be ticketing SoR for ops incidents (b) have xyOps open tickets in your external system via API. Don't run two parallel ticket stores.
- **Process snapshot feature** is genuinely differentiating — one-click "show me everything running on the host at the moment the alert fired". Rare among OSS monitoring tools.
- **Monitoring tool comparison**:
  - **Prometheus + Alertmanager** — metrics-first, PromQL; heavier
  - **Netdata** — real-time dashboards + lightweight agent
  - **Uptime Kuma** — simpler uptime monitoring
  - **Grafana Loki + Mimir + Tempo** — observability stack
  - **Checkmk** / **Icinga** / **Zabbix** — classic monitoring
  - **PagerDuty / Opsgenie** — alerting + incident (SaaS)
- **Scheduler comparison**:
  - **Cronicle** — pixlcore's predecessor; still usable
  - **Rundeck** — enterprise job automation (acquired by PagerDuty)
  - **Apache Airflow** — DAG-based workflow (data-eng heavy)
  - **Prefect** / **Dagster** — modern Python workflow
  - **Temporal** — durable workflow (dev-focused)
  - **Choose xyOps if:** small-to-mid ops team + want integrated tool + OK with BSD + maintenance-mode direction control.
  - **Choose Cronicle if:** just need cron-with-UI.
  - **Choose Rundeck if:** enterprise job automation with audit + RBAC.
  - **Choose Prometheus-stack if:** observability-first + willing to run multiple components.

## Links

- Repo: <https://github.com/pixlcore/xyops>
- Homepage: <https://xyops.io>
- Docs: <https://docs.xyops.io>
- Self-hosting: <https://docs.xyops.io/hosting>
- Pricing: <https://xyops.io/pricing>
- Sponsors: <https://github.com/sponsors/pixlcore>
- Contributing: <https://github.com/pixlcore/xyops/blob/main/CONTRIBUTING.md>
- Cronicle (predecessor): <https://github.com/jhuckaby/Cronicle>
- Rundeck (alt): <https://www.rundeck.com>
- Prometheus + Alertmanager: <https://prometheus.io>
- Netdata (alt monitoring): <https://www.netdata.cloud>
- Uptime Kuma (alt monitoring): <https://github.com/louislam/uptime-kuma>
