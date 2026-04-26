---
name: digitalocean-droplet-infra
description: DigitalOcean Droplet infra adapter — how to provision a Droplet with SSH key upload, Cloud Firewall, and Reserved IP via the `doctl` CLI. Pair with `runtimes/docker.md` or `runtimes/native.md` for the application install. Picked when the user wants polished UX, integrated managed services (Spaces, Postgres) potentially layered on later, or a US-headquartered alternative to Hetzner.
---

# DigitalOcean Droplet adapter

DigitalOcean ships clean APIs, regional coverage in 14+ datacenters, and an integrated ecosystem (managed Postgres, Spaces object storage, Load Balancers) that you can layer on later from the same console. Pricing sits between Hetzner (cheaper) and AWS (more expensive).

## Prerequisites

Check during preflight; stop and install/configure if missing:

- `doctl` CLI (`doctl version`)
- A DigitalOcean API token with read+write scope
- The user has a DigitalOcean account

### Install + auth

```bash
# macOS
brew install doctl

# Linux — download the latest binary
curl -fsSL -o /tmp/doctl.tgz \
  "https://github.com/digitalocean/doctl/releases/latest/download/doctl-$(curl -fsSL https://api.github.com/repos/digitalocean/doctl/releases/latest | jq -r .tag_name | sed 's/^v//')-linux-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/').tar.gz"
tar -xzf /tmp/doctl.tgz -C /tmp doctl
sudo install -m 0755 /tmp/doctl /usr/local/bin/doctl
doctl version

# One-time auth — paste the API token (generated at https://cloud.digitalocean.com/account/api/tokens)
doctl auth init                          # interactive
doctl auth list                          # confirm; the active context is highlighted
doctl account get                        # sanity check
```

`doctl` stores tokens in `~/.config/doctl/config.yaml`. Multiple accounts: `doctl auth init --context <name>` then `doctl auth switch --context <name>`.

## Inputs to collect

Cross-cutting preflight collects deployment name. The DO adapter additionally needs:

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Droplet size?" | `AskUserQuestion`, options from the table below | Project-recipe-suggested |
| End of preflight | "Region?" | `AskUserQuestion`: `New York 3 (nyc3)` / `San Francisco 3 (sfo3)` / `Toronto 1 (tor1)` / `London 1 (lon1)` / `Frankfurt 1 (fra1)` / `Amsterdam 3 (ams3)` / `Singapore 1 (sgp1)` / `Bangalore 1 (blr1)` / `Sydney 1 (syd1)` | Geographic-closest to user |
| End of preflight | "Image?" | `AskUserQuestion`: `Ubuntu 24.04 LTS` / `Debian 12` / `Other (specify slug)` | `ubuntu-24-04-x64` |
| End of preflight | "SSH key — upload an existing one?" | `AskUserQuestion`: `Yes (default ~/.ssh/id_ed25519.pub)` / `Generate a new one` / `Use a key already on this DO account` | Existing default |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.droplet_name` | Deployment name |
| `outputs.firewall_name` | `<deployment-name>-fw` |
| `outputs.ssh_key_name` | `<deployment-name>-key` |
| `outputs.reserved_ip` | `doctl compute reserved-ip create` output |
| `outputs.public_ip` | Same as reserved IP once associated |
| `outputs.ssh_key_path` | Local path to the private key |

### Common droplet-size options

| Slug | vCPU | RAM | Disk | Approx $/mo | When |
|---|---|---|---|---|---|
| `s-1vcpu-1gb` | 1 | 1 GB | 25 GB | $6 | Toy / static |
| `s-1vcpu-2gb` | 1 | 2 GB | 50 GB | $12 | Light Ghost |
| `s-2vcpu-2gb` | 2 | 2 GB | 60 GB | $18 | Real Ghost / WordPress |
| `s-2vcpu-4gb` | 2 | 4 GB | 80 GB | $24 | OpenClaw, Nextcloud — **recommended default** |
| `s-2vcpu-8gb-amd` | 2 | 8 GB | 160 GB | $63 | Premium AMD; heavier workloads |

`s-` is "Basic"; `c-` and `g-` are CPU- and general-purpose performance tiers.

## Provisioning

### 1. Upload (or reuse) the SSH key

```bash
KEY_NAME="${DROPLET_NAME}-key"

if [ ! -f "$SSH_PUBKEY_PATH" ]; then
  ssh-keygen -t ed25519 -f "${SSH_PUBKEY_PATH%.pub}" -N "" -C "open-forge $DROPLET_NAME"
fi

if ! doctl compute ssh-key list --format Name --no-header | grep -qx "$KEY_NAME"; then
  doctl compute ssh-key import "$KEY_NAME" --public-key-file "$SSH_PUBKEY_PATH"
fi

KEY_ID=$(doctl compute ssh-key list --format ID,Name --no-header | awk -v n="$KEY_NAME" '$2==n{print $1}')
```

### 2. Create the droplet

DO doesn't have a "create firewall first then attach" requirement — droplets get created with all-open inbound until a firewall covers them. Sequence matters: create droplet, then immediately apply firewall before continuing to app install.

```bash
DROPLET_OUT=$(doctl compute droplet create "$DROPLET_NAME" \
  --image "$IMAGE_SLUG" \
  --size "$DROPLET_SIZE" \
  --region "$REGION" \
  --ssh-keys "$KEY_ID" \
  --enable-monitoring \
  --tag-names "open-forge,deployment-$DROPLET_NAME" \
  --wait \
  --format ID,PublicIPv4 --no-header)

DROPLET_ID=$(echo "$DROPLET_OUT" | awk '{print $1}')
DROPLET_IP=$(echo "$DROPLET_OUT" | awk '{print $2}')
```

`--wait` blocks until the droplet is `active`.

### 3. Apply a Cloud Firewall (default-deny inbound, allow web + SSH)

```bash
FW_NAME="${DROPLET_NAME}-fw"

doctl compute firewall create \
  --name "$FW_NAME" \
  --droplet-ids "$DROPLET_ID" \
  --inbound-rules \
    "protocol:tcp,ports:22,address:0.0.0.0/0,address:::/0 \
     protocol:tcp,ports:80,address:0.0.0.0/0,address:::/0 \
     protocol:tcp,ports:443,address:0.0.0.0/0,address:::/0" \
  --outbound-rules \
    "protocol:tcp,ports:all,address:0.0.0.0/0,address:::/0 \
     protocol:udp,ports:all,address:0.0.0.0/0,address:::/0 \
     protocol:icmp,address:0.0.0.0/0,address:::/0"

FW_ID=$(doctl compute firewall list --format ID,Name --no-header | awk -v n="$FW_NAME" '$2==n{print $1}')
```

### 4. (Optional) Reserve a Floating / Reserved IP

DO Reserved IPs (formerly Floating IPs) survive droplet rebuild. For deployments where DNS must keep working across recreates, allocate one and assign:

```bash
RESERVED_IP=$(doctl compute reserved-ip create --region "$REGION" --format IP --no-header)
doctl compute reserved-ip-action assign "$RESERVED_IP" "$DROPLET_ID"
PUBLIC_IP="$RESERVED_IP"
```

For typical hobby deploys, the droplet's default IPv4 (`$DROPLET_IP` above) is fine — skip unless rebuild-stable DNS matters.

## SSH convention

- User: **`root`** by default on DO marketplace and base OS images. DO pushes your uploaded SSH keys into `/root/.ssh/authorized_keys`.
- First SSH: `-o StrictHostKeyChecking=accept-new`.

```bash
ssh -i "${SSH_PUBKEY_PATH%.pub}" -o StrictHostKeyChecking=accept-new "root@$PUBLIC_IP"
```

Project recipes that prefer a non-root user own the `adduser` + `sshd_config` hardening.

## Firewall changes after provision

```bash
doctl compute firewall add-rules "$FW_ID" \
  --inbound-rules "protocol:tcp,ports:<N>,address:0.0.0.0/0,address:::/0"

doctl compute firewall remove-rules "$FW_ID" \
  --inbound-rules "protocol:tcp,ports:<N>,address:0.0.0.0/0,address:::/0"
```

## Verification

Mark `provision` done only when all of:

- `doctl compute droplet get "$DROPLET_ID" --format Status --no-header` returns `active`
- `doctl compute firewall get "$FW_ID" --format DropletIDs --no-header` includes `$DROPLET_ID`
- `ssh -i <key> root@$PUBLIC_IP 'echo ok'` prints `ok`

## Teardown

Don't auto-run; confirm with the user.

```bash
doctl compute reserved-ip delete "$RESERVED_IP"     # only if you reserved one
doctl compute firewall delete "$FW_ID"
doctl compute droplet delete "$DROPLET_ID"
doctl compute ssh-key delete "$KEY_ID"              # only if no other droplet uses it
```

## Gotchas

- **Window between droplet create and firewall apply.** A droplet without a firewall has all inbound open. Keep the gap small — firewall step right after `--wait` returns.
- **`s-` vs `c-` vs `g-` slugs.** `s-` (Basic) shares CPU; `c-` (CPU-Optimized) and `g-` (General Purpose) are dedicated. For most self-hosts, Basic is plenty; only upgrade if you see CPU steal.
- **Reserved IP outage after detach.** Detaching a Reserved IP (e.g. to migrate to a new droplet) takes ~30s for DNS-cached clients to reconnect. Plan for it during maintenance windows.
- **Image slug rotation.** `ubuntu-24-04-x64` is stable; older images do get retired. Resolve with `doctl compute image list-distribution --public --format Slug,Distribution,Name` if the user supplies a custom slug.
- **No automated backups by default.** DO offers backups at +20% of droplet cost; snapshots are pay-per-GB. Single-node hobby deploys often skip both — be explicit with the user.
- **Tag naming for cleanup.** Tag everything with `open-forge` (and a deployment-specific tag) so a future cleanup script can find it. `doctl ... --tag-names` is supported on droplet, firewall, and reserved-ip create.

## Reference

- DigitalOcean docs: <https://docs.digitalocean.com/>
- `doctl` reference: <https://docs.digitalocean.com/reference/doctl/>
- Droplet pricing: <https://www.digitalocean.com/pricing/droplets>
