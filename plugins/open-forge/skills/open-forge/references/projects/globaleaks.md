---
name: globaleaks
description: GlobaLeaks recipe for open-forge. Free open-source whistleblowing platform enabling secure anonymous reporting, used by journalists and anti-corruption organizations worldwide. Source: https://github.com/globaleaks/globaleaks-whistleblowing-software
---

# GlobaLeaks

Free and open-source whistleblowing software enabling anyone to set up and maintain a secure anonymous reporting platform. Used by journalists, anti-corruption organizations, and government bodies worldwide. Recognized as a Digital Public Good. Features Tor hidden service support, end-to-end encrypted submissions, file attachments, questionnaire builder, and multilingual UI. Upstream: https://github.com/globaleaks/globaleaks-whistleblowing-software. Docs: https://docs.globaleaks.org.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| .deb package (install script) | Debian / Ubuntu LTS | Recommended. Official APT repository. |
| Docker | Docker | Official Docker support; see docs for compose setup. |
| Manual | Python 3 | Source install; not recommended for production. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Public URL or Tor-only?" | Clearnet URL (HTTPS) or .onion-only for maximum anonymity |
| setup | "Admin email?" | First admin account; used for alert notifications |
| tls | "HTTPS certificate?" | Let's Encrypt auto-provisioned if domain is set; or provide your own |
| privacy | "Enable Tor hidden service?" | Strongly recommended for high-risk whistleblowing deployments |

## Software-layer concerns

### .deb install (recommended)

  # Requires Debian 12 or Ubuntu 22.04/24.04
  # As root:
  curl https://deb.globaleaks.org/install-globaleaks.sh | bash

  # This adds the GlobaLeaks APT repository and installs the package.
  # The service starts automatically.

  # Access the admin setup wizard:
  # http://<server-ip>:8082  (clearnet, HTTP — configure HTTPS via admin)

### Post-install wizard

1. Open http://<server>:8082 in browser
2. Run through the setup wizard: set site name, language, admin password
3. Configure HTTPS: Admin > Network > HTTPS (Let's Encrypt or custom cert)
4. Configure Tor (recommended): Admin > Network > Tor
5. Design questionnaires and configure submission channels

### Docker

  # See: https://docs.globaleaks.org/en/stable/setup/DockerInstall.html
  docker run -d \
    --name globaleaks \
    -p 8082:8082 \
    -v globaleaks-data:/var/globaleaks \
    globaleaks/globaleaks

### Tor hidden service setup

GlobaLeaks can generate and manage a Tor v3 .onion address automatically.
Enable it in: Admin > Network > Tor. The onion address appears in the UI once Tor connects.
This provides anonymity for both submitters and the server's real IP.

### Key directories

  /var/globaleaks/         - all data (SQLite DB, uploads, TLS certs, Tor keys)
  /etc/globaleaks/         - configuration
  /var/log/globaleaks/     - logs

### Firewall

  # Minimum ports:
  80/tcp   - HTTP (redirect to HTTPS)
  443/tcp  - HTTPS (after TLS configured)
  8082/tcp - admin/setup (can be restricted after setup)
  # Tor: outbound TCP 9001, 9030 to Tor network

## Upgrade procedure

  # .deb install:
  apt-get update && apt-get upgrade globaleaks

  # Docker:
  docker pull globaleaks/globaleaks
  docker stop globaleaks && docker rm globaleaks
  # Re-run docker run with same volume

## Gotchas

- **Security-first design**: GlobaLeaks is hardened for high-risk deployments. Do not install other services on the same server. Follow the Hardening Guide in docs.
- **Tor strongly recommended**: for genuine whistleblowing, clearnet-only is insufficient. Enable the Tor hidden service.
- **Reverse proxy conflicts**: GlobaLeaks manages its own nginx internally. Do not put a conflicting nginx/Caddy in front without following the docs' reverse proxy guide.
- **Email notifications contain metadata**: configure carefully — notification emails to admins/recipients may leak metadata. Use PGP encryption for notifications or Tor-only delivery.
- **File security**: uploaded files are stored encrypted. Back up /var/globaleaks/ securely; it contains both the database and encryption keys.
- **Admin access should be Tor-only** for high-risk deployments: configure the admin interface to only be accessible via .onion.
- **Debian/Ubuntu only**: the .deb package only supports Debian/Ubuntu. Other distros require manual or Docker install.

## References

- Upstream GitHub: https://github.com/globaleaks/globaleaks-whistleblowing-software
- Documentation: https://docs.globaleaks.org
- Installation guide: https://docs.globaleaks.org/en/stable/setup/InstallationGuide.html
- Hardening guide: https://docs.globaleaks.org/en/stable/security/HardeningGuide.html
- Demo: https://demo.globaleaks.org
