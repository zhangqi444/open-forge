# POMjs

**Self-hosted random password generator** — pure HTML + JavaScript static app with no external dependencies, no tracking, and no cookies. Configurable character sets (uppercase, lowercase, digits, special chars), adjustable length via slider, clipboard copy, dark mode, and strength indicator.

**Official site:** https://password.oppetmoln.se
**Source:** https://github.com/joho1968/POMjs
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Any static file server (Nginx, Apache, Caddy) | No backend needed; drop files in web root |
| Shared hosting | Any PHP/static host | Works on any host that serves static files |

---

## Inputs to Collect

### Phase 1 — Planning
- Web root path to deploy files

---

## Software-Layer Concerns

- **Purely static:** HTML + JavaScript (minified `password-om.min.js`); no server-side processing
- **No external resources:** All CSS/JS is self-contained; works offline after load
- **No tracking, no cookies**
- **Customization:** Edit `password-om.js` to change character sets, default settings, or branding; then re-minify to `password-om.min.js`
- **"Öppet Moln" branding:** References to the author's Swedish site can be removed if desired

---

## Deployment

```bash
# Clone or download release
git clone https://github.com/joho1968/POMjs
# Or download from GitHub releases

# Copy files to your web root
cp -r POMjs/* /var/www/html/password/
```

No build step, no dependencies to install. Just serve the static files.

---

## Upgrade Procedure

```bash
git pull
# Copy updated files to web root
```

---

## Gotchas

- **Customization requires re-minification** — `index.html` loads `password-om.min.js`; if you edit `password-om.js`, you need to re-minify it (or copy it directly as-is)
- **Swedish branding references** — some text references "Öppet Moln" (the author's site); review and remove if deploying publicly under your own brand
- **No ongoing maintenance** — last release was July 2023; project is stable but not actively developed

---

## Links

- Upstream README: https://github.com/joho1968/POMjs#readme
- Live demo: https://password.oppetmoln.se
