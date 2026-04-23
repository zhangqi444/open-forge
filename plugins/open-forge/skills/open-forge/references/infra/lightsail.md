---
name: lightsail-infra
description: AWS Lightsail infra adapter — how to provision a Lightsail instance, allocate and attach a static IP, retrieve the default SSH key, and SSH in. Consumed by open-forge when `infra: lightsail` is selected.
---

# AWS Lightsail adapter

Lightsail is AWS's "simple VPS" product: pre-packaged Bitnami blueprints, flat monthly pricing, a built-in firewall, and one-click static-IP allocation. Good default for a single-node self-host.

## Prerequisites

Check during preflight; stop and install/configure if missing:

- `aws` CLI v2 (`aws --version`)
- A configured AWS profile with Lightsail permissions (`aws configure list-profiles`)
- The user knows which profile + region they want to use

## Inputs

Collect and record in the deployment state file:

| Key | Example | Notes |
|---|---|---|
| `inputs.aws_profile` | `qi-experiment` | `--profile` for every AWS CLI call |
| `inputs.aws_region` | `us-east-1` | `--region` for every AWS CLI call |
| `outputs.instance_name` | `my-blog` | Usually the deployment name |
| `outputs.static_ip_name` | `my-blog-ip` | `<instance_name>-ip` by convention |
| `outputs.bundle_id` | `nano_3_0` | Smallest tier; override if the project recipe needs more |
| `outputs.blueprint_id` | `ghost_5` | From the project recipe |

## Provisioning

Run in this order. Wait for each to finish before the next. Announce each command in one sentence before running.

### 1. Create the instance

```bash
aws lightsail create-instances \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --instance-names "$INSTANCE_NAME" \
  --availability-zone "${AWS_REGION}a" \
  --blueprint-id "$BLUEPRINT_ID" \
  --bundle-id "$BUNDLE_ID"
```

Wait until the instance state is `running`:

```bash
aws lightsail get-instance \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --instance-name "$INSTANCE_NAME" \
  --query 'instance.state.name' --output text
```

Poll every 5–10s. First boot of a Bitnami blueprint typically takes 60–120s.

### 2. Allocate and attach a static IP

Lightsail instances get a dynamic public IP by default, which changes on stop/start. Always allocate a static IP before DNS.

```bash
aws lightsail allocate-static-ip \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --static-ip-name "$STATIC_IP_NAME"

aws lightsail attach-static-ip \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --static-ip-name "$STATIC_IP_NAME" \
  --instance-name "$INSTANCE_NAME"

aws lightsail get-static-ip \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --static-ip-name "$STATIC_IP_NAME" \
  --query 'staticIp.ipAddress' --output text
```

Save the returned IP to `outputs.public_ip`.

### 3. Retrieve the default SSH key

Lightsail regions share one default keypair. Download it once and reuse:

```bash
KEY_PATH="$HOME/.ssh/lightsail-default.pem"
if [ ! -f "$KEY_PATH" ]; then
  aws lightsail download-default-key-pair \
    --profile "$AWS_PROFILE" --region "$AWS_REGION" \
    --query 'privateKeyBase64' --output text > "$KEY_PATH"
  chmod 600 "$KEY_PATH"
fi
```

Save `outputs.ssh_key_path`.

## SSH convention

- User: **`bitnami`** for any Bitnami blueprint (Ghost, WordPress, Nextcloud, …). For non-Bitnami blueprints, check the blueprint docs — often `ubuntu` or `ec2-user`.
- First SSH to a fresh static IP: use `-o StrictHostKeyChecking=accept-new`. Do not blow away `~/.ssh/known_hosts` entries.

```bash
ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new "bitnami@$PUBLIC_IP"
```

For one-shot remote commands, wrap in `bash -lc` so the Bitnami env is loaded:

```bash
ssh -i "$KEY_PATH" "bitnami@$PUBLIC_IP" 'bash -lc "sudo /opt/bitnami/ctlscript.sh status"'
```

## Firewall defaults

Lightsail's per-instance firewall opens these ports by default on Bitnami blueprints:

- 22/tcp (SSH)
- 80/tcp (HTTP)
- 443/tcp (HTTPS)

No extra action needed for a typical web app. If a project recipe needs additional ports, open them with:

```bash
aws lightsail open-instance-public-ports \
  --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  --instance-name "$INSTANCE_NAME" \
  --port-info "fromPort=<N>,toPort=<N>,protocol=tcp"
```

## Paths and layout (Bitnami blueprints)

| Thing | Path |
|---|---|
| App install root | `/opt/bitnami/<app>/` (e.g. `/opt/bitnami/ghost/`) |
| Apache vhosts | `/opt/bitnami/apache/conf/vhosts/` |
| ctlscript | `/opt/bitnami/ctlscript.sh` (status, start, stop, restart) |
| bncert-tool | `/opt/bitnami/bncert-tool` (Let's Encrypt helper) |
| Bitnami credentials | `/home/bitnami/bitnami_credentials` (initial admin password) |

Non-Bitnami blueprints differ — consult the project recipe.

## Verification

Mark `provision` done only when all of:

- `aws lightsail get-instance … --query 'instance.state.name'` returns `running`
- `aws lightsail get-static-ip … --query 'staticIp.isAttached'` returns `True`
- `ssh -i $KEY_PATH bitnami@$PUBLIC_IP 'echo ok'` prints `ok`

## Gotchas

- **Dynamic IP vs static IP.** If you SSH'd before attaching the static IP, your `~/.ssh/known_hosts` has the dynamic one. After attach, the instance answers on a new IP — use `accept-new`, don't delete the old entry manually.
- **Region-scoped keypair.** `download-default-key-pair` is per-region. A new region means a new key.
- **Availability zone naming.** `--availability-zone` must be `<region>a`/`<region>b`/…, not just the region. Defaulting to `<region>a` is fine.
- **Stopping vs deleting.** `aws lightsail stop-instance` preserves data and billing continues; `delete-instance` removes it. Never delete without explicit user confirmation.
- **Bitnami password banner.** The initial Ghost/WordPress/etc. admin password is printed in `/home/bitnami/bitnami_credentials` on first boot. Grab it during the relevant project phase, not here.
