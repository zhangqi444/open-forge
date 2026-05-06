---
name: kamailio
description: Kamailio recipe for open-forge. High-performance open-source SIP server — VoIP proxy, registrar, load balancer, presence server, WebRTC gateway. Debian/Docker install. Upstream: https://github.com/kamailio/kamailio
---

# Kamailio

High-performance, open-source SIP Signaling Server. The backbone of large-scale VoIP deployments — carrier-grade SIP proxy, registrar, load balancer, presence server, and WebRTC gateway. Handles millions of calls on commodity hardware.

2,806 stars · GPL-2.0

Upstream: https://github.com/kamailio/kamailio
Website: https://www.kamailio.org
Docs: https://www.kamailio.org/wikidocs/
Docker Hub: https://hub.docker.com/r/kamailio/kamailio

## What it is

Kamailio provides a flexible, modular SIP signaling infrastructure:

- **SIP proxy/router** — Route SIP calls between endpoints, carriers, and media servers
- **Registrar** — Manage SIP endpoint registrations (phones, softphones)
- **Load balancer** — Distribute SIP traffic across multiple media servers or proxies
- **Presence server** — Buddy list and presence (online/offline status)
- **WebRTC gateway** — Bridge WebRTC clients to SIP networks
- **Authentication** — Digest auth, database-backed, radius, LDAP
- **TLS/SRTP** — Encrypted signaling and media support
- **NAT traversal** — RTPproxy and RTPengine integration for media relay
- **Modular architecture** — 200+ modules: database connectors, auth, CDRs, GeoIP, Kafka, Redis, REST, and more
- **Scripting** — Powerful routing logic in Kamailio Script (kamailio.cfg), with Lua, Python, JavaScript, and Perl module support
- **High availability** — Active-active clustering, database replication
- **CDRs** — Call detail records to database or files
- **Push notifications** — APNS/FCM for SIP mobile clients
- **REST API** — JSON-RPC and MI HTTP interface for management

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | kamailio/kamailio image | Official image; good for dev/testing |
| Debian/Ubuntu | .deb from Kamailio repo | Recommended for production |
| CentOS/RHEL | .rpm from Kamailio repo | Supported |
| Bare metal | Compile from source | Full control; requires C build tools |

## Inputs to collect

### Phase 1 — Pre-install
- SIP domain (e.g. sip.example.com)
- Database backend (MySQL, PostgreSQL, or none for non-persistent)
- Authentication type (database, radius, etc.)
- IP addresses to bind (public + private)
- RTP relay strategy (RTPproxy, RTPengine, or none)

### Phase 2 — Config (kamailio.cfg)
- SIP_DOMAIN — your SIP domain
- Database credentials if using db_mysql/db_postgres
- TLS cert paths if enabling TLS

## Software-layer concerns

### Config file
- /etc/kamailio/kamailio.cfg — main routing script (Kamailio's powerful DSL)
- /etc/kamailio/kamailio-local.cfg — local overrides (included from main cfg)
- /etc/default/kamailio — startup options (Debian)

### Ports
- UDP/TCP 5060 — SIP (standard)
- TCP 5061 — SIP TLS
- UDP/TCP 5080 — Alternative SIP port (common for WebRTC)

### Database init (MySQL example)
  kamdbctl create    # creates and populates Kamailio DB tables
  # or manually:
  mysql -u root < /usr/share/kamailio/mysql/standard-create.sql

### Docker run
  docker run -d --name kamailio \
    -p 5060:5060/udp \
    -p 5060:5060/tcp \
    -v /path/to/kamailio.cfg:/etc/kamailio/kamailio.cfg:ro \
    kamailio/kamailio:latest

### Debian install (production)
  # Add Kamailio apt repository
  wget -O /usr/share/keyrings/kamailio-archive-keyring.gpg \
    https://deb.kamailio.org/kamailiodebkey.gpg
  echo "deb [signed-by=/usr/share/keyrings/kamailio-archive-keyring.gpg] \
    http://deb.kamailio.org/kamailio61 bookworm main" \
    > /etc/apt/sources.list.d/kamailio.list
  apt update && apt install kamailio kamailio-mysql-modules kamailio-tls-modules

### Minimal kamailio.cfg snippet
  #!define DBURL "mysql://kamailio:pass@localhost/kamailio"
  loadmodule "usrloc.so"
  loadmodule "registrar.so"
  loadmodule "auth.so"
  loadmodule "auth_db.so"
  # ... routing blocks follow

## Upgrade procedure

1. Backup /etc/kamailio/
2. Backup database: mysqldump -u kamailio -p kamailio > backup.sql
3. Debian: apt update && apt upgrade kamailio kamailio-* (stays within major version)
4. For major version upgrade: add new apt repo, then upgrade
5. Run kamdbctl migrate if prompted for DB schema changes
6. Reload or restart: kamailio ctl reload (graceful) or service kamailio restart
7. Verify with: kamctl monitor and check SIP registrations

## Gotchas

- Complex config DSL — kamailio.cfg uses a custom routing script language; steep learning curve; use the default templates from kamailio.org as starting points
- RTP relay required for NAT — Kamailio handles signaling only; for clients behind NAT, deploy RTPengine or RTPproxy to relay media
- Database initialization — do not skip kamdbctl create; Kamailio modules expect specific table schemas
- UDP firewall — SIP over UDP; cloud providers often block UDP 5060 by default; explicitly open it
- SIP ALG interference — home routers with SIP ALG can corrupt SIP packets; disable SIP ALG on any NAT device between Kamailio and endpoints
- Logging verbosity — default log level is verbose; set debug=0 or debug=1 in production to avoid disk fill
- WebRTC gateway — for WebRTC-to-SIP bridging you also need a media transcoder (e.g. Asterisk with WebRTC module, or FreeSWITCH); Kamailio alone does signaling only

## Links

- Upstream README: https://github.com/kamailio/kamailio/blob/master/README.md
- Documentation wiki: https://www.kamailio.org/wikidocs/
- Docker images: https://hub.docker.com/r/kamailio/kamailio
- Kamailio apt repo: https://www.kamailio.org/w/packages/
- Getting started tutorial: https://www.kamailio.org/docs/tutorials/getting-started/
