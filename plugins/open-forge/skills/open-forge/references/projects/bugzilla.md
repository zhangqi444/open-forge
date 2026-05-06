---
name: bugzilla
description: Bugzilla recipe for open-forge. General-purpose bug tracker and testing tool originally developed by Mozilla, supporting workflows, custom fields, email notifications, REST API, and LDAP. Source: https://github.com/bugzilla/bugzilla
---

# Bugzilla

General-purpose bug tracker and testing tool originally developed and used by the Mozilla project. Supports customizable workflows, custom fields and statuses, email notifications, time tracking, charting, a REST API, LDAP/SAML authentication, and fine-grained access control. Upstream: https://github.com/bugzilla/bugzilla. Docs: https://bugzilla.readthedocs.io/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Traditional (Perl + Apache/nginx) | Linux | Standard install; Perl + mod_cgi or mod_perl. |
| Docker (community) | Docker | No official Docker image; several community images exist. |
| BMO (bugzilla.mozilla.org fork) | Docker | https://github.com/mozilla-bteam/bmo — Mozilla's production stack. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Database host/name/user/password?" | MySQL/MariaDB (recommended) or PostgreSQL |
| setup | "Bugzilla URL?" | e.g. https://bugs.example.com — set as urlbase in localconfig |
| setup | "Admin email and password?" | First user created during checksetup.pl |
| email | "SMTP server details?" | Bugzilla sends all notifications by email |
| auth | "LDAP / SAML?" | Optional enterprise SSO — configure in Admin > Authentication |

## Software-layer concerns

### Prerequisites

- Perl 5.14+
- MySQL 5.6+ or MariaDB 10.1+ (PostgreSQL also supported)
- Apache 2.x with mod_cgi or mod_perl

Install required Perl modules:

  # On Debian/Ubuntu
  apt-get install perl mysql-server libcgi-pm-perl libdbi-perl \
    libdbix-connector-perl libtemplate-perl libemail-sender-perl \
    libfile-slurp-perl libxml-twig-perl libmime-tools-perl

  # Or let checksetup.pl install them
  perl install-module.pl --all

### Install steps

  # 1. Download release tarball (preferred) or clone
  wget https://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla-X.Y.Z.tar.gz
  tar xzf bugzilla-X.Y.Z.tar.gz
  mv bugzilla-X.Y.Z /var/www/bugzilla

  # 2. Run setup script
  cd /var/www/bugzilla
  perl checksetup.pl

  # checksetup.pl creates localconfig — edit it:
  # $webservergroup = 'www-data';
  # $db_host = 'localhost';
  # $db_name = 'bugzilla';
  # $db_user = 'bugzilla';
  # $db_pass = 'password';
  # $urlbase = 'https://bugs.example.com/';

  # 3. Run checksetup.pl again to create DB schema and admin account
  perl checksetup.pl

  # 4. Configure Apache virtual host (see docs for example)
  # 5. Set file permissions
  chown -R www-data:www-data /var/www/bugzilla
  chmod -R 755 /var/www/bugzilla

### Apache virtual host (minimal)

  Alias /bugzilla /var/www/bugzilla
  <Directory /var/www/bugzilla>
      AddHandler cgi-script .cgi
      Options +Indexes +ExecCGI
      DirectoryIndex index.cgi
      AllowOverride All
  </Directory>

## Upgrade procedure

1. Back up database: `mysqldump bugzilla > bugzilla-backup.sql`
2. Back up `localconfig` and `data/` directory
3. Replace Bugzilla files with new version (keep `localconfig`)
4. Run `perl checksetup.pl` — applies DB migrations automatically
5. Restart Apache

## Gotchas

- **checksetup.pl is idempotent**: safe to re-run after config changes or upgrades; it detects and applies only what's needed.
- **localconfig is not in version control**: do not overwrite it during upgrades.
- **Email is critical**: Bugzilla relies heavily on email for notifications and user confirmation. Configure SMTP correctly before going live.
- **mod_perl vs mod_cgi**: mod_perl is significantly faster for large installs but requires more memory and careful configuration.
- **CGI timeout**: for large reports/exports, increase Apache's timeout.
- **PostgreSQL support**: works but MySQL/MariaDB is better-tested and recommended.
- **Active development slowed**: Bugzilla is mature and stable; major new features are infrequent. Mozilla's active fork is BMO (https://github.com/mozilla-bteam/bmo).

## References

- Upstream README / GitHub: https://github.com/bugzilla/bugzilla
- Installation guide: https://bugzilla.readthedocs.io/en/latest/installing/
- Upgrade guide: https://bugzilla.readthedocs.io/en/latest/upgrading/
- Release downloads: https://www.bugzilla.org/download/
