---
name: Eclipse Mosquitto
description: The canonical open-source MQTT 5.0 / 3.1.1 / 3.1 broker. Tiny, mature, universal — used as the backbone of most self-hosted IoT + Home Assistant + Zigbee2MQTT + ESPHome + industrial stacks. C. EPL/EDL (Eclipse dual-license).
---

# Eclipse Mosquitto

Mosquitto is **the** open-source MQTT broker. If you've built anything IoT in the last decade, you've probably used it. It's tiny (a few MB of RAM), robust, and implements MQTT 5.0, 3.1.1, and 3.1. Home Assistant's MQTT integration, Zigbee2MQTT, ESPHome, Node-RED, InfluxDB's Telegraf, dozens of industrial gateways — they all assume Mosquitto (or a compatible broker) at the center.

Ships with:

- The broker (`mosquitto`)
- Client utilities:
  - `mosquitto_pub` — publish messages
  - `mosquitto_sub` — subscribe to topics
  - `mosquitto_rr` — request-response (MQTT 5)
  - `mosquitto_passwd` — manage password files
  - `mosquitto_ctrl` — administer brokers (MQTT 5 dynamic security)
- Dynamic security plugin for role/ACL management

Common use cases:

- **Home Assistant** — auto-discovery of sensors, lights, sensors via MQTT
- **Zigbee2MQTT** — Zigbee radio ↔ MQTT bridge
- **ESPHome (MQTT mode)** — as alternative to the HA-native API
- **Industrial IoT** — SCADA, Modbus bridges, PLC telemetry
- **Data pipelines** — Telegraf → InfluxDB, sensors → Kafka, etc.
- **Mobile push** — lightweight pub/sub to apps

- Upstream repo: <https://github.com/eclipse-mosquitto/mosquitto>
- Website: <https://mosquitto.org>
- Docs / man pages: <https://mosquitto.org/man/>
- Downloads (binaries for every platform): <https://mosquitto.org/download/>
- Docker Hub: <https://hub.docker.com/_/eclipse-mosquitto>
- Public test broker (for dev): <https://test.mosquitto.org/>

## Architecture in one minute

- **Single C binary** (`mosquitto`) — the broker
- Reads a config file (`mosquitto.conf`) — listeners, auth, ACL, persistence, bridges
- **Ports**:
  - **`1883`** — plain MQTT (default)
  - **`8883`** — MQTT over TLS (default convention)
  - **`9001`** (often) — MQTT over WebSockets (for browser clients)
- **Persistence** — writes retained messages + subscriptions to disk (optional)
- **Bridges** — connect to other MQTT brokers for federation
- Resource-wise: **minimal** — runs happily on a Raspberry Pi Zero, a home router, embedded devices

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                                     |
| ----------- | --------------------------------------------------- | ------------------------------------------------------------------------- |
| Single VM   | Docker (`eclipse-mosquitto`)                          | **Most common for self-hosters**                                            |
| Single VM   | `apt install mosquitto` / `brew install mosquitto`    | Debian/Ubuntu/Arch/Fedora/macOS native packages                               |
| Windows     | Official installer                                     | <https://mosquitto.org/download/>                                             |
| Kubernetes  | Community charts                                        | Stateless-ish with PV for persistence                                           |
| Home Assistant | Mosquitto add-on (one-click)                         | **THE way** for HA users                                                       |
| OpenWrt     | `opkg install mosquitto`                                | For home routers running IoT                                                    |

## Inputs to collect

| Input              | Example                             | Phase     | Notes                                                          |
| ------------------ | ----------------------------------- | --------- | -------------------------------------------------------------- |
| Port (MQTT)        | `1883`                               | Network   | Plain MQTT                                                       |
| Port (MQTTS)       | `8883`                               | Network   | MQTT over TLS                                                    |
| Port (WS)          | `9001`                               | Network   | MQTT over WebSockets; optional                                    |
| `mosquitto.conf`   | config file                          | Config    | See below                                                        |
| Username + password | for authenticated access             | Security  | Use `mosquitto_passwd` to create                                    |
| ACL file           | topic permissions                    | Security  | For multi-user setups                                              |
| TLS cert + key     | Let's Encrypt or self-signed         | Security  | For 8883                                                           |
| Persistence dir    | `/mosquitto/data`                    | Storage   | Retained messages, durable subscriptions                             |

## Install via Docker (simplest, with password)

```sh
mkdir -p /opt/mosquitto/{config,data,log}

# Create config
cat > /opt/mosquitto/config/mosquitto.conf << 'CONF'
listener 1883
listener 9001
protocol websockets

persistence true
persistence_location /mosquitto/data/

log_dest file /mosquitto/log/mosquitto.log

# Require auth (next section creates password file)
allow_anonymous false
password_file /mosquitto/config/passwords
CONF

# Set password
docker run --rm -it \
  -v /opt/mosquitto/config:/mosquitto/config \
  eclipse-mosquitto:2 \
  mosquitto_passwd -c /mosquitto/config/passwords admin
# Enter password when prompted

# Run broker
docker run -d --name mosquitto \
  --restart unless-stopped \
  -p 1883:1883 -p 9001:9001 \
  -v /opt/mosquitto/config:/mosquitto/config \
  -v /opt/mosquitto/data:/mosquitto/data \
  -v /opt/mosquitto/log:/mosquitto/log \
  eclipse-mosquitto:2.0   # pin to minor series; latest is 2.8.x
```

## Install via Docker Compose

```yaml
services:
  mosquitto:
    image: eclipse-mosquitto:2.0
    container_name: mosquitto
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "8883:8883"      # TLS
      - "9001:9001"      # WebSockets
    volumes:
      - ./config:/mosquitto/config
      - ./data:/mosquitto/data
      - ./log:/mosquitto/log
```

## Test the broker

From another terminal:

```sh
# Subscribe
mosquitto_sub -h localhost -p 1883 -u admin -P <pw> -t 'test/#' -v

# In another terminal: publish
mosquitto_pub -h localhost -p 1883 -u admin -P <pw> -t 'test/topic' -m 'hello'
```

`mosquitto_sub` should print `test/topic hello`.

## Minimal `mosquitto.conf` (TLS + auth)

```
# Listen on 1883 (plain), 8883 (TLS), 9001 (WS)
listener 1883
listener 8883
cafile /mosquitto/config/ca.crt
certfile /mosquitto/config/server.crt
keyfile /mosquitto/config/server.key
require_certificate false     # set true for mTLS

listener 9001
protocol websockets

# Authentication
allow_anonymous false
password_file /mosquitto/config/passwords

# ACL (per-user topic permissions)
acl_file /mosquitto/config/acl

# Persistence
persistence true
persistence_location /mosquitto/data/

# Logs
log_dest file /mosquitto/log/mosquitto.log
log_type error warning notice information
```

## ACL file example

```
# Admin gets everything
user admin
topic readwrite #

# Alice only her own devices
user alice
topic readwrite alice/#

# Dashboard reads everything, writes nothing
user dashboard
topic read #
```

## Data & config layout

Inside `/mosquitto/` (container paths):

- `config/mosquitto.conf` — main config
- `config/passwords` — user/hash file (from `mosquitto_passwd`)
- `config/acl` — ACL rules
- `config/ca.crt`, `server.crt`, `server.key` — TLS material
- `data/mosquitto.db` — retained messages + durable subscription state
- `log/mosquitto.log`

## Backup

```sh
tar czf mosquitto-$(date +%F).tgz -C /opt/mosquitto .
```

Mosquitto's `mosquitto.db` is self-consistent snapshots; safe to copy while running (small chance of missing last few seconds). For strict consistency, stop broker briefly.

## Upgrade

1. Releases: <https://github.com/eclipse-mosquitto/mosquitto/releases>. Infrequent.
2. `docker pull eclipse-mosquitto:2` / restart container.
3. **2.x is backward-compatible with 1.x configs** in most cases — check release notes for breaking changes between minor versions.
4. Config format is stable across minor versions.
5. The Docker image follows `eclipse-mosquitto:<major>.<minor>.<patch>` — pin at least the major (`:2`) or ideally minor.

## Gotchas

- **Default config allows anonymous access on localhost only** in Docker image 2.0+. For network exposure, you MUST set `allow_anonymous false` + configure `password_file`. Failing to do this = public open broker = someone will find it + use it for IoT botnets.
- **Old 1.x configs had `allow_anonymous true` as default**. Upgrading from 1.x to 2.x is a breaking change for configs that didn't set this explicitly.
- **Port 1883 is cleartext** — any intermediate proxy sees credentials + messages. Use 8883 (TLS) for anything off your LAN.
- **WebSockets (9001)** need protocol forwarding on nginx/haproxy — they're MQTT wrapped in WS, not HTTP. Use `mqtt-packet` libraries on the client side (e.g., MQTT.js for browsers).
- **`mosquitto_passwd`** hashes passwords with PBKDF2 by default (OK); older brokers used weaker hashes.
- **ACL file reload** requires `SIGHUP` or broker restart; changes not picked up automatically.
- **Persistence** — by default, disabled in many install paths. Enable it via `persistence true` + `persistence_location /path/`. Without it, retained messages + durable subscriptions are lost on restart.
- **Retained messages** (`publish -r`) stay around forever on a topic until explicitly cleared — useful for HA auto-discovery; be aware of long-term state buildup.
- **QoS levels**: 0 = fire-and-forget; 1 = at-least-once; 2 = exactly-once. Most IoT uses QoS 0. Durable subscriptions + QoS ≥1 need persistence.
- **Max connected clients**: Mosquitto handles 100k+ on modest hardware. Default is unlimited.
- **Bridging** to other brokers: configure in main conf; useful for multi-site or failover setups.
- **Dynamic security plugin** (MQTT 5+) replaces static password/ACL files with a broker-managed database — more flexible, requires `mosquitto_ctrl`.
- **Home Assistant's MQTT integration assumes retained messages** for auto-discovery. Zigbee2MQTT publishes discovery messages with `retain: true`; if you clear retained state, HA entities disappear.
- **TLS certificate renewal**: Let's Encrypt + a reload sidecar is the standard pattern. Mosquitto doesn't auto-reload certs; requires `SIGHUP`.
- **Client ID uniqueness**: if two clients connect with the same ID, the second kicks the first out. Use unique IDs per device.
- **Eclipse dual-license** (EPL v2.0 / EDL v1.0) — permissive; free commercial use; contributions under the same license.
- **Test broker**: <https://test.mosquitto.org/> — convenient for dev; NEVER use for prod data.
- **IANA-assigned MQTT ports**: 1883 (plain), 8883 (TLS). Firewall-friendly to stick with these.
- **Alternatives worth knowing:**
  - **EMQX** — high-scale MQTT broker (Erlang); clustering, millions of connections
  - **HiveMQ** — commercial MQTT platform; free CE with limitations
  - **VerneMQ** — Erlang broker, HA clustering, permissive license
  - **RabbitMQ + MQTT plugin** — if you're already on RabbitMQ
  - **NanoMQ** — C, lightweight, good for edge
  - **Flashmq** — modern C++ broker
  - **Aedes** / **Moquette** / **nanomq** — Node.js / Java / small C alternatives
  - **Mosquitto is right for 99% of self-hosted and small-to-medium installs**. Reach for EMQX/VerneMQ at scale >100k concurrent clients or for clustering.

## Links

- Repo: <https://github.com/eclipse-mosquitto/mosquitto>
- Website: <https://mosquitto.org>
- Download / binaries: <https://mosquitto.org/download/>
- Man pages: <https://mosquitto.org/man/>
- Authentication methods: <https://mosquitto.org/documentation/authentication-methods/>
- Dynamic security plugin: <https://mosquitto.org/documentation/dynamic-security/>
- Docker Hub: <https://hub.docker.com/_/eclipse-mosquitto>
- Releases: <https://github.com/eclipse-mosquitto/mosquitto/releases>
- MQTT v3.1.1 spec: <https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html>
- MQTT v5.0 spec: <https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html>
- MQTT community: <http://mqtt.org/>
- Public test broker: <https://test.mosquitto.org/>
