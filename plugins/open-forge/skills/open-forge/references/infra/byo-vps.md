---
name: byo-vps-infra
description: Bring-your-own-VPS infra adapter. The user already has a Linux VM somewhere (any cloud, dedicated server, home lab) and just wants Claude to install + configure their software on it. open-forge does NOT provision the VM here — only the user can do that, in their own provider's UI. Skill drives the install via SSH.
---

# BYO VPS — bring-your-own Linux VM

User already has a Linux VM with SSH access. open-forge skips provisioning entirely and drives everything over SSH. Compatible with any Linux distribution that supports the project's runtime requirements.

## When this is loaded

User picked **bring-your-own-VPS** (or named a host that doesn't have a dedicated infra adapter yet — Hetzner-without-a-hetzner-adapter, DigitalOcean-without-a-do-adapter, on-prem hardware, etc.) at the **where** question.

## Inputs to collect

| Phase | Prompt | Tool / format | Notes |
|---|---|---|---|
| preflight | "What's the IP or hostname of your VPS?" | Free-text | IPv4, IPv6, or DNS name |
| preflight | "SSH user?" | Free-text, default `root` for Hetzner / DO; `ubuntu` for AWS/GCP-Ubuntu; `ec2-user` for Amazon Linux | Confirm with user |
| preflight | "Path to the SSH private key?" | Free-text, default `~/.ssh/id_ed25519` then `~/.ssh/id_rsa` | Skill verifies the file exists and `chmod 600` |
| preflight | "OS family?" | `AskUserQuestion`: `Ubuntu/Debian` / `RHEL/CentOS/Fedora/Amazon Linux` / `Alpine` / `Other (specify)` | Determines package manager (apt / dnf / apk) |

After collecting, verify SSH access before proceeding:

```bash
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new "$SSH_USER@$HOST" 'whoami && cat /etc/os-release | head -3'
```

If this fails, stop and surface the error to the user (wrong key, host unreachable, etc.) — don't try to "fix" it autonomously.

## What this adapter does NOT do

- **Does not provision a VM.** User does that in their provider's UI.
- **Does not allocate / attach a static IP.** User does that in their provider's UI.
- **Does not manage the provider's firewall.** User opens ports in the provider's UI; on the host, Claude can use `ufw` / `firewalld` / `nftables` if needed (project recipe will say which ports).
- **Does not download SSH keys.** User must already have the key locally and provide the path.

## What this adapter does

- Runs `ssh` with the user's key for every command issued by the project recipe + runtime module.
- Detects OS family via `/etc/os-release` for package-manager dispatch.
- Provides the standard host paths (`/home/<user>`, `/etc/`, etc.) that runtime modules expect.

## SSH ergonomics

Suggest the user add a host alias to `~/.ssh/config` so subsequent sessions are simpler:

```
Host <deployment-name>
  HostName <ip-or-fqdn>
  User <ssh-user>
  IdentityFile <path-to-key>
```

Then `ssh <deployment-name>` works from anywhere. Optional but nice.

## Firewall conventions

Most VPS providers ship a firewall **outside** the VM (Hetzner Cloud Firewall, DO Cloud Firewalls, AWS Security Groups). Some don't (bare metal, simple VPS plans). The project recipe says which ports need to be open; the user owns opening them at their provider.

For host-level firewall (Ubuntu's `ufw`, RHEL's `firewalld`):

```bash
# Ubuntu/Debian — ufw
sudo ufw allow <port>/tcp
sudo ufw enable

# RHEL/Fedora — firewalld
sudo firewall-cmd --permanent --add-port=<port>/tcp
sudo firewall-cmd --reload
```

Default to NOT enabling host firewall unless a provider firewall is absent.

## Verification before marking `provision` done

- `ssh` returns the expected username from `whoami`
- OS family matches what the user said
- (If the project requires) the runtime layer's prereqs are present — Docker installed, etc.

## When to upgrade to a dedicated infra adapter

If a particular provider gets used repeatedly (e.g. multiple Hetzner deployments), it's worth adding `references/infra/hetzner/cloud-cx.md` so we can automate VM provisioning + firewall + (where the API allows) DNS. byo-vps stays the catch-all for everything else.
