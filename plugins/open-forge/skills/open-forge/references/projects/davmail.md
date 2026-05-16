---
name: davmail-project
description: DavMail recipe for open-forge. Covers JAR/package install, headless daemon setup via davmail.properties, Docker (community image), and O365 Modern Auth / OAuth configuration. Bridges standard email clients (Thunderbird, Apple Mail, Evolution) to Microsoft Exchange / Office 365 via OWA.
---

# DavMail

POP/IMAP/SMTP/CalDAV/CardDAV/LDAP gateway that bridges standard email clients to Microsoft Exchange and Office 365 via OWA (Outlook Web Access). Use Thunderbird, Apple Mail, Evolution, or any standards-based client with a corporate Exchange server — no Outlook required. GPL-2.0.

- **GitHub:** https://github.com/mguessan/davmail (719 stars)
- **Site / downloads:** https://davmail.sourceforge.net/
- **Download (JAR + OS packages):** https://sourceforge.net/projects/davmail/files/davmail/

## Compatible install methods

| Method | When to use |
|---|---|
| JAR (`davmail.jar`) | Cross-platform; Java 11+ required |
| Debian/Ubuntu `.deb` package | Native service integration on Debian-family distros |
| RPM package | Fedora / RHEL / CentOS |
| macOS `.dmg` (GUI) | Desktop use on Mac |
| Docker (community image `nicber/davmail`) | Containerised headless deployment |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Exchange/OWA URL (e.g. https://mail.company.com/owa) or Office 365?" | Set `davmail.url` |
| preflight | "Connection mode: EWS / O365Modern / O365Interactive / WebDav / Auto?" | See mode table below |
| network | "Ports to expose? (defaults are fine for local use)" | See default port table below |
| auth | "O365 tenant ID and client ID? (required for O365Modern OAuth)" | Only for modern auth |
| headless | "Run as a GUI app or headless daemon?" | Headless requires `davmail.properties` |

### Connection modes

| Mode | When to use |
|---|---|
| `O365Modern` | Office 365 with Modern Authentication (OAuth2) — recommended for O365 |
| `O365Interactive` | O365 with browser-based interactive OAuth login |
| `EWS` | On-premises Exchange 2007+ via Exchange Web Services |
| `WebDav` | Legacy Exchange 2003 or older OWA |
| `Auto` | Let DavMail detect — use as fallback |

## Default ports

| Protocol | Default port | Purpose |
|---|---|---|
| IMAP | 1143 | Incoming mail |
| POP3 | 1110 | Incoming mail (alternative) |
| SMTP | 1025 | Outgoing mail |
| CalDAV | 1080 | Calendar sync |
| CardDAV | 1080 | Contacts sync |
| LDAP | 1389 | Directory / address book |

> These are high-numbered non-privileged ports so DavMail can run without root. Configure your mail client to connect to `localhost:<port>`.

## Install — Debian/Ubuntu package

```bash
# Download the latest .deb from SourceForge
wget https://sourceforge.net/projects/davmail/files/davmail/<version>/davmail_<version>-1_all.deb

# Install
sudo dpkg -i davmail_<version>-1_all.deb
sudo apt-get install -f   # resolve any missing dependencies

# Enable and start as a systemd service
sudo systemctl enable davmail
sudo systemctl start davmail
```

## Install — JAR (any OS with Java)

```bash
# Requires Java 11+
java -version

# Download
wget https://sourceforge.net/projects/davmail/files/davmail/<version>/davmail-<version>.zip
unzip davmail-<version>.zip

# Run (GUI mode — opens a system tray icon)
java -jar davmail.jar

# Run headless (daemon mode)
java -jar davmail.jar davmail.properties
```

## Docker (community image)

```yaml
services:
  davmail:
    image: nicber/davmail:latest
    container_name: davmail
    restart: unless-stopped
    ports:
      - "1143:1143"   # IMAP
      - "1025:1025"   # SMTP
      - "1080:1080"   # CalDAV / CardDAV
      - "1389:1389"   # LDAP
    volumes:
      - ./davmail.properties:/etc/davmail/davmail.properties:ro
      - davmail-data:/root/.davmail

volumes:
  davmail-data:
```

## `davmail.properties` (headless configuration)

```properties
# Exchange / OWA URL — or use https://outlook.office365.com/EWS/Exchange.asmx for O365
davmail.url=https://mail.company.com/owa

# Connection mode: O365Modern | O365Interactive | EWS | WebDav | Auto
davmail.mode=EWS

# Run without GUI
davmail.server=true

# Ports (set to 0 to disable a protocol)
davmail.imapPort=1143
davmail.popPort=1110
davmail.smtpPort=1025
davmail.caldavPort=1080
davmail.ldapPort=1389

# Bind to localhost only (recommended for security)
davmail.bindAddress=127.0.0.1

# Logging
davmail.logFilePath=/var/log/davmail/davmail.log
davmail.logFileSize=1MB

# Allow remote connections (set true only if running on a remote server)
davmail.allowRemote=false

# SSL (for connecting to Exchange with a self-signed cert)
davmail.ssl.nosecuremime=false
davmail.ssl.pkcs12file=
davmail.ssl.pkcs12password=
```

Full property reference: https://davmail.sourceforge.net/serversetup.html

## O365 Modern Authentication (OAuth2)

For Office 365 with MFA/conditional access policies, `O365Modern` mode uses OAuth2:

1. Set `davmail.mode=O365Modern` in `davmail.properties`.
2. On first connection DavMail opens a browser window for the OAuth consent flow. The token is cached for subsequent connections.
3. For truly headless deployments, register an Azure app:
   - Azure Portal → Azure Active Directory → App registrations → New registration
   - Add Redirect URI: `http://localhost` (type: Public client/native)
   - Note the **Application (client) ID** and **Tenant ID**
   - Set in properties: `davmail.oauth.clientId=<client-id>` and `davmail.oauth.tenantId=<tenant-id>`

Reference: https://davmail.sourceforge.net/o365.html

## Configuring email clients

### Thunderbird

- **Incoming (IMAP):** server `localhost`, port `1143`, no SSL, normal password
- **Outgoing (SMTP):** server `localhost`, port `1025`, no SSL, normal password
- Username: your full Exchange email address (e.g. `user@company.com`)
- Password: your Exchange / O365 password (or OAuth token handled transparently by DavMail)

### Apple Mail / iOS

- IMAP server: `localhost:1143`
- SMTP server: `localhost:1025`
- CalDAV: `http://localhost:1080/principals/` (Calendars → Add Account → Other → CalDAV)
- CardDAV: `http://localhost:1080/carddav/` (Contacts → Add Account → Other → CardDAV)

## Notes

- Run DavMail on the same machine as your email client for lowest complexity; or on a LAN server and set `davmail.allowRemote=true` with firewall rules.
- DavMail does not store mail — it proxies requests live to Exchange/O365.
- Logs are invaluable for debugging auth issues: check `davmail.logFilePath`.
- Modern O365 tenants often require the `O365Modern` mode even for EWS endpoints.
