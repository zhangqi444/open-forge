---
name: farmos
description: farmOS recipe for open-forge. Web-based farm management, planning, and record keeping application built on Drupal, supporting livestock, crops, equipment, and sensor data. Source: https://github.com/farmOS/farmOS
---

# farmOS

Web-based farm management, planning, and record-keeping application. Tracks livestock, crops, equipment, inputs, activities, observations, and sensor data. Built on Drupal with a REST/JSON API for integrations. Used by farms, researchers, and agricultural organizations worldwide. Upstream: https://github.com/farmOS/farmOS. Docs: https://farmOS.org/hosting.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (production) | Docker | Recommended. Official image farmos/farmos. |
| Docker (development) | Docker | Uses docker-compose.development.yml with local volume mount. |
| Manual (Drupal install) | PHP + MySQL/PostgreSQL | Traditional Drupal deployment on LAMP/LEMP stack. |
| Managed hosting | Farmier.com | Paid hosted option if self-hosting is not desired. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Database type and credentials?" | PostgreSQL (recommended) or MySQL/MariaDB |
| setup | "Site hostname/URL?" | e.g. https://farm.example.com |
| setup | "Admin account email and password?" | Created during Drupal install wizard |
| storage | "Sites volume path?" | Maps to /opt/drupal/web/sites in container — contains uploaded files and settings |

## Software-layer concerns

### Docker production deployment

  # Create a directory for persistent data
  mkdir -p farmos/sites

  # Create docker-compose.yml:
  # (based on upstream docker/docker-compose.production.yml)
  cat > farmos/docker-compose.yml << 'COMPOSE'
  services:
    www:
      image: farmos/farmos:4.0.1   # Replace with latest stable release
      volumes:
        - ./sites:/opt/drupal/web/sites
      ports:
        - "80:80"
      restart: always
      environment:
        - POSTGRES_HOST=db
        - POSTGRES_USER=farmos
        - POSTGRES_PASSWORD=changeme
        - POSTGRES_DB=farmos
    db:
      image: postgres:14
      environment:
        - POSTGRES_USER=farmos
        - POSTGRES_PASSWORD=changeme
        - POSTGRES_DB=farmos
      volumes:
        - db-data:/var/lib/postgresql/data
      restart: always
  volumes:
    db-data:
  COMPOSE

  docker compose up -d

Note: The production compose file in the upstream repo does NOT include a database container — it assumes an external managed database. The example above adds one for convenience.

### Post-install wizard

After starting, visit http://<host>/ to complete the Drupal install wizard:
1. Choose language
2. Select "farmOS" installation profile
3. Configure database connection
4. Set site name, admin email/password
5. Configure timezone and country

### Sites volume

The ./sites volume contains:
  sites/default/settings.php    - DB credentials and Drupal config
  sites/default/files/          - uploaded files, images, map tiles
  sites/default/private/        - private files

Back up this directory regularly.

### Upgrade procedure

  # Update image tag in docker-compose.yml to new version, then:
  docker compose pull
  docker compose up -d

  # Run database updates:
  docker compose exec www drush updatedb -y
  docker compose exec www drush cr

## Gotchas

- **Drupal-based**: farmOS is a Drupal distribution. Understanding Drupal's update process (drush updatedb, cache rebuild) is important.
- **Image version pinning**: the production docker-compose uses farmos/farmos:x.y.z — always pin to a specific release, not :latest, to control upgrade timing.
- **Sites volume is critical**: everything outside sites/ is ephemeral in the container. Never store custom data outside this volume.
- **PostgreSQL recommended**: farmOS docs and upstream preference is PostgreSQL over MySQL for production.
- **Memory**: Drupal + farmOS is PHP-heavy. Minimum 512MB RAM; 1GB+ recommended with file imports and large datasets.
- **REST API**: farmOS provides a JSON:API for integrations with sensors, mobile apps, and other tools. See farmOS.org/development/api.
- **Modules/extensions**: additional farmOS modules can be installed like Drupal modules. Use Composer to manage them.

## References

- Upstream GitHub: https://github.com/farmOS/farmOS
- Hosting & install docs: https://farmOS.org/hosting/install
- Docker README: https://github.com/farmOS/farmOS/tree/3.x/docker
- REST API docs: https://farmOS.org/development/api/
- Docker Hub: https://hub.docker.com/r/farmos/farmos
- Demo: https://farmos-demo.rootedsolutions.io/
