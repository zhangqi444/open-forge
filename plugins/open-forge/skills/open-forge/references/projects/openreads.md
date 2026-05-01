---
name: Openreads
description: "Privacy-oriented open-source book tracker app for Android and iOS. Flutter. mateusz-bak/openreads. Reading lists, statistics, Open Library lookup, barcode scan, import/export."
---

# Openreads

**Privacy-oriented, open-source book tracker for Android and iOS.** Built in Flutter. Four reading lists (finished, reading, want to read, did not finish), custom tags, reading statistics, Open Library database lookup, barcode scanning, manual entry, and import/export. No accounts, no cloud sync, no analytics — all data stays on your device.

Built + maintained by **Mateusz Bak**. Available on F-Droid, Google Play, and App Store.

- Upstream repo: <https://github.com/mateusz-bak/openreads>
- F-Droid: <https://f-droid.org/en/packages/software.mdev.bookstracker>
- Google Play: <https://play.google.com/store/apps/details?id=software.mdev.bookstracker>
- App Store: <https://apps.apple.com/app/id6476542305>
- Matrix community: <https://matrix.to/#/#openreads:matrix.org>
- Mastodon: `@openreads@fosstodon.org`

## Architecture in one minute

- **Flutter** cross-platform app (Dart)
- **Local-first** — all data in the app's local SQLite DB on your device
- No server, no Docker, no self-hosting required
- Android + iOS (and via sideload on desktop, though not the primary target)
- Resource: **minimal** — standard mobile app

## "Install" / self-hosting note

Openreads is a **mobile app** — not a web server or Docker container. There is nothing to self-host or deploy server-side. "Self-hosting" here means:

1. Install from F-Droid (privacy-preserving, no Google) or Google Play / App Store.
2. All data lives on your device.
3. Backup = export feature within the app.

For users who want to build from source (e.g., sideload a custom variant):

```bash
git clone https://github.com/mateusz-bak/openreads.git
cd openreads
flutter pub get
flutter build apk          # Android
flutter build ios          # iOS (requires macOS + Xcode)
```

## Features

| Feature | Details |
|---------|---------|
| **Four reading lists** | Finished / Reading / Want to read / Did not finish |
| **Book lookup** | Open Library database search by title/author/ISBN |
| **Barcode scan** | Camera scan → auto-fill from Open Library |
| **Manual entry** | Full manual book details form |
| **Custom tags** | Add any tags; filter lists by tag |
| **Statistics** | Charts + counts — books per year/month, pages read, genre breakdown |
| **Import/Export** | Backup + restore your library (CSV/JSON — check in-app options) |
| **No account required** | Fully offline-capable; no registration |
| **Privacy** | No analytics, no tracking, no cloud sync |

## First use

1. Install from F-Droid (recommended for privacy) or Play Store / App Store.
2. Open app → start adding books (search, scan, or manual).
3. Move books between lists as you read them.
4. Use tags to categorize (e.g. `sci-fi`, `work`, `non-fiction`).
5. Export your library periodically via Settings → Backup.

## Backup & data portability

All data is local. Back up via:
- **In-app export** — generates a backup file you can store anywhere (Google Drive, Nextcloud, local folder).
- **Android adb backup** or standard device backup methods.

On uninstall, local data is deleted. Export first.

## Gotchas

- **No cloud sync.** Data does not sync between devices. If you want sync, export on one device, import on another. A native sync feature may be on the roadmap — check Issues/Discussions.
- **F-Droid package ID is `software.mdev.bookstracker`** — a legacy ID from when the app was called "Books Tracker." Same app, different name.
- **Open Library lookup requires internet.** Barcode scan + search both call the Open Library API. Manual entry works fully offline.
- **No web UI.** Openreads is mobile-only. There is no browser dashboard or API.
- **iOS build requires macOS + Xcode.** If you want to build from source for iOS, you need an Apple developer account + Mac. Most iOS users will use the App Store version.
- **Statistics are device-local.** Great for personal tracking; no way to share a "year in review" publicly (unlike Goodreads).
- **Not a Goodreads replacement for social features.** Openreads has no friends, no book reviews, no social feed. It's a personal tracker only. If you want social book discussion, combine with a Bookwyrm instance.

## Project health

Active Flutter development, F-Droid + Play Store + App Store, Weblate translations (community-driven i18n), Matrix community, GitHub Sponsors + Buy Me A Coffee. Solo-maintained by Mateusz Bak.

## Book-tracker-family comparison

- **Openreads** — Flutter, local-first, privacy-first, F-Droid, no account required
- **Bookwyrm** — ActivityPub federated book social network, web app + self-hosted
- **Kavita** — self-hosted reading server (ebooks + comics), not a "want to read" tracker
- **Calibre-Web** — ebook library manager/server
- **Goodreads** — SaaS, social, owned by Amazon; the incumbent

**Choose Openreads if:** you want a clean, offline-first mobile book tracker with no accounts or telemetry, available on F-Droid.

## Links

- Repo: <https://github.com/mateusz-bak/openreads>
- F-Droid: <https://f-droid.org/en/packages/software.mdev.bookstracker>
- Google Play: <https://play.google.com/store/apps/details?id=software.mdev.bookstracker>
- App Store: <https://apps.apple.com/app/id6476542305>
- Bookwyrm (social alt): <https://bookwyrm.social>
