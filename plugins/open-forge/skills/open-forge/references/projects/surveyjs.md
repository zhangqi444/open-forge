---
name: SurveyJS Form Library
description: "MIT-licensed client-side JS library for rendering dynamic JSON-based forms/surveys — React/Angular/Vue/jQuery/vanilla. Not self-hosted by itself; forms render in YOUR app + submit to YOUR backend. Companion commercial Survey Creator for drag-drop form builder."
---

# SurveyJS Form Library

SurveyJS Form Library is **NOT a self-hosted app** — it's a **client-side JavaScript library** you embed in YOUR web application to render dynamic, JSON-defined forms/surveys. MIT-licensed. The library displays forms, collects responses, and you handle persistence (to any backend you like). Because the entire SurveyJS product family is frequently bucketed under "self-hosted forms tooling" (especially when paired with Survey Creator + your own submit endpoint + your own DB), this recipe treats it as the **self-host-adjacent form/survey solution**.

**Product family — know what's MIT-free vs commercial:**

- **Form Library** — render JSON forms. **MIT**, free forever.
- **Survey Creator** — drag-drop form **builder** UI. **Commercial license** required for production use (free trial).
- **Dashboard** — visualize submissions. **Commercial.**
- **PDF Generator** — render forms as PDFs. **Commercial.**

Common self-host pattern: **you use the MIT Form Library + your own backend + your own DB** for a fully-free self-hosted survey solution. Add **Survey Creator** (commercial, per-domain license) if you need a WYSIWYG form builder.

Features of **Form Library** (MIT):

- **Native React / Angular / Vue / Knockout + vanilla JS** (jQuery via Knockout wrapper)
- **JSON-schema-based** — forms defined as JSON; portable between apps + versions
- **Multi-page forms** — paging, progress, conditional navigation
- **20+ input types** — text, rating, matrix, ranking, image-picker, signature, file, …
- **Input validation** — built-in + custom rules + async validators
- **Conditional logic / expression language** — show/hide/skip based on answers
- **Carry-forward / text piping** — dynamic text from prior answers
- **Autocomplete / cascading choices**
- **Load choices from web services** — populate dynamic dropdowns from APIs
- **Auto-save + partial submits + lazy loading**
- **Localization** — RTL + multi-locale forms + 50+ UI translations (community)
- **TypeScript typings**
- **Built-in themes + CSS customization**
- **e-Signature field**
- **Image capture** (camera)
- **Backend-agnostic** — integration examples for PHP, ASP.NET Core, Node.js
- **No submission limits** (library-level; limits live in YOUR backend)

- Upstream repo: <https://github.com/surveyjs/survey-library>
- Homepage: <https://surveyjs.io>
- Docs: <https://surveyjs.io/form-library/documentation/overview>
- Demos: <https://surveyjs.io/form-library/examples/overview>
- Release notes: <https://surveyjs.io/stay-updated/release-notes>
- Roadmap: <https://surveyjs.io/stay-updated/roadmap>
- Create a form (free tool): <https://surveyjs.io/create-free-survey>
- Backend integration examples: <https://surveyjs.io/backend-integration/examples>
- Survey Creator (commercial): <https://surveyjs.io/survey-creator/documentation/overview>

## Architecture in one minute

- **Pure client-side JS library** — ships as npm packages (`survey-core`, `survey-react-ui`, `survey-angular-ui`, `survey-vue3-ui`, `survey-js-ui`)
- **You build your own backend** for storing submissions (PHP / .NET / Node / Go / Python / whatever)
- **Survey JSON** = portable schema; store alongside submissions for reproducibility
- **No server-side SurveyJS component** — it's all browser-rendered
- **Resource**: negligible — it's a JS bundle loaded by your app

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Any web app        | `npm install survey-<framework>-ui survey-core`                    | **Upstream-primary**                                                               |
| Static HTML        | `<script src>` CDN or bundled                                             | Works                                                                                      |
| Self-host backend  | Your choice — PHP / ASP.NET / Node examples provided                                  | Upstream has repo examples                                                                             |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Host web app         | React / Vue / Angular / jQuery / vanilla                             | Framework    | Pick framework flavor                                                            |
| Backend for submits  | Node/Express, PHP/Laravel, .NET Core, Python/Django, ...                   | API          | Accepts form JSON + saves to DB                                                              |
| DB                   | Your choice — stores submissions                                                | Storage      | Postgres/MySQL/Mongo — whatever your stack prefers                                                              |
| Survey Creator license | Only if using drag-drop builder in production                                           | License      | Commercial — per-domain pricing                                                                                    |

## Install (Form Library, React example)

```sh
npm install survey-core survey-react-ui
```

Minimal app:
```js
import { Model } from "survey-core";
import { Survey } from "survey-react-ui";
import "survey-core/defaultV2.min.css";

const surveyJson = {
  elements: [
    { name: "email", title: "Your email", type: "text", isRequired: true },
    { name: "rating", title: "Rate us", type: "rating" }
  ]
};

function App() {
  const survey = new Model(surveyJson);
  survey.onComplete.add((sender) => {
    fetch("/api/submit-survey", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(sender.data)
    });
  });
  return <Survey model={survey} />;
}
```

## First boot

1. Design form JSON (hand-write for dev; use Survey Creator for prod-quality UX)
2. Drop into app — confirm render + completion
3. Implement backend endpoint (`POST /api/submit-survey` in the example)
4. Store submission as JSON column in DB (Postgres `jsonb` / Mongo native) alongside metadata (timestamp, user, survey version)
5. Store survey JSON schema versioned — critical for data reproducibility over time
6. Add auth if form isn't public (same app-auth mechanisms)
7. Consider honeypot / CAPTCHA for public forms (spam)
8. Analyze submissions: roll your own, or buy SurveyJS Dashboard (commercial)

## Data & config layout

- **No SurveyJS-managed data** — all data lives in YOUR backend/DB
- Form JSON schema — store alongside submissions for back-compat
- Submission rows — typically `{ survey_id, schema_version, submitted_at, data_json, user_id }`
- Files uploaded via SurveyJS file questions — decide: inline base64 (bad for large files) or upload-to-S3-and-store-url

## Backup

Back up YOUR backend DB. SurveyJS is just a JS library — nothing to back up on the library side.

## Upgrade

1. Releases weekly — <https://surveyjs.io/stay-updated/release-notes>. Disciplined cadence.
2. `npm update survey-core survey-<framework>-ui` — semver-respected.
3. Major versions can have breaking schema/API changes; test forms end-to-end after upgrade.
4. **Pin exact versions in production** — don't use `^` caret in package.json for SurveyJS if stability matters.

## Gotchas

- **It's a LIBRARY, not an APP.** You cannot "deploy SurveyJS" as a running service. Many self-host-lists index this entry; the actual self-host scenario is **your-app-built-with-SurveyJS**. Don't expect `docker run surveyjs`.
- **MIT Form Library = free. Survey Creator = commercial.** The drag-drop builder requires a paid license for production use. If your team needs WYSIWYG form authoring for multiple form creators, budget this. Alternative: hand-craft JSON (works, but requires dev skill per form).
- **Survey Creator license is typically per-domain + per-year** — review current pricing at <https://surveyjs.io/pricing>. Evaluation license available.
- **Form JSON is your source of truth.** Version the JSON alongside your app code. When you update a form mid-study, submissions from the old version must be joinable to the NEW version — store `schema_version` per submission + keep all historical JSON schemas.
- **Validation is client-side first.** Server-side validation MUST re-validate — attackers can bypass JS. Double-validate in your backend.
- **File-upload handling is YOUR problem.** SurveyJS renders the UI; you decide where the file goes. Don't send base64-encoded files through your form-submit endpoint at scale — that breaks at 10MB+ uploads. Use signed S3 uploads for file questions.
- **Public forms = spam magnet.** Rate-limit the submit endpoint + add hCaptcha/reCAPTCHA. SurveyJS has hCaptcha integration. Essential for public intake forms.
- **Privacy of responses**: if your survey collects PII/health/financial data, regulatory framework applies (GDPR/HIPAA/PIPEDA). Encrypt at rest; minimize data collected; publish privacy policy. Same regulated-data patterns as OpenEMR (batch 74), TaxHacker (batch 73).
- **Conditional logic testing** — complex expression logic needs regression tests. Add E2E tests for high-value forms (like insurance intake, medical history) that assert correct flows + validations.
- **Theme customization**: built-in themes cover most needs. Deep brand customization via CSS — expect time investment on pixel-perfect matches.
- **Offline capability** — SurveyJS has offline patterns (save to localStorage, submit later) but not built-in auto-offline. Implement per your app's needs.
- **Analytics**: no built-in. SurveyJS Dashboard (commercial) gives you analytics; or roll your own (Metabase / Superset / Grafana pointing at submission DB).
- **License**: Form Library is **MIT**. Survey Creator + Dashboard + PDF Generator are **commercial closed-source**. Transparent product-family tiering.
- **Governance**: SurveyJS is an established commercial company behind the OSS library — stable, long-running, sustained weekly releases.
- **Alternatives worth knowing:**
  - **Formbricks** — self-hosted survey platform (not just library); full app
  - **LimeSurvey** — PHP survey platform; full app
  - **Formio.js / form.io** — JSON-schema-based form builder; commercial + OSS parts
  - **Google Forms** — free cloud; zero privacy
  - **Jotform / Typeform / Tally** — commercial SaaS
  - **SurveyJS Creator** (commercial) — pairs with Form Library for full builder UX
  - **Choose SurveyJS Form Library if:** you have a web app + need JSON-schema forms + want MIT + can build your own backend.
  - **Choose Formbricks if:** you want a self-hosted SURVEY APP (not library).
  - **Choose LimeSurvey if:** you want a classic full-featured PHP survey platform.

## Links

- Repo: <https://github.com/surveyjs/survey-library>
- Homepage + product family: <https://surveyjs.io>
- Docs: <https://surveyjs.io/form-library/documentation/overview>
- Get started guides (per framework): <https://surveyjs.io/Documentation/Library>
- Demos: <https://surveyjs.io/form-library/examples/overview>
- Backend integration examples: <https://github.com/surveyjs/surveyjs_nodejs> (plus PHP/.NET variants)
- Release notes: <https://surveyjs.io/stay-updated/release-notes>
- Pricing (Creator/Dashboard/PDF): <https://surveyjs.io/pricing>
- npm: `survey-core`, `survey-react-ui`, `survey-angular-ui`, `survey-vue3-ui`, `survey-js-ui`
- Formbricks (self-hosted-app alt): <https://github.com/formbricks/formbricks>
- LimeSurvey (alt): <https://github.com/LimeSurvey/LimeSurvey>
- Formio.js (alt): <https://github.com/formio/formio.js>
