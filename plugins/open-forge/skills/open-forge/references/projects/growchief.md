---
name: GrowChief
description: "⚠️ LEGAL-RISK: social-media automation tool for LinkedIn/X outreach. Automates connection requests + follow-up messages via API. Alternative to Phantom Buster/Expandi/Zopto. AGPL-3.0. n8n/Make/Zapier integration. Commercial tier at growchief.com; self-host possible."
---

# GrowChief

GrowChief is **"Phantom Buster / Expandi / Zopto / LinkedIn Helper / Meet Alfred, self-hosted"** — a social-media automation tool for outreach at scale. Automates LinkedIn + X (Twitter) connection requests + follow-up messages via API. Targeted at sales teams, growth marketers, recruiters. Integrates with n8n / Make / Zapier for workflow automation.

Built + maintained by **GrowChief team** (linked to Postiz ecosystem). **License: AGPL-3.0**. Active; Discord (devs-only); commercial offering at growchief.com (cloud-hosted + platform tier).

> ## ⚠️ LEGAL + TOS RISK ADVISORY
>
> **Social-media automation violates the Terms of Service of LinkedIn, X (Twitter), Instagram, Facebook, and most major platforms.**
>
> - **LinkedIn User Agreement §8.2** explicitly prohibits automated tools: *"Develop, support or use software, devices, scripts, robots or any other means or processes (including crawlers, browser plugins and add-ons, or any other technology) to scrape the Services or otherwise copy profiles and other data from the Services."*
> - **X (Twitter) TOS** prohibits automated posting + engagement without API key with explicit permission for each use case
> - **Instagram + Facebook TOS** similarly prohibit automation
>
> **Consequences of detection:**
> - **Account suspension / permanent ban** (frequent)
> - **IP bans** for repeat offenses
> - **Legal action**: LinkedIn v. hiQ Labs (2017-2022) established LinkedIn's right to sue scrapers + automation vendors
> - **Business partner / recruiter network damage** if legit contacts flagged by automated-contact patterns
>
> **Some jurisdictions have specific anti-spam / automated-outreach laws:**
> - **CAN-SPAM Act (US)** — requires unsubscribe + accurate sender identity
> - **GDPR (EU)** — requires consent for unsolicited commercial messages
> - **CASL (Canada)** — similar strict consent requirements
> - **PECR (UK)** — similar
>
> **Use at your own risk.** Self-hosting doesn't shield you from platform enforcement OR regulatory enforcement.

Use cases (with caveats above):

(a) **LinkedIn Sales Navigator-style outreach** (ToS-violating) (b) **X growth automation** (ToS-violating) (c) **Recruiting sequencing** (ToS-violating) (d) **Legitimate uses** — there are few for fully-automated outreach; consider official LinkedIn Sales API / X Advertiser API / Twitter API v2 Premium for sanctioned automation.

Features (from upstream README):

- **Automated connection requests** (LinkedIn + X)
- **Follow-up message sequences**
- **n8n node** — npm package `n8n-nodes-growchief`
- **Web dashboard** for campaign management
- **API-based** — integrate into your stack
- **AGPL-3.0** — source-available
- **Connected to Postiz ecosystem** (social-media scheduling tool; same team likely)

- Upstream repo: <https://github.com/growchief/growchief>
- Homepage / platform: <https://growchief.com>
- Register (cloud): <https://platform.growchief.com>
- Docs: <https://docs.growchief.com>
- Discord (devs-only): <https://discord.growchief.com>
- n8n node: <https://www.npmjs.com/package/n8n-nodes-growchief>

## Architecture in one minute

- **API-based service** — likely Node.js/TypeScript (Postiz ecosystem)
- **Dashboard** for campaign definition
- **External integrations** via n8n / Zapier / Make
- **Uses LinkedIn/X APIs** (or automates browser sessions) for the actual outreach
- **DB**: Postgres likely (ecosystem-standard)
- **Resource**: varies with outreach volume

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Cloud platform** | **<https://platform.growchief.com>**                            | **Upstream-primary**                                                               |
| Self-host (Docker) | Per docs — may be limited vs cloud                                        | AGPL gives you the right                                                                                   |
| n8n integration    | Use as a node in existing n8n workflows                                                    | For automation-focused users                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Platform credentials | LinkedIn / X login + MFA                                    | **CRITICAL + LEGAL** | **Storing these violates platform ToS**                                                                                    |
| Target audience      | URLs / profile queries                                      | Campaign     | GDPR consideration if targeting EU residents                                                                                    |
| Message templates    | Outreach + follow-up text                                   | Campaign     | Must comply with CAN-SPAM/GDPR/CASL                                                                                    |
| Cadence settings     | Rate + timing of sends                                                                                       | Campaign     | Aggressive cadence = instant detection                                                                                    |
| Unsubscribe mechanism | REQUIRED in most jurisdictions                                                                                                          | Compliance   | **Regulatory requirement**                                                                                                            |

## Self-host caveat

Self-hosting GrowChief doesn't change the **platform-ToS violation** aspect — the action is automated outreach from your account, regardless of where the orchestration software runs. **Cloud or self-host, same ToS risk.**

## Gotchas

- **ToS VIOLATION is the HEADLINE RISK**: (see advisory banner above). Recipe convention: tools whose primary-use-case violates major-platform ToS get **prominent warning banners** + honest framing. **13th tool in network-service-legal-risk family — ToS-violation sub-family** (new sub-family; 1st tool). Distinct from:
  - Illegal-content-sub-family (pyLoad, *arr-piracy-tooling)
  - Music-royalty-sub-family (AzuraCast)
  - IoT-safety-sub-family (VerneMQ)
  - **ToS-violation-sub-family**: GrowChief + scrapers + automation-tools + (historically) hiQ Labs-class tools
- **39th tool in hub-of-credentials family — CROWN-JEWEL Tier 1**: GrowChief stores LinkedIn + X session cookies / API tokens / passwords + MFA codes. **8th tool in Crown-Jewel-Tier-1 sub-list.** Compromise = attacker has your social-media accounts + your outreach audience list + message history.
  - **Reputational blast radius**: attacker uses your accounts to send phishing/scam messages to YOUR CONTACTS. Major professional damage.
- **ACCOUNT-SAFETY THEATER vs REALITY**: some tools claim "undetectable" or "ToS-safe" — **no automation tool is truly undetectable**. LinkedIn + X invest heavily in detection:
  - Behavioral signals (click patterns, timing, sequences)
  - Browser-fingerprint analysis
  - IP reputation
  - ML-based anomaly detection
  - **Detection is probabilistic but real** — eventually most automation gets caught.
- **JURISDICTION-SPECIFIC ANTI-SPAM LAW**:
  - **CAN-SPAM (US)**: requires unsubscribe, accurate sender, no subject-deception. Automated-outreach violates if no consent + no unsubscribe.
  - **GDPR (EU)**: requires lawful basis for contact (typically consent OR legitimate-interest test). Unsolicited B2B messages fall into gray area.
  - **CASL (Canada)**: strict-opt-in required; heavy fines
  - **PECR (UK)**: similar
  - **Recipe convention: "jurisdiction-specific-anti-spam-law" framing** — regulatory risk amplifies ToS risk.
- **TARGET PII / DATA PROTECTION**: campaigns import lists of prospects (names, emails, LinkedIn URLs). These are personal data under GDPR:
  - Right to erasure when individuals request
  - Lawful basis for processing
  - Records of processing + DPO for high-volume
  - **Don't store target-audience data casually** — treat as regulated personal data.
- **LEGITIMATE ALTERNATIVES:**
  - **LinkedIn Sales Navigator + InMail** — LinkedIn's own paid tool; sanctioned
  - **LinkedIn Recruiter** — similar; for recruiting
  - **X Advertiser API / paid ads** — sanctioned way to reach X audience
  - **Email outreach** (with CAN-SPAM/GDPR compliance) — separate channel, better regulatory framework
  - **Content marketing + inbound** — slower but compliant
  - **Official LinkedIn API** (limited; requires partnership)
- **COMMERCIAL-TIER taxonomy**: GrowChief has **platform.growchief.com** hosted SaaS + self-host option. Standard **"primary-SaaS-with-OSS-of-record"** (like Feedbin batch 89) OR **"open-core"** — commercial features may be gated. **10+th commercial-tier entry or variation.**
- **ECOSYSTEM-CONNECTED**: linked to Postiz (social-media scheduler; gitroberts.io-ish footprint). **Watch as an ecosystem** — multi-product team building social-media-operations-tools.
- **SOLE-MAINTAINER to small team**: the Postiz ecosystem appears single-founder-led historically. **10th tool in sole-maintainer-with-community class; may have graduated to small-team.**
- **n8n INTEGRATION = AUTOMATION-STACK-READY**: the n8n node lets you trigger GrowChief from existing workflow tools. Design-friendly for automation-first teams BUT amplifies risk (larger attack surface if n8n compromised).
- **HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 reinforces**: 8 tools now in this tier. Security posture must be extreme:
  - MFA-protected admin
  - TLS + auth-in-front
  - IP-allowlist if possible
  - Short-session-timeouts
  - Audit-log review
  - Rotate social-media creds regularly
- **AGPL-3.0**: distinct commercial pressure — if you modify GrowChief + offer as a network service, you must publish modifications. Fine for self-host + internal use.
- **PROJECT HEALTH**: active + Discord (devs-only) + commercial-tier pressure + AGPL + n8n integration. Young but growing; ethical concerns due to use case.
- **ETHICAL CONSIDERATION / recipe-convention honest-framing**:
  - **We catalog GrowChief because it exists + users request self-host recipes**.
  - **We do not recommend ToS-violating use**.
  - **We frame honestly**: regulatory + ToS + reputational risks documented.
  - Compare to Bitmagnet/pyLoad framing: we catalog with honest-warning, not moralistic-skip.
  - **Recipe convention: neutral-honest-framing for legal-gray-area tools** (reinforces pyLoad batch 88 precedent).

## Links

- Repo: <https://github.com/growchief/growchief>
- Homepage: <https://growchief.com>
- Docs: <https://docs.growchief.com>
- n8n node: <https://www.npmjs.com/package/n8n-nodes-growchief>
- LinkedIn official API: <https://www.linkedin.com/developers/>
- LinkedIn Sales Navigator (legit alt): <https://business.linkedin.com/sales-solutions>
- X API: <https://developer.x.com>
- CAN-SPAM: <https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business>
- GDPR: <https://gdpr.eu>
- CASL: <https://crtc.gc.ca/eng/internet/anti.htm>
- hiQ v. LinkedIn case: <https://en.wikipedia.org/wiki/HiQ_Labs_v._LinkedIn>
