---
name: buddypress
description: BuddyPress recipe for open-forge. WordPress plugin that transforms a WordPress site into a social network with user profiles, activity streams, groups, messaging, and friend connections. PHP + MySQL. GPL-2.0. Source: https://github.com/buddypress/BuddyPress
---

# BuddyPress

WordPress plugin that turns a standard WordPress site into a full social network. Adds user profiles, activity streams, user groups, private messaging, friend connections, and notifications on top of WordPress. Ships with optional components that can be enabled individually. Actively maintained since 2008. PHP + MySQL. GPL-2.0 licensed.

Upstream: https://github.com/buddypress/BuddyPress | Plugin page: https://wordpress.org/plugins/buddypress/ | Docs: https://codex.buddypress.org

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | WordPress (self-hosted) | Requires WordPress 5.0+, PHP 7.4+ |
| Any | Docker (WordPress) | Standard WordPress Docker setup |
| Any | Managed WordPress hosting | Works on any cPanel/DirectAdmin host |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| pre-install | WordPress instance | BuddyPress is a plugin -- WordPress must already be installed and running |
| config | WordPress admin URL | e.g. https://example.com/wp-admin |
| config | BuddyPress components | Choose which components to enable: Profiles, Activity, Groups, Messages, Friends, Notifications, etc. |
| config (optional) | bbPress | Install bbPress plugin for forum integration with BuddyPress |
| config (optional) | Registration | Enable WordPress user registration (Settings > General > Membership) to allow new signups |

## Software-layer concerns

- Requires WordPress: BuddyPress is not a standalone app; it must be installed on a running WordPress site
- Component-based: BuddyPress ships with optional components (User Profiles, Activity Streams, Extended Profiles, Friend Connections, Private Messaging, Notifications, Groups). Enable only what you need.
- Theme compatibility: not all WordPress themes support BuddyPress templates. The bundled BuddyX theme or BuddyPress-compatible themes are recommended.
- Performance: activity streams and group feeds can generate significant DB queries on large communities. Use a caching plugin (Redis Object Cache, WP Super Cache) in production.
- WP multisite: BuddyPress has special handling for WordPress Multisite networks.

## Install -- Via WordPress Admin (recommended)

1. Log in to WordPress admin (wp-admin)
2. Plugins > Add New > Search for "BuddyPress"
3. Install and Activate
4. BuddyPress > Components -- enable the features you want
5. BuddyPress > Pages -- configure which WordPress pages map to BuddyPress features
6. Enable registration: Settings > General > check "Anyone can register"

## Install -- Via WP-CLI

```bash
wp plugin install buddypress --activate
wp bp component activate all   # or list specific components
```

## Install -- Docker (WordPress + BuddyPress)

```yaml
services:
  wordpress:
    image: wordpress:latest
    restart: unless-stopped
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: yourpassword
    volumes:
      - wp_data:/var/www/html

  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: yourpassword
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - db_data:/var/lib/mysql

volumes:
  wp_data:
  db_data:
```

After WordPress is running, install BuddyPress via the admin UI or WP-CLI.

## Upgrade procedure

Via WordPress admin: Plugins > check for updates > update BuddyPress. Or via WP-CLI:

```bash
wp plugin update buddypress
```

## Gotchas

- BuddyPress is a plugin, not a standalone app: you need WordPress first. If you don't already run WordPress, consider whether you want the full WordPress overhead for a social network.
- Theme compatibility matters: the default WordPress themes (Twenty Twenty, etc.) do not style BuddyPress pages well. Use a BuddyPress-aware theme or the free BuddyX theme.
- User registration must be explicitly enabled: WordPress disables registration by default. Go to Settings > General and check "Anyone can register."
- Development repo is a mirror: the GitHub repo is a mirror of the SVN repo at buddypress.svn.wordpress.org. Do not submit pull requests on GitHub -- submit patches to Trac instead.

## Links

- Source: https://github.com/buddypress/BuddyPress
- WordPress plugin page: https://wordpress.org/plugins/buddypress/
- Documentation (Codex): https://codex.buddypress.org
- Support forums: https://wordpress.org/support/plugin/buddypress/
