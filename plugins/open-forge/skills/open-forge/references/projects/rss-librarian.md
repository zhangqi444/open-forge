---
name: rss-librarian-project
description: Read-it-later service that stores articles into a personal RSS/Atom feed. No database, no accounts. Single PHP file. Upstream: https://github.com/thefranke/rss-librarian
---

# RSS-Librarian

Read-it-later service for RSS purists. Saves articles from the web as entries in your own personal RSS/Atom feed — read them in any feed reader. No database, no accounts, no third-party dependencies. A single self-hostable PHP file. Upstream: <https://github.com/thefranke/rss-librarian>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| PHP web server | [GitHub README](https://github.com/thefranke/rss-librarian) | ✅ | Any PHP-capable web host |
| Hosted instance | <https://www.rsslibrarian.ch/> | Public | No self-hosting needed |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Self-host or use the public instance?" | options | All |
| config | PHP-capable web server path | path | Self-hosted |

## Install

Source: <https://github.com/thefranke/rss-librarian>

Copy `librarian.php` to any PHP-capable web server. No database, no composer dependencies, no configuration file required.

A public hosted instance is available at <https://www.rsslibrarian.ch/librarian.php> if you prefer not to self-host.

## How it works

1. Submit a URL to the librarian (via web form or bookmarklet).
2. RSS-Librarian extracts the article content using [fivefilters.org](https://www.fivefilters.org/) readability service.
3. The article is written as a new entry into your personal RSS/Atom feed file.
4. Subscribe to your personal feed URL in any feed reader app.

## Use cases

- Store arbitrary web articles in a feed-reader app (NetNewsWire, Feedly, etc.)
- Avoid third-party services like Wallabag, Pocket, or Instapaper
- Read articles offline in a readable format
- Sync stored articles to multiple devices via feed reader sync

## Upgrade procedure

Replace `librarian.php` with the latest version from GitHub.

## Gotchas

- Content extraction depends on an external [fivefilters.org](https://www.fivefilters.org/) service — not fully self-contained.
- No user accounts — single-user by design.
- No permanent article archive — articles are stored as feed entries; old entries may fall off depending on your feed reader's retention.
- No Docker image documented in upstream README.

## References

- GitHub: <https://github.com/thefranke/rss-librarian>
- Public instance: <https://www.rsslibrarian.ch/librarian.php>
