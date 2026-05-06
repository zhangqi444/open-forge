# OpenSIPS

OpenSIPS is a GPL-licensed SIP (Session Initiation Protocol) proxy/server for voice, video, instant messaging, presence, and any SIP-based communication. It started as a fork of SER (SIP Express Router) with a focus on extensibility, modularity, and open development.

**Website:** https://opensips.org/
**Source:** https://github.com/OpenSIPS/opensips
**License:** GPL-2.0
**Stars:** ~1,464

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (Debian/Ubuntu/CentOS) | Native binary + apt/yum packages | Recommended |
| Any Linux | Build from source (C) | Full control |
| Docker | Community/custom image | No official Docker image |
| VPS/Bare metal | Native | Low-latency preferred for SIP |

---

## Inputs to Collect

### Phase 1 — Planning
- SIP domain (e.g. `sip.example.com`)
- Listen IP / interface
- SIP ports: UDP 5060 (standard), TCP 5060, TLS 5061
- Database backend (MySQL, PostgreSQL, or others for persistence)
- Features: registration, call routing, load balancing, media relay (RTP proxy)

### Phase 2 — Deployment
- `listen` directive (IP + port + transport)
- Database connection string
- `domain` / `alias` configuration
- TLS certificate (if using TLS transport)
- RTPproxy or rtpengine address (for media relay)

---

## Software-Layer Concerns

### Installation from Official Packages (Debian/Ubuntu)
```bash
# Add OpenSIPS repository
curl -sSfL https://apt.opensips.org/opensips-org.gpg | sudo tee /etc/apt/trusted.gpg.d/opensips-org.gpg > /dev/null
echo "deb https://apt.opensips.org $(lsb_release -cs) 3.5-releases" | sudo tee /etc/apt/sources.list.d/opensips.list

sudo apt update
sudo apt install -y opensips opensips-mysql-module opensips-presence-modules
```

### Key Ports
| Port | Transport | Purpose |
|------|-----------|---------|
| 5060 | UDP | Standard SIP signaling |
| 5060 | TCP | SIP over TCP |
| 5061 | TCP/TLS | SIP over TLS (SIPS) |
| 8888 | TCP | OpenSIPS MI (management interface), optional |

### Main Config (`/etc/opensips/opensips.cfg`)
OpenSIPS uses a custom scripting language for routing logic:
```
# Basic listener config
listen = udp:0.0.0.0:5060
listen = tcp:0.0.0.0:5060
listen = tls:0.0.0.0:5061

# Core modules
loadmodule "signaling.so"
loadmodule "sl.so"
loadmodule "tm.so"
loadmodule "rr.so"
loadmodule "maxfwd.so"
loadmodule "usrloc.so"
loadmodule "registrar.so"
loadmodule "uri.so"

# Database (example: MySQL)
loadmodule "db_mysql.so"
modparam("usrloc", "db_url", "mysql://opensips:pass@localhost/opensips")

# SIP routing script
route {
    if (!mf_process_maxfwd_header(10)) {
        sl_send_reply("483","Too Many Hops");
        exit;
    }
    if (is_method("REGISTER")) {
        save("location");
        exit;
    }
    # ... routing logic ...
}
```

### Database Setup
```bash
# Create DB and apply schema
mysql -u root -p -e "CREATE DATABASE opensips;"
mysql -u root -p -e "GRANT ALL ON opensips.* TO 'opensips'@'localhost' IDENTIFIED BY 'pass';"
opensipsdbctl create
```

### OpenSIPS Control Tool
```bash
# Manage users, domains, etc.
opensipsctl add user@example.com password
opensipsctl show users
opensipsctl domain add example.com
```

### Management Interface (MI)
```bash
# Query running instance via HTTP (if mi_http module loaded)
curl http://localhost:8888/mi/which

# Or use opensipsmi CLI tool
opensipsmi which
opensipsmi ul show
```

### Firewall Rules
```bash
ufw allow 5060/udp   # SIP
ufw allow 5060/tcp
ufw allow 5061/tcp   # SIPS (TLS)
# RTP media ports (if using media relay)
ufw allow 10000:20000/udp
```

---

## Upgrade Procedure

```bash
# Backup config
cp /etc/opensips/opensips.cfg ~/opensips.cfg.bak

# Update packages
sudo apt update && sudo apt upgrade opensips

# Restart
sudo systemctl restart opensips

# Check logs
journalctl -u opensips -f
```

---

## Gotchas

- **Complex scripting language**: OpenSIPS routing logic is a custom C-like scripting language with its own syntax. Expect a learning curve.
- **No official Docker image**: Docker deployment requires building a custom image or using community images; not straightforward.
- **NAT traversal**: SIP + NAT is notoriously complex. Use `nathelper` module and an RTPproxy/rtpengine for media relay in NAT scenarios.
- **UDP preferred for SIP**: SIP traditionally runs over UDP; TCP/TLS adds reliability but introduces more complexity.
- **RTP proxy separate**: OpenSIPS handles SIP signaling only; media (RTP audio/video) flows separately and requires an RTPproxy or rtpengine instance for relay.
- **Database required for registration persistence**: Without a database module, user registrations are in-memory only and lost on restart.
- **Module loading order matters**: Dependencies between modules must be loaded in the correct order in the config file.

---

## Links
- Docs: https://opensips.org/Resources/Documentation
- Tutorials: https://opensips.org/Resources/DocsTutorials
- Module Reference: https://www.opensips.org/Documentation/Modules
- GitHub Releases: https://github.com/OpenSIPS/opensips/releases
- Mailing Lists: https://lists.opensips.org/
