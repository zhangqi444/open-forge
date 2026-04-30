---
name: Lunar
description: "Modern headless Laravel e-commerce platform. Set of packages bringing Shopify/BigCommerce-like backend to any Laravel app. Admin panel built on Filament; core provides models/actions/utilities. MIT. Headless-first — BYO storefront. Active community + Discord + roadmap."
---

# Lunar

Lunar is **"Shopify for Laravel, but you own it"** — a set of Laravel packages providing the backend logic of a full e-commerce platform (products, orders, carts, checkout, tax, shipping, customers, inventory, discounts, multi-currency) + a polished admin panel built on Filament. You bring your own storefront (Blade / Inertia / Livewire / Nuxt / Next / React Native — whatever Laravel can serve or talk to via API). Headless-first architecture.

Built + maintained by **Lunar team** (lunarphp org) — originated as **GetCandy** (renamed to Lunar in 2022). **License: MIT**. Active development + Discord + roadmap + v1.0 released. Laravel ecosystem integration is first-class.

Use cases: (a) **custom-branded storefront** that can't fit Shopify's template constraints (b) **B2B commerce** with custom pricing, quoting, approvals (c) **marketplace / multi-vendor** (with extensions) (d) **subscription / digital products** (e) **GDPR-native European e-commerce** — data stays in your infra (f) **integrated with existing Laravel app** — user DB / CMS / ERP shared (g) **agency-built bespoke online stores** — Lunar as accelerator vs building from scratch.

Features (from upstream README + ecosystem):

- **Admin panel** — Filament-based; modern, extensible
- **Product management** — variants, attributes, collections, brands
- **Multi-channel** — different products / prices / inventory per channel
- **Multi-currency + multi-language**
- **Orders + fulfillment** workflow
- **Customer management** + groups + pricing tiers
- **Tax zones + tax engines** — multi-jurisdiction
- **Shipping methods + zones**
- **Discount engine** — percentage, fixed, BOGO, coupons
- **Inventory management**
- **Storefront-agnostic** — REST/GraphQL API + Livewire components
- **Extensible** — standard Laravel package ecosystem; add your models + listeners
- **Stripe, PayPal, Mollie adapters** (via community / additional packages)
- **Roadmap + active dev**

- Upstream repo: <https://github.com/lunarphp/lunar>
- Homepage: <https://lunarphp.com>
- Docs: <https://docs.lunarphp.com>
- Discord: <https://lunarphp.com/discord>
- Roadmap: <https://github.com/orgs/lunarphp/projects/9>
- Filament (admin framework): <https://filamentphp.com>

## Architecture in one minute

- **Laravel 11+ / PHP 8.2+** — host framework
- **Filament 3** — admin panel framework
- **MySQL / MariaDB / PostgreSQL** — DB (via Laravel Eloquent)
- **Redis** — recommended for cache / queues / sessions
- **Storefront**: YOURS — Lunar is headless + packages into your Laravel app
- **Resource**: moderate-to-heavy — 500MB-2GB+ RAM depending on traffic + storefront

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Composer install into Laravel app** | **`composer require lunarphp/lunar`** — primary path   | **Not a standalone self-host product — integrates into Laravel**                 |
| Laravel Sail (dev) | Docker-based dev environment                                              | For local dev                                                                                   |
| Laravel Forge / Envoyer | Production deploy tooling                                                                | Typical Laravel prod path                                                                                               |
| Bare Linux + nginx + PHP-FPM | Classic PHP deploy                                                                              | For DIY production                                                                                                 |
| Docker (community) | Community-built images exist                                                                                                | Not upstream-primary                                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Laravel app          | New or existing                                             | Prereq       | Lunar is a Laravel package                                                                                     |
| DB                   | MySQL / MariaDB / Postgres                                  | DB           | Laravel-standard options                                                                                     |
| Domain               | `shop.example.com`                                          | URL          | TLS MANDATORY — PCI scope                                                                                     |
| `APP_KEY`            | Laravel                                                                                     | **CRITICAL** | **IMMUTABLE** (encrypts sessions + DB fields)                                                                                     |
| Payment gateway creds| Stripe/PayPal/Mollie API keys                                                                                  | **CRITICAL** | **IMMUTABLE for active subscriptions**                                                                                                            |
| Tax engine           | Built-in + TaxJar/Avalara for complex jurisdictions                                                                                                           | Tax          | Regulatory depth                                                                                                                            |

## Install via Composer

```sh
# In your Laravel app:
composer require lunar/lunar
php artisan lunar:install
php artisan migrate
php artisan lunar:scout:init
# Create admin user
php artisan lunar:hub:install
# Seed demo data (optional)
php artisan db:seed --class=LunarDemoSeeder
```

## First boot

1. Browse `/admin` (Filament admin panel) → log in with seeded admin creds
2. Configure default channel + currency + language
3. Create first product + variant + collection
4. Configure tax zones for your jurisdictions + shipping methods
5. Connect payment gateway (Stripe recommended; install `lunarphp/stripe` addon)
6. Build storefront (Blade / Livewire / Inertia) against Lunar's models + components
7. Configure queues (`php artisan queue:work` + Horizon for production)
8. Put behind TLS + CDN for storefront assets
9. **Test entire checkout flow on staging** before going live

## Data & config layout

- Laravel app root — `config/lunar.php` per-package configs
- DB — Lunar tables prefixed `lunar_*`
- `storage/app/` — uploaded product media
- `.env` — all secrets (APP_KEY, DB, Stripe, etc.)
- `filament/` — Filament admin panel resources

## Backup

```sh
mysqldump -u lunar -p lunar > lunar-$(date +%F).sql
tar czf lunar-storage-$(date +%F).tgz storage/
```

## Upgrade

1. Releases: <https://github.com/lunarphp/lunar/releases>. v1.0 out + active.
2. `composer update lunar/lunar && php artisan migrate`.
3. **Review release notes for breaking changes** — Filament + Lunar both evolve.
4. **BACK UP DB + storage BEFORE major upgrades** — PCI-regulated data.
5. Staging-upgrade-first is essential for e-commerce (downtime = lost revenue).

## Gotchas

- **E-COMMERCE = HIGHEST-STAKES-INFRASTRUCTURE** (reinforces Hi-Events batch 89, Bigcapital 90):
  - **PCI-DSS SCOPE**: handling card data puts you IN PCI scope. **Use Stripe Elements / Stripe.js** (tokenization on client-side) so card data NEVER touches your server = SAQ-A scope. Don't submit raw card data to your Lunar backend.
  - **Fraud risk** — e-commerce storefronts are #1 targets for:
    - Card testing (thousands of micro-transactions to validate stolen cards)
    - Account takeover (stolen customer accounts)
    - Return fraud
    - Chargeback abuse
    - Configure Stripe Radar / Sift / fraud.net to protect
  - **Sales tax liability** — US (post-Wayfair): collect + remit in states where you have nexus. EU: VAT-OSS for B2C. Complex; regulatory. Use TaxJar or Avalara integrations for non-trivial jurisdictions.
- **31st tool in hub-of-credentials family — CROWN-JEWEL TIER 1**: Lunar stores:
  - Stripe/PayPal/Mollie API keys (live + test)
  - Customer PII (names, addresses, phones, emails, purchase history)
  - Order details (what they bought, when, how much)
  - Tax IDs (for some B2B)
  - NO raw card data (if using Stripe Elements properly)
  - **Compromise = customer-data-breach + financial-fraud-amplifier + regulatory-nightmare.**
  - **GDPR Article 32 + PCI requirements: at-rest encryption, TLS in transit, access audit, breach-notification within 72h.**
- **FINANCIAL-DATA REGULATORY CROWN-JEWEL** sub-family (reinforces Bigcapital 90, Invoice Ninja, Akaunting, Crater):
  - SOX / IFRS / GAAP for public-company sales records
  - Tax retention (7-10 years US, varies EU)
  - Payment data logs (PCI-specific retention)
  - **2nd tool in financial-data-regulatory-crown-jewel sub-family** (Bigcapital was 1st).
- **`APP_KEY` + STRIPE KEYS IMMUTABILITY**: Laravel APP_KEY + payment-gateway keys. **25th tool in immutability-of-secrets family.** Rotating payment gateway keys = potential brief outage; coordinate carefully.
- **HEADLESS ARCHITECTURE = STOREFRONT IS YOUR RESPONSIBILITY**: Lunar's Admin panel is well-designed; your storefront UX is entirely your problem. Budget design + development + testing + accessibility (WCAG) + performance (Core Web Vitals) + SEO. Most commerce agencies charge 2-5x more for custom storefront than for using Shopify themes.
- **INVENTORY OVERSELLING**: without proper locking / reservation during checkout, concurrent buyers can over-buy limited stock. Lunar supports reservation; configure it + use DB-level row locking on inventory-decrement.
- **CART EXPIRATION + ABANDONED CART RECOVERY**: core feature of e-commerce. Lunar gives hooks; building the recovery email flow is on you (or via addon). Abandoned cart emails require GDPR-consent in EU.
- **MULTI-CHANNEL COMPLEXITY**: different pricing/inventory per channel (web / retail / B2B) is powerful but adds substantial config complexity. Design channel strategy before enabling.
- **TAX RULES = CONTINUOUS MAINTENANCE**: tax rules change constantly (new states, new EU VAT rates, Brexit, post-Wayfair evolution). Subscribe to tax service (TaxJar, Avalara, Stripe Tax) if serious.
- **AGENCY-BUILT CUSTOM E-COMMERCE** is a common commercial pattern — Shopify is "good enough" for most; custom Lunar builds are for differentiated brands + agencies + complex B2B. Budget realistically: Lunar build = $20k-200k+ depending on scope.
- **GETCANDY LINEAGE**: Lunar was renamed from "GetCandy" in ~2022. Older docs / blog posts may reference GetCandy; current canonical is lunarphp.
- **MIT LICENSE**: permissive, minimal obligations. Reuse freely in commercial products. Positive signal for commercial adoption.
- **COMMERCIAL-TIER**: no paid hosted SaaS (yet); no paid support contracts explicitly listed. Community-funded at the moment. **Pattern: "paid services around OSS" likely exist via agency network**, not formally from Lunar org.
- **INSTITUTIONAL-STEWARDSHIP**: lunarphp org (with E-Commerce company Alcumus / Tekton Labs lineage historically). Active development signals. **15th tool in institutional-stewardship.**
- **NOTES ON COMMERCE-PLATFORM COMPARISON:**
  - **Shopify** — commercial SaaS; lowest effort; highest lock-in; transaction fees
  - **WooCommerce** — WordPress plugin; massive ecosystem; PHP; GPL
  - **Magento / Adobe Commerce** — enterprise e-commerce; complex; commercial + open-source
  - **PrestaShop** — OSS PHP; European base; mid-scale
  - **Medusa** — Node.js headless commerce; MIT; similar positioning to Lunar but Node
  - **Saleor** — Python/Django GraphQL-first; BSD; enterprise-focus
  - **Vendure** — Node.js/TypeScript headless; MIT
  - **Reaction Commerce** — Node.js / Meteor-origin
  - **OpenCart** — PHP; mid-scale; GPL
  - **CS-Cart** — PHP commercial
  - **Choose Lunar if:** Laravel-ecosystem + headless-flexibility + MIT + Filament-admin + moderate-scale.
  - **Choose Medusa/Saleor/Vendure if:** Node/Python preferred.
  - **Choose WooCommerce if:** WordPress-ecosystem + plugin-rich + smaller-scale.
  - **Choose Shopify if:** minimize-engineering + standard-store + accept fees.
- **PROJECT HEALTH**: v1.0 released + active + Discord + roadmap + Laravel/Filament ecosystem integration. Positive signals.

## Links

- Repo: <https://github.com/lunarphp/lunar>
- Homepage: <https://lunarphp.com>
- Docs: <https://docs.lunarphp.com>
- Discord: <https://lunarphp.com/discord>
- Roadmap: <https://github.com/orgs/lunarphp/projects/9>
- Filament: <https://filamentphp.com>
- Medusa (alt Node): <https://medusajs.com>
- Saleor (alt Python): <https://saleor.io>
- Vendure (alt Node): <https://www.vendure.io>
- WooCommerce (alt WP): <https://woocommerce.com>
- Magento (alt enterprise): <https://business.adobe.com/products/magento/magento-commerce.html>
- Shopify (commercial alt): <https://www.shopify.com>
