---
name: iobroker
description: ioBroker recipe for open-forge. Integration platform for the Internet of Things, focused on building automation, smart metering, ambient assisted living, and visualization. Node.js-based with a massive adapter ecosystem (800+ adapters). Source: https://github.com/ioBroker/ioBroker
---

# ioBroker

Modular IoT integration platform for building automation, smart metering, ambient assisted living, process automation, visualization, and data logging. Not a single application but a framework: ioBroker manages a set of adapters (processes) that connect to smart home devices, cloud services, and external systems and share data via a central object/state database. Node.js-based with 800+ community adapters (Zigbee, Z-Wave, MQTT, HomeKit, Alexa, KNX, Modbus, etc.). Upstream: https://github.com/ioBroker/ioBroker. Website: https://www.iobroker.net/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Installer script (Linux) | Linux | Recommended. `npx @iobroker/install` |
| Windows installer | Windows | GUI installer from ioBroker.build |
| Docker | Linux | Community Docker image available |
| Manual npm | Linux / macOS | Advanced use only |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Linux host?" | Raspberry Pi, Ubuntu, Debian — x64, ARM, ARM64 all supported |
| install | "Node.js version?" | LTS (20.x or 22.x) recommended |
| setup | "Admin port?" | Default: 8081 (ioBroker Admin web UI) |
| adapters | "Which adapters to install?" | List of smart home systems to connect |

## Software-layer concerns

### Install on Linux (recommended)

  # Prerequisites: Node.js LTS, git, curl
  # Installs ioBroker with the js-controller and admin adapter:
  npx @iobroker/install

  # Or using curl:
  curl -sLf https://iobroker.net/install.sh | bash -

  # The installer creates: /opt/iobroker/
  # Starts ioBroker as a system service automatically.

### Install on Windows

  # Download the Windows installer from:
  # https://github.com/ioBroker/ioBroker.build
  # Or run:
  mkdir C:\iobroker && cd C:\iobroker && npx @iobroker/install

### Docker (community image)

  # Community maintained image: ghcr.io/buanet/iobroker
  # Official Docker docs: https://docs.buanet.de/iobroker-docker-image/

  docker run \
    --name iobroker \
    --restart=always \
    -p 8081:8081 \
    -v /opt/iobroker:/opt/iobroker \
    ghcr.io/buanet/iobroker:latest

### Service management

  # Linux systemd service installed automatically:
  systemctl status iobroker
  systemctl start iobroker
  systemctl stop iobroker

  # Manual ioBroker CLI:
  cd /opt/iobroker
  node node_modules/iobroker.js-controller/iobroker status
  node node_modules/iobroker.js-controller/iobroker start
  node node_modules/iobroker.js-controller/iobroker stop

### Web UI

  http://<host>:8081   # Admin web interface

  # First run: Admin UI opens automatically. Follow setup wizard.
  # Language, license agreement, host info, default adapters setup.

### Install adapters

  # Via Admin UI: click "Adapters" tab, search, install.
  # Via CLI:
  cd /opt/iobroker
  node node_modules/iobroker.js-controller/iobroker add <adapter-name>
  # e.g.:
  node node_modules/iobroker.js-controller/iobroker add zigbee
  node node_modules/iobroker.js-controller/iobroker add mqtt

### Key directories

  /opt/iobroker/               # Main installation
  /opt/iobroker/iobroker-data/ # Config, objects, states database, backups
  /opt/iobroker/node_modules/  # Adapters installed here

### Databases (objects + states)

  # Default: in-memory "jsonl" file-based database
  # Production option: Redis (for states), for multi-host / high-availability setups
  # Configure in: /opt/iobroker/iobroker-data/iobroker.json

### Backup and restore

  # Built-in BackItUp adapter handles scheduled backups.
  # Manual backup:
  cd /opt/iobroker
  node node_modules/iobroker.js-controller/iobroker backup
  # Creates: /opt/iobroker/backups/<timestamp>.tar.gz

  # Restore:
  node node_modules/iobroker.js-controller/iobroker restore <backup-file>

## Upgrade procedure

  cd /opt/iobroker
  # Update js-controller:
  node node_modules/iobroker.js-controller/iobroker update
  node node_modules/iobroker.js-controller/iobroker upgrade self

  # Update all adapters:
  node node_modules/iobroker.js-controller/iobroker upgrade

  # Or use the Admin UI: Admin → Host → Update

## Gotchas

- **One process per adapter instance**: each adapter instance spawns a separate Node.js process. On Raspberry Pi (1 GB RAM), keep adapter count low to avoid OOM.
- **Not a database**: ioBroker's object/state store is lightweight in-memory/file-based by default. For multi-host setups, switch to Redis for the states DB.
- **Adapter ecosystem**: 800+ adapters exist, but quality varies. Core adapters (Admin, Zigbee, MQTT, vis-2) are well-maintained; niche ones may lag.
- **vis-2 visualization**: the primary dashboarding tool is vis-2 (graphical drag-and-drop). Complex but powerful; VIS 1.x dashboards are not compatible with vis-2.
- **Security warning**: ioBroker is designed for trusted local networks. Do NOT expose the Admin port (8081) directly to the internet. Use a VPN, Tailscale, or reverse proxy with auth.
- **Node.js version**: always use an LTS release. ioBroker may have compatibility issues with very new Node.js versions; check the compatibility matrix on the forums before upgrading Node.
- **Windows support**: fully supported via the installer, but Linux (including Raspberry Pi) is the primary deployment target for most users.

## References

- Upstream GitHub: https://github.com/ioBroker/ioBroker
- Website + documentation: https://www.iobroker.net/#en/documentation
- Adapter list: https://www.iobroker.net/#en/adapters
- Docker image (community): https://docs.buanet.de/iobroker-docker-image/
- Forum (EN/DE/RU): https://forum.iobroker.net
- Install script: https://github.com/ioBroker/ioBroker.js-controller
