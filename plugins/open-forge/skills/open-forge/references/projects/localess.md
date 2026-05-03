---
name: localess
description: Localess recipe for open-forge. Translation management and content management system built on Angular + Firebase (Firestore, Functions, Storage, Hosting, Auth).
---

# Localess

Powerful translation management tool and content management system built with Angular and Firebase. Upstream: <https://github.com/Lessify/localess>. Docs: <https://github.com/Lessify/localess/wiki>.

Localess uses Firebase (Firestore, Cloud Functions, Storage, Hosting, Authentication) to store and serve translations and content. The CDN-backed API delivers content with ~20ms response times. You pay only for the Firebase/GCP infrastructure you use.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Firebase Hosting + Firestore | [Setup wiki](https://github.com/Lessify/localess/wiki/Setup) | ✅ | Standard deployment — requires a Firebase/GCP project |

> **Note:** Localess is Firebase-native. It does not have a traditional Docker Compose self-hosted path — it deploys to Firebase Hosting and uses managed Firebase services. "Self-hosting" here means running your own Firebase project on GCP.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | Firebase project ID | Free-text | Created in Firebase Console |
| preflight | Firebase region | Free-text | e.g. `us-central1` or `europe-west1` |
| preflight | Firebase service account key | JSON file (sensitive) | For deployment via Firebase CLI |
| optional | Google Translate API key | Free-text (sensitive) | Enables AI-assisted translation |

## Software-layer concerns

Localess is a Firebase-first application. The architecture:

- **Admin UI** (Angular SPA) → deployed to Firebase Hosting
- **API** (Cloud Functions) → serves translations with GCP CDN caching
- **Data** stored in Firestore and Cloud Storage
- **Auth** managed by Firebase Authentication

There is no traditional server or Docker container to run. All backend logic runs in Firebase Cloud Functions.

```
# Conceptual architecture (no docker-compose)
Admin UI  →  Firebase Hosting
           →  Firestore (data)
           →  Cloud Storage (exports/imports)
           →  Cloud Functions (API)
           →  CDN cache (~20ms response)
```

Refer to the [Setup wiki](https://github.com/Lessify/localess/wiki/Setup) for full Firebase deployment steps.

## Upgrade procedure

```bash
git pull
npm install
firebase deploy
```

Upgrades are deployed via Firebase CLI. Firestore schema changes (if any) are handled via migration scripts documented in the wiki.

## Gotchas

- Localess requires a Firebase project — there is no option to run it without GCP/Firebase.
- Costs scale with Firebase usage (Firestore reads/writes, Function invocations, Storage). Free tier may cover small deployments.
- Google Translate AI integration requires enabling the Google Cloud Translation API and associating a billing account.
- Data export/import features help with backup and migration between Firebase projects.
- The GCP CDN caches translation responses — cache invalidation happens on publish; stale content may appear briefly after updates.
