---
name: uusec-waf
description: UUSEC WAF recipe for open-forge. High-performance AI-powered Web Application Firewall based on nginx. Based on upstream docs at https://waf.uusec.com and https://github.com/Safe3/uusec-waf
---

# UUSEC WAF

Industrial-grade, high-performance Web Application Firewall (WAF) and API security gateway. A fork of nginx with added AI/semantic detection engines for SQL injection, XSS, RCE, LFI, and zero-day defense. Also includes HIPS (host intrusion prevention) and RASP (runtime application self-defense). Upstream: <https://github.com/Safe3/uusec-waf>. Docs: <https://waf.uusec.com>

Operates as a cloud WAF reverse proxy — sits in front of your web servers on ports 80 and 443. Current release: v7.2.0 (March 2026).

> ⚠️ **Proxy mode only:** UUSEC WAF is a reverse proxy, not an inline agent or library. It requires dedicated use of ports 80 and 443. Install on a separate server or ensure those ports are free before installing.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| One-click installer script | <https://waf.uusec.com/> | ✅ | Recommended — installs Docker + WAF stack automatically |
| Manual Docker Compose | <https://github.com/Safe3/uusec-waf> | ✅ | When Docker is already installed |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Server IP or hostname for WAF management?" | Free-text | All |
| preflight | "Confirm ports 80 and 443 are free on this server?" | `AskUserQuestion`: Yes / No | Required |
| sites | "Domain(s) to protect?" | Free-text | Configure after install via admin UI |
| sites | "Backend server IP and port for each domain?" | Free-text | Configure after install |
| tls | "Do you have SSL certificates, or use Let's Encrypt?" | `AskUserQuestion`: Let's Encrypt / Upload certificates | Configure in admin after install |

## Software-layer concerns

**Architecture:**
- UUSEC WAF runs as a Docker container
- Acts as reverse proxy: traffic → WAF (80/443) → backend servers
- Admin interface at `https://<server-ip>:4443`

**Config paths:**
- All configuration via web admin UI — no manual config files needed for standard use
- WAF container managed via `/opt/waf/manager.sh`

**Data dirs:**
- `/opt/waf/` — WAF installation directory

**Requirements:**
- Linux x86_64 (recommended — pure Linux environment)
- Docker CE 20.10.14+ and Docker Compose 2.0.0+
- Ports 80, 443, and 4443 must be available

## Method — One-click installer

> **Source:** <https://waf.uusec.com/#installation>

The installer script automatically installs Docker (if not present) and the WAF container stack.

```bash
# Run as root or with sudo
sudo bash -c "$(curl -fsSL https://waf.uusec.com/installer.sh)"
```

Installation typically completes in a few minutes (depending on download speed).

After install, manage the WAF container:

```bash
bash /opt/waf/manager.sh
```

This script provides options to: start, stop, update, uninstall the WAF.

## First-time setup

1. **Login to admin:** `https://<server-ip>:4443`
   - Default username: `admin`
   - Default password: `#Passw0rd`
   - **Change the password immediately after first login.**

2. **Add a site:**
   - Go to the **Sites** menu → **Add Site**
   - Enter the domain name and backend server IP/port
   - The WAF will proxy requests for this domain to your backend

3. **Configure SSL:**
   - Go to **Certificate Management** → **Add Certificate**
   - Upload your certificate and private key, OR
   - Apply for a free Let's Encrypt certificate (auto-renews)

4. **Update DNS:**
   - Change the DNS A record for your domain to point to the WAF server's IP
   - Traffic now flows through the WAF

## Upgrade procedure

```bash
bash /opt/waf/manager.sh
# Select the "update" option
```

Or manually:

```bash
docker pull safe3/uusec-waf:latest
# Restart via manager.sh
```

## Gotchas

- **Ports 80 and 443 must be free:** UUSEC WAF is a reverse proxy that must own these ports. If any other web server (nginx, Apache, Caddy) is running on the same host, they will conflict. Migrate existing servers to backend-only ports (e.g. 8080) before installing.
- **x86_64 required (recommended):** The AI/semantic detection engines are compiled for x86_64. ARM or other architectures may not work correctly.
- **Rules take effect immediately:** Unlike traditional WAF rule engines, UUSEC WAF applies rule changes without restarting. Useful for rapid response but also means misconfigurations go live immediately.
- **RASP requires Java/PHP agents:** The runtime application self-defense (RASP) feature requires agents installed in your backend application runtime (Java JVM, PHP Zend). This is advanced configuration — basic WAF protection works without RASP.
- **Admin port 4443:** The management interface uses a non-standard port. Ensure port 4443 is allowed in your firewall for admin access, but restrict it to trusted IPs only.
- **Let's Encrypt certificate domain:** The domain in your SSL certificate must match the `VIRTUAL_HOST` / domain configured in the site settings, or TLS handshakes will fail.
- **Chinese-language docs:** Most documentation at <https://waf.uusec.com> is in Chinese. A Chinese README is also available at `/README_CN.md` in the repo.

## Links

- Upstream source: <https://github.com/Safe3/uusec-waf>
- Documentation: <https://waf.uusec.com>
- GitHub Discussions: <https://github.com/Safe3/uusec-waf/discussions>
