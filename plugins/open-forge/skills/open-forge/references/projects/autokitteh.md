---
name: AutoKitteh
description: "Self-hosted developer workflow automation and durable execution platform. Docker. Go. autokitteh/autokitteh. Write in Python/Starlark, durable via Temporal, 60+ integrations (Slack/GitHub/Gmail/Jira), VS Code extension, code-based Zapier alternative."
---

# AutoKitteh

**Code-based workflow automation and durable execution platform.** Write automation workflows in vanilla Python (or Starlark) — AutoKitteh makes them durable, reliable, and scalable via Temporal under the hood. 60+ built-in integrations (Slack, GitHub, Jira, Gmail, Google Calendar, Salesforce, Twilio, etc.). API-first, VS Code extension, web UI. Self-host or use the cloud offering.

Built + maintained by **AutoKitteh team**. Apache 2.0 license.

- Upstream repo: <https://github.com/autokitteh/autokitteh>
- Docs: <https://docs.autokitteh.com>
- Quickstart: <https://docs.autokitteh.com/get_started/quickstart>
- Cloud: <https://autokitteh.cloud>
- Example automations: <https://github.com/autokitteh/kittehub>
- Discord: <https://discord.gg/VMYFq7Trcq>

## Architecture in one minute

- **Go** server (AutoKitteh platform)
- **Temporal** workflow engine (embedded or external) — provides durable execution
- **SQLite** (default, dev) or **PostgreSQL** database
- **gRPC / HTTP** API-first architecture
- Port **9980** (HTTP API + web UI), **9982** (gRPC)
- Docker: builds from source via `compose.yaml`
- Resource: **medium** — Go + Temporal; scales horizontally

## Compatible install methods

| Infra       | Runtime                | Notes                                                         |
| ----------- | ---------------------- | ------------------------------------------------------------- |
| **Docker**  | build from `compose.yaml` | Build from source; `docker compose up`                     |
| **Binary**  | `ak` CLI               | Build from source: `make ak && cp bin/ak /usr/local/bin`      |
| **Cloud**   | autokitteh.cloud       | Managed iPaaS (beta); contact team                            |

Quickstart: <https://docs.autokitteh.com/get_started/quickstart>

## Install (self-hosted)

```bash
git clone https://github.com/autokitteh/autokitteh.git
cd autokitteh

# Option 1: Docker (dev mode)
docker compose up

# Option 2: Build the 'ak' binary (requires Go 1.24+)
make ak
cp ./bin/ak /usr/local/bin
ak version

# Start the server
ak up --mode=dev
```

Server starts on `http://localhost:9980`.

## How it works

1. Write an automation workflow in **Python** (or Starlark)
2. Use built-in SDK functions to call integrations (Slack, GitHub, etc.)
3. **Deploy** the workflow to AutoKitteh
4. **Trigger** via webhook, schedule, or event from a connected integration
5. AutoKitteh executes the workflow durably — **automatic retry on failure, state preserved across restarts, no manual checkpointing**

## Durable execution model

AutoKitteh wraps Temporal to provide:

- **Automatic retry** — failed workflow steps retry without re-running successful ones
- **State preservation** — workflow state survives server restarts
- **Long-running workflows** — wait days/weeks for events without blocking a thread
- **No boilerplate** — write plain Python; AutoKitteh handles the Temporal plumbing

## Integrations (60+)

| Category | Integrations |
|----------|-------------|
| Communication | Slack, Twilio, Zoom |
| Productivity | Gmail, Google Calendar, Notion, HubSpot |
| Developer | GitHub, Jira, Confluence, Linear |
| AI/LLM | ChatGPT, Gemini |
| Infrastructure | AWS, GCP, HTTP, gRPC |
| CRM | Salesforce |
| Auth | Auth0 |

Full list: <https://docs.autokitteh.com/integrations>

## User interfaces

- **CLI** (`ak`) — full control from terminal
- **Web UI** — visual management, monitoring, debugging
- **VS Code extension** — build and manage workflows from the IDE
- **gRPC / HTTP API** — full programmatic access

## Example workflow (Python)

```python
import autokitteh

@autokitteh.activity
def send_slack_message(channel, text):
    ak.slack.chat.post_message(channel=channel, text=text)

@autokitteh.workflow
def on_github_pr(event):
    pr = event["pull_request"]
    if pr["state"] == "opened":
        send_slack_message(
            channel="#engineering",
            text=f"New PR: {pr['title']} by {pr['user']['login']}"
        )
```

More examples: <https://github.com/autokitteh/kittehub>

## Gotchas

- **Temporal is a dependency.** Temporal provides the durable execution foundation. In `--mode=dev`, an embedded Temporal is used. For production, configure an external Temporal cluster. Temporal adds operational complexity — understand it before deploying at scale.
- **Build from source required.** There's no pre-built Docker Hub image for the compose setup — the `compose.yaml` builds from the local source. This adds build time (Go 1.24+ required). Alternatively, use the `ak` binary release from GitHub.
- **Python workflows run as activities.** AutoKitteh manages Python execution as Temporal activities — your code runs in the AutoKitteh Python runtime, not bare Python. Some Python patterns (global state, non-deterministic code) need to follow Temporal's workflow coding constraints.
- **Self-hosted is for on-prem.** The open-source server is designed for self-hosted/on-prem use. The managed cloud (autokitteh.cloud) is simpler for getting started quickly.
- **Integration credentials management.** Credentials for each integration (Slack OAuth app, GitHub App, etc.) must be configured in the AutoKitteh admin UI. Each integration has its own setup process.
- **vs. n8n/Zapier.** AutoKitteh is code-first (Python), not drag-and-drop. You write Python functions — AutoKitteh makes them durable and wires up integrations. If you want no-code/low-code, use n8n or Zapier instead.

## Backup

```sh
# SQLite (default dev mode)
cp ak.db ak-$(date +%F).db
# PostgreSQL
pg_dump autokitteh > autokitteh-$(date +%F).sql
```

## Upgrade

```sh
git pull && docker compose build && docker compose up -d
```

## Project health

Active Go development, 60+ integrations, Temporal-based durable execution, VS Code extension, cloud offering (beta), kittehub examples repo, Discord. Apache 2.0.

## Workflow-automation-family comparison

- **AutoKitteh** — Go, code-first Python/Starlark, Temporal durability, 60+ integrations, API-first
- **n8n** — Node.js, visual + code, 400+ integrations, large community; self-hosted
- **Activepieces** — TypeScript, visual, 200+ integrations; Zapier-like UX
- **Zapier** — SaaS, the commercial reference; no self-hosting
- **Temporal** — Go, durable execution primitive; AutoKitteh builds on top of it

**Choose AutoKitteh if:** you're a developer who wants to write automation workflows in plain Python with durable execution (Temporal-backed), built-in integrations, and full self-hosting control.

## Links

- Repo: <https://github.com/autokitteh/autokitteh>
- Docs: <https://docs.autokitteh.com>
- Quickstart: <https://docs.autokitteh.com/get_started/quickstart>
- Examples: <https://github.com/autokitteh/kittehub>
- Discord: <https://discord.gg/VMYFq7Trcq>
