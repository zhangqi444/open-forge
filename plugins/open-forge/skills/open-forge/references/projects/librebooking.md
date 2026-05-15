---
name: librebooking
description: Recipe for LibreBooking — an open-source resource scheduling and reservation platform. Fork of Booked Scheduler. Supports multi-resource booking, waitlists, RBAC, quotas, and reporting. PHP + MariaDB + Docker.
---

# LibreBooking

Open-source resource scheduling and reservation platform. Manage room bookings, equipment reservations, and any other shared resources. Supports multi-resource scheduling, waitlists, role-based access control, usage quotas, reporting, and calendar integration (iCal/Outlook). Fork of Booked Scheduler. Upstream: <https://github.com/LibreBooking/librebooking>. Docs: <https://librebooking.readthedocs.io/>.

License: GPL-3.0. Platform: PHP 8.2+, MariaDB 10.6+, Docker. Latest stable: v5.0.2. Actively maintained.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended — official Docker image from LibreBooking |
| PHP/Apache native | For existing LAMP stacks |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "MariaDB root password, database name, user, password?" | MariaDB 10.6+ required (MySQL 8.0+ also supported) |
| install | "LibreBooking install password?" | Used to access the `/install` setup page — change after first run |
| timezone | "Server timezone (e.g. `America/New_York`)?" | Set via `LB_DEFAULT_TIMEZONE` |
| mail | "SMTP host, port, user, password, from address?" | Required for reservation confirmations and reminders |
| network | "Public URL for LibreBooking?" | Used in outgoing emails and iCal links |

## Docker Compose (recommended)

Based on the official example at <https://github.com/LibreBooking/docker>.

```bash
mkdir librebooking && cd librebooking
mkdir -p uploads/images uploads/reservation logs
```

`docker-compose.yml`:
```yaml
services:
  db:
    image: linuxserver/mariadb:10.6.13
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: librebooking
      MYSQL_USER: lb_user
      MYSQL_PASSWORD: strongpassword
    volumes:
      - db_data:/config

  app:
    image: librebooking/librebooking:latest
    restart: always
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      LB_DATABASE_NAME: librebooking
      LB_DATABASE_USER: lb_user
      LB_DATABASE_PASSWORD: strongpassword
      LB_DATABASE_HOSTSPEC: db
      LB_INSTALL_PASSWORD: install_password_change_me
      LB_DEFAULT_TIMEZONE: America/New_York
      LB_LOGGING_FOLDER: /var/log/librebooking
      LB_LOGGING_LEVEL: none
      LB_LOGGING_SQL: "false"
    volumes:
      - app_conf:/config
      - ./uploads/images:/var/www/html/Web/uploads/images
      - ./uploads/reservation:/var/www/html/Web/uploads/reservation
      - ./logs:/var/log/librebooking

  cron:
    image: librebooking/librebooking:latest
    restart: always
    command: supercronic /config/lb-jobs-cron
    depends_on:
      - app
    volumes_from:
      - app
    environment:
      LB_DATABASE_NAME: librebooking
      LB_DATABASE_USER: lb_user
      LB_DATABASE_PASSWORD: strongpassword
      LB_DATABASE_HOSTSPEC: db
      LB_DEFAULT_TIMEZONE: America/New_York
      LB_LOGGING_FOLDER: /var/log/librebooking

volumes:
  db_data:
  app_conf:
```

```bash
docker compose up -d
```

Then visit `http://your-host:8080/Web/install/` and complete the installation wizard using the `LB_INSTALL_PASSWORD` you set. **Delete or restrict `/Web/install/` after setup.**

## First-run setup

1. Visit `http://your-host:8080/Web/install/`
2. Enter the install password
3. Run database installation/upgrade
4. Log in at `http://your-host:8080/Web/` with admin credentials created during install

## Background jobs (cron container)

The `cron` service handles:
- Reminder emails (`sendreminders.php`)
- Reservation notifications
- Waitlist processing

Without the cron container, reminders and automated notifications will not send. The `lb-jobs-cron` file is auto-generated on first run in the `app_conf` volume.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | Environment variables via `lb.env` or inline in compose |
| Uploads | `Web/uploads/images/` and `Web/uploads/reservation/` — persist these |
| Logs | `/var/log/librebooking/` — mount for host access |
| Default port | `8080` |
| Database | MariaDB 10.6+ or MySQL 8.0+ |
| Install page | `/Web/install/` — **must be restricted or removed after setup** |
| Admin URL | `/Web/` |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# Visit /Web/install/ to run any pending DB migrations
```

## Gotchas

- **Install page must be secured post-setup**: The `/Web/install/` page is accessible to anyone who knows the install password. After initial setup, restrict it via nginx or remove it. Change `LB_INSTALL_PASSWORD` to something random.
- **Cron container is required for reminders**: The `cron` service is a separate container that must run alongside the app for email reminders and background jobs. Without it, these features are silent.
- **Volume permissions**: If using bind mounts for uploads, set `chmod go+rwx` on those directories before starting the containers (the app runs as the web user, not root).
- **MariaDB 10.6+ required**: The Docker example uses `linuxserver/mariadb:10.6.13`. Newer MariaDB versions may work; older ones (< 10.6) may not support required features.
- **Fork of Booked Scheduler**: LibreBooking diverged significantly from Booked Scheduler. Do not mix documentation between the two projects.

## Upstream links

- Source: <https://github.com/LibreBooking/librebooking>
- Docker repo: <https://github.com/LibreBooking/docker>
- Docs: <https://librebooking.readthedocs.io/>
- Demo: <https://librebooking-demo.fly.dev/>
