---
name: bin
description: bin recipe for open-forge. Minimalist pastebin written in Rust. No database, no comments, no social features — just fast, simple text snippet sharing with syntax highlighting and curl support. Source: https://github.com/w4/bin
---

# bin

A paste bin that's actually minimalist. Written in Rust in ~300 lines of code. In-memory rotating store — no database, no persistence required. Provides syntax highlighting, curl support for CLI paste/retrieve, and nothing else. Upstream: https://github.com/w4/bin. Live instance: https://bin.gy/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Prebuilt binary | Linux (x86_64) | Download from GitHub Releases and run directly. |
| Cargo (source build) | Rust toolchain | `cargo build --release` |
| Nix | Nix / NixOS | `nix-shell` provides the build environment. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Bind address and port?" | Default: 127.0.0.1:8820 — change to 0.0.0.0:8820 to listen on all interfaces |
| setup | "Buffer size?" | Max number of pastes before oldest are rotated out. Default: 1000 |
| setup | "Max paste size?" | Default: 32KB. Increase if you need larger pastes. |

## Software-layer concerns

### Prebuilt binary

  # Download latest release
  curl -L https://github.com/w4/bin/releases/latest/download/bin-x86_64-unknown-linux-musl \
    -o /usr/local/bin/bin
  chmod +x /usr/local/bin/bin

  # Run (default: listens on 127.0.0.1:8820)
  bin

  # Run on all interfaces, port 8080, with custom limits:
  bin 0.0.0.0:8080 --buffer-size 2000 --max-paste-size 65536

### Source build

  # Requires Rust toolchain (rustup)
  git clone https://github.com/w4/bin.git
  cd bin
  cargo build --release
  ./target/release/bin 0.0.0.0:8820

### All options

  Usage: bin [<bind_addr>] [--buffer-size <buffer-size>] [--max-paste-size <max-paste-size>]

    bind_addr         socket address to bind to (default: 127.0.0.1:8820)
    --buffer-size     max pastes to store before rotating (default: 1000)
    --max-paste-size  max paste size in bytes (default: 32768 / 32kB)

### systemd service

  # /etc/systemd/system/bin-paste.service
  [Unit]
  Description=bin pastebin
  After=network.target

  [Service]
  ExecStart=/usr/local/bin/bin 0.0.0.0:8820 --buffer-size 5000
  Restart=on-failure
  User=nobody

  [Install]
  WantedBy=multi-user.target

  systemctl enable --now bin-paste

### CLI usage (curl API)

  # Create a paste:
  curl -X PUT --data 'hello world' https://your-bin-host/
  # Returns: https://your-bin-host/abc123

  # Retrieve a paste:
  curl https://your-bin-host/abc123

  # Pipe command output:
  cat file.txt | curl -X PUT --data-binary @- https://your-bin-host/

### Reverse proxy (nginx)

  location / {
    proxy_pass http://127.0.0.1:8820;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }

## Upgrade procedure

  # Download new binary from GitHub Releases, replace old binary, restart service.
  systemctl restart bin-paste

## Gotchas

- **In-memory only, no persistence**: pastes are stored in memory. They are lost on restart and rotated out when buffer-size is reached. Do not use if you need permanent storage.
- **No authentication**: anyone who can reach the service can create pastes. Put behind a VPN, basic auth, or firewall rule if you want to restrict access.
- **No deletion**: there is no delete endpoint. Pastes expire only by being rotated out of the buffer.
- **Bind address**: default 127.0.0.1 means only localhost. Change to 0.0.0.0 to accept external connections (and put a reverse proxy in front).
- **License WTFPL/0BSD**: effectively public domain — use however you like.

## References

- Upstream GitHub: https://github.com/w4/bin
- Live instance: https://bin.gy/
