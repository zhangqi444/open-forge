---
name: kiwi-irc
description: Kiwi IRC recipe for open-forge. Versatile web-based IRC client with theming, plugin support, and multiple connection modes. 100% static files served by any web server or CDN. Connects directly to WebSocket IRC servers or via webircgateway proxy. Source: https://github.com/kiwiirc/kiwiirc
---

# Kiwi IRC

Versatile web-based IRC messenger that is 100% static files — serve it from any web server or CDN. Works as a personal IRC client, a branded client for a specific IRC network, or an embeddable IRC widget for a website. Supports single and multiple IRC network connections, light/dark modes, desktop notifications, file uploading and video calling via plugins, and "Team mode" for workplaces. Connects directly to WebSocket-enabled IRC servers, or via the webircgateway proxy for regular IRC servers. Upstream: https://github.com/kiwiirc/kiwiirc. Docs: https://github.com/kiwiirc/kiwiirc/wiki. Builder: https://kiwiirc.com/clientbuilder/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Pre-built download | Linux / macOS / Windows | Recommended. Download from kiwiirc.com/downloads. |
| Build from source (yarn) | Linux / macOS / Windows | Full control over build |
| Hosted builder | Any | kiwiirc.com/clientbuilder — generates a hosted embed |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | "Default IRC network?" | Hostname / IP of IRC server to connect to |
| config | "IRC port?" | Default: 6667 (plaintext) or 6697 (TLS) |
| config | "Connection mode?" | WebSocket direct, or via webircgateway proxy |
| config | "Client branding?" | Server name, theme, logo (optional) |
| gateway | "webircgateway address?" | Only needed if IRC server doesn't support WebSockets |

## Software-layer concerns

### Method 1: Pre-built download (recommended)

  # Download latest release from:
  # https://kiwiirc.com/downloads/

  # Extract and serve the static files with any web server.
  # The distribution contains: index.html, static/

  # Example: nginx
  server {
      listen 80;
      root /var/www/kiwiirc;
      index index.html;
      location / {
          try_files $uri /index.html;
      }
  }

### Method 2: Build from source

  # Prerequisites: Node.js, yarn
  git clone https://github.com/kiwiirc/kiwiirc.git
  cd kiwiirc

  # Install dependencies
  yarn install

  # Build into dist/
  yarn run build

  # Copy dist/ to your web server's document root.

  # Development server (hot reload at localhost:8080):
  yarn run dev

### Configuration (config.json)

  # Kiwi IRC loads /static/config.json at runtime.
  # Copy the example and edit:
  cp static/config.json.example static/config.json

  # Key settings:
  {
    "startupOptions": {
      "server":   "irc.example.com",
      "port":     6697,
      "tls":      true,
      "channel":  "#general",
      "nick":     "Kiwi_%n"
    },
    "theme": "default",
    "showConnectionForm": true
  }

  # Full configuration reference:
  # https://github.com/kiwiirc/kiwiirc/wiki/Configuration

### Connection modes

  # Mode 1: Direct WebSocket (server must support WebSockets natively)
  # e.g. InspIRCd with ssl_openssl + websocket module
  "server": "wss://irc.example.com:443"

  # Mode 2: webircgateway proxy (standard IRC server, no WebSocket support)
  # Run webircgateway alongside your IRC server:
  # https://github.com/kiwiirc/webircgateway
  # Kiwi IRC connects to gateway → gateway connects to IRC server

  # Mode 3: KiwiBNC — stay connected 24/7
  # https://github.com/kiwiirc/kiwibnc

### Ports

  80/443/tcp   # Kiwi IRC web UI (served by your web server)
  (IRC connection handled by browser WebSocket to IRC server or gateway)

### Embed on a website

  # Add an iframe pointing to your Kiwi IRC install with pre-filled params:
  <iframe src="https://kiwi.example.com/?settings=..." style="width:800px;height:600px"></iframe>

  # Or use the hosted builder at: https://kiwiirc.com/clientbuilder/

## Upgrade procedure

  # Download the new release ZIP from https://kiwiirc.com/downloads/
  # Replace files in your web server's document root.
  # Keep your custom static/config.json — it's not overwritten by the new release.

  # From source:
  git pull origin master
  yarn install
  yarn run build
  # Copy new dist/ to web root

## Gotchas

- **Static files only**: Kiwi IRC has no backend. All server-side IRC connectivity is provided by the IRC server itself (WebSocket) or by webircgateway. You cannot connect to a regular IRC server without either WebSocket support on the server or webircgateway.
- **config.json is runtime-loaded**: the config is loaded by the browser at runtime, not baked into the build. You can update config.json without rebuilding.
- **HTTPS required for TLS IRC**: if connecting to an IRC server over TLS from Kiwi IRC, the Kiwi IRC app itself must also be served over HTTPS (browsers block mixed content).
- **webircgateway for non-WebSocket servers**: most traditional IRC servers (Freenode-era setups) don't support WebSockets natively. Run webircgateway on the same server as your IRC daemon to bridge the gap.
- **Plugins**: Kiwi IRC supports plugins (file upload, video calling, etc.). Load them via the `plugins` array in config.json. Community plugins: https://github.com/kiwiirc/kiwiirc/wiki/Plugins.

## References

- Upstream GitHub: https://github.com/kiwiirc/kiwiirc
- Downloads: https://kiwiirc.com/downloads/
- Configuration wiki: https://github.com/kiwiirc/kiwiirc/wiki/Configuration
- webircgateway: https://github.com/kiwiirc/webircgateway
- KiwiBNC (stay connected): https://github.com/kiwiirc/kiwibnc
- Client builder (hosted): https://kiwiirc.com/clientbuilder/
