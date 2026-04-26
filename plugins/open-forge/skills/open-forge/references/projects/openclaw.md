---
name: openclaw-project
description: OpenClaw recipe for open-forge — a self-hosted personal AI agent (openclaw.ai — NOT the Captain Claw platformer game). Covers every upstream-blessed install path documented under docs.openclaw.ai/install/* — Containers (Docker, Podman, Kubernetes/Kustomize, ClawDock, Ansible, Nix, Bun) and Hosting (AWS Lightsail blueprint, Azure VM, DigitalOcean, GCP, Hetzner, Hostinger, Oracle Cloud free-tier ARM, Raspberry Pi, macOS VMs via Lume, Linux Server via BYO VPS, native installers including install.sh / install-cli.sh / install.ps1, plus PaaS one-clicks: Fly.io, Render, Railway, Northflank, exe.dev). Supports any model provider (Anthropic / OpenAI / Google / Bedrock / GitHub Copilot / xAI / local). Pairs with references/runtimes/{docker,native,kubernetes,podman}.md, references/infra/*.md, and references/modules/tunnels.md as needed.
---

# OpenClaw

Self-hosted personal AI agent with web browsing, file access, shell execution, and optional messaging-app connectors. Runs a **gateway** daemon (WebSocket on port `18789`) plus a browser-based **Control UI**. Upstream: <https://openclaw.ai> — docs at <https://docs.openclaw.ai>.

## Compatible combos

OpenClaw upstream documents two parallel axes — **how to package it** (Containers) and **where to host it** (Hosting). open-forge maps these onto our 3-layer model: a where-answer picks an infra adapter, a how-answer picks a runtime module, and the upstream-specific commands live in the per-method sections below.

### Hosting (where) — picks the infra adapter

| Where | Adapter | Recommended runtime | Notes |
|---|---|---|---|
| **AWS Lightsail** (OpenClaw blueprint) | `infra/aws/lightsail.md` | vendor-bundled (native) | Fastest on AWS; Bedrock pre-wired via cross-account role. Requires a one-time IAM setup script. |
| **AWS Lightsail** (Ubuntu VM) | `infra/aws/lightsail.md` | `docker` or `native` | When you don't want the blueprint's Bedrock lock-in |
| **AWS EC2** | `infra/aws/ec2.md` | `docker` or `native` | More control than Lightsail; security groups and AMI choice |
| **Azure** | `infra/azure/vm.md` | `docker` or `native` | Bastion-hardened (no public IP); good for enterprise + GitHub Copilot users |
| **Hetzner Cloud** | `infra/hetzner/cloud-cx.md` | `docker` or `native` | Cheapest serious-VPS tier; EU-regulated |
| **DigitalOcean** | `infra/digitalocean/droplet.md` | `docker` or `native` | Polished UX; integrated firewall |
| **GCP Compute Engine** | `infra/gcp/compute-engine.md` | `docker` or `native` | Tag-targeted firewall, static IP |
| **Oracle Cloud** (Always-Free ARM) | `infra/oracle/free-tier-arm.md` | `native` | Genuinely free, indefinitely; ARM (aarch64); reach via Tailscale |
| **Hostinger** (Managed OpenClaw) | (none — Hostinger Console drives it) | vendor-bundled | 1-click managed; or "OpenClaw on VPS" via Hostinger Docker Manager |
| **Raspberry Pi** | `infra/byo-vps.md` (host, 64-bit Pi OS) | `native` | Pi 4/5 (4 GB+); ARM; always-on home self-host |
| **macOS VM** (Lume on Apple Silicon) | `infra/macos-vm.md` | `native` | Use only when you need iMessage via BlueBubbles or strict isolation from your daily Mac |
| **Linux Server / BYO VPS** | `infra/byo-vps.md` | `docker` or `native` | Catch-all for any provisioned Linux box (Vultr, Linode, on-prem, etc.) |
| **localhost** | `infra/localhost.md` | `docker` or `native` | Upstream's default path. Public reach via `references/modules/tunnels.md`. |
| **Fly.io** | `infra/paas/fly.md` | (PaaS bundles runtime) | Persistent volumes + auto-HTTPS. Two modes: public + private (no public IP). |
| **Render** | `infra/paas/render.md` | (PaaS bundles runtime) | Blueprint-based (`render.yaml` lives in upstream repo). |
| **Railway** | `infra/paas/railway.md` | (PaaS bundles runtime) | One-click template; required env vars + volume at `/data`. |
| **Northflank** | `infra/paas/northflank.md` | (PaaS bundles runtime) | One-click stack; persistent `/data` volume. |
| **exe.dev** | `infra/paas/exe-dev.md` | (PaaS bundles runtime) | Shelley agent does provisioning; `<vm>.exe.xyz` HTTPS proxy. |
| **Any Kubernetes cluster** (EKS / GKE / AKS / DOKS / k3s / kind / Docker-Desktop-K8s) | user-provisioned cluster | `kubernetes` | Upstream uses **Kustomize** via `scripts/k8s/deploy.sh` (Helm is community-only). |

### Containers (how) — picks the runtime module

| How | Runtime | Notes |
|---|---|---|
| **Docker** | `runtimes/docker.md` | The upstream-recommended default for VPS-style hosts. Setup script: `./scripts/docker/setup.sh` from the openclaw repo. |
| **Podman** | `runtimes/podman.md` | Rootless Docker-compatible alternative. Setup: `./scripts/podman/setup.sh`. Quadlet (systemd-user) supported. |
| **Kubernetes** | `runtimes/kubernetes.md` | **Kustomize-first** — `./scripts/k8s/deploy.sh` from the openclaw repo. Community Helm charts exist but are not upstream-blessed. |
| **Native** (`install.sh`) | `runtimes/native.md` | macOS / Linux / WSL2 — global Node + project install. systemd / launchd daemon. |
| **Native** (`install-cli.sh`) | `runtimes/native.md` | macOS / Linux / WSL2 — local-prefix install (`~/.openclaw` by default). No root required. |
| **Native** (`install.ps1`) | `runtimes/native.md` | Native Windows (PowerShell 5+). Scheduled Task daemon. |
| **ClawDock** | (shell wrapper over Docker — see project-specific section below) | Optional UX layer: `clawdock-start`, `clawdock-dashboard` instead of `docker compose ...`. |
| **Ansible** | (production hardening — see project-specific section below) | The `openclaw-ansible` upstream repo: UFW + Tailscale + Docker-isolated sandbox + systemd-hardened gateway. Native (not containerized) gateway. |
| **Nix** | (declarative — see project-specific section below) | The `nix-openclaw` Home Manager module: rollback-able, deterministic, launchd-managed (macOS). |
| **Bun** (experimental) | (dev-only — see project-specific section below) | TypeScript runtime swap for `bun run` / `bun --watch`. **Not recommended for gateway runtime** (WhatsApp + Telegram issues). |

The dynamic **how** question's options come from filtering this table by the user's **where** answer. On AWS the blueprint is the recommended default; on localhost the native installer is simpler than Docker Desktop for most users; for k8s the upstream Kustomize flow is the supported path.

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

## Native installer (Linux / macOS / Windows / WSL)

Three official installer scripts, served from `openclaw.ai`. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for the host-level prereqs (build tools, systemd/launchd/Scheduled-Tasks lifecycle, reverse proxy guidance).

| Script | Platform | When |
|---|---|---|
| `install.sh` | macOS / Linux / WSL2 | Default. Global install (system-wide Node). |
| `install-cli.sh` | macOS / Linux / WSL2 | Local prefix (default `~/.openclaw`). No root required. |
| `install.ps1` | Native Windows (PS 5+) | Installs Node via winget/Chocolatey/Scoop, then OpenClaw via npm. |

Upstream docs: <https://docs.openclaw.ai/install/installer> and `<https://docs.openclaw.ai/install/installer#installsh>` / `#install-clish` / `#installps1`.

### `install.sh` — macOS / Linux / WSL2 (default)

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
exec $SHELL -l
openclaw --version
openclaw onboard --install-daemon    # interactive — pause autonomous mode; user picks provider, pastes API key
openclaw gateway status
```

The installer drops a systemd **user** unit on Linux and a launchd plist on macOS. Lifecycle commands (`status` / `restart` / `journalctl`) are in `runtimes/native.md`. Defaults to **Node 24** (Node 22.14+ also supported); installs Git if missing; sets `SHARP_IGNORE_GLOBAL_LIBVIPS=1`.

Useful flags / env:

| Flag / env | Effect |
|---|---|
| `--no-onboard` / `OPENCLAW_NO_ONBOARD=1` | Skip the post-install wizard (Claude pre-stages config later) |
| `--no-prompt` / `OPENCLAW_NO_PROMPT=1` | Disable interactive prompts |
| `--install-method git\|npm` | npm registry vs git checkout (default `npm`) |
| `--version <ver>` | Pin a version, dist-tag (`latest` / `next` / `main`), or full package spec |
| `--beta` / `OPENCLAW_BETA=1` | Use the beta dist-tag if published |
| `--dry-run` | Print actions without executing — confirm before committing |

### `install-cli.sh` — local prefix (no root)

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash
# or pin a custom prefix:
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh | bash -s -- --prefix /opt/openclaw
exec $SHELL -l
"$HOME/.openclaw/bin/openclaw" --version
```

Downloads a pinned Node tarball (SHA-256 verified) into `<prefix>/tools/node-v<version>` and writes the wrapper at `<prefix>/bin/openclaw`. Useful when:

- You can't write to `/usr/local/`.
- The host has a Node version openclaw can't use (or none at all).
- You want multiple openclaw versions side-by-side under different prefixes.

Useful flags:

| Flag | Effect |
|---|---|
| `--prefix <path>` | Install root (default `~/.openclaw`) |
| `--node-version <ver>` | Pin Node version inside the prefix |
| `--json` | Emit NDJSON events — for CI/automation |
| `--onboard` | Run the wizard after install (default skips) |

### `install.ps1` — native Windows

```powershell
iwr -useb https://openclaw.ai/install.ps1 | iex
openclaw --version
openclaw onboard --install-daemon
openclaw gateway status
```

Installs Node via `winget` → `Chocolatey` → `Scoop` (first available wins). Daemon autostart uses **Scheduled Tasks**; manage via PowerShell's `Get-ScheduledTask -TaskName "openclaw*"`. Requires PS 5+.

For non-interactive runs:

```powershell
& ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
```

### Access (all three modes)

Gateway binds to `127.0.0.1:18789`. Three paths to reach it:

```bash
# Remote host — SSH tunnel
ssh -L 18789:127.0.0.1:18789 <user>@<host>
# then open: http://localhost:18789/#token=<TOKEN>

# Localhost — open directly
# http://localhost:18789/#token=<TOKEN>

# `openclaw dashboard` prints the URL with token fragment
openclaw dashboard --no-open
```

For public reach on a remote host, see `runtimes/native.md` § *Reverse proxy* (Caddy is recommended for new installs; on a Bitnami/Lightsail-blueprint host, Apache is already wired).

### Native-specific gotchas (OpenClaw-only)

- **Three installers don't share state.** A user who ran `install.sh` and later `install-cli.sh` has two `openclaw` binaries on PATH; whichever appears first in shell rc wins. Pick one and stick with it.
- **Node version mismatch after reboot.** `install.sh` and `install.ps1` use the system Node. If the user has nvm / `pyenv`-style Node managers / a system Node from another package, verify `openclaw gateway status` after a deliberate reboot. `install-cli.sh` ships its own pinned Node and is immune to this.
- **`openclaw onboard` and `openclaw configure` are interactive** — pause autonomous mode. There is no fully non-interactive onboarding today; `--no-onboard` skips the wizard but then the user must `openclaw configure` or hand-edit `openclaw.json` later.
- **Windows: `iwr | iex` errors are non-fatal to the shell.** A failure inside the piped script reports a terminating error but doesn't close the PowerShell window. Always check the explicit success line — silent partial installs happen on Windows more than elsewhere.
- **Local-prefix mode + GUI app on macOS.** The macOS GUI app doesn't inherit shell PATH. For Nix-style local-prefix installs the GUI won't see `openclaw`; the CLI still works.

---

## Kubernetes (any cluster — managed or self-hosted)

When the user picks **any k8s cluster → Kustomize**. Pair with [`references/runtimes/kubernetes.md`](../runtimes/kubernetes.md) for kubectl prereqs, namespace + Secret hygiene, ingress/cert-manager guidance.

Upstream docs: <https://docs.openclaw.ai/install/kubernetes>. The supported path is **Kustomize**, not Helm. Upstream explicitly says: *"OpenClaw is a single container with some config files. The interesting customization is in agent content (markdown files, skills, config overrides), not infrastructure templating. Kustomize handles overlays without the overhead of a Helm chart."* Community Helm charts exist (`Chrisbattarbee/openclaw-helm`, `serhanekicii/openclaw-helm`) but are not upstream-blessed.

### Prereqs (cluster-side)

- A reachable k8s cluster (`kubectl get nodes` returns ready nodes). Local testing: `kind create cluster` works (upstream ships `./scripts/k8s/create-kind.sh`).
- A default `StorageClass` (`scripts/k8s/manifests/pvc.yaml` requests 10 GiB).
- An API key for at least one model provider (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, or `OPENROUTER_API_KEY`).

No ingress controller required for the default flow — upstream's manifests bind the gateway to **loopback inside the pod** and expect access via `kubectl port-forward`. Public access requires switching the bind to non-loopback (see *Going beyond port-forward* below).

### Install (upstream `deploy.sh`)

```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw

# Replace ANTHROPIC with your provider as needed: GEMINI / OPENAI / OPENROUTER
export ANTHROPIC_API_KEY="..."
./scripts/k8s/deploy.sh
```

The script creates a namespace (`openclaw` by default; override with `OPENCLAW_NAMESPACE=...`), generates a gateway token, creates the `openclaw-secrets` Secret with your API key + token, then `kubectl apply -k`s the manifests. It's idempotent — re-running preserves existing keys not being changed.

For local debug runs, `./scripts/k8s/deploy.sh --show-token` prints the gateway token to stdout. Otherwise:

```bash
kubectl get secret openclaw-secrets -n openclaw \
  -o jsonpath='{.data.OPENCLAW_GATEWAY_TOKEN}' | base64 -d
```

### Verify

```bash
kubectl -n openclaw get pods,svc,pvc,configmap,secret
kubectl -n openclaw rollout status deploy/openclaw
kubectl -n openclaw logs deploy/openclaw -f
kubectl -n openclaw port-forward svc/openclaw 18789:18789
```

Then open `http://localhost:18789` and authenticate with the gateway token (from the Secret). Pairing approval flows through the same `openclaw devices approve --latest --token "$TOKEN"` command as elsewhere — but it must run **inside the pod** where the pairing state lives:

```bash
kubectl -n openclaw exec deploy/openclaw -- bash -lc \
  'TOKEN=$(jq -r .gateway.auth.token ~/.openclaw/openclaw.json); openclaw devices approve --latest --token "$TOKEN"'
```

### Customization

| Change | How |
|---|---|
| Agent instructions | Edit `AGENTS.md` in `scripts/k8s/manifests/configmap.yaml`, then re-run `./scripts/k8s/deploy.sh` |
| Gateway config (`openclaw.json`) | Edit `scripts/k8s/manifests/configmap.yaml`; same redeploy |
| Add provider keys | Re-run `./scripts/k8s/deploy.sh --create-secret` with new env vars exported. Existing keys stay unless overwritten. |
| Custom namespace | `OPENCLAW_NAMESPACE=my-namespace ./scripts/k8s/deploy.sh` |
| Custom image / version | Edit `image:` in `scripts/k8s/manifests/deployment.yaml` (e.g. pin `ghcr.io/openclaw/openclaw:v<version>`) |

Direct Secret patch (skips re-running `deploy.sh`):

```bash
kubectl patch secret openclaw-secrets -n openclaw \
  -p '{"stringData":{"OPENAI_API_KEY":"..."}}'
kubectl rollout restart deployment/openclaw -n openclaw
```

### Going beyond port-forward (Service / Ingress)

The default manifests bind the gateway to loopback **inside the pod**, so a Kubernetes `Service` or Ingress that targets the pod IP won't reach it. To expose:

1. Edit `scripts/k8s/manifests/configmap.yaml` and change the gateway bind from `loopback` to a non-loopback mode that matches your deployment (e.g. `lan` if behind a TLS-terminating proxy).
2. Keep gateway auth enabled.
3. Add an Ingress + cert-manager `ClusterIssuer` (see `runtimes/kubernetes.md` § *Reaching the service from outside*).
4. Set `gateway.controlUi.allowedOrigins` to include your public origin.

Or use Tailscale Serve / Funnel side-channel instead of opening the cluster — see `references/modules/tunnels.md`.

### Teardown

```bash
./scripts/k8s/deploy.sh --delete
```

Deletes the namespace and everything in it — **including the PVC**. The gateway token and paired-device state are gone. To preserve, snapshot the PVC first or take a backup via `openclaw backup create` before deleting.

### Kubernetes-specific gotchas (OpenClaw-only)

- **Kustomize, not Helm — even though community Helm charts exist.** Don't trust a `helm install openclaw/openclaw` snippet from a third-party blog as upstream-blessed; it isn't. Stick with `./scripts/k8s/deploy.sh` unless the user explicitly chose a community chart.
- **Loopback-bind by default.** `kubectl port-forward` is the access path. A `Service` of type `LoadBalancer` or `ClusterIP` won't work without first switching the bind in the ConfigMap. Symptom: pod healthy but `curl <svc-ip>:18789` hangs.
- **Re-running `deploy.sh` preserves existing Secret keys.** Adding `OPENAI_API_KEY` to a previously Anthropic-only deploy works; both stay in the Secret. Removing a key requires explicit `kubectl patch` (or editing the Secret YAML and re-applying).
- **Single-instance only.** OpenClaw holds local pairing state — replicas would diverge. Don't increase replica count even if the deployment YAML accepts it.
- **`openclaw devices approve` must run in the pod**, not on the user's laptop, because pairing state is in the pod's PVC. The `kubectl exec` line above handles this.
- **No automatic Bedrock IAM.** No equivalent of the Lightsail blueprint's cross-account assume-role. Pass an Anthropic / OpenAI / Gemini / OpenRouter key directly via env vars to `deploy.sh`, or set up IRSA (EKS) / Workload Identity (GKE) yourself.
- **Hardened pod security context.** The pod runs as UID 1000, `readOnlyRootFilesystem: true`, all capabilities dropped. If you customize the image, preserve these or things break.
- **Kind cluster ergonomics.** `./scripts/k8s/create-kind.sh` auto-detects Docker vs Podman; `--delete` tears down. Useful for verifying the deploy flow before pointing at a real managed cluster.

---

## Podman runtime (rootless container alternative to Docker)

When the user picks **any Linux host → Podman**. Pair with [`references/runtimes/podman.md`](../runtimes/podman.md) for rootless setup, Quadlet integration, and SELinux quirks.

Upstream docs: <https://docs.openclaw.ai/install/podman>. The intended model is "Podman runs the container; the host `openclaw` CLI is the control plane via `OPENCLAW_CONTAINER=openclaw`."

### Install

```bash
git clone https://github.com/openclaw/openclaw.git ~/openclaw
cd ~/openclaw
./scripts/podman/setup.sh                 # rootless build + ~/.openclaw seeding
# Optional, for systemd-user auto-start:
./scripts/podman/setup.sh --quadlet
```

`setup.sh` builds `openclaw:local` in the rootless Podman store, creates `~/.openclaw/openclaw.json` with `gateway.mode: "local"`, generates `~/.openclaw/.env` with `OPENCLAW_GATEWAY_TOKEN`, and (with `--quadlet`) installs `~/.config/containers/systemd/openclaw.container`.

### Run

```bash
./scripts/run-openclaw-podman.sh launch          # start the container
./scripts/run-openclaw-podman.sh launch setup    # start + run onboarding inside

# Day-to-day from the host CLI:
export OPENCLAW_CONTAINER=openclaw               # makes openclaw commands target the container
openclaw dashboard --no-open
openclaw gateway status --deep
openclaw doctor
openclaw channels login
```

Quadlet commands (if installed):

```bash
systemctl --user start openclaw.service
systemctl --user status openclaw.service
journalctl --user -u openclaw.service -f
sudo loginctl enable-linger "$(whoami)"          # for boot persistence on headless hosts
```

### Podman-specific gotchas (OpenClaw-only)

- **`OPENCLAW_CONTAINER=openclaw` is the magic env var.** Without it, host `openclaw` commands run on the host (not the container) and act on a non-existent install. Always export it.
- **`openclaw update --container` doesn't work.** Rebuild the image with `setup.sh` (or pull a new tag) and restart the container/Quadlet service instead.
- **macOS Podman machine + browser device-auth.** On macOS, the Podman VM presents the gateway as non-local to the browser, which can fail device-auth checks. Use Tailscale Serve instead of ad hoc local tunnels (see [Podman + Tailscale upstream notes](https://docs.openclaw.ai/install/podman)).
- **SELinux `:Z` is mandatory** on Fedora/RHEL/Amazon Linux. The launch helper auto-adds it; if you script your own `podman run`, don't forget.
- **Quadlet locks down ports to `127.0.0.1:18789` + `127.0.0.1:18790`.** Override only by editing the `.container` file; don't shadow it via the env file.

---

## ClawDock (shell helpers over Docker Compose)

Optional UX layer for Docker-based deploys — short commands like `clawdock-start`, `clawdock-dashboard`, `clawdock-fix-token` instead of long `docker compose ...` lines. Not a separate runtime — it's a shell-helpers wrapper over the existing Docker Compose flow.

Upstream docs: <https://docs.openclaw.ai/install/clawdock>.

### Install

```bash
mkdir -p ~/.clawdock
curl -sL https://raw.githubusercontent.com/openclaw/openclaw/main/scripts/clawdock/clawdock-helpers.sh \
  -o ~/.clawdock/clawdock-helpers.sh
echo 'source ~/.clawdock/clawdock-helpers.sh' >> ~/.zshrc       # or ~/.bashrc
source ~/.zshrc
```

### Use

```bash
clawdock-start            # docker compose up -d
clawdock-status           # status + container ps
clawdock-logs             # docker compose logs -f
clawdock-fix-token        # regenerate gateway token
clawdock-dashboard        # print Control UI URL with token fragment
clawdock-devices          # list paired devices
clawdock-approve          # approve --latest
clawdock-shell            # shell into the gateway container
clawdock-update           # pull latest image
clawdock-rebuild          # rebuild image from source
clawdock-cleanup          # remove containers + volumes (destructive)
clawdock-config           # cat openclaw.json
```

### ClawDock-specific gotchas

- **Helper location moved from `scripts/shell-helpers/` to `scripts/clawdock/`.** Old install commands won't find the file.
- **Helpers wrap `docker compose` (v2) — not `docker-compose` (v1).** If a host has only v1 installed, helpers silently fail. Upgrade to Compose v2.
- **Not exclusive with the host `openclaw` CLI.** You can use both — `clawdock-*` for compose lifecycle, `openclaw` (with `OPENCLAW_CONTAINER=...` set if needed) for everything else.

---

## Ansible — production-hardened native install

For production servers where the gateway runs **directly on the host** (not in a container) with strict security hardening. Upstream maintains a separate repo: [openclaw-ansible](https://github.com/openclaw/openclaw-ansible). The playbook installs Tailscale + UFW + Docker (only as a sandbox backend) + Node 24 + OpenClaw + a hardened systemd unit.

Upstream docs: <https://docs.openclaw.ai/install/ansible>.

### What you get

- **Firewall (UFW)** — only SSH (port 22) + Tailscale (UDP 41641) exposed to the public internet.
- **Tailscale VPN** — gateway accessible only via tailnet.
- **Docker** — installed for **agent sandboxes** (isolated tool execution), not for running the gateway itself.
- **systemd hardening** — `NoNewPrivileges`, `PrivateTmp`, unprivileged `openclaw` user.
- **Defense in depth** — UFW + Tailscale + Docker isolation + systemd hardening = 4 layers.

### Install

```bash
# One-command install on a Debian 11+ / Ubuntu 20.04+ host
curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw-ansible/main/install.sh | bash
```

That bootstraps Ansible itself if missing, then runs the playbook.

For manual control:

```bash
sudo apt-get update && sudo apt-get install -y ansible git
git clone https://github.com/openclaw/openclaw-ansible.git
cd openclaw-ansible
ansible-galaxy collection install -r requirements.yml
./run-playbook.sh                                                 # idempotent
```

### Post-install

```bash
sudo -i -u openclaw                                               # switch to the dedicated user
openclaw onboard                                                  # interactive: model provider + API key
openclaw channels login                                           # connect WhatsApp / Telegram / Discord / Signal

sudo systemctl status openclaw                                    # daemon running?
sudo journalctl -u openclaw -f                                    # live logs
```

Then join the user's tailnet (`tailscale up`) on a second device — the gateway is reachable only via Tailscale by design.

### Ansible-specific gotchas (OpenClaw-only)

- **Gateway runs as `openclaw` user, NOT as a system service or root.** Provider login (`openclaw channels login`) must run as that user: `sudo -i -u openclaw`.
- **No public ingress at all.** UFW blocks everything except SSH + Tailscale. If you can't reach the gateway, you're not on the tailnet — `tailscale status` is the first check.
- **Docker is for sandboxes only.** The playbook installs Docker but does **not** run the gateway in a container. Don't conflate this with the Docker runtime — different deploy.
- **`./run-playbook.sh` is idempotent.** Safe to re-run for config changes; it won't break a working install.
- **Verify external attack surface.** `nmap -p- <server-ip>` should return only port 22 open (and Tailscale's UDP isn't TCP-scannable).

---

## Nix — declarative, rollback-able install

For users on NixOS, Home Manager, or Determinate Nix. Upstream maintains a Home Manager module: [nix-openclaw](https://github.com/openclaw/nix-openclaw). Installs the gateway + macOS app + tools (whisper, spotify, cameras), pinned to specific versions, with launchd integration on macOS and instant rollback via `home-manager switch --rollback`.

Upstream docs: <https://docs.openclaw.ai/install/nix>.

### Install

```bash
# Install Determinate Nix if not present:
curl -fsSL https://install.determinate.systems/nix | sh

# Bootstrap a local flake from the upstream template:
mkdir -p ~/code/openclaw-local
# Copy templates/agent-first/flake.nix from https://github.com/openclaw/nix-openclaw
# Configure secrets at ~/.secrets/ (plain files work)
# Fill in placeholders in the flake, then:
home-manager switch
```

The module installs the launchd service that survives reboots; verify by `launchctl list | grep openclaw`.

### Nix-mode runtime behavior

When `OPENCLAW_NIX_MODE=1` is set (auto via nix-openclaw, or manually via `export OPENCLAW_NIX_MODE=1` / on macOS `defaults write ai.openclaw.mac openclaw.nixMode -bool true`):

- Auto-install + self-mutation flows are **disabled**.
- Missing dependencies surface Nix-specific remediation messages.
- The UI shows a read-only "Nix mode" banner.

### Nix-specific gotchas (OpenClaw-only)

- **Source of truth lives in `nix-openclaw`, not `openclaw`.** Module updates don't necessarily track openclaw releases 1:1 — read both repos' release notes when upgrading.
- **`OPENCLAW_STATE_DIR` and `OPENCLAW_CONFIG_PATH` should be Nix-managed** — never default into the immutable Nix store. The module sets these to writable paths under `~/.openclaw` by default.
- **Launchd PATH discovery via `NIX_PROFILES`.** The service auto-adds every entry in `NIX_PROFILES` to its PATH (right-to-left precedence). Plugins that shell out to nix-installed binaries work without manual PATH wrangling.
- **Rollback is your safety net.** A bad config can `home-manager switch --rollback` you back to a known-good state in seconds. Use it.

---

## Bun runtime (experimental, dev-only)

Bun is a faster JavaScript runtime + bundler. OpenClaw upstream supports Bun for **local development** (`bun run`, `bun --watch`) but explicitly recommends **against** using Bun for the gateway runtime in production. WhatsApp + Telegram channels have known issues under Bun.

Upstream docs: <https://docs.openclaw.ai/install/bun>.

```bash
# Inside an openclaw checkout:
bun install
bun run build
bun run vitest run

# If lifecycle scripts are blocked:
bun pm trust @whiskeysockets/baileys protobufjs
```

`pnpm-lock.yaml` is ignored by Bun — `bun.lock` is gitignored too, so no repo churn. Some scripts (`docs:build`, `ui:*`, `protocol:check`) hardcode pnpm; run those via pnpm even when otherwise on Bun.

### Bun-specific gotchas

- **Don't use Bun for the gateway in production.** Stick to Node 24 (or Node 22.14+).
- **Bun's lockfile mode differs from pnpm.** Don't expect `bun install` to read `pnpm-lock.yaml` — it doesn't.
- **Lifecycle script trust.** Some upstream deps (Baileys, protobufjs) have lifecycle scripts Bun blocks by default. The `bun pm trust` line above unblocks them.

---

## Per-cloud / per-PaaS pointers

The combo table at the top of this file already lists every (where × how) combination. For deployment paths beyond AWS Lightsail / Docker / Native / Kubernetes / Podman / ClawDock / Ansible / Nix / Bun, see the dedicated infra adapter:

| Where | Adapter / recipe |
|---|---|
| AWS EC2 | [`references/infra/aws/ec2.md`](../infra/aws/ec2.md) — runtime: Docker or native |
| Azure VM (Bastion-hardened) | [`references/infra/azure/vm.md`](../infra/azure/vm.md) — runtime: Docker or native |
| Hetzner Cloud (CX) | [`references/infra/hetzner/cloud-cx.md`](../infra/hetzner/cloud-cx.md) — runtime: Docker or native |
| DigitalOcean Droplet | [`references/infra/digitalocean/droplet.md`](../infra/digitalocean/droplet.md) — runtime: Docker or native |
| GCP Compute Engine | [`references/infra/gcp/compute-engine.md`](../infra/gcp/compute-engine.md) — runtime: Docker or native |
| Oracle Cloud (Always-Free ARM) | [`references/infra/oracle/free-tier-arm.md`](../infra/oracle/free-tier-arm.md) — Tailscale-only access |
| Hostinger (managed or VPS) | [`references/infra/hostinger.md`](../infra/hostinger.md) — browser-driven via hPanel |
| Raspberry Pi | [`references/infra/raspberry-pi.md`](../infra/raspberry-pi.md) — ARM64 always-on home host |
| macOS VM (Lume on Apple Silicon) | [`references/infra/macos-vm.md`](../infra/macos-vm.md) — for iMessage via BlueBubbles |
| Linux Server / BYO VPS (Vultr, Linode, on-prem, etc.) | [`references/infra/byo-vps.md`](../infra/byo-vps.md) — catch-all |
| **Fly.io** | [`references/infra/paas/fly.md`](../infra/paas/fly.md) — `fly.toml` + persistent volume; public or private mode |
| **Render** | [`references/infra/paas/render.md`](../infra/paas/render.md) — `render.yaml` Blueprint, one-click |
| **Railway** | [`references/infra/paas/railway.md`](../infra/paas/railway.md) — one-click template, browser-driven |
| **Northflank** | [`references/infra/paas/northflank.md`](../infra/paas/northflank.md) — one-click stack |
| **exe.dev** | [`references/infra/paas/exe-dev.md`](../infra/paas/exe-dev.md) — Shelley agent or manual |

Each adapter handles infra-level provisioning + access; once SSH/console works, the **Docker runtime**, **Native installer**, or **Kubernetes** sections of this file (or `runtimes/podman.md`, etc.) take over for the openclaw install.

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

Per-method gotchas live alongside each section above:

- **AWS Lightsail blueprint** — see *Blueprint gotchas* in the Lightsail section.
- **Docker runtime** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Native installers** (`install.sh` / `install-cli.sh` / `install.ps1`) — see *Native-specific gotchas* + `runtimes/native.md` § *Common gotchas*.
- **Kubernetes** (Kustomize) — see *Kubernetes-specific gotchas* + `runtimes/kubernetes.md` § *Common gotchas*.
- **Podman** — see *Podman-specific gotchas* + `runtimes/podman.md` § *Common gotchas*.
- **ClawDock / Ansible / Nix / Bun** — see the per-method sections above.
- **Per-cloud / per-PaaS** — see each adapter's *Gotchas* section under `references/infra/`.

---

## TODO — verify on subsequent deployments

- Exact `api` string and model ID format for non-Bedrock providers when editing config directly via `jq`.
- Whether `openclaw configure` has non-interactive flags (so model swap can be scripted).
- Behavior when both Bedrock and a non-Bedrock provider are configured simultaneously.
- Native installer on macOS (only exercised on Linux so far).
- Native installer on **Windows (`install.ps1`)** — never exercised; Scheduled-Task autostart, PATH after install, and `iwr | iex` failure modes are documented from upstream but unverified by open-forge.
- Native **`install-cli.sh`** local-prefix mode — never exercised end-to-end.
- **Docker runtime** end-to-end (verified commands only; first full deploy will surface gotchas to fold back here).
- **Kubernetes (Kustomize)** end-to-end — open questions for the first real cluster deploy:
  - Whether `./scripts/k8s/deploy.sh --create-secret` followed by `./scripts/k8s/deploy.sh` is the standard re-run pattern when adding new provider keys.
  - Whether the bundled Service binds to a non-loopback by default in any updated upstream version (current docs say loopback).
  - PVC reclaim behavior on `./scripts/k8s/deploy.sh --delete` vs `kubectl delete namespace openclaw` (script should delete the PVC; upstream says "deletes namespace and all resources in it").
  - Whether `openclaw backup create` works inside the pod against the mounted PVC.
- **Podman runtime** end-to-end — Quadlet-managed flow, `OPENCLAW_CONTAINER` interaction with multi-container setups, `podman machine` on macOS.
- **Ansible** path end-to-end — UFW + Tailscale + Docker-sandbox-only + systemd hardening combo from `openclaw-ansible` repo.
- **Nix** path on Linux (only macOS+Home Manager covered upstream); `OPENCLAW_NIX_MODE=1` interaction with our state file.
- **PaaS adapters** — Fly.io, Render, Railway, Northflank, exe.dev all written from upstream docs only; first real deploy on each will surface gotchas. Specifically:
  - Whether `OPENCLAW_GATEWAY_PORT` overrides on Render survive Blueprint sync.
  - Whether Railway's auto-generated `*.up.railway.app` requires re-setting `controlUi.allowedOrigins` on every redeploy.
  - exe.dev nginx config WebSocket timeout interaction with very long-running plugin operations.
  - Whether `fly.private.toml` deploy correctly skips public IP allocation on first deploy (vs requiring the post-hoc `fly ips release` dance).
- **Cloud-VM adapters** (Azure, Oracle) — both written from upstream docs but unexercised. Azure Bastion provisioning timing, Oracle "Out of capacity" workarounds.
- **macOS VM (Lume)** path — Setup Assistant scripting (currently manual VNC), BlueBubbles webhook origin verification, golden-image clone vs fresh-create cost trade-off.
- **Hostinger** managed flow — open-forge can't drive it; verify the user-facing checklist actually works on the latest hPanel UI.
