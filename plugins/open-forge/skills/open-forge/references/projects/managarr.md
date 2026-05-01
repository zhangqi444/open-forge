# Managarr

**Terminal UI (TUI) and CLI for managing your \*arr stack — Radarr, Sonarr, and Lidarr support, built in Rust. Manage your HTPC from the terminal.**
GitHub: https://github.com/Dark-Alex-17/managarr
Demo site: https://managarr-demo.alexjclarke.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker (interactive) | Mount config.yml |
| Any Linux | Cargo (binary) | `cargo install managarr` |
| macOS / Linux | Homebrew | `brew install Dark-Alex-17/managarr/managarr` |
| Windows | Chocolatey | `choco install managarr` |
| NixOS | Nix | `nix-env --install managarr` |

---

## Inputs to Collect

### Required (per Servarr instance)
- `host` or `uri` — address of the Servarr instance
- `port` — default: Radarr 7878, Sonarr 8989, Lidarr 8686
- `api_token` — API key from the Servarr instance settings

---

## Software-Layer Concerns

### Configuration file
Find the default config path for your OS:
```bash
managarr config-path
```

### Example config.yml
```yaml
theme: default
radarr:
  - host: 192.168.0.78
    port: 7878
    api_token: your-radarr-api-token

sonarr:
  - host: 192.168.0.78
    port: 8989
    api_token: your-sonarr-api-token

lidarr:
  - host: 192.168.0.78
    port: 8686
    api_token: your-lidarr-api-token
```

Multiple instances of the same Servarr are supported (add more list entries).

### Docker (interactive TTY required)
```bash
docker run --rm -it \
  -v /home/user/.config/managarr/config.yml:/root/.config/managarr/config.yml \
  darkalex17/managarr:latest
```

### Multiple config files
```bash
managarr --config-file /path/to/config.yml
```

### Supported Servarrs
- ✅ Radarr
- ✅ Sonarr
- ✅ Lidarr
- 🔄 Readarr, Prowlarr, Bazarr, Whisparr (in progress)

---

## Upgrade Procedure

- Cargo: `cargo install managarr`
- Homebrew: `brew upgrade managarr`
- Docker: pull latest tag and re-run

---

## Gotchas

- Docker requires `-it` (interactive + TTY) — it's a terminal UI, not a daemon
- Config file must exist before starting the Docker container or it will fail
- Use absolute paths for Docker volume mounts if relative paths cause errors
- Demo available before connecting to your real stack: run the demo script or visit the demo site

---

## References
- Demo: https://managarr-demo.alexjclarke.com
- GitHub: https://github.com/Dark-Alex-17/managarr#readme
