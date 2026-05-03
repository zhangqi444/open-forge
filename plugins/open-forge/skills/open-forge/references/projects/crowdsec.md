---
name: CrowdSec
description: Crowd-sourced intrusion detection + IP reputation system. Agent parses logs (SSH, nginx, Apache, Cloudflare, Traefik, K8s audit, …) to detect attacks; shares anonymized attack signatures with the community; bouncers enforce blocks via iptables / nginx / Cloudflare / Traefik / AWS / etc. Go, modular, MIT. Free Community Blocklist; paid tiers add more blocklists.
---

# CrowdSec

CrowdSec is a modern fail2ban successor with a twist: you don't just block what you see; you also benefit from a crowd-sourced blocklist of IPs already attacking others. Architecture:

1. **Agent** parses logs (SSH attempts, nginx 401s, etc.) in real time
2. **Detection** using modular "scenarios" (SSH brute, nginx 404 flood, WordPress probe, …)
3. **Local Decisions** store detected attackers in a local DB with a TTL
4. **Bouncers** enforce those decisions — block at firewall, reject at nginx, challenge at Cloudflare edge, custom webhook
5. **Community** signal: signed attack signatures uploaded; in return, you pull down the Community Blocklist (IPs others have reported)

Different from fail2ban:

- Parses structured logs (not regex-only)
- Agent is decoupled from the bouncer (log-parsing machine != enforcement machine)
- Crowd intelligence makes "new attacker" lookups cheap
- Console (web dashboard at <https://app.crowdsec.net>) aggregates multiple hosts

- Upstream repo: <https://github.com/crowdsecurity/crowdsec>
- Website: <https://www.crowdsec.net>
- Docs: <https://docs.crowdsec.net>
- Hub (scenarios, parsers, collections): <https://hub.crowdsec.net>
- Discord: <https://discord.gg/crowdsec>

## Architecture in one minute

- **`crowdsec`** (agent/LAPI) — single Go binary that: parses logs, detects attacks, exposes a Local API (LAPI) where bouncers pull decisions
- **Bouncers** (separate binaries) — enforce decisions. Examples:
  - `cs-firewall-bouncer` — iptables/nftables block at the kernel
  - `cs-nginx-bouncer` — nginx module, returns 403
  - `cs-cloudflare-bouncer` — adds IPs to Cloudflare's WAF block list
  - `cs-traefik-bouncer` — Traefik middleware (ForwardAuth-style)
  - `cs-aws-waf-bouncer` / `cs-haproxy-bouncer` / `cs-custom-bouncer` (webhook)
- **Hub** content: scenarios (YAML rules) + parsers + collections (curated bundles for nginx, SSH, WordPress, …)
- **Central API (CAPI)** — where agents share anonymized attack signatures + pull the Community Blocklist

## Compatible install methods

| Infra / Host                | Runtime                                                    | Notes                                                              |
| --------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------ |
| Any Linux                   | Distro package (`apt install crowdsec`)                     | **Most common**; pairs with distro log paths                        |
| Any                          | Docker (`crowdsecurity/crowdsec`)                           | For containerized setups; mount log files in                        |
| Kubernetes                  | Helm chart (official)                                      | `crowdsecurity/crowdsec` chart; reads K8s audit logs + ingress logs  |
| Cloudflare-fronted          | Agent anywhere + `cs-cloudflare-bouncer`                    | Edge blocking before traffic reaches your origin                    |
| nginx / Traefik             | Corresponding bouncer                                       | L7 block                                                            |
| Appliance                   | OPNsense / pfSense plugin                                   | Community-maintained                                                 |

## Inputs to collect

| Input                       | Example                                         | Phase     | Notes                                                           |
| --------------------------- | ----------------------------------------------- | --------- | --------------------------------------------------------------- |
| Log sources                 | `/var/log/auth.log`, nginx access.log, etc.    | Config    | Per-service acquisition files in `/etc/crowdsec/acquis.d/`       |
| Collections to install      | `crowdsecurity/nginx`, `.../sshd`, `.../linux` | Config    | Bundles of parsers + scenarios                                   |
| Community-blocklist opt-in  | enabled by default (`cscli capi register`)      | Community | Required to receive Community Blocklist                          |
| Console enrollment          | token from <https://app.crowdsec.net>           | Dashboard | Optional; multi-host visibility                                  |
| Bouncer API keys            | `cscli bouncers add <name>`                     | Deploy    | One per bouncer instance                                         |
| Whitelist                   | your own IPs in `/etc/crowdsec/parsers/s02-enrich/whitelists.yaml` | Ops | Don't ban yourself                                |

## Install on a Linux host (apt)

```sh
# Add repo + install
curl -s https://install.crowdsec.net | sudo sh
sudo apt install crowdsec

# Enroll with the Console (optional but useful)
sudo cscli console enroll <TOKEN>   # grab from https://app.crowdsec.net

# Install collections (scenarios + parsers bundles)
sudo cscli collections install crowdsecurity/linux crowdsecurity/sshd crowdsecurity/nginx

# Install a firewall bouncer
sudo apt install crowdsec-firewall-bouncer-nftables   # or -iptables
# Bouncer auto-registers with agent via LAPI

# Check status
sudo cscli hub list
sudo cscli decisions list
sudo cscli alerts list
```

## Install via Docker

```yaml
services:
  crowdsec:
    image: crowdsecurity/crowdsec:v1.7.7   # pin; don't use :latest
    container_name: crowdsec
    restart: unless-stopped
    environment:
      - COLLECTIONS=crowdsecurity/linux crowdsecurity/nginx crowdsecurity/sshd
      - GID=1000
      # Optional: enroll with Console
      # - ENROLL_KEY=...
    volumes:
      - ./config:/etc/crowdsec
      - ./data:/var/lib/crowdsec/data
      - /var/log/auth.log:/logs/auth.log:ro            # mount logs you want parsed
      - /var/log/nginx:/logs/nginx:ro
    ports:
      - "127.0.0.1:8080:8080"       # LAPI — don't expose publicly!
```

### Docker agent + separate firewall bouncer on host

Agent runs in Docker parsing logs; a host-installed `cs-firewall-bouncer` talks to the containerized agent's LAPI to update host iptables.

```sh
# On host
sudo apt install crowdsec-firewall-bouncer-nftables
# Edit /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml:
#   api_url: http://127.0.0.1:8080/
#   api_key: <from `docker exec crowdsec cscli bouncers add hostfb`>
sudo systemctl restart crowdsec-firewall-bouncer
```

## Install a bouncer (the enforcement layer)

CrowdSec **detects** but doesn't block until you install a bouncer.

| Enforcement point          | Bouncer                              | Install                                            |
| -------------------------- | ------------------------------------ | -------------------------------------------------- |
| Host firewall (iptables)   | `crowdsec-firewall-bouncer-iptables` | `apt install`                                      |
| Host firewall (nftables)   | `crowdsec-firewall-bouncer-nftables` | `apt install`                                      |
| nginx (L7)                 | `crowdsec-nginx-bouncer`             | `apt install` + load nginx module                 |
| Cloudflare edge            | `crowdsec-cloudflare-bouncer`        | Go binary; config with CF API token                |
| Traefik middleware         | `maxlerebourg/crowdsec-bouncer-traefik-plugin` | Traefik plugin                            |
| Custom webhook             | `crowdsec-custom-bouncer`            | For pushing to Fastly, AWS WAF, custom edge       |

## Data & config layout

### Host install

- `/etc/crowdsec/` — config dir
  - `config.yaml` — main config
  - `acquis.yaml` + `acquis.d/` — log source definitions
  - `parsers/`, `scenarios/`, `postoverflows/` — hub content (symlinked from `/etc/crowdsec/hub/`)
  - `bouncers/<name>.yaml` — bouncer configs
- `/var/lib/crowdsec/data/crowdsec.db` — SQLite of decisions, alerts, machines
- `/var/log/crowdsec.log` — agent log

### Docker install

Config + data volumes as above; mount log files you want parsed into `/logs/`.

## Backup

```sh
# Config
tar czf crowdsec-config-$(date +%F).tgz /etc/crowdsec

# State DB (small — decisions + alerts)
sqlite3 /var/lib/crowdsec/data/crowdsec.db ".backup /tmp/crowdsec-db-$(date +%F).db"
```

Re-registering with the Central API is quick; the most important thing to preserve is your local custom scenarios + whitelist.

## Upgrade

1. Releases: <https://github.com/crowdsecurity/crowdsec/releases>. Regular cadence.
2. apt: `apt upgrade crowdsec` + `systemctl restart crowdsec`.
3. Docker: `docker compose pull && docker compose up -d`.
4. Hub content (scenarios/parsers) updates **separately** via `cscli hub update && cscli hub upgrade` — run weekly.
5. Bouncers upgrade independently; **align versions with the agent** (major mismatches may break API protocol).
6. DB migrations automatic; break-glass documented in release notes for major bumps.

## Gotchas

- **CrowdSec detects; bouncers block.** Installing the agent alone = you see alerts but nothing is actually blocked. Always pair with at least one bouncer.
- **LAPI is not public.** Bind to `127.0.0.1` or Docker network; NEVER expose port 8080 to the internet (that's the bouncer API endpoint, with admin capabilities).
- **Bouncer API keys are credentials.** Rotate via `cscli bouncers delete <name>` + re-add if compromised.
- **Community Blocklist has a reputation gate.** New agents need to prove themselves (send legit reports for ~a week) before receiving the full blocklist. You'll see partial coverage initially.
- **Whitelist yourself** in `/etc/crowdsec/parsers/s02-enrich/whitelists.yaml` with your admin IPs or you'll ban yourself during a ham-fisted SSH session.
- **Parser/scenario updates can change behavior.** `cscli hub upgrade` pulls new versions of rules; occasionally a more aggressive scenario starts banning legitimate traffic. Monitor post-upgrade.
- **Log file permission**: CrowdSec runs as `crowdsec` user; it needs read access on log files. Ship logs via syslog if you don't want to add `crowdsec` to `adm` group.
- **Cloudflare bouncer rate limits.** CF API has strict rate limits; the bouncer batches updates every few minutes. Don't expect sub-second edge blocking.
- **Scenarios are YAML.** You can write your own for app-specific attacks. Learn the leaky-bucket model: `leakspeed`, `capacity`, `filter`.
- **Decision TTL** defaults to 4 hours. Tune per scenario for longer/shorter bans.
- **Collections vs scenarios**: Collections are curated bundles (e.g., `crowdsecurity/nginx` = nginx parsers + nginx scenarios). Start with collections, customize with individual items.
- **No log = no detection**. If an app writes logs only on a socket, CrowdSec needs a parser for that transport (syslog, journalctl, file, docker stdout).
- **Metrics exposed at Prometheus-compatible endpoint**; scrape for detection/alert/decision rates.
- **`cscli decisions add --ip <IP> --duration 24h`** to manually ban; `delete` to unban.
- **`cscli explain --file <log>`** tests parsers against a log line — invaluable debug.
- **Paid tiers** (Blocklists +) unlock specific domain blocklists (VPN, Tor, ransomware C2 IPs). Free tier is the Community Blocklist.
- **Privacy**: signals sent to CAPI are anonymized; read <https://www.crowdsec.net/privacy-by-design>.
- **Alternatives worth knowing:**
  - **fail2ban** — the classic; log-grep + iptables; simpler, no crowd intel
  - **CrowdSec itself via AppSec** (newer add-on) — WAF-style inline request inspection
  - **Cloudflare WAF + Bot Fight Mode** — managed equivalent, pay CF
  - **Wazuh / OSSEC** — full SIEM/HIDS, much heavier
  - **ModSecurity + OWASP CRS** — traditional WAF
  - **Suricata / Zeek** — network IDS (not log-based)

## Links

- Repo: <https://github.com/crowdsecurity/crowdsec>
- Docs: <https://docs.crowdsec.net>
- Install: <https://docs.crowdsec.net/docs/getting_started/install_crowdsec/>
- Docker: <https://docs.crowdsec.net/docs/getting_started/install_crowdsec_docker/>
- Hub: <https://hub.crowdsec.net>
- Console: <https://app.crowdsec.net>
- Bouncers list: <https://docs.crowdsec.net/docs/bouncers/intro>
- cscli reference: <https://docs.crowdsec.net/docs/cscli/cscli>
- Releases: <https://github.com/crowdsecurity/crowdsec/releases>
- Docker Hub: <https://hub.docker.com/u/crowdsecurity>
- Discord: <https://discord.gg/crowdsec>
