---
name: inspircd
description: InspIRCd recipe for open-forge. Modular IRC server written in C++ for Linux, BSD, Windows, and macOS. Clean codebase with well-documented module system for customizing features. Available via Docker, binary packages, or source build. Source: https://github.com/inspircd/inspircd
---

# InspIRCd

Modular Internet Relay Chat (IRC) server written in C++ for UNIX-like systems and Windows. Built from scratch to be stable, modern, and lightweight. Highly customizable via a well-documented module system — core functionality is kept minimal and features are added through modules. Supports TLS, SASL, oper privileges, ban management, channel modes, services integration, and more via modules. Upstream: https://github.com/inspircd/inspircd. Docs: https://docs.inspircd.org/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker | Linux | Recommended for quick deployment |
| Binary packages | Debian / Ubuntu / RHEL / Windows | Official .deb/.rpm from GitHub releases |
| Build from source | Linux / BSD / macOS / Windows | Full control; UNIX-like systems recommended |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "IRC network name?" | e.g. MyNet — displayed in server banners |
| server | "Server hostname (FQDN)?" | Must be a valid FQDN e.g. irc.example.com |
| server | "Server description?" | One-line description |
| admin | "Oper username + password?" | IRC operator credentials for server admin |
| ports | "Client ports?" | Default: 6667 (plaintext), 6697 (TLS) |
| tls | "TLS certificate?" | Self-signed or Let's Encrypt |

## Software-layer concerns

### Method 1: Docker (recommended)

  # Quick start:
  docker run --name ircd -p 6667:6667 -p 6697:6697 inspircd/inspircd-docker

  # With custom config directory:
  docker run --name ircd \
    -p 6667:6667 \
    -p 6697:6697 \
    -v /path/to/config:/inspircd/conf/ \
    inspircd/inspircd-docker

  # Note: if providing an empty config directory, set ownership to UID 10000:
  chown 10000 /path/to/config

  # With environment variable configuration (no config file needed):
  docker run --name ircd \
    -p 6667:6667 \
    -p 6697:6697 \
    -e INSP_NET_NAME="MyNetwork" \
    -e INSP_SERVER_NAME="irc.example.com" \
    -e INSP_ADMIN_NAME="Your Name" \
    -e INSP_ADMIN_EMAIL="admin@example.com" \
    inspircd/inspircd-docker

  # Available environment variables:
  # INSP_NET_SUFFIX       .example.com       Suffix appended to server name
  # INSP_NET_NAME         ExampleNet         IRC network name
  # INSP_SERVER_NAME      <container-id>+suffix  Server FQDN
  # INSP_ADMIN_NAME       Adam Inistrator    /ADMIN name
  # INSP_ADMIN_DESC       Supreme Overlord   /ADMIN description
  # INSP_ADMIN_EMAIL      noreply@server     /ADMIN email
  # INSP_ENABLE_DNSBL     yes                Set to 'no' to disable DNS blacklists
  # INSP_CONNECT_PASSWORD (none)             Connection password
  # INSP_CONNECT_HASH     (none)             Hash algorithm for connect password

### Method 2: Binary packages (Debian/Ubuntu)

  # Download .deb from GitHub releases:
  # https://github.com/inspircd/inspircd/releases/latest

  dpkg -i inspircd_4.x.y_amd64.deb
  apt-get install -f   # resolve dependencies if needed

  systemctl enable inspircd && systemctl start inspircd

### Method 3: Build from source

  # Prerequisites: C++ compiler (GCC 7+ or Clang 5+), pkg-config, libssl-dev
  apt-get install g++ pkg-config libssl-dev

  git clone https://github.com/inspircd/inspircd.git
  cd inspircd
  ./configure --prefix=/opt/inspircd --enable-extras ssl_openssl
  make -j$(nproc)
  make install

  # Config created at: /opt/inspircd/conf/
  /opt/inspircd/bin/inspircd start

### Configuration (inspircd.conf)

  # Full config reference: https://docs.inspircd.org/4/configuration/

  # Minimal example sections:
  # <server name="irc.example.com" description="My IRC Server" network="MyNet">
  # <admin name="Admin" nick="Admin" email="admin@example.com">
  # <bind address="" port="6667" type="clients">
  # <bind address="" port="6697" type="clients" ssl="openssl">
  # <connect allow="*" password="optional" ...>
  # <oper name="admin" password="sha256-hash" type="NetAdmin" host="*@*">

  # To hash oper passwords:
  /opt/inspircd/bin/inspircd --mkpasswd hmac-sha256 yourpassword

### Key ports

  6667/tcp   # Client plaintext
  6697/tcp   # Client TLS (ircs://)
  7000/tcp   # Server-to-server plaintext
  7001/tcp   # Server-to-server TLS

### Modules

  # InspIRCd 4 loads modules dynamically.
  # Enable modules in inspircd.conf:
  # <module name="cap">
  # <module name="sasl">
  # <module name="services_account">
  # <module name="ssl_openssl">
  # <module name="hostchange">

  # Module list: https://docs.inspircd.org/4/modules/

### systemd service

  # If installed from package:
  systemctl start inspircd
  systemctl enable inspircd
  systemctl status inspircd

## Upgrade procedure

  # Docker: pull new image
  docker pull inspircd/inspircd-docker:latest
  docker stop ircd && docker rm ircd
  # Re-run docker run command with new image

  # Binary: download new .deb/.rpm from releases and reinstall
  # Source: git pull, ./configure, make, make install

## Gotchas

- **DNSBL checks on new installs**: by default, client connections are checked against DNS blacklists. If users experience connection timeouts, try setting `INSP_ENABLE_DNSBL=no` (Docker) or disabling DNSBL modules in config.
- **UID 10000**: the Docker image runs as UID 10000. Custom config directories must be owned by this UID.
- **No default oper account**: you must configure at least one `<oper>` block to gain IRC operator access. Hash passwords with `--mkpasswd hmac-sha256`.
- **Modules must be explicitly loaded**: unlike some IRC servers, InspIRCd does not enable features automatically. Add `<module name="...">` entries for every feature you want.
- **TLS requires ssl_openssl or ssl_gnutls module**: load and configure one of these for TLS support. Without it, the TLS port will fail to bind.
- **Server name must be FQDN**: `<server name>` must be a fully qualified domain name (dots required). Using just a hostname without a domain will cause linking and connection issues.
- **Services integration**: for NickServ/ChanServ, run a separate IRC services daemon (Atheme, Anope) and link it to InspIRCd via server-to-server linking.

## References

- Upstream GitHub: https://github.com/inspircd/inspircd
- Docker image repo: https://github.com/inspircd/inspircd-docker
- Documentation: https://docs.inspircd.org/
- Installation (source): https://docs.inspircd.org/4/installation/source
- Module list: https://docs.inspircd.org/4/modules/
- Binary packages: https://github.com/inspircd/inspircd/releases/latest
