---
name: a-dark-room
description: A Dark Room recipe for open-forge. Covers self-hosting the minimalist text RPG/idle game as a Node.js web app. Upstream: https://github.com/doublespeakgames/adarkroom
---

# A Dark Room

Minimalist text adventure and idle RPG game playable in the browser. Self-hosting serves the static game files via a Node.js web server. Supports multiple languages (English, Chinese, French, German, Japanese, and more). Upstream: <https://github.com/doublespeakgames/adarkroom>. Play online: <http://adarkroom.doublespeakgames.com>.

**License:** MPL-2.0

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Node.js web server (from source) | https://github.com/doublespeakgames/adarkroom | ✅ | Any Linux server with Node.js; serves the game as static files |
| Static file serving (nginx/Apache) | https://github.com/doublespeakgames/adarkroom | ✅ | Serve pre-built game files behind any web server |
| GitHub Pages / CDN | https://doublespeakgames.github.io/adarkroom | ✅ | Zero-install; hosted by GitHub Pages |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Port to serve on?" | Number (default: 8080) | Node.js server |
| app | "Public URL / hostname?" | e.g. games.example.com | All |

## Node.js install (from source)

```bash
# Clone the repository
git clone https://github.com/doublespeakgames/adarkroom.git
cd adarkroom

# Install dependencies
npm install

# Start the server
npm start
# or: node server.js
```

The server starts on port 8080 by default. Open `http://localhost:8080` to play.

## Static file serving (nginx)

A Dark Room is a pure static web app (HTML/CSS/JS). After cloning, serve the root directory directly:

```nginx
server {
    listen 80;
    server_name adarkroom.example.com;
    root /var/www/adarkroom;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
git clone https://github.com/doublespeakgames/adarkroom.git /var/www/adarkroom
```

## Software-layer concerns

### Key files

| File / Dir | Purpose |
|---|---|
| `index.html` | Game entry point |
| `script/` | Game logic (JavaScript modules) |
| `lang/` | Localisation files per language |
| `server.js` | Simple Node.js static server |

### Language selection

Language is selected via query parameter: `?lang=zh_cn`, `?lang=fr`, `?lang=de`, etc. Default is English. Supported locales live in the `lang/` directory.

### Game state

All game state is stored in **browser localStorage** — there is no server-side persistence. No database required.

## Upgrade procedure

```bash
cd adarkroom
git pull
npm install  # in case dependencies changed
npm start
```

## Gotchas

- **No server-side state.** Save data lives entirely in the player's browser localStorage. Clearing browser data resets the game.
- **Pure static app.** No database, no user accounts, no auth. Anyone who can reach the URL can play.
- **Mobile apps are separate.** iOS, Android, and Steam versions are distinct codebases not included in this repo.
- **Access control.** If you don't want the game publicly accessible, put it behind HTTP basic auth in your reverse proxy.

## Upstream docs

- GitHub README: https://github.com/doublespeakgames/adarkroom
- Play online: http://adarkroom.doublespeakgames.com
- GitHub Pages version: https://doublespeakgames.github.io/adarkroom
