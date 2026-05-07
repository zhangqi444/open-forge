---
name: RconCli
description: CLI tool for executing RCON commands on remote Valve Source dedicated game servers. Supports Minecraft, ARK, Rust, CS:GO, Factorio, Palworld, and more. MIT licensed.
website: https://github.com/gorcon/rcon-cli
source: https://github.com/gorcon/rcon-cli
license: MIT
stars: 655
tags:
  - gaming
  - rcon
  - cli
  - game-server
platforms:
  - Go
  - Docker
---

# RconCli

RconCli is a command-line tool for sending RCON (Remote Console) commands to game servers that support the Valve Source RCON protocol. Supports a wide range of games including Minecraft, ARK, Rust, CS:GO, Factorio, Palworld, Project Zomboid, and more. Also supports Telnet and WebSocket RCON variants.

Source: https://github.com/gorcon/rcon-cli  
Docker Hub: https://hub.docker.com/r/outdead/rcon  
Latest release: check https://github.com/gorcon/rcon-cli/releases/latest

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / macOS / Windows | Native binary | Download from releases page |
| Any Linux | Docker | `outdead/rcon` image |
| Any Linux | Build from source (Go 1.21+) | `go install` |

## Inputs to Collect

**Phase: Planning**
- Game server address and RCON port (e.g., `127.0.0.1:25575` for Minecraft)
- RCON password
- Connection type: `rcon` (default), `telnet` (7 Days to Die), or `web` (Rust)

## Software-Layer Concerns

**Install binary:**
```bash
# Download from releases
wget https://github.com/gorcon/rcon-cli/releases/latest/download/rcon-cli_linux_amd64.tar.gz
tar -xzf rcon-cli_linux_amd64.tar.gz
sudo mv rcon /usr/local/bin/rcon
```

**Docker:**
```bash
docker pull outdead/rcon
docker run --rm outdead/rcon -a 192.168.1.100:25575 -p RCON_PASSWORD "help"
```

**Build from source:**
```bash
go install github.com/gorcon/rcon-cli/cmd/rcon@latest
```

**Basic usage:**
```bash
# Single command
rcon -a 127.0.0.1:25575 -p RCON_PASSWORD "list"

# Interactive mode (REPL)
rcon -a 127.0.0.1:25575 -p RCON_PASSWORD

# Telnet mode (7 Days to Die)
rcon -a 127.0.0.1:8081 -p RCON_PASSWORD -t telnet "help"

# WebSocket mode (Rust)
rcon -a 127.0.0.1:28016 -p RCON_PASSWORD -t web "status"
```

**Config file (`rcon.yaml`):**
```yaml
default:
  address: "127.0.0.1:25575"
  password: "CHANGE_ME"
  log: "rcon-default.log"
  type: "rcon"
  timeout: "10s"

minecraft:
  address: "mc.example.com:25575"
  password: "CHANGE_ME"
  log: "rcon-minecraft.log"
  type: "rcon"

rust:
  address: "rust.example.com:28016"
  password: "CHANGE_ME"
  type: "web"
```

```bash
# Use named environment from config
rcon -e minecraft "list"
rcon -e rust "status"
```

**Supported games:**
- Minecraft (`25575`)
- ARK: Survival Evolved (`27020`)
- Rust (`28016`, type: web)
- CS:GO (`27015`)
- Factorio (`27015`)
- Project Zomboid (`16261`)
- Palworld (`25575`)
- Conan Exiles (`25575`)
- 7 Days to Die (`8081`, type: telnet)
- V Rising, Team Fortress 2, Avorion, and more

## Upgrade Procedure

1. Download new binary from https://github.com/gorcon/rcon-cli/releases/latest
2. Replace existing binary: `sudo mv rcon /usr/local/bin/rcon`
3. Or: `docker pull outdead/rcon`

## Gotchas

- **RCON must be enabled on the game server**: Each game has its own RCON enable setting — check game-specific docs
- **Rust WebSocket RCON**: Rust uses WebSocket-based RCON, not standard Source RCON — use `-t web`
- **7 Days to Die Telnet**: Uses Telnet, not RCON — use `-t telnet`
- **Firewall**: RCON ports should never be exposed publicly — bind to `127.0.0.1` or firewall to trusted IPs only
- **Log files**: Each session can be logged to a file via `-l` flag or config — useful for audit trails on shared servers
- **Interactive mode**: Running `rcon` without a command argument enters interactive REPL mode for ongoing server administration

## Links

- Upstream README: https://github.com/gorcon/rcon-cli/blob/master/README.md
- Releases: https://github.com/gorcon/rcon-cli/releases
- Docker Hub: https://hub.docker.com/r/outdead/rcon
- Changelog: https://github.com/gorcon/rcon-cli/blob/master/CHANGELOG.md
