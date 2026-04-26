---
name: openclaw-project
description: OpenClaw recipe for open-forge — a self-hosted personal AI agent (openclaw.ai — NOT the Captain Claw platformer game). Covers install on AWS Lightsail (vendor blueprint or Ubuntu VM), AWS EC2, Hetzner Cloud, DigitalOcean, GCP Compute Engine, any Linux VPS (bring-your-own), and localhost. Supports any model provider (Anthropic / OpenAI / Google / Bedrock / local). Pairs with references/runtimes/{docker,native}.md, references/infra/*.md, and references/modules/tunnels.md as needed.
---

# OpenClaw

Self-hosted personal AI agent with web browsing, file access, shell execution, and optional messaging-app connectors. Runs a **gateway** daemon (WebSocket on port `18789`) plus a browser-based **Control UI**. Upstream: <https://openclaw.ai> — docs at <https://docs.openclaw.ai>.

## Compatible combos

| Where (infra) | How (service × runtime) | Adapter / runtime | Notes |
|---|---|---|---|
| **AWS Lightsail** | **OpenClaw blueprint** | `infra/aws/lightsail.md` (vendor-bundled runtime) | Fastest on AWS; Bedrock pre-wired via cross-account role. Requires a one-time IAM setup script. |
| AWS Lightsail | Ubuntu VM + Docker | `infra/aws/lightsail.md` + `runtimes/docker.md` | Use this if you don't want the vendor blueprint's Bedrock lock-in |
| AWS Lightsail | Ubuntu VM + native installer | `infra/aws/lightsail.md` + `runtimes/native.md` | Same as above, no container |
| AWS EC2 | Docker | `infra/aws/ec2.md` + `runtimes/docker.md` | More control than Lightsail; security groups and AMI choice |
| AWS EC2 | native | `infra/aws/ec2.md` + `runtimes/native.md` | Same as above, no container |
| Hetzner Cloud | Docker | `infra/hetzner/cloud-cx.md` + `runtimes/docker.md` | Cheapest VPS option; EU-regulated |
| Hetzner Cloud | native | `infra/hetzner/cloud-cx.md` + `runtimes/native.md` | |
| DigitalOcean | Docker | `infra/digitalocean/droplet.md` + `runtimes/docker.md` | Single-click droplets; integrated firewall |
| DigitalOcean | native | `infra/digitalocean/droplet.md` + `runtimes/native.md` | |
| GCP | Docker | `infra/gcp/compute-engine.md` + `runtimes/docker.md` | Compute Engine VM; needs `gcloud` configured |
| GCP | native | `infra/gcp/compute-engine.md` + `runtimes/native.md` | |
| BYO VPS (any other provider, on-prem) | Docker or native | `infra/byo-vps.md` + `runtimes/{docker,native}.md` | Catch-all when no dedicated adapter exists |
| **localhost** | Docker Desktop / native | `infra/localhost.md` + `runtimes/{docker,native}.md` | Upstream's default path (openclaw.ai's installer is designed for local). Public reach via `references/modules/tunnels.md`. |

The dynamic **how** question's options come from this table filtered by the user's **where** answer. On AWS the blueprint is the recommended default; on localhost the native installer is (simpler than Docker Desktop for most users).

## Inputs to collect

After cross-cutting preflight (cloud creds only when infra ∈ AWS/Hetzner/DO/GCP; nothing for localhost; SSH details for byo-vps):

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "OpenClaw" in the user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS / Hetzner / DigitalOcean / GCP / BYO VPS / localhost | Loads the matching infra adapter |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: options filtered by the infra choice | Loads the matching runtime module |
| provision | "Which model provider?" | `AskUserQuestion`: Bedrock (only if AWS + blueprint) / Anthropic / OpenAI / Google / Local | Blueprint defaults to Bedrock; everything else prompts |
| provision | "API key for `<provider>`?" | Free-text (sensitive) | Skipped for Bedrock (IAM) and Local. Pasted into `openclaw onboard`, not chat-logged. |
| provision (Docker only, optional) | "Enable agent sandboxing?" | `AskUserQuestion`: Yes / No | Sets `OPENCLAW_SANDBOX=1`. Requires mounting the host Docker socket. |
| (later) hardening | "Switch model provider?" | `AskUserQuestion` | Only asked after happy path verified. |

## Software-layer concerns (apply to every deployment)

### What the gateway is

- Binary named `openclaw-gateway`, written in Node. Listens on `18789/tcp` (configurable via `OPENCLAW_GATEWAY_PORT`).
- Exposes a WebSocket + HTTP control UI.
- Health endpoint: `GET /healthz` → `200 OK` when ready.

### Config files

| Path | Purpose |
|---|---|
| `~/.openclaw/openclaw.json` | Authoritative runtime config — model providers, gateway auth, sandbox mode, allowed origins |
| `~/.openclaw/agents/main/agent/models.json` | Per-agent model override (usually a subset of openclaw.json) |
| `~/.openclaw/identity/device.json` | Stable device identity for pairing |
| `~/.openclaw/.env` | Env vars loaded by the daemon (on the Lightsail OpenClaw blueprint, this is a symlink to `/opt/aws/open_claw/openclaw.env`) |

### Two-layer auth model

OpenClaw requires **both** to reach the chat UI:

1. **Gateway token** — bootstrap secret. Sourced at runtime from `.gateway.auth.token` in `openclaw.json`.
2. **Device pairing** — every browser fingerprint must be explicitly approved. Different browsers / private windows / fresh fingerprints each generate a new pairing request.

Pairing flow:

1. User opens `https://<host>/#token=<TOKEN>` (or `http://localhost:18789/#token=<TOKEN>` via tunnel / direct).
2. Browser registers a pending pairing request (device fingerprint hash).
3. Control UI shows "pairing required" until approved.
4. Approve from the host:

   ```bash
   TOKEN=$(jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json)
   openclaw devices approve --latest --token "$TOKEN"
   ```

5. User refreshes the browser tab → chat UI loads.

Notes:

- Always use `--latest`, not a specific request ID. IDs change on every browser refresh; stored IDs are usually stale (symptom: `unknown requestId`).
- The `--token` flag is required because the CLI itself isn't paired; it falls back to local-loopback auth via the token.
- Each new browser fingerprint needs its own approval. After approval, the device persists across gateway restarts and token rotations.

### Tokens are URL fragments, not query strings

Use `#token=<TOKEN>` in access URLs, not `?token=<TOKEN>`. The Lightsail blueprint's Apache config explicitly blocks `?token=` via RewriteRule for security; upstream generally discourages query-string tokens because reverse proxies log them. Fragments are client-only.

### Model provider config shape

Config lives at `~/.openclaw/openclaw.json` under `.models.providers.<name>`. Example for Anthropic direct:

```json
{
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "<sk-ant-...>",
        "api": "anthropic-messages",
        "models": [
          { "id": "claude-sonnet-4-6", "name": "Claude Sonnet 4.6", "contextWindow": 200000 }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": { "primary": "anthropic/claude-sonnet-4-6" }
    }
  }
}
```

Swap providers by editing this and restarting the gateway. Let `openclaw configure` do it interactively (recommended) or edit with `jq`.

### Switching the model provider

```bash
openclaw configure           # interactive; picks provider + paste API key
# or, via Docker runtime:
docker compose run --rm openclaw-cli configure
```

Restart the gateway after (`openclaw gateway restart` for native, `docker compose restart openclaw-gateway` for Docker). Already-paired devices keep working.

### Gateway token rotation

Upstream OpenClaw does **not** rotate the gateway token automatically. Rotate manually only after exposure (chat, logs, screenshot):

```bash
NEW=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 32)
jq --arg t "$NEW" '.gateway.auth.token = $t' ~/.openclaw/openclaw.json > /tmp/oc.json
mv /tmp/oc.json ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/openclaw.json
# then restart the gateway (method depends on runtime)
```

Paired devices keep working (per-device tokens are independent of the bootstrap token).

---

## AWS Lightsail OpenClaw blueprint (the vendor-bundled path)

When the user picks **AWS → Lightsail → OpenClaw blueprint**. Pair with [`references/infra/aws/lightsail.md`](../infra/aws/lightsail.md) for generic Lightsail provisioning.

### Blueprint

```bash
aws lightsail get-blueprints \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --query 'blueprints[?blueprintId==`openclaw_ls_1_0`]'
```

- `blueprint_id`: `openclaw_ls_1_0`
- Recommended `bundle_id`: `medium_3_0` (4 GB — AWS blog's recommended minimum, satisfies `minPower=1000`)
- SSH user: `ubuntu` (Ubuntu 24.04 under the hood)

### What the blueprint bakes in

- **Gateway as a systemd USER unit** (`openclaw-gateway.service` under user `ubuntu`) with `loginctl enable-linger` so it survives no-login sessions. There is no system-level service by design.
- **Apache 2.4 reverse proxy** on ports 80 (→ 301 to HTTPS) and 443 (snakeoil self-signed cert), forwarding to `127.0.0.1:18789`. WebSocket upgrade is supported.
- **Cross-account IAM scaffolding** for Bedrock: `/opt/aws/open_claw/target_account_id` holds your own AWS account ID, `~/.aws/config` has `[profile assumed]` pointing at `arn:aws:iam::<your-account>:role/LightsailRoleFor-<instance-id>`, `AWS_PROFILE=assumed` is set in `/opt/aws/open_claw/openclaw.env`. **The role itself does not exist until you run the setup script below.**
- **Daily token-rotation timer** (`openclaw-rotate-token.timer` at 03:00 UTC). **Disabled by default in this recipe** — not upstream behavior, and the AWS implementation is broken (see *Blueprint gotchas* below).

### Cleanup steps after provisioning

Run these right after the instance reaches `running`:

1. **Open port 22.** The blueprint's firewall locks SSH to Lightsail-internal CIDRs only (`lightsail-connect`, `lightsail-setup-*`), not `0.0.0.0/0`. Unique to this blueprint — no other Lightsail blueprint ships like this.

   ```bash
   aws lightsail put-instance-public-ports \
     --profile "$AWS_PROFILE" --region "$AWS_REGION" \
     --instance-name "$INSTANCE_NAME" \
     --port-infos '[
       {"fromPort":22,"toPort":22,"protocol":"tcp","cidrs":["0.0.0.0/0"],"ipv6Cidrs":["::/0"]},
       {"fromPort":80,"toPort":80,"protocol":"tcp","cidrs":["0.0.0.0/0"],"ipv6Cidrs":["::/0"]},
       {"fromPort":443,"toPort":443,"protocol":"tcp","cidrs":["0.0.0.0/0"],"ipv6Cidrs":["::/0"]}
     ]'
   ```

2. **Patch `allowedOrigins` for the static IP.** The install script reads the *dynamic* public IP from EC2 metadata and bakes it into `openclaw.json`. After you attach a static IP (done after provisioning — Lightsail static IPs require an existing instance), the dynamic one is stale. Browser WebSockets from the static IP will be rejected by origin check.

   ```bash
   ssh ubuntu@"$PUBLIC_IP" 'bash -s' <<EOF
   jq '.gateway.controlUi.allowedOrigins = ["http://localhost:18789","http://127.0.0.1:18789","https://${PUBLIC_IP}"]' \
     ~/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/.openclaw/openclaw.json
   chmod 600 ~/.openclaw/openclaw.json
   openclaw gateway restart
   EOF
   ```

3. **Disable the broken AWS rotation timer** (restores upstream behavior):

   ```bash
   ssh ubuntu@"$PUBLIC_IP" 'sudo systemctl disable --now openclaw-rotate-token.timer'
   ```

4. **Run the Bedrock IAM setup script** (see next section).

### IAM for Bedrock — required setup

The blueprint pre-bakes the *intent* for cross-account role assumption, but the actual IAM role doesn't exist until a setup script creates it. Before running: every Bedrock call fails with `sts:AssumeRole ... AccessDenied`.

**AWS publishes the script at a stable URL**, despite docs implying console-only access. open-forge can run it autonomously:

```bash
curl -fsSL https://d25b4yjpexuuj4.cloudfront.net/scripts/lightsail/setup-lightsail-openclaw-bedrock-role.sh \
  | AWS_PROFILE="$AWS_PROFILE" bash -s -- "$INSTANCE_NAME" "$AWS_REGION"
```

Required permissions on `$AWS_PROFILE`: `iam:CreateRole`, `iam:PutRolePolicy`, `iam:UpdateAssumeRolePolicy`, `iam:GetRole`, `lightsail:GetInstance`, `sts:GetCallerIdentity`. The script is idempotent (re-running updates trust policy + permissions, deletes nothing).

What it creates:

- IAM role `LightsailRoleFor-<instance-id>` in **your** AWS account.
- Trust policy allowing the Lightsail-internal account's instance role to assume it.
- Policy granting `bedrock:InvokeModel*`, `bedrock:ListFoundationModels`, and AWS Marketplace `Subscribe/Unsubscribe/ViewSubscriptions`.

Verify after ~5–10s (IAM propagation):

```bash
ssh ubuntu@"$PUBLIC_IP" 'AWS_PROFILE=assumed aws sts get-caller-identity'
# Expect: Arn under your account ID with LightsailRoleFor-<instance-id> role
# NOT: AccessDenied
```

### Access

- **Public HTTPS** (what the blueprint expects): `https://<PUBLIC_IP>/#token=<TOKEN>` — accept the snakeoil cert on first visit, or attach a real domain + Let's Encrypt cert (see *Optional: real cert*).
- **SSH tunnel**: `ssh -L 18789:127.0.0.1:18789 ubuntu@<PUBLIC_IP>` → `http://localhost:18789/#token=<TOKEN>`.

Retrieve the live token:

```bash
ssh ubuntu@"$PUBLIC_IP" "jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json"
# or:
ssh ubuntu@"$PUBLIC_IP" 'openclaw dashboard'   # prints the URL with token fragment
```

### Optional: real cert + custom domain

For messaging-app webhooks (Telegram/Discord) or to drop the cert warning:

1. Run the `dns` phase — A record `<domain>` → static IP.
2. Replace the snakeoil cert in `/etc/apache2/sites-enabled/default-ssl.conf`:

   ```bash
   sudo apt-get install -y certbot python3-certbot-apache
   sudo certbot --apache -d <domain> --agree-tos -m <email> -n
   ```

3. Add the domain to `allowedOrigins`:

   ```bash
   jq '.gateway.controlUi.allowedOrigins += ["https://<domain>"]' \
     ~/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/.openclaw/openclaw.json
   openclaw gateway restart
   ```

### Blueprint gotchas (Lightsail-blueprint-specific)

- **Port 22 closed by default.** Must open explicitly (step 1 above). Unique to this blueprint.
- **`allowedOrigins` baked with dynamic IP.** Must patch after static IP attach (step 2 above).
- **`/opt/aws/open_claw/credentials.log` is stale** after the first rotation. Don't read it — use `jq` on `openclaw.json` or `openclaw dashboard`.
- **AWS daily token-rotation timer is broken**: the rotation step aborts with `signal: killed` (OOM during systemd-unit reinstall), but the reinstall still wipes all paired devices. Net result: no rotation + daily lockout. Disabled by default in this recipe.
- **`sudo openclaw-rotate-token` fails to restart the gateway** with a DBUS error (`Failed to connect to bus: No medium found`) — sudo doesn't inherit the user DBUS. Token rotates fine; restart manually as `ubuntu`.
- **Bedrock IAM setup is required** despite the pre-baked target_account_id. The role doesn't exist until the script runs.

---

## Docker runtime (any infra where Docker works)

When the user picks **any cloud → Docker** or **localhost → Docker**. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for the host-level Docker install + lifecycle basics.

Upstream docs: <https://docs.openclaw.ai/install/docker> and <https://docs.openclaw.ai/install/docker-vm-runtime>.

### Sizing

- Minimum: 2 vCPU, 4 GB RAM, 20 GB disk. Image build's `pnpm install` step OOMs below ~2 GB free.
- ARM works — set `OPENCLAW_VARIANT=slim`; swap binary URLs to ARM variants per upstream.

### Install

Over SSH (or local shell for localhost):

```bash
git clone https://github.com/openclaw/openclaw.git ~/openclaw
cd ~/openclaw
bash scripts/docker/setup.sh
```

What `setup.sh` does (summarized — full flow in the upstream script):

1. Validates Docker + Compose, builds (or pulls) the image.
2. Seeds bind-mount dirs at `~/.openclaw/` and `~/.openclaw/workspace/`.
3. Generates a gateway token (or reuses an existing one).
4. Runs `openclaw onboard --mode local --no-install-daemon` **interactively** — pause autonomous mode; user pastes model provider + API key.
5. Pins `gateway.mode=local` and `gateway.bind=$OPENCLAW_GATEWAY_BIND` (default `lan`).
6. `docker compose up -d openclaw-gateway`.
7. Prints the gateway token + follow-up commands.

First build is slow (~5–10 min on 4 GB VPS); subsequent runs reuse the BuildKit cache.

### Useful env vars (set before `setup.sh`)

| Variable | Default | Purpose |
|---|---|---|
| `OPENCLAW_GATEWAY_BIND` | `lan` | `loopback` (tunnel only) / `lan` (any iface) / `tailnet` |
| `OPENCLAW_GATEWAY_PORT` | `18789` | Host-mapped gateway port |
| `OPENCLAW_BRIDGE_PORT` | `18790` | Host-mapped bridge port |
| `OPENCLAW_IMAGE` | `openclaw:local` | Set to a registry image to pull instead of build |
| `OPENCLAW_SANDBOX` | unset | `1` to enable Docker-isolated agent tool execution |
| `OPENCLAW_TZ` | `UTC` | IANA timezone string |

All persist to `~/openclaw/.env` after the first run. Re-running `setup.sh` reuses them.

### Lifecycle

```bash
cd ~/openclaw
docker compose ps
docker compose logs -f openclaw-gateway
docker compose restart openclaw-gateway
docker compose exec openclaw-gateway node dist/index.js health \
  --token "$(jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json)"
```

### Upgrades

```bash
cd ~/openclaw
git pull
bash scripts/docker/setup.sh    # rebuilds image + restarts; keeps token + config
```

### Pairing approval (Docker)

Same two-layer auth as everywhere else — approve pairing from the container's CLI:

```bash
docker compose run --rm openclaw-cli devices approve --latest \
  --token "$(jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json)"
```

### Docker-specific gotchas

- **No automatic Bedrock.** The Docker runtime has no AWS cross-account role assumption. Use Anthropic / OpenAI / Google / local here, or set up your own Bedrock credentials inside the container (not documented in this recipe).
- **Re-running `setup.sh` may overwrite `gateway.mode` and `gateway.bind`** back to defaults. Re-apply any intentional customizations after.
- See `references/runtimes/docker.md` for generic Docker gotchas (OOM on build, bind-mount perms, docker.sock exposure risk).

---

## Native installer (any Linux/macOS host without Docker)

When the user picks **any Linux/macOS host → native installer** or **localhost → native**. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for the host-level prereqs (build tools, systemd/launchd lifecycle, reverse proxy guidance).

### Install

```bash
# Linux: native.md installs build-essential / curl / ca-certificates first.
# macOS: native.md installs Xcode CLI tools first.

# Official installer (same on Linux + macOS)
curl -fsSL https://openclaw.ai/install.sh | bash
exec $SHELL -l
openclaw --version
openclaw onboard --install-daemon    # interactive — pause autonomous mode; user picks provider, pastes API key
openclaw gateway status
```

The installer drops a systemd user unit on Linux and a launchd plist on macOS. Lifecycle commands (`status` / `restart` / `journalctl`) are in `runtimes/native.md`.

### Access

Gateway binds to `127.0.0.1:18789`. Two paths to reach it:

```bash
# Remote host — SSH tunnel
ssh -L 18789:127.0.0.1:18789 <user>@<host>
# then open: http://localhost:18789/#token=<TOKEN>

# Localhost — open directly
# http://localhost:18789/#token=<TOKEN>
```

For public reach on a remote host, see `runtimes/native.md` § *Reverse proxy* (Caddy is recommended for new installs; if you're on a Bitnami/Lightsail-blueprint host, Apache is already wired).

### Native-specific gotchas (OpenClaw-only)

- **Node version mismatch after reboot.** The installer pins a specific Node. If the user has nvm or a system Node, verify `openclaw gateway status` after a deliberate reboot, not just right after install. (See `runtimes/native.md` § *PATH not refreshed* and *Node / Python version pinning* for general handling.)
- **`openclaw onboard` and `openclaw configure` are interactive** — pause autonomous mode. The native installer never has a non-interactive flow today.

---

## Verification before marking `provision` done

- Gateway process alive: `systemctl --user is-active openclaw-gateway` (native) or `docker compose ps` (Docker).
- Local probe: `curl -sI http://127.0.0.1:18789/` → `200 OK`.
- Browser pairs successfully and the chat UI loads.
- One test message round-trips — confirms the chosen model provider is reachable.

---

## Consolidated gotchas

Universal:

- **Tokens are URL fragments (`#token=`), not query strings.** Apache blocks `?token=`; upstream generally discourages query-string tokens.
- **Each browser fingerprint requires its own pairing approval.** Use `--latest`.
- **`openclaw onboard` / `openclaw configure` are interactive.** Don't try to automate — pause open-forge's autonomous mode.
- **Model costs compound.** Long agent runs can burn tokens fast. Set spend limits at the provider dashboard before first real use.

AWS Lightsail blueprint — see *Blueprint gotchas* above. Docker runtime — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*. Native — see *Native-specific gotchas* + `runtimes/native.md` § *Common gotchas*.

---

## TODO — verify on subsequent deployments

- Exact `api` string and model ID format for non-Bedrock providers when editing config directly via `jq`.
- Whether `openclaw configure` has non-interactive flags (so model swap can be scripted).
- Behavior when both Bedrock and a non-Bedrock provider are configured simultaneously.
- Native installer on macOS (only exercised on Linux so far).
- Docker runtime end-to-end (verified commands only; first full deploy will surface gotchas to fold back here).
