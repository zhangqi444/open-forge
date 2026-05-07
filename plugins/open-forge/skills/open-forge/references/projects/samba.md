---
name: samba
description: Samba recipe for open-forge. Standard Windows interoperability suite for Linux/Unix — provides SMB/CIFS file and print sharing, Active Directory domain controller, and Winbind AD integration. GPL-3.0. Source: https://www.samba.org
---

# Samba

The standard Windows interoperability suite for Linux and Unix. Provides SMB/CIFS file and print sharing compatible with Windows, macOS, and Linux clients, plus optional Active Directory Domain Controller (AD DC) functionality and Winbind for integrating Linux systems into Windows domains. GPL-3.0 licensed. Source: <https://www.samba.org>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | APT + systemd | Standard distro package; file server use case |
| Fedora / RHEL / Rocky | DNF + systemd | Standard distro package |
| Any Linux | Docker | Docker images available (dperson/samba, servercontainers/samba) |
| Any Linux | Source build | For AD DC, use Samba-bundled Kerberos (not MIT) |

> For **Active Directory DC** use: build from source or use a dedicated distro package that includes the AD DC components — standard distro packages often omit AD DC to avoid MIT Kerberos conflicts.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Use case?" | fileserver / ad-dc / ad-member | File sharing only, full AD DC, or joining existing domain |
| "Hostname?" | Short name | e.g. `fileserver` — appears as the NetBIOS name |
| "Workgroup / Domain?" | String | e.g. `WORKGROUP` for standalone; `EXAMPLE` for domain |
| "Shares to create?" | List of paths | Directories to share; one or more |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Guest access?" | Yes / No | Whether unauthenticated access is allowed |
| "Users?" | List | OS users to add to Samba with `smbpasswd -a` |
| "TLS?" | Yes / No | For LDAP/AD DC traffic; handled by Samba |

## Software-Layer Concerns

- **Config file**: `/etc/samba/smb.conf` — `[global]` section plus `[share-name]` blocks.
- **Samba users separate from OS**: Users must exist as OS users AND have a Samba password set via `smbpasswd -a username`.
- **`testparm`**: Always run `testparm` after editing `smb.conf` to validate before restarting.
- **Services**: `smbd` (file/print sharing), `nmbd` (NetBIOS name resolution), `winbindd` (AD integration) — enable as needed.
- **Firewall ports**: 137/udp (NetBIOS name), 138/udp (NetBIOS datagram), 139/tcp (NetBIOS session), 445/tcp (SMB over TCP/IP).
- **`vfs_recycle`**: VFS module that moves deleted files to a `.recycle` bin instead of permanent deletion.
- **macOS time machine**: `vfs objects = catia fruit streams_xattr` required for Time Machine share compatibility.
- **AD DC mode**: Requires its own Kerberos stack, DNS management (BIND DLZ or Samba internal DNS), and is a significant dedicated setup — see official AD DC documentation.

## Deployment

### File server (Docker — quickstart)

```yaml
services:
  samba:
    image: dperson/samba
    container_name: samba
    restart: unless-stopped
    ports:
      - "137:137/udp"
      - "138:138/udp"
      - "139:139/tcp"
      - "445:445/tcp"
    volumes:
      - /path/to/share:/share
    command: >
      -u "alice;password123"
      -s "Files;/share;yes;no;no;alice"
    environment:
      - TZ=UTC
```

### File server (native, Debian/Ubuntu)

```bash
apt install samba

# Edit config
vim /etc/samba/smb.conf
```

Sample `smb.conf`:

```ini
[global]
   workgroup = WORKGROUP
   server string = File Server
   security = user
   map to guest = bad user
   dns proxy = no

[homes]
   comment = Home Directories
   browseable = no
   read only = no
   create mask = 0700
   directory mask = 0700
   valid users = %S

[shared]
   path = /srv/samba/shared
   browseable = yes
   read only = no
   guest ok = no
   valid users = @smbusers
   create mask = 0664
   directory mask = 0775
```

```bash
# Validate config
testparm

# Create OS user and Samba password
useradd -s /usr/sbin/nologin -M alice
smbpasswd -a alice

# Create share directory with correct permissions
mkdir -p /srv/samba/shared
chown root:smbusers /srv/samba/shared
chmod 2775 /srv/samba/shared

# Restart services
systemctl enable --now smbd nmbd
systemctl restart smbd nmbd
```

### Firewall (ufw example)

```bash
ufw allow 'Samba'
# or manually:
ufw allow 137/udp
ufw allow 138/udp
ufw allow 139/tcp
ufw allow 445/tcp
```

## Upgrade Procedure

```bash
# APT
apt update && apt upgrade samba
systemctl restart smbd nmbd

# Docker
docker compose pull && docker compose up -d
```

## Gotchas

- **smbpasswd -a required**: Adding a user to Samba is a two-step process — OS user must exist AND `smbpasswd -a username` must be run. Forgetting the second step results in authentication failures.
- **Always run `testparm`**: Syntax errors in `smb.conf` cause silent failures on restart. `testparm` catches them before they hurt.
- **SMBv1 disabled by default**: Older Windows XP / Windows 7 clients require SMBv1 — do not re-enable unless absolutely necessary (security risk).
- **macOS Finder compatibility**: Without `vfs objects = catia fruit streams_xattr`, macOS may fail to write extended attributes or use Time Machine.
- **AD DC requires dedicated setup**: Do not use distro Samba packages for AD DC — they often omit `samba-ad-dc` and use MIT Kerberos which conflicts with Samba's bundled Heimdal.
- **Guest access and security**: `guest ok = yes` with `map to guest = bad user` allows unauthenticated access — only appropriate for trusted network shares.
- **Port 445 conflicts**: Some Linux distros have services binding to 445 — check `ss -tlnp | grep 445` before starting Samba.

## Links

- Homepage: https://www.samba.org
- Documentation: https://www.samba.org/samba/docs/
- smb.conf man page: https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- AD DC setup: https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller
- macOS Time Machine: https://wiki.samba.org/index.php/Configure_Samba_to_Work_Better_with_Mac_OS_X
