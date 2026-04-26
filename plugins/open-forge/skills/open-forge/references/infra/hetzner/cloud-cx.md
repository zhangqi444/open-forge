---
name: hetzner-cloud-cx-infra
description: Hetzner Cloud (CX-line VPS) infra adapter — how to provision a CX server with SSH key upload, firewall, and primary IP via the `hcloud` CLI. Pair with `runtimes/docker.md` or `runtimes/native.md` for the application install. Picked when the user wants the cheapest serious-VPS option (€4–€7/mo), EU-jurisdiction hosting, or both.
---

# Hetzner Cloud — CX-line adapter

Hetzner Cloud is a German-headquartered VPS provider with the cheapest "real" tier in the market (CX22 ≈ €4.5/mo for 4 GB RAM). Good default for hobby self-hosts where every dollar matters and EU-jurisdiction is a feature, not a constraint.

## Prerequisites

Check during preflight; stop and install/configure if missing:

- `hcloud` CLI (`hcloud version`)
- A Hetzner Cloud API token with read+write scope, set in an `hcloud` context
- The user has a Hetzner Cloud account and has created at least one project in the Hetzner Console

### Install + auth

```bash
# macOS
brew install hcloud

# Linux — download the latest binary
curl -fsSL -o /tmp/hcloud.tgz \
  "https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/').tar.gz"
tar -xzf /tmp/hcloud.tgz -C /tmp hcloud
sudo install -m 0755 /tmp/hcloud /usr/local/bin/hcloud
hcloud version

# One-time: create a context tied to a project token
# (User generates the token in https://console.hetzner.cloud → project → Security → API Tokens)
hcloud context create open-forge        # interactive — paste the token
hcloud context use open-forge
hcloud server-type list                 # sanity check — should print the catalog
```

Tokens are project-scoped; one per Hetzner project. open-forge does not store tokens — `hcloud` keeps them in `~/.config/hcloud/cli.toml` with `chmod 600`.

## Inputs to collect

Cross-cutting preflight collects deployment name. The Hetzner adapter additionally needs:

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Server type?" | `AskUserQuestion`, options from the table below | Project-recipe-suggested |
| End of preflight | "Location?" | `AskUserQuestion`: `Falkenstein, DE (fsn1)` / `Nuremberg, DE (nbg1)` / `Helsinki, FI (hel1)` / `Ashburn, US (ash)` / `Hillsboro, US (hil)` / `Singapore (sin)` | Geographic-closest to user |
| End of preflight | "Image?" | `AskUserQuestion`: `Ubuntu 24.04` / `Debian 12` / `Other (specify)` | `Ubuntu 24.04` |
| End of preflight | "SSH key — upload an existing one?" | `AskUserQuestion`: `Yes (default ~/.ssh/id_ed25519.pub)` / `Generate a new one for this deployment` / `Use a key already in this Hetzner project` | Existing default |

Derived (no prompt):

| Recorded as | Derived from |
|---|---|
| `outputs.server_name` | Deployment name |
| `outputs.firewall_name` | `<deployment-name>-fw` |
| `outputs.ssh_key_name` | `<deployment-name>-key` (or pre-existing name if reusing) |
| `outputs.public_ip` | `hcloud server describe` output |
| `outputs.ssh_key_path` | The local path the user supplied / generated key |

### Common server-type options (Intel x86)

| Type | vCPU | RAM | Disk | Approx €/mo | When |
|---|---|---|---|---|---|
| `cx22` | 2 (shared) | 4 GB | 40 GB | €4.5 | OpenClaw, Ghost, anything Node — recommended default |
| `cx32` | 4 (shared) | 8 GB | 80 GB | €7.5 | Heavier Node/Java workloads |
| `cx42` | 8 (shared) | 16 GB | 160 GB | €15 | Real production |
| `cpx11` | 2 (dedicated AMD) | 2 GB | 40 GB | €5 | When CPU steal matters more than RAM |

ARM (Ampere) lines (`cax11` etc.) are also offered — pick if upstream ships ARM.

## Provisioning

### 1. Upload (or reuse) the SSH key

```bash
KEY_NAME="${SERVER_NAME}-key"

if [ ! -f "$SSH_PUBKEY_PATH" ]; then
  ssh-keygen -t ed25519 -f "${SSH_PUBKEY_PATH%.pub}" -N "" -C "open-forge $SERVER_NAME"
fi

if ! hcloud ssh-key describe "$KEY_NAME" >/dev/null 2>&1; then
  hcloud ssh-key create --name "$KEY_NAME" --public-key-from-file "$SSH_PUBKEY_PATH"
fi
```

### 2. Create a firewall (default-deny, then allow)

Hetzner's stateful firewall lives outside the VM (no host iptables needed for ingress).

```bash
FW_NAME="${SERVER_NAME}-fw"

hcloud firewall create --name "$FW_NAME"

hcloud firewall add-rule "$FW_NAME" --direction in --protocol tcp --port 22  --source-ips 0.0.0.0/0 --source-ips ::/0 --description SSH
hcloud firewall add-rule "$FW_NAME" --direction in --protocol tcp --port 80  --source-ips 0.0.0.0/0 --source-ips ::/0 --description HTTP
hcloud firewall add-rule "$FW_NAME" --direction in --protocol tcp --port 443 --source-ips 0.0.0.0/0 --source-ips ::/0 --description HTTPS
```

If the project recipe needs additional ports, add them the same way at the relevant phase.

### 3. Create the server

```bash
hcloud server create \
  --name "$SERVER_NAME" \
  --type "$SERVER_TYPE" \
  --image "$IMAGE" \
  --location "$LOCATION" \
  --ssh-key "$KEY_NAME" \
  --firewall "$FW_NAME" \
  --label "open-forge=true" \
  --label "deployment=$SERVER_NAME"
```

`hcloud server create` blocks until the server is `running`. The output contains the IPv4 + IPv6.

```bash
PUBLIC_IP=$(hcloud server ip "$SERVER_NAME")
```

### 4. (Optional) Reserve a Primary IP for portability

Hetzner servers come with a primary IPv4 + IPv6 by default. They survive reboots but **not** delete-and-recreate. For deployments where the same DNS A record must keep working across rebuilds, allocate a separate Primary IP and assign it:

```bash
hcloud primary-ip create \
  --type ipv4 --datacenter "${LOCATION}-dc1" \
  --name "${SERVER_NAME}-ip" \
  --assignee-type server --assignee-id "$(hcloud server describe "$SERVER_NAME" -o json | jq -r .id)"
```

For most hobby deploys this is overkill — the server's default IP is fine. Skip unless the user explicitly wants rebuild-stable DNS.

## SSH convention

- User: **`root`** by default on Hetzner Ubuntu/Debian images. Hetzner provisioning seeds your SSH key into `/root/.ssh/authorized_keys` directly; there is no `ubuntu` user pre-created.
- First SSH: `-o StrictHostKeyChecking=accept-new`.

```bash
ssh -i "${SSH_PUBKEY_PATH%.pub}" -o StrictHostKeyChecking=accept-new "root@$PUBLIC_IP"
```

For a non-root daily user, follow the project recipe — most recipes do `adduser <name>`, copy `authorized_keys`, then disable root login in `/etc/ssh/sshd_config`. `runtimes/native.md` and `runtimes/docker.md` assume the user already has shell access.

## Firewall changes after provision

```bash
hcloud firewall add-rule "$FW_NAME" --direction in --protocol tcp --port <N> --source-ips 0.0.0.0/0 --source-ips ::/0 --description '<purpose>'
hcloud firewall delete-rule "$FW_NAME" --direction in --protocol tcp --port <N> --source-ips 0.0.0.0/0 --source-ips ::/0
```

## Verification

Mark `provision` done only when all of:

- `hcloud server describe "$SERVER_NAME" -o json | jq -r .status` returns `running`
- `ssh -i <key> root@$PUBLIC_IP 'echo ok'` prints `ok`

## Teardown

Don't auto-run; confirm with the user.

```bash
hcloud server delete "$SERVER_NAME"
hcloud firewall delete "$FW_NAME"
hcloud ssh-key delete "$KEY_NAME"          # only if no other server uses it
hcloud primary-ip delete "${SERVER_NAME}-ip"   # only if you allocated one
```

## Gotchas

- **Default user is `root`.** Different from AWS / GCP defaults (`ubuntu`, `ec2-user`). Don't try `ubuntu@<ip>` — it doesn't exist.
- **Server delete also frees the default Primary IP.** If you reserved one separately (step 4 above), keep that — it's not auto-deleted.
- **Firewall must be attached at create time** (or via `hcloud firewall apply-to-resource` after) — a server without a firewall has all inbound open at the cloud level. The `--firewall` flag on `server create` is the simplest path.
- **Bandwidth metering.** Hetzner's per-server traffic allowance (20 TB/mo on most plans) is generous; over-allowance is billed at €1/TB. Not a concern for typical self-host workloads.
- **Snapshot vs backup.** Snapshots are manual (€0.0119/GB/mo); automated backups are 20% of server price. Hobby deploys often skip both — explain the trade to the user before ticking either on.
- **`hcloud context` is per-project.** Multiple Hetzner projects in one account each have their own API token and need their own context. Switch with `hcloud context use <name>`.
- **No private networking by default.** All traffic between Hetzner servers goes over the public internet unless you create a Hetzner Cloud Network and attach servers. Single-node self-hosts don't need this.

## Reference

- Hetzner Cloud docs: <https://docs.hetzner.com/cloud/>
- `hcloud` CLI: <https://github.com/hetznercloud/cli>
- Server-type catalog: <https://www.hetzner.com/cloud/>
