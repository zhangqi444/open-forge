---
name: untrusted
description: untrusted recipe for open-forge. Covers self-hosted Node.js/nginx deploy. untrusted is a meta-JavaScript puzzle game where players solve roguelike levels by reading and modifying the JavaScript code that generates each level.
---

# untrusted

A unique meta-JavaScript puzzle game where players guide Dr. Eval through a mysterious machine continuum by editing the JavaScript code that generates each level. Combines roguelike exploration with real JavaScript programming puzzles — players must modify the (partially locked) level-generation code to open a path forward. Upstream: <https://github.com/AlexNisnevich/untrusted>. Demo: <http://alexnisnevich.github.io/untrusted/>.

**License:** CC-BY-NC-SA-3.0 · **Language:** Node.js (JavaScript) · **Default port:** 8080 · **Stars:** ~4,700

> **License note:** CC-BY-NC-SA-3.0 — Non-commercial use only. You may self-host for personal/educational use, but cannot use it for commercial purposes.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Static file server (nginx/Apache) | <https://github.com/AlexNisnevich/untrusted#development> | ✅ | Simplest — the built game is static HTML/JS. |
| Node.js `http-server` | <https://github.com/AlexNisnevich/untrusted#development> | ✅ | Quick local or LAN play. |
| Docker (nginx) | Community | — | Containerized static file hosting. |

> **Note:** untrusted is a static web application — there is no backend server, database, or user authentication. It's a single-page app that runs entirely in the browser.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Serving method: nginx reverse proxy, Node.js http-server, or Docker?" | AskUserQuestion | Determines steps below. |
| domain | "Domain or IP to serve on?" | Free-text | nginx / Docker. |
| port | "Port to serve on? (default: 8080)" | Free-text | http-server / Docker. |

## Install — Build and serve with nginx

```bash
# Prerequisites
sudo apt install -y git nodejs npm nginx

git clone https://github.com/AlexNisnevich/untrusted.git
cd untrusted

npm install

# Build the release bundle
make release
# Produces: scripts/build/untrusted.min.js
```

Copy to web root:

```bash
sudo mkdir -p /var/www/untrusted
sudo cp -r . /var/www/untrusted/
sudo chown -R www-data:www-data /var/www/untrusted
```

nginx vhost:

```nginx
server {
    listen 80;
    server_name untrusted.example.com;
    root /var/www/untrusted;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

```bash
sudo systemctl reload nginx
```

## Install — Quick local play (http-server)

```bash
git clone https://github.com/AlexNisnevich/untrusted.git
cd untrusted
npm install

# Install http-server globally
npm install -g http-server

# Build and run
make release
http-server -p 8080
```

Open `http://localhost:8080` in your browser.

> **Why a server?** The game cannot be opened as a local file (`file://`) due to browser CORS restrictions on same-origin JavaScript loading. A local HTTP server is required.

## Install — Docker (nginx)

```yaml
services:
  untrusted:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./untrusted:/usr/share/nginx/html:ro
```

Pre-build the game and mount the directory:

```bash
git clone https://github.com/AlexNisnevich/untrusted.git
cd untrusted && npm install && make release
# Then run docker compose from the parent directory
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Static app | No backend, no database, no user accounts. All game state is in the browser session. |
| Build step | Must run `make release` (or `make` for debug) to merge JS files into `scripts/build/untrusted.min.js`. The game won't work from source without building. |
| CORS | Cannot be served as `file://` — must use an HTTP server (even for local play). |
| Make | GNU `make` required for the build step. Available via `sudo apt install build-essential`. |
| Mods | Community mods go in the `mods/` directory — build with `make mod=modname`. |
| Save state | Game progress is stored in browser `localStorage` — no server-side persistence. |
| License | CC-BY-NC-SA-3.0 — non-commercial only. Attribution required. Derivative works must use the same license. |

## Upgrade procedure

```bash
cd untrusted
git pull
npm install
make release
# Redeploy static files to web root
sudo rsync -av --delete . /var/www/untrusted/
```

## Gotchas

- **`make` required:** The game ships as separate source files. Without running `make release`, the game won't start (it looks for `scripts/build/untrusted.min.js`). Always build before deploying.
- **Must use HTTP server:** Directly opening `index.html` in a browser fails with CORS errors. Even for local play, you need at least `npx http-server` or `python3 -m http.server`.
- **No HTTPS required:** untrusted doesn't use camera, mic, or secure APIs — plain HTTP is fine for internal/LAN play.
- **Archived repo:** The upstream repo has had no commits since ~2020. It's a complete, stable game — but don't expect updates.
- **CC-BY-NC-SA-3.0 license:** Not an OSI-approved open source license. Non-commercial clause means you cannot monetize it or use it in a paid product.

## Upstream links

- GitHub: <https://github.com/AlexNisnevich/untrusted>
- Live demo: <http://alexnisnevich.github.io/untrusted/>
- npm package for mods: <https://github.com/AlexNisnevich/untrusted#contributing-levels>
