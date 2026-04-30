---
name: HAProxy
description: "Free, fast, reliable TCP/HTTP reverse proxy + load balancer. Industry-standard software load balancer: powers GitHub, Reddit, Stack Overflow, Twitter (historically), countless financial trading systems. Single config file. Modern features: HTTP/3 (QUIC), Lua scripting, stick tables, SPOE. GPL-2.0+ / LGPL-2.1 headers."
---

# HAProxy

HAProxy is **the industry-standard software load balancer** — a high-performance TCP and HTTP reverse proxy used everywhere from personal homelabs to the busiest sites on the internet. Exceptionally fast, rock-solid stability, powerful config DSL, outstanding observability. If you need to put more than one backend behind a single entry point, or terminate TLS at the edge, HAProxy does it and does it very well.

What it does:

- **Layer 4 (TCP) load balancing** — for any TCP protocol (MySQL, Redis, RabbitMQ, SSH, etc.)
- **Layer 7 (HTTP/HTTPS) load balancing** — with header inspection, routing rules, rewriting
- **TLS termination** — SNI, ALPN, OCSP stapling, session resumption
- **HTTP/2** + **HTTP/3 (QUIC)** (modern versions)
- **WebSocket** — transparent pass-through
- **Health checks** — HTTP / TCP / custom scripts; active + passive
- **Load-balancing algorithms** — roundrobin, leastconn, source, uri, hdr, random, first
- **Rate limiting / stick tables** — per-IP / per-session / per-header state tracking
- **Connection pooling** to backends (HTTP keep-alive efficiency)
- **Circuit breaker** patterns via `observe`, `on-marked-down`
- **Lua scripting** — custom logic in hot path
- **SPOE (Stream Processing Offload Engine)** — offload processing to external agents (e.g., mod-security)
- **Stats / admin socket** — runtime tuning, zero-downtime reloads
- **Prometheus exporter** (built-in since 2.x)
- **ACL language** — expressive routing rules

Running since ~2001. Used by GitHub, Reddit, Stack Overflow, Airbnb, Twitter (historically), Instagram, Tumblr, countless banks and trading desks.

- Upstream repo: <https://github.com/haproxy/haproxy>
- Website: <http://www.haproxy.org>
- Docs: <http://docs.haproxy.org>
- Wiki: <https://github.com/haproxy/wiki/wiki>
- Commercial (HAProxy Enterprise / Fusion / ALOHA): <https://www.haproxy.com>

## Architecture in one minute

- **Single multithreaded process** (modern versions); event-driven (epoll/kqueue/evports)
- **Config: single plain-text file** (`haproxy.cfg`) with `global`, `defaults`, `frontend`, `backend`, `listen` sections
- **Zero-downtime reload** via `SIGUSR2` / `haproxy -sf` — drains old workers
- **Extremely low memory** — tens of MB typical; scales to 100k+ concurrent connections
- **No dependencies** beyond libc / openssl / zlib — statically buildable
- **Stats UI** on an admin port; optionally Prometheus metrics

## Compatible install methods

| Infra          | Runtime                                                      | Notes                                                                            |
| -------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| Single VM      | **Distro package** (`apt install haproxy`)                       | **Simplest**; Debian/Ubuntu/RHEL all ship recent LTS versions                        |
| Single VM      | **HAProxy Technologies PPA** (Debian/Ubuntu)                                  | For latest stable branch (2.8/2.9/3.0/3.1)                                                   |
| Single VM      | **Docker (`haproxy:2.9-alpine`)**                                                     | Great for isolation + version pinning                                                                   |
| Kubernetes     | HAProxy Ingress Controller / Kubernetes Ingress HAProxy                                       | Full-featured; competes with nginx-ingress / Traefik                                                             |
| Cloud          | HAProxy ALOHA (hardware-ish appliance) / Enterprise subscription                                        | Commercial paths                                                                                                         |
| Raspberry Pi   | Works; arm64 packages                                                                                              | Tiny resource footprint                                                                                                                     |

## Inputs to collect

| Input                | Example                               | Phase       | Notes                                                                  |
| -------------------- | ------------------------------------- | ----------- | ---------------------------------------------------------------------- |
| Listen addrs/ports   | `*:80`, `*:443`                             | Network     | Frontend binds                                                                  |
| Backend endpoints    | `10.0.0.10:8080`, `10.0.0.11:8080`                    | Routing     | One or many; health-checked                                                            |
| TLS certs            | fullchain PEM + key                                   | Security    | Single file preferred (`cat cert.pem key.pem > haproxy.pem`)                                           |
| Stats port           | `:9000`                                                        | Ops         | Lock down; admin access                                                                                   |
| Prometheus           | same process, `/metrics` endpoint                                      | Metrics     | Built-in since 2.0                                                                                                 |
| Load-balancing alg   | `roundrobin` (default) / `leastconn` / `source`                                   | Config      | Most common: `roundrobin` for stateless HTTP, `source` for sticky, `leastconn` for long-lived                                 |
| Health-check path    | `GET /health`                                                                            | Backend     | Must respond 200 fast                                                                                                                    |

## Install on Debian/Ubuntu

```sh
sudo apt install -y haproxy
# For latest stable, use HAProxy PPA:
# sudo add-apt-repository ppa:vbernat/haproxy-3.1
# sudo apt install -y haproxy=3.1.*

# Edit config
sudo $EDITOR /etc/haproxy/haproxy.cfg

# Test config before reload!
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload (zero-downtime)
sudo systemctl reload haproxy
```

## Minimal `haproxy.cfg`

```
global
    log /dev/log local0
    maxconn 50000
    user haproxy
    group haproxy
    daemon
    # Modern TLS
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384
    ssl-default-bind-options prefer-client-ciphers ssl-min-ver TLSv1.2
    # Metrics + stats socket
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client 50s
    timeout server 50s
    timeout http-request 10s

# Frontend: HTTPS on 443, redirect HTTP
frontend https-in
    bind :80
    bind :443 ssl crt /etc/haproxy/certs/haproxy.pem alpn h2,http/1.1
    http-request redirect scheme https code 301 unless { ssl_fc }
    default_backend app

# Backend: round-robin across two app servers
backend app
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    server app1 10.0.0.10:8080 check inter 2s fall 3 rise 2
    server app2 10.0.0.11:8080 check inter 2s fall 3 rise 2

# Stats + Prometheus
frontend stats
    bind :9000
    http-request use-service prometheus-exporter if { path /metrics }
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:verystrongpassword      # change!
```

## First boot

1. `sudo haproxy -c -f /etc/haproxy/haproxy.cfg` — **ALWAYS test config before reload**
2. `sudo systemctl start haproxy && sudo systemctl enable haproxy`
3. `curl -I https://yourdomain.com/` → 200 from a backend
4. Stats UI: `http://haproxy:9000/stats` (admin-locked)
5. Prometheus: scrape `http://haproxy:9000/metrics`
6. Load test: `wrk -t4 -c400 -d30s https://yourdomain.com/` — observe stats

## Data & config layout

- `/etc/haproxy/haproxy.cfg` — the config
- `/etc/haproxy/certs/` — TLS combined PEMs (if on-disk)
- `/var/log/haproxy.log` (via syslog)
- `/run/haproxy/admin.sock` — runtime admin socket
- HAProxy itself has **no persistent data** — fully stateless; reloads start fresh

## Backup

```sh
tar czf haproxy-$(date +%F).tgz /etc/haproxy/
```

Stateless → just back up config + certs.

## Upgrade

1. Release branches: <https://github.com/haproxy/wiki/wiki/Versions>. LTS = even-numbered stable (2.2, 2.4, 2.6, 2.8, 3.0). Stay on LTS unless you need a feature.
2. Always test on staging first.
3. `apt upgrade haproxy` → `haproxy -c -f ...` → `systemctl reload haproxy` (zero-downtime).
4. Watch for deprecated keywords — release notes call these out.
5. **Major version (e.g., 2.x → 3.x)** — read migration guide; some config changes.

## Gotchas

- **Always `haproxy -c -f cfg` before reload.** A syntax error = systemctl reload silently fails = old config still running OR hard-stop. Test first. **Always.**
- **Max open files**: default ulimit usually OK at ~65k but for heavy use bump `maxconn` + systemd `LimitNOFILE=200000`.
- **TLS cert reload**: changing cert file doesn't auto-reload — use `systemctl reload haproxy` or admin socket (`echo "set ssl cert ... <cat fullchain.pem priv.pem" | socat - /run/haproxy/admin.sock`).
- **Let's Encrypt integration**: certbot renewal hook → `haproxy -c && systemctl reload haproxy`. Combined PEM required (`cat fullchain.pem privkey.pem > combined.pem`).
- **HTTP/2 + backend**: frontend can speak h2; backends typically HTTP/1.1 unless you explicitly enable h2 backends.
- **WebSocket** — works out of the box with `mode http` + appropriate timeouts. **Increase `timeout client`/`timeout server`** for long-lived WS.
- **Sticky sessions**: use `cookie SERVERID insert indirect nocache` in backend block — not `balance source` (which is IP-based, broken behind NAT).
- **Send-Proxy protocol**: enable on backend if backend supports it (nginx `proxy_protocol on`, Apache `RemoteIPProxyProtocol On`) — preserves client IP without trusting `X-Forwarded-For`.
- **Rate limiting**: use stick tables + `http-request deny` on threshold. Powerful but config-heavy; read upstream examples.
- **Stats UI exposure**: `stats auth` is HTTP Basic. **Do not** expose the stats port to the internet without an additional auth layer / VPN.
- **Observability gold**: `option httplog` + log format customization → logs have everything (backend, response time, TLS version). Ship to Loki/ELK.
- **SSL session cache**: tune `tune.ssl.cachesize` + `tune.ssl.lifetime` for TLS resumption at scale.
- **Health check flakiness**: set `fall 3 rise 2` — require 3 consecutive failures before down-marking; avoid flapping.
- **Zero-downtime reload**: `systemctl reload` sends USR2; old workers drain active conns, new workers take new conns. Seamless IF health checks don't flap during reload. Tune backends accordingly.
- **Container health checks** — HAProxy in Docker with external health checks is a pain; prefer `haproxy -c -f ...` in the healthcheck.
- **Trust boundary**: HAProxy often terminates TLS → backend is plaintext. Keep backend on private network / localhost / internal VPC.
- **Comparison to nginx**: HAProxy is pure LB (no static files / no PHP); nginx does both. HAProxy has richer L4/L7 LB features + better observability + stick tables. Many use nginx in front for static + HAProxy behind for LB.
- **Comparison to Traefik/Caddy**: Traefik/Caddy have auto-LE + dynamic discovery (Docker/K8s labels). HAProxy requires explicit config but is more powerful + faster at scale.
- **Comparison to envoy**: envoy has richer L7 features + xDS dynamic config; HAProxy is simpler + equally fast for classic LB workloads.
- **License**: **GPL-2.0+** (core) + LGPL-2.1 (headers). Community edition is what you want.
- **Commercial options**: HAProxy Enterprise adds WAF + bot protection + support; ALOHA is a hardware appliance; HAProxy Fusion = control plane for fleets.
- **Alternatives worth knowing:**
  - **nginx** — web server + LB; more LB features free (plus tier for dynamic LB); serves static well
  - **Traefik** — Go-based; dynamic discovery (Docker/K8s); auto-HTTPS built in (separate recipe likely)
  - **Caddy** — Go-based; auto-HTTPS; simpler config than HAProxy/nginx (separate recipe likely)
  - **envoy** — Lyft/CNCF; powerful L7 + xDS; service-mesh oriented
  - **NGINX Plus** — commercial NGINX with dynamic LB
  - **AWS ALB/NLB** / **GCP LB** / **Cloudflare LB** — cloud-native managed
  - **Cloudflare** — CDN/WAF in front of your origin
  - **Choose HAProxy if:** you want the fastest, most observable, most mature software LB with rich L4/L7 features and don't mind writing config.
  - **Choose Traefik/Caddy if:** you want auto-HTTPS + dynamic discovery + simple config.
  - **Choose envoy if:** you're building a service mesh or need xDS.
  - **Choose nginx if:** you want LB + webserver + static serving in one.

## Links

- Repo: <https://github.com/haproxy/haproxy>
- Website: <http://www.haproxy.org>
- Docs (HTML): <http://docs.haproxy.org>
- Configuration manual: <http://docs.haproxy.org/3.1/configuration.html>
- Wiki: <https://github.com/haproxy/wiki/wiki>
- Branches / LTS: <https://github.com/haproxy/wiki/wiki/Versions>
- Discourse: <https://discourse.haproxy.org>
- Slack: <https://slack.haproxy.org>
- Docker Hub: <https://hub.docker.com/_/haproxy>
- Packagecloud (PPAs): <https://haproxy.debian.net>
- HAProxy Technologies (commercial): <https://www.haproxy.com>
- Prometheus exporter (built-in): <http://docs.haproxy.org/3.1/configuration.html#4-prometheus-exporter>
- nginx (alt): <https://nginx.org>
- Traefik (alt): <https://traefik.io>
- Caddy (alt): <https://caddyserver.com>
- envoy (alt): <https://www.envoyproxy.io>
