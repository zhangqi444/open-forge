---
name: Cronicle
description: "Multi-server task scheduler with web UI — fancy cron replacement in Node.js. Scheduled + repeating + on-demand jobs, auto-failover, live log viewer, plugins in any language, JSON messaging, REST API. Maintenance mode — successor is xyOps. Node.js. MIT."
---

# Cronicle

Cronicle is **a multi-server task scheduler + runner with a web UI** — a "fancy cron replacement" in Node.js by **Joseph Huckaby (jhuckaby / pixlcore)**. Handles scheduled + recurring + on-demand jobs across a cluster of worker servers, with real-time status, live log tailing, CPU/memory tracking per job, plugins written in any language, webhooks, and a REST API. Widely deployed in homelabs + SMB environments for batch processing, reports, scraping, dev ops automation.

> **📢 Successor announced — xyOps™:**
>
> Per current upstream README: *"Announcing xyOps™, the spiritual successor to Cronicle! Version 1.0 is now live... Cronicle will still be supported and maintained going forward (mainly bug fixes and security issues will be patched)."*
>
> - **Cronicle is in maintenance mode** — bug fixes + security, not new features
> - **xyOps** is the successor: <https://xyops.io> / <https://github.com/pixlcore/xyops>
> - **For new deployments**: evaluate xyOps first
> - **For existing Cronicle**: you're fine to stay; upgrade path to xyOps if/when needed

Features:

- **Single or multi-server** cluster — primary + backup + worker roles
- **Automated failover** — backup server takes over if primary dies
- **Auto-discovery** of nearby Cronicle servers on LAN
- **Real-time job status + live log viewer**
- **Plugins in any language** — shell/Python/Node/Go/Perl/whatever reads stdin, writes JSON, exits
- **Multi-timezone scheduling** — different jobs in different timezones
- **Job queuing** — optional, for long-running events
- **CPU + memory tracking** per job
- **Historical stats + performance graphs**
- **Webhook notifications**
- **REST API** with API keys
- **User accounts** with bcrypt passwords + role-based access
- **Event history + re-run**
- **Target server groups** — route jobs to specific servers (e.g., "backup-group", "analytics-group")

- Upstream repo: <https://github.com/jhuckaby/Cronicle>
- Documentation: split across `docs/` folder
  - Setup: <https://github.com/jhuckaby/Cronicle/blob/master/docs/Setup.md>
  - Configuration: <https://github.com/jhuckaby/Cronicle/blob/master/docs/Configuration.md>
  - Web UI: <https://github.com/jhuckaby/Cronicle/blob/master/docs/WebUI.md>
  - Plugins: <https://github.com/jhuckaby/Cronicle/blob/master/docs/Plugins.md>
  - API: <https://github.com/jhuckaby/Cronicle/blob/master/docs/APIReference.md>
- Successor (xyOps): <https://github.com/pixlcore/xyops> / <https://xyops.io>

## Architecture in one minute

- **Node.js** monolith; single process per server
- **Storage backend**: local filesystem (default), S3, Couchbase (configurable)
- **Multi-server coordination**: heartbeat + primary-election
- **Job execution**: spawns child processes; plugins are stdin-JSON / stdout-JSON
- **Web UI**: built into the Node.js process; no separate webserver
- **Resource**: ~200-400 MB RAM primary; workers similar; per-job memory depends on the job
- **Listens on one port** (default 3012)

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Native via install script** (Node.js)                             | **Upstream-recommended**                                                           |
| Multi-VM cluster   | Primary + backup + worker servers                                           | Core multi-server use case                                                                              |
| Docker             | Community images (e.g., `bluet/cronicle-docker`)                                         | Works; coordinate with host network for auto-discovery                                                                          |
| Kubernetes         | Rare — Cronicle's model predates K8s                                                                                   |                                                                                                                                                    |
| Raspberry Pi       | Works — low resource                                                                                                     |                                                                                                                                                                      |

## Inputs to collect

| Input              | Example                             | Phase       | Notes                                                                 |
| ------------------ | ----------------------------------- | ----------- | --------------------------------------------------------------------- |
| Hostname           | FQDN                                    | Network     | For auto-discovery + cluster join                                                  |
| Port               | `3012`                                      | Network     | Default                                                                               |
| Storage            | local FS (default) / S3 / Couchbase                | Config      | Per deployment                                                                                 |
| Admin user         | created during install script                           | Bootstrap   | Set strong password                                                                                    |
| Secret key         | for session tokens                                       | Security    | Generated at install                                                                                              |
| Cluster servers    | primary + backup(s) + workers                                     | Deployment  | Per server role                                                                                                                |

## Install (native)

```sh
# On primary
curl -s https://raw.githubusercontent.com/jhuckaby/Cronicle/master/bin/install.js | sudo node
# Follow prompts; start with:
sudo /opt/cronicle/bin/control.sh start
```

Browse `http://<host>:3012/` → log in with admin creds.

For additional worker servers, repeat install + point at primary.

## First boot

1. Log in as admin → create additional users / API keys if needed
2. Set timezone(s) for schedule display
3. **Schedule → Add Event** → define shell command or Plugin, set cron schedule, target server/group, notifications
4. Test event manually → verify execution + log output
5. Configure webhook for notifications (Slack/Discord/Teams)
6. Add backup + worker servers to cluster as needed
7. (Optional) move state to S3/Couchbase for multi-server HA durability

## Data & config layout

- `/opt/cronicle/` — Cronicle install
- `/opt/cronicle/data/` — state: events, jobs, logs, user data (unless using S3/Couchbase)
- `/opt/cronicle/conf/` — config files
- Plugins — user-written scripts anywhere, referenced by path in event config

## Backup

```sh
# State + config (CRITICAL for scheduled jobs metadata)
sudo tar czf cronicle-$(date +%F).tgz /opt/cronicle/data /opt/cronicle/conf
```

If using S3/Couchbase, backup is on that backend's schedule.

## Upgrade

1. Releases: <https://github.com/jhuckaby/Cronicle/releases>. Maintenance mode — occasional bug fix/security releases.
2. Upstream has `upgrade.js` script in `bin/`.
3. **Back up `data/` + `conf/` first.**
4. Consider migrating to xyOps when planning major upgrade.

## Gotchas

- **Maintenance mode reality**: Cronicle won't get new features. If you need new integrations / UI improvements / modern auth (OIDC/SAML), **xyOps or another scheduler** is the path forward.
- **Security**: Cronicle runs arbitrary commands as its process user. Anyone with admin access can schedule `rm -rf /` on any connected server. **Authentication + API key scoping + network isolation matter.**
- **Default port 3012 + self-signed TLS**: put behind reverse proxy with real TLS for anything beyond dev.
- **Plugin stdin/stdout JSON model**: clean but strict. Plugin must read JSON params from stdin, emit progress + complete JSON objects to stdout. Non-JSON output goes to log.
- **Job log retention**: grows over time. Configure retention policy.
- **Multi-server clock skew**: NTP required — job scheduling depends on agreed time. Use chrony/systemd-timesyncd.
- **Primary election + failover timing**: backup takes ~1-2 min to promote. Short outages during failover normal.
- **Auto-discovery can leak across subnets** — if you have multiple Cronicle clusters on same LAN, they may see each other. Use explicit cluster tokens to prevent cross-join.
- **Storage backend choice**: local FS is fine for single-server; multi-server HA requires shared storage (S3 or Couchbase). Mixing is asking for trouble.
- **Node.js version compat**: check supported Node versions per release; old Node = security risk.
- **No OIDC/SAML**: local user accounts only. Mitigation: reverse-proxy auth (Authelia/Authentik/OAuth2-Proxy) in front.
- **Concurrent job limit**: configurable per server; watch for runaway forks.
- **Long-running jobs**: use queue mode to prevent overlapping runs; set timeouts.
- **Resource tracking (CPU/mem)**: approximate — uses `ps` polling. Don't rely for precise cost accounting.
- **License**: **MIT**.
- **Single-maintainer** (pixlcore / Joseph Huckaby): same bus-factor note as recent recipes (mox, GoatCounter, Duplicacy). xyOps transition suggests active-but-focused.
- **Alternatives worth knowing (actively developed):**
  - **xyOps** — spiritual successor by same author (<https://xyops.io>)
  - **Rundeck** (batch 67) — enterprise job scheduler; Java; multi-tenant
  - **n8n** — workflow automation; more ETL/integration-focused (separate recipe likely)
  - **Airflow** — data-pipeline DAG scheduler; heavier
  - **Dagster / Prefect** — modern data orchestrators
  - **Kestra** — workflow orchestration
  - **Windmill** — modern open-source Zapier+Airflow (separate recipe)
  - **Jenkins** — CI/CD with scheduling
  - **GitHub Actions (self-hosted runners) + cron** — if already on GHE
  - **systemd timers + Ansible** — old-school Unix
  - **Choose Cronicle if:** you already have it or want simple Node.js scheduling today.
  - **Choose xyOps if:** new deployment — successor, active.
  - **Choose Rundeck if:** enterprise + SSH-fleet automation.
  - **Choose Windmill/n8n if:** workflow/integration focus beyond plain job scheduling.

## Links

- Repo: <https://github.com/jhuckaby/Cronicle>
- Setup: <https://github.com/jhuckaby/Cronicle/blob/master/docs/Setup.md>
- Plugins: <https://github.com/jhuckaby/Cronicle/blob/master/docs/Plugins.md>
- API: <https://github.com/jhuckaby/Cronicle/blob/master/docs/APIReference.md>
- Releases: <https://github.com/jhuckaby/Cronicle/releases>
- xyOps (successor): <https://xyops.io>
- xyOps repo: <https://github.com/pixlcore/xyops>
- Rundeck (batch 67): <https://github.com/rundeck/rundeck>
- n8n (alt): <https://github.com/n8n-io/n8n>
- Windmill (alt): <https://www.windmill.dev>
