---
name: oracle-free-tier-arm-infra
description: Oracle Cloud Infrastructure (OCI) Always-Free ARM (Ampere A1.Flex) infra adapter — provision an aarch64 Ubuntu VM at zero cost (up to 4 OCPU / 24 GB RAM / 200 GB storage), reach it via Tailscale instead of public ingress. Pair with `runtimes/native.md` for the application install. Picked when budget is the priority and the user is OK with OCI's manual capacity-pool dance and Tailscale for SSH.
---

# Oracle Cloud Free-Tier ARM (A1.Flex) adapter

OCI's **Always Free** tier includes up to 4 OCPU / 24 GB RAM of Ampere ARM (A1.Flex) compute and 200 GB of storage. Genuinely free, indefinitely — but capacity is contended and creation can fail with "Out of capacity" until you find an availability domain that has space. Compensates with the best price/perf in the market once you're in.

Unlike the AWS / Hetzner / DO / GCP adapters, this one **does not** automate the OCI VM provisioning via CLI — OCI's CLI flow is significantly more involved (compartments, image OCIDs, capacity reservations) and the Console-driven flow is the one openclaw upstream documents and the user is most likely to succeed with. open-forge's role here is:

1. Tell the user exactly which Console buttons to click.
2. Take over via SSH once the VM exists, via Tailscale.
3. Lock down the VCN security list to Tailscale-only.

## Prerequisites

- An Oracle Cloud account ([signup](https://www.oracle.com/cloud/free/)). The signup itself can be tricky — keep [community guide](https://gist.github.com/rssnyder/51e3cfedd730e7dd5f4a816143b25dbd) handy.
- A Tailscale account (free tier works) with the `tailscale` CLI installed locally.
- An SSH public key.

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Do you already have an OCI free-tier instance?" | `AskUserQuestion`: `Yes — give me its public IP` / `No — walk me through Console creation` | — |
| End of preflight (if No) | (instructions only — no prompt) | Walk through Console steps below | — |
| End of preflight | "VM public IP?" | Free-text | Read from Console after creation |
| End of preflight | "OCPU count (1–4)?" | `AskUserQuestion`: `2` / `4` | `2` |
| End of preflight | "Memory (GB) — between 1 and 24, ≤ 6× OCPU count?" | Free-text or `AskUserQuestion`: `12` / `24` | `12` |
| End of preflight | "SSH public key path?" | Free-text; default `~/.ssh/id_ed25519.pub` | `~/.ssh/id_ed25519.pub` |
| End of preflight | "Tailscale auth — already signed in locally?" | `AskUserQuestion`: `Yes` / `No, walk me through it` | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.instance_name` | Deployment name (typed into Console) |
| `outputs.shape` | `VM.Standard.A1.Flex` |
| `outputs.image` | `Canonical-Ubuntu-24.04-aarch64` (latest) |
| `outputs.public_ip` | Provided by user from Console |
| `outputs.tailscale_hostname` | Deployment name (passed to `tailscale up --hostname=`) |

## Console-driven provisioning (Claude reads aloud, user clicks)

Open the [Oracle Cloud Console](https://cloud.oracle.com/) and have the user follow:

1. **Compute → Instances → Create Instance.**
2. **Name:** `<deployment-name>` (e.g. `openclaw`).
3. **Image and shape → Edit:**
   - Image: **Ubuntu 24.04** (`aarch64`, not the x86 variant).
   - Shape: **VM.Standard.A1.Flex** (Ampere ARM).
   - OCPUs: `<chosen>`. Memory (GB): `<chosen>`.
4. **Networking:** accept defaults (the wizard creates a VCN and subnet for you the first time).
5. **SSH key:** paste the contents of the user's public key (`cat ~/.ssh/id_ed25519.pub`).
6. **Boot volume:** keep default size (47 GB) or bump up to 200 GB (still free).
7. Click **Create**.

If creation fails with **"Out of capacity"**:
- Try a different **availability domain** in the same region (the dropdown right above the Image/Shape section).
- Try a different region if your home region has no domains with capacity.
- Retry off-peak hours.

Note the assigned **public IP** once the instance reaches `Running`.

## Initial host setup (over SSH)

```bash
ssh ubuntu@"$PUBLIC_IP"        # works while the VCN security list still allows public SSH

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y build-essential curl ca-certificates jq

# Hostname for clarity
sudo hostnamectl set-hostname "$DEPLOYMENT_NAME"
sudo loginctl enable-linger ubuntu     # so user services survive logout (used by openclaw)
```

`build-essential` is needed for ARM compilation of native-addon Node modules.

## Tailscale install + connect

```bash
# On the VM
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --hostname="$DEPLOYMENT_NAME"
```

The `--ssh` flag enables Tailscale SSH, which means future SSH access goes through the tailnet (no public ingress needed). On the user's local machine, `tailscale ip "$DEPLOYMENT_NAME"` returns the tailnet IP; from any device in the tailnet, `ssh ubuntu@$DEPLOYMENT_NAME` works.

## Lock down the VCN (Console-driven, after Tailscale is up)

Once Tailscale is confirmed working from a second device, harden the VCN:

1. **Networking → Virtual Cloud Networks**, click the user's VCN.
2. **Security Lists → Default Security List** (or whatever name the wizard gave it).
3. Under **Ingress Rules:**
   - **Remove** the default `0.0.0.0/0 TCP 22` rule (that's the public-SSH escape hatch we no longer need).
   - **Add:** `0.0.0.0/0 UDP 41641` — allows Tailscale's WireGuard traffic.
4. **Egress rules:** leave the default allow-all in place.

After this, public SSH (port 22 from the internet) is blocked at the VCN edge. The instance is reachable only via Tailscale.

## SSH convention (after lockdown)

```bash
ssh ubuntu@"$DEPLOYMENT_NAME"   # via Tailscale magicDNS
# or:
ssh ubuntu@"$(tailscale ip "$DEPLOYMENT_NAME" | head -1)"
```

The original public IP is now firewalled — don't use it.

## Verification

Mark `provision` done only when all of:

- `tailscale status` (locally) shows the instance as connected.
- `ssh ubuntu@"$DEPLOYMENT_NAME" 'echo ok'` prints `ok`.
- A `dig` or browser hit on `<public-ip>:22` returns no response (lockdown confirmed).

## Teardown

Console-driven (no CLI):

1. **Compute → Instances**, click the instance, **Terminate**.
2. Confirm. The boot volume can be preserved or deleted in the same dialog.

## Gotchas

- **"Out of capacity" is the dominant failure mode.** A1.Flex is the most popular free tier — Oracle rate-limits creation. Persistence wins; some users retry every hour for a day before getting in.
- **ARM (`aarch64`) image is mandatory.** A1.Flex won't accept x86 images. Most npm packages work on ARM64; native binaries you depend on may need an `aarch64`-labeled release.
- **Free tier can be terminated for inactivity.** OCI reclaims A1 instances that show no CPU activity for ~7 days. Keep the instance doing something (the OpenClaw gateway suffices) or expect to re-provision.
- **Plain `tailscale up` without `--ssh`** misses the SSH-over-tailnet feature. Always use `--ssh` for openclaw deployments — pairs with the public-SSH lockdown step.
- **Boot volume free-tier limit is per-tenancy, not per-region.** 200 GB is the total across all your free instances; allocate per VM accordingly.
- **VCN lockdown breaks if Tailscale is down.** If the Tailscale daemon stops, you're locked out. Mitigations: enable `tailscale up --reset-on-boot=false` (default), monitor `tailscale status`, and keep a recovery path via OCI's Console "Cloud Shell" (a browser-based SSH from the Console UI).
- **No `OCI_API_KEY` setup needed for this adapter** — we drive nothing via the OCI CLI here.

## Reference

- OCI Free Tier: <https://www.oracle.com/cloud/free/>
- Tailscale install: <https://tailscale.com/kb/1031/install-linux>
- Tailscale SSH: <https://tailscale.com/kb/1193/tailscale-ssh>
- OpenClaw on Oracle Cloud (upstream): <https://docs.openclaw.ai/install/oracle>
