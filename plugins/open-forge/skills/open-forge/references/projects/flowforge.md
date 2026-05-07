---
name: flowforge
description: FlowFuse (formerly FlowForge) recipe for open-forge. DevOps platform for Node-RED — collaborative development, remote deployment management, and enterprise-grade security for industrial IoT applications. Source: https://github.com/FlowFuse/flowfuse
---

# FlowFuse

DevOps platform for Node-RED (formerly named FlowForge). Provides team collaboration, scalable remote deployment of Node-RED instances, CI/CD pipelines, audit trails, and role-based access controls for industrial IoT and automation teams. Available as FlowFuse Cloud (managed) or self-hosted.

Upstream: <https://github.com/FlowFuse/flowfuse> | Docs: <https://flowfuse.com/docs> | Installer: <https://github.com/FlowFuse/installer>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux (Ubuntu 20.04+, Debian, Fedora 35, CentOS 8, RHEL 8, Amazon Linux 2) | Node.js v20 + install script | Recommended self-hosted path |
| Raspberry Pi (Buster/Bullseye, ARMv7+) | Node.js v20 + install script | Arm6 (Pi Zero/Zero W) not supported |
| macOS (Big Sur+, Intel + Apple M) | Node.js v20 + install script | Requires manual Node.js install |
| Windows 10/11 | Node.js v20 + install script (.bat) | Requires manual Node.js + build tools |
| Any | Kubernetes (Helm) | Production-scale; separate Helm chart |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Target OS and architecture | Determines install path and Node.js source |
| preflight | Node.js v20 installed? | Install script checks; will offer to install on Linux |
| install | Install directory | Linux/macOS: /opt/flowforge recommended |
| config | Domain / base URL | Used for Node-RED instance URLs |
| config | Admin email + password | First-run setup |
| config | Email/SMTP settings (optional) | For user invitations and notifications |

## Software-layer concerns

### Install via script (Linux/macOS)

The installer is a zip archive with a shell script. It handles Node.js detection, build tools, and service setup.

```bash
# 1. Create install directory
sudo mkdir /opt/flowforge
sudo chown $USER /opt/flowforge

# 2. Download latest installer zip
cd /tmp
curl -LO https://github.com/FlowFuse/installer/releases/latest/download/flowforge-installer.zip
unzip flowforge-installer.zip
cp -R flowforge-installer/* /opt/flowforge

# 3. Run installer (interactive — checks Node.js, installs deps)
cd /opt/flowforge
./install.sh
```

On Windows, use install.bat from the same zip.

### Config paths

- Main config: /opt/flowforge/etc/flowforge.yml
- Data dir: /opt/flowforge/var/ (SQLite DB, snapshots, etc.)
- Logs: /opt/flowforge/var/log/

Key flowforge.yml settings:

```yaml
host: 0.0.0.0
port: 3000
base_url: http://localhost:3000   # set to your public URL
admin_user: admin
```

### Running as a service

The install script sets up a systemd service (Linux) or launchd plist (macOS):

```bash
# Linux
sudo systemctl start flowforge
sudo systemctl enable flowforge
sudo systemctl status flowforge

# Logs
journalctl -u flowforge -f
```

## Upgrade procedure

```bash
cd /tmp
curl -LO https://github.com/FlowFuse/installer/releases/latest/download/flowforge-installer.zip
unzip flowforge-installer.zip
cp -R flowforge-installer/* /opt/flowforge
cd /opt/flowforge
./install.sh   # re-runs upgrade path
sudo systemctl restart flowforge
```

Always back up /opt/flowforge/var/ before upgrading.

## Gotchas

- Node.js v20 is required — other versions are not supported. The Linux install script will offer to install it if not found; on Windows/macOS you must install it manually from https://nodejs.org/.
- Arm6 devices (original Pi Zero, Zero W) are not supported — only ARMv7+ Raspberry Pi boards work.
- base_url must be set to your public-facing URL (including protocol and port if non-standard) — Node-RED instances use this URL to register callbacks.
- FlowFuse manages Node-RED instances itself — do not run a separate Node-RED installation on the same host and expect FlowFuse to manage it; use FlowFuse's instance creation workflow instead.
- The self-hosted edition has feature parity with lower FlowFuse Cloud tiers; some enterprise features (SSO, advanced audit) require a license.

## Links

- Upstream: https://github.com/FlowFuse/flowfuse
- Installer: https://github.com/FlowFuse/installer
- Documentation: https://flowfuse.com/docs
- Docker / Kubernetes: https://flowfuse.com/docs/install/kubernetes/
