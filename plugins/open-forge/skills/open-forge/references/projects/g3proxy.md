---
name: g3proxy
description: g3proxy recipe for open-forge. Enterprise-grade forward proxy with proxy chaining, TLS MITM inspection, ICAP adaptation, transparent proxy, and multi-protocol support. Apache-2.0, Rust. Source: https://github.com/bytedance/g3/tree/master/g3proxy
---

# g3proxy

An enterprise-grade forward proxy server from ByteDance supporting proxy chaining, TLS MITM interception, ICAP content adaptation, transparent proxy, and TCP/TLS streaming. Designed for high-throughput production use with rich observability (metrics, logging, tracing). Apache-2.0 licensed, written in Rust. Part of the g3 project. Source: <https://github.com/bytedance/g3>. Docs: <https://g3-project.readthedocs.io/projects/g3proxy/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux (x86_64) | Debian/RPM package | Official packages from GitHub releases |
| Any Linux | Docker image | Community build available |
| Any Linux | Build from source | Requires Rust toolchain |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Use case?" | Forward proxy / MITM inspection / Transparent proxy / Proxy chaining | Drives config structure |
| "Upstream proxy?" | host:port | If chaining through another proxy |
| "TLS inspection (MITM)?" | Yes / No | Requires custom CA cert deployed to clients |
| "ICAP server?" | host:port | Optional — for content scanning/filtering |
| "Listen port?" | Number | e.g. 3128 for HTTP proxy |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Authentication?" | None / Basic / Token | Client authentication method |
| "Allowed networks?" | CIDR list | ACL for which clients can use the proxy |
| "Metrics endpoint?" | host:port | Prometheus metrics |

## Software-Layer Concerns

- **YAML config**: g3proxy uses a YAML configuration file — separate files for servers, upstreams, resolvers, and user groups.
- **Multi-process**: g3proxy runs as multiple worker processes managed by g3proxy-ctl. `g3proxy-ctl` is the admin CLI.
- **TLS MITM**: Requires a custom CA cert and key — the proxy generates per-site certs signed by your CA. Clients must trust your CA.
- **ICAP integration**: Connects to an ICAP server (e.g., ClamAV via c-icap, Squid) for request/response scanning.
- **Transparent proxy**: Requires iptables/nftables REDIRECT rules to intercept traffic without client configuration.
- **Protocol support**: HTTP/1.1, HTTP/2, HTTPS, SOCKS4/5, TCP/TLS streaming, SNI proxying.
- **Observability**: Built-in Prometheus metrics, structured JSON logging, OpenTelemetry tracing.
- **Rust binary**: Single binary with no runtime dependencies beyond glibc.

## Deployment

### Install from package (Debian)

```bash
# Check https://github.com/bytedance/g3/releases for latest .deb
wget https://github.com/bytedance/g3/releases/download/g3proxy-v1.x.y/g3proxy_1.x.y-1_amd64.deb
dpkg -i g3proxy_1.x.y-1_amd64.deb
```

### Minimal config (HTTP forward proxy)

```yaml
# /etc/g3proxy/main.yaml
runtime:
  worker_threads: 4

log:
  default: stdout

resolver:
  - name: default
    type: c-ares
    server: 8.8.8.8

upstreamer:
  - name: default
    type: direct_fixed
    resolver: default

server:
  - name: http-proxy
    type: http_proxy
    listen:
      address: "0.0.0.0:3128"
    upstreamer: default
```

```bash
# Start
g3proxy -c /etc/g3proxy/main.yaml

# Control
g3proxy-ctl -p /run/g3proxy.pid offline
g3proxy-ctl -p /run/g3proxy.pid reload
```

### systemd service

```ini
[Unit]
Description=g3proxy forward proxy
After=network.target

[Service]
ExecStart=/usr/bin/g3proxy -c /etc/g3proxy/main.yaml
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Proxy chaining example

```yaml
upstreamer:
  - name: upstream-chain
    type: http_connect
    peer:
      address: "upstream-proxy.example.com:3128"
      tls_client:
        use_tls: false

server:
  - name: http-proxy
    type: http_proxy
    listen:
      address: "0.0.0.0:3128"
    upstreamer: upstream-chain
```

## Upgrade Procedure

1. Download new package from GitHub releases.
2. `dpkg -i` new package.
3. `systemctl restart g3proxy`.
4. Check https://github.com/bytedance/g3/releases for config format changes.

## Gotchas

- **TLS MITM requires client CA trust**: Without pushing your CA cert to all clients, HTTPS interception will break TLS validation.
- **Complex config format**: Enterprise feature set = complex YAML config. Read the reference docs carefully before production deployment.
- **Worker process model**: g3proxy uses a multi-process model — `g3proxy-ctl` manages running workers; signals affect the supervisor process.
- **Transparent proxy needs iptables**: For transparent mode, configure iptables/nftables REDIRECT rules to intercept traffic on the host.
- **ByteDance origin**: Open-sourced from ByteDance's internal infrastructure. Production-grade but documentation assumes familiarity with enterprise proxy concepts.

## Links

- Source: https://github.com/bytedance/g3/tree/master/g3proxy
- Documentation: https://g3-project.readthedocs.io/projects/g3proxy/
- Releases: https://github.com/bytedance/g3/releases
- User guide (EN): https://github.com/bytedance/g3/blob/master/g3proxy/UserGuide.en_US.md
