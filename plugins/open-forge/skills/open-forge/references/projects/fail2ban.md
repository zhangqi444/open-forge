---
name: Fail2Ban
description: Scans log files for failed auth attempts and bans offending IPs via firewall (iptables/nftables/pf) rules for a configurable period. GPL-2.0, Python, maintained since 2004.
---

# Fail2Ban

Fail2Ban is a log-tailing intrusion-prevention daemon. It watches `/var/log/auth.log`, web-server access logs, mail-server logs, etc., matches failure patterns with "filters", and runs "actions" (typically firewall insertions) when a source IP crosses a threshold within a time window. Multiple "jails" each pair a filter + action + log path.

- Upstream repo: <https://github.com/fail2ban/fail2ban>
- Website: <https://www.fail2ban.org>
- Dev docs: <https://fail2ban.readthedocs.io/>

**Upstream does NOT publish a Docker image.** Fail2Ban is a host-system service: on a real server, install the distro package (`apt install fail2ban`, `dnf install fail2ban`, `pkg install py311-fail2ban`, etc.) and run it under systemd. For container/Docker-host use, the community-standard image is `crazymax/fail2ban`.

## Compatible install methods

| Infra                        | Runtime                                  | Notes                                                                     |
| ---------------------------- | ---------------------------------------- | ------------------------------------------------------------------------- |
| Linux host (bare metal / VM) | Distro package + systemd                 | **Recommended.** Matches how upstream is tested; watches host logs natively |
| FreeBSD / OpenBSD            | Distro package                           | `/etc/rc.d/fail2ban`; uses `pf` actions instead of iptables               |
| Docker host                  | `crazymax/fail2ban` container (`--network host`, `--cap-add NET_ADMIN NET_RAW`) | For protecting Docker itself via DOCKER-USER chain                       |
| Kubernetes                   | Not supported                            | Fail2Ban needs host-level firewall access; not a cloud-native fit          |

## Inputs to collect

| Input                 | Example                          | Phase    | Notes                                                                   |
| --------------------- | -------------------------------- | -------- | ----------------------------------------------------------------------- |
| Jail list             | `sshd`, `nginx-http-auth`, `recidive` | Config | Which services to protect; enable per-jail in `jail.d/*.local`          |
| `bantime`             | `1h`, `1d`, `-1` (permanent)     | Config   | Ban duration; `-1` is permanent (use with `recidive` jail)              |
| `findtime`            | `10m`                            | Config   | Sliding window for counting failures                                    |
| `maxretry`            | `5`                              | Config   | Fail count within `findtime` that triggers the ban                       |
| `ignoreip`            | `127.0.0.1/8 10.0.0.0/8 …`       | Config   | **Critical:** allow-list for your own networks and monitoring probes    |
| Backend               | `systemd` / `pyinotify` / `polling` | Config | How logs are read; `systemd` on distros that journal                    |
| Chain (Docker hosts)  | `DOCKER-USER` vs `INPUT`         | Config   | Docker-hosted services need `DOCKER-USER`; host SSH stays on `INPUT`    |

## Install via distro package (recommended)

```sh
# Debian/Ubuntu:
sudo apt update && sudo apt install fail2ban
sudo systemctl enable --now fail2ban

# RHEL/Fedora/Rocky/Alma:
sudo dnf install fail2ban fail2ban-firewalld   # firewalld mode
sudo systemctl enable --now fail2ban
```

Create `/etc/fail2ban/jail.local` (never edit `jail.conf` — it's overwritten on upgrade):

```ini
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8

[sshd]
enabled  = true

[recidive]
enabled  = true
bantime  = 1w
findtime = 1d
maxretry = 5
```

Reload: `sudo fail2ban-client reload`. Status: `sudo fail2ban-client status sshd`. Unban: `sudo fail2ban-client set sshd unbanip 203.0.113.42`.

## Install via Docker (`crazymax/fail2ban`)

Per <https://github.com/crazy-max/docker-fail2ban>:

```yaml
services:
  fail2ban:
    image: crazymax/fail2ban:1.1.0   # pin; track ghcr.io/crazy-max/fail2ban for latest
    container_name: fail2ban
    restart: unless-stopped
    network_mode: host           # required — must see host firewall
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - TZ=UTC
      - F2B_LOG_TARGET=STDOUT
      - F2B_LOG_LEVEL=INFO
      - F2B_DB_PURGE_AGE=1d
      - IPTABLES_MODE=auto       # or 'nft' / 'legacy' to force
    volumes:
      - ./data:/data             # custom jail.d, action.d, filter.d + persistent ban DB
      - /var/log:/var/log:ro     # so Fail2Ban can tail host logs
```

Platform matrix is large — image publishes for `linux/amd64`, `linux/arm64`, `linux/arm/v7`, `linux/arm/v6`, `linux/386`, `linux/ppc64le`, `linux/riscv64`, `linux/s390x`.

Custom jails go in `./data/jail.d/*.local`; custom filters in `./data/filter.d/`. `fail2ban-client` still works via `docker exec`:

```sh
docker exec -it fail2ban fail2ban-client status
docker exec -it fail2ban fail2ban-client set sshd banip 203.0.113.42
```

## Data & config layout

- `/etc/fail2ban/jail.conf` — ships with distro; **do not edit** (overwritten)
- `/etc/fail2ban/jail.local` — your global overrides
- `/etc/fail2ban/jail.d/*.local` — per-service jails
- `/etc/fail2ban/filter.d/*.conf` — regex filters (one per protocol)
- `/etc/fail2ban/action.d/*.conf` — firewall actions (one per platform)
- `/var/lib/fail2ban/fail2ban.sqlite3` — persistent ban database
- `/var/log/fail2ban.log` — service log

Docker variant maps the same tree under `/data/` (jail.d/, filter.d/, action.d/, the sqlite db).

## Gotchas

- **`ignoreip` is critical.** Without it, a burst of failed `ssh` logins from your own jump host (mistyped password) will lock you out. Include all your management IPs + VPN CIDRs.
- **Docker + `INPUT` chain is a trap.** Docker inserts its own rules on the `FORWARD` / `DOCKER-USER` chains that bypass `INPUT`. Fail2Ban jails for Docker-hosted services (Traefik, nginx-proxy, etc.) need `chain = DOCKER-USER`; host SSH stays on `chain = INPUT`.
- **`network_mode: host`** is mandatory for the Docker variant. Bridge networking isolates Fail2Ban from the host firewall.
- **`NET_ADMIN + NET_RAW` caps** let Fail2Ban modify host firewall rules — treat the container as equivalent to host root.
- **Default `bantime=10m`** is trivially defeated by a botnet. Use `bantime.increment=true` (exponential backoff up to `bantime.maxtime`) or enable the `recidive` jail.
- **`nft` vs `iptables-legacy`:** modern distros default to `nftables` with the `iptables-nft` shim. If you explicitly want `iptables-legacy` (e.g. for Docker <20.10), set `banaction = iptables-legacy` or `IPTABLES_MODE=legacy`.
- **Log-format drift.** SSHD 9.x changed failure log lines. If you're on an old distro's Fail2Ban + new OpenSSH, built-in filters miss attacks. Either upgrade Fail2Ban or use `/etc/fail2ban/filter.d/sshd.local` with an updated regex.
- **`pyinotify` vs `systemd` vs `polling` backends.** The systemd backend is fastest + most reliable on systemd distros; `pyinotify` misses rotated logs on some setups; `polling` burns CPU.
- **Banning the router IP.** Many corporate NATs put everyone behind one IP; a single compromised user can get your whole office blocked. Scope jails with `ignoreip` carefully.
- **IPv6 support requires `allowipv6 = auto`** in `fail2ban.local` on some older distro packages — modern packages default to `auto` but older Ubuntu LTS releases do not.
- **SQLite DB grows.** `F2B_DB_PURGE_AGE` (or `dbpurgeage` in `fail2ban.conf`) controls history retention. Default `1d` is fine; raise for forensics, not for operational bans.
- **Doesn't stop distributed attacks.** Fail2Ban bans individual IPs. A 10 000-IP botnet with 1 request each will never trigger a ban. Pair with rate limiting at the app/proxy layer + WAF + CrowdSec (complementary tool).
- **Email notifications can rate-limit YOU.** `[DEFAULT] destemail` + `action = %(action_mwl)s` emails every ban. Busy hosts DDoS their own SMTP with attack reports; use digest mode or drop emails.
- **Upstream is on version 1.x as of 2025** after many years in 0.10/0.11 series. Major filter/action syntax changes between 0.x and 1.x — some third-party jails need updates.

## Upgrade

- **Package:** `apt upgrade fail2ban` / `dnf update fail2ban` — distro maintainer handles migrations.
- **Docker:** `docker compose pull && docker compose up -d`. Check release notes: <https://github.com/fail2ban/fail2ban/releases>.
- After upgrade: `sudo fail2ban-client reload` to reload jails without dropping existing bans.

## Links

- Repo: <https://github.com/fail2ban/fail2ban>
- Wiki: <https://github.com/fail2ban/fail2ban/wiki>
- Readthedocs: <https://fail2ban.readthedocs.io/>
- Default `jail.conf` reference: <https://github.com/fail2ban/fail2ban/blob/master/config/jail.conf>
- Community Docker image: <https://github.com/crazy-max/docker-fail2ban>
- Crazymax compose examples: <https://github.com/crazy-max/docker-fail2ban/tree/master/examples>
- Install-from-packages wiki: <https://github.com/fail2ban/fail2ban/wiki/How-to-install-fail2ban-packages>
- Alternatives/complements: CrowdSec (<https://github.com/crowdsecurity/crowdsec>) for collaborative blocklists
