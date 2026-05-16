---
name: Flint
description: "Modern KVM management tool. Single Go binary + embedded Next.js web UI + CLI + API. 0xchasercat/flint (volantvm/flint). No XML, no bloat. libvirt-based. Remote KVM via SSH."
---

# Flint

**Modern KVM management, reimagined.** A single <11MB Go binary with an embedded Next.js web UI, CLI, and REST API for managing KVM/libvirt virtual machines. No XML. No Virt-Manager. No bloat. Built for developers, sysadmins, and homelabbers who want zero-friction VM management.

Built + maintained by **volantvm** / 0xchasercat. Built quickly out of frustration with existing tooling.

- Upstream repo: <https://github.com/0xchasercat/flint> (also: <https://github.com/volantvm/flint>)
- Releases: <https://github.com/volantvm/flint/releases/latest>
- Chaser platform: <https://chaser.sh>

## Architecture in one minute

- **Single Go binary** (`flint`) — embeds the full Next.js + Tailwind web UI
- Communicates with **libvirt** (`libvirtd`) on the local or remote host
- **Port 5550** — web dashboard + REST API
- **Passphrase authentication** for the web UI; **Bearer token (API key)** for CLI + API
- **Cloud-Init support** — native provisioning for templates/instances
- Remote KVM management via SSH (connect to remote libvirt servers from one Flint instance)
- Resource: **tiny** — <11MB binary, minimal RAM beyond libvirt

## Compatible install methods

| Infra              | Runtime                                       | Notes                                                    |
| ------------------ | --------------------------------------------- | -------------------------------------------------------- |
| **Binary (glibc)** | `flint-linux-amd64` / `flint-linux-arm64`     | Debian, Ubuntu, Fedora, RHEL, Arch, etc.                 |
| **Binary (musl)**  | `flint-linux-amd64-musl` / `-arm64-musl`      | Alpine Linux                                             |
| **One-liner**      | `curl -fsSL …install.sh | bash`               | Auto-detects OS + arch, installs to `/usr/local/bin`     |

## Prerequisites

KVM/libvirt must be installed and running on the host before Flint:

```sh
# Debian / Ubuntu
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-daemon libvirt-clients bridge-utils
sudo systemctl enable --now libvirtd

# RHEL / Fedora / CentOS
sudo dnf install -y qemu-kvm libvirt libvirt-client virt-install
sudo systemctl enable --now libvirtd

# Arch Linux
sudo pacman -S qemu-full libvirt virt-install virt-manager
sudo systemctl enable --now libvirtd

# Alpine Linux
apk add libvirt-daemon libvirt-qemu qemu-system-x86_64
rc-update add libvirtd && rc-service libvirtd start
```

Verify: `libvirtd --version` → should show ≥ 6.10.0.

## Install Flint

**One-liner (recommended):**

```sh
curl -fsSL https://raw.githubusercontent.com/volantvm/flint/main/install.sh | bash
# Installs to /usr/local/bin/flint
# Prompts for web UI passphrase on first run
```

**Manual (glibc, amd64):**

```sh
wget https://github.com/volantvm/flint/releases/latest/download/flint-linux-amd64.zip
unzip flint-linux-amd64.zip && chmod +x flint
sudo mv flint /usr/local/bin/
```

**Manual (musl/Alpine, amd64):**

```sh
wget https://github.com/volantvm/flint/releases/latest/download/flint-linux-amd64-musl.zip
unzip flint-linux-amd64-musl.zip && chmod +x flint
sudo mv flint /usr/local/bin/
```

**ARM64 variants:** replace `amd64` with `arm64` in the URLs above.

## First run

```sh
# Interactive passphrase setup (recommended for first run)
flint serve --set-passphrase

# Or set passphrase directly
flint serve --passphrase "your-secure-password"

# Or via environment variable
export FLINT_PASSPHRASE="your-secure-password"
flint serve
```

Visit `http://<host>:5550` → enter passphrase → full dashboard access.

## Authentication

**Web UI:**
- Passphrase login → session cookie (HTTP-only, 1-hour expiry)
- Web UI never exposes API keys

**CLI + API:**
```sh
# List VMs from CLI (uses API key)
flint vm list --all

# External API call
curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:5550/api/vms
```

API key is generated and shown on first startup; also visible in the dashboard settings.

## Core features

- Create, start, stop, pause, delete VMs via UI / CLI / API
- Cloud-Init support for automated provisioning
- Snapshot-based template system
- Remote KVM/libvirt management via SSH
- Modern web UI (Next.js + Tailwind, embedded — no separate frontend server)
- **No XML editing** — Flint abstracts libvirt's XML config behind a clean interface

## Run as systemd service

```sh
# Create /etc/systemd/system/flint.service
[Unit]
Description=Flint KVM Management
After=libvirtd.service

[Service]
ExecStart=/usr/local/bin/flint serve
Environment=FLINT_PASSPHRASE=your-secure-password
Restart=on-failure

[Install]
WantedBy=multi-user.target

systemctl daemon-reload && systemctl enable --now flint
```

## Backup

Flint itself is stateless — VM data lives in libvirt's storage pools (typically `/var/lib/libvirt/images/`). Back up:

- VM disk images: `cp /var/lib/libvirt/images/<vm>.qcow2 backups/`
- Libvirt domain XML (export): `virsh dumpxml <vm-name> > backups/<vm>.xml`
- Use Flint's snapshot system for point-in-time VM backups

## Upgrade

Download new binary from <https://github.com/volantvm/flint/releases/latest>, replace `/usr/local/bin/flint`, restart the service.

## Gotchas

- **libvirt must be installed and `libvirtd` running** before starting Flint. If libvirt isn't running, Flint will start but all VM operations fail.
- **`libvirt-lxc.so.0` missing error** — install `libvirt-daemon-driver-lxc` (Debian) or `libvirt-daemon-lxc` (RHEL). Happens even if you're not using LXC containers; libvirt links against it.
- **glibc vs musl binaries.** Standard Debian/Ubuntu/Fedora/RHEL/Arch → use `flint-linux-amd64` (glibc). Alpine Linux → use `flint-linux-amd64-musl`. Using glibc binary on Alpine without `gcompat` causes a "not found" error.
- **Port 5550** — may conflict with other local services. Change via `flint serve --port 5551` or equivalent.
- **Passphrase is the only web UI auth.** No per-user accounts, no RBAC. Appropriate for homelabs; not for shared team use on a public IP without additional access control (VPN, Tailscale, Cloudflare Access).
- **Remote KVM via SSH** — Flint can manage remote libvirt servers from one local instance. Uses SSH key auth; configure `~/.ssh/config` for the remote host first.
- **Not a Proxmox replacement for production.** Flint is a clean management UI for existing libvirt/KVM setups — it doesn't do clustering, HA, live migration, or storage pool management at Proxmox's scale. For homelabs and dev servers it's excellent; for enterprise KVM → Proxmox or oVirt.
- **"Built in a few hours" pedigree.** Honest upstream README note. The tool is functional and has active development, but expect rough edges compared to mature projects. Test before deploying VMs you care about.

## Project health

Active releases, CI (GitHub Actions), solo-maintained by volantvm/ccheshirecat, embedded in the Chaser platform ecosystem.

## KVM-management-family

- **Flint** — single binary, no XML, embedded web UI + CLI + API, homelab/devserver focus
- **Proxmox VE** — full enterprise KVM hypervisor, clustering, HA, production-grade, heavier
- **Virt-Manager** — GTK desktop GUI for libvirt; no web UI
- **Cockpit + cockpit-machines** — browser-based sysadmin UI with VM management
- **oVirt** — enterprise KVM management, Red Hat lineage, complex
- **KVM CLI** (`virsh`, `virt-install`) — full control, zero UI

**Choose Flint if:** you want a clean zero-XML web + CLI interface for managing KVM/libvirt VMs on a homelab or dev server, with remote management via SSH and a modern UI.

## Links

- Repo: <https://github.com/0xchasercat/flint>
- Releases: <https://github.com/volantvm/flint/releases>
- Proxmox (alt): <https://www.proxmox.com>
- Cockpit (alt): <https://cockpit-project.org>
