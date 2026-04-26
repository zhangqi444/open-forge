---
name: exe-dev-paas-infra
description: exe.dev PaaS infra adapter — provision a VM that's reachable at `https://<vm-name>.exe.xyz` via exe.dev's HTTPS proxy + email auth. Two paths: Shelley agent (one-prompt automated) or manual SSH-in setup. Picked when the user wants an integrated HTTPS proxy + auth layer without configuring a tunnel themselves.
---

# exe.dev adapter

exe.dev provisions VMs accessible via `https://<vm-name>.exe.xyz`, with a built-in HTTPS proxy and email-based authentication layer in front. OpenClaw upstream documents two paths: a fully-automated "Shelley agent" prompt that does everything, or a manual SSH-driven install with nginx.

## Prerequisites

- exe.dev account.
- Browser for Shelley path; SSH access to the VM for manual path.
- API key for at least one model provider.

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Setup style?" | `AskUserQuestion`: `Shelley agent (one-prompt; recommended)` / `Manual SSH install` | Shelley |
| End of preflight | "VM name?" (becomes `<vm-name>.exe.xyz`) | Free-text | `<deployment-name>` |
| At secrets phase | "Shared secret for Control UI auth?" | Free-text or generated | Generated |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.vm_name` | The deployment name |
| `outputs.public_url` | `https://<vm-name>.exe.xyz/` |

## Path A — Shelley agent (recommended)

The fastest path — a single agent prompt does everything.

1. Walk the user to `https://exe.new/openclaw`.
2. Sign in / supply credentials.
3. Select **Agent** → wait for provisioning.
4. Once provisioned, visit `https://<vm-name>.exe.xyz/` and authenticate with the shared secret Shelley printed.
5. Approve the device pairing using the CLI command Shelley provides (typically `ssh exe.dev -t '...'`).

That's it. open-forge's role here is to coordinate the user's clicks, then verify access once the URL is live.

## Path B — Manual SSH install

For users who want full control or are debugging Shelley issues.

### 1. Create the VM

```bash
ssh exe.dev new
# Follow prompts to name the VM; you'll get an SSH endpoint like <user>@<vm-name>.exe.dev
```

### 2. Install dependencies + OpenClaw on the VM

```bash
ssh "<user>@<vm-name>.exe.dev"

sudo apt-get update
sudo apt-get install -y git curl jq ca-certificates nginx

curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
exec $SHELL -l
openclaw onboard --install-daemon
```

### 3. Configure nginx to proxy port 18789 → exe.dev's port 8000

```bash
sudo tee /etc/nginx/sites-available/openclaw <<'EOF'
server {
  listen 8000;

  location / {
    proxy_pass http://127.0.0.1:18789;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400s;
  }
}
EOF
sudo ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

The `Upgrade` and `Connection: upgrade` headers are mandatory for the WebSocket gateway. `proxy_read_timeout 86400s` keeps long-lived connections alive — the gateway holds WebSockets open for hours.

### 4. Get the gateway token + approve devices

```bash
TOKEN=$(jq -r .gateway.auth.token ~/.openclaw/openclaw.json)
echo "$TOKEN"
openclaw devices approve --latest --token "$TOKEN"
```

## Verification

```bash
curl -sIo /dev/null -w '%{http_code}\n' "https://<vm-name>.exe.xyz/"
# Expect: 2xx or 3xx (after exe.dev's email auth gate clears)
```

Open `https://<vm-name>.exe.xyz/#token=<TOKEN>` in a browser. exe.dev's email-auth screen appears first; once authenticated, the OpenClaw Control UI loads.

## Updates

```bash
# On the VM (Path B)
ssh "<user>@<vm-name>.exe.dev" 'curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard'
# or via openclaw's own update flow:
ssh "<user>@<vm-name>.exe.dev" 'openclaw update'
```

For Path A (Shelley), re-run the Shelley prompt at `https://exe.new/openclaw`.

## Teardown

```bash
ssh exe.dev delete <vm-name>
```

(Or via the exe.dev dashboard if available.)

## Gotchas

- **WebSocket headers in nginx are mandatory.** Without `Upgrade` / `Connection: upgrade`, the Control UI loads but pairing requests time out. Symptom: chat box appears but messages never send.
- **`proxy_read_timeout` defaults to 60s.** OpenClaw's WebSocket sits idle longer than that; raise to 86400s (24h) or higher.
- **exe.dev email auth is in front of openclaw's gateway token.** Two auth layers; users see exe.dev's login first, then openclaw's. Tell users to expect two prompts.
- **Path B port number (8000) is exe.dev-specific.** That's the port their proxy forwards from `*.exe.xyz` HTTPS to your VM. If exe.dev changes it, the nginx config breaks — verify against current exe.dev docs.
- **Shelley is opaque automation.** When it works it's great; when it fails, the user is back to Path B. Have the manual path ready.

## Reference

- exe.dev: <https://exe.dev>
- OpenClaw on exe.dev (upstream): <https://docs.openclaw.ai/install/exe-dev>
