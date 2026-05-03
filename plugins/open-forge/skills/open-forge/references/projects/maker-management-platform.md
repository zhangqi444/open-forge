---
name: maker-management-platform-project
description: Self-hosted 3D model library manager with STL rendering, metadata, and slicer integration. Upstream: https://github.com/Maker-Management-Platform
---

# Maker Management Platform (MMP)

Self-hosted 3D model library manager. Organises STL files with automatic 3D thumbnail rendering, metadata, and slicer integration. Two-container setup: an `agent` (backend) and a `ui` (frontend). Upstream: <https://github.com/Maker-Management-Platform>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [Docs repo](https://github.com/Maker-Management-Platform/docs) | ✅ | Recommended |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| config | Path to your 3D model library | path | All |
| config | Path for persistent application data | path | All |
| config | Thingiverse token (optional, for imports) | string | Optional |
| config | Max render workers (≤ CPU cores, default 5) | number | All |

## Docker Compose install

Source: <https://github.com/Maker-Management-Platform/docs>

```yaml
version: "3.6"
services:
  agent:
    image: ghcr.io/maker-management-platform/agent:main
    container_name: agent
    volumes:
      - ./library:/library
      - ./data:/data
    ports:
      - 8000:8000
    restart: unless-stopped

  ui:
    image: ghcr.io/maker-management-platform/mmp-ui:master
    container_name: ui
    ports:
      - 8083:8081
    environment:
      - "AGENT_ADDRESS=agent:8000"
    restart: unless-stopped
```

## Configuration (agent)

Config file (TOML) or environment variables:

| Key | Default | Description |
|---|---|---|
| `port` | `8000` | Backend API port |
| `server_hostname` | `localhost` | Hostname |
| `library_path` | `/library` | Path to 3D model library |
| `max_render_workers` | `5` | Parallel STL renderers (≤ CPU cores) |
| `file_blacklist` | `[]` | File extensions to ignore |
| `model_render_color` | `#167DF0` | 3D model render colour |
| `model_background_color` | `#FFFFFF` | Render background colour |
| `thingiverse_token` | `` | Token for Thingiverse imports |

Volumes:
- `/library` — your STL file library
- `/data` — persistent agent data

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Port 8000 on the agent is currently required for slicer integration — do not change it without also updating your slicer config.
- UI `AGENT_ADDRESS` must point to the internal Docker service name (`agent:8000`), not the host-exposed port.
- `max_render_workers` should not exceed your available CPU cores.

## References

- GitHub org: <https://github.com/Maker-Management-Platform>
- Agent: <https://github.com/Maker-Management-Platform/agent>
- UI: <https://github.com/Maker-Management-Platform/mmp-ui>
- Docs: <https://github.com/Maker-Management-Platform/docs>
- Discord: <https://discord.gg/SqxKE3Ve4Z>
