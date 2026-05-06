# MTA:SA (Multi Theft Auto: San Andreas)

MTA:SA adds network multiplayer functionality to Grand Theft Auto: San Andreas. It uses code injection and Lua scripting to turn the single-player game into a multiplayer platform supporting hundreds of concurrent players, custom game modes, and community-created resources.

**Website:** https://multitheftauto.com/
**Source:** https://github.com/multitheftauto/mtasa-blue
**License:** GPL-3.0
**Stars:** ~1,744

> ⚠️ **Requires GTA:SA**: The client requires an original copy of Grand Theft Auto: San Andreas. This server component is open source; the game itself is proprietary.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS (x86_64) | Native binary | Official supported platform |
| Linux VPS (arm64) | Native binary (experimental) | Unstable, may crash |
| Windows Server | Native binary | Official supported platform |
| Linux | Docker (community) | Unofficial images available |

---

## Inputs to Collect

### Phase 1 — Planning
- Server name (displayed in server browser)
- Max player count
- Server port (default: 22003 UDP)
- HTTP port for resource downloads (default: 22005)
- ASE/master server listing (optional — registers with public server browser)
- Admin password
- Server password (if private server)

### Phase 2 — Deployment
- `servername`: display name
- `maxplayers`: max concurrent connections
- `port`: UDP game port
- `httpport`: HTTP resource download port
- `password`: server password (leave blank for public)
- `ase`: 1 to register with public master list

---

## Software-Layer Concerns

### Linux Server Installation

```bash
# Download the latest Linux server package from:
# https://nightly.multitheftauto.com/ (nightly) or
# https://www.multitheftauto.com/downloads.html (stable release)

# Example for Ubuntu/Debian:
wget https://nightly.multitheftauto.com/files/multitheftauto_linux_x64.tar.gz
tar -xzf multitheftauto_linux_x64.tar.gz
cd multitheftauto_linux_x64/

# Run the server
./mta-server64
```

### Directory Structure
```
multitheftauto_linux_x64/
├── mods/
│   └── deathmatch/
│       ├── mtaserver.conf   # Main server config
│       ├── acl.xml          # Access control list
│       ├── banlist.xml      # Bans
│       └── resources/       # Game modes and scripts
├── mta-server64             # Server binary
└── logs/                    # Server logs
```

### Server Config (`mods/deathmatch/mtaserver.conf`)
```xml
<config>
  <servername>My MTA:SA Server</servername>
  <serverport>22003</serverport>
  <httpport>22005</httpport>
  <maxplayers>32</maxplayers>
  <password></password>
  <ase>1</ase>
  <adminpass>yourAdminPassword</adminpass>
  <logfile>logs/server.log</logfile>
  <fpslimit>100</fpslimit>
</config>
```

### Firewall Rules
```bash
# UDP for game traffic
ufw allow 22003/udp

# TCP for HTTP resource downloads
ufw allow 22005/tcp
```

### Resources (Game Modes)
Resources are the core unit of content — each is a ZIP or folder containing Lua scripts and assets:
```bash
# Place resources in mods/deathmatch/resources/
# Start a resource from the server console:
start <resource_name>

# Or add to mtaserver.conf:
<resource src="freeroam" startup="1" protected="0"/>
```

Community resources: https://community.multitheftauto.com/index.php?p=resources

### Running as a Service (systemd)
```ini
[Unit]
Description=MTA:SA Game Server
After=network.target

[Service]
Type=simple
User=mta
WorkingDirectory=/opt/mtasa
ExecStart=/opt/mtasa/mta-server64
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

---

## Upgrade Procedure

```bash
# Back up your config and resources
cp -r mods/deathmatch/resources/ ~/resources-backup/
cp mods/deathmatch/mtaserver.conf ~/mtaserver.conf.bak
cp mods/deathmatch/acl.xml ~/acl.xml.bak

# Download and extract new version
wget https://nightly.multitheftauto.com/files/multitheftauto_linux_x64.tar.gz
tar -xzf multitheftauto_linux_x64.tar.gz

# Copy your resources and config into new installation
cp -r ~/resources-backup/ multitheftauto_linux_x64/mods/deathmatch/resources/
cp ~/mtaserver.conf.bak multitheftauto_linux_x64/mods/deathmatch/mtaserver.conf
```

---

## Gotchas

- **GTA:SA required on clients**: Players must own and install GTA:SA before connecting. The MTA:SA client mod is free but the base game is not.
- **UDP port**: The game uses UDP (not TCP) for gameplay; ensure your firewall allows UDP on the game port.
- **arm64 experimental**: ARM support is unstable — use x86_64 for production servers.
- **Resource sync**: Clients auto-download resources from the server's HTTP port on connect; ensure port 22005 (TCP) is open.
- **ACL management**: The `acl.xml` file controls what scripts and players can do. Misconfigured ACL can allow server-side exploits via Lua scripts.
- **Lua sandboxing**: All server-side scripts run in a Lua environment; vet community resources before installing them.

---

## Links
- Downloads: https://www.multitheftauto.com/downloads.html
- Nightly Builds: https://nightly.multitheftauto.com/
- Wiki / Scripting Docs: https://wiki.multitheftauto.com/
- Community Resources: https://community.multitheftauto.com/index.php?p=resources
- Discord: https://discord.com/invite/mtasa
