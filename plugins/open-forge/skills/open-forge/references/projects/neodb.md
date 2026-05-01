# NeoDB

**Fediverse-native open-source platform for tracking, rating, and discovering books, movies, TV, music, podcasts, games, and performances — with ActivityPub federation.**
Official site: https://neodb.net
GitHub: https://github.com/neodb-social/neodb
Hosted instance: https://neodb.social

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | See official installation guide |

---

## Inputs to Collect

### All phases
- Domain name — public URL for the instance
- Database credentials — PostgreSQL
- Secret key / application keys
- SMTP config — for user notifications
- Federation settings — instance name, admin contact

---

## Software-Layer Concerns

### Install
Full installation guide: https://neodb.net/install/

### Stack
- Python/Django backend
- PostgreSQL database
- Redis cache
- ActivityPub federation (Fediverse-compatible)

### Features
- Catalog for books, movies, TV shows, music albums, games, podcasts, performances
- One-click item creation from 15+ third-party sites (Goodreads, IMDB, TMDB, Douban, Spotify, Steam, Bandcamp, IGDB, Bangumi, BGG, AO3, WikiData, Open Library, Musicbrainz, any podcast RSS)
- Collection states: wishlist / in-progress / complete / dropped
- Ratings, notes, reviews, tags (private or public)
- User data import/export
- Import from Goodreads, Letterboxd, Douban, StoryGraph, Steam
- Fediverse social features via ActivityPub
- i18n, accessibility, dark mode

---

## Upgrade Procedure

Follow the upgrade notes in the official installation guide: https://neodb.net/install/

---

## Gotchas

- Primarily intended to run as a federated instance — not just a personal single-user app
- The hosted neodb.social instance is free to use if self-hosting isn't needed
- Federation with Mastodon and other ActivityPub services is a core feature — configure your public URL carefully
- More servers and apps listed at https://neodb.net/servers/

---

## References
- Installation guide: https://neodb.net/install/
- GitHub: https://github.com/neodb-social/neodb#readme
- Fediverse: https://mastodon.online/@neodb
