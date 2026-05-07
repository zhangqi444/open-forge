---
name: esmira
description: ESMira recipe for open-forge. Platform for running longitudinal psychological studies (ESM/AA/EMA) with anonymous data collection. PHP server + Android/iOS apps. Source: https://github.com/KL-Psychological-Methodology/ESMira
---

# ESMira

A self-hosted platform for running longitudinal research studies using Experience Sampling Method (ESM), Ambulatory Assessment (AA), and Ecological Momentary Assessment (EMA) designs. Study admins manage studies via a web interface; participants use Android/iOS apps. All data collection is anonymous and decentralized. AGPL-3.0 licensed, PHP server. Upstream: <https://github.com/KL-Psychological-Methodology/ESMira>. Website: <https://esmira.kl.ac.at>. Demo: <https://demo-esmira.kl.ac.at>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any PHP webhost / VPS | PHP + Apache/NGINX | Copy files to webserver — no database required |
| Shared hosting | PHP | Works on basic PHP hosting |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for ESMira?" | FQDN | e.g. esm.research.example.org |
| "Admin username?" | String | Created during first-run setup wizard |
| "Admin password?" | String (sensitive) | Created during first-run setup wizard |
| "Institution name?" | String | Shown to study participants |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "SMTP config for participant communication?" | host:port + credentials | Optional; enables email notifications |
| "Storage path for study data?" | Directory | Where ESMira stores study responses — must be writable by webserver |

## Software-Layer Concerns

- **No database required**: ESMira stores all data as flat files. Simple setup — just copy files to a webserver.
- **Two sub-modules**: ESMira-web (server/admin) and ESMira-apps (Android + iOS participant apps). The web server is where study admins work; participants download the mobile app.
- **Anonymous participation**: Participant data is not linked to identifiable information by design. Suitable for ethically sensitive research.
- **Data dir**: Study responses stored in a configurable directory — must be writable by the webserver user and not publicly accessible.
- **Academic use**: Developed at Karl Landsteiner University. Should be cited in publications — see upstream conditions.
- **Setup wizard**: First run triggers a web-based setup wizard for initial admin account and config.

## Deployment

### PHP webserver (recommended)

```bash
# Download latest release
curl -LO https://github.com/KL-Psychological-Methodology/ESMira-web/releases/latest/download/ESMira-web.zip
unzip ESMira-web.zip -d /var/www/esmira
chown -R www-data:www-data /var/www/esmira

# Configure Apache vhost or NGINX server block to serve /var/www/esmira
# Then visit https://your-domain/ and follow the setup wizard
```

Ensure the data storage directory (configured during setup) is:
- Writable by the webserver user
- NOT accessible via HTTP (outside the web root, or protected by `.htaccess`/NGINX deny rule)

### NGINX config snippet

```nginx
server {
    listen 443 ssl;
    server_name esm.example.com;
    root /var/www/esmira;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Block direct access to data directory
    location /data/ {
        deny all;
    }
}
```

## Upgrade Procedure

1. Download new ESMira-web release zip from https://github.com/KL-Psychological-Methodology/ESMira-web/releases
2. Backup the data directory before upgrading.
3. Extract new files over the existing installation (config and data directory are preserved).
4. Check the wiki for any migration steps: https://github.com/KL-Psychological-Methodology/ESMira/wiki

## Gotchas

- **Data directory security**: The data directory must NOT be web-accessible — participant response data could be exposed. Place it outside the web root or add deny rules.
- **No Docker image**: ESMira uses flat files — Docker adds complexity without benefit. Native PHP hosting is simpler and fully supported.
- **Mobile apps required for participants**: Participants must install the ESMira Android or iOS app to participate in studies. There is no web-based participant interface.
- **Academic citation required**: Per upstream conditions, ESMira must be cited in publications if used for research.
- **PHP version**: Check upstream wiki for current PHP version requirements before deploying on a new server.
- **Translation**: UI available in many languages via Lokalise — see https://translate.jodli.dev/projects/esmira/ to contribute.

## Links

- Source: https://github.com/KL-Psychological-Methodology/ESMira
- Web server sub-module: https://github.com/KL-Psychological-Methodology/ESMira-web
- Apps sub-module: https://github.com/KL-Psychological-Methodology/ESMira-apps
- Website: https://esmira.kl.ac.at
- Wiki / setup guide: https://github.com/KL-Psychological-Methodology/ESMira/wiki
- Demo: https://demo-esmira.kl.ac.at
- Discussion forum: https://github.com/KL-Psychological-Methodology/ESMira/discussions
