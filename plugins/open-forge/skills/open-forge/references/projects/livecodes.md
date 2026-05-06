# LiveCodes

LiveCodes is a feature-rich, open-source, **client-side** code playground supporting 90+ languages and frameworks including React, Vue, Svelte, Solid, TypeScript, Python, Go, Ruby, and PHP. It runs entirely in the browser — no server-side execution — making self-hosting simple (just static file serving).

**Website:** https://livecodes.io/docs/features/self-hosting
**Source:** https://github.com/live-codes/livecodes
**License:** MIT
**Stars:** ~1,429

> ⚠️ **Third-party dependencies**: LiveCodes loads language compilers and runtimes from CDNs by default (npm, jsDelivr, deno.land, etc.). Full air-gapped self-hosting requires additional configuration.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Static file server (nginx, Caddy, Apache) | Recommended |
| Any | Docker + nginx | Simple container |
| Any | Node.js (serve/http-server) | Development/quick use |
| CDN / S3 | Static hosting | Ideal — no server-side needed |

---

## Inputs to Collect

### Phase 1 — Planning
- Hosting URL (e.g. `https://playground.example.com`)
- Whether to restrict embedding/cross-origin access
- GitHub integration (optional): GitHub OAuth app for saving projects to Gist

### Phase 2 — Deployment
- Static file root
- Reverse proxy config (if needed)
- GitHub OAuth client ID/secret (optional, for GitHub integration features)

---

## Software-Layer Concerns

### Method 1: Self-host the Built App (Recommended)

```bash
# Download latest release build
wget https://github.com/live-codes/livecodes/releases/latest/download/livecodes.zip
unzip livecodes.zip -d livecodes/

# Serve with nginx or any static file server
# Point web root to the extracted directory
```

### Method 2: npm Package (Embedded Playground)

```html
<!-- Embed in your own page -->
<div id="container"></div>
<script type="module">
  import { createPlayground } from 'https://cdn.jsdelivr.net/npm/livecodes';
  createPlayground('#container', {
    params: {
      html: '<h1>Hello World</h1>',
      css: 'h1 { color: dodgerblue; }',
      js: 'console.log("Hello!");',
    },
  });
</script>
```

### Method 3: Docker

```dockerfile
FROM nginx:alpine
COPY livecodes/ /usr/share/nginx/html/
```

```yaml
services:
  livecodes:
    build: .
    ports:
      - "8080:80"
```

Or use a one-liner:
```bash
docker run -d -p 8080:80 \
  -v $(pwd)/livecodes:/usr/share/nginx/html:ro \
  nginx:alpine
```

### nginx Config Example
```nginx
server {
    listen 80;
    server_name playground.example.com;
    root /var/www/livecodes;
    index index.html;

    # Required for SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|ico|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### GitHub Integration (Optional)
For saving projects to GitHub Gist, configure a GitHub OAuth App:
1. Create OAuth App at https://github.com/settings/applications/new
2. Set callback URL: `https://playground.example.com/`
3. Add to your LiveCodes config (via URL params or SDK config): `githubClientId`

### SDK / Embedding API
```javascript
import { createPlayground } from 'livecodes';

const playground = await createPlayground('#container', {
  config: {
    languages: ['typescript', 'react', 'vue'],
    theme: 'dark',
  },
});

// Programmatic control
await playground.run();
const output = await playground.getCode();
```

---

## Upgrade Procedure

```bash
# Download new release
wget https://github.com/live-codes/livecodes/releases/latest/download/livecodes.zip

# Backup current (optional — no server-side state)
mv livecodes/ livecodes-old/

# Extract new version
unzip livecodes.zip -d livecodes/

# Reload web server if needed
nginx -s reload
```

No database migrations needed — LiveCodes is stateless on the server side.

---

## Gotchas

- **Client-side only**: Code execution happens in the user's browser using WebAssembly, iframes, and CDN-loaded runtimes. The server only serves static files.
- **CDN dependencies**: By default, language compilers/runtimes load from CDNs (jsDelivr, esm.sh, etc.). In restricted environments, these requests may fail or need proxying.
- **No server-side persistence**: Projects are saved to browser localStorage or GitHub Gist (if configured). There is no built-in server-side project storage.
- **GitHub OAuth optional**: The GitHub integration for saving/loading from Gist requires a GitHub OAuth App. Without it, only browser localStorage is available.
- **Content Security Policy**: If your nginx/server sets strict CSP headers, the playground may break. LiveCodes uses `eval()` and dynamic imports internally.
- **iframe security**: The code execution sandbox uses iframes with `sandbox` attributes; ensure your server doesn't set `X-Frame-Options: DENY`.
- **Large bundle**: The full LiveCodes build is large (~10 MB+). Leverage CDN/browser caching for repeat visitors.

---

## Links
- Self-hosting Docs: https://livecodes.io/docs/features/self-hosting
- SDK Docs: https://livecodes.io/docs/sdk/
- Configuration Reference: https://livecodes.io/docs/configuration/
- GitHub Releases: https://github.com/live-codes/livecodes/releases
- Demo: https://livecodes.io
