---
name: koha
description: Koha recipe for open-forge. Enterprise-class Integrated Library System (ILS) with modules for acquisitions, circulation, cataloging, OPAC, label printing, offline circulation, and much more. Perl/MySQL web app. Source: https://github.com/Koha-Community/Koha
---

# Koha

Enterprise-class free software Integrated Library System (ILS) used by libraries worldwide. Covers the full library workflow: acquisitions, receiving, cataloging (MARC21/UNIMARC), OPAC (public catalog), circulation (checkout/checkin/holds), patron management, label printing, serials management, course reserves, offline circulation, and reporting. Built on Perl with a MySQL/MariaDB backend and Apache/nginx. GPLv3. Upstream: https://github.com/Koha-Community/Koha. Community: https://koha-community.org. Packages available for Debian/Ubuntu via the official Koha repository.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Debian/Ubuntu package (koha-common) | Debian / Ubuntu | Recommended; maintained by Koha community |
| Docker (koha-docker) | Linux | Community Docker image; see community resources |
| From source (git) | Linux | For developers/contributors |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| system | "Library/site name?" | Shown in OPAC and staff client |
| domain | "OPAC domain?" | e.g. catalog.library.example.com |
| domain | "Staff client domain?" | e.g. staff.library.example.com |
| db | "MySQL root password?" | Used to create the koha database user |
| email | "Library email address?" | For outgoing notices and holds |
| admin | "Koha admin username/password?" | Set during web installer |

## Software-layer concerns

### Prerequisites

  # Debian 12 / Ubuntu 22.04+ recommended
  # Apache2 with mod_rewrite, mod_cgi, mod_headers, mod_deflate
  # MySQL 8+ or MariaDB 10.5+
  # Perl 5.32+
  # 4 GB RAM minimum; 8+ GB recommended for production

### Method 1: Debian/Ubuntu package install (recommended)

  # Add the Koha community repository:
  sudo apt install gnupg2
  wget -O- https://debian.koha-community.org/koha/gpg.asc | sudo apt-key add -
  echo "deb https://debian.koha-community.org/koha stable main" | sudo tee /etc/apt/sources.list.d/koha.list

  sudo apt update
  sudo apt install koha-common

  # Enable required Apache modules:
  sudo a2enmod rewrite cgi headers deflate
  sudo systemctl restart apache2

### Create a Koha instance

  sudo koha-create --create-db library
  # "library" is your instance name (can be anything)
  # This creates:
  # - A MySQL database (koha_library)
  # - A dedicated system user
  # - Apache virtual host config files

### Enable and configure Apache vhosts

  sudo a2ensite library
  sudo systemctl reload apache2

  # Edit /etc/apache2/sites-available/library.conf to set ServerName:
  # OPAC: http://catalog.library.example.com → port 80
  # Staff: http://staff.library.example.com → port 8080 (or via reverse proxy)

### Access the web installer

  # Navigate to: http://staff.library.example.com/cgi-bin/koha/installer/install.pl
  # Or: http://localhost:8080/cgi-bin/koha/installer/install.pl
  # Complete the web installer to:
  # - Set admin credentials
  # - Load MARC frameworks
  # - Configure library settings

### Key config files

  /etc/koha/sites/library/koha-conf.xml   # Instance config (DB, paths, Z39.50)
  /etc/apache2/sites-available/library.conf  # Apache vhost

### Ports

  80/tcp     # OPAC (public catalog)
  8080/tcp   # Staff client (default; change in koha-conf.xml)

### Reverse proxy (nginx) for OPAC

  server {
      listen 443 ssl;
      server_name catalog.library.example.com;
      location / {
          proxy_pass http://127.0.0.1:80;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
      }
  }

### Cron jobs

  # Koha requires several cron jobs for holds, overdues, notices, etc.
  # The Debian package installs these automatically under /etc/cron.d/koha-common.
  # Review /usr/share/koha/bin/cronjobs/ for the full list.

### Useful admin commands (Debian package)

  sudo koha-list                  # List all instances
  sudo koha-shell library         # Drop into a shell as the koha user
  sudo koha-passwd library        # Reset Koha DB password
  sudo koha-start-zebra library   # Start Zebra search daemon
  sudo koha-rebuild-zebra library # Rebuild search index

## Upgrade procedure

  sudo apt update && sudo apt upgrade koha-common
  # Package upgrades run database migrations automatically.
  # After major version upgrades: check /cgi-bin/koha/installer/install.pl for migration steps.

## Gotchas

- **Zebra indexing**: Koha uses the Zebra search server for catalog searches. It must be running (`koha-start-zebra library`) and the index must be rebuilt periodically via cron (`koha-rebuild-zebra`). Without this, searches return no results.
- **Two interfaces, two ports**: The staff client (8080) and OPAC (80) are separate Apache virtual hosts. Both need to be exposed appropriately — often via a reverse proxy.
- **Not accepting GitHub PRs**: Koha patches are submitted via Bugzilla at https://bugs.koha-community.org, not GitHub pull requests. The GitHub repo is a mirror.
- **Heavy dependencies**: Koha has hundreds of Perl module dependencies. The Debian package handles this automatically; installing from source on a non-Debian system is complex.
- **Offline circulation**: Koha supports offline circulation (for when the server is unreachable) via a browser plugin or desktop client. Useful for bookmobiles.
- **MARC frameworks**: On first install, import a MARC21 (or UNIMARC) framework from the web installer. This defines how bibliographic records are structured.
- **RAM**: Koha with Zebra, MySQL, and Apache can consume 2–4 GB RAM under load. 8 GB recommended for production.

## References

- Upstream GitHub: https://github.com/Koha-Community/Koha
- Community website: https://koha-community.org
- Installation wiki: https://wiki.koha-community.org/wiki/Koha_on_Debian
- Bug tracker: https://bugs.koha-community.org
- Debian repository: https://debian.koha-community.org
