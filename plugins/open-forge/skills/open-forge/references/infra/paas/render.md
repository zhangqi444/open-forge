---
name: render-paas-infra
description: Render PaaS infra adapter — deploy via the upstream-shipped `render.yaml` Blueprint from the openclaw repo. Render builds the Dockerfile, runs the container, and mounts a persistent disk. Picked when the user wants "Heroku-style" UX with a free starter tier and infrastructure-as-code via the Blueprint file.
---

# Render adapter

Render is a PaaS that builds and runs containers from a Git repo, configured declaratively via `render.yaml` (Render's "Blueprint" format). OpenClaw upstream ships the Blueprint file; Render reads it on first deploy and provisions the service + persistent disk + env vars in one step.

## Prerequisites

- Render account ([signup](https://render.com)). Free tier available but spins down after 15 min idle.
- A GitHub account linked to Render (Render reads the upstream `openclaw/openclaw` repo or your fork).
- An API key for at least one model provider (Anthropic, OpenAI, Gemini, OpenRouter).

No CLI install required — Render is browser-driven for the deploy step. Day-to-day operations (logs, shell, env vars) happen in the Render Dashboard or via `render` CLI (optional).

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Render service name?" | Free-text (lowercase, hyphens) | `<deployment-name>` |
| End of preflight | "Plan?" | `AskUserQuestion`: `Free (spin-down after 15 min idle, no disk)` / `Starter ($7/mo, always-on, 1 GB disk)` / `Standard+ ($25+/mo, more CPU)` | `Starter` |
| End of preflight | "Region?" | `AskUserQuestion`: Render auto-picks; rarely user-set | (auto) |
| At secrets phase | "API key for model provider?" | Free-text (sensitive) | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.service_name` | The Render service name |
| `outputs.public_url` | `https://<service>.onrender.com` |
| `outputs.disk_name` | `openclaw-data` (defined in upstream `render.yaml`) |

## Provisioning

### 1. Click the deploy button (browser-driven)

The fastest path uses Render's one-click deploy URL pre-wired to the upstream repo:

```
https://render.com/deploy?repo=https://github.com/openclaw/openclaw
```

Walk the user through the browser flow:

1. Sign in to Render if not already.
2. Render reads `render.yaml` from the openclaw repo and shows the planned resources (service + 1 GB disk + auto-generated `OPENCLAW_GATEWAY_TOKEN`).
3. Choose the plan (Starter recommended for always-on + persistent disk).
4. Click **Apply**. Render builds the Dockerfile (~3–5 min) and deploys.

### 2. Set the model-provider API key

The Blueprint generates `OPENCLAW_GATEWAY_TOKEN` automatically but doesn't include API keys (security). After the first deploy:

1. **Render Dashboard → your service → Environment.**
2. **Add Environment Variable:**
   - `ANTHROPIC_API_KEY=<paste>` (or `OPENAI_API_KEY`, `GEMINI_API_KEY`, etc.)
3. Save — Render auto-redeploys with the new env.

### 3. Retrieve the gateway token

```
Render Dashboard → your service → Environment → OPENCLAW_GATEWAY_TOKEN → Reveal
```

Save it for the Control UI authentication step.

## Custom domain (optional)

```
Render Dashboard → your service → Settings → Custom Domains → Add Domain
```

Render auto-provisions a TLS cert via Let's Encrypt. DNS instructions show the CNAME target (`<service>.onrender.com`).

## SSH / shell access

Render provides a browser-based shell — no SSH key required:

```
Render Dashboard → your service → Shell
```

Persistent disk is mounted at `/data` inside the shell. Useful commands once inside:

```bash
ls -la /data
cat /data/.openclaw/openclaw.json
openclaw backup create                # creates a portable archive
openclaw devices approve --latest --token "$OPENCLAW_GATEWAY_TOKEN"
```

## Logs / lifecycle

All in the Render Dashboard:

| Action | Where |
|---|---|
| Live logs | **Logs** tab — filter by build / deploy / runtime |
| Restart | **Manual Deploy** menu → **Clear build cache & deploy** (or **Restart service**) |
| Pause / resume | **Settings** → **Suspend Service** (keeps state, stops billing) |
| Roll back | **Events** → click any prior deploy → **Rollback** |

`render` CLI is optional and supports the same operations from the terminal.

## Verification

Mark `provision` done only when all of:

- Render Dashboard shows the service as **Live** (green dot).
- `curl -sI https://<service>.onrender.com/` returns 2xx/3xx.
- The Render shell can read `/data/.openclaw/openclaw.json` (persistence confirmed).

## Updates

Render auto-deploys on every push to the upstream OpenClaw repo's main branch — **but only if the Render service is connected to your fork**, not the upstream repo. If you used the one-click deploy linked to `openclaw/openclaw` directly, Render does **not** auto-deploy on upstream changes.

To pick up new openclaw versions:

```
Render Dashboard → your service → Manual Deploy → Sync Blueprint
```

Or fork the openclaw repo, point Render at your fork, and merge from upstream when you want updates (Render auto-deploys your fork on push).

## Teardown

```
Render Dashboard → your service → Settings → Delete Service
```

Confirm. Persistent disk is deleted with the service unless you explicitly snapshot first.

## Gotchas

- **Free plan = no persistent disk.** State resets on every redeploy. For any real use, upgrade to Starter ($7/mo). Periodically `openclaw backup create` if you must use Free.
- **Free plan cold starts.** First request after 15 min idle takes 30–60s while the container spins up. Health-check window is 30s — services that take longer to start fail their first health check and Render marks them unhealthy. Mitigation: upgrade to Starter (always-on).
- **`OPENCLAW_GATEWAY_PORT=8080` is mandatory.** Render expects services to bind to the port in `$PORT`. Upstream's `render.yaml` sets it to 8080 already; don't override.
- **`healthCheckPath: /health` must return 200.** If the openclaw build doesn't expose `/health`, Render keeps redeploying and failing. Verify via the Render shell: `curl -sI http://127.0.0.1:8080/health`.
- **Auto-deploy off by default for upstream-direct.** Renders linked to `openclaw/openclaw` (read-only fork relationship) won't auto-update. Document this for the user — they'll need to manual-sync when they want a new version.
- **Custom domain requires Starter+ plan.** Free tier domains are `*.onrender.com` only.
- **No SSH; shell is browser-only.** Some workflows that depend on local SSH config (file uploads from a laptop) don't work cleanly. Use `openclaw backup create` to export state, then download via the dashboard's file viewer.
- **Build cache eviction.** Render's free build cache is shared across all your services. Heavy concurrent deploys evict; expect occasional 5+ min full rebuilds.

## Reference

- Render Blueprints: <https://render.com/docs/blueprint-spec>
- Render CLI (optional): <https://render.com/docs/cli>
- OpenClaw on Render (upstream): <https://docs.openclaw.ai/install/render>
