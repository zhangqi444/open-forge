---
name: Defguard
description: "Enterprise-grade OSS VPN + comprehensive access control. 'Only solution with MFA for WireGuard connections.' Built-in or external SSO (OpenID Connect), LDAP/AD two-way sync, YubiKey provisioning, ACL/firewall management, remote enrollment. Rust. Public pentest reports + daily SBOM CVE scans."
---

# Defguard

Defguard is **"WireGuard VPN — but enterprise + MFA-on-VPN + comprehensive-access-control + Rust + security-transparent"** — an enterprise-grade open-source VPN solution. **Unique value**: **MFA for WireGuard** connections (not just for "access-to-application"). Built-in SSO (TOTP + biometrics + passkeys) OR external SSO (Google/Microsoft/Active Directory/LDAP/Okta/JumpCloud/any OIDC). **Two-way LDAP/AD sync**. **YubiKey hardware-key management + provisioning**. **ACL/firewall management** (Linux + FreeBSD/OPNSense). **Remote user enrollment + onboarding**.

Built + maintained by **DefGuard** (Polish team; commercial + enterprise-tier + OSS-core). License: check LICENSE (OSS-core + enterprise features). Active; **public penetration-test reports**, **daily SBOM CVE scans**, **Architecture Decision Records** published on GitBook; roadmap public on GitHub Projects. Rust-built for speed + security.

Use cases: (a) **enterprise VPN with MFA-protection** — MFA required PER WIREGUARD CONNECTION (not just for apps behind VPN) (b) **replace Cisco AnyConnect / Palo Alto / Pulse Secure** — OSS alternative with SSO integration (c) **YubiKey-managed VPN access** — hardware-key mandatory for sensitive envs (d) **Zero-trust network access (ZTNA) entry-point** — one tool for VPN + identity + ACL (e) **compliance-grade VPN** — SOC2 / ISO 27001 requires MFA + audit (f) **LDAP/AD-integrated onboarding** — user in AD → automatic VPN account (g) **remote-employee onboarding** — self-service enrollment with administrator validation (h) **multi-location VPN** — multi-gateway deployments.

Features (per README):

- **WireGuard® VPN with 2FA/MFA** (unique — not just app-layer MFA)
- **Built-in SSO** (OpenID Connect-compliant) OR **external SSO** (Google/Microsoft/LDAP/Okta/JumpCloud)
- **Two-way Active Directory / LDAP sync**
- **YubiKey hardware-key management + provisioning**
- **ACL / firewall management** (Linux + FreeBSD/OPNSense)
- **Remote user enrollment + onboarding**
- **Automatic real-time desktop-client configuration sync**
- **Multi-location / multi-gateway / Kubernetes** deployments
- **Rust** for speed + security
- **Public pentest reports + daily SBOM CVE scans + public ADRs + public roadmap**

- Upstream repo: <https://github.com/DefGuard/defguard>
- Website: <https://defguard.net>
- Docs: <https://docs.defguard.net>
- Security page: <https://defguard.net/security>
- Pentest reports: <https://defguard.net/pentesting>
- SBOM CVE scans: <https://defguard.net/sbom>

## Architecture in one minute

- **Rust** backend + frontend
- **WireGuard kernel module** — data plane
- **PostgreSQL** DB
- **Multiple gateway nodes** — VPN endpoints
- **Central control plane** — identity, ACL, client config
- **Resource**: moderate — depends on user count + gateway count
- **Enterprise deployments** — Kubernetes + HA

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary for single-node**                                                                        |
| **Kubernetes**     | **Multi-gateway / HA**                                          | Enterprise                                                                                   |
| Source             | Rust build                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `vpn.example.com`                                           | URL          | TLS MANDATORY                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong + MFA                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| WireGuard public IP  | Gateway endpoints                                           | Network      |                                                                                    |
| **Gateway keypairs** | Per-gateway private keys                                    | **CRITICAL** | **EACH GATEWAY = CREDENTIAL**                                                                                    |
| SSO provider         | Internal OR external (OIDC endpoint)                        | Auth         |                                                                                    |
| LDAP/AD creds (opt)  | Bind-DN + password                                          | Integration  |                                                                                    |
| YubiKey PGP keys (opt) | For provisioning                                          | Hardware     |                                                                                    |
| ACL rules            | Per-location                                                                                                           | Config       |                                                                                    |
| Email (SMTP)         | Enrollment-invites                                                                                                     | Notifications |                                                                                    |

## Install via Docker

Follow: <https://docs.defguard.net>

```yaml
# MINIMAL SCAFFOLD — follow upstream docs for production
services:
  defguard:
    image: ghcr.io/defguard/defguard:latest        # **pin version**
    environment:
      DEFGUARD_DB_URL: postgresql://defguard:${DB_PASSWORD}@db:5432/defguard
      DEFGUARD_SECRET_KEY: ${SECRET_KEY}
    volumes: [defguard-config:/etc/defguard]
    ports: ["8080:8080"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: defguard
      POSTGRES_USER: defguard
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

  gateway:
    image: ghcr.io/defguard/gateway:latest
    # Follow upstream gateway config — WireGuard needs kernel module / cap_net_admin

volumes:
  defguard-config: {}
  pgdata: {}
```

## First boot

1. Read docs thoroughly
2. Plan: SSO-provider? LDAP? YubiKeys?
3. Configure identity backend
4. Create first admin + enable MFA
5. Provision first gateway (separate node ideally)
6. Create first location (network + ACL policy)
7. Enroll first user — test client configuration push
8. Verify MFA-on-VPN-connection flow
9. Set up pentest-style review before production

## Data & config layout

- PostgreSQL — users, locations, gateways, ACLs, audit
- `/etc/defguard/` — secrets + config
- Gateway nodes — WireGuard state

## Backup

```sh
docker compose exec db pg_dump -U defguard defguard > defguard-$(date +%F).sql
sudo tar czf defguard-config-$(date +%F).tgz defguard-config/
# ENCRYPT — contains user-MFA-state + gateway-keys
```

## Upgrade

1. Releases: <https://github.com/DefGuard/defguard/releases>. Active.
2. **Read release notes + ADRs** — enterprise deployments need staged rollout
3. Gateway + control-plane versions matter
4. **Daily SBOM CVE scan** = stay current on security patches
5. **Public pentest reports** = transparency on security posture

## Gotchas

- **94th HUB-OF-CREDENTIALS — CROWN-JEWEL TIER 1 SUB-CATEGORY FORMALIZED**:
  - **"enterprise-VPN-IdP" sub-category** — Defguard 1st formally
  - Holds: user accounts + SSO-trust + LDAP-bind + YubiKey-provisioning + ALL WireGuard private-keys + ACLs + firewall-rules + MFA secrets
  - Compromise of Defguard → ATTACKER HAS ENTIRE VPN INFRASTRUCTURE + all users' MFA
  - **NEW CROWN-JEWEL Tier 1 sub-category: "enterprise-VPN-with-IdP"** (Defguard 1st)
  - Distinct from GLAuth (105) "IdP-auth-service" because Defguard is VPN + IdP combined
  - **CROWN-JEWEL Tier 1: 25 tools / 22 sub-categories**
- **VPN-IDP-COMBINATION RISK**:
  - Combining VPN with identity management = single point of compromise
  - vs. separate IdP (Keycloak) + separate VPN (WireGuard-Easy)
  - Defguard's architecture is intentional (simpler UX) but carries concentrated-risk
  - **Recipe convention: "VPN+IdP-combined-concentrated-risk" callout**
  - **NEW recipe convention** (Defguard 1st formally)
- **MFA-FOR-WIREGUARD = UNIQUE FEATURE**:
  - Standard WireGuard: connection = key-possession → no MFA
  - Defguard layers MFA ON TOP of WireGuard connection
  - Addresses stolen-device scenario (stolen key + password ≠ stolen MFA)
  - **Recipe convention: "MFA-on-VPN-connection positive-signal"** — rare
  - **NEW positive-signal convention** (Defguard 1st)
- **TRANSPARENT-SECURITY PRACTICES** (exceptional):
  - **Public pentest reports** — rare; most OSS projects don't
  - **Daily SBOM CVE scans** — continuous supply-chain monitoring
  - **Public Architecture Decision Records (ADRs)** — design-rationale documented
  - **Public roadmap** — prioritization transparent
  - **Recipe convention: "public-pentest-reports positive-signal"** (1st formally — Defguard)
  - **Recipe convention: "public-SBOM-CVE-scan positive-signal"** (1st — Defguard)
  - **Recipe convention: "public-ADRs positive-signal"** (1st formally — Defguard)
  - **Recipe convention: "public-project-roadmap positive-signal"** (1st formally — Defguard)
  - **3 NEW positive-signal conventions** — all Defguard 1sts
- **RUST FOR SECURITY**:
  - Memory-safe language = reduces memory-corruption CVEs
  - **Recipe convention: "Rust-for-security positive-signal"** (reinforces Quickwit, Meilisearch, Rauthy, ...)
- **TWO-WAY LDAP/AD SYNC**:
  - Writes back to AD (most tools only read)
  - Requires elevated AD permissions (write access)
  - **Recipe convention: "LDAP-write-back-elevated-permissions" callout**
- **GATEWAY KEY-PAIRS = PER-NODE CREDENTIALS**:
  - Each gateway node has WireGuard private-key
  - Compromise of gateway node = compromise of all connections through it
  - **Recipe convention: "per-gateway-key-material-risk" callout**
- **ACL MANAGEMENT FOR LINUX + FREEBSD/OPNSENSE**:
  - Multi-OS firewall management
  - Network-level enforcement (not just app-level)
  - **Recipe convention: "multi-OS-firewall-management positive-signal"**
- **REMOTE USER ENROLLMENT**:
  - Self-service onboarding via admin-validated process
  - **Recipe convention: "secure-self-service-enrollment positive-signal"**
- **YUBIKEY PROVISIONING**:
  - Defguard can provision YubiKeys
  - Yubico PGP-key generation
  - **Recipe convention: "hardware-key-provisioning positive-signal"** — rare
- **ENTERPRISE-TIER VS OSS-CORE**:
  - Some features marked "enterprise only" in docs
  - OSS covers core; enterprise covers scale + advanced features
  - **Commercial-tier-taxonomy: open-core-with-enterprise-features** — reinforces Dittofeed pattern
- **INSTITUTIONAL-STEWARDSHIP**: DefGuard org (Polish team) + commercial-tier + community + public-security-practices. **80th tool — commercial-org-with-transparent-security-practices sub-tier** (**NEW sub-tier** — exceptional openness).
  - **NEW sub-tier: "commercial-org-with-public-security-practices"** (1st — DefGuard)
- **TRANSPARENT-MAINTENANCE**: active + Rust + docs + public-pentests + public-SBOM + public-ADRs + public-roadmap + CI + enterprise-focus + security-first. **88th tool in transparent-maintenance family.**
- **ENTERPRISE-VPN-CATEGORY:**
  - **Defguard** — MFA-on-WireGuard + IdP + LDAP + YubiKey
  - **Netbird** — WireGuard + zero-trust
  - **Tailscale** (commercial; also OSS control-plane Headscale)
  - **Headscale** — OSS Tailscale-compatible control plane
  - **WireGuard-Easy** — simple WireGuard UI (single-node)
  - **pfSense / OPNsense** — firewall + VPN
  - **OpenVPN AS** — commercial OpenVPN
- **ALTERNATIVES WORTH KNOWING:**
  - **Headscale** — if you want Tailscale-compatible + mesh
  - **Netbird** — if you want commercial-backed zero-trust
  - **WireGuard-Easy** — if you want minimal single-admin WireGuard
  - **Choose Defguard if:** enterprise + MFA-on-VPN + LDAP/AD + YubiKey + security-transparent.
- **PROJECT HEALTH**: active + Rust + enterprise-focus + public-security-practices + CI + docs. **EXCEPTIONAL** for transparency.

## Links

- Repo: <https://github.com/DefGuard/defguard>
- Website: <https://defguard.net>
- Docs: <https://docs.defguard.net>
- Security: <https://defguard.net/security>
- Pentests: <https://defguard.net/pentesting>
- SBOM scans: <https://defguard.net/sbom>
- Headscale (alt): <https://github.com/juanfont/headscale>
- Netbird (alt): <https://github.com/netbirdio/netbird>
- WireGuard-Easy: <https://github.com/wg-easy/wg-easy>
