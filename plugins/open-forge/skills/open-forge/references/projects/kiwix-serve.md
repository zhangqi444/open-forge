---
name: kiwix-serve
description: kiwix-serve recipe for open-forge. HTTP daemon for serving offline wikis (Wikipedia, WikiBooks, etc.) from ZIM archive files. Part of kiwix-tools. Available as Docker image or native binary. Source: https://github.com/kiwix/kiwix-tools
---

# kiwix-serve

HTTP daemon for serving offline content — primarily Wikipedia and other Wikimedia/Kiwix ZIM archive files — over a local or LAN web interface. Part of the kiwix-tools collection. Point it at one or more `.zim` files and it presents a searchable, browser-accessible library. Ideal for offline/low-connectivity environments, schools, and homelab reference servers. Upstream: https://github.com/kiwix/kiwix-tools. Official Docker image: `ghcr.io/kiwix/kiwix-serve`. ZIM file library: https://download.kiwix.org/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (ghcr.io/kiwix/kiwix-serve) | Linux | Recommended; no compilation needed |
| Docker (ghcr.io/kiwix/kiwix-tools) | Linux | Full kiwix-tools suite |
| Native binary / package manager | Debian/Ubuntu/Fedora | `apt install kiwix-tools` |
| Compile from source | Linux / macOS | Requires libkiwix, libzim |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| data | "ZIM file(s) directory?" | Local path to folder containing .zim files |
| port | "Port to expose?" | Default: 8080 |
| auth | "Enable authentication?" | Optional; kiwix-serve supports basic auth via --userAuth |

## Software-layer concerns

### Method 1: Docker (recommended)

  docker run -d \
    --name kiwix-serve \
    -p 8080:8080 \
    -v /data/zim:/data \
    ghcr.io/kiwix/kiwix-serve \
    --port 8080 \
    /data

  # /data/zim — directory on host containing your .zim files
  # kiwix-serve scans the directory and serves all .zim files found

### docker-compose.yml

  version: "3"
  services:
    kiwix-serve:
      image: ghcr.io/kiwix/kiwix-serve:latest
      container_name: kiwix-serve
      restart: unless-stopped
      ports:
        - "8080:8080"
      volumes:
        - /data/zim:/data
      command: --port 8080 /data

### Method 2: Native install (Debian/Ubuntu)

  sudo apt install kiwix-tools

  # Serve a single ZIM file:
  kiwix-serve --port 8080 /path/to/wikipedia_en_all_maxi.zim

  # Serve an entire directory of ZIM files:
  kiwix-serve --port 8080 /data/zim/

  # Or use a library XML file:
  kiwix-manage /data/library.xml add /data/zim/wikipedia_en_all_maxi.zim
  kiwix-serve --port 8080 --library /data/library.xml

### CLI flags

  --port <port>          HTTP port (default 80)
  --address <ip>         Bind address (default 0.0.0.0)
  --library <file>       XML library file (for multi-book setups)
  --threads <n>          Worker threads (default 4)
  --userAuth <user:pass> Enable HTTP Basic Auth
  --nodatealias          Disable date-based URL aliases
  --verbose              Verbose logging

### Systemd unit (native install)

  [Unit]
  Description=Kiwix Serve
  After=network.target

  [Service]
  ExecStart=/usr/bin/kiwix-serve --port 8080 /data/zim/
  Restart=on-failure
  User=kiwix

  [Install]
  WantedBy=multi-user.target

### Ports

  8080/tcp   # Web UI and content server (configurable)

### Reverse proxy (nginx)

  location / {
      proxy_pass http://127.0.0.1:8080;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
  }

## ZIM files

  # Download from the official Kiwix library:
  # https://download.kiwix.org/zim/
  #
  # Example — download a Wikipedia ZIM (mini version):
  wget https://download.kiwix.org/zim/wikipedia/wikipedia_en_wp10_2024-11.zim -P /data/zim/
  #
  # Sizes vary: from ~100 MB (topic-specific) to >100 GB (Wikipedia all + images)

## Upgrade procedure

  # Docker:
  docker pull ghcr.io/kiwix/kiwix-serve:latest
  docker restart kiwix-serve

  # Native:
  sudo apt update && sudo apt upgrade kiwix-tools

## Gotchas

- **ZIM files can be huge**: Full English Wikipedia with images is >100 GB. Start with a smaller topical ZIM to test. Check available disk before downloading.
- **No authentication by default**: kiwix-serve is open to anyone who can reach its port. Add `--userAuth user:pass` or put it behind a reverse proxy with auth if exposing beyond localhost.
- **Docker image is kiwix/kiwix-serve**: There are two images — `kiwix-tools` (full suite) and `kiwix-serve` (server only). Either works.
- **Directory vs library XML**: Pointing at a directory is simplest. A `library.xml` (managed via `kiwix-manage`) is needed for advanced multi-book management with custom metadata.
- **Compilation from source**: Requires `libkiwix` and `libzim` which are not always packaged. Use the Docker image unless you need a custom build.
- **Port 80 requires root**: If running natively on port 80, the process needs CAP_NET_BIND_SERVICE or run as root. Use port 8080+ and reverse-proxy instead.

## References

- Upstream GitHub: https://github.com/kiwix/kiwix-tools
- Docker image (kiwix-serve): https://ghcr.io/kiwix/kiwix-serve
- Docker image (kiwix-tools): https://ghcr.io/kiwix/kiwix-tools
- ZIM file library: https://download.kiwix.org/zim/
- Kiwix website: https://kiwix.org
