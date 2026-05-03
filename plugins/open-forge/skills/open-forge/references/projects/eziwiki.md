# EziWiki

> Lightweight static wiki and documentation site generator — write content in Markdown, configure navigation in TypeScript, build to static files and deploy anywhere. Hash-based URLs for privacy. No server runtime after build.

**Official URL:** https://github.com/i3months/eziwiki  
**Demo:** https://eziwiki.vercel.app

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any static host | Static files (Next.js export) | Vercel, GitHub Pages, Netlify, Nginx, Caddy |
| Any Linux VPS/VM | Nginx/Caddy | Serve the `out/` directory |
| Local | Node.js dev server | `npm run dev` for live editing |

**Note:** EziWiki generates a static site — no server process runs after `npm run build`. Deploy the `out/` directory to any static host.

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `baseUrl` | Public URL of your deployed wiki | `https://wiki.example.com` |
| `title` | Site title | `My Knowledge Base` |
| `description` | Site description | `Internal docs` |
| Content (`content/` dir) | Your Markdown files | `content/intro.md`, etc. |
| Navigation (`payload/config.ts`) | TypeScript nav config | see below |

---

## Software-Layer Concerns

### Quick Start
```bash
git clone https://github.com/i3months/eziwiki.git
cd eziwiki
npm install
npm run dev     # development server at http://localhost:3000
```

### Configuration (`payload/config.ts`)
```typescript
export const payload: Payload = {
  global: {
    title: 'My Wiki',
    description: 'My docs',
    baseUrl: 'https://wiki.example.com',
  },
  navigation: [
    { name: 'Introduction', path: 'intro' },
    {
      name: 'Guides',
      color: '#fef08a',
      children: [
        { name: 'Quick Start', path: 'guides/quick-start' },
      ],
    },
  ],
  theme: {
    primary: '#2563eb',
    secondary: '#7c3aed',
  },
};
```

### Adding Content
Create Markdown files in `content/` matching nav paths:
```
content/intro.md
content/guides/quick-start.md
```
Frontmatter (`---title: ...---`) is optional.

### Building for Production
```bash
npm run build        # generates out/ directory
npm run validate:payload  # check config for errors
npm run show-urls    # list all hash URLs
```

Deploy the `out/` directory to Vercel, Netlify, GitHub Pages, or serve with Nginx/Caddy.

### Serving with Nginx/Caddy
```nginx
server {
    root /var/www/eziwiki/out;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Hash-Based URLs (Privacy)
Pages use obfuscated hash URLs instead of readable paths:
- `intro` → `/c432b372-e0e30267-e65e26a1`
- Normal path links in Markdown are auto-converted at build time
- Find all URL mappings: `npm run show-urls`

---

## Upgrade Procedure

1. Pull latest: `git pull`
2. Install updated deps: `npm install`
3. Rebuild: `npm run build`
4. Redeploy the `out/` directory

---

## Gotchas

- **Static only — no server** — EziWiki has no backend; there is no search server, auth, or user management; it's purely a static documentation site
- **Hash URLs are opaque** — the privacy-first URL scheme means you can't guess page URLs; use `npm run show-urls` to see the mapping; bookmarks to old URLs break if content moves
- **TypeScript config** — navigation is configured in TypeScript, not JSON/YAML; requires basic comfort with TypeScript syntax
- **No built-in search** — full-text search is not included in the base project; add a client-side search library (Pagefind, Lunr.js) separately if needed
- **Node.js 18+** — requires Node.js 18.0 or higher for the build step

---

## Links
- GitHub: https://github.com/i3months/eziwiki
- Demo (Vercel): https://eziwiki.vercel.app
- Demo (GitHub Pages): https://i3months.github.io/eziwiki
