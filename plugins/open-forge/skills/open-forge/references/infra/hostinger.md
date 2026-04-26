---
name: hostinger-infra
description: Hostinger managed hosting + VPS infra adapter — fully Console-driven (hPanel). Two modes: 1-Click OpenClaw (Hostinger handles infrastructure + Docker + auto-updates) and OpenClaw on VPS (Hostinger deploys via Docker; you manage through hPanel's Docker Manager). Picked when the user wants the lowest-friction managed path with optional pre-purchased "Ready-to-Use AI" credits.
---

# Hostinger adapter

Hostinger ships an OpenClaw-specific managed offering at <https://www.hostinger.com/openclaw>. Two modes, both Console-driven via hPanel:

| Mode | What you get | When to pick |
|---|---|---|
| **1-Click OpenClaw** | Fully managed; Hostinger runs OpenClaw, handles Docker + updates | Lowest-friction path; user just wants chat working |
| **OpenClaw on VPS** | A Hostinger VPS with OpenClaw deployed via Docker; manage from hPanel's **Docker Manager** | Want server-level control without leaving Hostinger's UI |

Optional **"Ready-to-Use AI" credits** at checkout pre-purchase model-provider access — no Anthropic/OpenAI/Gemini account needed. Or bring your own keys during setup.

This adapter is unusual: open-forge does **not** drive provisioning here. Hostinger's flow is browser-only at <https://www.hostinger.com/openclaw>. open-forge's role is to:

1. Walk the user to the right Hostinger page based on their mode preference.
2. Confirm post-deploy that the dashboard loads and chat is wired up.
3. Document the differences from a typical SSH-driven VPS.

## Prerequisites

- Hostinger account ([signup](https://www.hostinger.com/openclaw)).
- Browser only.
- (Optional) BYO model-provider API key, or use Ready-to-Use AI credits at checkout.
- A messaging channel choice (WhatsApp number, or Telegram bot token from BotFather).

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Mode?" | `AskUserQuestion`: `1-Click OpenClaw (managed)` / `OpenClaw on VPS (Docker Manager)` | 1-Click |
| End of preflight | "Use Ready-to-Use AI credits, or bring your own API key?" | `AskUserQuestion`: `Ready-to-Use AI` / `BYO key (Anthropic / OpenAI / Gemini / xAI)` | Ready-to-Use AI |
| End of preflight | "Messaging channel?" | `AskUserQuestion`: `WhatsApp (scan QR in setup)` / `Telegram (bot token)` / `Both` / `Skip — set up later` | WhatsApp |
| At setup phase (BYO key) | "API key?" | Free-text (sensitive) | — |
| At setup phase (Telegram) | "Bot token from BotFather?" | Free-text (sensitive) | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.dashboard_url` | Provided by hPanel after deployment (typically `https://<assigned-host>/...`) |
| `outputs.gateway_token` | Auto-generated; visible in hPanel |
| `outputs.mode` | `1-click` or `vps` |

## Provisioning (browser-driven)

### Mode A — 1-Click OpenClaw

1. Walk the user to <https://www.hostinger.com/openclaw> → choose a **Managed OpenClaw** plan → checkout.
2. At checkout, opt in to **Ready-to-Use AI** credits (or skip to bring your own keys later).
3. After checkout, **Setup wizard** prompts:
   - Pick channel: WhatsApp (scan QR) or Telegram (paste bot token).
4. Click **Finish**. Hostinger deploys.
5. Once ready: **hPanel → OpenClaw Overview → Open**. The dashboard URL loads with auth pre-wired.

### Mode B — OpenClaw on VPS

1. Walk the user to <https://www.hostinger.com/openclaw> → choose **OpenClaw on VPS** → checkout.
2. (Optional) Ready-to-Use AI credits at checkout.
3. After provisioning, **hPanel** prompts for:
   - **Gateway token** — auto-generated; copy and save.
   - **WhatsApp number** (with country code) — optional.
   - **Telegram bot token** — optional.
   - **API keys** — only if you didn't pick Ready-to-Use AI.
4. Click **Deploy**. Hostinger's Docker Manager pulls the image and starts the container.
5. Once running: **hPanel → click Open** for dashboard access.

## Verification

The user opens the dashboard from hPanel. To confirm chat is working, send "Hi" to the connected WhatsApp/Telegram channel. OpenClaw replies and walks through initial preferences.

## Day-to-day operations (Mode B specifically)

All in hPanel's **Docker Manager**:

| Action | Where |
|---|---|
| Logs | Docker Manager → service → **Logs** |
| Restart | Docker Manager → service → **Restart** |
| Update | Docker Manager → service → **Update** (pulls latest image) |
| Env-var changes | Docker Manager → service → **Edit** |

Mode A (1-Click) is fully managed — Hostinger handles updates without user action. There's no Docker Manager view; just **OpenClaw Overview**.

## SSH access?

Mode A: typically not. The managed path is browser-only.

Mode B: SSH **is** available on the VPS — Hostinger provides credentials in hPanel after provisioning. Once SSH'd in, this becomes a regular Linux Server / BYO VPS deployment (`infra/byo-vps.md`) on the back end. open-forge can drive the host directly from there if the user wants more advanced configuration than Docker Manager exposes.

## Updates

| Mode | Update path |
|---|---|
| 1-Click | Automatic — Hostinger pushes updates |
| VPS | hPanel → Docker Manager → **Update** (manual) |

## Teardown

Cancel the plan in **hPanel → Subscriptions** (or specific service settings). Hostinger handles resource cleanup.

## Gotchas

- **Browser-only flow.** Unlike every other adapter in open-forge, Hostinger's setup is genuinely click-driven at <https://www.hostinger.com/openclaw>. open-forge can't automate the click steps; we read them aloud and verify the result.
- **Ready-to-Use AI credits are pre-purchased.** They expire / get consumed; no key rotation is needed but billing is per-token. Surface the cost model so the user isn't surprised when credits run out.
- **Telegram bot pairing flow has an extra step.** After deploy, Hostinger's docs say to send the pairing code message *from Telegram directly as a message inside your OpenClaw chat* — easy to miss.
- **Mode A doesn't expose `openclaw devices approve`.** Hostinger's managed wrapper handles pairing automatically. Don't try to `kubectl exec`-style approve manually — it's not exposed.
- **Mode B is fundamentally a Hostinger VPS running Docker.** If hPanel becomes limiting, SSH into the VPS and use it as a regular Docker host (`runtimes/docker.md`).

## Reference

- Hostinger OpenClaw page: <https://www.hostinger.com/openclaw>
- OpenClaw on Hostinger (upstream): <https://docs.openclaw.ai/install/hostinger>
