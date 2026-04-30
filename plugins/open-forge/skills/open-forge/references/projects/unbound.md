---
name: Unbound
description: "Validating, recursive, caching DNS resolver — the gold-standard self-hosted DNS backend. DNSSEC validation, DNS-over-TLS/HTTPS, IPv6, modern standards. Small, fast, secure. From NLnet Labs. BSD-3-Clause."
---

# Unbound

Unbound is **the reference-quality open-source recursive DNS resolver** — a validating, caching DNS server designed from scratch for security, performance, and modern standards. Built + maintained by **NLnet Labs** (Netherlands non-profit; also maintainers of **NSD** authoritative DNS + OpenBGPD/OpenSMTPD-adjacent tooling + **Routinator** RPKI validator + more) — one of the most trusted institutions in open-source DNS infrastructure.

Unbound is **not a consumer product** — it's **infrastructure**. You run it as the DNS backend behind **Pi-hole** / **AdGuard Home** / **Blocky**, or on routers (OPNsense/pfSense bundle it), or as the recursive resolver for your internal network, or as a local-only DNS validator for your dev laptop.

Features (per upstream):

- **Recursive + validating** — walks the DNS tree from root, verifies DNSSEC signatures
- **Caching** — stores answers to reduce upstream load
- **DNSSEC validation** — cryptographic DNS integrity
- **DNS-over-TLS (DoT)** + **DNS-over-HTTPS (DoH)** — encrypted transport
- **IPv6** native
- **Modern standards**: RFC-compliant, aggressive negative caching, EDNS client subnet
- **OSS-Fuzz tested** — continuously fuzz-tested (security signal)
- **Small codebase** — auditable, minimal dependencies
- **libunbound** — embed in apps

- Upstream repo: <https://github.com/NLnetLabs/unbound>
- Homepage: <https://nlnetlabs.nl/projects/unbound/about/>
- Documentation: <https://unbound.docs.nlnetlabs.nl/>
- Man page (`unbound.conf(5)`): <https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html>
- Example config: <https://github.com/NLnetLabs/unbound/blob/master/doc/example.conf.in>
- Mailing list: <https://lists.nlnetlabs.nl/mailman/listinfo/unbound-users>
- NLnet Labs: <https://nlnetlabs.nl>

## Architecture in one minute

- **C** single daemon
- **In-memory cache** + optional lightweight persistent cache
- **Config file** `/etc/unbound/unbound.conf` with include-able snippet dirs
- **libevent optional** — improves concurrency at scale (10000+ outgoing ports)
- **OpenSSL** for DoT/DoH + DNSSEC validation
- **Resource**: 30-100 MB RAM typical; scales linearly with cache size + active queries
- **Port 53** UDP + TCP (standard DNS); 853 for DoT; 443 for DoH (optional)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Linux / BSD        | **Distro package** (`unbound`)                                     | **Upstream-recommended** — every major distro ships it                             |
| Docker             | Community images (`mvance/unbound` popular)                                | Works; often bundled downstream                                                            |
| Router / firewall  | **OPNsense / pfSense / OpenWrt** bundled                                              | Default on these                                                                                        |
| Raspberry Pi       | Distro package — classic Pi-hole + Unbound combo                                                   | VERY common                                                                                             |
| Bare metal         | `./configure && make && make install`                                                                 | For custom builds                                                                                                    |
| Embedded           | `libunbound` — link into your app                                                                                    | For validator-in-library use                                                                                           |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Listen address       | `127.0.0.1` (local) / `192.168.1.1` (LAN) / `0.0.0.0`                 | Network      | **Never listen on public internet unrestricted — open resolver = abuse**         |
| Port                 | 53 (standard); 5335 (Pi-hole+Unbound pattern)                           | Network      | 5335 common for Unbound-behind-Pi-hole setups                                                    |
| Access-control       | `access-control: 192.168.0.0/16 allow`                                       | Security     | **Default denies everything — explicitly allow your subnets**                                                |
| DNSSEC trust anchor  | bundled; auto-rolled via `unbound-anchor`                                                 | Security     | Keep current; stale trust anchor = validation fails                                                             |
| Forward zone (opt)   | Forward `.lan` to internal resolver                                                                     | Split-horizon | For private zones                                                                                                   |
| DoT/DoH (opt)        | port 853 + cert for DoT                                                                                  | Encryption   | For outbound or inbound encrypted                                                                                                                |

## Install (Linux)

### Debian / Ubuntu

```sh
sudo apt install unbound
# Edit /etc/unbound/unbound.conf.d/my.conf (see below)
sudo systemctl enable --now unbound
```

Minimal production config `/etc/unbound/unbound.conf.d/recursive.conf`:
```
server:
    interface: 192.168.1.1
    port: 53
    access-control: 127.0.0.0/8 allow
    access-control: 192.168.0.0/16 allow
    access-control: 0.0.0.0/0 refuse                # explicit default deny
    hide-identity: yes
    hide-version: yes
    qname-minimisation: yes                         # privacy
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    prefetch: yes
    cache-min-ttl: 300
    cache-max-ttl: 86400
```

Check: `sudo unbound-checkconf`, then reload service, then `dig @192.168.1.1 example.com`.

## First boot

1. Install + minimal config
2. `unbound-checkconf` — syntax valid
3. `systemctl start unbound`
4. Test from client in allowed subnet: `dig @server example.com`
5. Verify DNSSEC: `dig +dnssec +multi dnssec-failed.org` — should return SERVFAIL (validating)
6. Verify recursion: first query takes ~100ms; second query from cache <5ms
7. Configure DHCP to hand out Unbound as DNS server
8. Monitor: `unbound-control stats` — query count, cache hit rate, errors
9. Long-term: enable `unbound-control` for runtime management + automatic trust-anchor updates

## Data & config layout

- `/etc/unbound/unbound.conf` — main config
- `/etc/unbound/unbound.conf.d/*.conf` — drop-in snippets
- `/etc/unbound/trust-anchor.key` (or `root.key`) — DNSSEC trust anchor
- `/var/lib/unbound/` — auto-updated trust anchor, sometimes cache persistence
- `/var/log/unbound/` — logs (if configured)

## Backup

Config is the only interesting state:
```sh
sudo tar czf unbound-config-$(date +%F).tgz /etc/unbound /var/lib/unbound/root.key
```

Cache is ephemeral; no need to back up.

## Upgrade

1. **Distro package updates** — standard `apt/dnf upgrade` cadence.
2. NLnet Labs releases: <https://github.com/NLnetLabs/unbound/releases>. Security updates shipped promptly.
3. `unbound-control reload` after config changes; full restart for binary upgrades.
4. **`unbound-anchor`** rotates DNSSEC trust anchor automatically when ICANN rolls the root KSK (rare, but important).
5. Package-manager-driven = low-risk upgrade path.

## Gotchas

- **OPEN RESOLVER = ABUSE VECTOR. DO NOT listen on public internet unrestricted.** An open recursive DNS resolver exposed to 0.0.0.0 with no ACLs is used for **DNS amplification DDoS attacks** (attacker spoofs source IP → tiny query → massive response hits victim). Legal + ISP consequences; your IP gets null-routed; criminal-adjacent liability. **Default `access-control` denies all** — override only for your trusted subnets.
- **DNSSEC trust anchor expiration**: the root KSK has been rolled before (2018). Stale trust anchor = all DNSSEC validation fails. `unbound-anchor` auto-handles rolls but check occasionally. On Debian the systemd unit runs this correctly; double-check on custom installs.
- **Pi-hole + Unbound combo on 127.0.0.1:5335** is the standard home-lab pattern: Pi-hole = blocker + cache (upstream facing clients); Unbound = recursive-validating resolver (upstream facing Pi-hole). Don't skip either; they solve different problems.
- **qname-minimisation** (RFC 7816) — send minimum necessary info to upstream authoritative servers. Privacy win. Enable.
- **Prefetching** re-queries popular domains before TTL expires → perceived faster-than-first-query cache hits. Modest CPU/bandwidth cost.
- **Forwarder vs recursive decision**: recursive (default) walks the tree yourself (privacy — no single upstream sees all queries); forwarder (to 1.1.1.1 / 8.8.8.8 / 9.9.9.9) = faster first-query but hands all metadata to upstream. Choose based on privacy values + bandwidth.
- **EDNS Client Subnet (ECS)**: disabled by default (privacy). Enabling can improve CDN geo-routing but leaks subnet to upstream. Most self-hosters: leave disabled.
- **DoT/DoH outbound** — have Unbound FORWARD to Cloudflare/Quad9 over DoT if you want encrypted upstream. Otherwise recursive = cleartext to authoritative servers.
- **DoT/DoH inbound** (serving clients over encrypted DNS) = requires valid TLS cert. Less common in home use but supported.
- **Log verbosity tradeoff**: full query logging = privacy concern for family members / roommates + massive disk use. Default `verbosity: 1` is the right production level. Debug higher only temporarily.
- **Cache size `msg-cache-size` + `rrset-cache-size`** — tune for memory available. 100MB each is plenty for home. For ISP-scale, tune upward.
- **Blocking via local-zones**: `local-zone: "ads.example.com" refuse` — inline blocking within Unbound. Useful for tiny lists. For large blocklists (100K domains) use Pi-hole or AdGuard Home (purpose-built).
- **Blocking vs forwarding conflict**: decide whether Pi-hole OR Unbound is the "primary" for clients. Usually Pi-hole primary → Unbound upstream.
- **`unbound-control`** requires initial setup: `unbound-control-setup` generates cert for admin tool. Then `unbound-control stats`, `unbound-control flush example.com`, etc.
- **License**: **BSD-3-Clause** — very permissive, safe everywhere.
- **Project health**: NLnet Labs is a Netherlands non-profit institution funded by NLnet Foundation grants + DNS-community sponsors. DECADES of DNS infrastructure software. Institutional-grade; not bus-factor-1 in any sense.
- **Ethical purchase / sponsorship**: NLnet Labs welcomes sponsorship for DNS infrastructure as public good.
- **Alternatives worth knowing:**
  - **BIND** — Internet Systems Consortium; the grandfather of DNS; feature-heavy; authoritative + recursive
  - **PowerDNS Recursor** — feature-rich; active commercial entity (Open-Xchange)
  - **Knot Resolver** — CZ.NIC; modern; excellent
  - **dnsmasq** — lightweight; caching + DHCP; simpler; NOT validating
  - **CoreDNS** — K8s-default; pluggable; Go
  - **Blocky** — Go DNS proxy with blocking (upstream → Unbound typical)
  - **Choose Unbound if:** you want a validating recursive resolver with an audit-quality pedigree.
  - **Choose dnsmasq if:** you need DHCP + minimal DNS; validation not needed.
  - **Choose CoreDNS if:** Kubernetes-native use.
  - **Choose BIND if:** you need authoritative + recursive in one tool + legacy compatibility.

## Links

- Repo: <https://github.com/NLnetLabs/unbound>
- Homepage: <https://nlnetlabs.nl/projects/unbound/about/>
- Documentation: <https://unbound.docs.nlnetlabs.nl/>
- `unbound.conf(5)`: <https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html>
- Example config: <https://github.com/NLnetLabs/unbound/blob/master/doc/example.conf.in>
- Releases: <https://github.com/NLnetLabs/unbound/releases>
- Mailing list: <https://lists.nlnetlabs.nl/mailman/listinfo/unbound-users>
- OSS-Fuzz status: <https://bugs.chromium.org/p/oss-fuzz/issues/list?sort=-opened&can=1&q=proj:unbound>
- NLnet Labs: <https://nlnetlabs.nl>
- Pi-hole + Unbound guide: <https://docs.pi-hole.net/guides/dns/unbound/>
- Knot Resolver (alt): <https://www.knot-resolver.cz>
- PowerDNS Recursor (alt): <https://www.powerdns.com/recursor>
- BIND (alt): <https://www.isc.org/bind/>
- CoreDNS (alt): <https://coredns.io>
