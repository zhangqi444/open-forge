---
name: sabredav
description: SabreDAV recipe for open-forge. The most popular WebDAV framework for PHP. Use it to create WebDAV, CalDAV, and CardDAV servers. Source: https://github.com/sabre-io/dav
---

# SabreDAV

The most popular WebDAV framework for PHP. Use it to create WebDAV, CalDAV, and CardDAV servers. Upstream: <https://github.com/sabre-io/dav>. Full documentation: <https://sabre.io/dav/>.

SabreDAV is a PHP library / server, not a standalone application. You embed it in a PHP project or use it as a standalone server. It powers several CalDAV/CardDAV products including Baikal (which has its own recipe).

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Composer (library) | PHP 7.4+ / 8.x | Install as a dependency in your PHP project. |
| Standalone server | PHP + web server (Apache/Nginx) | Use the bundled server examples as a starting point. |
| Via Baikal | Docker or bare metal | Baikal is a batteries-included CalDAV/CardDAV server built on SabreDAV. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "PHP version?" | PHP 7.4 minimum; PHP 8.x recommended |
| setup | "Which DAV protocols?" | CalDAV, CardDAV, WebDAV, or combination |
| storage | "Backend storage type?" | PDO/MySQL, PDO/SQLite, or filesystem |
| auth | "Authentication method?" | HTTP Basic (default), Digest, or custom |
| network | "Domain / virtual host for DAV endpoint?" | e.g. `dav.example.com` |

## Software-layer concerns

- **Requires:** PHP 7.4+, Composer, a web server (Apache/Nginx), and a database (MySQL or SQLite for CalDAV/CardDAV)
- **Install via Composer:**
  ```bash
  composer require sabre/dav
  ```
- **Config:** PHP code — implement `Sabre\DAV\Server` with your chosen backends. See examples at https://sabre.io/dav/gettingstarted/
- **Data dir:** Depends on backend. SQLite file or MySQL database.
- **Apache config:** Enable `mod_rewrite` and `mod_headers`; set `AllowOverride All`
- **Nginx config:** Use `try_files` and pass all requests to the PHP entry point

### Minimal CalDAV/CardDAV server skeleton

```php
<?php
// server.php
$pdo = new PDO('sqlite:data/db.sqlite');

$authBackend    = new Sabre\DAV\Auth\Backend\PDO($pdo);
$calBackend     = new Sabre\CalDAV\Backend\PDO($pdo);
$cardBackend    = new Sabre\CardDAV\Backend\PDO($pdo);
$principalBackend = new Sabre\DAVACL\PrincipalBackend\PDO($pdo);

$tree = [
    new Sabre\CalDAV\Principal\Collection($principalBackend),
    new Sabre\CalDAV\CalendarRoot($principalBackend, $calBackend),
    new Sabre\CardDAV\AddressBookRoot($principalBackend, $cardBackend),
];

$server = new Sabre\DAV\Server($tree);
$server->setBaseUri('/');
$server->addPlugin(new Sabre\DAV\Auth\Plugin($authBackend));
$server->addPlugin(new Sabre\CalDAV\Plugin());
$server->addPlugin(new Sabre\CardDAV\Plugin());
$server->addPlugin(new Sabre\DAVACL\Plugin());
$server->exec();
```

## Upgrade procedure

1. Update via Composer: `composer update sabre/dav`
2. Review the [changelog](https://github.com/sabre-io/dav/blob/master/CHANGELOG.md) for breaking changes
3. Run database migrations if any schema changes are documented
4. Test CalDAV/CardDAV sync with a client (e.g. Thunderbird, Apple Calendar)

## Gotchas

- **SabreDAV is a framework, not an app**: you must write PHP glue code. If you want a ready-to-run server, use **Baikal** instead.
- **HTTP PROPFIND/REPORT methods** must not be blocked by your web server or security rules.
- **Apache `mod_rewrite`** must be enabled; missing it causes 404s on all DAV requests.
- **`BASE_URI` mismatch**: if the server is not at `/`, set `setBaseUri()` correctly or sync will silently fail.
- **PHP memory limit**: CalDAV sync of large calendars may require increasing `memory_limit`.
- **Baikal is the easier path**: for most self-hosters, Baikal (which wraps SabreDAV) is simpler to set up.

## References

- [Upstream README](https://github.com/sabre-io/dav#readme)
- [Official docs](https://sabre.io/dav/)
- [Getting started](https://sabre.io/dav/gettingstarted/)
- [Installation guide](https://sabre.io/dav/install/)
