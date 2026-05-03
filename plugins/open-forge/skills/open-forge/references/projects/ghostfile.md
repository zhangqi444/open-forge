---
name: ghostfile-project
description: Lightweight one-time ephemeral file upload server that shuts down after handling an upload. CLI and GUI modes. Upstream: https://github.com/jon6fingrs/ghostfile
---

# GhostFile

Lightweight, one-time file upload server that automatically shuts down after handling an upload. Designed for quick, ephemeral file transfers. Distributed as a single self-contained binary; supports CLI mode (terminal) and GUI mode (desktop environment). Upstream: <https://github.com/jon6fingrs/ghostfile>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Pre-built binary | [GitHub dist/](https://github.com/jon6fingrs/ghostfile/tree/main/dist) | ✅ | Recommended — no dependencies |
| Source build | [GitHub](https://github.com/jon6fingrs/ghostfile) | ✅ | Development |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| config | Upload directory path | path | All |
| config | Host to bind (default `0.0.0.0`) | string | CLI |
| config | Port (default `5000`) | number | CLI |

## Binary install

Source: <https://github.com/jon6fingrs/ghostfile>

**Intel (x86_64):**
```bash
wget -O ghostfile https://raw.githubusercontent.com/jon6fingrs/ghostfile/main/dist/ghostfile
chmod +x ghostfile
sudo mv ghostfile /usr/local/bin/
```

**ARM64:**
```bash
wget -O ghostfile https://raw.githubusercontent.com/jon6fingrs/ghostfile/main/dist/ghostfile-arm64
chmod +x ghostfile
sudo mv ghostfile /usr/local/bin/
```

## Usage

**CLI mode (from terminal):**
```bash
# Default: binds 0.0.0.0:5000, uploads to ./downloads/
ghostfile

# Custom options:
ghostfile --dir /path/to/upload --host 127.0.0.1 --port 8080 --gui false
```

Press `Ctrl+C` to shut down gracefully.

**GUI mode:** launch from a desktop environment (double-click or desktop launcher). A window opens to configure directory, host, and port with a live log window.

Force mode: `--gui true` or `--gui false`.

## Configuration

| Flag | Default | Description |
|---|---|---|
| `--dir` | `./downloads` (or cwd) | Upload destination directory |
| `--host` | `0.0.0.0` | Network interface to bind |
| `--port` | `5000` | Port to listen on |
| `--gui` | auto-detect | Force CLI (`false`) or GUI (`true`) |

## Upgrade procedure

Download a new binary from [dist/](https://github.com/jon6fingrs/ghostfile/tree/main/dist) and replace the existing one.

## Gotchas

- Server **exits after one upload** — this is by design for ephemeral transfers.
- Primarily tested on Linux; Windows and macOS may work but are not officially tested.
- ARM64 testing is limited — report issues upstream.
- No Docker image in upstream README.

## References

- GitHub: <https://github.com/jon6fingrs/ghostfile>
- Dist folder: <https://github.com/jon6fingrs/ghostfile/tree/main/dist>
