---
name: OpenSpeedTest
description: "HTML5 + JavaScript network performance estimation tool. Self-hosted internet + LAN speed test — no Flash, no app, browser-only. Runs anywhere serving static files. Docker + bare-metal. GPL-3.0. Great for ISP / homelab / enterprise network testing."
---

# OpenSpeedTest

OpenSpeedTest is **"speedtest.net on your own server, in HTML5, with no Flash + no tracking"** — a pure-HTML5/JavaScript network-performance estimator. Point your browser at it, hit start, measure download + upload + ping + jitter + packet-loss against **your chosen server** rather than some commercial speedtest provider's pre-selected endpoint. Useful for: testing your LAN performance, verifying your ISP's advertised speeds against a neutral point, diagnosing network issues, running unbranded speed tests inside an enterprise, integrating speed-tests into your homelab dashboard.

Built + maintained by **openspeedtest org** (Viswa Kumar + contributors). **GPL-3.0**. Simple, focused tool. Available as Docker image, npm package, GitHub Pages hosting, and commercial embedded SDK.

Use cases: (a) **ISP verification** — "am I actually getting the 1Gbps I'm paying for?" (b) **LAN performance testing** — test your wifi / wired LAN speeds without external-internet bottlenecks (c) **homelab dashboard widget** — integrate into Homarr / Homepage as a "network health" tile (d) **enterprise network testing** — unbranded + on-prem (no corporate data leaked to Ookla) (e) **remote support tool** — "run the speedtest I hosted + screenshot the result" (f) **multi-location-WAN testing** — deploy to each site; test between them (g) **VPN performance comparison** — test with + without VPN.

Features:

- **HTML5 + JavaScript** — browser-only; no apps, no Flash, no native install
- **Download + upload + ping + jitter** measurement
- **Packet-loss estimation**
- **IPv4 + IPv6** support
- **Client-side JS engine** — server is just static files
- **Works offline-LAN** — no internet dependency (after install)
- **Fully self-hosted** — no data to Ookla / speedtest.net
- **Responsive UI** — mobile + tablet + desktop
- **CLI client** available (pip / npm)
- **Dark mode + custom branding**
- **Embedable iframe** for integration into dashboards

- Upstream repo: <https://github.com/openspeedtest/Speed-Test>
- Homepage: <https://openspeedtest.com>
- Docker Hub: <https://hub.docker.com/r/openspeedtest/latest>
- CLI package (npm): <https://www.npmjs.com/package/openspeedtest>
- Self-host docs: <https://openspeedtest.com/SelfHosted.php>
- Demo: <https://openspeedtest.com>

## Architecture in one minute

- **Static HTML + JS + CSS** — served by any HTTP server
- **No backend logic** — client-side JS measures round-trip + large-file up/download speeds
- **Resource**: absurdly light — KB-scale assets; static-file-serving-only
- **Port 3000** (default Docker image via nginx inside)
- **Traffic volume**: speed tests TRANSFER large amounts of data per test; bandwidth planning needed if heavy-use

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`openspeedtest/latest`** (nginx + static assets inside)       | **Easiest path**                                                                   |
| Static web host    | nginx / Apache / Caddy serving the HTML/JS/CSS                            | Trivial deploy                                                                                   |
| GitHub Pages       | Clone + push to gh-pages                                                                | Absolutely free hosting                                                                                         |
| Node.js            | `npx openspeedtest` (CLI tool)                                                                         | Zero-config if Node installed                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain / IP          | `speedtest.example.com` or LAN IP                           | URL          | TLS optional but recommended                                                                                    |
| Port                 | 3000 default (Docker)                                       | Network      | Behind reverse proxy in production                                                                                    |
| Bandwidth budget     | Be aware of data transfer per test                                               | Planning     | Each test = ~100s of MB transferred                                                                                    |

## Install via Docker

```yaml
services:
  openspeedtest:
    image: openspeedtest/latest:latest     # **pin specific tag in prod**
    container_name: openspeedtest
    restart: unless-stopped
    ports:
      - "3000:3000"
```

That's it. No config. No volumes. Stateless.

## First boot

1. Start → browse `http://host:3000` → click "Start"
2. Test completes in ~30 seconds
3. Read download / upload / ping / jitter results
4. (opt) Configure reverse proxy for custom domain + TLS
5. (opt) Embed in homelab dashboard via iframe

## Data & config layout

- **NO PERSISTENT STATE** — OpenSpeedTest is stateless
- Results shown in-browser; not stored server-side unless you write custom logging

## Backup

- **Nothing to back up** — stateless. Redeploy from Docker image.

## Upgrade

1. Docker: `docker pull + up -d`.
2. No migrations; no state.
3. Check release notes for UI changes or measurement-algorithm updates.

## Gotchas

- **MEASUREMENT ACCURACY ≠ PHYSICAL LINK SPEED**: a speedtest measures **end-to-end user-perceived throughput between browser + server** which is affected by:
  - **Browser overhead** (JS parsing, DOM rendering)
  - **CPU bottleneck** on weak client devices
  - **WiFi quality** (radio issues can cap speed below wired-link capacity)
  - **Server CPU / network bottleneck** (your OpenSpeedTest server)
  - **Network path congestion** — not just physical link
  - **TCP window scaling + kernel tuning** on both sides
  - **Result**: a 10Gbps physical link might measure 2-3Gbps in a browser-based test. **This is a TOOL LIMITATION, not a network problem.** For true link-capacity testing: `iperf3` on both ends.
- **BANDWIDTH CONSUMPTION**: each OpenSpeedTest run transfers significant data. On a metered connection (cellular, data-cap ISP, cloud VPS with egress fees) you can rack up:
  - **One user-run**: ~50-500MB of transfer depending on link speed (faster link → bigger transfer to get statistically useful measurement)
  - **Publicly-exposed instance**: each visitor hitting "start" consumes your bandwidth. **Rate-limiting or access-restriction recommended**.
  - **DDoS amplification risk**: a public OpenSpeedTest is a mini-bandwidth-amplifier. Consider auth / IP-allowlist for public deploy.
- **IF HOSTING PUBLICLY, EXPECT ABUSE**: popular public OpenSpeedTest instances get hit regularly by automation + bandwidth-hogs. **Access control or rate limits are operationally necessary** for public deployment. For homelab / LAN / corporate-internal: no concern.
- **IPv4 vs IPv6 asymmetry**: your ISP may have very different IPv4 + IPv6 performance. Test both. OpenSpeedTest can bind to either (or both).
- **LAN TESTING vs INTERNET TESTING**: 
  - **LAN testing** (client + server both on local network): tests your wifi + switch + cable quality; isolates from ISP
  - **Internet testing** (server on remote VPS, client on home): tests your ISP uplink; typical speedtest use
  - **Deploy OpenSpeedTest on both sides** for comprehensive testing
- **SERVER CPU can bottleneck tests**: nginx serving 1GB/s of static data + a client asking for it → server CPU + kernel + network-stack tuning matter. **For gigabit+ testing, confirm server hardware can saturate the link.** Otherwise you're measuring server bottleneck, not client network.
- **TLS TERMINATION adds overhead**: for accurate max-speed-measurement, consider HTTP (not HTTPS) for LAN tests. HTTPS adds CPU overhead on both sides that caps measured speed (slightly). For public internet tests, TLS is mandatory despite the overhead.
- **MULTI-STREAM vs SINGLE-STREAM**: OpenSpeedTest uses multiple parallel HTTP connections. Single-stream throughput is lower than multi-stream for high-latency links (bandwidth-delay product). Don't confuse the two.
- **NO USER ACCOUNTS / NO AUTH / NO DATA STORAGE**: makes deployment trivial + removes all the secret-management gotchas that plague other recipes. **No immutability-of-secrets entry. No hub-of-credentials entry.** A pleasant rarity in this family of recipes.
- **AI AUTONOMY LEVELS**: OpenSpeedTest doesn't claim one but we're noticing these badges in this batch (OliveTin has one). Reserving pattern-flag for future consolidation.
- **GPL-3.0 license**: user-facing freedom + derivatives must remain GPL-3. Fine for self-hosting + internal use + modifications. Commercial redistribution of modified version requires GPL-3 compliance (source disclosure).
- **COMMERCIAL-TIER / EMBEDDED SDK**: OpenSpeedTest upstream offers a paid **embedded SDK** for integrating into commercial products. Standard commercial OSS tier. **"feature-gated embedded"** — the free version is fully functional; SDK/support paid.
- **ALTERNATIVES WORTH KNOWING:**
  - **LibreSpeed** — PHP/JS; very similar; arguably more established; LGPL-3.0
  - **speedtest-cli** — CLI wrapper around speedtest.net (uses Ookla infra)
  - **iperf3** — CLI true-throughput measurement; bidirectional; TCP+UDP; best for accurate measurement
  - **Speedtest Tracker** (dockerized variant) — automated-scheduled + historical-chart
  - **MyRepublic Speedtest** / Cloudflare / M-Lab — commercial public speedtests
  - **SmokePing** — long-term latency + packet-loss charts (complementary, not replacement)
  - **Choose OpenSpeedTest if:** you want HTML5 browser-based + self-host + easy-setup + GPL-3.
  - **Choose LibreSpeed if:** you want PHP + arguably more feature-rich + LGPL.
  - **Choose iperf3 if:** you want TRUE throughput measurement + CLI-based + accurate.
  - **Choose Speedtest Tracker if:** you want automated + historical-logging of speeds over time.
- **Project health**: active maintenance + commercial-SDK funding + stable mature tool + broad adoption. Positive signals.

## Links

- Repo: <https://github.com/openspeedtest/Speed-Test>
- Homepage: <https://openspeedtest.com>
- Self-host docs: <https://openspeedtest.com/SelfHosted.php>
- Docker: <https://hub.docker.com/r/openspeedtest/latest>
- Demo: <https://openspeedtest.com>
- LibreSpeed (alt): <https://librespeed.org>
- iperf3 (alt, CLI accurate): <https://iperf.fr>
- Speedtest Tracker (alt, historical): <https://github.com/alexjustesen/speedtest-tracker>
- SmokePing (latency monitoring): <https://oss.oetiker.ch/smokeping/>
