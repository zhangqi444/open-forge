---
name: azure-vm-infra
description: Microsoft Azure Linux VM infra adapter — provision an Ubuntu VM with no public IP, NSG-hardened to allow SSH only via Azure Bastion, then install via SSH. Pair with `runtimes/native.md` or `runtimes/docker.md` for the application install. Picked when the user already has an Azure subscription, wants enterprise-grade SSH gating (Bastion), or is using GitHub Copilot as the model provider.
---

# Azure VM (Bastion-hardened) adapter

Provisions an Ubuntu 24.04 LTS VM in Azure with **no public IP** — SSH access goes exclusively through **Azure Bastion**, a managed jumpbox. NSG rules allow SSH only from the Bastion subnet; everything else is denied. Mirrors openclaw upstream's `docs/install/azure.md` recipe.

Worth picking when:
- The user already has an Azure subscription with billing.
- Enterprise security policy requires no public-IP VMs.
- The user has GitHub Copilot licenses and wants to use Copilot as the model provider (most enterprise Azure teams do; openclaw upstream highlights this).

## Prerequisites

Check during preflight; stop and install/configure if missing:

- `az` CLI (`az --version`)
- `az` SSH extension (`az extension add -n ssh`) — required for Bastion native SSH tunneling
- An Azure subscription where the user can create compute + network resources
- Microsoft.Compute and Microsoft.Network resource providers registered

### Install + auth

```bash
# macOS
brew install azure-cli

# Linux — Microsoft's apt repo
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az --version

# Auth
az login                                     # opens browser
az extension add -n ssh                      # for `az network bastion ssh`
az account show                              # confirm subscription
```

For multi-subscription accounts: `az account list -o table`, then `az account set --subscription <id-or-name>`.

### One-time provider registration

```bash
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network

# Wait for both to show "Registered" — usually < 1 min:
az provider show --namespace Microsoft.Compute --query registrationState -o tsv
az provider show --namespace Microsoft.Network --query registrationState -o tsv
```

## Inputs to collect

Cross-cutting preflight collects deployment name. The Azure adapter additionally needs:

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Azure subscription?" | `AskUserQuestion`: list from `az account list -o tsv --query '[].{name:name,id:id}'` | Active default |
| End of preflight | "Region (location)?" | `AskUserQuestion`: `westus2` / `eastus` / `westeurope` / `northeurope` / `southeastasia` / `Other` | Geographic-closest |
| End of preflight | "VM size?" | `AskUserQuestion`, options from the table below | Project-recipe-suggested |
| End of preflight | "OS disk size (GB)?" | `AskUserQuestion`: `30` / `64` / `128` / `Other` | `64` |
| End of preflight | "SSH public key path?" | Free-text; default `~/.ssh/id_ed25519.pub`. If missing, offer `ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519` | `~/.ssh/id_ed25519.pub` |

Derived (no prompt):

| Recorded as | Derived from |
|---|---|
| `outputs.resource_group` | `rg-<deployment-name>` |
| `outputs.vnet_name` | `vnet-<deployment-name>` |
| `outputs.vm_subnet_name` | `snet-<deployment-name>-vm` |
| `outputs.bastion_subnet_name` | `AzureBastionSubnet` (name is **required** by Azure) |
| `outputs.nsg_name` | `nsg-<deployment-name>-vm` |
| `outputs.vm_name` | `vm-<deployment-name>` |
| `outputs.bastion_name` | `bas-<deployment-name>` |
| `outputs.bastion_pip_name` | `pip-<deployment-name>-bastion` |
| `outputs.admin_username` | `<deployment-name>` (or `azureuser`) |

### Common VM-size options

| Size | vCPU | RAM | Approx $/mo (us-west2, on-demand) | When |
|---|---|---|---|---|
| `Standard_B2as_v2` | 2 (burstable AMD) | 8 GB | $55 | OpenClaw, Ghost, anything Node — recommended default |
| `Standard_B2s_v2` | 2 (burstable Intel) | 8 GB | $50 | Same workloads, Intel |
| `Standard_D2as_v5` | 2 (dedicated AMD) | 8 GB | $90 | Steady-state CPU loads |
| `Standard_B4as_v2` | 4 (burstable AMD) | 16 GB | $110 | Heavier workloads |
| `Standard_D2pls_v5` | 2 (Ampere ARM) | 4 GB | $65 | ARM workloads (cheaper if upstream ships ARM) |

List what's available: `az vm list-skus --location "$LOCATION" --resource-type virtualMachines -o table`.

## Provisioning

Run sequentially. Announce each command in one sentence before running.

### 1. Resource group

```bash
RG="rg-${DEPLOYMENT_NAME}"
LOCATION="$AZ_REGION"
az group create -n "$RG" -l "$LOCATION"
```

### 2. Network + NSG (hardened ingress)

CIDR ranges below are placeholders — adjust if they collide with the user's existing VNets.

```bash
VNET_NAME="vnet-${DEPLOYMENT_NAME}"
VM_SUBNET_NAME="snet-${DEPLOYMENT_NAME}-vm"
NSG_NAME="nsg-${DEPLOYMENT_NAME}-vm"

VNET_PREFIX="10.40.0.0/16"
VM_SUBNET_PREFIX="10.40.2.0/24"
BASTION_SUBNET_PREFIX="10.40.1.0/26"        # /26 minimum, required by Azure Bastion

# NSG with three rules: allow SSH from Bastion subnet only, deny SSH from everywhere else
az network nsg create -g "$RG" -n "$NSG_NAME" -l "$LOCATION"

az network nsg rule create -g "$RG" --nsg-name "$NSG_NAME" \
  -n AllowSshFromBastionSubnet --priority 100 \
  --access Allow --direction Inbound --protocol Tcp \
  --source-address-prefixes "$BASTION_SUBNET_PREFIX" \
  --destination-port-ranges 22

az network nsg rule create -g "$RG" --nsg-name "$NSG_NAME" \
  -n DenyInternetSsh --priority 110 \
  --access Deny --direction Inbound --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-port-ranges 22

az network nsg rule create -g "$RG" --nsg-name "$NSG_NAME" \
  -n DenyVnetSsh --priority 120 \
  --access Deny --direction Inbound --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --destination-port-ranges 22

# VNet + VM subnet (NSG attached) + Bastion subnet
az network vnet create \
  -g "$RG" -n "$VNET_NAME" -l "$LOCATION" \
  --address-prefixes "$VNET_PREFIX" \
  --subnet-name "$VM_SUBNET_NAME" \
  --subnet-prefixes "$VM_SUBNET_PREFIX"

az network vnet subnet update \
  -g "$RG" --vnet-name "$VNET_NAME" -n "$VM_SUBNET_NAME" --nsg "$NSG_NAME"

az network vnet subnet create \
  -g "$RG" --vnet-name "$VNET_NAME" \
  -n AzureBastionSubnet \
  --address-prefixes "$BASTION_SUBNET_PREFIX"
```

### 3. Create the VM (no public IP, no per-NIC NSG)

```bash
VM_NAME="vm-${DEPLOYMENT_NAME}"
ADMIN_USERNAME="${DEPLOYMENT_NAME//[^a-zA-Z0-9]/}"     # alphanumeric only
SSH_PUB_KEY="$(cat "$SSH_PUB_KEY_PATH")"

az vm create \
  -g "$RG" -n "$VM_NAME" -l "$LOCATION" \
  --image "Canonical:ubuntu-24_04-lts:server:latest" \
  --size "$VM_SIZE" \
  --os-disk-size-gb "$OS_DISK_GB" \
  --storage-sku StandardSSD_LRS \
  --admin-username "$ADMIN_USERNAME" \
  --ssh-key-values "$SSH_PUB_KEY" \
  --vnet-name "$VNET_NAME" --subnet "$VM_SUBNET_NAME" \
  --public-ip-address "" \
  --nsg ""
```

`--public-ip-address ""` blocks public-IP allocation; `--nsg ""` skips a per-NIC NSG (the subnet-level NSG handles security).

For reproducibility, replace `latest` with a pinned image version: `az vm image list --publisher Canonical --offer ubuntu-24_04-lts --sku server --all -o table`.

### 4. Provision Azure Bastion (Standard SKU + tunneling)

```bash
BASTION_NAME="bas-${DEPLOYMENT_NAME}"
BASTION_PIP_NAME="pip-${DEPLOYMENT_NAME}-bastion"

az network public-ip create \
  -g "$RG" -n "$BASTION_PIP_NAME" -l "$LOCATION" \
  --sku Standard --allocation-method Static

az network bastion create \
  -g "$RG" -n "$BASTION_NAME" -l "$LOCATION" \
  --vnet-name "$VNET_NAME" \
  --public-ip-address "$BASTION_PIP_NAME" \
  --sku Standard --enable-tunneling true
```

Provisioning typically takes 5–10 min, occasionally 15–30 min in some regions. Don't skip the Standard SKU — Basic doesn't support `az network bastion ssh` (CLI tunneling).

## SSH convention (via Bastion only)

```bash
VM_ID="$(az vm show -g "$RG" -n "$VM_NAME" --query id -o tsv)"

az network bastion ssh \
  --name "$BASTION_NAME" --resource-group "$RG" \
  --target-resource-id "$VM_ID" \
  --auth-type ssh-key \
  --username "$ADMIN_USERNAME" \
  --ssh-key "${SSH_PUB_KEY_PATH%.pub}"
```

Plain `ssh user@<ip>` will not work — there's no public IP. All shell access flows through Bastion.

For commands that runtime/project recipes want to drive non-interactively, wrap in:

```bash
az network bastion ssh ... --command 'bash -lc "openclaw gateway status"'
```

## Verification

Mark `provision` done only when all of:

- `az vm get-instance-view -g "$RG" -n "$VM_NAME" --query 'instanceView.statuses[?starts_with(code, `PowerState/`)].displayStatus' -o tsv` returns `VM running`.
- `az network bastion ssh ... --command 'echo ok'` prints `ok`.

## Cost considerations

Azure Bastion **Standard SKU** is the largest cost (~$140/month). To reduce:

- **Deallocate the VM** when not actively running OpenClaw: `az vm deallocate -g "$RG" -n "$VM_NAME"` (compute stops billing; disk continues). Restart later: `az vm start`.
- **Delete and recreate Bastion** as needed. Recreation takes a few minutes; saves $140/month if SSH access is rare.
- **Use Basic Bastion SKU** (~$38/month) if you only need browser-portal SSH. CLI tunneling (`az network bastion ssh`) is **not** supported on Basic.

VM size `Standard_B2as_v2` is ~$55/month on-demand. Reserved 1-year/3-year instances cut that by 30–60%.

## Teardown

Don't auto-run; confirm with the user.

```bash
az group delete -n "$RG" --yes --no-wait
```

Deletes the resource group and everything inside it (VM, VNet, NSG, Bastion, public IPs, disks). `--no-wait` returns immediately; full deletion takes 5–15 min.

## Gotchas

- **Bastion subnet name is fixed.** Must be exactly `AzureBastionSubnet` — Azure rejects any other name. CIDR must be at least `/26`.
- **`Standard` Bastion SKU mandatory for CLI SSH.** Don't downgrade to Basic and expect `az network bastion ssh` to work.
- **`az vm create --public-ip-address ""` is the no-IP flag.** Older docs recommended `--public-ip-sku ""`, but the empty-string `--public-ip-address ""` is what the current az CLI honors. Verify post-create: `az vm show --query 'networkProfile.networkInterfaces[0].id' -o tsv` then check the NIC has no public IP attached.
- **NSG priorities matter.** Allow rules must have lower priority numbers than deny rules. The 100 / 110 / 120 layout above is correct; reordering breaks SSH.
- **Subscription quota.** New subscriptions often have low vCPU quotas in popular regions. `az vm list-usage --location "$LOCATION" -o table` shows current usage; request increases via the Azure Portal.
- **`az ssh` extension drift.** `az extension update -n ssh` periodically; older versions miss `--auth-type ssh-key` for Bastion.
- **Disk encryption** is on by default for OS disk (Azure-managed key). Customer-managed keys require additional setup not covered here.
- **Provider registration is per-subscription, not per-region.** Once registered, `Microsoft.Compute` and `Microsoft.Network` are registered everywhere in that subscription.

## Reference

- Azure CLI install: <https://learn.microsoft.com/cli/azure/install-azure-cli>
- Bastion docs: <https://learn.microsoft.com/azure/bastion/>
- Ubuntu images on Azure: <https://documentation.ubuntu.com/azure/explanation/intro/>
- OpenClaw on Azure (upstream): <https://docs.openclaw.ai/install/azure>
