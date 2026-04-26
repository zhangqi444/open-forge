---
name: railway-paas-infra
description: Railway PaaS infra adapter — deploy via the upstream-shipped one-click template. Railway builds the project's Docker image, mounts a persistent volume, and provides a public domain with auto-HTTPS. Picked when the user wants the simplest possible PaaS UX (no terminal on the server).
---

# Railway adapter

Railway is a PaaS focused on developer experience: connect a GitHub repo (or use a one-click template), set env vars, click deploy. OpenClaw upstream ships a one-click template that pre-wires the Dockerfile, a `/data` volume, and the required env vars.

## Prerequisites

- Railway account ([signup](https://railway.com)). Free trial credit; paid usage after.
- Browser only — no CLI required for the one-click flow.

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Service name on Railway?" | Free-text | `<deployment-name>` |
| End of preflight | "Custom domain or use the auto-generated `*.up.railway.app`?" | `AskUserQuestion` | Auto-generated |
| At secrets phase | "Model-provider API key?" | Free-text (sensitive) | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.public_url` | `https://<service>.up.railway.app` (or custom) |
| `outputs.gateway_token` | Set by user as `OPENCLAW_GATEWAY_TOKEN` env var |
| `outputs.volume_mount_path` | `/data` |

## Provisioning (browser-driven)

1. Walk the user to the upstream template URL: `https://railway.com/deploy/clawdbot-railway-template`.
2. Click **Deploy on Railway**. Railway clones the openclaw repo into a new service.
3. **Add a Volume** mounted at `/data` (Railway → service → **Volumes** → **New Volume**, mount path `/data`).
4. **Set Variables** (Railway → service → **Variables**):
   - `OPENCLAW_GATEWAY_PORT=8080` (required — must match Public Networking port)
   - `OPENCLAW_GATEWAY_TOKEN=<random>` — generate with `openssl rand -hex 32`, treat as admin secret
   - `OPENCLAW_STATE_DIR=/data/.openclaw` (recommended)
   - `OPENCLAW_WORKSPACE_DIR=/data/workspace` (recommended)
   - `ANTHROPIC_API_KEY` (or your provider key)
5. **Enable HTTP Proxy** on port `8080` (Railway → service → **Settings** → **Networking** → **Generate Domain**).
6. Get the public URL from **Settings → Domains** (`https://<service>.up.railway.app` by default).

## Verification

```bash
curl -sIo /dev/null -w '%{http_code}\n' "https://<your-railway-domain>/"
# Expect: 2xx or 3xx
```

Then open `https://<your-railway-domain>/openclaw` (note the `/openclaw` path) in a browser and authenticate with `OPENCLAW_GATEWAY_TOKEN`.

## Day-to-day operations

Railway has a built-in shell:

```
Railway → service → ⋯ menu → Open Shell
```

Inside the shell, persistent storage is at `/data`:

```bash
cat /data/.openclaw/openclaw.json
openclaw backup create
openclaw devices approve --latest --token "$OPENCLAW_GATEWAY_TOKEN"
```

For automation, the `railway` CLI works too — `npm i -g @railway/cli`, `railway login`, `railway shell`.

## Logs / lifecycle

All in the Railway Dashboard: **service → Deployments / Logs / Metrics**. Restart via **Deployments → ⋯ → Restart**.

## Updates

Railway auto-redeploys on push to the connected repo. If you used the upstream template, Railway connected your account to a fork — push to the fork's main branch to redeploy. To pull upstream openclaw changes, merge them into your fork.

## Teardown

```
Railway → service → Settings → Delete Service
```

Volume is deleted with the service unless explicitly snapshotted.

## Gotchas

- **`OPENCLAW_GATEWAY_PORT` must match Public Networking port.** Both default to 8080 in the template; don't change one without the other.
- **`/openclaw` path matters.** The template's HTTP Proxy is configured for the OpenClaw Control UI at `/openclaw`, not the root. `https://<domain>/` may 404; `https://<domain>/openclaw` is the correct entry.
- **Volume isn't auto-attached.** If you skipped step 3, state writes to ephemeral container storage and disappears on every redeploy. Always add the volume before enabling networking.
- **Auto-generated `up.railway.app` domains rotate** if you delete + recreate the service. Custom domain protects against this.
- **No free always-on.** Trial credits run out; expect a small monthly bill (~$5–10) for a real always-on deployment.

## Reference

- Railway docs: <https://docs.railway.com/>
- OpenClaw on Railway (upstream): <https://docs.openclaw.ai/install/railway>
