# Forms.md

**Developer-first open-source Typeform alternative — build multi-step forms and surveys with a JavaScript API or Markdown-like syntax. Privacy-focused, accessible, localizable, and themeable.**
Official site: https://forms.md
Docs: https://docs.forms.md
GitHub: https://github.com/formsmd/formsmd

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | npm package | Install into your Node.js project |
| Any | Browser CDN/bundle | Include CSS + JS in any HTML page |

---

## Inputs to Collect

### Required
- Form ID — unique identifier for the form
- `postUrl` — API endpoint to receive form submissions

---

## Software-Layer Concerns

### Install via npm
```bash
npm install formsmd
```

### Use in browser (no bundler)
```html
<!-- Forms.md CSS -->
<link rel="stylesheet" type="text/css" href="path/to/formsmd/dist/css/formsmd.min.css" />
<!-- Forms.md JS bundle -->
<script src="path/to/formsmd/dist/js/formsmd.bundle.min.js"></script>
```

### Basic usage (JavaScript API)
```javascript
import "formsmd/dist/css/formsmd.min.css";
import { Composer, Formsmd } from "formsmd";

const composer = new Composer({ id: "my-form", postUrl: "/api/submit" });
composer.textInput("name", { question: "What's your name?", required: true });

const formsmd = new Formsmd(
  composer.template,
  document.getElementById("form-container"),
  { postHeaders: { Authorization: `Bearer ${token}` } }
);
formsmd.init();
```

### Key features
- Multi-step slides with conditional logic (`displayCondition`, `jumpCondition`)
- Input types: text, email, choice, file, and more
- RTL support (`formsmd.rtl.min.css`)
- Theming support
- i18n / localization
- Progress indicators per slide
- Free tier available — see https://forms.md/pricing/

---

## Upgrade Procedure

```bash
npm update formsmd
```

---

## Gotchas

- Forms.md is a frontend library — you must provide your own backend to receive form submissions via `postUrl`
- For full self-hosting, serve the dist files yourself; the npm package includes all assets
- RTL layouts use a separate CSS file: `formsmd.rtl.min.css`
- License: Apache-2.0

---

## References
- Documentation: https://docs.forms.md
- GitHub: https://github.com/formsmd/formsmd#readme
