---
name: CoreShop
description: eCommerce plugin for Pimcore CMS. Full-featured online store with product catalog, orders, multi-currency, multi-store, and a rewritten Pimcore Studio React UI. OSL-3.0 licensed.
website: https://www.coreshop.com
source: https://github.com/coreshop/CoreShop
license: OSL-3.0
stars: 290
tags:
  - ecommerce
  - shop
  - pimcore
  - php
platforms:
  - PHP
---

# CoreShop

CoreShop is an open-source eCommerce bundle for the Pimcore platform. It leverages Pimcore's advanced content management and data modeling capabilities to deliver a highly customizable online store. Features include product catalog, orders, multi-store, multi-currency, complex pricing rules, taxation, shipping, and a modern Pimcore Studio UI (React/TypeScript). Designed for developers and agencies building enterprise-grade shops.

Official site: https://www.coreshop.com
Source: https://github.com/coreshop/CoreShop
Docs: https://docs.coreshop.com/latest
Demo: https://docs.coreshop.com/CoreShop/Getting_Started/Demo

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS (4GB+ RAM) | PHP 8.2+ + Pimcore 2026.1+ + MySQL | Required — CoreShop runs inside Pimcore |
| Linux | Docker (Pimcore skeleton) | Via Pimcore's official Docker setup |

## Inputs to Collect

**Phase: Planning**
- Pimcore installation (CoreShop requires Pimcore `^2026.1`)
- MySQL/MariaDB credentials
- Domain/hostname
- PHP 8.2+ with Composer
- Node.js (for building Studio UI assets)

## Software-Layer Concerns

**Note:** CoreShop is a Pimcore plugin, not a standalone application. You must have a working Pimcore installation first.

**Install Pimcore skeleton with CoreShop:**

```bash
# Install Pimcore skeleton (includes Docker option)
# See https://pimcore.com/docs/platform/Pimcore/Getting_Started/Installation/Docker_Based_Install/

# After Pimcore is running, add CoreShop:
composer require coreshop/core-shop

# Install Pimcore bundles
php bin/console pimcore:bundle:install CoreShopOrderBundle
php bin/console pimcore:bundle:install CoreShopCoreBundle
# ... install all required CoreShop bundles per docs
```

**Build Studio UI assets (CoreShop 2026.x):**

```bash
npm ci
npm run build
```

**Database migrations:**

```bash
php bin/console doctrine:migrations:migrate --no-interaction
```

**Key Pimcore + CoreShop stack requirements:**
- Pimcore `^2026.1`
- PHP 8.2+ with extensions: pdo_mysql, gd, zip, xml, mbstring, intl
- MySQL 8.0+ or MariaDB 10.6+
- Redis (for Pimcore cache — recommended)
- Elasticsearch (optional, for catalog search)
- Node.js 20+ (for building Studio UI)

**Configuration** is managed via Pimcore's Symfony-based config system in `config/packages/`.

Full installation guide: https://docs.coreshop.com/CoreShop/Getting_Started/Installation

## Upgrade Procedure

1. `composer update coreshop/core-shop`
2. `php bin/console doctrine:migrations:migrate --no-interaction`
3. `php bin/console pimcore:bundle:install` for any new bundles
4. Rebuild Studio assets: `npm run build`
5. Check upgrade notes: https://github.com/coreshop/CoreShop/releases

## Gotchas

- **Pimcore dependency**: CoreShop cannot run without Pimcore — plan for the full Pimcore stack (significant setup complexity)
- **OSL-3.0 license**: Open Software License 3.0 has strong copyleft requirements for network-deployed software — review the license before commercial use
- **Heavy stack**: Full Pimcore + CoreShop stack needs 4GB+ RAM, preferably 8GB+ for production; add Redis for caching
- **Developer-oriented**: CoreShop is designed for developers and agencies — not a point-and-click shop builder; expect significant configuration and PHP development
- **Studio UI**: CoreShop 2026.x ships with a fully rewritten React/TypeScript admin UI (Pimcore Studio) — building assets requires Node.js
- **Multiple bundles**: CoreShop is split into many Symfony bundles (Order, Core, Product, Index, etc.) — install only what you need

## Links

- Upstream README: https://github.com/coreshop/CoreShop/blob/master/README.md
- Documentation: https://docs.coreshop.com/latest
- Installation guide: https://docs.coreshop.com/CoreShop/Getting_Started/Installation
- Demo: https://docs.coreshop.com/CoreShop/Getting_Started/Demo
- Pimcore: https://github.com/pimcore/pimcore
- Releases: https://github.com/coreshop/CoreShop/releases
