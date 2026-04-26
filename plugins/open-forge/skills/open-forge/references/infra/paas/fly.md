---
name: fly-paas-infra
description: Fly.io PaaS infra adapter — deploy via the upstream-shipped fly.toml + Dockerfile from the openclaw repo. The `flyctl` CLI does provisioning + deploy + secrets in one tool. Two modes: public (default — Fly assigns a *.fly.dev URL with auto-HTTPS) and private (no public IP; access via WireGuard / fly proxy). Picked when the user wants minimal infra ops + global edge networking.
---

# Fly.io adapter

A PaaS that builds the project's `Dockerfile`, runs it on Firecracker microVMs, and provides:

- Persistent volumes mounted into the container (survive deploys).
- Auto-HTTPS at `<app>.fly.dev` (or a custom domain).
- Secrets management via the `flyctl` CLI.
- Optional **private mode** with no public IP — accessed via WireGuard or `fly proxy`.

OpenClaw upstream ships the `fly.toml` and `Dockerfile` in the repo root. open-forge's job: clone, customize the toml, set secrets, deploy.

## Prerequisites

- Fly.io account ([signup](https://fly.io)). Free tier covers small workloads but is not always-on.
- `flyctl` CLI installed locally and authenticated.

### Install + auth

```bash
# macOS
brew install flyctl

# Linux / WSL
curl -L https://fly.io/install.sh | sh
flyctl version

# One-time auth
fly auth login            # opens browser
fly auth whoami           # confirm
```

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Fly app name?" | Free-text (lowercase, hyphens, globally unique on Fly) | `<deployment-name>` |
| End of preflight | "Region?" | `AskUserQuestion`: `iad` (Virginia) / `ord` (Chicago) / `sjc` (San Jose) / `lhr` (London) / `fra` (Frankfurt) / `sin` (Singapore) / `Other` | Geographic-closest |
| End of preflight | "VM size?" | `AskUserQuestion`: `shared-cpu-1x / 1024mb` (free-tier-eligible) / `shared-cpu-2x / 2048mb` (recommended) / `Other` | `shared-cpu-2x / 2048mb` |
| End of preflight | "Volume size (GB)?" | `AskUserQuestion`: `1` / `3` / `10` | `1` |
| End of preflight | "Public or private?" | `AskUserQuestion`: `Public — *.fly.dev URL` / `Private — WireGuard / fly proxy access only` | `Public` |
| At secrets phase | "Anthropic / OpenAI / Gemini API key?" | Free-text (sensitive) | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.app_name` | The Fly app name |
| `outputs.region` | The Fly region |
| `outputs.volume_name` | `${app}_data` |
| `outputs.public_url` | `https://<app>.fly.dev` (public mode) or `none` (private) |

## Provisioning

### 1. Clone the project repo

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

The repo ships `fly.toml` (default config) and `fly.private.toml` (no-public-IP variant) at the root.

### 2. Create the Fly app + volume

```bash
fly apps create "$APP_NAME"
fly volumes create "${APP_NAME}_data" --size "$VOLUME_GB" --region "$FLY_REGION"
```

### 3. Customize `fly.toml`

The default `fly.toml` needs the app name and region updated. Minimum diffs:

```toml
app = "<your-app-name>"          # was: "openclaw" or similar placeholder
primary_region = "<your-region>"

# everything else can stay as upstream ships it; the key invariants:
# [processes].app must include `--bind lan` (so Fly's proxy can reach the gateway)
# [http_service].internal_port must equal --port from [processes].app
# [mounts].destination must equal /data, source must match the volume name
# [[vm]].memory should be 2048mb minimum (1024mb OOMs under load)
```

For private mode, use `fly.private.toml` instead — it removes `[http_service]` so no public IP is allocated.

### 4. Set secrets

```bash
# Required: bootstrap gateway auth
fly secrets set OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)" --app "$APP_NAME"

# Required: at least one model provider
fly secrets set ANTHROPIC_API_KEY="<paste>" --app "$APP_NAME"
# Optional: more providers
fly secrets set OPENAI_API_KEY="<paste>" --app "$APP_NAME"
fly secrets set GEMINI_API_KEY="<paste>" --app "$APP_NAME"

# Optional: messaging tokens
fly secrets set DISCORD_BOT_TOKEN="<paste>" --app "$APP_NAME"
fly secrets set TELEGRAM_BOT_TOKEN="<paste>" --app "$APP_NAME"
```

Treat these tokens like passwords. Prefer secrets over editing `openclaw.json` for any API key — keeps them out of the file (and out of any backup that includes the volume).

### 5. Deploy

```bash
# Public mode (default)
fly deploy --app "$APP_NAME"

# Private mode (no public IP)
fly deploy --app "$APP_NAME" -c fly.private.toml
```

First deploy builds the Docker image (~2–3 min). Subsequent deploys hit the build cache.

### 6. Create config inside the volume (one-time, after first deploy)

The container starts with `--allow-unconfigured` so it can boot without `/data/openclaw.json`. Once running, SSH in to seed the real config:

```bash
fly ssh console --app "$APP_NAME"

# Inside the container:
mkdir -p /data
cat > /data/openclaw.json <<'EOF'
{
  "agents": { "defaults": { "model": { "primary": "anthropic/claude-sonnet-4-6" } } },
  "gateway": {
    "mode": "local",
    "bind": "auto",
    "controlUi": {
      "allowedOrigins": [
        "https://<your-app>.fly.dev",
        "http://localhost:3000",
        "http://127.0.0.1:3000"
      ]
    }
  }
}
EOF
exit

fly machine restart $(fly machines list --app "$APP_NAME" --json | jq -r '.[0].id')
```

`gateway.controlUi.allowedOrigins` MUST include the public Fly URL — the container's `--bind lan` advertises `0.0.0.0` but browsers from `*.fly.dev` are origin-checked separately.

## SSH convention

```bash
fly ssh console --app "$APP_NAME"               # interactive shell
fly ssh console --app "$APP_NAME" -C 'cat /data/openclaw.json'   # one-shot
fly sftp shell --app "$APP_NAME"                # file transfer
```

Note: `fly ssh console -C` doesn't honor shell redirection; for writing files, pipe via `tee` or use `fly sftp`.

## Public access (public mode)

```bash
fly open --app "$APP_NAME"                      # opens https://<app>.fly.dev
# Or directly: https://<app>.fly.dev/
```

Authenticate with `OPENCLAW_GATEWAY_TOKEN` (use `#token=<TOKEN>` URL fragment, not `?token=`).

## Private access (private mode)

No public URL. Pick one:

```bash
# Option 1 — local proxy (simplest)
fly proxy 3000:3000 --app "$APP_NAME"
# then open http://localhost:3000

# Option 2 — WireGuard
fly wireguard create
# import the printed config to your WireGuard client; then open http://[fdaa:x:x:x::x]:3000

# Option 3 — SSH only
fly ssh console --app "$APP_NAME"
```

For inbound webhooks (Telegram, Discord) in private mode, use a tunnel inside the container (ngrok, Tailscale Funnel) — see `references/modules/tunnels.md`.

## Logs / lifecycle

```bash
fly logs --app "$APP_NAME"                              # live tail
fly logs --no-tail --app "$APP_NAME" | tail -200        # recent
fly status --app "$APP_NAME"
fly machines list --app "$APP_NAME"
fly machine restart <machine-id> --app "$APP_NAME"
fly deploy --app "$APP_NAME"                            # redeploy after a git pull
```

## Verification

Mark `provision` done only when all of:

- `fly status --app "$APP_NAME"` shows `started` for the machine.
- `fly logs` shows `[gateway] listening on …`.
- (Public) `curl -sIo /dev/null -w '%{http_code}\n' https://<app>.fly.dev/` returns 2xx/3xx.
- (Private) `fly proxy 3000:3000` then `curl -sI http://127.0.0.1:3000/` returns 2xx/3xx.

## Teardown

Don't auto-run; confirm.

```bash
fly apps destroy "$APP_NAME" -y
fly volumes destroy "${APP_NAME}_data" -y     # if not auto-deleted with the app
```

## Gotchas

- **`--bind lan` is required.** Default openclaw bind is loopback; Fly's proxy needs `0.0.0.0`. Fly's health check fails silently if you forget. Symptom: `App is not listening on expected address`.
- **`internal_port` must match `--port`.** Mismatch silently fails health checks.
- **Memory: 1024mb is too small.** OOM kills during build or under load. Default to 2048mb. Symptom: `SIGABRT`, `v8::internal::Runtime_AllocateInYoungGeneration`, or silent restarts.
- **Lock file at `/data/gateway.*.lock`.** Survives container restart. If gateway refuses to start with "already running", `fly ssh console -C 'rm -f /data/gateway.*.lock'` then `fly machine restart`.
- **`fly deploy` resets the machine command.** Manual `fly machine update --command ...` overrides drop after the next `fly deploy`. Keep machine command in `fly.toml`.
- **`OPENCLAW_STATE_DIR=/data` is critical for persistence.** Without it, state writes to the container filesystem and disappears on every restart. Confirm in `fly.toml` `[env]` block.
- **`allowedOrigins` must list the public Fly URL.** Browser WebSocket connections from `<app>.fly.dev` get rejected by origin check otherwise. The default config seeds local origins only — patch via SSH after first deploy.
- **Signal Messenger requires Java + signal-cli.** Default Dockerfile doesn't ship them. Use a custom image; keep memory ≥ 2048mb.
- **x86 only on Fly.** No ARM/Graviton machines. Don't try ARM tags.
- **Free tier sleeps after 15 min idle.** Set `min_machines_running = 1` in `[http_service]` to keep always-on (counts against free allowance).

## Reference

- Fly.io docs: <https://fly.io/docs/>
- `flyctl` reference: <https://fly.io/docs/flyctl/>
- OpenClaw on Fly (upstream): <https://docs.openclaw.ai/install/fly>
