---
name: ClamAV
description: "Open-source antivirus engine for detecting trojans, viruses, malware, and other threats. Cross-platform daemon (clamd), CLI scanner (clamscan), signature updater (freshclam), milter for mail integration. Used by countless mail servers, file scanners, and security pipelines. Cisco-Talos maintained. GPL-2.0."
---

# ClamAV

ClamAV is **the ubiquitous open-source antivirus engine** — scan files / mail / uploads / backups for known malware using signatures maintained by Cisco Talos. It's not a consumer AV with a pretty GUI; it's a **building block** you wire into mail servers, file-upload pipelines, S3 bucket scanners, CI scanners, and endpoint checks.

Used under the hood by: Apache SpamAssassin integrations, Amavis, Rspamd, MailScanner, countless Nextcloud/ownCloud AV plugins, S3 virus-scan Lambdas, web upload sanitizers.

Key components:

- **`clamd`** — long-running daemon; keeps virus signatures loaded in RAM; exposes a Unix socket / TCP port for scan requests; very fast (hundreds of MB/s)
- **`clamscan`** — CLI scanner; loads sigs each invocation (slow for one-off, fine for cron)
- **`freshclam`** — signature updater; pulls `main.cvd`, `daily.cvd`, `bytecode.cvd` from the Cisco Talos CVD mirrors
- **`clamav-milter`** — Sendmail/Postfix milter integration
- **`clamonacc`** — on-access scanner (Linux fanotify) — scans every file open/close
- **`libclamav`** — the C library; language bindings exist for most platforms

- Upstream repo: <https://github.com/Cisco-Talos/clamav>
- Website: <https://www.clamav.net>
- Docs: <https://docs.clamav.net>
- Docker Hub: <https://hub.docker.com/r/clamav/clamav>
- Signature database: <https://database.clamav.net>
- Security advisories: <https://blog.clamav.net>

## Architecture in one minute

- **Daemon model**: run `freshclam` periodically (cron / systemd timer / container init) to pull signatures → `clamd` loads them → `clamdscan` / `clamonacc` / milters issue scan requests over socket
- **Signature formats**: `.cvd` (signed bundle) + `.cld` (incrementals) + custom rules (YARA, hash, logical signatures)
- **Resource**: **clamd RAM: 1–2+ GB** at steady state (signature DB in memory). Plan for it.
- **Throughput**: hundreds of MB/s per core; scales linearly with cores for daemon mode

## Compatible install methods

| Infra          | Runtime                                                                | Notes                                                                          |
| -------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM      | **Distro package** (`apt install clamav clamav-daemon`)                    | **Most common** — well-packaged on Debian/Ubuntu/RHEL                              |
| Single VM      | **Docker (`clamav/clamav`)**                                                        | Official image; bundle of clamd+freshclam+CLI                                              |
| Kubernetes     | Helm / community manifests                                                                     | Works; shared signature volume for multi-replica                                                       |
| Windows        | Native installer                                                                                         | Supported                                                                                                         |
| macOS          | Homebrew (`brew install clamav`)                                                                                  | Native                                                                                                                     |
| Mail server    | `clamav-milter` + Postfix/Sendmail                                                                                          | Canonical email-AV integration                                                                                                               |
| Managed SaaS   | — (ClamAV is infra, not SaaS; but it powers many commercial scanners)                                                                                |                                                                                                                                                  |

## Inputs to collect

| Input                | Example                                | Phase      | Notes                                                                    |
| -------------------- | -------------------------------------- | ---------- | ------------------------------------------------------------------------ |
| Signature dir        | `/var/lib/clamav/`                         | Data       | Where `*.cvd` / `*.cld` live                                                  |
| clamd socket         | `/var/run/clamav/clamd.ctl`                       | IPC        | Unix socket (preferred) or TCP `3310`                                                    |
| Freshclam mirror     | defaults fine                                         | Update     | Can use private mirror for airgap                                                                  |
| Max scan size        | 100 MB default                                               | Config     | Raise for large file workflows; `MaxScanSize` / `MaxFileSize` / `StreamMaxLength`                                  |
| On-access target     | `/home/` or upload dir                                                  | Feature    | For `clamonacc`                                                                                                       |
| Milter socket        | Postfix `smtpd_milters`                                                                | Mail       | Chain with SpamAssassin/Rspamd                                                                                                       |
| Auto-update schedule | `freshclam` every 4h                                                                                 | Cron       | Defaults hourly; respect Talos fair-use                                                                                                                    |

## Install on Debian/Ubuntu

```sh
sudo apt update
sudo apt install -y clamav clamav-daemon clamav-freshclam
# Stop clamav-freshclam to do first update manually
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
sudo systemctl start clamav-daemon

# Test
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.txt
clamdscan /tmp/eicar.txt
# Should detect: Eicar-Test-Signature FOUND
```

## Install via Docker

```yaml
services:
  clamav:
    image: clamav/clamav:1.5                      # pin
    container_name: clamav
    restart: unless-stopped
    ports:
      - "3310:3310"                                 # TCP if scanning remotely
    volumes:
      - ./clamav-db:/var/lib/clamav                 # persist signatures across restarts
      - ./scan:/scan                                # files to scan
    environment:
      CLAMAV_NO_FRESHCLAMD: "false"
      CLAMAV_NO_CLAMD: "false"
    healthcheck:
      test: ["CMD", "clamdcheck.sh"]
      interval: 60s
      retries: 3
      start_period: 6m                              # freshclam first-run can take 5-10 min
```

**First container start is slow** — freshclam downloads ~200 MB of signatures. Don't kill it; ride it out.

## First boot / testing

```sh
# Test signature
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.txt
clamdscan --fdpass eicar.txt
# Expected: "Eicar-Test-Signature FOUND"

# Check signature DB freshness
sudo -u clamav freshclam --version
clamdscan --version
```

## Data & config layout

- `/var/lib/clamav/` — signature DB (`main.cvd`, `daily.cvd`, `bytecode.cvd`)
- `/etc/clamav/clamd.conf` — daemon config
- `/etc/clamav/freshclam.conf` — updater config
- `/var/log/clamav/` — logs
- `/var/run/clamav/clamd.ctl` — Unix socket

## Backup

Signatures are downloaded fresh on demand — **don't back them up**. Back up:

```sh
# Configs only
sudo tar czf clamav-conf-$(date +%F).tgz /etc/clamav/
```

## Upgrade

1. Releases: <https://github.com/Cisco-Talos/clamav/releases>. Active; major = 0.x → 1.x; pin.
2. Distro: `apt upgrade clamav` (Ubuntu LTS may lag behind; enable Cisco Talos PPA for bleeding edge).
3. Docker: bump image tag; first run re-downloads sigs (or persists via volume).
4. **Watch for `clamd.conf` schema changes** on major upgrades.

## Gotchas

- **RAM is significant.** clamd keeps the entire signature DB in RAM — plan on 1-2 GB resident. On a small VPS this can dominate. Don't deploy on a 512 MB box.
- **First freshclam takes time** + bandwidth (~200 MB). Container start lags; systemd start lags. Be patient; set healthcheck grace periods.
- **freshclam fair-use**: Cisco Talos enforces rate limits per IP. Don't run freshclam more than hourly. Excessive requests = IP temp-ban.
- **On-access scanner (`clamonacc`)** — can slow down file-heavy workloads dramatically. Use only on targeted directories. Not for general filesystem protection.
- **Signature DB age alerts** — `freshclam` failures silently mean stale sigs. Monitor `/var/lib/clamav/main.cvd` mtime + alert if > 24h.
- **False positives** exist — Talos daily sigs occasionally flag benign files. Build a pre-quarantine step; don't auto-delete.
- **Not a replacement for modern EDR.** ClamAV is signature-based AV — good at catching known malware, weak against novel/polymorphic threats. Pair with behavioral tools if endpoint security matters.
- **`clamav-milter`** requires Postfix/Sendmail milter config + socket perms. Read upstream doc; easy to misconfigure.
- **Integration with Nextcloud / ownCloud**: install ClamAV + Files Antivirus app; point at socket. Upload scanning = **SYNCHRONOUS** = slow on large files; configure async alternatives.
- **S3 virus scan** pattern: Lambda triggers on S3 upload → pipe file to clamd → tag object or quarantine.
- **Archive limits**: `MaxScanSize`, `MaxFileSize`, `MaxRecursion` — decompression bombs are a real threat. Don't disable; understand defaults.
- **TCP vs Unix socket**: Unix socket is faster + safer; use TCP only for remote daemons + firewall tightly.
- **Log parsing**: scan results go to `/var/log/clamav/clamav.log` + exit codes from `clamscan`. Parse for alerts.
- **SIG mirror for airgap**: run an internal CVD mirror; point freshclam at it (`DatabaseMirror` directive).
- **Windows** — ClamAV works, but most Windows users use Defender or commercial AV. Use case is specific (forensics / non-interactive servers).
- **Third-party signature sets**: SecuriteInfo / Malware Patrol / SaneSecurity — add coverage; some require paid subscriptions; fair-use terms vary.
- **License**: **GPL-2.0**. ClamAV is owned by Cisco but continues community development at github.com/Cisco-Talos/clamav.
- **Alternatives worth knowing:**
  - **Rspamd built-in heuristics** — for email, Rspamd covers much of what ClamAV-milter does; ClamAV adds signature AV layer
  - **Sophos for Linux free** — closed-source; commercial
  - **ESET NOD32** — commercial
  - **Kaspersky Endpoint Security** — commercial; geopolitical concerns in some jurisdictions
  - **CrowdStrike Falcon** — commercial EDR
  - **Wazuh** — open-source EDR; complements ClamAV (separate recipe)
  - **ClamAV + YARA rules** — power combo for custom threat hunting
  - **Microsoft Defender** — Linux support; free with M365
  - **Choose ClamAV if:** you need a free, scriptable, daemon-mode AV for pipelines / file scanning / mail servers — the de facto open-source AV.
  - **Choose a commercial EDR if:** you need behavioral detection + endpoint response.
  - **Pair ClamAV with Wazuh / OSSEC** for IDS + AV coverage.

## Links

- Repo: <https://github.com/Cisco-Talos/clamav>
- Website: <https://www.clamav.net>
- Docs: <https://docs.clamav.net>
- Installation: <https://docs.clamav.net/manual/Installing.html>
- Signatures: <https://docs.clamav.net/manual/Signatures.html>
- Releases: <https://github.com/Cisco-Talos/clamav/releases>
- Docker Hub: <https://hub.docker.com/r/clamav/clamav>
- Blog / CVEs: <https://blog.clamav.net>
- Talos mirror: <https://database.clamav.net>
- SaneSecurity 3rd-party sigs: <https://sanesecurity.com>
- Wazuh (pair): <https://wazuh.com>
