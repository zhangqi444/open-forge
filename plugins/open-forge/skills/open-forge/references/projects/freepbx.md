---
name: freepbx
description: FreePBX recipe for open-forge. Web-based GUI for managing Asterisk VoIP PBX. Call routing, IVR, voicemail, extensions, trunks. GPL-2.0, PHP. Source: https://git.freepbx.org/projects/FREEPBX
---

# FreePBX

The most widely deployed open-source web GUI for managing Asterisk — the industry-standard VoIP PBX engine. Provides a point-and-click interface for configuring extensions, trunks, ring groups, IVR menus, call queues, voicemail, time conditions, and call recording. Powers millions of phone systems globally. GPL-2.0 licensed, PHP frontend over Asterisk. Website: <https://www.freepbx.org/>. Source: <https://git.freepbx.org/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Bare metal / VPS | FreePBX Distro ISO | Official installer — recommended for production |
| Existing Debian / CentOS | Manual install on top of Asterisk | More complex; follow admin guide |
| VirtualBox / VMware | FreePBX Distro ISO | Good for testing and dev |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Dedicated server for FreePBX?" | Yes / No | FreePBX should own the machine — not a shared host |
| "SIP trunk provider?" | Provider name + credentials | e.g. Twilio, Vonage, local carrier — for PSTN connectivity |
| "Extensions to provision?" | Count + DID range | e.g. 100-199 for internal extensions |
| "Public IP / static IP?" | IP or FQDN | For SIP trunk registration and NAT configuration |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Admin email?" | email | For FreePBX admin account |
| "Time zone?" | TZ string | Affects voicemail timestamps and time conditions |
| "VoIP phones?" | Physical / Softphone | For endpoint provisioning (DPMA or manual) |

## Software-Layer Concerns

- **Asterisk dependency**: FreePBX is a GUI for Asterisk — Asterisk must be installed and running. The FreePBX Distro installs both together.
- **FreePBX Distro**: The official installer ISO (based on CentOS/Rocky) is the easiest path — includes Asterisk, FreePBX, database, and HTTPD pre-configured.
- **MySQL/MariaDB**: FreePBX stores config in MySQL — included in the Distro install.
- **SIP ALG**: Disable SIP ALG on your router/firewall — it breaks SIP NAT traversal.
- **NAT configuration**: FreePBX must know its external IP and local subnet for correct SIP signaling behind NAT.
- **Port requirements**: UDP 5060 (SIP), UDP 10000-20000 (RTP audio), TCP 80/443 (web admin). Restrict web admin to trusted IPs.
- **Module system**: FreePBX functionality is modular — install/update modules via Admin → Module Admin.
- **Commercial modules**: Many advanced features (Parking Pro, Contact Manager, etc.) require paid Sangoma commercial modules.

## Deployment

### FreePBX Distro (recommended)

```bash
# 1. Download ISO from https://www.freepbx.org/freepbx-distro/
# 2. Boot from ISO on bare metal or VM
# 3. Follow interactive installer (sets hostname, timezone, admin password)
# 4. After install, access web UI at http://<server-ip>/admin
# 5. Complete Setup Wizard in the browser
```

### Post-install: SIP trunk setup

In FreePBX Admin:
1. **Connectivity → Trunks** → Add SIP trunk with your provider credentials
2. **Connectivity → Outbound Routes** → Route calls to the trunk
3. **Connectivity → Inbound Routes** → Route incoming DIDs to extensions/IVR
4. **Applications → Extensions** → Add extensions for each phone

### Firewall rules

```bash
# Allow SIP and RTP from SIP trunk provider IPs only
firewall-cmd --add-port=5060/udp --permanent
firewall-cmd --add-port=10000-20000/udp --permanent
firewall-cmd --add-port=80/tcp --permanent   # restrict to admin IPs
firewall-cmd --add-port=443/tcp --permanent
firewall-cmd --reload
```

### Fail2Ban (included in Distro)

```bash
# FreePBX Distro includes Fail2Ban pre-configured for SIP brute force
systemctl status fail2ban
# Check banned IPs:
fail2ban-client status asterisk
```

## Upgrade Procedure

1. In FreePBX Admin: **Admin → Module Admin → Check Online** → update all modules.
2. For FreePBX version upgrades, use `fwconsole upgrade` or the Distro's `yum update`.
3. Full system backup via **Admin → Backup & Restore** before any major upgrade.
4. Test with a staging system before upgrading production.

## Gotchas

- **Dedicated server only**: FreePBX/Asterisk takes over the system — don't run on shared servers.
- **SIP ALG must be disabled**: Any router/firewall with SIP ALG enabled will mangle SIP packets and cause one-way audio or failed calls.
- **NAT configuration critical**: Set external IP and local subnet in FreePBX SIP settings (`Admin → Asterisk SIP Settings`) or calls behind NAT will fail.
- **Web admin exposure**: Never expose port 80/443 to the public internet without strong password + fail2ban. SIP scanners will brute-force your system.
- **RTP port range**: UDP 10000-20000 must be open for audio — missing RTP = one-way audio.
- **Commercial modules**: Many features shown in documentation require paid Sangoma modules — check licensing before planning feature set.
- **SIP vs PJSIP**: FreePBX 14+ defaults to PJSIP (chan_pjsip) driver — some older trunk configs may need `chan_sip` settings.

## Links

- Website: https://www.freepbx.org/
- FreePBX Distro download: https://www.freepbx.org/freepbx-distro/
- Documentation: https://wiki.freepbx.org/
- Source (Gitea): https://git.freepbx.org/projects/FREEPBX
- Community forum: https://community.freepbx.org/
