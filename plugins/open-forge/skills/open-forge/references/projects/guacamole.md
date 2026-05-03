---
name: Apache Guacamole
description: "Clientless remote desktop gateway — access VNC / RDP / SSH via your web browser over HTML5 + WebSocket. Enterprise-grade; Apache Software Foundation project. Java web app (guacamole-client) + C proxy daemon (guacamole-server/guacd). Apache-2.0. The OSS bastion/jump-host UI."
---

# Apache Guacamole

Apache Guacamole is **"remote desktops, in your browser, with no client software"** — an HTML5 + WebSocket gateway that lets users access **VNC, RDP, SSH, Kubernetes pods + containers, serial consoles** from a browser. You install Guacamole on a server; users browse to it, authenticate, see a list of pre-configured connections, and click to get a full remote desktop or terminal session **inside the browser tab**. No VPN, no RDP client install, no SSH key management on user devices. The canonical **OSS bastion / jump host** solution; also popular as a unified remote-access dashboard for homelab + VM-heavy environments.

Built + maintained by **Apache Software Foundation** (ASF) — enterprise-grade governance, long release history, part of the Apache Incubator alum now top-level project. **Apache-2.0** license throughout. Architecture is 2-part: **guacamole-server** (this repo — C daemon `guacd` that translates RDP/VNC/SSH to the Guacamole binary protocol) + **guacamole-client** (separate repo — Java web app that serves the UI).

Use cases: (a) **browser-based jump host** for ops teams (b) **homelab remote access** to a fleet of VMs/containers/servers (c) **RDP gateway** without exposing RDP to the internet (d) **customer support** — remote into user sessions via browser (e) **BYOD environments** — no client install required on user laptops (f) **air-gapped network** remote-access pattern (g) **Kubernetes / container consoles** in a browser.

Features:

- **Protocols**: VNC, RDP, SSH, Telnet, Kubernetes pods + containers
- **Clientless** — everything runs in a browser (HTML5 + WebSocket)
- **Session recording** — record + replay sessions for audit
- **User + group management** — LDAP, SAML, OIDC, Radius, DB
- **MFA support** — TOTP, Duo
- **Connection sharing** — multiple users can watch/control same session (support scenarios)
- **File transfer** — SFTP integration for SSH sessions
- **Clipboard integration** across the browser ↔ remote
- **Mobile-friendly** — works on tablets/phones (with caveats)
- **Extensible** — auth provider plugin system (LDAP, SAML, OIDC, headers, etc.)

- Upstream `guacamole-server` repo (this recipe's subject): <https://github.com/apache/guacamole-server>
- Companion `guacamole-client` repo: <https://github.com/apache/guacamole-client>
- Homepage: <https://guacamole.apache.org>
- Full manual: <https://guacamole.apache.org/doc/gug/>
- Downloads: <https://guacamole.apache.org/releases/>

## Architecture in one minute

- **guacd** (this repo) — C daemon that speaks VNC/RDP/SSH to targets + Guacamole protocol to the web client
- **guacamole-client** (Java / Tomcat or Jetty) — web UI + WebSocket bridge to guacd
- **DB** — typically MySQL or PostgreSQL for users / connections / recording metadata
- **Deployment**: 3 containers (guacd + guac-client + DB) or all-in-one via community images
- **Resource**: moderate — 1-2GB RAM baseline; scales with concurrent sessions
- **Ports**: 8080 (web), 4822 (guacd internal; never exposed)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker (official)  | **`guacamole/guacd` + `guacamole/guacamole` + `mysql`/`postgres`** | **Upstream-supported**; 3-container pattern                                       |
| Docker (all-in-one) | Community: `flcontainers/guacamole`, `oznu/guacamole`, `abesnier/guacamole`         | Single-container for trial; official 3-container for prod                                  |
| Bare-metal         | Build `guacamole-server` from source + Tomcat + MySQL/Postgres                         | Classic path; most flexibility                                                                        |
| Kubernetes         | Community Helm charts                                                                                         | Works                                                                                                            |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `remote.example.com`                                        | URL          | **TLS MANDATORY** — remote-desktop sessions in the clear = disaster                                                                         |
| DB                   | MySQL 8+ or PostgreSQL 13+                                              | DB           | Initialize schema with upstream SQL                                                                                    |
| Guacamole admin      | First admin user created via DB bootstrap                                       | Bootstrap    | **Strong password mandatory + enable MFA**                                                                                    |
| Target systems       | VNC/RDP/SSH endpoints to configure                                                | Config       | Per-connection entries                                                                                                      |
| LDAP/SAML/OIDC (opt) | For SSO                                                                                 | Auth         | Highly recommended over DB-only auth                                                                                                                       |
| Session recording path (opt)                       | Network share or local dir                                                                                                                | Compliance   | For audit retention                                                                                                                                                    |

## Install via Docker Compose (official 3-container)

```yaml
services:
  guacd:
    image: guacamole/guacd:1.6.0           # **pin; check latest stable**
    restart: unless-stopped

  guacamole:
    image: guacamole/guacamole:1.6.0       # **pin same major**
    restart: unless-stopped
    depends_on: [guacd, db]
    environment:
      GUACD_HOSTNAME: guacd
      POSTGRES_HOSTNAME: db
      POSTGRES_DATABASE: guacamole
      POSTGRES_USER: guacamole
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports: ["8080:8080"]

  db:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_DB: guacamole
      POSTGRES_USER: guacamole
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./guac-db:/var/lib/postgresql/data
      - ./initdb.sql:/docker-entrypoint-initdb.d/initdb.sql:ro
```

Generate `initdb.sql` once:
```sh
docker run --rm guacamole/guacamole:1.6.0 /opt/guacamole/bin/initdb.sh --postgresql > initdb.sql
```

Then `docker compose up -d` → browse `http://host:8080/guacamole` → default creds `guacadmin` / `guacadmin` → **change immediately**.

## First boot

1. Start stack → browse `/guacamole`
2. Login as `guacadmin` / `guacadmin` (default — upstream ships with these)
3. **CHANGE PASSWORD + CREATE YOUR ADMIN USER → DELETE DEFAULT `guacadmin`**
4. Configure auth provider (LDAP / SAML / OIDC) + enable MFA
5. Add first connection: target hostname, protocol, creds
6. Test: click connection → remote desktop in browser
7. Configure TLS reverse proxy (Caddy / nginx / Traefik) in front of port 8080
8. Enable session recording if required for compliance
9. Back up DB + recording storage

## Data & config layout

- **DB** — users, connections, connection params (passwords encrypted by guacamole-auth-jdbc), session history, recording metadata
- **Recording storage** — per-session recording files (can be LARGE)
- **`guacamole-client` config** (in Tomcat) — `guacamole.properties`, extensions
- **`guacd`** — stateless daemon

## Backup

```sh
# DB
pg_dump -Fc -U guacamole guacamole > guac-db-$(date +%F).dump
# Recordings (if used)
sudo rsync -av /recordings/ backup:/recordings/$(date +%F)/
# guacamole-client config (extensions, properties)
sudo tar czf guac-config-$(date +%F).tgz /etc/guacamole/
```

## Upgrade

1. Releases: <https://guacamole.apache.org/releases/>. Apache release cadence (quarterly-ish).
2. Bump BOTH `guacd` + `guacamole-client` to SAME version — **they must match**.
3. DB schema migrations between majors — run upstream migration SQL scripts.
4. Back up DB FIRST.
5. Apache releases include security advisories — **monitor apache.org security announcements**.

## Gotchas

- **DEFAULT CREDS `guacadmin` / `guacadmin` ARE PUBLIC KNOWLEDGE.** Every scanner knows them. **Change on first login + delete the default user.** Same class as Black Candy (batch 83) + PMS (86) demo-creds warning. **Third tool in default-credentials-PUBLIC family.**
- **HUB-OF-CREDENTIALS CROWN-JEWEL CLASS-MAX.** Guacamole is arguably **THE archetypal example** of this pattern — the whole point is to aggregate credentials for your RDP / VNC / SSH targets into one login. If Guacamole is compromised, attackers get:
  - Every RDP target's password
  - Every SSH private key + passphrase
  - Every VNC server
  - **And can initiate sessions AS privileged users.**
  - **11th tool in hub-of-credentials family + the most extreme member.**
  - Treat Guacamole as **bastion-host-tier infrastructure**:
    - Dedicated VM / no co-tenancy with other services
    - TLS MANDATORY
    - MFA mandatory for every user
    - Behind VPN / Zero-Trust-Network-Access if possible
    - Monitored intensively (who logged in, when, from where)
    - Session recording enabled for audit
    - Regular password rotation + key rotation on target systems
- **`GUACAMOLE_HOME` + secret-provider considerations**: connection passwords stored in DB are encrypted by the JDBC auth extension's private key (`guacamole-auth-jdbc` private key). If that key is weak / default / leaked, DB-stolen passwords can be decrypted.
- **guacd + guacamole-client VERSION MATCH MANDATORY**. Upgrading one without the other = broken. Protocol compat between majors.
- **Session recording SIZE**: full video capture of remote desktop sessions = GB per hour of high-res desktop work. Plan retention + storage. Recordings contain EVERYTHING the user saw + typed = **crown-jewel secondary**.
- **Session recording PRIVACY / LEGAL**: recording user sessions raises **labor-law + privacy concerns** in many jurisdictions (same class as Nexterm batch 81). Inform users in writing + legal-counsel-reviewed policy required in EU / parts of US / Canada / etc.
- **RDP + Network Level Authentication (NLA)**: RDP targets with NLA can be tricky to configure from Guacamole. Check docs for `enable-wallpaper`, `security`, + related params.
- **Clipboard + file transfer = data-exfiltration vectors**: a compromised user with Guacamole access can use clipboard / SFTP to move data out of restricted targets. Configure connection-level permissions to disable clipboard/file-transfer where appropriate.
- **Latency** matters for remote desktop. Same reality as Webtop (batch 83) + pad-ws (85). Users across high-latency links will curse you. Deploy Guacamole geographically close to users + targets.
- **Keyboard layouts across languages** are a historic Guacamole pain. Check upstream docs if your users are non-US-English.
- **Browser compatibility**: Chrome/Firefox/Edge work well; Safari has periodic quirks; mobile browsers work but small-screen RDP is ugly.
- **Scaling**: single guacd handles many concurrent sessions but RDP/VNC per-session RAM + CPU add up. For large teams (100+ concurrent), multiple guacd workers + load balancer.
- **Apache governance quality**: ASF = industrial-grade process + security-response + release management. **Institutional-stewardship signal** (same family: NLnet Labs for Unbound batch 80, Deciso for OPNsense 80, TryGhost for Ghost / Fider 82, Linux Foundation for Valkey, Codeberg e.V. for Forgejo 82, LinuxServer.io across batches, Element for Synapse 84). **8th member of institutional-stewardship family + one of the strongest.**
- **Permissive license (Apache-2.0)** = great for commercial embedding + integration + redistribution. Rare-quality signal in modern OSS. Same "permissive-ecosystem-asset" framing as IronCalc (86), Caddy, Rustpad.
- **Zero-Trust Network Access (ZTNA) alternatives**: Guacamole is a pre-ZTNA-era tool but still relevant. Modern alternatives include Cloudflare Access, Tailscale, Teleport, StrongDM. For teams going full-ZTNA, Guacamole may be less relevant; for hybrid / legacy-RDP access, Guacamole still shines.
- **Project health**: Apache TLP + active + commercial-ecosystem (Keeper Security, Kasm Workspaces build on Guacamole) + stable API. Bus-factor-ASF = effectively zero.
- **Alternatives worth knowing:**
  - **Teleport** — modern ZTNA jump-host (OSS + commercial)
  - **Bastillion** (formerly KeyBox) — OSS SSH/SSM jump-host
  - **Warpgate** — modern bastion for SSH + HTTPS + MySQL (Rust)
  - **Nexterm** (batch 81) — lighter-weight RDP/SSH browser access
  - **Apache NiFi + Cloudberry + commercial** — not competitors but overlap in some ops workflows
  - **Cloudflare Access / Tailscale / Pomerium** — ZTNA-style
  - **Kasm Workspaces** — commercial containerized desktop (built on Guacamole)
  - **Choose Guacamole if:** you want mature + ASF + multi-protocol + compliance-grade + widely-deployed.
  - **Choose Teleport if:** you want modern ZTNA + SSH-focus + OSS-plus-commercial tiers.
  - **Choose Nexterm if:** you want lighter footprint + modern UI + homelab-scale.
  - **Choose Tailscale / Cloudflare Access if:** you're going full Zero-Trust instead of bastion.

## Links

- `guacamole-server` repo: <https://github.com/apache/guacamole-server>
- `guacamole-client` repo: <https://github.com/apache/guacamole-client>
- Homepage: <https://guacamole.apache.org>
- Full manual: <https://guacamole.apache.org/doc/gug/>
- Downloads: <https://guacamole.apache.org/releases/>
- Docker images: <https://hub.docker.com/u/guacamole>
- Security advisories: <https://guacamole.apache.org/security/>
- Teleport (alt, ZTNA): <https://goteleport.com>
- Warpgate (alt, Rust bastion): <https://github.com/warp-tech/warpgate>
- Nexterm (alt, homelab): <https://github.com/gnmyt/Nexterm>
- Kasm Workspaces (commercial built on Guacamole): <https://www.kasmweb.com>
