---
name: Dagu
description: "Self-hosted workflow orchestrator — \"cron with a web UI and DAGs\". YAML workflows: shell, scripts, containers, HTTP, SQL, SSH, sub-workflows, AI agents. Single Go binary; local-file state by default. GPL-3.0. Positioned as lightweight Airflow/Prefect alternative."
---

# Dagu

Dagu is **"cron meets Airflow — one binary, no database required"** — a self-hosted **workflow orchestrator / control plane** that gives teams one place to run, schedule, review, and debug existing ops automation. YAML-defined workflows execute shell commands, scripts, containers, HTTP requests, SQL queries, SSH commands, sub-workflows, and AI agent steps. Runs as a single Go binary. Stores state in local files by default — no DB, message broker, or language-specific SDK required. Adds scheduling + dependencies + retries + queues + logs + documents + Web UI + optional distributed workers on top of your existing scripts.

Built + maintained by **Dagu team** (yohamta + community → dagucloud org). **License: GPL-3.0**. Active; Discord + Bluesky community; frequent releases.

Use cases: (a) **replacement for cron + email-tailing** — visibility + retries + kanban-view (b) **lightweight Airflow alternative** — no-DB, no-broker, no-Python-specific setup (c) **ops runbook automation** — define + schedule + review runbook steps (d) **data pipeline lite** — DB queries + HTTP → transform → ship (e) **AI-agent step orchestration** — YAML-defined multi-step LLM workflows (f) **distributed scheduled work** across worker nodes (g) **infrastructure-as-code + scheduled executions** — deploy + schedule in one tool.

Features:

- **YAML workflow definitions** — declarative DAGs (directed acyclic graphs)
- **Step types**: shell, scripts, containers (Docker), HTTP, SQL, SSH, sub-workflows, AI agents
- **Scheduling**: cron expressions + triggers + manual
- **Dependencies + retries**: define step A→B→C + retry policies
- **Queues**: limit concurrent runs per workflow
- **Distributed workers**: offload to worker nodes for scale
- **Web UI** — kanban-style run-view, logs, run details, documents
- **Single Go binary** — no external deps
- **Local-file state** by default (SQLite / filesystem) → no DB setup
- **Scales to thousands of runs/day** on one machine (per upstream claim)

- Upstream repo: <https://github.com/dagucloud/dagu>
- Homepage / live demo: <https://dagu-demo-f5e33d0e.dagu.sh> (demo creds: `demouser`/`demouser`)
- Docs: <https://docs.dagu.sh>
- Examples: <https://docs.dagu.sh/writing-workflows/examples>
- Discord: <https://discord.gg/gpahPUjGRk>
- Bluesky: <https://bsky.app/profile/dagu-org.bsky.social>
- Changelog: <https://docs.dagu.sh/overview/changelog>
- Releases: <https://github.com/dagucloud/dagu/releases>

## Architecture in one minute

- **Go single binary** — runs as one process
- **Default storage**: local filesystem + SQLite — no DB needed
- **Workflow files**: YAML in a directory you configure
- **Optional distributed**: spawn workers on other hosts; controller coordinates
- **Web UI**: served by the binary
- **Resource**: light — ~100-300MB RAM baseline; scales with concurrent runs

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Static binary**  | **Download from releases, run**                                 | **Simplest — Go single binary**                                                    |
| Docker             | `ghcr.io/dagucloud/dagu:latest` (check docs for canonical image)          | For containerized deploy                                                                                   |
| Homebrew / package | Community packages (check docs)                                                      | If available                                                                                               |
| Distributed setup  | Controller + N worker nodes                                                                                  | For scale                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Workflow directory   | `/etc/dagu/workflows`                                       | Config       | Where YAML definitions live                                                                                    |
| State directory      | `/var/lib/dagu`                                             | State        | Run logs + history                                                                                    |
| Port                 | `8080` default                                              | Network      | Web UI                                                                                    |
| Admin auth           | Configure in config.yaml                                                          | **CRITICAL** | **NEVER expose without auth** — Dagu EXECUTES ARBITRARY CODE                                                                                    |
| Secrets for steps    | DB creds, API tokens, SSH keys                                                                                  | Step-level   | Use env vars; don't hardcode                                                                                                            |

## Install (binary)

```sh
curl -L https://github.com/dagucloud/dagu/releases/latest/download/dagu_Linux_x86_64.tar.gz | tar xz
sudo mv dagu /usr/local/bin/
sudo useradd -r -s /bin/false dagu
sudo mkdir -p /etc/dagu /var/lib/dagu
sudo chown dagu:dagu /etc/dagu /var/lib/dagu

# config.yaml example
sudo tee /etc/dagu/config.yaml << 'YAML'
host: 0.0.0.0
port: 8080
dags: /etc/dagu/workflows
logDir: /var/lib/dagu/logs
auth:
  basic:
    username: admin
    password: ${DAGU_ADMIN_PASSWORD}
YAML

# systemd service
sudo tee /etc/systemd/system/dagu.service << 'UNIT'
[Unit]
Description=Dagu
[Service]
User=dagu
Environment=DAGU_ADMIN_PASSWORD=changeme
ExecStart=/usr/local/bin/dagu start-all --config /etc/dagu/config.yaml
Restart=always
[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl enable --now dagu
```

## First boot

1. Write your first workflow YAML in `/etc/dagu/workflows`
2. Browse `http://host:8080` → log in → see the kanban
3. Trigger a manual run → check logs
4. Add scheduling + retries + dependencies
5. Put behind TLS reverse proxy + IP allowlist
6. Back up workflow dir + state dir

## Data & config layout

- `config.yaml` — dagu config (auth, ports, paths)
- Workflow dir — YAML DAG definitions (treat as code; version-control)
- State dir — run history + logs + SQLite (if used)
- **Secrets** — in env vars / referenced files; DO NOT commit to git

## Backup

```sh
sudo tar czf dagu-$(date +%F).tgz /etc/dagu/workflows /var/lib/dagu
# Config file separate if it contains secrets:
sudo cp /etc/dagu/config.yaml dagu-config-$(date +%F).yaml
```

## Upgrade

1. Releases: <https://github.com/dagucloud/dagu/releases>. Active.
2. Binary: download new version, replace.
3. Back up workflow dir + state dir BEFORE upgrading.
4. Read changelog for YAML schema changes.

## Gotchas

- **DAGU = WEB-EXPOSED CODE-EXECUTION PLATFORM** (same fundamental-reality as OliveTin batch 91): workflows run shell commands + containers + HTTP + SSH. **Compromising Dagu = compromising every system Dagu can reach.** Security perimeter:
  - **NEVER expose Dagu without strong auth** — admin-only access
  - **TLS reverse proxy** mandatory
  - **Workflows run as Dagu-user** — run Dagu as non-root with limited sudo for specific commands
  - **2nd tool in web-exposed-shell-exec-gateway class** (after OliveTin 91). Dagu is broader — also runs containers + SQL + SSH.
- **COMMAND INJECTION in YAML step args**: if workflow YAML templates step arguments from web-trigger params, sanitize. Typical DAG-runner risk. Check Dagu's template-var safety (most modern orchestrators use structured passing, not string-concat).
- **AI-AGENT STEPS**: Dagu supports AI agent steps — this means LLM calls that can potentially trigger tool-use. Prompt-injection risk if LLM receives untrusted input that then triggers tool-calls. **Sandbox AI steps carefully** — limit which workflows/tools the LLM can invoke.
- **DOCKER / SSH / SQL STEPS = CROWN-JEWEL ACCESS**: Dagu steps touching Docker socket, SSH into servers, SQL against prod DB → these step-configs contain the creds-of-all-creds. **38th tool in hub-of-credentials family — CROWN-JEWEL Tier 1** (joins Octelium, Guacamole, Homarr, pgAdmin, WGDashboard, Lunar). **7th tool in Crown-Jewel-Tier-1 sub-list.** Breach of Dagu = breach of the whole ops surface.
- **AUTH CONFIG IS CRITICAL**: Dagu's config.yaml holds auth password. Perms 0600 + owned by dagu-user. Don't commit to git.
- **DISTRIBUTED WORKERS = ADDITIONAL AUTH SURFACE**: worker nodes connect to controller with shared token. Rotate tokens + limit worker-network to trusted subnets.
- **LOCAL-FILE STATE is GREAT for simplicity but LIMITS SCALE**: Dagu's filesystem/SQLite default is perfect for small-to-medium scale; push toward distributed workers for scale. Don't mix: either all-local or all-distributed for consistency.
- **"THOUSANDS-OF-RUNS-PER-DAY"** upstream claim: realistic for many workflows. For heavier (tens of thousands+/day), consider Airflow/Prefect or scale-up hardware.
- **YAML-WORKFLOWS-AS-CODE**: treat YAML workflow dir as a git repo — commit all workflow changes; review via PR; deploy via CI. Same discipline as Ansible playbooks, Terraform, Kubernetes manifests.
- **RUNS CONTAIN OUTPUT + POTENTIALLY SECRETS**: workflow logs can leak secrets (if steps print env vars, error messages echo creds, etc.). Configure:
  - Redact known secret patterns in logs
  - Use step-level secret-injection (env vs hardcoded)
  - Limit log retention
  - Audit-trail who viewed logs
- **SCHEDULE DRIFT + MONITORING**: if Dagu goes down, scheduled runs missed. Configure:
  - **Liveness monitoring** — external uptime check on Dagu
  - **Missed-run alerting** — expected-run-didn't-happen alerts
  - **Silent-failure monitoring** same family as DVB (batch 92): success + failure notifications matter.
- **PATTERN: WORKFLOW-ORCHESTRATOR-CROWN-JEWEL sub-family** (forming): Dagu + Airflow + Prefect + n8n + Temporal + Argo Workflows → all store credentials for external systems + execute code → CROWN-JEWEL-Tier-1 archetype. **1st explicitly-named tool in this sub-family** (Airflow etc. are pending).
- **COMMERCIAL-TIER**: `dagucloud` org implies there may be a cloud-hosted tier; check upstream for paid features. Currently appears to be OSS-primary with potential future cloud offering → **pattern: "emerging hosted-SaaS-of-OSS-product" OR "OSS-first-with-brand-for-future-cloud"**. Watch roadmap.
- **GPL-3.0**: source-disclosure for modified-distributed code; fine for self-host + internal.
- **TRANSPARENT-MAINTENANCE**: active releases + Discord + Bluesky + live demo with creds + clear docs + changelog + Coverity-style signals (CI badges). **20th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: dagucloud org; active community; moved from single-maintainer (yohamta) to org. **18th tool in institutional-stewardship family; emerging-company sub-tier.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Apache Airflow** — the OG workflow orchestrator; Python-centric; requires DB + scheduler; Apache-2
  - **Prefect** — modern Python; good cloud + self-host; Apache-2 + commercial
  - **Dagster** — data-centric; Python-native; Apache-2
  - **n8n** — low-code automation (different niche, more integration-focused); Sustainable Use License (source-available)
  - **Temporal** — durable workflow; production-grade; MIT; complex
  - **Argo Workflows** — Kubernetes-native; Apache-2
  - **Kestra** — YAML workflow engine; Apache-2; similar philosophy
  - **Windmill** — Rust + TypeScript; AGPL; similar YAML + script-focused
  - **Choose Dagu if:** you want SIMPLE + SINGLE-BINARY + no-DB-required + YAML + light-to-moderate scale.
  - **Choose Airflow if:** you want Python-centric + serious-data-engineering + mature-ecosystem.
  - **Choose Temporal if:** you want durable/exactly-once + serious-production-workflows.
  - **Choose n8n if:** you want low-code + integration-heavy + UI-building.
  - **Choose Kestra/Windmill if:** you want YAML + modern + feature-rich.
- **PROJECT HEALTH**: active + Go-single-binary + GPL-3 + Discord + live demo + dagucloud org + clear docs. Growing + healthy signals.

## Links

- Repo: <https://github.com/dagucloud/dagu>
- Docs: <https://docs.dagu.sh>
- Live demo: <https://dagu-demo-f5e33d0e.dagu.sh> (demouser / demouser)
- Discord: <https://discord.gg/gpahPUjGRk>
- Airflow (alt, mature): <https://airflow.apache.org>
- Prefect (alt): <https://www.prefect.io>
- Dagster (alt, data): <https://dagster.io>
- Temporal (alt, durable): <https://temporal.io>
- n8n (alt, low-code): <https://n8n.io>
- Kestra (alt, YAML): <https://kestra.io>
- Windmill (alt): <https://www.windmill.dev>
- Argo Workflows (alt, k8s): <https://argoproj.github.io/workflows/>
