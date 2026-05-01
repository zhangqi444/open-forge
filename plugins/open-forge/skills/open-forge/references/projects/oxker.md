---
name: oxker
description: "Simple TUI to view & control Docker containers. Rust + ratatui + Bollard. mrjackwills/oxker. Docker run / cargo install / Homebrew / AUR / Nix."
---

# oxker

**A simple TUI to view & control Docker containers.** Terminal-based dashboard (ratatui) that connects to the Docker socket and shows running/stopped containers, logs, resource stats — with keyboard controls to start/stop/restart/exec into containers, filter by name, search logs, and save logs to file.

Built + maintained by **mrjackwills**. Written in Rust, uses Bollard (Docker API) and ratatui (terminal UI).

- Upstream repo: <https://github.com/mrjackwills/oxker>
- Docker Hub: <https://hub.docker.com/r/mrjackwills/oxker>
- GHCR: `ghcr.io/mrjackwills/oxker`
- crates.io: <https://crates.io/crates/oxker>
- Homebrew: `brew install oxker`
- AUR: `oxker`

## Architecture in one minute

- **Single Rust binary** — zero runtime dependencies
- Connects to **`/var/run/docker.sock`** (read-only mount when run via Docker)
- No ports, no web UI, no server — pure terminal
- Multi-arch: `linux/amd64`, `linux/arm64`, `linux/arm/v6` (Pi Zero W compatible)
- Resource: **tiny** — compiled binary, minimal RAM

## Compatible install methods

| Method             | Command                                                                                                                    | Notes                                        |
| ------------------ | -------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| **Docker (ghcr)**  | `docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock:ro --pull=always ghcr.io/mrjackwills/oxker`             | **Recommended** — no local install needed    |
| **Docker Hub**     | `docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock:ro --pull=always mrjackwills/oxker`                     | Equivalent; same image, different registry   |
| **Cargo**          | `cargo install oxker`                                                                                                      | Builds from source; requires Rust toolchain  |
| **Homebrew**       | `brew install oxker`                                                                                                       | macOS + Linux (Homebrew tap)                 |
| **AUR**            | `paru -S oxker`                                                                                                            | Arch Linux; AUR helper required              |
| **Nix**            | `nix run nixpkgs#oxker`                                                                                                    | Nix flakes; or `nix-shell -p oxker`          |
| **Pre-built**      | Download from [releases](https://github.com/mrjackwills/oxker/releases)                                                    | x86_64 one-liner in README                   |

## Inputs to collect

None. No server, no database, no domain. Just a Docker socket path if non-default (`--host`).

## Run via Docker (quickest start)

```sh
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --pull=always \
  ghcr.io/mrjackwills/oxker
```

Press `q` to quit. The container exits cleanly.

## Run with a config file

oxker supports `.toml`, `.json`, `.jsonc` config for persistent keybindings, color scheme, and settings:

```sh
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /path/to/config.toml:/config.toml:ro \
  ghcr.io/mrjackwills/oxker
```

(Inside Docker, oxker looks for config at `/` by default. Example configs in [example_config/](https://github.com/mrjackwills/oxker/tree/main/example_config).)

## Key bindings

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab` | Switch panel |
| `↑↓` / `jk` / `Home End` | Scroll selected panel (mouse wheel too) |
| `←→` | Scroll horizontally |
| `Ctrl` | Faster scroll |
| `Enter` | Run selected docker command |
| `1–9` | Sort by column heading |
| `0` | Stop sorting |
| `F1` / `/` | Filter mode |
| `#` | Log search mode |
| `-` / `=` | Shrink/grow log panel |
| `\` | Toggle log panel visibility |
| `e` | Exec into container (Linux only) |
| `i` | Container inspect mode |
| `s` | Save logs to `$HOME/<name>_<ts>.log` |
| `m` | Toggle mouse capture |
| `q` | Quit |

## CLI flags

| Flag | Effect |
|------|--------|
| `-d <ms>` | Update interval (default 1000ms) |
| `-r` | Raw logs (keep ANSI, conflicts with `-c`) |
| `-c` | Colour logs (conflicts with `-r`) |
| `-t` | Remove timestamps from logs |
| `-s` | Show the oxker container itself |
| `--host <socket>` | Custom Docker socket path |
| `--config-file <path>` | Load custom config file |
| `--save-dir <dir>` | Save logs to custom directory |
| `--timezone <tz>` | Show log timestamps in given TZ (default UTC) |
| `--use-cli` | Use Docker CLI binary for exec (instead of API) |

## Gotchas

- **Docker socket is read-only in the run command — but commands still work.** The `:ro` mount allows reads; container lifecycle commands (start/stop/restart) go via the API, not direct socket writes. If something doesn't work, try without `:ro`.
- **Exec into container is Linux-only.** The `e` key is disabled on Windows; on macOS via Docker Desktop, behaviour may vary.
- **Pi Zero W (arm/v6):** If no memory information appears, append `cgroup_enable=cpuset cgroup_enable=memory` to `/boot/cmdline.txt` (or `/boot/firmware/cmdline.txt` on newer Pi OS). Without cgroup memory, Docker resource stats are absent.
- **`--host` / `$DOCKER_HOST`**: for remote Docker hosts or non-default sockets, set either; handy for managing a remote host's containers from your laptop.
- **Config file location inside Docker**: oxker defaults to `/config.toml` inside the container (not the platform-native config dir it uses when running as a native binary). Mount accordingly.
- **`-r` and `-c` conflict.** Pick one: raw ANSI passthrough (`-r`) or oxker's own colour parsing (`-c`). Both flags together = error.
- **Not a persistent service.** oxker is a short-lived TUI session, not a daemon. For persistent container monitoring/alerting, combine with something like Uptime Kuma or Dozzle.

## Project health

Active Rust project, CI, multi-arch Docker images, Homebrew formula, AUR package, Nix package, crates.io published. Solo-maintained by mrjackwills (also author of `belugasnooze`, `mealpedant`).

## Docker-TUI-family comparison

- **oxker** — Rust, TUI, read-only socket, multi-arch, lightweight
- **Lazydocker** — Go, TUI, more features (compose support, stats), heavier
- **Dozzle** — Go, web UI (not TUI), log-streaming focus
- **Portainer** — web UI, full management, heavier stack
- **ctop** — Go, TUI, stats-only (no log search / exec)

**Choose oxker if:** you want a fast Rust TUI to glance at containers and exec in, with minimal setup and no web server.

## Links

- Repo: <https://github.com/mrjackwills/oxker>
- GHCR: `ghcr.io/mrjackwills/oxker`
- Example configs: <https://github.com/mrjackwills/oxker/tree/main/example_config>
- Lazydocker (alt): <https://github.com/jesseduffield/lazydocker>
- Dozzle (alt): <https://dozzle.dev>
