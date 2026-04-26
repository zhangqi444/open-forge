---
name: gcp-compute-engine-infra
description: Google Cloud Compute Engine infra adapter — how to provision a VM with VPC firewall rule, SSH key in instance metadata, and reserved external IP via the `gcloud` CLI. Pair with `runtimes/docker.md` or `runtimes/native.md` for the application install. Picked when the user already has a GCP org / billing account, or wants e2-small free-tier-eligible VMs.
---

# GCP Compute Engine adapter

Compute Engine is GCP's general-purpose VM service. Worth picking when: the user already has a GCP project + billing set up, they want the e2-micro free-tier (specific regions only), or they need GCP-native networking with other GCP services.

## Prerequisites

Check during preflight; stop and install/configure if missing:

- `gcloud` CLI (`gcloud version`)
- A configured GCP project with billing enabled and Compute Engine API enabled
- The user is authenticated (`gcloud auth list` shows an active account)

### Install + auth

```bash
# macOS
brew install --cask google-cloud-sdk

# Linux — Google's apt repo
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install -y google-cloud-cli
gcloud version

# One-time auth (opens browser)
gcloud auth login
gcloud config set project <project-id>
gcloud config set compute/region <region>          # optional — sets default
gcloud config set compute/zone   <region>-a        # optional — sets default
gcloud services enable compute.googleapis.com      # idempotent; needed once per project
```

`gcloud auth list` should show the active account marked with `*`. `gcloud config get-value project` should print the project ID.

## Inputs to collect

Cross-cutting preflight collects deployment name. The GCP adapter additionally needs:

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "GCP project ID?" | `AskUserQuestion`: list from `gcloud projects list` | Active default |
| End of preflight | "Region / zone?" | `AskUserQuestion`: `us-central1-a` / `us-east1-b` / `us-west1-a` / `europe-west1-b` / `asia-northeast1-a` / `Other` | Geographic-closest |
| End of preflight | "Machine type?" | `AskUserQuestion`, options from the table below | Project-recipe-suggested |
| End of preflight | "Image family?" | `AskUserQuestion`: `ubuntu-2404-lts-amd64` / `debian-12` / `Other (specify)` | `ubuntu-2404-lts-amd64` |
| End of preflight | "Boot disk size (GB)?" | `AskUserQuestion`: `20` / `30` / `50` / `Other` | `30` |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.instance_name` | Deployment name |
| `outputs.firewall_rule_name` | `<deployment-name>-allow-web` |
| `outputs.address_name` | `<deployment-name>-ip` |
| `outputs.public_ip` | `gcloud compute addresses describe` output |
| `outputs.ssh_key_path` | `~/.ssh/google_compute_engine` (gcloud-managed default) |

### Common machine-type options

| Type | vCPU | RAM | Approx $/mo (us-central1, sustained) | When |
|---|---|---|---|---|
| `e2-micro` | 2 (shared) | 1 GB | $7 (free-tier eligible in select regions) | Toy / static |
| `e2-small` | 2 (shared) | 2 GB | $13 | Light Ghost |
| `e2-medium` | 2 (shared) | 4 GB | $25 | OpenClaw, Nextcloud — **recommended default** |
| `e2-standard-2` | 2 (dedicated) | 8 GB | $49 | Heavier workloads |
| `t2a-standard-1` | 1 (Ampere ARM) | 4 GB | $24 | ARM workloads |

Free tier (`e2-micro`) is restricted to one VM per month in `us-west1`, `us-central1`, or `us-east1`. Outside those regions the small bill applies.

## Provisioning

### 1. Create a firewall rule (default-deny → allow specific ports)

GCP's "default" VPC ships with a `default-allow-ssh` rule already; we add an explicit web rule. Tag-targeted rules attach to instances by tag rather than by name, which is more robust.

```bash
RULE_NAME="${INSTANCE_NAME}-allow-web"
NETWORK_TAG="open-forge-${INSTANCE_NAME}"

gcloud compute firewall-rules create "$RULE_NAME" \
  --project "$GCP_PROJECT" \
  --network default \
  --direction INGRESS \
  --action ALLOW \
  --rules tcp:80,tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --target-tags "$NETWORK_TAG"
```

SSH (`tcp:22`) is already allowed by `default-allow-ssh` on the `default` network for any instance. If the user customized their VPC and `default-allow-ssh` is gone, add `tcp:22` here too.

### 2. Reserve a static external IP

```bash
ADDRESS_NAME="${INSTANCE_NAME}-ip"

gcloud compute addresses create "$ADDRESS_NAME" \
  --project "$GCP_PROJECT" \
  --region "$GCP_REGION"

PUBLIC_IP=$(gcloud compute addresses describe "$ADDRESS_NAME" \
  --project "$GCP_PROJECT" --region "$GCP_REGION" \
  --format='value(address)')
```

### 3. Create the VM

```bash
gcloud compute instances create "$INSTANCE_NAME" \
  --project "$GCP_PROJECT" \
  --zone "$GCP_ZONE" \
  --machine-type "$MACHINE_TYPE" \
  --image-family "$IMAGE_FAMILY" \
  --image-project ubuntu-os-cloud \
  --boot-disk-size "${BOOT_DISK_GB}GB" \
  --boot-disk-type pd-balanced \
  --tags "$NETWORK_TAG" \
  --address "$PUBLIC_IP" \
  --shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring \
  --labels "open-forge=true,deployment=$INSTANCE_NAME"
```

`--image-project ubuntu-os-cloud` is correct for Canonical-published Ubuntu images; Debian uses `debian-cloud`. The `--address $PUBLIC_IP` flag attaches the reserved IP at launch (avoids the "ephemeral first, swap later" dance).

Wait for the boot to settle:

```bash
gcloud compute instances describe "$INSTANCE_NAME" \
  --project "$GCP_PROJECT" --zone "$GCP_ZONE" \
  --format='value(status)'
# Expect: RUNNING
```

### 4. Push your SSH key (the gcloud way)

`gcloud compute ssh` lazily generates `~/.ssh/google_compute_engine` and pushes the public key into the instance's metadata on first use. To do it explicitly:

```bash
gcloud compute ssh "$INSTANCE_NAME" \
  --project "$GCP_PROJECT" --zone "$GCP_ZONE" \
  --command 'echo ok'
```

This is the easiest path. For tools (Ansible, plain `ssh`) that don't go through `gcloud`, add the key to project- or instance-level metadata:

```bash
gcloud compute instances add-metadata "$INSTANCE_NAME" \
  --project "$GCP_PROJECT" --zone "$GCP_ZONE" \
  --metadata "ssh-keys=<linux-user>:$(cat ~/.ssh/id_ed25519.pub)"
```

## SSH convention

Two paths:

```bash
# Through gcloud (handles key + IAP fallback)
gcloud compute ssh "$INSTANCE_NAME" --project "$GCP_PROJECT" --zone "$GCP_ZONE"

# Plain ssh (after key is in metadata; user is your local username on Ubuntu images by default)
ssh -i ~/.ssh/google_compute_engine -o StrictHostKeyChecking=accept-new "$USER@$PUBLIC_IP"
```

The default Linux username on Ubuntu/Debian images is **whatever local username gcloud detects** (often the segment of your Google email before `@`). Plain `ssh` needs `-l <user>` or `<user>@host` matching what gcloud created.

## Firewall changes after provision

```bash
gcloud compute firewall-rules update "$RULE_NAME" \
  --project "$GCP_PROJECT" \
  --rules tcp:22,tcp:80,tcp:443,tcp:<N>,tcp:<M>
```

(GCP firewall rules' `--rules` is replace-not-append. Pass the full final list each time.)

## Verification

Mark `provision` done only when all of:

- `gcloud compute instances describe ... --format='value(status)'` returns `RUNNING`
- `gcloud compute addresses describe ... --format='value(status)'` returns `IN_USE`
- `gcloud compute ssh "$INSTANCE_NAME" --command 'echo ok'` prints `ok`

## Teardown

Don't auto-run; confirm with the user.

```bash
gcloud compute instances delete "$INSTANCE_NAME" \
  --project "$GCP_PROJECT" --zone "$GCP_ZONE" --quiet
gcloud compute addresses delete "$ADDRESS_NAME" \
  --project "$GCP_PROJECT" --region "$GCP_REGION" --quiet
gcloud compute firewall-rules delete "$RULE_NAME" \
  --project "$GCP_PROJECT" --quiet
```

## Gotchas

- **Compute Engine API not enabled.** A fresh GCP project doesn't enable Compute Engine by default. `gcloud services enable compute.googleapis.com` once per project. Symptom on `gcloud compute instances create`: `Compute Engine API has not been used in project <id> before or it is disabled.`
- **Billing not linked.** Free-tier projects without a billing account block instance creation. Surface this clearly — only the user can attach billing in the GCP Console.
- **Address must match zone's region.** Reserved IPs are regional. The instance must be in a zone within that region. Mixing `--region us-central1` IP with `--zone us-east1-a` instance fails.
- **Default `default-allow-ssh` may be missing.** Some org policies remove default firewall rules. If `default-allow-ssh` doesn't exist, our `--rules` must include `tcp:22`.
- **`gcloud auth login` vs `gcloud auth application-default login`.** The first authenticates the CLI itself (used by `gcloud compute …` commands). The second sets up Application Default Credentials for SDKs (boto-style libraries on the VM). Don't conflate; for our use, only the first is needed.
- **Sustained-use vs committed-use discounts** apply automatically the longer the VM runs, but the headline price you see on the Pricing page is *list*. Cheaper than what AWS shows by default.
- **Static IP outside the free tier costs $$ when not attached** (~$0.005/hr). Release on teardown unless you want to retain the IP for a future deploy.
- **OS Login vs metadata-keys.** Org-policy may force OS Login (centralized IAM-based SSH). When that's on, adding metadata keys silently does nothing — `gcloud compute ssh` is the only path. Detect with `gcloud compute project-info describe --format='value(commonInstanceMetadata.items.enable-oslogin)'`.

## Reference

- Compute Engine docs: <https://cloud.google.com/compute/docs>
- `gcloud compute` reference: <https://cloud.google.com/sdk/gcloud/reference/compute>
- Free tier eligibility: <https://cloud.google.com/free/docs/free-cloud-features#compute>
