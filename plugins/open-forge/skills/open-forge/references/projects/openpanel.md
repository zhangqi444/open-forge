# OpenPanel

**Highly customizable self-hosted web hosting control panel — gives each user an isolated Docker container with their own web server, PHP version, database, and resource limits. Includes OpenAdmin for host-level management.**
Official site: https://openpanel.com
Docs: https://openpanel.com/docs/admin/intro/
GitHub: https://github.com/stefanpejcic/OpenPanel

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu 24.04 | Bare metal / VPS | Recommended (AMD CPU) |
| Ubuntu 22.04 | Bare metal / VPS | Supported |
| Debian 10–13 | Bare metal / VPS | Supported |
| AlmaLinux 9.5 | Bare metal / VPS | Recommended for ARM CPU |
| AlmaLinux 10 | Bare metal / VPS | Supported |
| RockyLinux 9.6 / 10 | Bare metal / VPS | Rocky 10: switch nftables → iptables first |
| CentOS 9.5 | Bare metal / VPS | Supported |

> Not installed via Docker Compose — uses its own installer script on a VPS or dedicated server.

---

## Inputs to Collect

### Required
- Fresh VPS or dedicated server (one of the supported OS/versions above)
- Root SSH access

---

## Software-Layer Concerns

### Installation
```bash
bash <(curl -sSL https://openpanel.org)
```

See https://openpanel.com/install for configuration options.

### Architecture
```
Server
├── OpenAdmin   — admin panel (host management: users, plans, settings)
└── OpenPanel   — user panel (per-user Docker containers)
    ├── Web server (Nginx, Apache, OpenLiteSpeed, or Varnish combinations — per user)
    ├── PHP version (multiple — per site, per user)
    ├── Database (MySQL 8.0, MariaDB, Percona, or PostgreSQL — per user)
    └── Resource limits (CPU, RAM, storage — per user)
```

### Key features
- Per-user isolated Docker containers (VPS-like experience for shared hosting)
- Per-user web server and PHP version selection
- Dedicated database per user
- Resource limits (CPU, RAM, storage) per user
- Caddy reverse proxy + SSL
- BIND9 DNS server
- Full activity log for all user actions
- Billing integrations: FOSSBilling, WHMCS, Blesta
- cPanel / CyberPanel account import
- White-label UI customization
- REST API

---

## Upgrade Procedure

Follow the official upgrade docs: https://openpanel.com/docs/admin/intro/

---

## Gotchas

- Requires a fresh OS installation — not installed on top of an existing server setup
- RockyLinux 10: must manually switch from `nftables` to `iptables` before installing (see [#1472](https://github.com/docker/for-linux/issues/1472))
- Not a Docker Compose app — the installer manages Docker internally

---

## References
- Installation: https://openpanel.com/install
- Admin docs: https://openpanel.com/docs/admin/intro/
- User panel docs: https://openpanel.com/docs/panel/intro/
- GitHub: https://github.com/stefanpejcic/OpenPanel#readme
