---
name: webhook (adnanh/webhook)
description: Tiny Go binary that runs shell commands in response to HTTP webhooks. The Swiss Army knife of "make an HTTP call run a script" — perfect for deploy hooks, Git auto-deploy, alert ingestion, simple automation. Single-binary, JSON/YAML config, triggering rules, templating. MIT.
---

# webhook (adnanh/webhook)

`webhook` is a single Go binary that listens on HTTP and runs configurable shell commands when matching requests arrive. Ideal for:

- **Git push → deploy** — GitHub/GitLab push webhook hits your webhook server → it runs your deploy script
- **Alertmanager / Grafana → alert handler** — receive alerts, invoke `notify-send` or a Discord curl
- **Tiny automation glue** — anything where "an HTTP call should run a script" beats a full app

Purpose-built for sysadmin automation. Active since 2015 and basically maintenance-mode-stable; the feature set rarely changes because it does its one job well.

- Upstream repo: <https://github.com/adnanh/webhook>
- Docs: <https://github.com/adnanh/webhook/tree/master/docs>
- Hook definition reference: <https://github.com/adnanh/webhook/blob/master/docs/Hook-Definition.md>
- Examples: <https://github.com/adnanh/webhook/blob/master/docs/Hook-Examples.md>

## Architecture in one minute

- **Single Go binary** `webhook`
- Reads **hooks config** (JSON or YAML, `hooks.json` / `hooks.yaml`)
- Listens on a port (default `9000`)
- For each incoming HTTP request, matches to a hook by **id** (URL path)
- Applies **match rules** (signature verification, header checks, JSON value matches, regex)
- If rules pass, invokes `execute-command` with arguments pulled from the request (query params, JSON, form, headers)
- Returns the command's stdout as the HTTP response (configurable)

Not a daemon managing services; just a request → command runner.

## Compatible install methods

| Infra           | Runtime                                                    | Notes                                                                       |
| --------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------- |
| Single VM       | Native binary (systemd)                                     | **Most common**                                                              |
| Single VM       | Docker via community images (no official)                    | Several well-maintained community images                                     |
| Ubuntu / Debian | `apt install webhook`                                        | Community-packaged (older version but stable)                                |
| FreeBSD         | `pkg install webhook`                                        | Community-packaged                                                           |
| Snap            | `snap install webhook` (community)                           | Snap store                                                                    |
| Kubernetes      | Deploy as a Deployment + Service                              | Trivial; stateless                                                            |

## No official Docker image

Upstream doesn't publish a Docker image. Community images (README recommends):

- `almir/webhook` — <https://github.com/almir/docker-webhook>
- `roxedus/webhook` — <https://github.com/Roxedus/docker-webhook>
- `thecatlady/webhook` — <https://github.com/thecatlady/docker-webhook>
- `lwlook/webhook` — <https://hub.docker.com/r/lwlook/webhook> (allows Docker host access)

## Inputs to collect

| Input              | Example                                | Phase     | Notes                                                             |
| ------------------ | -------------------------------------- | --------- | ----------------------------------------------------------------- |
| Port               | `9000`                                 | Network   | Default HTTP listen port                                            |
| Hooks file         | `/etc/webhook/hooks.json` or `.yaml`   | Config    | Define your hooks here                                              |
| Scripts dir        | `/var/scripts/`                        | Filesystem| Your redeploy/cleanup/notify scripts                                 |
| Secret (per hook)  | `openssl rand -hex 32`                 | Security  | For HMAC signature verification (GitHub/GitLab require this)          |
| TLS (optional)     | cert + key                              | Security  | Or put behind a reverse proxy terminating TLS                         |

## Install (native binary)

```sh
# Via package manager (Ubuntu 17.04+/Debian stretch+)
sudo apt install webhook

# Or download a prebuilt binary
wget https://github.com/adnanh/webhook/releases/download/2.8.2/webhook-linux-amd64.tar.gz
tar xzf webhook-linux-amd64.tar.gz
sudo install webhook-linux-amd64/webhook /usr/local/bin/

# Or Go build (Go 1.21+)
go install github.com/adnanh/webhook@latest
```

Write `hooks.json`:

```json
[
  {
    "id": "redeploy-webhook",
    "execute-command": "/var/scripts/redeploy.sh",
    "command-working-directory": "/var/webhook",
    "response-message": "Executing redeploy script",
    "trigger-rule": {
      "match": {
        "type": "payload-hmac-sha256",
        "secret": "YOUR_WEBHOOK_SECRET",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature-256"
        }
      }
    }
  }
]
```

Run:

```sh
webhook -hooks /etc/webhook/hooks.json -verbose
# Now POST to http://<host>:9000/hooks/redeploy-webhook
```

## Run under systemd

Minimal `webhook.service`:

```ini
[Unit]
Description=webhook HTTP command runner
After=network.target

[Service]
ExecStart=/usr/local/bin/webhook -hooks /etc/webhook/hooks.json -verbose
Restart=on-failure
User=webhook
Group=webhook

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now webhook
```

## Install via Docker (community image)

```yaml
services:
  webhook:
    image: thecatlady/webhook:latest
    container_name: webhook
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - ./hooks.yaml:/etc/webhook/hooks.yaml:ro
      - ./scripts:/scripts:ro
      - /var/run/docker.sock:/var/run/docker.sock    # ONLY if scripts need docker commands
    command: -verbose -hooks /etc/webhook/hooks.yaml
```

For **deploy-from-Docker-host** patterns (script needs to run `docker compose pull` on host), `lwlook/webhook` bundles Docker CLI + socket integration.

## Hook definition essentials

```yaml
- id: my-hook
  execute-command: /scripts/deploy.sh
  command-working-directory: /app
  response-message: OK
  pass-arguments-to-command:
    - source: payload
      name: ref
  trigger-rule:
    and:
      - match:
          type: payload-hmac-sha256
          secret: <secret>
          parameter:
            source: header
            name: X-Hub-Signature-256
      - match:
          type: value
          value: refs/heads/main
          parameter:
            source: payload
            name: ref
```

Parameters can come from: `header`, `payload` (JSON path), `url` (query string), `form` data, request body. Rules support `and`, `or`, `not`, regex, value match, HMAC signatures.

## Reverse proxy for HTTPS

```nginx
location /hooks/ {
    proxy_pass http://127.0.0.1:9000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Or run webhook directly with TLS:

```sh
webhook -secure -cert /etc/letsencrypt/live/.../fullchain.pem \
         -key /etc/letsencrypt/live/.../privkey.pem -hooks hooks.json
```

## Data & config layout

- Stateless binary — no persistent state of its own
- Your `hooks.json` / `hooks.yaml` is the config
- Your scripts live wherever you want (convention: `/var/scripts/`)
- Logs go to stdout (capture via systemd journal or Docker logs)

## Backup

Back up `hooks.json` + `/var/scripts/*` (version-controlled in a git repo is ideal). No DB, no state.

## Upgrade

1. Releases: <https://github.com/adnanh/webhook/releases>. Infrequent (release every 6-12 months).
2. Replace the binary; restart systemd unit.
3. Read release notes — config format changes are rare but happen on major versions.
4. For Docker: `docker compose pull && docker compose up -d`.

## Gotchas

- **No authentication if you skip `trigger-rule`** — anyone on the network can POST and execute commands. **Always configure signature verification** for internet-exposed webhooks.
- **HMAC signature type matters**: GitHub uses `X-Hub-Signature-256` (SHA-256); GitLab uses `X-Gitlab-Token`; Bitbucket uses UUID-based signing. Match the rule type to the provider.
- **Shell injection risk** — if you pass request data unfiltered as command arguments, an attacker can break out with `;`/`$()`. Use `pass-arguments-to-command` as separate args (not a shell string) and/or sanitize inside your script.
- **Scripts run with webhook's user**. In systemd, default user is `webhook` or `root` (bad). Run as a dedicated low-privilege user; grant only what's needed (e.g., `sudo -n` for specific commands).
- **Docker socket access = root-equivalent.** If scripts need to `docker compose pull`, either mount the socket (trusted environment only) or SSH to a controller. Never expose socket-using webhooks publicly without MFA.
- **Templating (`-template` flag)** supports Go templates in hooks config — useful for dynamic config from env vars.
- **CORS**: use `-header` flag to add CORS headers if browsers need to call directly.
- **Multi-stage triggers** — use `and` / `or` / `not` rules for complex logic (e.g., "only if branch is main AND signature valid AND payload has label `deploy`").
- **Timeouts**: per-hook `command-execution-timeout` default is infinite. Set to a sane number (e.g., 300s) to prevent stuck scripts.
- **Response capture**: stdout → HTTP response body (good for GitHub webhook "Recent Deliveries" debugging). stderr → webhook's own log.
- **Form data**: for file-upload-style webhooks, see `multipart/form-data` section in README.
- **Under-fitness test** — it's Go 1.21 era; modern Go versions may or may not compile cleanly. Use prebuilt releases unless you're building from source deliberately.
- **MIT license** — use freely.
- **No official Docker image** — depend on community images; pin by tag.
- **Not a queue**: if requests arrive faster than commands finish, `webhook` runs them in parallel (bounded). For high-throughput, use a proper queue (Redis + worker).
- **No retry logic**: if the command fails, webhook returns an error response; the source is responsible for retry.
- **Alternatives worth knowing:**
  - **hookdoo** (commercial) — managed webhook-to-script service
  - **n8n / Node-RED / Home Assistant automations** — more visual, heavier
  - **`systemd-socket-activated` scripts** — no HTTP server needed, triggered by TCP accept
  - **Caddy's `exec` plugin** — similar but tied to Caddy
  - **smee.io / ngrok / localtunnel** — for developing against webhooks locally (pairs with `webhook`)
  - **Apprise** — notification forwarding (not command execution)
  - **Gohook / gitlab-webhook-receiver / rack-webhook** — more specialized

## Links

- Repo: <https://github.com/adnanh/webhook>
- Hook definition: <https://github.com/adnanh/webhook/blob/master/docs/Hook-Definition.md>
- Hook examples: <https://github.com/adnanh/webhook/blob/master/docs/Hook-Examples.md>
- Configuration: <https://github.com/adnanh/webhook/blob/master/docs/Referencing-Request-Values.md>
- Running under systemd: <https://github.com/adnanh/webhook/blob/master/docs/Systemd-Integration.md>
- Releases: <https://github.com/adnanh/webhook/releases>
- Snap package: <https://snapcraft.io/webhook>
- Debian package: <https://packages.debian.org/sid/webhook>
- Community Docker image (almir): <https://github.com/almir/docker-webhook>
- Community Docker image (Roxedus): <https://github.com/Roxedus/docker-webhook>
- Community Docker image (thecatlady): <https://github.com/thecatlady/docker-webhook>
- Community Docker image (lwlook, Docker-host-access): <https://hub.docker.com/r/lwlook/webhook>
