---
name: SparkyFitness
description: "Self-hosted, privacy-first MyFitnessPal alternative. Nutrition + exercise + hydration + sleep + fasting + mood + body tracking. Backend + web frontend + native iOS/Android apps. 20+ language translations. Multi-user + family access. License varies — check upstream."
---

# SparkyFitness

SparkyFitness is **"MyFitnessPal, self-hosted, without data harvesting"** — a comprehensive fitness + nutrition + health tracking platform. Backend server stores your food log, exercise log, hydration, sleep, fasting, mood, body measurements. Web frontend + native mobile apps (iOS + Android) for daily use. Designed so your health data — which is among the most personal categories — stays on infrastructure you control. Multi-user with family-access support.

Built + maintained by **CodeWithCJ** (chhavi-jaiswal). **License: check LICENSE in repo** (README implies OSS but specific license should be verified by reader). Active; translated into 20+ languages; privacy-first positioning explicit.

Use cases: (a) **escape MyFitnessPal** — after its 2018 breach (150M accounts) + Under Armour sale (b) **diabetes / chronic-condition tracking** — store glucose, meds, symptoms in one place (c) **family health tracking** — parent + kids + grandparents on one instance (d) **athletic performance tracking** — runners / cyclists / lifters with training-log needs (e) **weight-loss journey** without company-selling-data — GDPR-native health app (f) **clinical-research prep** — patient-collected data pipeline into clinical settings.

Features (from upstream README):

- **Nutrition tracking** — food log with database
- **Exercise tracking** — workouts + calorie burn
- **Hydration** — daily water intake
- **Sleep tracking**
- **Fasting tracking** — intermittent fasting windows
- **Mood tracking**
- **Body measurement tracking** — weight, circumferences, composition
- **Goal setting + daily check-ins**
- **Interactive charts + long-term reports**
- **Multi-user + family access**
- **Backend API + web frontend + native iOS/Android apps**
- **20+ language translations**
- **Privacy-first** — data stays on infrastructure you control
- **No third-party services required**

- Upstream repo: <https://github.com/CodeWithCJ/SparkyFitness>
- Homepage / docs: check repo

## Architecture in one minute

- **Backend server** — API + data storage (tech stack per repo)
- **Web frontend** — browser access
- **iOS app** (native)
- **Android app** (native)
- **DB**: likely Postgres or similar
- **Resource**: moderate — depends on user count + data volume

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided compose** (check repo for canonical setup)  | **Typical path**                                                                   |
| Bare-metal         | Node.js or similar per repo                                               | DIY                                                                                   |
| Mobile apps        | iOS App Store / Android Play Store or F-Droid                                                  | Complementary to server                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `fitness.example.com`                                       | URL          | TLS MANDATORY                                                                                    |
| DB                   | Postgres / whatever upstream specifies                      | DB           | Per docs                                                                                    |
| Admin creds          | First-boot                                                                                   | Bootstrap    | Strong password                                                                                    |
| Secret keys          | JWT / encryption-at-rest                                                                                    | **CRITICAL** | **IMMUTABLE**                                                                                                            |
| Mobile API endpoint  | Your self-hosted URL configured in mobile app                                                                                                           | Mobile       | Each family member                                                                                                                            |

## Install (per upstream)

Check `README.md` and `docker-compose.yml` in the repo for canonical setup instructions. Recipe convention: when upstream install-details are sparse in README, defer to upstream docs rather than fabricate. (See recipe constraints — do NOT fabricate install steps.)

## Gotchas

- **HEALTH DATA = SPECIAL-CATEGORY PERSONAL DATA** (GDPR Article 9): your fitness/health data is legally SENSITIVE:
  - **GDPR Article 9** — special category; needs explicit consent OR specific legal basis for processing
  - **HIPAA (US)** — applies if you're a covered entity (health provider, insurer); NOT applies to personal tracking (but best practices worth following)
  - **UK DPA 2018** — mirrors GDPR special-category protections
  - **State laws (US)** — various: California CMIA, Illinois BIPA (biometrics), Washington My Health My Data Act (2024; strict)
  - **Biometric data** (body composition scans) has additional protections in many jurisdictions
  - **40th tool in hub-of-credentials family — HEALTHCARE-CROWN-JEWEL sub-family** (new: 1st tool)
  - **Regulatory-crown-jewel sub-families** now 3-named: financial (Bigcapital 90, Lunar 92), research (LimeSurvey 90), **healthcare (SparkyFitness 94)**.
- **MULTI-USER FAMILY ACCESS = PRIVACY-BOUNDARY COMPLEXITY**: family-access means one family member can (potentially) see another's data. Spouses + teens + adult children want different scopes:
  - Teen-adolescent weight data is particularly sensitive (eating disorder triggers)
  - Adult children may not want parents seeing menstrual tracking or sexual-health
  - Domestic-violence context: abuser with admin access = surveillance tool
  - **Default to private per-user; opt-in sharing; granular sharing scopes.**
- **EATING-DISORDER / MENTAL-HEALTH RISK**: fitness-tracking apps have documented associations with disordered eating + body-image distortion:
  - **Calorie-counting triggers** for ED-prone individuals
  - **Weight-tracking charts** can reinforce obsession
  - **Wellness-claim-boundary-respect** (from Moodist batch 93): SparkyFitness is a tool, not a therapy. Doesn't overreach into medical-claims (good).
  - Consider: opt-in for ED-sensitive features, warnings, helpline resources linked
- **DATA-BREACH CONSEQUENCES amplified for health data**: MyFitnessPal's 2018 breach exposed 150M accounts (emails + usernames + hashed passwords). Self-hosting doesn't change the risk profile — it changes **whose responsibility** the breach is. Security posture must be rigorous:
  - At-rest encryption for sensitive fields (weight, body-comp, glucose, menstrual cycles)
  - TLS 1.3 mandatory
  - Strong auth + MFA
  - Breach-notification procedure (GDPR 72h)
  - Audit logging
  - Regular backup + restore drills
- **MOBILE APPS = ADDITIONAL ATTACK SURFACE**:
  - API endpoints exposed for mobile
  - Mobile app stores pinning (to your self-hosted backend) = trust chain
  - OAuth flows / session tokens on device
  - **Device theft / compromise = full data exposure** unless E2E-encrypted
- **FAMILY-ACCESS RBAC QUALITY MATTERS**: check whether SparkyFitness implements proper per-user permissions at DB-level + API-level, or just UI-level. Weaker-than-advertised sharing = real privacy violation.
- **WOMEN'S HEALTH + REPRODUCTIVE DATA**: period tracking + fertility/menstrual data has become legally sensitive in post-Dobbs US context. Some US states have subpoenaed period-tracking data in abortion-law enforcement. Self-hosting helps BUT:
  - Consider E2E encryption for the most-sensitive fields
  - Don't store if not needed
  - Provide easy-delete UX
  - Consider a legal threat model, not just hacker-threat model
  - **Post-Dobbs-US regulatory-crown-jewel consideration** — 1st explicit flag.
- **FOOD DATABASE INTEGRATION**: most fitness apps use external food databases (USDA, Open Food Facts, MyFitnessPal/Fatsecret DBs). Check:
  - Which food DB SparkyFitness uses + license + refresh mechanism
  - Privacy: do food searches go to external DB? Self-host via sync?
  - Data freshness + completeness
- **EXPORT + DATA-PORTABILITY**: for health data, export-ability is critical. GDPR Article 20 (right to portability). Verify SparkyFitness supports structured export (JSON / CSV / FHIR / OpenmHealth).
- **HUB-OF-CREDENTIALS SUB-FAMILY: HEALTHCARE-CROWN-JEWEL**: SparkyFitness + Fasten Health + Nightscout + OpenEMR (pending) + Nextcloud Health + SelfPrivacy-health = emerging health-data self-host subcategory. **Recipe convention: flag as healthcare-crown-jewel sub-family of hub-of-credentials.**
- **SOLE-MAINTAINER**: CodeWithCJ / chhavi-jaiswal. Bus-factor-1 mitigated by OSS license (check) + community + forkability. **11th tool in sole-maintainer-with-community class.**
- **20+ LANGUAGE TRANSLATIONS**: strong internationalization signal (via OpenAITx translation service per README header). More lang-coverage than most sole-maintainer projects. **Positive stewardship.**
- **AI-TRANSLATION NOTE**: OpenAITx (openaitx.github.io) is AI-powered translation. **Translation quality may vary** — positive for availability; verify accuracy for your language before serious use. Native-speaker audit recommended.
- **COMMERCIAL-TIER**: no paid tier explicit; appears donation-based (check repo for Sponsors/BMC). **Likely 12th tool in pure-donation category** (pending verification).
- **ALTERNATIVES WORTH KNOWING:**
  - **MyFitnessPal** — commercial SaaS; 2018 breach infamy; Under Armour-owned
  - **LoseIt!** — commercial SaaS
  - **Cronometer** — commercial; data-accuracy-focused; solid
  - **Fitly / Nutritracker** (various OSS attempts, varying maturity)
  - **Nightscout** — self-hosted diabetes / CGM focus
  - **OpenAPS / Loop** — automated-insulin-dosing (hardware-integrated)
  - **wger** — FOSS workout manager (not nutrition-focused)
  - **Senpai** — wellness tracking (various stages)
  - **Choose SparkyFitness if:** you want COMPREHENSIVE + self-host + multi-user + mobile-apps + privacy-first.
  - **Choose Cronometer if:** you accept commercial + want best-in-class food-DB + macro accuracy.
  - **Choose wger if:** you want exercise-log-only + mature FOSS.
  - **Choose Nightscout if:** diabetes-specific.
- **PROJECT HEALTH**: active + 20+ translations + native mobile apps (significant engineering investment) + privacy-first positioning. Growing.

## Links

- Repo: <https://github.com/CodeWithCJ/SparkyFitness>
- Cronometer (commercial alt): <https://cronometer.com>
- MyFitnessPal (incumbent): <https://www.myfitnesspal.com>
- Nightscout (diabetes): <https://nightscout.github.io>
- wger (exercise): <https://wger.de>
- Open Food Facts (food DB): <https://world.openfoodfacts.org>
- OpenmHealth (health-data standards): <https://www.openmhealth.org>
- FHIR (health-data standards): <https://www.hl7.org/fhir/>
- GDPR Art. 9: <https://gdpr-info.eu/art-9-gdpr/>
- Washington My Health My Data Act: <https://www.atg.wa.gov/washington-my-health-my-data-act>
