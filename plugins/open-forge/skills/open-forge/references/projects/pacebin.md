---
name: pacebin
description: Pacebin recipe for open-forge. Minimalist self-hosted pastebin written in C with NGINX integration. No database, filesystem-based storage. AGPL-3.0. Source: https://git.swurl.xyz/swirl/pacebin
---

# Pacebin

A minimalist, high-performance self-hosted pastebin written in C. No database required — pastes are stored as plain files on the filesystem. Integrates with NGINX via FastCGI. Very low resource footprint, suitable for single-user or small-team use. AGPL-3.0 licensed. Source: <https://git.swurl.xyz/swirl/pacebin>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | NGINX + FastCGI + systemd | Primary supported deployment |
| Any Linux | NGINX + FastCGI (non-systemd) | Works without systemd |

> No Docker image is provided upstream — source compilation required.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. paste.example.com |
| "Paste storage directory?" | Path | Where paste files are saved; set in environment config |
| "Port?" | Number | Default 8081 (pacebin listens on localhost) |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Max paste size?" | Bytes | Configurable in environment file |
| "TLS?" | Yes / No | Handled by NGINX |

## Software-Layer Concerns

- **C build required**: No pre-built binaries or Docker image — must compile from source.
- **Dependencies**: Requires glibc (or compatible libc), optionally libcrypt, and Git. Most Linux distros include these.
- **Filesystem storage**: Pastes are stored as files — no database setup needed. Storage directory must be writable by the pacebin process.
- **FastCGI via NGINX**: Pacebin communicates with NGINX over FastCGI (TCP socket on localhost:8081 by default).
- **Environment file**: `/etc/pacebin.conf` (installed by `make install-systemd`) controls paste directory, port, and limits.
- **systemd service**: Installed by `make install-systemd`; enable with `systemctl enable --now pacebin`.

## Deployment

### Build from source

```bash
# Install build dependencies (Debian/Ubuntu example)
apt install gcc make git libcrypt-dev

# Clone the repo
git clone https://git.swurl.xyz/swirl/pacebin.git && cd pacebin

# Compile
make

# Install (binary + NGINX config + systemd unit)
make install
# or without systemd:
make install-bin install-nginx

# Optionally specify prefix/DESTDIR for packaging:
# make prefix=/usr DESTDIR="${pkgdir}" install
```

### Configure

```bash
# Edit the environment file (installed to /etc/pacebin.conf)
vim /etc/pacebin.conf
# Set paste storage directory, max size, port as needed
```

### Start service (systemd)

```bash
systemctl enable --now pacebin
# Confirm listening on localhost:8081
ss -tlnp | grep 8081
```

### NGINX configuration

The `make install-nginx` command installs a pre-configured NGINX snippet. Sample:

```nginx
server {
    listen 443 ssl;
    server_name paste.example.com;

    location / {
        fastcgi_pass 127.0.0.1:8081;
        include fastcgi_params;
    }
}
```

```bash
# Reload NGINX after configuration
nginx -t && systemctl reload nginx
```

## Upgrade Procedure

1. `cd pacebin && git pull`
2. `make`
3. `make install` (overwrites binary and config files)
4. `systemctl restart pacebin`

## Gotchas

- **No Docker**: Pacebin has no upstream Docker image — build from source only.
- **libcrypt dependency**: Some minimal distributions may not have libcrypt by default — install `libxcrypt` (Arch) or `libcrypt-dev` (Debian).
- **NGINX required**: Pacebin speaks FastCGI — it cannot be exposed directly to the internet without a reverse proxy.
- **Paste storage permissions**: The paste directory must be writable by the user running the pacebin service. Verify ownership after install.
- **Minimal feature set by design**: No syntax highlighting, no expiry, no user accounts — intentionally bare-bones.

## Links

- Source: https://git.swurl.xyz/swirl/pacebin
- Mirror: https://github.com/nicholaschiasson/pacebin (may lag behind)
