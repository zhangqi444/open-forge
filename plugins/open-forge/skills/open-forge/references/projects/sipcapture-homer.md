---
name: sipcapture-homer
description: SIPCAPTURE HOMER recipe for open-forge. Covers Docker Compose install (HOMER 7 — the current release). HOMER is an open-source VoIP capture, troubleshooting, and monitoring platform that ingests SIP/HEP traffic from Kamailio, OpenSIPS, Asterisk, FreeSWITCH, and other agents.
---

# SIPCAPTURE HOMER

Open-source VoIP capture, troubleshooting, and monitoring system. Receives SIP signaling, RTCP stats, logs, and custom metrics via HEP (Homer Encapsulation Protocol) from capture agents (Kamailio, OpenSIPS, Asterisk, FreeSWITCH, captagent). Provides a web UI for call search, ladder diagrams, QoS analysis, and correlation. Upstream: <https://github.com/sipcapture/homer>. Website: <https://www.sipcapture.org>.

**License:** AGPL-3.0 · **Language:** Go (API) + Node.js (UI) · **Default port:** 9080 (web), 9060 (HEP) · **Stars:** ~1,900

> **Version note:** HOMER 7 (current release, Go-based API + PostgreSQL/InfluxDB/Elasticsearch) is the active branch. HOMER 5 (older, Kamailio-based) is legacy. This recipe covers HOMER 7.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/sipcapture/homer-docker> | ✅ | **Recommended** — official Docker bundle with homer-app, homer-ui, and databases. |
| Binary / package | <https://github.com/sipcapture/homer-app/releases> | ✅ | Bare-metal installs or custom database configurations. |
| Homer-in-a-box | <https://github.com/sipcapture/homer/wiki/Quick-Install> | ✅ | All-in-one shell installer for quick POC. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method — Docker Compose (recommended) or bare-metal binary?" | AskUserQuestion | Determines section. |
| domain | "What IP/hostname will the HOMER web UI be accessible at?" | Free-text | All methods. |
| hep_port | "HEP capture port (default: 9060/UDP+TCP)?" | Free-text | All methods — set on capture agents too. |
| db | "Database backend: PostgreSQL (default), InfluxDB, or both?" | AskUserQuestion | Affects homer-app config. |
| capture_agents | "Which VoIP platforms send HEP to HOMER? (Kamailio / OpenSIPS / Asterisk / FreeSWITCH / captagent)" | Free-text | Determines capture agent config. |

## Install — Docker Compose (recommended)

Reference: <https://github.com/sipcapture/homer-docker>

```bash
git clone https://github.com/sipcapture/homer-docker.git
cd homer-docker

# Start the full stack (homer-app + homer-ui + PostgreSQL + provisioning)
docker compose up -d
```

Default services started:
- **homer-app** — REST API + HEP listener (port 9060 UDP/TCP, port 9080 HTTP)
- **homer-ui** — Web interface (served via homer-app on port 9080)
- **PostgreSQL** — Call/signaling data storage
- **homer-init** — One-time database provisioning container

Web UI: `http://<host>:9080` — default credentials: `admin` / `sipcapture`

**Change the default password immediately after first login.**

### Custom configuration

```bash
# Copy and customize homer-app config
cp homer-app/docker/homer-app.json homer-app-custom.json
```

Key settings in `homer-app.json`:

```json
{
  "database_data": {
    "node": [{
      "help": "PostgreSQL for SIP data",
      "name": "LocalDB",
      "type": "postgres",
      "keepalive": true,
      "node": "local",
      "user": "root",
      "password": "homerS七",
      "host": "postgres",
      "port": 5432,
      "database": "homer_data"
    }]
  },
  "hep_server": {
    "udp": "0.0.0.0:9060",
    "tcp": "0.0.0.0:9060"
  },
  "http_settings": {
    "host": "0.0.0.0",
    "port": 9080
  }
}
```

## Install — Binary (bare-metal)

```bash
# Download latest homer-app binary from releases
curl -LO https://github.com/sipcapture/homer-app/releases/latest/download/homer-app-linux-amd64
chmod +x homer-app-linux-amd64
sudo mv homer-app-linux-amd64 /usr/local/bin/homer-app

# Download example config
curl -LO https://raw.githubusercontent.com/sipcapture/homer-app/master/example/homer-app.json

# Edit homer-app.json with your database credentials
nano homer-app.json

# Run
homer-app -config=homer-app.json
```

## Configuring capture agents

### Kamailio

Add to `kamailio.cfg`:

```cfg
loadmodule "sipcapture.so"
modparam("sipcapture", "capture_node", "homer01")
modparam("sipcapture", "hep_capture_id", 1)

# HEP3 to HOMER
sip_trace_mode("t");
setflag(FLT_CAPTURE);
```

Or use the `hep.lua` script — see <https://github.com/sipcapture/homer/wiki/Examples:-Kamailio>.

### Asterisk

In `hep.conf`:

```ini
[general]
enabled = yes
capture_address = <homer-host>:9060
uuid_type = call-id
```

### FreeSWITCH / OpenSIPS

See wiki for per-platform config: <https://github.com/sipcapture/homer/wiki>

### captagent (for non-HEP-native platforms)

```bash
# captagent is a general-purpose capture agent
# https://github.com/sipcapture/captagent
captagent -f captagent.xml  # config points HEP output to HOMER
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| HEP port | UDP 9060 must be reachable from all capture agents. Open in firewall. TCP 9060 also available for reliable transport. |
| PostgreSQL | Default data store. Tables: `hep_proto_1_default` (SIP), `hep_proto_5_default` (RTCP), `hep_proto_100_default` (logs). |
| InfluxDB | Optional time-series backend for QoS/RTCP metrics — configure alongside PostgreSQL. |
| Elasticsearch | Optional search backend for large-scale deployments (millions of calls/day). |
| Retention | Set up PostgreSQL table partitioning or scheduled cleanup for `hep_proto_*` tables. High-volume SIP can generate GBs/day. |
| TLS | HOMER web UI has no built-in TLS. Put behind nginx/Caddy with TLS for production. |
| HEP encryption | Supports HEP3 encrypted transport — configure shared secret in homer-app and on capture agents. |
| Auth | JWT-based auth for the REST API. Default user: admin/sipcapture. Add users via web UI. |

## Upgrade procedure

```bash
cd homer-docker
docker compose pull
docker compose up -d
```

For bare-metal:

```bash
curl -LO https://github.com/sipcapture/homer-app/releases/latest/download/homer-app-linux-amd64
sudo mv homer-app-linux-amd64 /usr/local/bin/homer-app
sudo systemctl restart homer-app
```

Database schema upgrades are applied automatically by homer-app on startup.

## Gotchas

- **Default password — change it:** The Docker Compose stack starts with `admin`/`sipcapture`. Change it in the web UI immediately — HOMER port 9080 is often exposed directly.
- **UDP 9060 firewall:** HEP capture is UDP. If capture agents can't reach port 9060, calls are silently lost (no error on the SIP side). Verify connectivity with `nc -u <homer-host> 9060`.
- **Retention must be managed:** HOMER does not auto-expire old call data by default. PostgreSQL tables grow unboundedly. Set up table partitioning and a cron job to DROP old partitions, or disk fills up.
- **HOMER 7 vs HOMER 5:** Many tutorials and forum posts still describe HOMER 5 (Kamailio-based, PHP frontend). HOMER 7 is a complete rewrite with a Go API and is the current release. The two are not compatible.
- **Clock sync:** HEP timestamps are critical for call reconstruction. All capture agents and the HOMER server must be NTP-synchronized. Drifted clocks cause call ladders to appear scrambled.
- **captagent for non-native platforms:** Platforms without native HEP support (legacy switches, SBCs) need [captagent](https://github.com/sipcapture/captagent) as a sidecar capture agent.

## Upstream links

- GitHub (HOMER): <https://github.com/sipcapture/homer>
- GitHub (homer-app API): <https://github.com/sipcapture/homer-app>
- GitHub (homer-docker): <https://github.com/sipcapture/homer-docker>
- Wiki / quick install: <https://github.com/sipcapture/homer/wiki/Quick-Install>
- Capture agent examples: <https://github.com/sipcapture/homer/wiki>
- Website: <https://www.sipcapture.org>
