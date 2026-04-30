---
name: VerneMQ
description: "High-performance distributed MQTT message broker — Erlang/OTP. MQTT 3.1/3.1.1/5.0, scales horizontally + vertically, fault-tolerant. For IoT platforms + smart products. Apache-2.0. Commercial enterprise features + support via VerneMQ GmbH."
---

# VerneMQ

VerneMQ is **"the Erlang-OTP distributed MQTT broker — telecom-grade reliability for IoT platforms"** — a high-performance, horizontally + vertically scalable, fault-tolerant MQTT 3.1 / 3.1.1 / 5.0 message broker. Built on Erlang/OTP (the runtime that powers telecom switches + WhatsApp). Scales to millions of concurrent MQTT connections on a single cluster. Used in production across 50+ countries for IoT platforms, smart products, M2M messaging, industrial SCADA, smart city networks.

Built + maintained by **VerneMQ GmbH** (Germany) + community. **Apache-2.0**. Commercial tier: **VerneMQ Enterprise + paid support contracts** for production-critical deployments. Long-running project (since ~2015).

Use cases: (a) **IoT platform backbone** — millions of devices publish telemetry / subscribe to commands (b) **smart-home hub** for commercial/residential (c) **M2M industrial messaging** — SCADA, building automation (d) **mobile-app push-style messaging** via MQTT (e) **smart-city sensor networks** — low-bandwidth + high-device-count workloads (f) **replacement for commercial MQTT services** (HiveMQ Cloud, AWS IoT Core) at scale (g) **Matter / Home Assistant MQTT backend** (for advanced homelabbers).

Features:

- **MQTT 3.1 / 3.1.1 / 5.0** — full spec coverage
- **QoS 0, 1, 2** — all quality-of-service levels
- **Clustering** — distributed, masterless; nodes join/leave dynamically
- **High availability** — horizontal scale-out; no SPOF
- **Bridge support** — MQTT-to-MQTT bridging between brokers
- **$SYS tree** for monitoring + reporting
- **Pluggable authentication** — files, MySQL, PostgreSQL, MongoDB, Redis, LDAP, webhook
- **Shared subscriptions** (MQTT 5)
- **Retained messages**
- **Will messages**
- **TLS / mTLS** — client certificate authentication
- **WebSocket support** (MQTT-over-WebSocket)
- **HTTP API** for monitoring + management
- **Prometheus / Graphite metrics export**
- **Plugins** — extensible via Erlang or external (HTTP webhook) plugins
- **Commercial enterprise features**: advanced clustering, LDAP, monitoring integrations (VerneMQ GmbH)

- Upstream repo: <https://github.com/vernemq/vernemq>
- Homepage: <https://vernemq.com>
- Docs: <https://docs.vernemq.com>
- Docker Hub: <https://hub.docker.com/r/vernemq/vernemq>
- Docs: <https://docs.vernemq.com>
- Forum: <https://erlangforums.com/c/erlang-platforms/vernemq-forum/82>
- Google Group: <https://groups.google.com/forum/#!forum/vernemq-users>
- Mastodon: <https://fosstodon.org/@VerneMQ>

## Architecture in one minute

- **Erlang/OTP** — the runtime (same as WhatsApp, RabbitMQ, CouchDB)
- **Distributed, masterless** — nodes coordinate via gossip + Mnesia
- **Stateless MQTT gateway** design per-node; state replicated across cluster
- **Resource**: efficient — handles millions of connections on modest hardware; memory per connection scales predictably
- **Ports**: 1883 (MQTT), 8883 (MQTTS), 8080 (WebSocket), 8443 (WSS), 8888 (HTTP API)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`vernemq/vernemq:latest`**                                   | **Primary self-host path**                                                         |
| .deb / .rpm        | Binary packages for Debian/Ubuntu/RHEL                                    | Traditional install                                                                                   |
| Kubernetes         | Helm charts + StatefulSet pattern                                                               | For production clusters                                                                                                 |
| Source build       | Erlang toolchain + `make rel`                                                                                 | For dev / custom builds                                                                                                             |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain(s)            | `mqtt.example.com`                                          | DNS          | TLS MANDATORY for non-local                                                                                    |
| `VERNEMQ_ACCEPT_EULA`| `yes` (required Docker env for start)                                | Bootstrap    | **Note: Apache-2 code, but Docker image has an "EULA accept" — actually a nudge to read license; Apache-2 still applies**                                                                                    |
| Cluster cookie       | Shared Erlang cookie for cluster nodes                                                       | **CRITICAL** | **IMMUTABLE for running cluster**                                                                                    |
| TLS certs            | Server cert + CA for mTLS                                                                                          | Security     | Let's Encrypt works via ACME + webroot                                                                                                  |
| Auth backend         | Files (simple), DB (MySQL/PG/Mongo/Redis), LDAP, webhook                                                                                    | Auth         | Scale-appropriate choice                                                                                                                              |
| Cluster peers        | Other VerneMQ node hostnames                                                                                                      | Clustering   | For multi-node production                                                                                                                                      |

## Install via Docker (single-node for dev)

```yaml
services:
  vernemq:
    image: vernemq/vernemq:latest   # **pin to a specific version in prod**
    restart: unless-stopped
    environment:
      - DOCKER_VERNEMQ_ACCEPT_EULA=yes
      - DOCKER_VERNEMQ_ALLOW_ANONYMOUS=off         # **critical**
      - DOCKER_VERNEMQ_USER_admin=${MQTT_ADMIN_PASSWORD}
    volumes:
      - ./vernemq-config:/vernemq/etc
      - ./vernemq-data:/vernemq/data
    ports:
      - "1883:1883"
      - "8883:8883"
      - "8080:8080"
```

For clusters: deploy 3+ nodes with shared Erlang cookie; use `VERNEMQ_DISCOVERY_NODE` per upstream docs.

## First boot

1. Start → check logs for "VerneMQ started"
2. Test MQTT connect: `mosquitto_pub -h host -u admin -P ${PASSWORD} -t test/topic -m hello -p 1883`
3. Subscribe: `mosquitto_sub -h host -u admin -P ${PASSWORD} -t test/topic -p 1883`
4. Configure TLS certs + switch clients to port 8883
5. Set up proper auth backend (not just admin file creds) — Postgres/Redis/LDAP/webhook
6. Configure authorization ACLs — who can publish/subscribe to what topics
7. For cluster: deploy additional nodes + join cluster
8. Enable Prometheus metrics → Grafana dashboards
9. Back up config + auth DB

## Data & config layout

- `/vernemq/etc/vernemq.conf` — main config
- `/vernemq/etc/vmq.passwd` — file-based auth if enabled
- `/vernemq/data/` — Mnesia DB (cluster state, retained messages, sessions)
- `/vernemq/log/` — structured logs
- Erlang VM cookie — `.erlang.cookie` — cluster-wide shared secret

## Backup

- **Mnesia data dir** — cluster state + retained messages
- **Config file** — auth backend config, listener config
- **Cluster cookie** — critical for restore into same cluster
- **Client-side state** (QoS 1/2 sessions): MQTT is pub-sub; persistent sessions matter for some clients — back up to include them

## Upgrade

1. Releases: <https://github.com/vernemq/vernemq/releases>. Regular cadence.
2. **Rolling upgrade across cluster** — restart one node at a time.
3. **Version compatibility across cluster nodes**: Erlang/OTP cluster tolerates mixed minor versions; major upgrades require coordination.
4. **Back up Mnesia data BEFORE major upgrades**.
5. Read release notes — MQTT protocol compliance changes occasionally require config adjustments.

## Gotchas

- **MQTT AUTH = YOUR ENTIRE IoT PLATFORM SECURITY**: MQTT default-open is catastrophic for IoT.
  - **`DOCKER_VERNEMQ_ALLOW_ANONYMOUS=off` MANDATORY** for any non-local deployment. Default in many configs is ON.
  - **Every device needs credentials** — either per-device client certs (mTLS) OR username+password
  - **ACL rules** — limit each device to topics it should publish/subscribe to; default-deny ACLs
  - **Same class of "default-open-is-disaster"** as Redis, Elasticsearch, MongoDB pre-2018. **5th tool in default-creds/default-auth-risk family** (joining Black Candy 83, PMS 86, Guacamole 87, pyLoad 88).
- **CLUSTER COOKIE IMMUTABILITY** (Erlang-standard): the `.erlang.cookie` secret gates cluster membership. Change it = split the cluster. **20th tool in immutability-of-secrets family.** Same discipline as Garage RPC secret (batch 90).
- **TLS / mTLS FOR IoT DEVICES**: publicly-routable MQTT brokers must use TLS. IoT devices often have constrained TLS support (some can't do TLS 1.3); verify device capability + broker config match.
- **`$SYS` topic access = observability gold + operational secrets**: the `$SYS` topic tree exposes internal broker state (connected clients, QoS stats, node health). **ACL-restrict `$SYS` subscription to ops-only accounts** — regular device accounts shouldn't see broker internals.
- **RETAINED MESSAGES are POWERFUL + FOOTGUN**: MQTT retained messages persist indefinitely. A device publishing retained to `/factory/floor/emergency` with "override" = next subscriber gets "override" as first message. **Audit what's retained periodically** + document retained-message expectations per topic.
- **WILL MESSAGES**: when a device disconnects ungracefully, will-message is published. Can reveal info (device-status). Design topic structure so wills don't leak sensitive state.
- **SCALE PLANNING**: MQTT brokers hit different bottlenecks:
  - **Connection count**: per-connection memory (~KB each); millions-of-devices = big RAM
  - **Publish throughput**: messages/sec; scales with cluster
  - **Retained message count**: O(subscribers × retained-topics) at subscribe time — careful with "retained" for public topics
  - **Persistent session count** (QoS 1/2 with clean-session=false): each pending-message queued per offline client
  - **Plan for peak, not average.**
- **HUB-OF-CREDENTIALS Tier 2**: VerneMQ stores:
  - All MQTT credentials (username+password hashed, or reference to external backend)
  - TLS private keys
  - Cluster cookie
  - API tokens for HTTP mgmt API
  - **24th tool in hub-of-credentials family, crown-jewel Tier 2** — compromised broker = attacker controls the IoT platform's command-path.
- **IoT-SPECIFIC LEGAL / SAFETY**:
  - Industrial/medical IoT devices via MQTT can have **safety-critical** implications (a hijacked MQTT-command = physical-world harm)
  - **Cybersecurity regulations** (EU CRA, US CISA IoT baseline, UK PSTI) mandate IoT security baselines
  - **10th tool in network-service-legal-risk family** — the risk isn't illegal-content (like Bitmagnet, AzuraCast, pyLoad), it's SAFETY + liability for connected devices
- **BRIDGE SECURITY**: MQTT-to-MQTT bridges forward traffic. A compromised bridge relays attacker traffic into upstream brokers. Audit bridge destinations + creds.
- **Erlang-as-OS learning curve**: tuning VerneMQ at scale requires some Erlang/OTP understanding (VM flags, process limits). Community docs help; for production-critical, consider paid support from VerneMQ GmbH.
- **COMMERCIAL-TIER taxonomy**: VerneMQ GmbH offers **"services-around-OSS"** (support contracts) + possibly open-core (enterprise features in paid edition). Same class as osTicket (batch 89) + pgAdmin (90 via Postgres commercial vendors).
- **INSTITUTIONAL-STEWARDSHIP company-tier** (VerneMQ GmbH, similar to LimeSurvey GmbH batch 90, Deciso batch 80, TryGhost). **13th tool in institutional-stewardship family, company sub-tier.**
- **"AI Autonomy" badges**: VerneMQ doesn't use one but OliveTin in this same batch does — pattern worth noticing for future consolidation.
- **Alternatives worth knowing:**
  - **Eclipse Mosquitto** — lightweight single-node; C-based; EPL-2.0; widely deployed
  - **EMQ X (EMQX)** — Erlang-based like VerneMQ; Apache-2 + commercial; hyperscale focus
  - **HiveMQ** — commercial-first; community edition available
  - **RabbitMQ with MQTT plugin** — AMQP-primary, MQTT-via-plugin
  - **AWS IoT Core** / **Azure IoT Hub** / **Google Cloud IoT Core (shut down)** — commercial SaaS
  - **NanoMQ** — lightweight C++ MQTT broker
  - **Choose VerneMQ if:** you want Erlang-grade reliability + distributed scaling + Apache-2 + proven in production at scale.
  - **Choose Mosquitto if:** you want simple single-node + lightweight C + don't need clustering.
  - **Choose EMQX if:** you want higher-scale feature set + similar Erlang lineage + commercial support easier to buy.
- **Project health**: active repo + VerneMQ GmbH commercial backing + active forum + Mastodon + Google Group + 10-year track record. Strong signals.

## Links

- Repo: <https://github.com/vernemq/vernemq>
- Homepage: <https://vernemq.com>
- Docs: <https://docs.vernemq.com>
- Docker: <https://hub.docker.com/r/vernemq/vernemq>
- Forum: <https://erlangforums.com/c/erlang-platforms/vernemq-forum/82>
- Mosquitto (alt): <https://mosquitto.org>
- EMQX (alt): <https://www.emqx.com>
- HiveMQ (commercial-first alt): <https://www.hivemq.com>
- NanoMQ (lightweight alt): <https://nanomq.io>
- MQTT spec: <https://mqtt.org>
