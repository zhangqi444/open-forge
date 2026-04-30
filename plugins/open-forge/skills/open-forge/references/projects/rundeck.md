---
name: Rundeck
description: "Open-source runbook automation + job scheduler — standardize and delegate operational tasks across nodes. Web console + CLI + REST API. Workflow orchestration for ops, SRE, release, disaster recovery. Java/Grails + Vue.js. Owned by PagerDuty. Apache-2.0 (Community); commercial PagerDuty Runbook Automation."
---

# Rundeck

Rundeck is **a runbook automation + job scheduler** — think Jenkins for ops/SRE/release tasks rather than software builds. It lets you define workflows (a series of steps: run a shell command on 50 servers, then HTTP-POST an API, then wait for approval, then fail-over a DB) + schedule them + delegate to non-engineers via self-service jobs with ACL-limited access.

**Ownership**: Rundeck is **owned by PagerDuty**. The Community Edition (Apache-2.0) is on GitHub and fully functional; PagerDuty sells **PagerDuty Runbook Automation** (commercial) with enterprise features like ACL UI, Workflow Designer, compliance audit, enterprise support.

Common use cases:

- **Delegate ops to devs / on-call** — create parameterized "restart service X on N servers" self-service jobs; non-root users can run them safely
- **Scheduled maintenance** — nightly cleanup, DB vacuum, log rotation, cert renewal
- **Release deploy workflows** — roll out to canary → observe → full rollout
- **Disaster recovery runbooks** — codify DR steps so they're auditable + repeatable
- **Compliance reporting** — scheduled jobs emit evidence artifacts

Features:

- **Job definitions** — multi-step workflows in YAML / XML / UI
- **Nodes** — inventory sources (YAML file / EC2 / Ansible inventory / Puppet / Chef / Azure / GCP)
- **Executors** — SSH (default), local, WinRM, Kubernetes, Docker
- **Parameterization** — interactive inputs + validated options
- **Scheduling** — cron syntax
- **Error handling** — retry, failover, conditional branches
- **Notifications** — email, Slack, Discord, webhook, SNMP
- **ACLs** — yaml-based per-user/group project permissions
- **SSO** — LDAP, SAML, OIDC
- **REST API** + **CLI** (`rd`)
- **Secret management** — Key Storage (built-in) or Vault plugins
- **Audit log** — every execution; who/what/when
- **Multi-project**

- Upstream repo: <https://github.com/rundeck/rundeck>
- Website: <https://www.rundeck.com>
- Docs: <https://docs.rundeck.com/docs/>
- Install guide: <https://docs.rundeck.com/docs/administration/install/installing-rundeck.html>
- Community forum: <https://community.pagerduty.com>
- Commercial: <https://www.pagerduty.com/platform/automation/>
- Docker Hub: <https://hub.docker.com/r/rundeck/rundeck>

## Architecture in one minute

- **JVM app** — Grails (Groovy/Java) backend + Vue.js frontend
- **DB**: **MariaDB / MySQL / Postgres / H2 (dev-only)**
- **Storage**: filesystem for job definitions + logs + key storage
- **Executors**: talks over SSH, WinRM, Kubernetes API, etc.
- **Resource**: ~2 GB RAM typical; scales vertically well; cluster mode for HA

## Compatible install methods

| Infra              | Runtime                                                     | Notes                                                                         |
| ------------------ | ----------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **Debian / RPM package**                                        | **Upstream-documented**                                                           |
| Single VM          | **Docker (`rundeck/rundeck`)**                                             | Very common                                                                               |
| Single VM          | WAR (standalone Java)                                                                 | Works                                                                                                   |
| Kubernetes         | Helm / community manifests                                                                       | Production path for scale                                                                                             |
| Cluster (HA)       | Multiple Rundeck nodes + shared DB + shared filesystem                                                     | Commercial cluster features                                                                                                      |
| Managed            | **PagerDuty Runbook Automation** (SaaS, commercial)                                                                | Paid option                                                                                                                              |

## Inputs to collect

| Input                  | Example                                | Phase       | Notes                                                                          |
| ---------------------- | -------------------------------------- | ----------- | ------------------------------------------------------------------------------ |
| External URL           | `https://rundeck.example.com`                | URL         | Rundeck needs to know its own URL for callbacks                                            |
| DB                     | MariaDB / Postgres                            | Storage     | H2 for toy only                                                                              |
| Storage dir            | `/var/lib/rundeck`                                 | Files       | Job defs + logs + Key Storage                                                                             |
| SSH keys               | key for Rundeck → target nodes                          | Auth        | Load into Key Storage; rotate regularly                                                                            |
| Admin user             | first-boot wizard                                              | Bootstrap   | Change default creds immediately                                                                                                        |
| SMTP                   | host/port/user/pass                                                    | Notify      | Email alerts                                                                                                                                           |
| LDAP / OIDC / SAML     | IdP config                                                                      | SSO         | Use from day 1 for audit trail                                                                                                                                                         |

## Install via Docker

```yaml
services:
  rundeck:
    image: rundeck/rundeck:5.7                         # pin in prod
    container_name: rundeck
    restart: unless-stopped
    ports:
      - "4440:4440"
    environment:
      RUNDECK_GRAILS_URL: https://rundeck.example.com
      RUNDECK_DATABASE_DRIVER: org.mariadb.jdbc.Driver
      RUNDECK_DATABASE_USERNAME: rundeck
      RUNDECK_DATABASE_PASSWORD: CHANGE_ME
      RUNDECK_DATABASE_URL: jdbc:mariadb://db/rundeck?autoReconnect=true&useSSL=false
      RUNDECK_SERVER_ADDRESS: 0.0.0.0
    volumes:
      - ./data:/home/rundeck/server/data
      - ./logs:/home/rundeck/server/logs
    depends_on:
      - db
  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: rundeck
      MARIADB_USER: rundeck
      MARIADB_PASSWORD: CHANGE_ME
      MARIADB_RANDOM_ROOT_PASSWORD: "yes"
    volumes:
      - ./db:/var/lib/mysql
```

Put behind Caddy/Traefik/nginx with TLS.

## First boot

1. Browse `https://rundeck.example.com/` → log in as `admin` / default password (**change immediately**)
2. **System → Users** → disable default admin; create personal admin users
3. **Projects → New Project** → set name
4. **Project → Nodes → Edit Sources** → add Node Source (File/Ansible/EC2/etc.)
5. **Key Storage → Add** → upload SSH private key for target nodes
6. **Jobs → New Job** → define steps (shell command / script / HTTP) → target node filter → save
7. Run job manually → observe per-node output
8. Schedule it (cron) / expose to ops team with ACL-limited runner role

## Data & config layout

- `/etc/rundeck/` — config (`rundeck-config.properties`, `framework.properties`, `jaas-*.conf`, `realm.properties`, `log4j2.properties`)
- `/var/lib/rundeck/` — project data + logs + key storage
- `/var/log/rundeck/` — service logs
- DB — jobs, executions, users (metadata + indices)
- Project data also on disk (YAML definitions)

## Backup

```sh
# DB (critical — all execution history, job defs, users)
mysqldump -u rundeck -p rundeck | gzip > rundeck-db-$(date +%F).sql.gz
# Filesystem state
sudo tar czf rundeck-fs-$(date +%F).tgz /var/lib/rundeck/ /etc/rundeck/
```

## Upgrade

1. Releases: <https://github.com/rundeck/rundeck/releases>. Regular minor + major.
2. Back up DB + `/var/lib/rundeck/` before major.
3. Read release notes — schema changes happen. **Run DB migration step** described there.
4. Docker: bump tag → restart; migrations run automatically on start.
5. **Test on staging** — Rundeck is mission-critical; regressions are painful.

## Gotchas

- **Rundeck runs as root-equivalent on your infrastructure.** Jobs with SSH keys + sudo = god-mode. Treat ACLs + audit logs as gospel. Lock down who can create jobs vs run jobs vs read logs.
- **Default admin/admin — change IMMEDIATELY.** First thing after install.
- **SSH key management**: store in Key Storage encrypted + rotate regularly. Don't put private keys on disk unencrypted.
- **SSO from day 1**: every change you make is auditable by username. Don't share accounts.
- **ACL complexity**: Rundeck ACLs are YAML + powerful + easy to mis-scope. Test carefully before trusting. Commercial tier has ACL UI.
- **Backup DB religiously** — execution history is compliance evidence; losing it during a DR event = audit fail.
- **Cluster mode (HA)** — requires shared storage (NFS for `/var/lib/rundeck/`) + shared DB + some config. Not trivial; some features commercial-tier.
- **Memory**: JVM default heap is conservative. For real workloads, set `RUNDECK_JVM_OPTS="-Xmx4g"` or higher.
- **Long-running jobs**: Rundeck tracks via polling; very long jobs (hours+) with lots of output can memory-balloon the execution log. Tune log levels.
- **Webhooks / external triggers**: built-in webhook receivers; great for CI → Rundeck integration.
- **Ansible integration**: first-class plugin; Rundeck can execute playbooks + use Ansible inventory.
- **Executor plugins**: SSH (default), WinRM, Kubernetes, Docker, HTTP — pick per target type.
- **Job YAML as source of truth**: store job definitions in Git; import/export via CLI or API for IaC workflow.
- **Parameter validation**: regex + allowed-values on job inputs prevent user error.
- **Community vs PagerDuty commercial**: Community is Apache-2.0 + fully functional; PagerDuty adds ACL UI, Workflow Designer, compliance reports, enterprise SSO, cluster auto-failover, 24x7 support.
- **PagerDuty acquisition context**: Rundeck was acquired by PagerDuty in 2020. Community development continues; commercial offering is marketed as "PagerDuty Runbook Automation."
- **License**: Apache-2.0 (Community Edition).
- **Alternatives worth knowing:**
  - **StackStorm** — event-driven automation; more complex; opensource
  - **AWX / Ansible Automation Platform (Red Hat)** — Ansible-centric; Red Hat commercial for AAP
  - **Jenkins** — CI/CD tool; can be abused for ops; not purpose-built
  - **n8n / Node-RED** — low-code automation (different segment; lighter; separate recipe)
  - **Shipyard** — automation orchestration
  - **Semaphore CI** — Ansible-focused CI
  - **SaltStack** — config-mgmt-first; has orchestration
  - **Puppet Enterprise Orchestrator** — commercial
  - **Choose Rundeck if:** you want mature, self-hostable runbook automation with ACLs, audit, multi-executor support.
  - **Choose StackStorm if:** you want event-driven (ChatOps, alert-triggered) automation.
  - **Choose AWX if:** Ansible-centric shop and you want a UI layer.
  - **Choose n8n / Node-RED if:** lighter, integration-focused.

## Links

- Repo: <https://github.com/rundeck/rundeck>
- Website: <https://www.rundeck.com>
- Docs: <https://docs.rundeck.com/docs/>
- Install guide: <https://docs.rundeck.com/docs/administration/install/installing-rundeck.html>
- Docker Hub: <https://hub.docker.com/r/rundeck/rundeck>
- Releases: <https://github.com/rundeck/rundeck/releases>
- Release notes: <https://docs.rundeck.com/docs/history/>
- Community Q&A: <https://community.pagerduty.com>
- PagerDuty commercial: <https://www.pagerduty.com/platform/automation/>
- StackStorm (alt): <https://stackstorm.com>
- AWX (alt): <https://github.com/ansible/awx>
- n8n (alt): <https://n8n.io>
