---
name: reveal.js
description: "Open-source HTML presentation framework — create beautiful, browser-based slideshows with Markdown, auto-animate, speaker notes, PDF export, and syntax highlighting. JavaScript. MIT."
---

# reveal.js

reveal.js is an open-source HTML presentation framework that lets anyone with a web browser create beautiful, interactive presentations. Slides are written in HTML or Markdown, run entirely in the browser, and require no installation for viewers.

Created by Hakim El Hattab. The companion service [Slides.com](https://slides.com) provides a visual editor for reveal.js presentations (paid SaaS); the framework itself is fully self-hostable and free.

Use cases: (a) developer/technical presentations with live code demos (b) conference talks hosted on own domain (c) educational slideshows with interactive elements (d) team knowledge sharing with version-controlled slides.

Features:

- **HTML + Markdown slides** — write slides in plain HTML or Markdown; mix and match
- **Nested slides** — vertical stacks for sub-topics; horizontal flow for main topics
- **Auto-Animate** — automatically animate elements between slides with matching data attributes
- **Speaker view** — separate presenter window with notes, timer, and upcoming slide preview
- **PDF export** — built-in print-to-PDF support via browser
- **Syntax highlighting** — code blocks with highlight.js; line-by-line highlighting
- **LaTeX / MathJax** — math typesetting support
- **Transitions** — slide, fade, convex, concave, zoom
- **Themes** — built-in themes (black, white, league, beige, sky, etc.); fully customizable CSS
- **Plugins** — search, zoom, notes, math, highlight; custom plugin API
- **Fullscreen API** — full-screen presentations; responsive scaling
- **REST/iframe embed** — embed presentations in other pages via iframe

- Upstream repo: https://github.com/hakimel/reveal.js
- Homepage: https://revealjs.com/
- Docs: https://revealjs.com/markup/
- Demo: https://revealjs.com/demo/

## Architecture

reveal.js is a static JavaScript/CSS/HTML bundle — no server-side runtime required. Self-hosting options:

1. **Static file hosting** — copy the dist/ bundle + your slides HTML to any web server or static host
2. **Node.js dev server** — clone repo, `npm install`, `npm start` for live-reload dev mode with speaker notes socket server
3. **Standalone HTML** — single `index.html` + CDN-linked assets; zero server needed

The Node.js server is only needed if you want **speaker notes** (separate presenter window) or live editing. For a published presentation, any static file host works.

## Compatible install methods

| Infra         | Runtime               | Notes                                                              |
|---------------|-----------------------|--------------------------------------------------------------------|
| Any web server| Static files (nginx, Apache, Caddy) | Simplest; just serve the HTML + assets directory |
| Node.js       | `npm start`           | Live-reload dev server; enables speaker notes socket server        |
| Docker        | nginx:alpine          | `COPY dist/ + index.html` into nginx image; ~5 MB image            |
| CDN/static    | GitHub Pages, Netlify, Vercel, Cloudflare Pages | Zero-cost hosting for public presentations |
| Embedded      | `<iframe>`            | Embed slides in any webpage                                        |

## Inputs to collect

| Input         | Example                    | Phase    | Notes                                              |
|---------------|----------------------------|----------|----------------------------------------------------|
| Domain        | `slides.example.com`       | URL      | Optional; any URL works                            |
| Slide content | `index.html` or `.md` file | Content  | One file per presentation; can use Markdown plugin |
| Theme         | `black`, `white`, custom   | Config   | Set in `<link>` tag or Markdown front matter       |

## Install (Node.js dev server)

```sh
git clone https://github.com/hakimel/reveal.js.git
cd reveal.js
npm install
npm start
# → http://localhost:8000
```

Edit `index.html` to write your slides. The server auto-reloads on save.

## Install (static hosting — simplest)

```sh
# Option 1: Use CDN links (no files needed)
# Just reference reveal.js from jsDelivr in your HTML

# Option 2: Install via npm and copy dist/
npm install reveal.js
# then copy node_modules/reveal.js/dist/ to your web root
```

See https://revealjs.com/installation/ for all options.

## Basic slide structure

```html
<!doctype html>
<html>
<head>
  <link rel="stylesheet" href="dist/reveal.css">
  <link rel="stylesheet" href="dist/theme/black.css">
</head>
<body>
  <div class="reveal">
    <div class="slides">
      <section>Slide 1</section>
      <section>Slide 2</section>
      <section>
        <section>Vertical slide 2a</section>
        <section>Vertical slide 2b</section>
      </section>
    </div>
  </div>
  <script src="dist/reveal.js"></script>
  <script>Reveal.initialize({ hash: true });</script>
</body>
</html>
```

## Markdown slides

```html
<section data-markdown>
  <textarea data-template>
    ## Slide 1
    Content here

    ---

    ## Slide 2
    More content

    Note:
    Speaker notes go here (only visible in presenter view)
  </textarea>
</section>
```

Or load an external `.md` file:

```html
<section data-markdown="slides.md" data-separator="^\n---\n"></section>
```

## Speaker notes

Speaker notes display in a separate browser window (press `S`). They require the Node.js server (uses a WebSocket for sync). For static hosting without the Node server, notes are embedded but the separate presenter window won't sync.

## PDF export

Open presentation URL with `?print-pdf` appended → use browser Print → Save as PDF. Best results with Chrome.

```
http://localhost:8000/?print-pdf
```

## Gotchas

- **Speaker notes require Node.js server** — the separate presenter window uses a WebSocket connection. Static file hosting alone won't sync notes across windows. If you need speaker notes with static hosting, the notes are still visible by pressing `S` but won't sync between presenter/audience windows.
- **Vertical slides navigation** — viewers unfamiliar with reveal.js may miss vertical slides. Use `overview` mode (press `O`) or navigation hints (`showSlideNumber: true`) to guide audience.
- **PDF export quirks** — transitions/animations don't export to PDF; only the final state of each slide is captured. Complex CSS animations may look different in PDF.
- **Content security** — if embedding external Markdown files, ensure proper CORS headers or serve from same origin; browser security blocks cross-origin file loads.
- **Font/asset loading** — for offline presentations, ensure fonts and assets are local (not CDN-linked). CDN references require internet connectivity.
- **Mobile touch** — reveal.js supports touch swipe navigation on mobile, but speaker notes and some plugins don't work well on small screens.
- **Version 5.x breaking changes** — the plugin system was overhauled in v5. If using third-party plugins, check compatibility.
- **Alternatives:** Slidev (Vue.js-based, developer-focused, great code highlighting), Marp (Markdown-to-slides, simpler), Impress.js (3D/path-based, more theatrical), Google Slides/PowerPoint (GUI-based, no self-hosting needed).

## Links

- Repo: https://github.com/hakimel/reveal.js
- Homepage: https://revealjs.com/
- Installation: https://revealjs.com/installation/
- Documentation: https://revealjs.com/markup/
- Themes: https://revealjs.com/themes/
- Speaker view: https://revealjs.com/speaker-view/
- Plugins: https://revealjs.com/plugins/
- Demo: https://revealjs.com/demo/
- Slides.com (visual editor): https://slides.com/
