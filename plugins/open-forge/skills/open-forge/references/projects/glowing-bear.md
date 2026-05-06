---
name: glowing-bear
description: Glowing Bear recipe for open-forge. Web frontend for WeeChat IRC client. Connects directly from your browser to a running WeeChat instance via the relay plugin using WebSockets. No backend service required — serve as a static site. Source: https://github.com/glowing-bear/glowing-bear
---

# Glowing Bear

Modern web frontend for the WeeChat IRC client. Lets you use WeeChat from any browser (computer, tablet, or phone) without installing anything on the client device. Connects directly from the browser to your WeeChat instance via the WeeChat relay plugin over WebSockets. No separate backend service is needed — Glowing Bear is a purely client-side JavaScript app; just serve the static files with any web server. Upstream: https://github.com/glowing-bear/glowing-bear. Hosted instance: https://www.glowing-bear.org/ (your browser connects to your WeeChat, not to their servers).

> **Prerequisite**: a running WeeChat instance (0.4.2+) with the relay plugin configured. WeeChat must be reachable from the device running the browser.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Use hosted version | Any browser | No install. Visit https://www.glowing-bear.org. |
| Static files (nginx/Caddy/Apache) | Linux / macOS | Self-host the built static files |
| npm dev server | Linux / macOS | For development |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| weechat | "WeeChat relay port?" | Default: 9001 |
| weechat | "WeeChat relay password?" | Set in WeeChat: `/set relay.network.password PASSWORD` |
| weechat | "WeeChat host / IP?" | Must be reachable from the browser |
| tls | "TLS on relay?" | Strongly recommended for non-localhost access |

## Software-layer concerns

### Step 1: Configure WeeChat relay

  # In WeeChat, add a relay:
  /relay add weechat 9001

  # Set a relay password:
  /set relay.network.password YOURPASSWORD

  # For TLS relay (recommended):
  /relay add ssl.weechat 9001
  # (Requires a TLS certificate configured in WeeChat)

### Step 2: Self-host Glowing Bear (static files)

  # Build from source:
  git clone https://github.com/glowing-bear/glowing-bear.git
  cd glowing-bear
  npm install
  npm run build
  # Output: build/ directory

  # Serve with nginx:
  # Point web root to build/
  server {
      listen 80;
      root /var/www/glowing-bear/build;
      index index.html;
      location / {
          try_files $uri $uri/ /index.html;
      }
  }

  # Or serve with any static web server:
  npx serve build/

### Development server

  git clone https://github.com/glowing-bear/glowing-bear.git
  cd glowing-bear
  npm install
  npm start
  # Opens at http://localhost:8000

### Option: use the hosted version

  # Visit https://www.glowing-bear.org
  # Enter your WeeChat host, port, and password.
  # Your browser connects directly to your WeeChat — glowing-bear.org sees nothing.

### Connecting via Glowing Bear

  # In the browser UI:
  Host:     your-weechat-server.example.com (or IP)
  Port:     9001
  Password: YOURPASSWORD
  Encryption: check if using SSL relay

### WebSocket proxy (optional — expose relay via nginx)

  # If WeeChat is on a different server/port, proxy it through nginx:
  # nginx config:
  location /weechat {
      proxy_pass http://127.0.0.1:9001;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "Upgrade";
      proxy_read_timeout 4h;
  }
  # Then in Glowing Bear: Host = your nginx server, Port = 443, Path = /weechat

## Upgrade procedure

  cd glowing-bear
  git pull origin master
  npm install
  npm run build
  # Replace build/ directory on your web server

## Gotchas

- **WeeChat must be running**: Glowing Bear is just a UI layer. WeeChat must be running with the relay plugin active. If WeeChat stops, Glowing Bear cannot connect.
- **Plaintext relay is insecure**: the default relay setup (`/relay add weechat 9001`) sends all data unencrypted. Use `ssl.weechat` relay or proxy through nginx with TLS for anything beyond localhost.
- **WebCrypto requires HTTPS**: if you self-host Glowing Bear, serve it over HTTPS. Browsers restrict certain JavaScript APIs to secure contexts.
- **No persistent state**: Glowing Bear does not store chat history itself — history comes from WeeChat's logs. If WeeChat is not running (and logging), you lose messages while disconnected.
- **firewall the relay port**: don't expose WeeChat's relay port (9001) directly to the internet without TLS and a strong password. Use a reverse proxy or SSH tunnel instead.
- **Mobile as Progressive Web App**: on Android Chrome, use "Add to Homescreen" for a full-screen app experience without browser chrome.
- **Hosted version is safe**: even though you enter your WeeChat credentials at glowing-bear.org, the JavaScript runs entirely in your browser and connects directly to your WeeChat. The hosting server only serves static files.

## References

- Upstream GitHub: https://github.com/glowing-bear/glowing-bear
- Hosted version: https://www.glowing-bear.org
- Development version: https://latest.glowing-bear.org
- Proxy setup wiki: https://github.com/glowing-bear/glowing-bear/wiki/Proxying-WeeChat-relay-with-a-web-server
- WeeChat relay documentation: https://weechat.org/files/doc/stable/weechat_user.en.html#relay_plugin
