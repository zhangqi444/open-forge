---
name: itflow
description: ITFlow recipe for open-forge. Free open-source IT documentation, ticketing, invoicing, and accounting platform for small MSPs (Managed Service Providers). PHP/MariaDB stack deployed via install script on Ubuntu/Debian. Source: https://github.com/itflow-org/itflow
---

# ITFlow

Free and open source IT documentation, ticketing, and accounting system designed for small managed service providers (MSPs). Consolidates client documentation (assets, contacts, domains, files, passwords), ticketing, billing (quotes, invoices, accounting, expenses), and a client portal into one unified platform. PHP application with MariaDB backend. A free alternative to ITGlue and Hudu. Upstream: https://github.com/itflow-org/itflow. Docs: https://docs.itflow.org/. Demo: https://demo.itflow.org (demo@demo.com / demo).

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Install script | Ubuntu 22.04 / Debian 12 | Recommended. Installs LAMP stack + ITFlow. |
| Manual install | Ubuntu / Debian | PHP + MariaDB + Apache/nginx setup manually |
| Docker | Linux | Community-maintained Docker images available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Target OS?" | Ubuntu 22.04 LTS or Debian 12 recommended |
| install | "Domain name?" | e.g. itflow.example.com — used for web server config and URL |
| install | "Admin email + password?" | For initial ITFlow admin account |
| tls | "TLS certificate?" | Let's Encrypt via Certbot (prompted by script) |

## Software-layer concerns

### Install via script (recommended)

  # Run as root on a fresh Ubuntu/Debian server:
  wget -O itflow_install.sh https://github.com/itflow-org/itflow-install-script/raw/main/itflow_install.sh
  bash itflow_install.sh

  # The script installs and configures:
  # - Apache2 + PHP (8.x)
  # - MariaDB
  # - ITFlow application files in /var/www/itflow/
  # - Let's Encrypt TLS (optional, prompted)
  # - Cron jobs for scheduled tasks

  # Video walkthrough: https://www.youtube.com/watch?v=kKz9NOU_1XE

### First-time setup

  # After install, navigate to: https://your-domain/
  # Complete the web-based setup wizard:
  # 1. Company name, email, and admin password
  # 2. Currency, timezone
  # 3. Email settings (SMTP for outbound mail)

### Manual install overview

  # Full manual install guide:
  # https://docs.itflow.org/installation

  # Requirements:
  # - PHP 8.1+ with extensions: mysqli, gd, curl, mbstring, zip, imap, xml
  # - MariaDB 10.6+ (MySQL also works)
  # - Apache2 or nginx
  # - Composer (for dependencies)

  # Clone the repo:
  git clone https://github.com/itflow-org/itflow.git /var/www/itflow

  # Set permissions:
  chown -R www-data:www-data /var/www/itflow
  chmod -R 755 /var/www/itflow

  # Create database:
  mysql -u root -e "CREATE DATABASE itflow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql -u root -e "CREATE USER 'itflow'@'localhost' IDENTIFIED BY 'password';"
  mysql -u root -e "GRANT ALL ON itflow.* TO 'itflow'@'localhost';"

### Key directories

  /var/www/itflow/           # Application root
  /var/www/itflow/uploads/   # File attachments (client files, documents)
  /var/www/itflow/config.php # Database connection config (auto-created by setup wizard)

### Cron jobs (required for scheduled tasks)

  # Add to root's crontab:
  * * * * * www-data php /var/www/itflow/cron/cron.php >> /var/log/itflow-cron.log 2>&1

  # Handles: invoice reminders, domain/SSL expiry alerts, scheduled reports

### Email (SMTP)

  # Configure outbound email in Settings → Email Settings after first login.
  # Supports SMTP with TLS/SSL. Required for: ticket notifications, invoices, alerts.

### Apache virtual host example

  <VirtualHost *:443>
      ServerName itflow.example.com
      DocumentRoot /var/www/itflow

      <Directory /var/www/itflow>
          Options -Indexes
          AllowOverride All
          Require all granted
      </Directory>

      SSLEngine on
      SSLCertificateFile /etc/letsencrypt/live/itflow.example.com/fullchain.pem
      SSLCertificateKeyFile /etc/letsencrypt/live/itflow.example.com/privkey.pem
  </VirtualHost>

### Security notes

  # .htaccess restricts access to sensitive directories.
  # Ensure mod_rewrite is enabled: a2enmod rewrite
  # Restrict /uploads/ and /config.php from direct web access.
  # Enable 2FA for admin accounts (Settings → Security).

## Upgrade procedure

  # Via git pull:
  cd /var/www/itflow
  git pull origin master
  # Navigate to Admin → Settings → Database → Run Migrations (if prompted)

  # Or use the built-in update mechanism: Admin → Settings → Update

## Gotchas

- **PHP IMAP extension required**: ITFlow can import emails into tickets via IMAP. The `php-imap` extension must be installed even if you don't use this feature, as it may cause errors if missing.
- **Uploads directory must be writable**: `/var/www/itflow/uploads/` must be writable by the web server user (`www-data`). Client file attachments are stored here.
- **Cron is mandatory**: many ITFlow features (reminders, alerts, recurring invoices) depend on the cron job. Ensure it's running.
- **Not multi-tenant by default**: ITFlow is designed as a single MSP's internal tool, not a multi-tenant SaaS platform. One instance serves one MSP with multiple clients.
- **Password storage in client docs**: ITFlow stores client passwords in its database. Use strong database credentials, encrypt the server, and restrict access with TLS + firewall.
- **Actively developed**: ITFlow receives frequent updates. Subscribe to release notifications and update regularly for security fixes.

## References

- Upstream GitHub: https://github.com/itflow-org/itflow
- Install script: https://github.com/itflow-org/itflow-install-script
- Documentation: https://docs.itflow.org/
- Forum / community: https://forum.itflow.org/
- Demo: https://demo.itflow.org (demo@demo.com / demo)
- Installation video: https://www.youtube.com/watch?v=kKz9NOU_1XE
