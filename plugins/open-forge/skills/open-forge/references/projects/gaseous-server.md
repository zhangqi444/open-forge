---
name: gaseous-server
description: Gaseous Server recipe for open-forge. Game ROM manager with a built-in web-based emulator. Uses IGDB for metadata. Supports multiple users, ROM organization, and EmulatorJS for in-browser play. Docker Compose deployment with MariaDB. Source: https://github.com/gaseous-project/gaseous-server
---

# Gaseous Server

Game ROM manager and web-based emulator server. Organizes your ROM collection, fetches game metadata and artwork from IGDB (Internet Games Database), and provides a browser-based emulator powered by EmulatorJS. Supports multiple user accounts, collection management, and in-browser play for a wide range of console platforms. Docker Compose deployment with MariaDB backend. Upstream: https://github.com/gaseous-project/gaseous-server. Wiki: https://github.com/gaseous-project/gaseous-server/wiki.

> **Prerequisite**: a free IGDB API key (Twitch developer account). Required to fetch game metadata.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose (separate containers) | Linux | Recommended. Gaseous + MariaDB. |
| Docker (all-in-one) | Linux / Unraid | Embedded MariaDB — for systems that can't run multiple containers |
| Build from source (.NET) | Linux / macOS / Windows | .NET 7+ required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "IGDB Client ID?" | From Twitch dev console — see https://github.com/gaseous-project/gaseous-server/wiki/Metadata |
| install | "IGDB Client Secret?" | From Twitch dev console |
| install | "Database password?" | For MariaDB root and gaseous user |
| install | "Timezone?" | e.g. America/New_York |
| storage | "ROM library path?" | Host path where ROM files are stored; mounted into container |

## Software-layer concerns

### Get IGDB API credentials

  # 1. Go to https://dev.twitch.tv/ and create a developer account
  # 2. Register a new application (type: Website or Other)
  # 3. Copy the Client ID and Client Secret
  # Full instructions: https://github.com/gaseous-project/gaseous-server/wiki/Metadata

### Method 1: Docker Compose (recommended)

  mkdir gaseous && cd gaseous

  cat > docker-compose.yml << 'COMPOSE'
  version: '2'
  services:
    gaseous-server:
      container_name: gaseous-server
      image: gaseousgames/gaseousserver:latest
      restart: unless-stopped
      networks:
        - gaseous
      depends_on:
        - gsdb
      ports:
        - 5198:80
      volumes:
        - gs:/home/gaseous/.gaseous-server
        - /path/to/your/roms:/roms     # mount your ROM library here
      environment:
        - TZ=America/New_York
        - dbhost=gsdb
        - dbuser=root
        - dbpass=gaseous
        - igdbclientid=YOUR_CLIENT_ID
        - igdbclientsecret=YOUR_CLIENT_SECRET

    gsdb:
      container_name: gsdb
      image: mariadb
      restart: unless-stopped
      networks:
        - gaseous
      volumes:
        - gsdb:/var/lib/mysql
      environment:
        - MARIADB_ROOT_PASSWORD=gaseous
        - MARIADB_USER=gaseous
        - MARIADB_PASSWORD=gaseous

  networks:
    gaseous:
      driver: bridge

  volumes:
    gs:
    gsdb:
  COMPOSE

  docker-compose up -d
  # Access at: http://localhost:5198

### Method 2: All-in-one container (Unraid / single container)

  cat > docker-compose.yml << 'COMPOSE'
  version: '2'
  services:
    gaseous-server:
      container_name: gaseous-server
      image: gaseousgames/gaseousserver:latest-embeddeddb
      restart: unless-stopped
      ports:
        - 5198:80
      volumes:
        - gs:/home/gaseous/.gaseous-server
        - gsdb:/var/lib/mysql
      environment:
        - TZ=America/New_York
        - PUID=1000
        - PGID=1000
        - igdbclientid=YOUR_CLIENT_ID
        - igdbclientsecret=YOUR_CLIENT_SECRET

  volumes:
    gs:
    gsdb:
  COMPOSE

  docker-compose up -d

### Key environment variables

  TZ                  Timezone (e.g. Australia/Sydney, America/New_York)
  dbhost              MariaDB hostname (default: gsdb for compose setup)
  dbuser              MariaDB username (default: root)
  dbpass              MariaDB password
  igdbclientid        IGDB / Twitch API client ID (required)
  igdbclientsecret    IGDB / Twitch API client secret (required)
  PUID / PGID         User/group IDs (all-in-one container only)

### Key paths (inside container)

  /home/gaseous/.gaseous-server/   # App data, config, EmulatorJS files
  /roms/                           # Mount your ROM library here

### Ports

  5198/tcp   # Web UI

### First login

  # Navigate to http://localhost:5198
  # Default admin account is created on first startup.
  # Check startup logs for credentials:
  docker logs gaseous-server | grep -i "admin\|password"

### Configuration

  # Full configuration options:
  # https://github.com/gaseous-project/gaseous-server/wiki/Configuration-File
  # Config file: /home/gaseous/.gaseous-server/config.json

## Upgrade procedure

  # Important: v2+ changed the data directory from /root/.gaseous-server to
  # /home/gaseous/.gaseous-server. Update volume mounts when upgrading from v1.

  docker-compose pull
  docker-compose up -d --force-recreate

## Gotchas

- **IGDB API key required**: Gaseous cannot fetch game metadata without a valid IGDB (Twitch) API key. Register at https://dev.twitch.tv/ before deploying.
- **Data directory changed in v2**: if upgrading from v1, update your volume mapping from `/root/.gaseous-server` to `/home/gaseous/.gaseous-server` and rename the host directory accordingly.
- **ROM files are read by the server**: mount your ROM collection into the container. Gaseous scans the mounted path to build your library.
- **All-in-one not recommended**: the embedded DB image bundles an older MariaDB that won't receive timely security updates. Use the separate-container compose for anything long-term.
- **EmulatorJS in-browser emulation**: the built-in emulator runs in the browser using WebAssembly. Performance depends on the client device, not the server. Raspberry Pi as a server is fine; old mobile browsers as a client may struggle.
- **Legal responsibility**: ensure you own the ROMs you manage. Gaseous is a personal ROM manager, not a ROM distribution platform.

## References

- Upstream GitHub: https://github.com/gaseous-project/gaseous-server
- Installation wiki: https://github.com/gaseous-project/gaseous-server/wiki/Installation
- Configuration wiki: https://github.com/gaseous-project/gaseous-server/wiki/Configuration-File
- IGDB/Metadata setup: https://github.com/gaseous-project/gaseous-server/wiki/Metadata
- Releases: https://github.com/gaseous-project/gaseous-server/releases
