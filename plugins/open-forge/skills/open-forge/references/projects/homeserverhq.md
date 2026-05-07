# HomeServerHQ

**All-in-one home server infrastructure installer** — shell-based setup utility that installs a fully configured email server, VPN, public websites, and an integrated FOSS software suite in under an hour. Works even behind CGNAT via a relay server. Designed for non-technical users.

**Official site:** https://www.homeserverhq.com
**Source:** https://github.com/homeserverhq/hshq
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Home server (bare metal) | Debian 12 / Ubuntu 22.04 / 24.04 / Mint 22 | Primary path; custom ISOs available |
| VPS (RelayServer) | Any Linux | Small VPS needed as relay for CGNAT/public access |

---

## Inputs to Collect

### Phase 1 — Planning
- Home server hardware (x86_64; Raspberry Pi not listed as supported)
- Domain name (required; purchased separately)
- VPS for RelayServer (needed for CGNAT bypass and public websites)
- Linux distribution preference (Debian 12 or Ubuntu 24.04 recommended)

### Phase 2 — Deploy
- Domain name and DNS access (to set DNS/MX records)
- VPS SSH access for RelayServer setup
- Admin account credentials

---

## Software-Layer Concerns

- **Shell-based installer:** Single `hshq.sh` script drives the entire setup
- **Two machines required for public hosting:** HomeServer (your hardware) + RelayServer (small VPS) for CGNAT bypass
- **CGNAT support:** Novel networking approach routes public traffic through the RelayServer even when your home ISP uses CGNAT
- **Integrated software suite:** Email (full stack), VPN, reverse proxy, web hosting, and more — all pre-configured with secure defaults
- **Custom ISOs available:** Pre-built Debian 12 and Ubuntu 24.04 desktop/server ISOs with HSHQ pre-configured for easiest install

---

## Deployment

**Easiest path (Custom ISO):**
1. Download a custom ISO from https://wiki.homeserverhq.com/tutorials/install-linux
2. Flash to USB with Balena Etcher
3. Install Linux (5-10 minutes with guided installer)
4. Double-click 'Install HSHQ' on the desktop

**Manual install (headless/GitHub):**
```bash
# Run as first non-root user (UID=1000) on a fresh Linux install
cd ~
mkdir -p hshq/data/lib
wget -q4N https://raw.githubusercontent.com/homeserverhq/hshq/main/hshq.sh
wget -q4 -O hshq/data/lib/hshqlib.sh https://raw.githubusercontent.com/homeserverhq/hshq/main/hshqlib.sh
bash hshq.sh
```

**Post-install:**
1. Set up RelayServer VPN via HSHQ Web Utility → 06 My Network → 14 Set Up Hosted VPN
2. Configure DNS records with your domain registrar (A/MX records)
3. Install all services via HSHQ Web Utility → 02 Services → 02 Install All Available Services

Full getting started guide: https://wiki.homeserverhq.com/getting-started

---

## Upgrade Procedure

Updates are managed through the HSHQ Web Utility. Check for and apply updates from the admin interface.

---

## Gotchas

- **Domain name required** — HSHQ won't work without a real domain; purchase one before starting
- **Two-machine setup for public hosting** — a small VPS (~$3-5/month) is needed as a RelayServer for public email/websites; home-only use (no public sites) may work with just the home server
- **Run as UID=1000** — the installer must be run as the first non-root user, not root
- **Fresh Linux install recommended** — installing on an existing system with other software may conflict
- **Source code verification** — HSHQ provides a verification guide to confirm the script hasn't been tampered with; review before running

---

## Links

- Upstream README: https://github.com/homeserverhq/hshq#readme
- Getting started: https://wiki.homeserverhq.com/getting-started
- Source code verification: https://wiki.homeserverhq.com/tutorials/source-code-verification
- Wiki: https://wiki.homeserverhq.com
