---
name: keepassxc-project
description: KeePassXC recipe for open-forge. GPL-2/3 modern desktop password manager — Windows/macOS/Linux native application storing credentials in local KDBX-format encrypted files (KeePass-compatible KDBX3 + KDBX4). NOT a server. Listed on selfh.st because the KDBX file is self-portable — you self-host it via syncing the file through Nextcloud / Syncthing / WebDAV / any cloud. Features: TOTP generation/storage, YubiKey/OnlyKey challenge-response, passkeys (WebAuthn) via browser integration, auto-type, browser integration for Chrome/Firefox/Edge/Brave/Vivaldi/Tor-Browser, SSH agent integration, FreeDesktop Secret Service, HIBP password-health reports, import from 1Password/Bitwarden/Proton Pass. Covers the desktop-app reality + self-hosting-the-DB-file patterns (syncing strategies, conflict handling, mobile clients like KeePassDX/KeePassium).
---

# KeePassXC

GPL-2 / GPL-3 modern desktop password manager. Upstream: <https://github.com/keepassxreboot/keepassxc>. Website: <https://keepassxc.org>. Downloads: <https://keepassxc.org/download>.

## ⚠️ This is NOT a server application

KeePassXC is a **native desktop app** (Qt-based, cross-platform). It does not run on a headless Linux server; it has no web UI; there is no container image. It's listed at selfh.st/apps because the KeePass data format (`.kdbx`) is **self-portable** — you self-host your password vault by syncing the encrypted `.kdbx` file across your devices via your preferred storage (Nextcloud / Syncthing / WebDAV / rsync / iCloud Drive / etc).

**The KeePassXC "install" is just running the installer on each of your devices.** The "self-hosting" angle is syncing the `.kdbx` file to storage you control.

If you want a **web-based multi-user password manager**, use Bitwarden / Vaultwarden / Passbolt instead. If you want the single-user / local-file / cross-platform model, KeePassXC is one of the best options.

## What you get

- **Local KDBX file** — AES-256 or ChaCha20 encrypted, master-password-protected.
- **KDBX3 + KDBX4 support** — compatible with KeePass / KeePassDX (Android) / KeePassium (iOS) / Strongbox / KeeWeb / KPCLI / many others.
- **TOTP** storage + on-the-fly generation.
- **YubiKey / OnlyKey challenge-response** as additional key factor.
- **Passkey (FIDO2/WebAuthn)** support via browser integration.
- **Browser integration** — Chrome, Firefox, Edge, Chromium, Vivaldi, Brave, Tor Browser (via `keepassxc-browser` extension + native messaging).
- **Auto-Type** — KeePassXC types credentials into any window (global keyboard shortcut).
- **SSH agent integration** — unlock DB → ssh keys auto-loaded.
- **FreeDesktop Secret Service** (Linux) — replaces GNOME Keyring so apps can query KeePassXC via DBus.
- **Password health reports** — HIBP check, weak passwords, duplicates.
- **Imports**: 1Password, Bitwarden, Proton Pass, CSV, XML, KeePass 1.x.
- **Exports**: CSV, XML, HTML.
- **CLI** (`keepassxc-cli`) for scripting / headless read of entries.
- **Command-line-only builds** available for servers (no GUI) — the `keepassxc-cli` subset.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Official binaries (Windows / macOS / Linux AppImage + Flatpak + Snap + .deb + .rpm) | <https://keepassxc.org/download/> | ✅ | Primary install path. |
| Homebrew (macOS) | `brew install --cask keepassxc` | Community | macOS users. |
| Chocolatey / winget (Windows) | `choco install keepassxc` / `winget install KeePassXCTeam.KeePassXC` | Community | Windows users. |
| Distro packages (apt/dnf/pacman/etc.) | Most Linux distros ship KeePassXC | ✅ (upstream-adjacent) | Linux users. |
| Source build | <https://github.com/keepassxreboot/keepassxc/blob/develop/INSTALL.md> | ✅ | Contributors. |
| Mobile — **not KeePassXC**; use `KeePassDX` (Android) / `KeePassium` (iOS) / `Strongbox` (iOS+macOS) | — | — | These read the SAME kdbx file. |

No Docker image. No web UI. Don't ask.

## Self-hosting strategy — what you're actually doing

### 1. Pick a storage backend for the `.kdbx` file

Anything that syncs files across your devices:

- **Nextcloud / OwnCloud** — WebDAV + desktop/mobile clients.
- **Syncthing** — peer-to-peer, no server required.
- **Resilio Sync** — proprietary alternative to Syncthing.
- **Rclone** to any S3 / B2 / GDrive / OneDrive / Dropbox backend.
- **Git** (small vaults only; binary diffs don't compress well — use `git-lfs` if > few MB).
- **USB stick / sneakernet** — still a valid option for the paranoid.
- **Direct SSH/SFTP** — KeePassXC opens `sftp://` URLs via URL handler on Linux/macOS.

### 2. Master-key strategy

Choose ONE or combine:

- **Password only** — fine for most users.
- **Password + key file** — key file lives in a different location than the DB (USB stick, separate sync channel).
- **Password + YubiKey/OnlyKey** — hardware second factor via HMAC-SHA1 challenge-response.
- **Password + key file + hardware key** — paranoid tier.

⚠️ **Losing ALL factors = data loss.** Back up the DB + key file + a record of the master password in a SEPARATE secure location (fire-proof safe, safety deposit box).

### 3. Mobile + browser

- **Android**: install KeePassDX → point at your synced `.kdbx` (use Nextcloud app + DocumentsProvider, or Syncthing-Fork + local file).
- **iOS**: install KeePassium (freemium) or Strongbox (freemium) → sync via Files.app / iCloud Drive / WebDAV.
- **Browser**: install `keepassxc-browser` extension in each browser → pair with desktop KeePassXC over DBus/native messaging.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Primary OS?" | `AskUserQuestion`: `windows` / `macos` / `linux` | Drives installer type. |
| install | "Install method?" | `AskUserQuestion`: `official-binary` / `homebrew` / `chocolatey-winget` / `distro-package` / `flatpak` / `appimage` | Per-platform. |
| sync | "Sync backend for .kdbx?" | `AskUserQuestion`: `nextcloud` / `syncthing` / `rclone-to-cloud` / `webdav` / `git` / `usb-manual` | Not KeePassXC-specific — whatever you use. |
| master | "Master-key strategy?" | `AskUserQuestion`: `password-only` / `password-plus-key-file` / `password-plus-yubikey` / `paranoid-triple` | Lost keys = lost vault. |
| mobile | "Mobile clients?" | `AskUserQuestion`: `keepassdx-android` / `keepassium-ios` / `strongbox-ios` / `both` / `none` | For reading on mobile. |
| browser | "Browser integration?" | `AskUserQuestion`: `keepassxc-browser` / `none` | Install extension + enable Tools → Settings → Browser Integration. |
| conflict | "Multi-device write strategy?" | `AskUserQuestion`: `last-write-wins (simple)` / `merge-via-kpcli (explicit)` / `single-writer-only` | Concurrent writes = conflicts; see gotchas. |

## Install — Linux (Flatpak is upstream-recommended for most)

```bash
# Flatpak (upstream-recommended for consistent version across distros)
flatpak install flathub org.keepassxc.KeePassXC
flatpak run org.keepassxc.KeePassXC

# AppImage (official, no root needed)
# Download from https://keepassxc.org/download/#linux
chmod +x KeePassXC-*.AppImage
./KeePassXC-*.AppImage

# Debian/Ubuntu native
sudo apt install keepassxc

# Fedora / RHEL
sudo dnf install keepassxc

# Arch
sudo pacman -S keepassxc
```

## Install — macOS

```bash
# Homebrew cask (most common)
brew install --cask keepassxc

# Or download .dmg from https://keepassxc.org/download/#mac
```

## Install — Windows

```powershell
# winget
winget install KeePassXCTeam.KeePassXC

# Or Chocolatey
choco install keepassxc

# Or download .msi installer from https://keepassxc.org/download/#windows
```

## First-time setup

1. Launch KeePassXC.
2. **Database → New Database** → pick a name.
3. **Encryption Settings**: AES-256 (compatibility) or ChaCha20 (modern, faster). Iterations: tune so unlock takes ~1 second on your machine (higher = slower brute force).
4. **Master Key**: enter strong password; optionally attach a key file; optionally enroll YubiKey.
5. **Save As** → inside your sync dir (`~/Nextcloud/keepass.kdbx` or similar).
6. Your vault is now syncing.

## Browser integration setup

1. Install `keepassxc-browser` extension in your browser (Chrome Web Store / Firefox Add-ons / Edge / etc.).
2. In KeePassXC: **Tools → Settings → Browser Integration** → enable + check the browsers you use.
3. Click the extension icon in the browser → "Connect" → accept the pairing in KeePassXC (name it, e.g. "Firefox laptop").
4. Browse to any site → extension icon shows matching entries → one-click fill.

Native messaging — works even for Flatpak'd KeePassXC + native browsers, but needs manifest symlinks. See <https://keepassxc.org/docs/KeePassXC_UserGuide.html#_setup_browser_integration>.

## `keepassxc-cli` (scripting)

The CLI ships with most packages and can read/write KDBX without a GUI:

```bash
# List entries
keepassxc-cli ls vault.kdbx

# Get a password (prompts for master)
keepassxc-cli show vault.kdbx "Work/Gmail"

# Pipe for scripts (password is the last line of output)
keepassxc-cli clip vault.kdbx "Work/Gmail"    # copies to clipboard

# Add entry from script
keepassxc-cli add -u alice -p 'xyz' vault.kdbx "Work/API"
```

Useful for CI / server automation — a headless server can read secrets from a synced KDBX without ever opening the GUI.

## Data layout

A single file: `<sync-dir>/<name>.kdbx`. Everything lives inside it (encrypted).

Key file (if you use one): separate file, usually kept on a different device/USB.

**Backup priority:**

1. **The `.kdbx` file** — primary + secondary + offline backups. Test restore quarterly.
2. **The key file** — separate backup from DB (defeats the purpose otherwise).
3. **Record of master password** — sealed envelope in a safe; NOT alongside the DB.

KeePassXC auto-backup: **Tools → Settings → Security → Save previous version as backup when saving a database**. Keeps `<name>.kdbx.old` next to the DB.

## Upgrade procedure

KeePassXC follows semver; upgrades are smooth.

```bash
# Flatpak
flatpak update org.keepassxc.KeePassXC

# Homebrew
brew upgrade --cask keepassxc

# Linux distro
sudo apt upgrade keepassxc   # or dnf / pacman

# Windows
winget upgrade KeePassXCTeam.KeePassXC
```

On major-version bump, KeePassXC may offer to upgrade the KDBX format (KDBX3 → KDBX4). KDBX4 is faster + supports ChaCha20 + better argon2 KDF — upgrade if all your clients support KDBX4 (modern KeePassDX/KeePassium do).

## Gotchas

- **NOT a server.** Don't try to `docker run` it. Use Bitwarden/Vaultwarden for that pattern.
- **Concurrent writes corrupt the DB** on most sync services. If you edit the vault on Device A + Device B before a sync, one write overwrites the other. Best practice: close the DB on one device before editing on another. Or use "merge" via `keepassxc-cli merge`.
- **Syncthing is better than Dropbox for conflict handling.** Syncthing keeps `.sync-conflict-*` copies you can merge explicitly. Dropbox/GDrive silently overwrite.
- **Nextcloud + KeePassXC** — enable Nextcloud's file versioning so you can roll back a bad sync.
- **KDBX4 with Argon2 KDF** unlocks slower on weak devices (esp. old Android phones). Tune iterations in Database Settings to balance security vs UX.
- **YubiKey challenge-response requires `ykpersonalize` to program slot 1 or 2 with HMAC-SHA1.** Once programmed, you need THAT yubikey (or a backup configured with same challenge). Lost YubiKey = can't unlock, even with the master password.
- **Key files should be unique** — don't use a file already on every device. The whole point is that the key file is separated.
- **Browser integration requires the desktop app running.** Close KeePassXC → extension can't fetch passwords. Not a tradeoff unique to KeePassXC; all such setups have this property.
- **Flatpak browser integration** needs an extra setup step — symlink the native-messaging manifest. See upstream docs.
- **Auto-Type** uses OS-level keyboard simulation — works into most windows, but some apps (RDP / Citrix / games) eat the keypresses.
- **SSH agent** integration — unlock KeePassXC → SSH keys in entries auto-added to `ssh-agent`. Set entry "Advanced → SSH Agent" → Add key.
- **TOTP vs dedicated authenticator app** — TOTP in KeePassXC means if your password DB is compromised, so is your 2FA. Some users prefer separate apps (Aegis / Authy) for TOTP. Tradeoff: convenience vs defense-in-depth.
- **Secret Service (Linux)** — KeePassXC can replace GNOME Keyring / KWallet. Fine for most apps; some apps hard-code `libsecret` paths and don't respect the replacement.
- **Master password == single point of failure.** If forgotten + no key file + no hardware key backup = vault is lost forever. No recovery mechanism. This is by design.
- **Don't store the key file inside the sync dir** alongside the DB — defeats the purpose. Key file should travel separately.
- **Hardware key slot 2 is typically for challenge-response** (slot 1 is usually OTP). `ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible`.
- **KPCLI vs keepassxc-cli**: different tools. `kpcli` is Perl-based, older; `keepassxc-cli` ships with KeePassXC. Both read KDBX.
- **Password generation policy** in KeePassXC is generous — use at least 20 chars for master password, 20+ chars / 4+ word passphrase for entries.
- **Entry expiration dates** are just visual — KeePassXC doesn't prevent using expired entries. Useful as reminders.
- **Attachments** (files inside entries) bloat the DB. A few KB fine; storing big files (images, docs) inside KDBX = slow opens. Use separate storage.
- **History** (Database Settings → General → History) keeps N previous versions per entry. Defaults to 10; tune for your use.
- **Database integrity check** — occasionally run `keepassxc-cli db-info vault.kdbx` to detect corruption before you rely on a backup.
- **Always test restore** — copy the backup `.kdbx` to a new path and open it. If you only learn your backup was bad during an emergency, the backup doesn't exist.
- **Bottom line**: KeePassXC is excellent for personal/family use with 1-5 devices. For team/company-wide password sharing, use Bitwarden/Vaultwarden/1Password Teams.

## Links

- Upstream repo: <https://github.com/keepassxreboot/keepassxc>
- Website: <https://keepassxc.org>
- Download page: <https://keepassxc.org/download>
- User Guide (official): <https://keepassxc.org/docs/KeePassXC_UserGuide.html>
- QuickStart Guide: <https://keepassxc.org/docs/KeePassXC_GettingStarted.html>
- Build / install from source: <https://github.com/keepassxreboot/keepassxc/blob/develop/INSTALL.md>
- Changelog: <https://github.com/keepassxreboot/keepassxc/blob/develop/CHANGELOG.md>
- Releases: <https://github.com/keepassxreboot/keepassxc/releases>
- Matrix community: `#keepassxc:matrix.org`
- IRC: `#keepassxc` on Libera.Chat
- KeePassXC Browser extension: <https://github.com/keepassxreboot/keepassxc-browser>
- Compatible mobile clients: KeePassDX (<https://github.com/Kunzisoft/KeePassDX>), KeePassium (<https://keepassium.com>), Strongbox (<https://strongboxsafe.com>)
- KDBX format spec: <https://keepass.info/help/kb/kdbx_4.html>
