---
name: ente-auth-project
description: Ente Auth recipe for open-forge. AGPL-3.0 end-to-end encrypted 2FA/TOTP authenticator app — part of the Ente monorepo (`github.com/ente-io/ente`), shares the same Museum backend as Ente Photos. Alternative to Google Authenticator / Authy / Microsoft Authenticator, but with encrypted cloud sync: codes are encrypted on-device (libsodium), synced via Museum, decrypted on your other devices. Ente's hosted auth service is FREE (even when Photos is paid). Self-hosting runs the same Museum server + a dedicated web UI (`ente-auth` on :3003). Features: TOTP, HOTP, Steam Guard, backup codes, imports from Aegis/andOTP/2FAS/Bitwarden/Google Authenticator QR. Desktop apps for macOS/Windows/Linux + mobile iOS/Android. Shares all self-hosting steps with ente-photos; minimum setup = Museum + web auth UI.
---

# Ente Auth

AGPL-3.0 end-to-end encrypted 2FA/TOTP authenticator. Upstream: <https://github.com/ente-io/ente> (monorepo, `auth/` subtree). Docs: <https://help.ente.io/auth>. Website: <https://ente.io/auth>.

**Positioning:** open-source alternative to Authy / Google Authenticator / Microsoft Authenticator / 1Password 2FA — but with END-TO-END encrypted cloud sync. Your TOTP secrets are encrypted on-device before upload; even Ente the company can't see them. Ente's hosted auth service is **free**, even though Ente Photos is paid — they subsidize it because "2FA should be free."

If you're self-hosting Ente Photos already, Auth comes for free (same backend). If you ONLY want Auth, you still need to deploy the Museum backend — there's no "Auth-only server" today.

## What it does

- **TOTP (RFC 6238)** — time-based one-time passwords. The standard Google Authenticator / Authy format.
- **HOTP (RFC 4226)** — counter-based (less common; some legacy systems).
- **Steam Guard** — Steam's custom TOTP variant.
- **Backup codes** — store static fallback codes alongside TOTP entries.
- **Import from**: Aegis (JSON), andOTP, 2FAS, Bitwarden, Google Authenticator (QR batch export), plain `otpauth://` URIs.
- **Export**: encrypted JSON backup (portable to any Ente instance).
- **Encrypted cloud sync** via Museum — your codes auto-sync across devices.
- **Desktop apps**: macOS, Windows, Linux (Electron).
- **Mobile apps**: iOS, Android.
- **Web app**: <https://auth.ente.io> (or your self-hosted instance).
- **No tracking, no ads, no upsell.**

## Architecture

Same as Ente Photos — because it's the **same repo + same Museum backend**:

| Service | Purpose |
|---|---|
| `museum` | Backend API on `:8080` — handles user auth, encrypted blob storage |
| `postgres` | User metadata + encrypted key material |
| `minio` | Object storage — encrypted auth secret blobs |
| `ente-auth` web app | Web UI on `:3003` (if self-hosting the web frontend) |

Key distinction from Photos: Auth's encrypted blobs are TINY (just TOTP secrets + issuer names + notes). Don't need much storage — a user with 100 2FA entries might use ~50 KB.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Use Ente's FREE hosted service | <https://auth.ente.io> | ✅ | Easiest. Genuinely free. |
| Self-host with Ente Photos stack | Same as Photos (see `ente-photos.md`) | ✅ | If you're already self-hosting Photos. |
| Self-host Auth-only (minimal Museum) | Same compose, just don't deploy the photos-app container | ✅ | If you ONLY want Auth. Still needs Museum + Postgres + MinIO. |
| Mobile apps directly — NO backend | Mobile apps work offline with local-only vault | ✅ | If you don't want cloud sync at all. |

The mobile/desktop apps support **offline-only mode** (no sync, no account) — you can use Ente Auth as a pure local-only authenticator like Aegis, without deploying any backend. Backups then happen via manual export.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Why self-host?" | `AskUserQuestion`: `also-hosting-photos` / `auth-only` / `offline-no-backend-needed` | Answers drive path. |
| preflight | "Platforms?" | `AskUserQuestion`: `ios` / `android` / `macos-desktop` / `windows-desktop` / `linux-desktop` / `web` / `all` | Clients to install. |
| (if self-hosting backend) | — | Same inputs as `ente-photos.md` — Museum + Postgres + MinIO + SMTP + reverse proxy | See ente-photos.md. |
| (web UI only) | "Auth web URL?" | e.g. `https://auth.example.com` | Points at `ente-auth` web container on :3003. |

## Install path 1 — Use Ente's free hosted service

```
1. Download the app:
   - iOS: App Store → "Ente Auth"
   - Android: Play Store / F-Droid / Obtainium → "Ente Auth"
   - Desktop: https://ente.io/download
   - Web: https://auth.ente.io
2. Sign up (free) with email.
3. Start adding 2FA codes.
4. (Optional) Set up additional devices — they auto-sync.
```

No self-hosting. Ente's hosted Auth is genuinely free, forever, per upstream.

## Install path 2 — Self-host (same as Ente Photos)

Follow the Ente Photos recipe (`ente-photos.md`). Auth shares the Museum backend + Postgres + MinIO — it's the SAME stack, SAME quickstart, SAME configuration. The web UI for Auth runs as a separate container (`ente-auth` on port :3003) if you want a self-hosted web UI too.

**If using the `quickstart.sh` script**, Auth web UI is not deployed by default (only Photos + Albums). To deploy the auth web UI yourself:

```yaml
# Add to the quickstart-generated compose.yaml:
ente-auth-web:
  build:
    context: .
    dockerfile: web/apps/auth/Dockerfile
  ports:
    - "3003:3003"
  environment:
    ENTE_API_ORIGIN: "https://ente-api.example.com"
```

Or just use the mobile/desktop apps — they work fine against any Museum instance without needing a web UI.

## Connecting the app to your self-hosted instance

- **Mobile (Auth app)**: on the welcome screen, long-press "Sign in" → enter custom server URL (`https://ente-api.example.com`).
- **Desktop Auth (Electron)**: same — Settings → Advanced → Custom server URL.
- **Web Auth**: if you deployed `ente-auth` web app, open `https://auth.example.com/`.

## Install path 3 — Offline-only (no backend)

If you don't want cloud sync at all, the mobile/desktop apps support offline mode:

1. Install app.
2. Skip sign-in (there's a "Skip" or "Use locally" option on first launch).
3. Your vault is stored locally, encrypted with your device PIN / biometrics.
4. Export backups manually via Settings → Export → encrypted JSON.
5. Import the backup on another device to restore.

This is like using Aegis (Android) or Raivo OTP (iOS) but with Ente's UI.

## Import from other authenticators

Settings → Data → Import:

| Source | Format | Notes |
|---|---|---|
| Aegis | JSON (encrypted or plain) | Most reliable path. |
| andOTP | JSON (encrypted or plain) | |
| 2FAS | JSON | |
| Bitwarden | JSON export | Only TOTP entries. |
| Google Authenticator | QR code batch export | Scan the QR(s) from Google's "Transfer accounts" flow. |
| Plain `otpauth://` URIs | Text/QR | Per-entry. |

Export your own: Settings → Data → Export → encrypted JSON (password-protected). Portable to any Ente instance or to Aegis (via plain JSON export — discouraged, but possible).

## Data layout

If self-hosting, identical to Ente Photos — Auth data is just additional rows in the same Postgres + additional (tiny) blobs in the same MinIO buckets. See `ente-photos.md`.

If using mobile offline-only, everything's in the app's local encrypted storage (iOS Keychain-backed, Android Keystore-backed).

**Backup priority (offline-only mode):**

1. **Manual encrypted JSON exports** — scheduled reminder to export monthly.
2. **iCloud / Google Drive backup** of your device — includes the Ente Auth data, but tied to device OS backup chain.
3. **Secondary device** with the same codes (either via Ente cloud sync OR via independent import).

## Upgrade procedure

Self-hosted: follow `ente-photos.md` upgrade (same Museum). Mobile/desktop apps: auto-update from their stores.

## Gotchas

- **Ente hosted Auth is FREE** — if you just want "Authy but better," don't self-host; use <https://auth.ente.io>. You'd spin up infrastructure for no reason.
- **Can't self-host Auth without Museum.** There's no "Auth-only backend" slim image. You need Postgres + MinIO + Museum, same as Photos.
- **End-to-end encryption means lost password + lost recovery key = data gone.** Just like Photos. Ente (or you) CAN'T recover a forgotten password. Users MUST save the 24-word recovery key.
- **Offline mode has no recovery mechanism.** Lose your phone → lose your 2FA secrets unless you have an export. Export to encrypted JSON monthly.
- **Two app names / products**: mobile "Ente Auth" and web "auth.ente.io" are the same service; they sync via Museum.
- **Don't confuse Ente Auth with "Ente Authenticator"** — same thing, upstream calls it "Ente Auth."
- **Custom server URL gotcha (mobile)**: long-press the "Sign in" button on the splash screen. Easy to miss — not a visible setting.
- **Backup codes stored alongside TOTP** — convenient but concentrates risk. If vault is compromised, backup codes go too. Some users prefer separate storage for backup codes.
- **Steam Guard** works correctly — many TOTP apps botch Steam's custom format. Ente Auth handles it.
- **No browser extension** for auto-fill (yet). You copy codes manually from the app.
- **No password manager fusion.** Ente Auth is 2FA-only; for passwords, you need KeePassXC / Bitwarden / 1Password alongside.
- **Password-manager-stored TOTP is a different threat model.** Bitwarden / 1Password put TOTP in the same vault as passwords — single compromise = both gone. Ente Auth separates (different app, different master password potentially).
- **F-Droid / Obtainium** have the Android app for users who avoid Play Store.
- **Mobile app encryption** uses the device's secure enclave / keystore — phone PIN / biometric required to unlock vault.
- **Sync latency** — typically seconds. Push-based + periodic pull.
- **Subscription / billing NOT enforced** for Auth in self-hosted Museum. Whole service is free even on ente.io.
- **Desktop app (Electron)** runs heavy for what it does — if you prefer lightweight, use the web app instead.
- **Web app works fully offline once loaded** (service worker + IndexedDB). Useful for kiosk-style setups.
- **Passkeys (FIDO2)**: Auth supports passkey login to your Ente account itself (for the app), in addition to storing passkeys for OTHER sites via browser integration (that's KeePassXC-territory, not Ente's).
- **Two-device-minimum recommendation**: always have your vault on at least 2 devices. Losing the only device with your codes is a nightmare recovery.

## Links

- Upstream repo (monorepo): <https://github.com/ente-io/ente>
- Auth subtree: <https://github.com/ente-io/ente/tree/main/auth>
- Auth docs: <https://help.ente.io/auth>
- Install Auth app: <https://help.ente.io/auth/faq/installing>
- Hosted Auth (free): <https://auth.ente.io>
- Self-hosting (shared with Photos): <https://help.ente.io/self-hosting>
- Website: <https://ente.io/auth>
- iOS: <https://apps.apple.com/app/id6444121398>
- Android (Play): <https://play.google.com/store/apps/details?id=io.ente.auth>
- Android (F-Droid): <https://f-droid.org/packages/io.ente.auth>
- Desktop: <https://ente.io/download>
- Security model: <https://ente.io/architecture>
- Releases: <https://github.com/ente-io/ente/releases>
- Discord: <https://ente.io/discord>
- Related — same backend: see `ente-photos.md`
