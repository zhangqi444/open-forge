---
name: openssh-sftp-server
description: OpenSSH SFTP server recipe for open-forge. Secure file transfer server via SFTP (SSH File Transfer Protocol). Standard system package on Linux, or containerised via the popular atmoz/sftp Docker image. Based on https://www.openssh.com/ and https://github.com/atmoz/sftp.
---

# OpenSSH SFTP Server

Secure File Transfer Program using the SSH File Transfer Protocol (SFTP). Part of OpenSSH — the most widely deployed SSH implementation. Supports multiple users, chroot jails, key-based auth, and encrypted password auth. BSD-2-Clause license. Upstream: https://www.openssh.com/. Popular Docker image: https://github.com/atmoz/sftp (atmoz/sftp — Debian and Alpine variants).

## Compatible install methods

| Method | When to use |
|---|---|
| System package (openssh-server) | Native Linux install; managed by the OS |
| Docker (atmoz/sftp) | Isolated SFTP-only container, no shell access |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| users | "SFTP username?" | String | e.g. foo |
| users | "SFTP password?" | String | Will be set in container command or users.conf |
| users | "UID for the user?" | Number (e.g. 1001) | Match host filesystem UID for volume permissions |
| network | "Port to expose SFTP on?" | Number (default 22) | Use a non-standard port (e.g. 2222) for Docker to avoid conflicts |
| storage | "Host directory to share?" | Host path | Mounted into the container at /home/USER/upload |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Protocol | SFTP over SSH (port 22 default) |
| Auth | Password or SSH key pair |
| Chroot | Users are chrooted to their home directories (Docker image) |
| Volumes | Mount host dirs under /home/USER/<subdir> — users cannot write directly to home root |
| SSH host keys | Mount /etc/ssh/ssh_host_* from host for persistent server fingerprint across container restarts |
| Image | atmoz/sftp:latest (Debian) or atmoz/sftp:alpine |

## Install: Docker (atmoz/sftp)

Source: https://github.com/atmoz/sftp

**Single user, simplest form:**

```bash
docker run -p 2222:22 -d atmoz/sftp foo:pass:::upload
```

User "foo", password "pass", can upload to ~/upload. Login: `sftp -P 2222 foo@HOST`

**Docker Compose with persistent volume:**

```yaml
services:
  sftp:
    image: atmoz/sftp
    ports:
      - "2222:22"
    volumes:
      - /srv/sftp/foo/upload:/home/foo/upload
      - /etc/ssh/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key:ro
      - /etc/ssh/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key:ro
    command: foo:CHANGEME_PASSWORD:1001
    restart: unless-stopped
```

**Multiple users via users.conf:**

Create `/etc/sftp/users.conf`:
```
foo:PASS1:1001:100
bar:PASS2:1002:100
```

```yaml
services:
  sftp:
    image: atmoz/sftp
    ports:
      - "2222:22"
    volumes:
      - /etc/sftp/users.conf:/etc/sftp/users.conf:ro
      - /srv/sftp:/home
    restart: unless-stopped
```

**SSH key-based auth (no password):**

```bash
mkdir -p /etc/sftp/keys/foo
cp ~/.ssh/id_rsa.pub /etc/sftp/keys/foo/authorized_keys
```

```yaml
    volumes:
      - /etc/sftp/keys:/home/foo/.ssh/keys:ro
```

Append to users.conf or command: `foo::1001` (empty password = keys only).

## Install: System package

```bash
# Debian/Ubuntu
apt install openssh-server

# RHEL/Fedora
dnf install openssh-server

# Enable/start
systemctl enable --now sshd
```

Configure SFTP-only chroot in `/etc/ssh/sshd_config`:

```
Match Group sftponly
    ChrootDirectory /srv/sftp/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

## Upgrade procedure

**Docker:** `docker pull atmoz/sftp && docker compose up -d`

**System package:** Standard OS package updates (`apt upgrade openssh-server`)

## Gotchas

- Volume ownership: Mount volumes under a subdirectory of the user's home (e.g. /home/foo/upload, not /home/foo). OpenSSH requires the chroot root to be owned by root; users can't write to the home directory itself.
- UID/GID matching: Set the user's UID in the container command to match the owner UID of the host directory to avoid permission mismatches.
- Persistent host keys: Without mounting host keys, the container generates new SSH host keys on each restart, causing "host key changed" warnings on every reconnect. Mount /etc/ssh/ssh_host_*_key files as read-only.
- Encrypted passwords: Append :e to the password field to pass a pre-hashed password: `foo:$1$...:e:1001`. Generate with: `openssl passwd -1 YOURPASSWORD`
- Port 22 conflict: If your host already runs sshd on port 22, expose the container on a different port (e.g. 2222) with `-p 2222:22`.
- SFTP vs FTP: SFTP (SSH File Transfer Protocol) is unrelated to FTP or FTPS. It uses the SSH protocol on port 22.

## Links

- OpenSSH upstream: https://www.openssh.com/
- Docker image (atmoz/sftp): https://github.com/atmoz/sftp
- Docker Hub: https://hub.docker.com/r/atmoz/sftp
