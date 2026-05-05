---
name: osquery
description: "SQL-powered OS instrumentation and monitoring framework — query running processes, open ports, installed packages, users, hardware, and 300+ other OS attributes as if they were database tables. Runs as a daemon (osqueryd) or interactive shell (osqueryi). Apache 2.0."
---

# osquery

**What it is:** A framework that exposes your operating system as a high-performance relational database. You write SQL queries to explore OS state: running processes, logged-in users, open network connections, kernel modules, browser extensions, hardware events, file hashes, and more — across Linux, macOS, and Windows. Used for security monitoring, compliance, incident response, and fleet visibility.

**Official site:** https://osquery.io
**Docs:** https://osquery.readthedocs.io
**GitHub:** https://github.com/osquery/osquery
**License:** Apache 2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (deb/rpm) | Native package | Ubuntu, Debian, RHEL, CentOS, Fedora |
| macOS | PKG installer | x86_64 and arm64 |
| Windows | MSI installer | Windows 10/Server 2016+ |
| Docker | `osquery/osquery` image | Query container or host (with volume mounts) |
| Fleet / kolide / fleetdm | Managed daemon | Centralized query across many hosts |

---

## Inputs to Collect

### Daemon config (`osquery.conf`)
- `schedule` — map of named SQL queries run on a timer (results written to log)
- `options.logger_path` — directory for result and snapshot logs (default `/var/log/osquery`)
- `options.database_path` — RocksDB state dir (default `/var/osquery/osquery.db`)
- `options.disable_events` — set `false` to enable file/process/socket event monitoring

### Optional (for fleet enrollment)
- `--tls_hostname` — Fleet/TLS server hostname
- `--enroll_secret_path` — path to enrollment secret file
- `--config_plugin=tls` — fetch config from Fleet server instead of local file

---

## Software-Layer Concerns

### Key binaries
| Binary | Purpose |
|--------|---------|
| `osqueryd` | Background daemon; runs scheduled queries, logs results |
| `osqueryi` | Interactive SQL shell for ad-hoc queries |
| `osqueryctl` | Helper script to start/stop/configure the daemon |

### Config paths (Linux)
```
/etc/osquery/osquery.conf          # main config
/etc/osquery/osquery.conf.d/       # config fragments
/var/log/osquery/                  # result logs, snapshot logs
/var/osquery/osquery.db/           # RocksDB state
/var/osquery/osquery.pidfile       # daemon PID
```

### Log formats
- **result log** — differential changes (added/removed rows) from scheduled queries
- **snapshot log** — full result set on each run (set `"snapshot": true` on a query)

---

## Installation

### Linux (Ubuntu/Debian)
```bash
# Add osquery GPG key and repo
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
sudo add-apt-repository "deb [arch=amd64] https://pkg.osquery.io/deb deb main"
sudo apt update && sudo apt install osquery

# Start daemon
sudo systemctl enable --now osqueryd

# Interactive shell
osqueryi
```

### Linux (RPM)
```bash
curl -L https://pkg.osquery.io/rpm/GPG | sudo tee /etc/pki/rpm-gpg/RPM-GPG-KEY-osquery
sudo yum-config-manager --add-repo https://pkg.osquery.io/rpm/osquery-s3-rpm.repo
sudo yum install osquery
sudo systemctl enable --now osqueryd
```

### Docker (ad-hoc queries against host)
```bash
docker run --rm -it \
  --pid=host --net=host \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  osquery/osquery osqueryi
```

---

## Example Queries

```sql
-- Processes listening on all interfaces
SELECT DISTINCT processes.name, listening_ports.port, processes.pid
FROM listening_ports JOIN processes USING (pid)
WHERE listening_ports.address = '0.0.0.0';

-- Recently modified files in /etc
SELECT path, mtime, size FROM file
WHERE path LIKE '/etc/%' AND mtime > (strftime('%s','now') - 3600);

-- Installed packages (Debian/Ubuntu)
SELECT name, version, install_time FROM deb_packages ORDER BY install_time DESC LIMIT 20;

-- Users with login shell
SELECT username, uid, gid, shell FROM users WHERE shell NOT LIKE '%nologin%';

-- Cron jobs
SELECT * FROM crontab;
```

---

## Daemon Config Example

```json
{
  "options": {
    "logger_path": "/var/log/osquery",
    "disable_logging": false,
    "schedule_splay_percent": 10
  },
  "schedule": {
    "system_info": {
      "query": "SELECT hostname, cpu_brand, physical_memory FROM system_info;",
      "interval": 3600
    },
    "listening_ports": {
      "query": "SELECT pid, port, protocol, address FROM listening_ports;",
      "interval": 300,
      "snapshot": true
    }
  }
}
```

---

## Upgrade Procedure

```bash
# Debian/Ubuntu
sudo apt update && sudo apt install --only-upgrade osquery
sudo systemctl restart osqueryd

# RPM
sudo yum update osquery
sudo systemctl restart osqueryd
```

---

## Gotchas

- **Not a server app** — osquery runs as a local daemon or CLI tool on each host; there is no central UI bundled with it. For fleet-wide management, pair with Fleet (fleetdm/fleet) or Kolide.
- **Root required** — `osqueryd` must run as root to access most OS tables; `osqueryi` can run as non-root but many tables will be empty.
- **Event-based tables need `disable_events=false`** — Tables like `process_events`, `file_events`, and `socket_events` require event collection to be enabled in config.
- **RocksDB corruption** — If osqueryd crashes mid-write, the RocksDB state can corrupt. Delete `/var/osquery/osquery.db` to recover (state is rebuilt automatically).
- **Performance** — Complex queries with large `file` table scans (e.g. entire filesystem hashes) can be CPU/IO intensive. Keep scheduled query intervals reasonable.
- **Table availability varies by OS** — Not all tables exist on all platforms. Check https://osquery.io/schema for per-platform availability.

---

## Links
- GitHub: https://github.com/osquery/osquery
- Documentation: https://osquery.readthedocs.io
- Table schema reference: https://osquery.io/schema
- Downloads: https://osquery.io/downloads
- Fleet integration: https://fleetdm.com
