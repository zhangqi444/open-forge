---
name: oxid-eshop
description: OXID eShop recipe for open-forge. Flexible open source e-commerce platform popular in German-speaking markets. PHP + MySQL. Docker SDK for development. Proprietary (Community Edition open source). Source: https://github.com/OXID-eSales/oxideshop_ce
---

# OXID eShop

Flexible, modular e-commerce platform. Popular in German-speaking European markets. Supports custom themes (APEX theme), extensive module system, B2B/B2C features, and multi-shop configurations. REST API included. PHP + MySQL. Official Docker-based SDK for development. Community Edition is open source (OXID Community License); Professional and Enterprise editions are proprietary/commercial. Note: listed as Proprietary in awesome-selfhosted due to the commercial editions.

Upstream: https://github.com/OXID-eSales/oxideshop_ce | Docs: https://docs.oxid-esales.com | Docker SDK: https://github.com/OXID-eSales/docker-eshop-sdk

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | Docker SDK (dev) | Official development environment |
| Any | Composer install (prod) | See installation manual |
| Linux (Debian/Ubuntu) | LAMP stack | Traditional PHP + Apache/Nginx + MySQL |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Domain / URL | Public URL for the shop |
| config | Database credentials | MySQL user, password, database name |
| config | Admin credentials | Set during installation wizard |
| config | Edition | Community (free), Professional, or Enterprise |
| config (optional) | License key | Required for Professional/Enterprise editions |
| config (optional) | SMTP settings | For order confirmation and transactional emails |

## Software-layer concerns

- PHP requirements: PHP 8.1+ with extensions: curl, gd, mbstring, openssl, PDO, pdo_mysql, soap, xml, zip
- Composer-based: OXID is installed and managed via Composer; do not copy files manually
- Module system: extend functionality via modules (packages); install via composer require
- Sessions and cache: supports Redis and Memcached for session storage and caching (recommended for production)
- File storage: product images and media stored under out/pictures/ -- persist this directory

## Install -- Development (Docker SDK)

```bash
git clone https://github.com/OXID-eSales/docker-eshop-sdk.git myshop
cd myshop

# Review available make targets
make help

# Setup permissions and config files
make setup

# Run example setup script (demonstrates environment)
make example

# Start the environment
docker compose up -d
```

Access at http://localhost.local (add to /etc/hosts: 127.0.0.1 localhost.local)

## Install -- Production (Composer)

Full instructions: https://docs.oxid-esales.com/developer/en/latest/getting_started/installation/eshop_installation.html

```bash
composer create-project oxid-esales/oxideshop-project myshop --no-dev
cd myshop
# Configure config/configincpath.php with DB credentials
# Run web installer at https://yourshop.example.com/Setup/
```

## Upgrade procedure

```bash
# Back up database and files first
composer update oxid-esales/oxideshop-ce
# Run migrations via admin panel or CLI:
vendor/bin/oe-console oe:migration:apply-all
```

## Gotchas

- Community Edition is open source (OXID Community License / GPL-3.0 depending on version), but Professional and Enterprise editions are commercial. Verify the license for the specific version you install.
- Docker SDK is for development only: the SDK uses MySQL 5.7 (older), Xdebug, and mail catchers -- not suitable for production as-is.
- Composer required: OXID must be managed with Composer. Manual file copies will break the autoloader and module system.
- /etc/hosts entry required for Docker SDK: 127.0.0.1 localhost.local must be added to your hosts file.
- Module compatibility: third-party modules specify compatible OXID versions. Always check module compatibility before upgrading the shop.

## Links

- Source (Community Edition): https://github.com/OXID-eSales/oxideshop_ce
- Docker SDK: https://github.com/OXID-eSales/docker-eshop-sdk
- Documentation: https://docs.oxid-esales.com
- Website: https://www.oxid-esales.com
- Module marketplace: https://exchange.oxid-esales.com
