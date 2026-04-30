---
name: OPNsense
description: "Open-source FreeBSD-based firewall + router platform — enterprise feature set, web UI, VPN (WireGuard/OpenVPN/IPsec), IDS/IPS (Suricata/Zenarmor), web filtering, plugins. Community + commercial business edition. Deciso B.V. BSD-2-Clause (core)."
---

# OPNsense

OPNsense is **the open-source enterprise-class firewall + router** — FreeBSD-based, HardenedBSD-hardened, web-UI-managed; covers stateful firewall, VPN (WireGuard/OpenVPN/IPsec/Tailscale), IDS/IPS (Suricata/Zenarmor), web filtering, traffic shaping, multi-WAN + failover, captive portal, DHCP/DNS (Unbound — batch 80 companion!), DNSSEC, reporting, high-availability, 2FA, a mature plugin ecosystem, RADIUS, LDAP/AD auth, VLAN, TAP/TUN, and professional weekly-ish release cadence.

Developed + maintained by **Deciso B.V.** (Netherlands) — commercial company behind OPNsense with **Business Edition** (paid subscription for enterprises; funds upstream development). Community Edition is BSD-2-Clause and fully-featured.

Forked from **pfSense** in 2014-2015 (philosophy + governance differences) → has since evolved distinct codebase + plugins + release discipline. Both are solid FreeBSD-based firewalls; differences are cultural/licensing/feature-set.

Features:

- **Firewall**: stateful inspection, NAT, traffic shaping, aliases, groups
- **VPN**: WireGuard, OpenVPN, IPsec, L2TP, Tailscale (plugin)
- **IDS/IPS**: Suricata (in-line or tap); Zenarmor plugin (L7 app-aware)
- **Web filtering**: proxy (Squid), blocklist subscription
- **DNS**: Unbound (DNSSEC-validating) + DHCP server
- **Captive portal** (hotspot)
- **Multi-WAN + gateway failover**
- **HA**: CARP + pfsync
- **Auth**: 2FA (TOTP), LDAP, RADIUS, AD integration
- **Reporting**: NetFlow, RRD graphs, state tables
- **Plugin ecosystem**: os-acme-client, os-wireguard, os-tailscale, os-zenarmor, os-nextcloud-backup, etc.
- **Weekly-ish stable + monthly-ish dev releases**
- **Professionally audited**: Coverity Scan

- Upstream repo: <https://github.com/opnsense/core>
- Homepage: <https://opnsense.org>
- Forum: <https://forum.opnsense.org>
- Docs: <https://docs.opnsense.org>
- Architecture: <https://docs.opnsense.org/development/architecture.html>
- Build tools: <https://github.com/opnsense/tools>
- Download: <https://opnsense.org/download/>
- Business Edition: <https://shop.opnsense.com>
- Coverity Scan: <https://scan.coverity.com/projects/opnsense-core>
- Deciso B.V.: <https://www.deciso.com>

## Architecture in one minute

- **FreeBSD / HardenedBSD** base OS
- **Web UI** in PHP (backend CLI in Python + shell)
- **PFsense-fork legacy → modern rewrite** — gradual codebase modernization documented in architecture
- **Config file `/conf/config.xml`** — everything declarative (great for backups + diff review)
- **Resource**: small router = Atom/Celeron N5105 + 8GB RAM handles gigabit; larger deployments scale up

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Bare-metal router  | **Dedicated box** (Netgate/Protectli/mini-PC)                      | **Upstream-primary** — purpose-built router                                        |
| Virtualized        | Proxmox / ESXi / KVM / Hyper-V VM with PCIe NIC passthrough OR bridged | Common for homelab; NIC passthrough for performance                                                      |
| Cloud instance     | AWS / Azure / DigitalOcean — supported but niche                                      | Edge gateways + VPN concentrators                                                                                 |
| Deciso Hardware    | Pre-loaded OPNsense appliances from Deciso                                                       | Commercial hardware                                                                                              |

## Inputs to collect

| Input                | Example                                                       | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Hardware             | CPU with AES-NI, 2+ Intel NICs (not Realtek if possible)            | Prereq       | Realtek NICs on FreeBSD are historically flaky                                  |
| Install media        | OPNsense nano / dvd image                                                | Install      | Written to USB via dd                                                                       |
| WAN interface        | From ISP — DHCP / static / PPPoE                                                | Network      | Clarify with ISP                                                                                          |
| LAN interface + subnet | `192.168.1.0/24` default                                                              | Network      | Change default; `192.168.1.x` is collision-prone with other routers                                                 |
| Admin password       | set during install                                                                      | Bootstrap    | Strong; rotate default `opnsense`                                                                                                    |
| Cert (for web UI)    | self-signed default; replace with internal CA or Let's Encrypt                                 | TLS          | os-acme-client plugin integrates Let's Encrypt                                                                                               |
| DNS servers          | Unbound bundled (RECOMMENDED) / external                                                                   | DNS          | Unbound integration is first-class (batch 80 companion)                                                                                            |

## Install

1. Download installer image from <https://opnsense.org/download/>
2. Write to USB: `dd if=OPNsense-xx.img of=/dev/sdX bs=1M`
3. Boot on target hardware; follow installer
4. Set WAN + LAN interfaces; initial admin pass; reboot
5. Connect laptop to LAN → browse `https://192.168.1.1`
6. Complete web setup wizard: timezone, hostname, passwords, DHCP for LAN

## First boot

1. Change default admin password (first boot prompts)
2. Update to latest: System → Firmware → Check for updates → Apply
3. Configure DHCP scope on LAN (adjust to your network)
4. Enable 2FA for admin: System → Access → Users → edit admin → enable TOTP
5. Enable Unbound (Services → Unbound DNS) — DNSSEC validation + blocklists
6. **Replace self-signed web-UI cert** with Let's Encrypt or internal CA
7. Back up `/conf/config.xml` (download via System → Configuration → Backups)
8. Configure WireGuard / OpenVPN if VPN needed
9. Enable Suricata IDS if you want intrusion detection
10. Review firewall default rules — tighten where needed
11. Set up remote backup (plugin or scheduled SCP)

## Data & config layout

- `/conf/config.xml` — ALL configuration as XML (firewall rules, interfaces, users, VPN, DHCP, DNS, plugins)
- `/var/log/` — logs
- `/var/backups/` — automatic config backups (previous versions)
- Packages/plugins in `/usr/local/`

## Backup

```
System → Configuration → Backups → Download Configuration
```
Back up the XML. Off-site + encrypted. This file = everything. You can bare-metal reinstall + restore in minutes.

## Upgrade

1. **Business Edition** = supported stable releases aligned with enterprise policies
2. **Community Edition** = weekly patches + bi-annual major releases (22.x, 22.7, 23.1, 23.7, 24.1, 24.7, etc.)
3. **Upgrade path**: System → Firmware → Check → Apply. OPNsense rolling updates are very reliable; Deciso's release discipline is a signal.
4. **Back up config.xml before major upgrades.**
5. Major releases occasionally shift defaults — read release notes.

## Gotchas

- **Realtek NICs on FreeBSD are a known pain.** Historically flaky drivers; random disconnects; worse performance. Prefer **Intel NICs** (1G i226/i350; 10G X520/X710). Before buying hardware, verify NIC chipset. Netgate and Protectli ship Intel NICs.
- **CPU with AES-NI** is highly recommended for VPN performance (OpenVPN + WireGuard + IPsec all benefit). Modern Intel + AMD CPUs have it; very old Atom CPUs don't.
- **Virtualized firewall gotchas**: passthrough NICs if possible (PCIe passthrough) for line-rate + to avoid virt-layer issues. Bridged NICs work but MAC-spoofing + promiscuous on vSwitch can trip up hypervisors. If you virtualize your router, your hypervisor going down = internet going down. Plan recovery.
- **Don't expose web UI to WAN.** Default config blocks but verify. Access via VPN or internal network ONLY. Unauthenticated web UI = take-over-your-network attack surface.
- **Change default credentials IMMEDIATELY.** Default admin creds are documented publicly. Script-kiddie scanners hammer default-cred routers constantly.
- **pfSense vs OPNsense**: similar pedigree; cultural differences. pfSense has more US enterprise mindshare; OPNsense has more EU mindshare + weekly patch cadence + BSD-2 (more liberal than pfSense's Apache + Netgate's brand/trademark constraints). Both excellent. Pick based on community preference + local support.
- **Plugin trust**: os-acme-client is first-party; some community plugins have varying quality. Read GitHub + forum before installing.
- **HA (CARP) requires matched pair** of hardware — two identical boxes for reliable failover. Homelab-overkill; SMB/enterprise-sensible.
- **Traffic shaping** is powerful + complex. CBQ + HFSC + codel — read the docs. Easy to misconfigure + degrade performance.
- **Suricata IDS** at line rate needs CPU + RAM. On a low-end appliance enable on specific interfaces only (e.g., WAN); full-fat-mode needs beefier hardware.
- **Zenarmor plugin** adds L7 app-aware filtering but has **commercial tier for advanced features** — free tier covers basics; Professional tier for TLS inspection + more rules. Up-front license awareness.
- **WireGuard is THE modern VPN** — simpler, faster, smaller attack surface than OpenVPN/IPsec. Use it unless you need compat with old gear.
- **Tailscale plugin** lets you join a Tailscale tailnet with OPNsense as a subnet router — very useful for hybrid cloud + remote-home-LAN-access.
- **DNS over TLS upstream** via Unbound: easy config win for privacy.
- **config.xml-as-source-of-truth** mindset — treat it as IaC. Git-track with redacted secrets. Diff review before applying. Recoverable in minutes from a working backup.
- **License**: **BSD-2-Clause** (core). Plugins vary.
- **Project health**: Deciso B.V. commercial company + community. Funded + disciplined. Excellent long-term bet.
- **Ethical purchase**: Business Edition subscription directly funds Deciso + upstream development. Consider if your org depends on OPNsense (same commercial-tier-funds-upstream pattern as Statamic Pro, Baserow Premium, MediaCMS Elestio, etc.).
- **Alternatives worth knowing:**
  - **pfSense CE / pfSense+** — the fork source; Netgate-backed; widely deployed
  - **VyOS** — CLI-first network OS; Linux kernel; configuration-as-code; enterprise
  - **OpenWrt** — Linux router OS; great for consumer routers + deep customization
  - **Untangle / NG Firewall** — commercial
  - **MikroTik RouterOS** — proprietary; popular for ISP/WISP
  - **Commercial enterprise**: Palo Alto, Fortinet, Cisco — different price bracket
  - **Choose OPNsense if:** want FreeBSD stability + weekly-patch discipline + BSD-2 + EU community.
  - **Choose pfSense CE if:** prefer pfSense heritage / US-forum community.
  - **Choose VyOS if:** want CLI + config-as-code + Linux.
  - **Choose OpenWrt if:** consumer router + hack-friendly + smaller scale.

## Links

- Repo: <https://github.com/opnsense/core>
- Homepage: <https://opnsense.org>
- Docs: <https://docs.opnsense.org>
- Forum: <https://forum.opnsense.org>
- Download: <https://opnsense.org/download/>
- Plugins: <https://docs.opnsense.org/development/examples/plugins.html>
- Business Edition: <https://shop.opnsense.com>
- Architecture docs: <https://docs.opnsense.org/development/architecture.html>
- Build tools: <https://github.com/opnsense/tools>
- Deciso hardware: <https://shop.deciso.com>
- Coverity: <https://scan.coverity.com/projects/opnsense-core>
- pfSense (alt): <https://www.pfsense.org>
- VyOS (alt): <https://vyos.io>
- OpenWrt (alt): <https://openwrt.org>
- Unbound companion (batch 80): <https://github.com/NLnetLabs/unbound>
- Zenarmor plugin: <https://www.zenarmor.com>
