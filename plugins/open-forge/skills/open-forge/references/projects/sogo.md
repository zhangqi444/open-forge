---
name: sogo
description: SOGo recipe for open-forge. Covers package install (Debian/Ubuntu) with PostgreSQL or MySQL, and Docker. SOGo is a groupware server providing CalDAV, CardDAV, GroupDAV, ActiveSync, and a web interface — with native Outlook compatibility.
---

# SOGo

Open-source groupware server providing shared calendars, contacts, and email. Supports CalDAV, CardDAV, GroupDAV, and Microsoft Exchange ActiveSync (including native Outlook connectivity). Includes a web interface and integrates with Postfix/Dovecot for a full mail+groupware stack. Upstream: <https://github.com/Alinto/sogo>. Website: <https://www.sogo.nu>. Demo: <https://demo.sogo.nu/SOGo/>.

**License:** LGPL-2.1 · **Language:** Objective-C (GNUstep) · **Default port:** 20000 (proxied via nginx/Apache) · **Stars:** ~2,100

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Package install (Debian/Ubuntu) | <https://www.sogo.nu/files/docs/SOGoInstallationGuide.html> | ✅ | **Recommended** — official Alinto apt repository, easiest maintenance. |
| Package install (RHEL/CentOS/Fedora) | <https://www.sogo.nu/files/docs/SOGoInstallationGuide.html> | ✅ | Official RPM repository. |
| Docker Compose | <https://github.com/Alinto/sogo/tree/master/Docker> | ✅ | Containerized deploy — SOGo + memcached stack. |
| Source compile | <https://sogo.nu/support/faq/how-do-i-compile-sogo.html> | ✅ | Cutting-edge or custom builds — requires GNUstep toolchain. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method — packages (Debian/Ubuntu/RHEL) or Docker?" | AskUserQuestion | Determines section. |
| os_version | "OS and version? (e.g. Ubuntu 24.04, Debian 12)" | Free-text | Package install. |
| database | "Database: PostgreSQL or MySQL/MariaDB?" | AskUserQuestion | All methods. |
| db_credentials | "Database host, name, username, password?" | Free-text (sensitive) | All methods. |
| ldap | "User authentication: LDAP/Active Directory, or SQL-based?" | AskUserQuestion | Determines auth config. |
| ldap_url | "LDAP server URL and bind credentials?" | Free-text (sensitive) | If LDAP selected. |
| domain | "Mail domain for SOGo (e.g. example.com)?" | Free-text | All methods. |
| imap | "IMAP server host and port for email access?" | Free-text | Required for email tab. |
| smtp | "SMTP server host and port for sending?" | Free-text | Required for email. |

## Install — Packages (Debian/Ubuntu)

Reference: <https://www.sogo.nu/files/docs/SOGoInstallationGuide.html>

### 1. Add Alinto repository

```bash
# Ubuntu 24.04 / Debian 12 example
sudo apt-get install -y apt-transport-https ca-certificates gnupg

# Add the signing key
curl -sSL https://keys.openpgp.org/vks/v1/by-fingerprint/74FFC6D72B925A34B5D356BDF8A27B36A6E2EAE8 \
  | sudo gpg --dearmor -o /usr/share/keyrings/alinto-sogo.gpg

# Add repository (check https://www.sogo.nu/files/docs/SOGoInstallationGuide.html for current URL)
echo "deb [signed-by=/usr/share/keyrings/alinto-sogo.gpg] https://packages.sogo.nu/ubuntu $(lsb_release -cs) restricted" \
  | sudo tee /etc/apt/sources.list.d/sogo.list

sudo apt-get update
```

> **Note:** Always check the [official installation guide](https://www.sogo.nu/files/docs/SOGoInstallationGuide.html) for the current repository URL — it changes with OS releases.

### 2. Install SOGo

```bash
sudo apt-get install -y sogo sogo-tool

# Also install memcached (strongly recommended for performance)
sudo apt-get install -y memcached
```

### 3. Configure database

PostgreSQL example:

```bash
sudo -u postgres psql <<'SQL'
CREATE USER sogo WITH PASSWORD 'sogopassword';
CREATE DATABASE sogo OWNER sogo;
SQL
```

SOGo stores user data (calendars, contacts, prefs) in the DB. If using SQL auth, also create a users table (see installation guide for schema).

### 4. Configure SOGo

Edit `/etc/sogo/sogo.conf` (GNUstep property list format):

```plist
{
  /* Database */
  OCSFolderInfoURL = "postgresql://sogo:sogopassword@localhost/sogo/sogo_folder_info";

  /* IMAP */
  SOGoIMAPServer = "imaps://imap.example.com:993";

  /* SMTP */
  SOGoSMTPServer = "smtp://smtp.example.com:587";
  SOGoSMTPAuthenticationType = PLAIN;

  /* Auth (LDAP example) */
  SOGoUserSources = (
    {
      type = ldap;
      CNFieldName = cn;
      UIDFieldName = uid;
      IDFieldName = uid;
      bindDN = "cn=admin,dc=example,dc=com";
      bindPassword = "ldappassword";
      canAuthenticate = YES;
      displayName = "Shared Addresses";
      hostname = "ldap://ldap.example.com";
      id = ldap;
      isAddressBook = YES;
      port = 389;
      baseDN = "ou=users,dc=example,dc=com";
    }
  );

  /* Web */
  SOGoPageTitle = "My Groupware";
  SOGoLanguage = English;
  SOGoTimeZone = "America/New_York";

  /* Memcached */
  SOGoMemcachedHost = "127.0.0.1";

  /* Workers */
  WOWorkersCount = 5;
}
```

### 5. nginx reverse proxy

SOGo runs on port 20000; it must be proxied:

```nginx
server {
    listen 443 ssl;
    server_name groupware.example.com;

    # SOGo web interface
    location /SOGo {
        proxy_pass http://127.0.0.1:20000;
        proxy_redirect http://127.0.0.1:20000 https://groupware.example.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header x-webobjects-server-url https://groupware.example.com;
        proxy_set_header x-webobjects-server-name groupware.example.com;
        proxy_set_header x-webobjects-server-port 443;
        proxy_set_header x-webobjects-server-protocol HTTP/1.0;
    }

    # ActiveSync
    location /Microsoft-Server-ActiveSync {
        proxy_pass http://127.0.0.1:20000/SOGo/Microsoft-Server-ActiveSync;
        proxy_redirect default;
        proxy_connect_timeout 75;
        proxy_send_timeout 3600;
        proxy_read_timeout 3600;
        proxy_set_header Host $host;
        proxy_set_header x-webobjects-server-url https://groupware.example.com;
    }
}
```

### 6. Start SOGo

```bash
sudo systemctl enable --now sogo
sudo systemctl enable --now memcached
```

Access the web UI at: `https://groupware.example.com/SOGo`

## Install — Docker Compose

Reference: <https://github.com/Alinto/sogo/tree/master/Docker>

```bash
git clone https://github.com/Alinto/sogo.git
cd sogo/Docker

# Copy and customize env file
cp sogo.env.sample sogo.env
nano sogo.env  # set DB, LDAP, SMTP, IMAP settings

docker compose up -d
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | PostgreSQL (recommended) or MySQL/MariaDB. Stores calendar/contact/preference data in OCS tables. |
| LDAP/AD | Typical production deploy uses LDAP or Active Directory for user auth. SQL-based auth also supported. |
| Memcached | Strongly recommended for performance — caches session data and folder info. |
| nginx proxy | SOGo's built-in WOPort (20000) is not TLS-capable — always proxy through nginx or Apache with TLS. |
| ActiveSync | Microsoft Outlook / mobile clients connect via ActiveSync endpoint. Requires additional nginx location block (see above). |
| IMAP/SMTP | SOGo is groupware middleware, not a mail server. Requires an external IMAP server (Dovecot, Cyrus) and SMTP relay. |
| Workers | `WOWorkersCount` in sogo.conf controls concurrency. Set to 2× CPU cores for production. |
| CalDAV/CardDAV | Clients connect directly to `/SOGo/dav/` for calendar and contact sync. |
| Cron | SOGo alaarms daemon: `sudo -u sogo /usr/sbin/sogo-ealarms-notify` — run via cron for event notifications. |

## Upgrade procedure

```bash
sudo apt-get update && sudo apt-get upgrade sogo

# Restart after upgrade
sudo systemctl restart sogo
```

For schema migrations, run:

```bash
sudo -u sogo /usr/sbin/sogo-tool update-autoreply
```

Back up the database before major version upgrades.

## Gotchas

- **Always proxy via nginx/Apache:** SOGo does not support TLS natively on its WOPort. Browsers and mobile clients will refuse connections without TLS.
- **ActiveSync proxy timeout:** ActiveSync uses long-polling (up to 30 min). Set `proxy_read_timeout 3600` in nginx or mobile sync will constantly drop and reconnect.
- **x-webobjects-server-url header:** This header must match the actual public HTTPS URL exactly (including scheme and no trailing slash). Wrong value breaks CalDAV autodiscovery, ActiveSync, and web redirects.
- **Memcached required for multi-worker:** If running `WOWorkersCount > 1`, Memcached is mandatory for session sharing between worker processes. Without it, users get random session drops.
- **Repository URL changes:** Alinto's package repository URL has changed across OS versions. Always verify the current URL in the [official installation guide](https://www.sogo.nu/files/docs/SOGoInstallationGuide.html) rather than relying on old tutorials.
- **GNUstep config format:** `sogo.conf` uses GNUstep property list syntax (not JSON, not YAML). Invalid syntax causes SOGo to silently fall back to defaults.

## Upstream links

- GitHub: <https://github.com/Alinto/sogo>
- Installation guide: <https://www.sogo.nu/files/docs/SOGoInstallationGuide.html>
- Website: <https://www.sogo.nu>
- Demo: <https://demo.sogo.nu/SOGo/>
- FAQ / compilation: <https://sogo.nu/support/faq/how-do-i-compile-sogo.html>
- Mailing list: <https://groups.google.com/group/sogo-users>
