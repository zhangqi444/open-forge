---
name: openclaw-project
description: OpenClaw recipe for open-forge — a self-hosted personal AI agent. Primary path uses the official AWS Lightsail "OpenClaw" blueprint (blueprintId openclaw_ls_1_0), which auto-wires Amazon Bedrock via cross-account role assumption (no CloudShell IAM script needed). Includes a follow-on step to switch the model provider to Anthropic, OpenAI, Google, or local.
---

# OpenClaw

OpenClaw is a self-hosted personal AI agent with web browsing, file access, shell execution, and optional messaging-app connectors.

## Inputs to collect

After preflight (which gathers AWS profile / region / deployment name), OpenClaw-specific prompts. Most users on Path A need to answer **just one question** — everything else has sensible defaults.

| Phase | Prompt | Tool / format | Notes |
|---|---|---|---|
| preflight | "Which path?" | `AskUserQuestion`, options: `A — Lightsail OpenClaw blueprint (AWS, Bedrock pre-wired)` / `B — Stock Ubuntu + curl installer (any provider, no Docker)` / `C — Docker container on any Linux VPS (any provider, easy upgrades)` | Default A for AWS users; suggest C for non-AWS hosts. |
| provision (if Path A) | none | — | Bedrock model defaults to `claude-sonnet-4-6` via cross-account role; IAM script run autonomously (see below). |
| provision (if Path B or C) | "Which model provider?" | `AskUserQuestion`, options: `Anthropic` / `OpenAI` / `Google` / `Local` | Selected provider's API key prompted next |
| provision (if Path B or C) | "API key for `<provider>`?" | Free-text (sensitive) | Skipped for `Local`. Pasted into `openclaw onboard` interactive flow, not chat-logged |
| provision (if Path C, optional) | "Enable agent sandboxing? (each tool execution runs in a separate Docker container — adds overhead, stronger isolation)" | `AskUserQuestion`, options: `Yes` / `No` | Sets `OPENCLAW_SANDBOX=1` before `setup.sh`. See *Path C — Docker container* below. |
| (optional) hardening | "Switch from Bedrock to a different model provider?" | `AskUserQuestion`, options: `Stay with Bedrock` / `Anthropic direct` / `OpenAI` / `Google` / `Local` | Only asked after the happy-path Bedrock chat is verified working |
| (optional) hardening | "API key for `<provider>`?" | Free-text (sensitive) | Same as Path B prompt |
| (optional, only for messaging webhooks) dns | "Custom domain for messaging-app webhooks?" | Free-text (or `Skip`) | Only needed for Telegram/Discord/Slack/WhatsApp inbound; not for chat UI access |
| (optional) tls | "Email for Let's Encrypt expiration notices?" | Free-text | Only if a domain was given |

After each prompt, write into the state file under `inputs.*` so a resume can skip re-asking.

The `smtp` and `inbound` phases are always skipped for OpenClaw (no transactional email; messaging integrations have their own webhook channels).

## Blueprint architecture (Path A)

The Lightsail OpenClaw blueprint ships with:

- A **Node-based gateway** (process: `openclaw-gateway`) running as a **systemd user unit** (`openclaw-gateway.service` under user `ubuntu`) on `127.0.0.1:18789`.
- **Apache 2.4** as a TLS-terminating reverse proxy on ports 80 (→ 301 to https) and 443 (snakeoil self-signed cert), proxying to the gateway and supporting WebSocket upgrade.
- **Bedrock pre-wired** via cross-account role assumption to AWS account `654654373986` (AWS-owned, hosts the models for this blueprint). Default model: `bedrock/global.anthropic.claude-sonnet-4-6` (Claude Sonnet 4.6).
- A daily **token-rotation timer** (`openclaw-rotate-token.timer` at 03:00 UTC).

There is **no `openclaw-gateway` system unit**; the gateway is installed as a systemd `--user` unit by `openclaw gateway install`, with `loginctl enable-linger ubuntu` so it survives no-login sessions.

## Three deployment paths

| Path | When |
|---|---|
| **A. Official Lightsail OpenClaw blueprint** (default for AWS users) | Happy path on AWS — fastest to a working chat UI. Bedrock pre-wired via cross-account role. Apache + snakeoil HTTPS pre-installed. |
| **B. Stock Ubuntu + official curl installer** | Native install on any Linux box. Pick if you specifically don't want Bedrock, AWS cross-account role baggage, or the snakeoil-cert HTTPS setup. |
| **C. Docker container on any Linux VPS** | Containerized — clean isolation, easy upgrades (`git pull && setup.sh`), runs anywhere with Docker (Lightsail Ubuntu, Hetzner, DigitalOcean, GCP, etc.). Recommended for production / non-AWS hosts. |

This recipe leads with Path A. Paths B and C live at the end.

---

## Path A — Official Lightsail OpenClaw blueprint

### Resolve the blueprint ID

```bash
aws lightsail get-blueprints \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --query 'blueprints[?contains(name, `OpenClaw`) || contains(name, `openclaw`)].[name,blueprintId,platform,isActive,minPower]' \
  --output table
```

Confirmed value (us-east-1, as of 2026-04-22): **`blueprintId = openclaw_ls_1_0`**, `minPower = 1000`. Save to `outputs.blueprint_id`.

### Bundle

| Field | Value |
|---|---|
| `bundle_id` | `medium_3_0` (4 GB RAM — the AWS blog's recommended minimum, and it satisfies `minPower=1000`) |

### SSH user

**`ubuntu`** (Ubuntu 24.04 LTS underneath).

### Provisioning

Standard Lightsail create / static-IP / attach — see `references/infra/lightsail.md`. First boot's cloud-init runs `/opt/aws/open_claw/install_open_claw.sh`, which generates the auth token, installs and starts the gateway, enables Apache, and generates a snakeoil cert. Allow ~3–5 min after `state==running` before the gateway is fully responsive.

After the gateway is healthy, run these blueprint-cleanup steps:

```bash
# 1. Open port 22 (blueprint defaults it to lightsail-internal CIDRs only)
#    — see "Firewall" section below for the full put-instance-public-ports call

# 2. Patch allowedOrigins for the static IP
#    — see "allowedOrigins is baked with the dynamic IP" section below

# 3. Disable AWS-added daily token rotation timer (not upstream behavior, broken)
ssh "$INSTANCE" 'sudo systemctl disable --now openclaw-rotate-token.timer'

# 4. Run the AWS-published Bedrock IAM setup script (autonomous — uses your AWS profile)
#    — see "IAM for Bedrock — required setup script" below for the curl-piped one-liner.
#    WITHOUT THIS, model calls fail with AssumeRole AccessDenied even though the chat UI loads.
```

### ⚠️ Firewall: port 22 is locked down by default

Unlike every other Lightsail blueprint, the OpenClaw blueprint defaults port 22 to Lightsail-internal CIDR aliases only (`lightsail-connect`, `lightsail-setup-*`) — **not** `0.0.0.0/0`. Direct SSH from your machine fails with a connection timeout until you open it.

Open 22 + reaffirm 80/443:

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

### ⚠️ allowedOrigins is baked with the dynamic IP, not the static IP

The cloud-init install script reads the **dynamic** public IP from EC2 metadata and writes it into `~/.openclaw/openclaw.json` under `gateway.controlUi.allowedOrigins`. If you allocate + attach a static IP **after** provisioning (which you will — Lightsail static IPs require an existing instance to attach to), the baked origin is now stale and the browser's Origin header (`https://<static-ip>`) will be rejected by the gateway's CORS check. Symptom: the page loads from Apache but the WebSocket immediately fails with "pairing required" or just hangs.

Fix on every provision (do this right after attaching the static IP):

```bash
ssh -i "$KEY_PATH" ubuntu@"$PUBLIC_IP" 'bash -s' <<EOF
set -e
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.preforge
jq '.gateway.controlUi.allowedOrigins = ["http://localhost:18789","http://127.0.0.1:18789","https://${PUBLIC_IP}"]' \
  ~/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/openclaw.json
openclaw gateway restart
EOF
```

If you also have a custom domain, include `https://<domain>` in the array.

### IAM for Bedrock — required setup script

The blueprint pre-bakes the *intent* — `/opt/aws/open_claw/target_account_id` (= **your own AWS account ID**, auto-detected at first boot), `~/.aws/config` configured with `[profile assumed]` pointing at `arn:aws:iam::<your-account>:role/LightsailRoleFor-<instance-id>`, and `AWS_PROFILE=assumed` in `/opt/aws/open_claw/openclaw.env` — but the IAM role itself doesn't exist yet. A one-time setup script must create it.

**Until the setup script runs, the gateway starts and the Control UI loads, but every model call fails with:**

```
sts:AssumeRole on resource: arn:aws:iam::<your-account>:role/LightsailRoleFor-<instance-id>
... is not authorized
```

Important account details (educational; surprised me on first run):

- Lightsail instances run on EC2 underneath in a **Lightsail-internal AWS account** (e.g. `592667671527`), with instance role `AmazonLightsailInstance/<instance-id>`.
- The Bedrock IAM role is created in **your AWS account** (the one your `qi-experiement`-style profile authenticates to).
- The trust policy lets the Lightsail-internal account's instance role assume the role in your account. Cross-account, but both ends are tied to your specific instance ID.

#### The script — automatable, no console required

AWS publishes the script at a stable URL, despite their own docs implying it's only available via the console:

```
https://d25b4yjpexuuj4.cloudfront.net/scripts/lightsail/setup-lightsail-openclaw-bedrock-role.sh
```

It takes `<instance-name> <region>` as args and uses your AWS profile's credentials to:

1. Look up the instance's `supportCode` to extract the Lightsail-internal account + EC2 instance ID.
2. Create (or update) IAM role `LightsailRoleFor-<instance-id>` in your account.
3. Set the trust policy so the instance can assume it.
4. Attach Bedrock + AWS Marketplace permissions (`bedrock:InvokeModel*`, `aws-marketplace:Subscribe/Unsubscribe/ViewSubscriptions`).

The script is idempotent — re-running updates trust policy + permissions, deletes nothing.

**open-forge can run this autonomously** during the `provision` phase, no console hand-off required:

```bash
curl -fsSL https://d25b4yjpexuuj4.cloudfront.net/scripts/lightsail/setup-lightsail-openclaw-bedrock-role.sh \
  | AWS_PROFILE="$AWS_PROFILE" bash -s -- "$INSTANCE_NAME" "$AWS_REGION"
```

Required permissions on `$AWS_PROFILE`: `iam:CreateRole`, `iam:PutRolePolicy`, `iam:UpdateAssumeRolePolicy`, `iam:GetRole`, `lightsail:GetInstance`, `sts:GetCallerIdentity`.

#### Verify

IAM changes take a few seconds to propagate. After running, sleep ~5–10s then:

```bash
ssh "$INSTANCE" 'AWS_PROFILE=assumed aws sts get-caller-identity'
# Should print an Arn under your account ID with the LightsailRoleFor-<instance-id> role,
# NOT AccessDenied.
```

Only after this verification passes is `provision` complete. Send a test chat message to confirm Bedrock actually responds end-to-end.

### Auth token — locations and gotchas

There are **three** places a token may appear, and only one is authoritative:

| Path | Authoritative? | Notes |
|---|---|---|
| `~/.openclaw/openclaw.json` → `.gateway.auth.token` | ✅ **YES** — what the gateway uses | Updated on rotation |
| `/opt/aws/open_claw/credentials.log` | ❌ NO — installer-set, **stale after first rotation** | Don't read this; mislabeled |
| `openclaw dashboard` (CLI) | ✅ — prints the live token in a URL fragment | Best UX for handing the user a one-click link |

Read the live token (the only one that works):

```bash
ssh "$INSTANCE" "jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json"
```

Or get the dashboard URL:

```bash
ssh "$INSTANCE" 'openclaw dashboard'
# Prints: http://127.0.0.1:18789/#token=<TOKEN>
```

**Tokens are URL fragments, not query strings.** Apache's vhost explicitly blocks `?token=` query strings (`RewriteCond %{QUERY_STRING} (^|&)token= [F,L]`). Use `https://<host>/#token=<TOKEN>` — fragments stay client-side.

### Token rotation — disable the AWS-added timer

The Lightsail blueprint installs `/usr/local/bin/openclaw-rotate-token` (a 2.6 MB ELF binary, AWS-specific — not part of upstream OpenClaw) plus an `openclaw-rotate-token.timer` systemd unit that fires daily at 03:00 UTC. **This is not upstream OpenClaw behavior** — upstream has no gateway-token-rotation feature; only manual per-device token rotation via `openclaw devices rotate`.

In v2026.3.23 the AWS rotation flow is **broken in two ways**:

1. The "sync gateway token" step exits with `signal: killed` (likely OOM — peaks ~340 MB on top of the ~280 MB gateway). The token doesn't actually change.
2. The script reinstalls the systemd user unit anyway, which **wipes the paired-device table**. Result: you get locked out every morning even though no rotation happened.

**Default for open-forge: disable the timer**, restoring upstream OpenClaw behavior.

```bash
ssh "$INSTANCE" 'sudo systemctl disable --now openclaw-rotate-token.timer'
```

Run this once during the `provision` phase, after the gateway is verified healthy.

#### Manual rotation (when you need it)

If a token leaks (chat, logs, screenshot), rotate immediately. Two options:

**Recommended — match upstream pattern: regenerate the token in the config and restart the gateway.**

```bash
ssh "$INSTANCE" 'bash -s' <<'EOF'
NEW=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 32)
jq --arg t "$NEW" '.gateway.auth.token = $t' ~/.openclaw/openclaw.json > /tmp/oc.json
mv /tmp/oc.json ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/openclaw.json
openclaw gateway restart
echo "New token (first 6): ${NEW:0:6}…"
EOF
```

Already-paired devices keep working (per-device tokens are independent of the gateway bootstrap token).

**Not recommended — `sudo /usr/local/bin/openclaw-rotate-token`** — even if you accept the risks above, sudo loses the user's DBUS so the auto-restart fails (`Failed to connect to bus: No medium found`). You'd have to manually restart anyway.

### Browser pairing

OpenClaw uses a **two-layer auth model**:

1. **Gateway token** — bootstrap secret. Identifies you as someone who knows the gateway's secret.
2. **Device pairing** — every browser fingerprint must be explicitly approved before the gateway accepts WebSocket traffic from it. Different browsers / private windows / fresh fingerprints each generate a new pairing request.

Pairing flow:

1. User opens `https://<public-ip>/#token=<TOKEN>` (or via SSH tunnel; see below).
2. The browser registers a pending pairing request, identified by a device fingerprint hash.
3. The Control UI displays "**pairing required**" until approved.
4. From SSH:

   ```bash
   TOKEN=$(jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json)
   openclaw devices list   --token "$TOKEN"
   openclaw devices approve --latest --token "$TOKEN"
   ```

5. User refreshes the browser tab. Chat UI loads.

Notes:

- Approve via `--latest`, not by request ID. Request IDs change on every browser refresh, so a stored ID is usually stale. (Symptom of stale ID: `unknown requestId`.)
- The `--token` flag is required because the CLI itself isn't paired ("gateway connect failed: pairing required ... Direct scope access failed; using local fallback"). The "local fallback" via the token works.
- IP is captured for some pairing requests but not others — likely depends on how the browser opened the connection (websocket vs initial HTTP). Don't rely on filtering by IP.
- Each new browser session/profile = new fingerprint = new approval. After approval the device persists in the paired list across token rotations.

### Access path A — public HTTPS (what the blueprint expects)

```
https://<PUBLIC_IP>/#token=<TOKEN>
```

Browser will warn about the snakeoil self-signed cert (`/etc/ssl/certs/ssl-cert-snakeoil.pem`). Click through (Advanced → Proceed) once per browser session. To avoid the warning permanently, attach a real domain + Let's Encrypt cert (see *Optional: public HTTPS with a real cert*).

### Access path B — SSH tunnel (no cert warning)

```bash
ssh -i "$KEY_PATH" -L 18789:127.0.0.1:18789 ubuntu@"$PUBLIC_IP"
# In a separate terminal / browser:
# http://localhost:18789/#token=<TOKEN>
```

The tunnel reaches the gateway directly, bypassing Apache. Same pairing flow applies.

`~/.ssh/config` shortcut:

```
Host openclaw
  HostName <PUBLIC_IP>
  User ubuntu
  IdentityFile ~/.ssh/lightsail-default.pem
  LocalForward 18789 127.0.0.1:18789
```

### Verification before marking `provision` done

- `aws lightsail get-instance ...` → state `running`
- `aws lightsail get-static-ip ... --query 'staticIp.isAttached'` → `True`
- Direct SSH succeeds: `ssh ubuntu@<PUBLIC_IP> 'systemctl --user is-active openclaw-gateway'` → `active`
- Local probe: `curl -sI http://127.0.0.1:18789/` → `200 OK` (run from the instance)
- Public probe: `curl -skI https://<PUBLIC_IP>/` → `200 OK` (snakeoil cert, accept)
- Browser pairs successfully and the chat UI loads
- One test message round-trips — confirms Bedrock reachability

---

## Switching the model provider (after the happy path works)

Once Bedrock is verified, swap to Anthropic / OpenAI / Google / local. Two approaches:

### Option 1 — interactive `openclaw configure`

```bash
ssh ubuntu@"$PUBLIC_IP"
openclaw configure   # interactive: pick provider, paste API key
openclaw gateway restart
```

### Option 2 — direct config edit

The model config lives in two places that need to stay in sync:

- `~/.openclaw/openclaw.json` — `.models.providers.<name>` and `.agents.defaults.model.primary`
- `~/.openclaw/agents/main/agent/models.json` — `.providers.<name>` (per-agent override)

Bedrock entry shape (example):

```json
"models": {
  "providers": {
    "bedrock": {
      "baseUrl": "https://bedrock-runtime.us-east-1.amazonaws.com",
      "apiKey": "...",
      "api": "bedrock-converse-stream",
      "models": [{ "id": "global.anthropic.claude-sonnet-4-6", "name": "Claude Sonnet 4.6", ... }]
    }
  }
}
```

For Anthropic direct, replace with:

```json
"anthropic": {
  "baseUrl": "https://api.anthropic.com",
  "apiKey": "<sk-ant-...>",
  "api": "anthropic-messages",
  "models": [{ "id": "claude-sonnet-4-6", "name": "Claude Sonnet 4.6", ... }]
}
```

Then update `.agents.defaults.model.primary` to `anthropic/claude-sonnet-4-6`. **TODO — verify the exact `api` string and model ID format on first non-Bedrock run.**

After the swap:

- The cross-account IAM assumption + `AWS_PROFILE=assumed` env var become unused but harmless.
- The Bedrock provider entry can stay (multiple providers can coexist).

Verify in the provider's dashboard that requests are now hitting them, not Bedrock.

---

## Phase applicability

| Phase | Applies? | Notes |
|---|---|---|
| preflight | ✅ | Resolve blueprint ID, collect inputs, confirm region has the blueprint |
| provision | ✅ | Includes opening port 22 + patching allowedOrigins for static IP |
| dns | ⚠️ skip by default | Only needed for messaging webhooks or to ditch the snakeoil cert |
| tls | ⚠️ skip by default | Same — needed only with a real domain (see optional section below) |
| smtp | ❌ skip | OpenClaw does not send transactional email |
| inbound | ❌ skip | Messaging integrations use their own webhook channels |
| hardening | ✅ | Rotate gateway token, prune unused paired devices, optionally re-restrict port 22 to your IP |

---

## Optional: public HTTPS with a real cert + custom domain

For messaging-app webhooks (Telegram / Discord / Slack / WhatsApp) or to drop the cert warning, attach a real domain.

1. Run the `dns` phase (A record `<domain>` → static IP).
2. Replace the snakeoil cert path in `/etc/apache2/sites-enabled/default-ssl.conf` with a Let's Encrypt cert. Easiest: install certbot's Apache plugin:

   ```bash
   sudo apt-get install -y certbot python3-certbot-apache
   sudo certbot --apache -d <domain> --agree-tos -m <email> -n
   ```

3. Add the domain to `gateway.controlUi.allowedOrigins`:

   ```bash
   jq '.gateway.controlUi.allowedOrigins += ["https://<domain>"]' \
     ~/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/.openclaw/openclaw.json
   openclaw gateway restart
   ```

4. Done — `https://<domain>/#token=<TOKEN>` works without a warning.

**Do not weaken the gateway token or device pairing** once the UI is reachable from the internet. Without both layers, anyone hitting the URL controls the agent.

---

## Path B — Stock Ubuntu + official curl installer

Pick this only if you specifically don't want Bedrock or the AWS-specific cross-account setup.

- Blueprint: `ubuntu_22_04` (or `ubuntu_24_04` if available)
- Bundle: `medium_3_0` (4 GB)
- SSH user: `ubuntu`

```bash
sudo apt-get update && sudo apt-get install -y curl build-essential
curl -fsSL https://openclaw.ai/install.sh | bash
exec $SHELL -l
openclaw --version
openclaw onboard --install-daemon   # interactive: pick provider, paste API key
openclaw gateway status
```

Access via SSH tunnel by default. No Apache pre-installed; if you want a public HTTPS endpoint, add Caddy or certbot/Apache yourself.

---

## Path C — Docker container on any Linux VPS

Containerized deployment using OpenClaw's official Dockerfile + docker-compose + `setup.sh`. Works on any infra that gives you a Linux VM with Docker — Lightsail Ubuntu, Hetzner CX-line, DigitalOcean droplets, GCP Compute Engine, EC2, etc. Upstream docs: [docker](https://docs.openclaw.ai/install/docker) and [docker-vm-runtime](https://docs.openclaw.ai/install/docker-vm-runtime).

### When to pick Path C over Path B

- **You want easy upgrades** — `git pull && bash scripts/docker/setup.sh` re-pulls/rebuilds and restarts cleanly. Path B's curl installer drops files all over the host.
- **You want container isolation** — config + workspace are bind-mounted host dirs; the rest of the image is throwaway. Easier to wipe and redeploy.
- **You want sandboxed agent tool execution** (`OPENCLAW_SANDBOX=1`) — runs each agent's exec calls in a separate Docker container.
- **You're not on Lightsail at all** — Hetzner / DigitalOcean / your own hardware.

### VPS sizing

- **Minimum**: 2 vCPU, 4 GB RAM, 20 GB disk. Image build's `pnpm install` step OOMs below ~2 GB free.
- **Recommended**: 4 GB RAM (matches the Lightsail blueprint baseline).
- ARM works — set `OPENCLAW_VARIANT=slim` and use ARM-native binaries per [docker-vm-runtime](https://docs.openclaw.ai/install/docker-vm-runtime).

### Prerequisites on the VPS

```bash
# Docker engine + compose v2 (Ubuntu/Debian — adjust per OS)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"   # log out + in for group change to apply
docker compose version            # confirm compose v2 plugin present
```

### Install

Over SSH to the target VPS:

```bash
git clone https://github.com/openclaw/openclaw.git ~/openclaw
cd ~/openclaw
bash scripts/docker/setup.sh
```

What `setup.sh` does (summarized — see `scripts/docker/setup.sh` for the full flow):

1. Validates Docker + Compose, builds (or pulls) the OpenClaw image.
2. Seeds bind-mount dirs at `~/.openclaw/` and `~/.openclaw/workspace/`.
3. Generates a gateway token (or reuses an existing one from `~/.openclaw/openclaw.json` / `.env`).
4. Runs `openclaw onboard --mode local --no-install-daemon` interactively — **pause autonomous mode here**, the user pastes their model provider + API key.
5. Pins `gateway.mode=local` and `gateway.bind=$OPENCLAW_GATEWAY_BIND` (default `lan`) in the config.
6. `docker compose up -d openclaw-gateway`.
7. Prints the gateway token, config dir, and useful follow-up commands.

The build is slow first time (~5–10 min on a 4 GB VPS); subsequent runs reuse the BuildKit cache.

### Useful environment variables (set before running setup.sh)

| Variable | Default | Purpose |
|---|---|---|
| `OPENCLAW_GATEWAY_BIND` | `lan` | `loopback` (only via tunnel) / `lan` (any iface) / `tailnet` (Tailscale) |
| `OPENCLAW_GATEWAY_PORT` | `18789` | Host-mapped gateway port |
| `OPENCLAW_BRIDGE_PORT` | `18790` | Host-mapped bridge port |
| `OPENCLAW_IMAGE` | `openclaw:local` | Set to a registry image to pull instead of build |
| `OPENCLAW_SANDBOX` | unset | `1` to enable Docker-isolated agent tool execution |
| `OPENCLAW_TZ` | `UTC` | IANA timezone string (e.g. `Asia/Shanghai`) |
| `OPENCLAW_HOME_VOLUME` | unset | Use a named volume instead of `$HOME/.openclaw` bind mount |

All of these get persisted to `~/openclaw/.env` after the first setup run, so re-running `setup.sh` reuses them.

### Firewall

Open port `18789` only if you intend to expose the gateway directly on the public IP. Default and safer: keep it closed and reach the gateway via SSH tunnel. For Lightsail Ubuntu hosts, see `references/infra/lightsail.md`'s `put-instance-public-ports` example. For Hetzner / DigitalOcean / etc., use the provider's firewall UI or `ufw`.

### Access — same as Path A/B

- **SSH tunnel** (default): `ssh -L 18789:127.0.0.1:18789 <user>@<vps-ip>` then open `http://localhost:18789/#token=<TOKEN>`.
- **Direct over LAN/WAN**: `http://<vps-ip>:18789/#token=<TOKEN>` if port 18789 is open.
- **Behind a TLS reverse proxy** (recommended for public exposure): see *Optional: public HTTPS with a real cert + custom domain* above. Caddy → `localhost:18789`. Add `https://<domain>` to `gateway.controlUi.allowedOrigins`.

Pairing approval is the same as Path A — `openclaw devices approve --latest --token "$TOKEN"` from inside the container:

```bash
cd ~/openclaw
docker compose run --rm openclaw-cli devices approve --latest \
  --token "$(jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json)"
```

### Daemon control

```bash
cd ~/openclaw
docker compose ps                              # running services
docker compose logs -f openclaw-gateway        # live logs
docker compose restart openclaw-gateway        # restart
docker compose down                            # stop everything
docker compose up -d openclaw-gateway          # start again
docker compose exec openclaw-gateway node dist/index.js health \
  --token "$(jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json)"
```

### Upgrades

```bash
cd ~/openclaw
git pull
bash scripts/docker/setup.sh   # rebuilds image + restarts; keeps token + config
```

The bind-mounted `~/.openclaw/` survives. Image cache is reused unless the Dockerfile changed.

### Gotchas (Docker-specific)

- **OOM during image build** on small VMs — script uses `NODE_OPTIONS=--max-old-space-size=2048` to mitigate, but ≤2 GB RAM still fails. Resize up before retrying.
- **`group_add` for sandbox** needs the host's docker socket GID. `setup.sh` autodetects via `stat -c '%g' /var/run/docker.sock`.
- **Bind-mount permissions**: setup.sh runs a one-shot root container to `chown` the config dir to uid 1000 (the container's `node` user). On rare hosts (rootless Docker, NFS bind mounts), this can fail — check container logs for `EACCES`.
- **Re-running `setup.sh` after editing config**: the script may overwrite `gateway.mode` and `gateway.bind` to its defaults. If you've intentionally changed those, re-apply after.
- **No automatic Bedrock**: Path C does not have the AWS cross-account role assumption. Don't use Bedrock here unless you set up your own IAM credentials inside the container.

---

## Gotchas (consolidated)

- **Port 22 closed by default** in the OpenClaw blueprint firewall. You must `put-instance-public-ports` to open it.
- **`allowedOrigins` baked with dynamic IP.** Patch after attaching the static IP, or the browser is rejected.
- **`/opt/aws/open_claw/credentials.log` is stale** after the first rotation — don't read it. Use `jq` on `openclaw.json` or `openclaw dashboard`.
- **Tokens are URL fragments**, not query strings (`#token=`, not `?token=`). Apache blocks `?token=`.
- **Each new browser fingerprint requires a separate pairing approval.** Use `--latest`, not request IDs (which roll over fast).
- **AWS-bundled token rotation timer is disabled by default** in this recipe — it's not part of upstream OpenClaw, and the AWS implementation is broken (no actual rotation + wipes pairings). See *Token rotation* above.
- **Bedrock IAM setup is required** despite the pre-baked target_account_id — the role itself doesn't exist until the AWS-published script runs. open-forge can run it autonomously via the stable URL `https://d25b4yjpexuuj4.cloudfront.net/scripts/lightsail/setup-lightsail-openclaw-bedrock-role.sh`; AWS docs falsely imply console-only access. UI loads fine without it, but every model call fails with `AssumeRole AccessDenied`. See *IAM for Bedrock* above.
- **The "target account" is your own AWS account**, not an AWS-owned one. The Lightsail-internal account (e.g. `592667671527`) appears in the trust policy as the principal that's *allowed to assume*. Don't confuse the two.
- **Don't open port 18789 to the internet.** It's bound to `127.0.0.1` for a reason; use Apache (already configured) or an SSH tunnel.
- **Snakeoil cert warning** in browsers — replace with Let's Encrypt if exposing publicly.
- **Model costs compound.** Long agent runs can burn tokens fast. Set spend limits in your provider dashboard before first real use.

---

## TODO — verify on subsequent deployments

- Exact `api` string and model ID format for non-Bedrock providers (Anthropic, OpenAI, Google) when editing config directly.
- Whether `openclaw configure` non-interactive flags exist (so model swap can be scripted).
- Behavior when both Bedrock and a non-Bedrock provider are configured simultaneously.
