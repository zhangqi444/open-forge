---
name: northflank-paas-infra
description: Northflank PaaS infra adapter — deploy via the upstream-shipped one-click stack template. Northflank runs the project's Docker image and mounts a persistent volume at `/data`. Picked when the user wants a Heroku/Railway-style "no terminal on the server" path with the option to add managed Postgres/Redis later from the same console.
---

# Northflank adapter

Northflank is a PaaS that builds and runs services from Git, with managed databases, queues, and persistent volumes available from the same dashboard. OpenClaw upstream ships a one-click stack template (`Deploy OpenClaw`) that pre-wires the service + volume.

## Prerequisites

- Northflank account ([signup](https://app.northflank.com/signup)).
- Browser only — no CLI required for the one-click flow.

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Project / stack name?" | Free-text | `<deployment-name>` |
| At secrets phase | "Gateway token?" | `AskUserQuestion`: `Generate a strong random` / `I'll paste my own` | Generate |
| At secrets phase | "Model-provider API key?" | Free-text (sensitive) | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.public_url` | The public URL Northflank assigns to the OpenClaw service (visible in **View resources**) |
| `outputs.volume_mount_path` | `/data` |

## Provisioning (browser-driven)

1. Walk the user to the upstream template URL: `https://northflank.com/stacks/deploy-openclaw`.
2. Sign in to Northflank if not already.
3. Click **Deploy OpenClaw now**.
4. Set required environment variable: `OPENCLAW_GATEWAY_TOKEN` — strong random value (generate with `openssl rand -hex 32`).
5. (Optional but recommended) add `ANTHROPIC_API_KEY` (or your provider key) under the same env-var screen.
6. Click **Deploy stack**. Northflank builds the Docker image and runs it.
7. When deployment completes, click **View resources** → open the **OpenClaw** service → note the public URL.

## Verification

```bash
curl -sIo /dev/null -w '%{http_code}\n' "<the-public-url>/"
# Expect: 2xx or 3xx
```

Open `<public-url>/openclaw` in a browser and authenticate with `OPENCLAW_GATEWAY_TOKEN`.

## Day-to-day operations

Northflank provides:

| Action | Where |
|---|---|
| Live logs | Service → **Logs** |
| Shell access (browser) | Service → **Console** (browser-based; no SSH key) |
| Env-var changes | Service → **Environment** → save → auto-redeploys |
| Volume browser | Service → **Storage** → `/data` |
| Restart | Service → **Restart** |

Inside the shell, persistent storage is at `/data`:

```bash
cat /data/.openclaw/openclaw.json
openclaw backup create
openclaw devices approve --latest --token "$OPENCLAW_GATEWAY_TOKEN"
```

## Updates

Northflank auto-redeploys on push to the connected repo (your fork of openclaw, if you forked). For deployments tied directly to the upstream template, manual redeploy from the dashboard pulls the latest image.

## Teardown

```
Northflank → stack → Settings → Delete stack
```

Persistent volumes are deleted with the stack unless individually snapshotted first.

## Gotchas

- **No CLI deploy step.** Northflank is dashboard-driven for the initial setup. Document this clearly to the user — open-forge can't automate the click flow.
- **`OPENCLAW_GATEWAY_TOKEN` is the only required env var.** If you forget the API key on first deploy, the gateway boots in unconfigured mode; add the key after deploy and redeploy from the dashboard.
- **`/data` mount is part of the template.** Don't delete the volume binding when customizing other settings — state will reset on every redeploy.
- **Service URLs come from Northflank's domain pool** (`*.northflank.app` or similar). Custom domain available on paid tiers.
- **Northflank's build cache is generous** but not unlimited; expect occasional full rebuilds (~5 min) after long idle.

## Reference

- Northflank docs: <https://northflank.com/docs>
- OpenClaw on Northflank (upstream): <https://docs.openclaw.ai/install/northflank>
