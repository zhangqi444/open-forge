---
name: enigma-12-bbs
description: ENiGMA½ BBS recipe for open-forge. Modern multi-platform BBS (Bulletin Board System) software built on Node.js. Supports Telnet, SSH, WebSocket access, FidoNet, ActivityPub (experimental), door games (including native x86 DOS emulation), ANSI art, and more. Source: https://github.com/NuSkooler/enigma-bbs
---

# ENiGMA½ BBS

Modern, multi-platform Bulletin Board System (BBS) software with nostalgic flair. Built on Node.js with SQLite storage. Supports Telnet, SSH, and WebSocket (secure and plain) access; FidoNet (FTN/BSO) message networks; native BinkP mailer; ActivityPub federation (experimental); ANSI/CP437 art; DOS door game support including native x86 emulation via v86 (no DOSBox/QEMU needed); Z-Machine interactive fiction; achievements; and highly customizable HJSON-based menus/themes. Unlimited concurrent callers. Upstream: https://github.com/NuSkooler/enigma-bbs. Docs: https://nuskooler.github.io/enigma-bbs/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Bash installer script | Linux / macOS / FreeBSD | Recommended; installs Node.js + ENiGMA½ |
| Docker | Linux | Dockerfile available in repo |
| Manual (git clone + npm) | Linux / macOS / Windows | For dev/custom setups |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| system | "BBS name?" | Shown to callers on login |
| system | "SysOp username?" | Your admin account |
| network | "Telnet port?" | Default: 8888 |
| network | "SSH port?" | Default: 8022 |
| network | "WebSocket port?" | Default: 8810 |
| domain | "Hostname / domain?" | Used in SSH host key, FidoNet node config |
| fidonet | "Join FidoNet?" | Optional; requires FTN node address |

## Software-layer concerns

### Method 1: Bash installer (recommended)

  curl -o- https://raw.githubusercontent.com/NuSkooler/enigma-bbs/master/misc/install.sh | bash

  # The installer:
  # - Installs Node.js (if needed)
  # - Clones the repo to ~/enigma-bbs (or chosen directory)
  # - Runs npm install
  # - Generates a starter config.hjson

### First-run wizard

  cd ~/enigma-bbs
  node core/enigma_bbs.js --new
  # Follow the interactive setup to configure:
  # - BBS name, SysOp account, domain
  # - Telnet/SSH/WebSocket ports
  # - Message bases, file areas

### config.hjson (key sections)

  {
    general: {
      boardName: "My BBS"
      domain: bbs.example.com
    }

    loginServers: {
      telnet: { port: 8888, enabled: true }
      ssh: { port: 8022, enabled: true }
      webSocket: { port: 8810, enabled: true }
    }

    messageNetworks: {
      # FidoNet configuration goes here if joining FTN
    }
  }

### Run ENiGMA½

  cd ~/enigma-bbs
  node core/enigma_bbs.js

  # Or with pm2 (process manager):
  npm install -g pm2
  pm2 start core/enigma_bbs.js --name enigma-bbs
  pm2 save && pm2 startup

### Docker

  # Dockerfile is in the repo root; build and run:
  docker build -t enigma-bbs .
  docker run -d \
    --name enigma-bbs \
    -p 8888:8888 \
    -p 8022:8022 \
    -p 8810:8810 \
    -v $PWD/config:/enigma-bbs/config \
    -v $PWD/db:/enigma-bbs/db \
    enigma-bbs

### oputil — admin command-line tool

  node oputil.js user --add     # add a user
  node oputil.js config         # edit config wizard
  node oputil.js ffmpeg         # configure FFmpeg for media
  node oputil.js v86            # interactive DOS desktop (for door setup)
  node oputil.js fat            # manage FreeDOS disk images for doors

### Ports

  8888/tcp   # Telnet (default; configure in config.hjson)
  8022/tcp   # SSH
  8810/tcp   # WebSocket (ws:// and wss://)
  80/tcp     # Built-in web server (file browsing, temp download URLs)

### Reverse proxy for WebSocket (nginx)

  location /ws {
      proxy_pass http://127.0.0.1:8810;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
  }

### FidoNet (FTN) setup

  # Configure in messageNetworks.ftn section of config.hjson
  # Set up a BinkP mailer for mail exchange with a hub
  # See: https://nuskooler.github.io/enigma-bbs/messageareas/message-networks.html

## Upgrade procedure

  cd ~/enigma-bbs
  git pull
  npm install
  # Restart the process (pm2 restart enigma-bbs)
  # Check WHATSNEW.md for migration notes

## Gotchas

- **Node.js version**: ENiGMA½ requires a modern Node.js version (check `.nvmrc` in the repo). Use nvm to manage Node versions.
- **Port conflicts**: Default ports (8888, 8022) may conflict with existing SSH on 22 or other services. Change in config.hjson as needed.
- **SSH key generation**: On first SSH start, ENiGMA½ generates host keys. Ensure the `misc/` directory is writable.
- **DOS doors need v86 or a DOS emulator**: For classic DOS doors (LORD, TradeWars, etc.), ENiGMA½ includes native v86 emulation — no DOSBox needed. Use `oputil v86` to set up disk images.
- **ANSI/CP437 requires a compatible terminal**: For the full retro experience, use SyncTERM, IcyTERM, or NetRunner. Modern terminals (iTerm2, Windows Terminal) can display CP437 with the right font.
- **ActivityPub is experimental**: Fediverse federation is available but marked experimental. Test before relying on it for production use.
- **SQLite storage**: All user and message data is in SQLite. Back up the `db/` directory regularly.
- **Firewall**: Open Telnet (8888) and/or SSH (8022) ports in your firewall for callers to connect.

## References

- Upstream GitHub: https://github.com/NuSkooler/enigma-bbs
- Documentation: https://nuskooler.github.io/enigma-bbs/
- Installation methods: https://nuskooler.github.io/enigma-bbs/installation/installation-methods.html
- Discord: https://discord.gg/ghx8Vxex
