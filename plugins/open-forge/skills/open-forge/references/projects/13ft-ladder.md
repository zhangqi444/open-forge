---
name: 13 Feet Ladder (13ft)
description: "Self-hosted paywall / ad / nuisance bypass — mimics Googlebot to fetch articles behind soft paywalls that reveal content to search crawlers. Python Flask. Educational purposes + legal/ethical caveats. Unlicensed."
---

# 13 Feet Ladder (13ft)

13 Feet Ladder is **"self-hosted 12ft.io"** — a small Python web service that fetches web pages while **identifying itself as Googlebot**. Many news sites + Medium publications + publication-platforms show content to search engines (for SEO indexing) but hide it from regular visitors behind a soft paywall or signup wall. 13ft exploits that asymmetry.

Name is a play on "12ft.io" — the public service that inspired it. The author's stance (paraphrasing upstream README): **"support creators you benefit from; if you want one occasional article, this might help."** Upstream is disarmingly honest about the ethical position.

Built + maintained by **wasi-master** (Wasi Master). Tiny codebase (a few Python files). Dockerized. Widely forked.

**Ethical + legal caveats FRONT-LOADED — see Gotchas.** This is a tool with distinct risk surface; treat its recipe accordingly.

Features:

- **Paywall bypass** for sites that soft-block regular visitors
- **Simple Flask web UI** — paste URL, get article
- **Or browser-extension pattern** — redirect through your instance
- **Self-hosted** = no third-party logs of what you read
- **Docker + Python** standalone install

- Upstream repo: <https://github.com/wasi-master/13ft>
- Docker Hub: <https://hub.docker.com/r/wasimaster/13ft>
- GHCR: <https://ghcr.io/wasi-master/13ft>
- Original inspiration: <https://12ft.io> (public SaaS of the same concept; has had takedown activity)
- Author: <https://github.com/wasi-master>

## Architecture in one minute

- **Python 3** + Flask
- **No database** — stateless; each request fetches upstream
- **Spoofs `User-Agent: Googlebot/2.1`** header
- **Respects robots.txt? — NO, explicitly bypasses.** That's the point.
- **Resource**: tiny — 50-100MB RAM

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | `wasimaster/13ft` or `ghcr.io/wasi-master/13ft`            | **Upstream-primary**                                                               |
| Python script      | `pip install -r requirements.txt && python portable.py`                           | Local run                                                                                  |
| Single-user VPS    | Private instance — recommended                                                                       | **Never expose publicly**                                                                                |
| **NOT RECOMMENDED**| Public-facing instance                                                                                           | Legal + operational risk (see Gotchas)                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Access control       | VPN / tailnet / localhost-only / basic-auth                             | **REQUIRED** | Do NOT expose to public Internet                                                                             |
| Port                 | 5000 (Flask default)                                                    | Network      | Behind reverse proxy                                                                                       |
| TLS                  | Reverse proxy                                                                        | Security     | Not strictly required on tailnet but good practice                                                                          |

## Install via Docker

```sh
git clone https://github.com/wasi-master/13ft.git
cd 13ft
docker compose up -d
# Access via http://localhost:5000 (or whatever it maps to)
```

Or pull directly:
```sh
docker run -d -p 5000:5000 wasimaster/13ft:latest    # pin version in practice
```

## First boot

1. Deploy locally or on your tailnet/VPN
2. Test: paste a Medium URL → verify article rendering
3. **DO NOT EXPOSE PUBLICLY** — add auth or keep on a private network
4. Install browser extension or bookmarklet that prepends `http://<your-13ft>/` to URLs
5. Monitor for abuse if anyone else has network access

## Data & config layout

- No persistent data
- Config via env vars (port, bind)

## Backup

Nothing to back up. It's stateless.

## Upgrade

1. Releases: <https://github.com/wasi-master/13ft/releases>. Sporadic cadence.
2. `docker pull && docker compose up -d`.
3. Low-risk; small codebase.

## Gotchas

- **LEGAL + ETHICAL RISK — READ CAREFULLY.**
  - **Terms of Service violations**: most publishers' ToS prohibit circumvention of access controls. Using 13ft to read paywalled content likely violates the site's ToS. ToS violations are generally civil, not criminal, but they CAN form the basis for service-level consequences (IP blocks, account bans).
  - **DMCA / CFAA (US) gray area**: bypassing a "technological protection measure" can implicate DMCA §1201 (anti-circumvention). Soft paywalls like "content hidden unless you sign in" — case law is mixed. The Computer Fraud and Abuse Act (CFAA) has been used against people who accessed content in ways the site didn't authorize. **Consult a lawyer before running a PUBLIC instance in the US.** Similar framing to Scanopy (batch 76) CFAA warning + Unbound (batch 80) DNS-amp-crime + MicroBin (batch 81) pastebin-abuse — fifth tool in the **network-service-legal-risk class**.
  - **EU Copyright Directive (Article 17 / DSM)** may restrict systematic paywall circumvention services.
  - **Takedowns happen**: 12ft.io (the public inspiration) has faced legal pressure + cloud-provider takedowns. Hosting a PUBLIC instance invites the same.
  - **Author's own framing** in README is thoughtful: "support creators" + "if you just want one article". That's the intended usage pattern.
- **Goal of self-hosting this tool:** privacy (no third-party sees what you read) + availability (no takedowns affecting you) — NOT scaling abuse.
- **Do NOT run a public-facing instance.** Legal risk + abuse magnet + operational burden (load, cost, law-enforcement requests). Keep it on your tailnet/VPN/localhost.
- **Googlebot spoofing = abuse of SEO access.** The trick works because publishers give Googlebot full content for indexing. If enough tools do this at scale, publishers will fingerprint more aggressively → arms race → techniques fail.
- **Doesn't work on hard paywalls.** Sites that DO verify Googlebot (reverse-DNS lookup) or use JavaScript-gated paywalls (content is never in initial HTML) will not yield to 13ft. It's a soft-paywall tool.
- **Browser-based reading plugins (Bypass Paywalls Clean extension)** have similar scope without self-hosting. Different tradeoff.
- **Consider a simpler ethical alternative:**
  - **Archive.is / archive.org** — public archives often have cached versions without paywall
  - **Browser reader mode** — strips overlays but doesn't get past server-side paywalls
  - **Actually subscribe** to publications you read frequently — supports journalism + removes friction
  - **Library / employer access** — many institutions have subscriptions
- **License**: **Unlicensed** / unclear per repo. Check latest LICENSE file. Treat as "code available" rather than "free-software licensed" until explicit.
- **Project health**: single-author + niche + small codebase. Bus-factor-1 doesn't matter much — the tool is so simple that a fork or rewrite is weekend work.
- **Server log content-privacy**: when 13ft fetches for you, the URL is in YOUR server's access logs + upstream traffic logs. Using it doesn't hide what you read from your hosting provider — only from the publishing site.
- **User-Agent rotation or evasion**: some sites detect "fake Googlebot" vs "real Googlebot" via ASN reverse-lookup. When that detection ships at a site, 13ft fails against it.
- **No caching = repeated upstream load** per request. Not great for heavy use; fine for occasional reads.
- **Alternatives worth knowing:**
  - **12ft.io** — original; commercial-but-free SaaS; has had takedown pressure
  - **archive.today / archive.is** — snapshots; different approach
  - **archive.org (Wayback Machine)** — legal + ethical + trusted
  - **Bypass Paywalls Clean** (browser extension) — client-side; not self-hosted
  - **nitter** / **invidious** / **libredirect** — privacy-respecting front-ends to specific services (different goal: privacy + minimalism, not paywall-bypass)
  - **Pocket / Instapaper / Readwise Reader** — paid read-it-later services that save articles for offline reading (often capture content before paywall re-check)

## Links

- Repo: <https://github.com/wasi-master/13ft>
- Docker Hub: <https://hub.docker.com/r/wasimaster/13ft>
- GHCR: <https://github.com/wasi-master/13ft/pkgs/container/13ft>
- Original 12ft.io: <https://12ft.io>
- Archive.today (alt): <https://archive.ph>
- Wayback Machine (alt): <https://web.archive.org>
- Bypass Paywalls Clean (extension): <https://github.com/bpc-clone/bypass-paywalls-clean-filters>
- EFF on CFAA: <https://www.eff.org/issues/cfaa>
- DMCA §1201 overview: <https://www.eff.org/issues/dmca>
