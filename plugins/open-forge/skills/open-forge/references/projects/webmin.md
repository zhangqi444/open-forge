---
name: Webmin
description: "Powerful web-based system administration control panel for Unix-like servers. ~1M yearly installs. Manages users, filesystems, packages, firewall, services, DNS, Apache, MySQL — 116 built-in modules + third-party. Perl. BSD-like license (historic). Pairs with Virtualmin (web-hosting panel) and Usermin (user-facing subset)."
---

# Webmin

Webmin is **the classic, mature, still-maintained web-based sysadmin control panel** — in continuous development since **1997** by **Jamie Cameron**, ~1 million yearly installations. Point your browser at `https://server:10000/` and manage virtually every aspect of a Unix/Linux server: users and groups, disk quotas, cron jobs, network config, firewall, LSM/SELinux, iSCSI, LVM, RAID, NFS/Samba, BIND DNS, DHCP, Apache, Nginx, Postfix/Sendmail, MySQL/MariaDB/Postgres, log files, package management, systemd services, cluster coordination — **116 built-in modules** plus a large third-party module ecosystem.

**Companion projects:**
- **Virtualmin** — web hosting control panel on top of Webmin (cPanel alternative); separate recipe likely
- **Usermin** — slimmer, user-facing subset (users manage their own account, email, files)

- Upstream repo: <https://github.com/webmin/webmin>
- Website: <https://webmin.com>
- Docs: <https://webmin.com/docs/>
- FAQ: <https://webmin.com/faq/>
- Security: <https://webmin.com/security/>
- Screenshots: <https://webmin.com/screenshots/>
- Forum: <https://forum.virtualmin.com/c/webmin/12>
- Download: <https://webmin.com/download>
- Changelog: <https://github.com/webmin/webmin/blob/master/CHANGELOG.md>

## Architecture in one minute

- **Perl** monolith; ships its own mini-webserver (`miniserv.pl`) on port **10000** (HTTPS by default)
- **Root-level access** to the OS — Webmin essentially runs commands as root (with ACL controls per user)
- Modules are Perl scripts + CGI templates — easy to extend
- **No database** — config stored in `/etc/webmin/`
- **Agentless** — each server runs its own Webmin daemon; "Webmin clustering" federates multiple
- **Tiny footprint** — ~50-100 MB RAM

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM/server   | **Official Debian/Ubuntu + RHEL/Rocky/Alma RPM repos**              | **Upstream-recommended**                                                           |
| Single VM          | Official tarball install (`setup.sh`)                                       | For distros without packages                                                                           |
| Single VM          | Community Docker images                                                                     | Unusual — Webmin is a host-management tool; in a container it has limited reach                                                             |
| Raspberry Pi       | Great fit — ARM binaries available                                                                         | Manage your Pi via web                                                                                                   |
| FreeBSD / OpenBSD  | Official pkg                                                                                               | Webmin originated on Unix and still supports BSDs                                                                                                                   |
| Virtualmin stack   | Install Webmin + Virtualmin together for full web-hosting panel                                                                      | `install.sh` from virtualmin.com                                                                                                                                                      |

## Inputs to collect

| Input                  | Example                                 | Phase        | Notes                                                                     |
| ---------------------- | --------------------------------------- | ------------ | ------------------------------------------------------------------------- |
| Hostname               | FQDN the server is addressed by                | URL          | Used for TLS cert                                                                 |
| Port                   | `10000`                                           | Network      | **Never expose to internet — bind to LAN/VPN or tunnel**                                                                 |
| Root creds             | Webmin authenticates via Unix `root` or configured users    | Auth         | **2FA strongly recommended + allow-list IPs**                                                                                                         |
| TLS                    | Let's Encrypt (Webmin has built-in ACME client)                       | Security     | Or bring your own cert                                                                                                                |
| Allowed IPs            | LAN / VPN / tailnet only                                              | Hardening    | `Webmin Configuration → IP Access Control`                                                                                                                                            |

## Install on Debian/Ubuntu

```sh
curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
sudo sh setup-repos.sh
sudo apt install --install-recommends webmin
```

Browse `https://<server>:10000/` — log in with your Unix `root` account.

## Install on RHEL/Rocky/Alma

```sh
curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
sudo sh setup-repos.sh
sudo dnf install webmin
```

## First boot

1. Browse → accept the self-signed cert (or install Let's Encrypt via Webmin itself)
2. Log in as `root` (or a sudoer)
3. **Webmin → Webmin Configuration → IP Access Control** → allow only LAN/VPN IPs
4. **Webmin → Webmin Configuration → Two-Factor Authentication** → enable TOTP
5. **Webmin → Webmin Configuration → SSL Encryption** → Let's Encrypt → request cert for your FQDN
6. **Webmin → Webmin Users** → create per-admin accounts (don't share root)
7. Explore modules needed for your workload (Apache, Postfix, BIND, etc.)
8. (Optional) install Usermin for user-self-service

## Data & config layout

- `/etc/webmin/` — all Webmin config (modules, users, ACLs)
- `/var/webmin/` — logs + session data
- `/usr/libexec/webmin/` or `/usr/share/webmin/` — module code
- `/etc/webmin/miniserv.conf` — web server config (port, SSL, IP ACL)

## Backup

```sh
# Config (CRITICAL — users, ACLs, module settings)
sudo tar czf webmin-$(date +%F).tgz /etc/webmin/
```

Webmin's state is configuration only. The thing it manages (the server) is backed up separately.

## Upgrade

1. Releases: <https://github.com/webmin/webmin/releases>. Active; regular minor/bugfix releases.
2. **Apt/dnf upgrade handles it.**
3. **Auto-upgrade feature** inside Webmin — convenient; verify after upgrade.
4. Custom modules may need update; check compatibility.

## Gotchas

- **Webmin runs as root with web access.** Compromising Webmin = compromising the host. Treat it like SSH:
  - **Never expose port 10000 to the public internet.** Use VPN / WireGuard / Tailscale / SSH tunnel / reverse proxy with auth.
  - **Enable 2FA immediately.**
  - **IP allow-list** in Webmin's config.
  - **TLS mandatory.** Install Let's Encrypt via Webmin (built-in) or provide your own cert.
- **Historical CVEs**: Webmin has had significant security advisories (including the infamous 2019 backdoor incident on the download host — see <https://www.webmin.com/security.html>). Modern Webmin is solid but the threat model is real: keep updated + subscribe to security announcements.
- **Modules are powerful**: a user with "all modules" access is effectively root. Use ACLs to scope per-user access (e.g., "Jane can only manage Apache").
- **Clustering is rudimentary**: Webmin has "cluster-wide" module versions but isn't a real config-management system. For fleet management beyond a handful of hosts, use Ansible/Puppet/Chef/Salt.
- **Perl legacy**: codebase is Perl; contributions are possible but the pool of Perl hackers is shrinking. Project is still maintained (Jamie Cameron + small core team).
- **Not a container**: Webmin in Docker has limited reach — can only manage what's inside the container. Most meaningful use is on a real host/VM.
- **ACL file editing**: direct edits to `/etc/webmin/miniserv.users` + module ACLs are powerful; mis-edits can lock you out. Keep SSH access as recovery path.
- **Password changes**: if you change a user's Unix password, Webmin authenticates against Unix; so Webmin login updates automatically.
- **Certificate renewal**: Webmin's ACME client handles Let's Encrypt; make sure port 80 is reachable for HTTP-01 challenge OR configure DNS-01.
- **Modular deprecations**: over the years some modules (CVS, old mail systems) get marked deprecated — don't rely on deprecated modules for core infra.
- **UI dated but functional**: Webmin looks late-2010s. The "Authentic Theme" modernizes it significantly — installed by default now.
- **Usermin vs Webmin**: Webmin = admin; Usermin = user self-service (read email, change password, manage own files). Install both on multi-tenant Unix boxes.
- **Virtualmin**: the full web-hosting panel (virtual hosts, email hosting, DBs) — separate product but built on Webmin.
- **License**: Webmin is distributed under a **BSD-like license** (see repo `LICENCE` file); FOSS-friendly.
- **Download integrity**: always verify package signatures (GPG). The 2019 incident involved compromised tarballs on the primary host — always use signed repos.
- **Alternatives worth knowing:**
  - **Cockpit** — modern, lightweight admin UI (Red Hat; dominant on RHEL/Fedora/CentOS Stream); much simpler scope (separate recipe likely)
  - **Portainer** — Docker/Swarm/K8s container UI (not host admin) (separate recipe likely)
  - **Ajenti** — Python-based admin panel; lighter
  - **Webvirtcloud** — KVM/libvirt-focused
  - **cPanel / Plesk** — commercial web-hosting panels
  - **CloudPanel / HestiaCP / ISPConfig** — free web-hosting panels
  - **Ansible/Puppet/Chef/Salt** — not UIs, but proper fleet config management
  - **Choose Webmin if:** single-server/small-fleet, mature, want huge module catalog, Unix sysadmin background.
  - **Choose Cockpit if:** modern RHEL/Fedora/CentOS; simpler day-to-day tasks.
  - **Choose Portainer if:** containers specifically.
  - **Choose Ansible if:** >10 hosts, repeatable config.

## Links

- Repo: <https://github.com/webmin/webmin>
- Website: <https://webmin.com>
- Docs: <https://webmin.com/docs/>
- Modules list: <https://doxfer.webmin.com/Webmin/Webmin_Modules>
- Download: <https://webmin.com/download>
- Security: <https://webmin.com/security/>
- Forum: <https://forum.virtualmin.com/c/webmin/12>
- Virtualmin: <https://www.virtualmin.com>
- Usermin: <https://github.com/webmin/usermin>
- Releases: <https://github.com/webmin/webmin/releases>
- Cockpit (alt): <https://cockpit-project.org>
- Portainer (alt): <https://www.portainer.io>
