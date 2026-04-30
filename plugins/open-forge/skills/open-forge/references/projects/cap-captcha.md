---
name: Cap
description: "Lightweight, modern, open-source CAPTCHA alternative using SHA-256 proof-of-work + JavaScript instrumentation challenges. No images, no tracking, ~20kb, zero deps. Privacy-preserving replacement for reCAPTCHA / hCaptcha / Cloudflare Turnstile. Standalone Docker mode. Apache-2.0."
---

# Cap

Cap is **a privacy-respecting CAPTCHA replacement** that uses **SHA-256 proof-of-work** + JavaScript instrumentation challenges instead of "identify the traffic lights" image puzzles. The user's browser does a tiny bit of hashing work (invisible, a fraction of a second) to prove it's a real browser; no images, no tracking, no Google/Cloudflare dependency, no visual friction.

**~250× smaller than hCaptcha** (~20kb client-side, zero dependencies). Drop-in replacement for reCAPTCHA, hCaptcha, Cloudflare Turnstile on login/signup/comment/contact forms.

Works two ways:

- **Library mode** — embed in any JavaScript runtime (Node/Bun/Deno/browser); issue challenges + verify tokens
- **Standalone mode** — run the Cap server in Docker; your app validates tokens via API calls

Features:

- **SHA-256 proof-of-work** challenges (configurable difficulty)
- **Instrumentation checks** — catches headless browsers / automation
- **Privacy**: no telemetry back to Cap / the developer; zero third-party requests
- **Fully customizable** — CSS variables for colors, size, position, icons
- **Programmatic / invisible mode** — solve in the background
- **Machine-to-machine (M2M)** — friendly API auth
- **Analytics dashboard** (standalone mode)
- **Multi-framework client** — React, Vue, vanilla JS, etc.
- **Open source, Apache-2.0**

- Upstream repo: <https://github.com/tiagozip/cap>
- Website / docs: <https://trycap.dev>
- Demo: <https://trycap.dev/guide/demo>
- Effectiveness docs: <https://trycap.dev/guide/effectiveness>
- Alternatives comparison: <https://trycap.dev/guide/alternatives>
- Docker Hub: (see upstream)

## Architecture in one minute

- **Client widget** — ~20kb JS + CSS; drops into any form
- **Proof-of-work challenge**: client computes SHA-256 to find a nonce meeting server-specified difficulty → returns token
- **Server verifies**: token is validated against the challenge → grants/rejects
- **Library mode**: embed Cap's verification code in your backend (Node/Bun/Deno)
- **Standalone mode**: run Cap container, call its API for validation
- **No persistent state** needed for verification (tokens are stateless per challenge)

## Compatible install methods

| Mode                  | Runtime                                                       | Notes                                                                        |
| --------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Library**           | npm/jsr: `@cap.js/widget`, `@cap.js/server`                            | **Embed in Node/Bun/Deno backend**                                                 |
| **Standalone Docker** | `ghcr.io/tiagozip/cap:latest`                                                | Self-contained server with analytics UI                                                     |
| Cloudflare Workers    | Library works in Workers (Edge runtime)                                               | Possible                                                                                       |
| Raspberry Pi          | Docker or native Node                                                                         | Fine; Cap is tiny                                                                                           |
| Managed               | **trycap.dev** free instance (supported by DigitalOcean for OSS)                                              | Point-and-use, hosted                                                                                                 |

## Inputs to collect

| Input              | Example                                 | Phase      | Notes                                                                     |
| ------------------ | --------------------------------------- | ---------- | ------------------------------------------------------------------------- |
| Site key + secret  | generated per site                          | API        | Site key = public (widget), secret = backend verification                         |
| Challenge difficulty | low / medium / high                               | Tuning     | Higher = more PoW work = more bot-resistance + slightly slower UX                          |
| Domain(s)          | `www.example.com`                                        | Config     | Lock tokens to specific domains                                                                      |
| Port (standalone)  | `8080`                                                         | Network    | If running own server                                                                                          |
| Admin auth         | for analytics dashboard (standalone)                                       | Security   | Set before exposing                                                                                                      |

## Integrate as a library (Node.js example)

Client:

```html
<script src="https://cdn.jsdelivr.net/npm/@cap.js/widget"></script>
<cap-widget data-cap-api-endpoint="/api/cap"></cap-widget>
```

Server (Express/Fastify/etc.):

```js
import Cap from "@cap.js/server";
const cap = new Cap({ tokens_store_path: "./cap.db" });

// 1. Issue challenge
app.post("/api/cap/challenge", async (req, res) => {
  res.json(await cap.createChallenge());
});

// 2. Redeem challenge → token
app.post("/api/cap/redeem", async (req, res) => {
  const { token } = await cap.redeemChallenge(req.body);
  res.json({ token });
});

// 3. On actual form submit, verify token server-side
app.post("/signup", async (req, res) => {
  const { cap_token } = req.body;
  const valid = await cap.validateToken(cap_token);
  if (!valid) return res.status(403).send("bot?");
  // ... continue with signup
});
```

## Standalone Docker

```yaml
services:
  cap:
    image: ghcr.io/tiagozip/cap:latest              # pin in prod
    container_name: cap
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      CAP_ADMIN_TOKEN: CHANGE_ME                     # for analytics dashboard
    volumes:
      - ./data:/data
```

Your app calls Cap's HTTP API to verify tokens.

## First boot / integration

1. Bring up Cap (library or standalone)
2. Add widget to a test form
3. Submit form → widget runs PoW in background (~200ms) → token generated
4. Backend validates token via Cap API → pass/reject
5. Watch analytics dashboard (standalone) for challenge stats
6. Tune difficulty based on false-positive rate + bot noise

## Data & config layout

- Library mode: tokens stored in SQLite by default (`tokens_store_path`)
- Standalone: `/data/` inside container — SQLite + analytics
- Config via env vars

## Backup

```sh
tar czf cap-$(date +%F).tgz data/
```

Minimal state; mostly ephemeral tokens.

## Upgrade

1. Releases: <https://github.com/tiagozip/cap/releases>.
2. npm: `npm update @cap.js/widget @cap.js/server`.
3. Docker: bump tag.
4. Client widget is forward-compatible with older server versions generally, but test.

## Gotchas

- **PoW is not bulletproof.** Determined botnets can solve challenges; Cap raises the cost. Combine with rate limiting + bot-detection heuristics for full coverage. Cap's effectiveness doc is transparent about this.
- **Headless browser detection**: the JS instrumentation part detects Puppeteer/Playwright/Selenium. Real attackers use residential proxies + stealth plugins; arms race.
- **User experience trade-off**: higher PoW difficulty = longer solve time on weak devices (old phones). Default is tuned; don't over-tune.
- **Client-side cost**: browsers burn CPU for 100-500ms. Mobile battery impact is minimal; cumulative effect on many challenges across the web would be real (Cap addresses this with proof-of-work-per-site).
- **Lock tokens to domains** — prevent token replay across sites.
- **Expire tokens quickly** — default 60s is typical; longer windows enable replay.
- **M2M** — Cap has an API auth mode for programmatic traffic. Use this for legitimate bots (monitoring, partners) — issue them stable keys, don't serve them challenges.
- **Privacy story**: Cap doesn't call home. Inspect network traffic to confirm (worthy paranoia for privacy tool).
- **Analytics data (standalone)**: local only by default; don't accidentally expose the dashboard publicly.
- **No visual challenge fallback** — if a browser can't run JS, Cap can't challenge. Same as Turnstile/reCAPTCHA v3. If you need JS-disabled support, Cap isn't the answer.
- **Not suitable for "prove you're human in the strict sense."** For CSAM reporting / severe abuse gating, combine Cap + manual review + IP reputation. Cap blocks bots; it doesn't verify identity.
- **License**: **Apache-2.0**.
- **Alternatives worth knowing:**
  - **Google reCAPTCHA v2/v3** — SaaS; tracks users extensively; "free" but privacy-hostile
  - **hCaptcha** — SaaS; privacy better than reCAPTCHA but still third-party
  - **Cloudflare Turnstile** — SaaS; behind Cloudflare; privacy-decent; free
  - **Altcha** — similar PoW-based OSS alternative
  - **Friendly Captcha** — commercial PoW captcha
  - **mCaptcha** — Rust PoW-based OSS
  - **Rate limiting (no captcha)** — sometimes enough for low-value forms
  - **Honeypot fields** — old-school invisible-input trick
  - **Choose Cap if:** you want OSS + privacy-respecting + modern DX + self-hostable.
  - **Choose Turnstile if:** you already use Cloudflare + don't mind SaaS.
  - **Choose Altcha/mCaptcha if:** you want alternative PoW OSS.
  - **Choose reCAPTCHA/hCaptcha if:** you need the most mature anti-bot and accept privacy trade-offs.

## Links

- Repo: <https://github.com/tiagozip/cap>
- Website / docs: <https://trycap.dev>
- Demo: <https://trycap.dev/guide/demo>
- Effectiveness: <https://trycap.dev/guide/effectiveness>
- Alternatives comparison: <https://trycap.dev/guide/alternatives>
- NPM widget: <https://www.npmjs.com/package/@cap.js/widget>
- NPM server: <https://www.npmjs.com/package/@cap.js/server>
- Releases: <https://github.com/tiagozip/cap/releases>
- Altcha (alt): <https://altcha.org>
- mCaptcha (alt): <https://mcaptcha.org>
- Cloudflare Turnstile: <https://developers.cloudflare.com/turnstile/>
- hCaptcha: <https://www.hcaptcha.com>
