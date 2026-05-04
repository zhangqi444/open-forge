---
name: cockpit-project
description: Cockpit recipe for open-forge. Covers package-manager installation of Cockpit, a web-based server management interface providing systemd service control, storage management, networking, terminal access, and Podman container management. NOT a Docker deployment — installed via apt/dnf on the host. Includes TLS setup, extensions, and upgrade guidance.
---

# Cockpit

Cockpit is a web-based server management interface. Provides systemd service control, storage management, networking, terminal, and Podman container management, among other features. Upstream: <https://github.com/cockpit-project/cockpit>. Docs: <https://cockpit-project.org/>.

**Cockpit is NOT available as a Docker image.** It requires systemd on the host and deep OS integration — it manages the very system it runs on. Install it via the host package manager only.

Cockpit listens on port `9090` and serves a web UI backed by the host's D-Bus and systemd APIs. Authentication uses the host's PAM stack (system users).

## Install method

| Method | When to use |
|---|---|
| `apt install cockpit` | Debian / Ubuntu / Raspberry Pi OS |
| `dnf install cockpit` | Fedora / RHEL / CentOS Stream / AlmaLinux / Rocky Linux |
| `zypper install cockpit` | openSUSE Leap / Tumbleweed |

There is no Docker image. There is no pip/snap/flatpak path for the server daemon. If you need container isolation, Cockpit is not the right tool for that requirement.

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which distro / package manager?" | Determines install command |
| preflight | "Will Cockpit be accessible from the public internet?" | Drives TLS setup requirement |
| tls | "TLS via Let's Encrypt (requires a public domain) or self-signed?" | Drives cert provisioning approach |
| extensions | "Which extensions do you need? (cockpit-machines, cockpit-podman, cockpit-storaged, etc.)" | Determines additional packages to install |

## Installation

### Debian / Ubuntu

```bash
sudo apt update
sudo apt install -y cockpit

# Enable and start
sudo systemctl enable --now cockpit.socket

# Open firewall (ufw)
sudo ufw allow 9090/tcp
```

### Fedora / RHEL 9+ / CentOS Stream / AlmaLinux / Rocky Linux

```bash
sudo dnf install -y cockpit

# Enable and start
sudo systemctl enable --now cockpit.socket

# Open firewall (firewalld)
sudo firewall-cmd --add-service=cockpit --permanent
sudo firewall-cmd --reload
```

### openSUSE

```bash
sudo zypper install -y cockpit
sudo systemctl enable --now cockpit.socket
```

## Access

Once installed, Cockpit is available at:

```
https://<server-ip-or-hostname>:9090/
```

Log in with any system user account that has `sudo` / `wheel` group membership for administrative functions. Cockpit uses PAM — no separate user database.

## TLS

### Default (self-signed)

Cockpit generates a self-signed certificate automatically on first start. Stored at `/etc/cockpit/ws-certs.d/`. The browser will show a certificate warning; proceed past it for internal use.

### Let's Encrypt (public domain)

```bash
# Install certbot
sudo apt install -y certbot   # or dnf install certbot

# Obtain a certificate
sudo certbot certonly --standalone -d cockpit.example.com \
  --email admin@example.com --agree-tos --non-interactive

# Copy certs to cockpit's cert dir
sudo cp /etc/letsencrypt/live/cockpit.example.com/fullchain.pem \
        /etc/cockpit/ws-certs.d/cockpit.cert
sudo cp /etc/letsencrypt/live/cockpit.example.com/privkey.pem \
        /etc/cockpit/ws-certs.d/cockpit.key
sudo chmod 640 /etc/cockpit/ws-certs.d/cockpit.key

# Restart cockpit
sudo systemctl restart cockpit
```

Alternatively, if you already have a reverse proxy (nginx/Caddy) handling TLS on port 443, configure it to proxy to `http://127.0.0.1:9090/` and disable Cockpit's external port. Example Caddyfile:

```
cockpit.example.com {
    reverse_proxy 127.0.0.1:9090
}
```

## Extensions (optional packages)

| Package | What it adds |
|---|---|
| `cockpit-machines` | KVM/QEMU virtual machine management (requires libvirt) |
| `cockpit-podman` | Podman container management UI |
| `cockpit-storaged` | Advanced storage management (LVM, RAID, iSCSI) |
| `cockpit-networkmanager` | Networking configuration (usually included) |
| `cockpit-selinux` | SELinux policy management (RHEL/Fedora only) |
| `cockpit-packagekit` | Software updates UI |
| `cockpit-pcp` | Performance metrics via PCP |

Install any extension the same way as Cockpit itself:

```bash
# Debian/Ubuntu
sudo apt install -y cockpit-machines cockpit-podman

# RHEL/Fedora
sudo dnf install -y cockpit-machines cockpit-podman
```

Extensions take effect immediately — no Cockpit restart required.

## Verify

```bash
sudo systemctl status cockpit.socket    # active (listening)
sudo systemctl status cockpit           # active (running) while a browser session is open

curl -sk https://localhost:9090/ | head -5   # returns HTML
```

## Lifecycle (upgrade)

```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade cockpit

# RHEL/Fedora
sudo dnf upgrade cockpit

# Restart after upgrade
sudo systemctl restart cockpit
```

Cockpit upgrades are in-place package updates. No data migration is needed — Cockpit itself is stateless (all state is the underlying OS configuration it manages).

## Cockpit configuration file

`/etc/cockpit/cockpit.conf` — override defaults:

```ini
[WebService]
AllowUnencrypted = false
LoginTitle = My Server
Origins = https://cockpit.example.com:9090

[Session]
IdleTimeout = 15   # minutes
```

Restart Cockpit after editing: `sudo systemctl restart cockpit`.

## Gotchas

- **No Docker image.** Cockpit must be installed on the host via the package manager. It cannot run in a container — it manages systemd and the host OS.
- **Requires systemd.** Cockpit uses D-Bus and systemd APIs. It will not work on systems without systemd (e.g. LXC containers with no systemd, or minimal Docker base images).
- **PAM authentication.** Cockpit authenticates via system PAM. The user must have a local system account. Root login is typically disabled via PAM configuration — use a `sudo`-capable user.
- **TLS warning on first visit.** The default self-signed cert triggers browser warnings. This is expected for internal use; provision a real cert via Let's Encrypt for public-facing deployments.
- **Extensions are distro packages.** `cockpit-machines`, `cockpit-podman`, etc. are separate packages; install them with the same package manager as Cockpit.
- **Port 9090 conflict.** Some monitoring tools (Prometheus Node Exporter historically used 9100; SonarQube uses 9000) or other services may conflict on 9090. Adjust if needed via `cockpit.conf`.
- **Podman vs Docker.** `cockpit-podman` manages Podman containers, not Docker. For Docker management, consider Portainer instead.
