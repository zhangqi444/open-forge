---
name: mirotalk-c2c
description: MiroTalk C2C recipe for open-forge. Covers Docker Compose and Node.js direct install. MiroTalk C2C is a self-hosted WebRTC cam-to-cam 1-to-1 video calling platform with screen sharing and E2E encryption, embeddable via iframe.
---

# MiroTalk C2C

Self-hosted WebRTC cam-to-cam peer-to-peer video calling platform for 1-to-1 real-time communication. Features screen sharing, end-to-end encryption, and easy iframe embedding for any website. Part of the broader MiroTalk suite (SFU, BRO, WDC). Upstream: <https://github.com/miroslavpejic85/mirotalkc2c>. Docs: <https://docs.mirotalk.com/mirotalk-c2c/self-hosting/>.

**License:** AGPL-3.0 · **Language:** Node.js · **Default port:** 8080 · **Stars:** ~500

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.mirotalk.com/mirotalk-c2c/self-hosting/> | ✅ | Recommended — isolated, reproducible deploy. |
| Node.js direct | <https://github.com/miroslavpejic85/mirotalkc2c#-quick-start> | ✅ | Development or bare-metal without Docker. |
| install.sh | <https://github.com/miroslavpejic85/mirotalkc2c/blob/master/install.sh> | ✅ | One-shot Linux install script (sets up nginx, pm2, certbot). |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method — Docker Compose, Node.js direct, or install.sh?" | AskUserQuestion | Determines section. |
| domain | "What domain will MiroTalk C2C be served on?" | Free-text | All methods. |
| port | "Which host port to expose MiroTalk C2C on? (default: 8080)" | Free-text | All methods. |
| https | "HTTPS termination — reverse proxy (nginx/Caddy/Traefik), or install.sh with certbot?" | AskUserQuestion | Required for WebRTC in browsers. |

## Install — Docker Compose

Reference: <https://docs.mirotalk.com/mirotalk-c2c/self-hosting/>

```bash
git clone https://github.com/miroslavpejic85/mirotalkc2c.git
cd mirotalkc2c

# Copy and edit environment file
cp .env.template .env
nano .env  # set HOST, PORT, NODE_ENV=production
```

Key `.env` settings:

```bash
NODE_ENV=production
HOST=https://c2c.example.com   # public URL
PORT=8080
TZ=UTC
TRUST_PROXY=true                # set true if behind nginx/Caddy
```

Create `docker-compose.yml` from the template:

```bash
cp docker-compose.template.yml docker-compose.yml
```

Start:

```bash
docker compose up -d
docker compose logs -f
```

The container image is `mirotalk/c2c:latest`.

## Install — Node.js direct

```bash
git clone https://github.com/miroslavpejic85/mirotalkc2c.git
cd mirotalkc2c
cp .env.template .env
npm install
npm start        # development
# or for production:
npm run start    # uses NODE_ENV=production
```

Run persistently with PM2:

```bash
npm install -g pm2
pm2 start npm --name mirotalkc2c -- start
pm2 startup && pm2 save
```

## Install — install.sh (Linux)

```bash
git clone https://github.com/miroslavpejic85/mirotalkc2c.git
cd mirotalkc2c
chmod +x install.sh
sudo ./install.sh
```

The script installs Node.js, clones the repo, configures nginx with TLS (certbot), and sets up the app with PM2.

## Reverse proxy — nginx

WebRTC requires HTTPS. Example nginx configuration:

```nginx
server {
    listen 443 ssl;
    server_name c2c.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Set `TRUST_PROXY=true` in `.env` when proxying.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Node.js version | Requires Node.js 18+. |
| HTTPS | **Mandatory for WebRTC in modern browsers.** Without TLS, camera/mic access is blocked. Use nginx + certbot or Caddy. |
| WebRTC STUN/TURN | Uses Google STUN servers by default. For production across NAT, configure a TURN server (coturn). See `backend/config.js`. |
| CORS | Set `CORS_ORIGIN` in `.env` if embedding in an iframe on a different domain. |
| Signaling | Uses Socket.io for WebRTC signaling — the server is stateless between calls. |
| Peer-to-peer | Traffic flows directly between browsers (P2P) after signaling — no media relay unless TURN is used. |
| Iframe embedding | Embed with `<iframe src="https://c2c.example.com/?room=roomname" allow="camera; microphone; display-capture">`. |

## Upgrade procedure

```bash
cd mirotalkc2c
docker compose pull
docker compose up -d
```

Or for Node.js direct:

```bash
git pull
npm install
pm2 restart mirotalkc2c
```

## Gotchas

- **HTTPS is non-negotiable:** Browsers block camera/microphone access on non-secure origins. TLS is required even for local LAN deployments (use a self-signed cert or local CA for internal use).
- **TURN server for strict NAT:** In production environments where both peers are behind strict NAT (e.g. cellular, corporate), P2P WebRTC may fail without a TURN relay. Set up coturn and configure it in `backend/config.js`.
- **TRUST_PROXY:** Set `TRUST_PROXY=true` in `.env` when running behind nginx or any reverse proxy — otherwise IP logging and redirect URLs will be wrong.
- **AGPL-3.0 license:** If you modify MiroTalk C2C and serve it to users, you must release your source code under AGPL-3.0.
- **1-to-1 only:** MiroTalk C2C is specifically designed for cam-to-cam (1:1) calls. For multi-party conferencing, use [MiroTalk SFU](https://github.com/miroslavpejic85/mirotalk) instead.

## Upstream links

- GitHub: <https://github.com/miroslavpejic85/mirotalkc2c>
- Self-hosting docs: <https://docs.mirotalk.com/mirotalk-c2c/self-hosting/>
- Docker Hub: <https://hub.docker.com/r/mirotalk/c2c>
- Live demo: <https://c2c.mirotalk.com>
- MiroTalk SFU (multi-party): <https://github.com/miroslavpejic85/mirotalk>
