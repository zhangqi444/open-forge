---
name: davmail-project
description: DavMail recipe for open-forge. Covers desktop GUI install, headless server daemon, and Docker (community image). DavMail bridges standard email/calendar/contacts clients (Thunderbird, Apple Mail, Evolution) to Microsoft Exchange / Office 365 via OWA or EWS.
---

# DavMail

POP/IMAP/SMTP/CalDAV/CardDAV/LDAP gateway that bridges standard email and calendar clients to Microsoft Exchange / Office 365 via OWA (Outlook Web Access) or EWS. Lets you use Thunderbird, Apple Mail, Evolution, or any standard client with a corporate Exchange/O365 account — without needing Outlook. GPL-2.0. Upstream: <https://github.com/mguessan/davmail>. Site: <https://davmail.sourceforge.net/>.

DavMail runs locally (desktop or server) and exposes standard protocol ports. Your email client connects to DavMail as if it were a normal mail server; DavMail forwards the traffic to Exchange / O365.

## Compatible install methods

| Method | When to use |
|---|---|
| Desktop GUI (JAR / OS package) | Running DavMail on your workstation alongside your email client |
| Headless daemon (JAR + `davmail.properties`) | Running on a Linux server, NAS, or Raspberry Pi |
| Docker (community image `nicber/davmail`) | Containerised headless deployment |

## Default ports

| Service | Port |
|---|---|
| IMAP | 1143 |
| POP3 | 1110 |
| SMTP | 1025 |
| CalDAV + CardDAV (HTTP) | 1080 |
| LDAP | 1389 |

All ports are above 1024 so DavMail can run as a non-root user. Configure your email client to point to `127.0.0.1` (or the server IP) at these ports.

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Install method?" (Desktop GUI / Headless server / Docker) | Drives which section to follow |
| exchange | "Exchange / O365 OWA URL?" (e.g. `https://mail.company.com/owa` or `https://outlook.office365.com/owa`) | All |
| exchange | "Connection mode?" (`O365Modern` for modern O365, `EWS` for on-premises Exchange 2010+, `WebDav` for very old Exchange) | All |
| auth | "Does your organisation use modern OAuth / MFA for O365?" | If mode = `O365Modern` — requires token setup |
| ports | "Which protocols does your email client need?" (IMAP / POP3 / SMTP / CalDAV / CardDAV / LDAP) | Determines which ports to expose |

After each prompt, record the value in the state file under `inputs.*`.

---

## Phase 1 — Download

### JAR / OS packages

Download from: <https://sourceforge.net/projects/davmail/files/davmail/>

Available packages:

| Package | Use for |
|---|---|
| `davmail-<version>-dist.zip` | Cross-platform ZIP containing the JAR |
| `davmail_<version>_all.deb` | Debian / Ubuntu |
| `davmail-<version>-1.noarch.rpm` | RHEL / Fedora / openSUSE |
| `DavMail-<version>.pkg` | macOS |
| `DavMail-<version>-setup.exe` | Windows installer |

### Docker (community)

```bash
docker pull nicber/davmail
```

---

## Method — Desktop GUI

Start DavMail by double-clicking the JAR or launching the OS package. On first run a GUI wizard appears.

### JAR start (cross-platform)

```bash
java -jar davmail.jar
```

Requires Java 11+. Install via `apt install default-jre` (Debian/Ubuntu), `brew install openjdk` (macOS), or <https://adoptium.net/> (Windows/macOS/Linux).

### GUI wizard

Fill in:

| Field | Value |
|---|---|
| Gateway URL | Your OWA URL (e.g. `https://mail.company.com/owa`) |
| Connection mode | `O365Modern` (O365) / `EWS` (on-prem Exchange 2010+) / `WebDav` (old) |
| IMAP port | `1143` (default) |
| POP3 port | `1110` (default) |
| SMTP port | `1025` (default) |
| CalDAV port | `1080` (default) |
| LDAP port | `1389` (default) |

Click **Save**. DavMail starts listening. Configure your email client (see Client configuration below).

---

## Method — Headless daemon

For servers, NAS, or Raspberry Pi without a display.

### Install Java

```bash
# Debian / Ubuntu
apt-get install -y default-jre-headless

# Check
java -version
```

### Install DavMail .deb

```bash
wget "https://sourceforge.net/projects/davmail/files/davmail/<VERSION>/davmail_<VERSION>_all.deb"
dpkg -i davmail_<VERSION>_all.deb
```

### Configure `davmail.properties`

The configuration file is at `/etc/davmail/davmail.properties` (package install) or wherever you place it.

Key settings:

```properties
# OWA / Exchange URL
davmail.url=https://mail.company.com/owa

# Connection mode: O365Modern, EWS, WebDav, or Auto
davmail.mode=O365Modern

# Headless mode (no GUI) — set to true for server
davmail.server=true

# Bind address — 0.0.0.0 to allow remote clients, 127.0.0.1 for local only
davmail.bindAddress=127.0.0.1

# Ports (0 = disabled)
davmail.imapPort=1143
davmail.pop3Port=1110
davmail.smtpPort=1025
davmail.caldavPort=1080
davmail.ldapPort=1389

# Logging
davmail.logFileSize=1MB
davmail.logFilePath=/var/log/davmail/davmail.log
```

### Start headless

```bash
# Run directly
java -jar /usr/share/davmail/davmail.jar /etc/davmail/davmail.properties

# Or via the systemd unit (if installed by .deb)
systemctl enable davmail
systemctl start davmail
systemctl status davmail
```

### Run as a non-root systemd service (manual install)

```bash
# Create system user
useradd -r -s /bin/false davmail

# Create log dir
mkdir -p /var/log/davmail
chown davmail:davmail /var/log/davmail

# Create service unit
cat > /etc/systemd/system/davmail.service << 'EOF'
[Unit]
Description=DavMail Gateway
After=network.target

[Service]
User=davmail
ExecStart=/usr/bin/java -jar /opt/davmail/davmail.jar /etc/davmail/davmail.properties
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now davmail
```

---

## Method — Docker (community image)

```yaml
# compose.yaml
services:
  davmail:
    image: nicber/davmail
    restart: unless-stopped
    ports:
      - "1143:1143"   # IMAP
      - "1110:1110"   # POP3
      - "1025:1025"   # SMTP
      - "1080:1080"   # CalDAV / CardDAV
      - "1389:1389"   # LDAP
    volumes:
      - ./davmail.properties:/etc/davmail/davmail.properties:ro
    environment:
      - JAVA_OPTS=-Xmx256m
```

Place your `davmail.properties` file next to the `compose.yaml`, then:

```bash
docker compose up -d
docker compose logs -f davmail
```

---

## Client configuration

After DavMail is running, configure your email client to connect to `127.0.0.1` (or the server IP) with your **Exchange username and password**:

### Thunderbird

| Setting | Value |
|---|---|
| IMAP server | `127.0.0.1` port `1143`, no SSL (STARTTLS off) |
| SMTP server | `127.0.0.1` port `1025`, no SSL |
| Username | Your Exchange email address or `DOMAIN\username` |
| Password | Your Exchange password |

For CalDAV (Thunderbird + Lightning):

| Setting | Value |
|---|---|
| CalDAV URL | `http://127.0.0.1:1080/users/<your-email>/calendar/` |

### Apple Mail / Calendar

Add an account with type **Other** (not Exchange). Point IMAP to `127.0.0.1:1143` and SMTP to `127.0.0.1:1025`.

---

## O365 Modern Auth (OAuth) setup

If your O365 tenant requires modern authentication (MFA, Conditional Access), DavMail must obtain an OAuth token. Set `davmail.mode=O365Modern` in `davmail.properties`.

On **first connect** (desktop mode):

1. DavMail opens a browser window for O365 login.
2. Complete MFA as normal.
3. DavMail caches the token and refreshes it automatically.

In **headless mode**, OAuth requires a pre-obtained refresh token. The recommended approach:

1. Run DavMail in desktop mode once on a machine with a browser to complete OAuth.
2. Copy the token from `~/.davmail/<email>_token` to the headless server.

See DavMail's O365 OAuth guide: <https://davmail.sourceforge.net/o365.html>.

---

## Verify

```bash
# Check DavMail is listening
ss -tlnp | grep -E '1143|1110|1025|1080|1389'

# Test IMAP connection
openssl s_client -connect 127.0.0.1:1143   # or: telnet 127.0.0.1 1143
# Should receive: * OK DavMail ready

# Check logs
tail -f /var/log/davmail/davmail.log   # package install
# or:
docker compose logs -f davmail          # Docker
```

---

## Lifecycle

```bash
# Restart after config change
systemctl restart davmail         # systemd
docker compose restart davmail    # Docker

# Update DavMail (package)
apt-get update && apt-get upgrade davmail

# Update Docker image
docker compose pull && docker compose up -d

# View logs
journalctl -u davmail -f          # systemd
docker compose logs -f davmail    # Docker
```

---

## Gotchas

- **O365 Modern Auth / MFA.** If the tenant enforces MFA, plain password auth will fail. You must use `davmail.mode=O365Modern` and complete OAuth token setup. See the O365 OAuth guide above.
- **Port numbers above 1024.** DavMail intentionally uses non-standard ports (1143 not 143, 1025 not 25) so it can run without root. Configure your email client with the DavMail ports, not the standard IMAP/SMTP ports.
- **`davmail.bindAddress=127.0.0.1` vs `0.0.0.0`.** The default binds only to localhost. If your email client runs on a different machine, change to `0.0.0.0` and add a firewall rule to restrict access.
- **Java required.** DavMail is a Java app. `default-jre-headless` is sufficient for headless mode; the GUI requires a full JRE with AWT.
- **CalDAV + CardDAV on the same port (1080).** Both are served on HTTP port 1080. The URL path distinguishes them: `/users/<email>/calendar/` vs `/users/<email>/contacts/`.
- **No TLS on DavMail's listening ports.** DavMail communicates with Exchange over HTTPS but its own listening ports are plain (not encrypted). Keep DavMail on localhost or in a trusted network. If remote access is required, tunnel through SSH or a VPN.

---

## Resources

- Site: <https://davmail.sourceforge.net/>
- GitHub: <https://github.com/mguessan/davmail> (~719 stars)
- Downloads: <https://sourceforge.net/projects/davmail/files/davmail/>
- O365 OAuth guide: <https://davmail.sourceforge.net/o365.html>
- License: GPL-2.0
