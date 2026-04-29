---
name: localsend-project
description: LocalSend recipe for open-forge. MIT-licensed cross-platform peer-to-peer file/message sharing (AirDrop-alike). It's a desktop/mobile app, not a traditional self-hosted server — no cloud component. This recipe documents how to install it per platform and mentions the edge case of running the CLI / portable build on a Linux server for scripted transfers within a LAN.
---

# LocalSend (AirDrop-style local file sharing)

MIT-licensed, cross-platform file and message sharing over the local network. Peers discover each other via mDNS and transfer via REST + HTTPS — no internet connection, no account, no central server.

**Upstream README:** https://github.com/localsend/localsend/blob/main/README.md
**Homepage:** https://localsend.org
**Releases / installers:** https://github.com/localsend/localsend/releases

> [!NOTE]
> LocalSend is **not a traditional self-hosted server**. It's a peer-to-peer desktop/mobile app — there is no daemon you configure, no web UI, no API you aim a reverse proxy at. This recipe exists because LocalSend is listed on selfh.st (it fits the "local-only, no cloud" ethos), but the "deploy" story is just "install the app on each device." No infrastructure required.

## What it actually is

- Flutter app built for Android, iOS, macOS, Windows, Linux, Fire OS
- Starts a small HTTPS server on the LAN when the app is open
- Other LocalSend instances on the same network discover it via mDNS
- Tap a peer → drop files → they're transferred directly, no internet

Common use case: moving a photo from your phone to your laptop without cables or cloud uploads. Alternative to AirDrop, Nearby Share, ShareIt, Quick Share.

## Compatible combos

There's nothing to "host" in the open-forge sense — no Docker, no compose, no VPS.

| Platform | Install method |
|---|---|
| Windows | Winget / Scoop / Chocolatey / MSIX / EXE installer / Portable ZIP |
| macOS | App Store / Homebrew cask / DMG |
| Linux | Flathub / Snap / AUR / TAR / DEB / AppImage / Nixpkgs |
| Android | Play Store / F-Droid / direct APK |
| iOS | App Store |
| Fire OS | Amazon Appstore |

All links: the upstream README's "Download" table at https://github.com/localsend/localsend#download

## Install reference (platform by platform)

From upstream README:

**Linux**

```bash
# Flathub (recommended for most distros)
flatpak install flathub org.localsend.localsend_app

# Snap
snap install localsend

# Arch AUR
yay -S localsend-bin

# Debian / Ubuntu — .deb from releases page
wget https://github.com/localsend/localsend/releases/latest/download/LocalSend-<version>-linux-x86-64.deb
sudo dpkg -i LocalSend-*-linux-x86-64.deb

# AppImage — portable, no install
wget .../LocalSend-<version>-linux-x86-64.AppImage
chmod +x LocalSend-*.AppImage
./LocalSend-*.AppImage
```

**macOS**

```bash
brew install --cask localsend
```

**Windows**

```powershell
winget install LocalSend.LocalSend
# Or Scoop:
scoop install localsend
# Or Chocolatey:
choco install localsend
```

**Android / iOS:** direct App Store links.

## The edge case: LocalSend on a Linux server

If you want LocalSend on a headless server (e.g. to drop phone uploads onto a NAS), you can run the Linux build in an X server / Wayland-forwarded session or via `xvfb-run` for a receive-only daemon. **This is unusual and not officially supported** — upstream targets desktops with UIs.

Practical approaches seen in the wild:

- Run LocalSend on a Raspberry Pi with a display (makes it a fancy "inbox" device)
- Use the AppImage under `xvfb-run` and configure auto-accept (upstream has an "auto-receive" toggle in settings)
- For true headless scripting, consider [`localsend-cli`](https://github.com/localsend/localsend/issues?q=cli) — community issue threads have discussed a CLI but there is no first-party headless binary as of the current README

For a "real" self-hosted receive endpoint on a LAN, a simpler alternative is **Syncthing** with a receive-only folder — more mature for always-on server use.

## Software-layer concerns

### Ports

- `53317/tcp` — HTTP/HTTPS listener (configurable in-app)
- `53317/udp` — mDNS / multicast discovery

LocalSend will pick the port automatically if the default is in use. No action required for most users; if your firewall blocks UDP multicast, LAN discovery fails and you have to pair manually by IP.

### Data

Received files go to a platform-specific "Downloads" directory, configurable in Settings. No database, no config DB — just per-device preferences.

### Auto-update

From the README:

> It is recommended to download the app either from an app store or from a package manager because the app does not have an auto-update.

So upgrades are: re-run your package manager (`brew upgrade`, `winget upgrade`, `flatpak update`, etc.) or manually download the new release.

### Protocol

Custom REST + HTTPS protocol documented at https://github.com/localsend/protocol. Self-signed certs negotiated at pairing time. Two devices must confirm a session before files flow.

## Upgrade procedure

- **App stores / package managers** — use their update UI (Play Store / App Store / `brew upgrade` / `winget upgrade` / `flatpak update` / `apt`)
- **Manual installs** — download the new release and replace the binary
- **Portable ZIP / AppImage** — download the new version to replace the old

No migration needed; data is just files in the system Downloads folder.

## Gotchas

- **Not a server.** If the user asks "how do I self-host LocalSend on my Hetzner box?" — redirect them. LocalSend is LAN-peer-to-peer; a VPS can't participate meaningfully (no LAN, no mDNS).
- **mDNS blocked on some corporate / segmented networks.** Pairs on the same subnet but different VLANs, different guest-Wi-Fi, or hotel networks won't find each other. Manual pair-by-IP works in that case.
- **No auto-update.** Use the package manager or app store to stay current.
- **Unofficial MSIX preview builds exist** (linked in README). Upstream explicitly says stability isn't guaranteed for those.
- **"Auto-receive" mode accepts any peer that pairs.** Think about that on a shared network — a guest could drop anything into your downloads. Review the setting.
- **Linux headless is not supported.** Possible with Xvfb hacks; fragile. Use Syncthing for that role.
- **Each major platform has a different app-store identity.** F-Droid lags Play Store sometimes; Flathub lags sometimes; check release notes on GitHub for latest features.
- **iOS TestFlight previously used; now stable App Store release.** Older blog posts may point at TestFlight — not needed.

## TODO — verify on subsequent deployments

- [ ] Check if a first-party CLI / headless binary ships — upstream has discussed it.
- [ ] Test AppImage under `xvfb-run` on a Pi for an "inbox" pattern.
- [ ] Compare LocalSend vs Snapdrop vs PairDrop for the "web-only" AirDrop alternatives.
- [ ] Document mDNS troubleshooting for segmented networks.
