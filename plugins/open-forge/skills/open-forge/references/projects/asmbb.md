---
name: asmbb
description: AsmBB recipe for open-forge. Fast, SQLite-powered forum engine written in x86 Assembly. EUPL-1.2. Source: https://asm32.info/fossil/asmbb/index
---

# AsmBB

A fast, lightweight forum engine written in x86 Assembly language (FASM), powered by SQLite. No dependencies beyond the OS — the entire forum is a single self-contained binary. Serves pages extremely fast with minimal CPU and memory usage. EUPL-1.2 licensed. Forum demo: <https://board.asm32.info>. Upstream (Fossil): <https://asm32.info/fossil/asmbb/index>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux x86/x86_64 | Native binary (FastCGI) | Pre-built binary via NGINX/Apache FastCGI |
| Linux x86/x86_64 | Native binary (standalone) | Minimal standalone HTTP mode |

> ⚠️ **x86 only**: AsmBB is written in x86 Assembly — runs only on x86/x86_64 Linux. Not compatible with ARM (Raspberry Pi), RISC-V, etc.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for the forum?" | FQDN | e.g. forum.example.com |
| "Forum name and description?" | strings | Set during initial configuration |
| "Admin username and password?" | string + secret | First admin account |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache | For FastCGI integration |
| "SQLite data directory?" | Path | Where the forum database is stored — must be persistent |

## Software-Layer Concerns

- **Single binary**: The entire forum is one compiled x86 binary + SQLite file. No PHP, no Python, no Node.js.
- **FastCGI**: AsmBB communicates with NGINX or Apache via FastCGI. The binary acts as a FastCGI application server.
- **SQLite**: All forum data in a single `.db` file — easy to backup (`cp forum.db forum.db.bak`).
- **x86 only**: Written in FASM (flat assembler) for x86 architecture. Will not run on ARM, RISC-V, or other architectures.
- **Fossil SCM**: Source hosted on Fossil (asm32.info), not GitHub. Use Fossil tools to clone/update.
- **Extremely lightweight**: Memory footprint measured in kilobytes — can run on very modest hardware.
- **No dependencies**: Statically linked binary — no shared library requirements beyond the Linux kernel.

## Deployment

### Download and install

```bash
# Download latest release from:
# https://asm32.info/fossil/asmbb/wiki?name=Download
# (check upstream wiki for current download link)

# Extract and place binary
mkdir -p /opt/asmbb
cd /opt/asmbb
# extract asmbb archive here

# Create data directory
mkdir -p /var/lib/asmbb
chown www-data:www-data /var/lib/asmbb
```

### NGINX + FastCGI

```nginx
server {
    listen 443 ssl;
    server_name forum.example.com;
    root /opt/asmbb/www;

    location / {
        fastcgi_pass unix:/run/asmbb.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

Start AsmBB FastCGI process:
```bash
/opt/asmbb/asmbb --fcgi /run/asmbb.sock --data /var/lib/asmbb/
```

See upstream wiki for full setup guide: https://asm32.info/fossil/asmbb/wiki

## Upgrade Procedure

1. Download new release binary from upstream.
2. Stop AsmBB process.
3. Replace binary.
4. Restart — SQLite database persists.
5. Check upgrade notes on the upstream wiki for any data migration steps.

## Gotchas

- **x86 only**: Cannot run on ARM (Raspberry Pi), cloud ARM instances, or any non-x86 architecture.
- **Niche technology**: Assembly-language forum engine — debugging issues requires comfort with low-level tooling.
- **Fossil SCM**: Source and releases hosted on Fossil, not GitHub/GitLab.
- **FastCGI socket permissions**: The socket must be accessible by both AsmBB and the web server (NGINX/Apache) user.
- **Backup = copy SQLite file**: Backup by copying the `.db` file while AsmBB is stopped, or use SQLite's `.backup` command for online backup.

## Links

- Upstream (Fossil): https://asm32.info/fossil/asmbb/index
- Wiki / download: https://asm32.info/fossil/asmbb/wiki
- Live forum demo: https://board.asm32.info
