---
name: czkawka-project
description: Czkawka/Krokiet recipe for open-forge. MIT-licensed desktop app for finding and removing unwanted files — duplicates (by hash/name/size), similar images, similar videos, similar music, empty folders/files, big files, temporary files, invalid symlinks, broken files, bad extensions, EXIF remover, video optimizer, bad filenames. Three frontends: **Krokiet** (new Slint-based, recommended), **Czkawka** (older GTK 4, still maintained for bugs), **Czkawka CLI** (for automation/servers), **Cedinia** (experimental Android). Written in Rust; memory-safe + multithreaded. NOT a self-hosted web app — this is a desktop utility. Recipe documents install via distro packages / Flatpak / Snap / precompiled binaries / source build / and the CLI path for scripting.
---

# Czkawka / Krokiet

MIT-licensed desktop utility for finding + removing unwanted files. Upstream: <https://github.com/qarmin/czkawka>. Author: Rafał Mikrut (`qarmin`).

**Name origins (fun fact):** "Czkawka" is Polish for "hiccup" (IPA: `/ˈʧ̑kafka/`). "Krokiet" is Polish for "croquette" (IPA: `/ˈkrɔcɛt/`). "Cedinia" is the newer Android variant.

## Four frontends, one core

| Name | GUI toolkit | Status | When to use |
|---|---|---|---|
| **Krokiet** | Slint | ✅ **Recommended new GUI** | New deploys. Fast, multiplatform, modern. |
| **Czkawka** | GTK 4 | 🛠️ Bugfix-only | Existing users who like GTK. Superseded by Krokiet. |
| **Czkawka CLI** | CLI | ✅ | Headless servers, cron jobs, scripting. |
| **Cedinia** | Slint (touch) | 🧪 Experimental | Android devices. Early-stage. |

All share the same `czkawka_core` Rust library — feature parity across frontends.

## Features (all frontends)

| Tool | What it finds |
|---|---|
| **Duplicates** | By filename / size / hash (full or partial). Fast-partial-hash mode for terabyte-scale libraries. |
| **Empty folders** | Recursive — finds folders whose tree has no content. |
| **Big files** | Top N biggest files in a path. |
| **Empty files** | Zero-byte files. |
| **Temporary files** | `.tmp`, `.bak`, browser caches, OS temp dirs, etc. |
| **Similar images** | Perceptual hashing — finds resized / rewatermarked / re-JPEG'd versions. |
| **Similar videos** | Per-frame perceptual hashing. |
| **Same music** | Audio fingerprint (by content) OR by tags. |
| **Invalid symlinks** | Dangling links. |
| **Broken files** | Corrupted/invalid files (detected per-format). |
| **Bad extensions** | File extension ≠ actual file type (content-sniffed). |
| **EXIF remover** | Strips metadata from images/videos. |
| **Video optimizer** | Crops static parts + re-encodes to more efficient codecs. |
| **Bad filenames** | Files with problematic characters. |

## Not a server app

Unlike most open-forge recipes, **Czkawka is a desktop utility + CLI**, not a long-running service. Install it on a workstation OR on a server where you want to run occasional cleanups. No ports, no database, no web UI.

## Compatible install methods

| Method | Krokiet | Czkawka GUI | Czkawka CLI | First-party? | When |
|---|---|---|---|---|---|
| Precompiled binary | ✅ | ✅ | ✅ | ✅ Recommended | Linux x86_64 / arm64, Windows, macOS |
| Flatpak | ✅ | ✅ | ❌ | ✅ | Linux desktops |
| Snap | ✅ | ✅ | ❌ | ✅ | Ubuntu |
| Distro package (`apt install czkawka`, `dnf install czkawka`, `pacman -S czkawka`, etc.) | ⚠️ Varies | ✅ | ✅ | Varies | Check your distro first — often outdated. |
| Homebrew | `brew install czkawka` | ✅ | ✅ | ⚠️ Community | macOS. |
| `cargo install czkawka_cli` | ❌ | ❌ | ✅ | ✅ | Rust devs. CLI only via cargo. |
| Build from source | ✅ | ✅ | ✅ | ✅ | Contributors / custom builds. |
| Nightly builds | ✅ | ✅ | ✅ | ✅ | `Nightly` release tag on GitHub. |
| AppImage | ⚠️ Community | ⚠️ Community | ❌ | Varies | Portable Linux binary. |
| Android APK (Cedinia) | N/A | N/A | N/A | ✅ Experimental | Android. From GitHub releases. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which frontend?" | `AskUserQuestion`: `krokiet (recommended)` / `czkawka-gui` / `czkawka-cli` | Drives section. |
| preflight | "Install method?" | `AskUserQuestion`: `binary` / `flatpak` / `snap` / `distro-pkg` / `cargo` / `source` | Drives commands. |
| scan | "What directories to scan?" | List of paths | E.g. `/home/alice/Pictures`, `/mnt/nas/music`. |
| scan | "Excluded directories?" | List | e.g. `.git`, `node_modules`, `.cache`. |
| tool | "Which tool?" | `AskUserQuestion`: `duplicates` / `similar-images` / `big-files` / ... | For CLI mode, picks the subcommand. |

## Install — Krokiet (Slint GUI, recommended)

### Precompiled binary

```bash
# Linux x86_64
VERSION=$(curl -s https://api.github.com/repos/qarmin/czkawka/releases/latest | grep tag_name | cut -d'"' -f4)
curl -LO "https://github.com/qarmin/czkawka/releases/download/${VERSION}/krokiet-${VERSION#v}-x86_64-linux.zip"
unzip "krokiet-${VERSION#v}-x86_64-linux.zip"
chmod +x krokiet
./krokiet
```

Releases page: <https://github.com/qarmin/czkawka/releases>.

### Flatpak

```bash
flatpak install flathub com.github.qarmin.Krokiet
flatpak run com.github.qarmin.Krokiet
```

### Snap

```bash
sudo snap install krokiet
```

### Build from source

```bash
# Requires Rust 1.77+
git clone https://github.com/qarmin/czkawka.git
cd czkawka
cargo build --release -p krokiet
./target/release/krokiet
```

## Install — Czkawka (GTK 4 GUI, legacy)

Same pattern as Krokiet; substitute `czkawka_gui` in paths / package names.

```bash
# Flatpak
flatpak install flathub com.github.qarmin.czkawka
```

## Install — Czkawka CLI (headless / server-side cleanups)

### Precompiled binary

```bash
VERSION=$(curl -s https://api.github.com/repos/qarmin/czkawka/releases/latest | grep tag_name | cut -d'"' -f4)
curl -LO "https://github.com/qarmin/czkawka/releases/download/${VERSION}/czkawka_cli-${VERSION#v}-x86_64-linux.zip"
unzip "czkawka_cli-${VERSION#v}-x86_64-linux.zip"
sudo install czkawka_cli /usr/local/bin/
czkawka_cli --help
```

### Cargo

```bash
cargo install czkawka_cli
```

### Distro package

```bash
sudo apt install czkawka-cli      # Debian/Ubuntu (may lag behind upstream)
sudo dnf install czkawka-cli      # Fedora
```

## Example CLI usage

```bash
# Find duplicate files by hash in a directory
czkawka_cli dup \
  --directories /home/alice/Photos \
  --excluded-directories /home/alice/Photos/processed \
  --method hash \
  --search-method size_name \
  --delete-method none     # "none" just lists; see below for deletion modes
```

### Deletion modes (`--delete-method`)

| Mode | Effect |
|---|---|
| `none` (default) | List only, no deletion |
| `aen` | All except newest |
| `aeo` | All except oldest |
| `on` | Only newest (deletes all except newest? — check docs) |
| `oo` | Only oldest |
| `hl` / `hlo` | Replace duplicates with hardlinks |

**⚠️ Always start with `--delete-method none`** on a new scan and inspect the output before running with a delete mode.

### Similar images

```bash
czkawka_cli image \
  --directories /home/alice/Pictures \
  --similarity-preset medium \
  --hash-alg gradient \
  --image-filter lanczos3 \
  --delete-method none
```

### Big files (top 100)

```bash
czkawka_cli big --directories / --number-of-files 100
```

### Empty folders

```bash
czkawka_cli empty-folders --directories /home/alice --delete-folders
```

### Scriptable / cron-friendly

```bash
#!/bin/bash
# Weekly duplicate report piped to mail
czkawka_cli dup \
  --directories /srv/archive \
  --method hash \
  --delete-method none \
  | mail -s "Weekly duplicates report" admin@example.com
```

## Safety tips (for CLI / automated use)

- **ALWAYS dry-run first.** `--delete-method none` produces a report without deletions. Review it.
- **Use hardlink mode (`hl`) for dedup-without-deletion.** Replaces duplicates with hardlinks to one copy — saves space, reversible (each hardlink is still a full file reference).
- **Scope your scan paths narrowly.** Running on `/` with delete flags is catastrophic if the tool misidentifies something.
- **Cached results** live in `~/.cache/czkawka/` — second scans of the same paths are much faster. Delete the cache if behavior seems stale.

## Flatpak / Snap sandboxing

Flatpak Krokiet runs sandboxed; it only sees directories you've granted via Filesystem permissions (Flatseal is handy for this). Out of the box it sees your home dir; `/mnt`, `/media`, and external drives need explicit grants.

## Data layout

Czkawka has **no persistent state outside of cache:**

| Path | Content |
|---|---|
| `~/.cache/czkawka/` | Cache of file hashes, image perceptual hashes, video fingerprints |
| `~/.config/czkawka/` | Saved preferences (GUI only) |
| `~/.config/krokiet/` | Krokiet's saved preferences |

No DB, no server, no user accounts.

## Upgrade procedure

```bash
# Binary
curl -L https://github.com/qarmin/czkawka/releases/latest/download/krokiet-x86_64-linux.zip -o krokiet.zip
unzip -o krokiet.zip
# Or:
flatpak update com.github.qarmin.Krokiet
snap refresh krokiet
cargo install --force czkawka_cli
```

## Gotchas

- **"Duplicate" detection by SIZE ONLY is fast but unreliable.** Two unrelated files can have the same size. Default to `--search-method size_name` or `--method hash` for real deduplication.
- **Hash of a 20 GB file takes a while.** On spinning rust with terabyte-scale media libraries, expect hours. Krokiet shows a progress bar; CLI prints periodically.
- **Similar-images threshold is a trade-off.** Too strict = misses obvious dupes; too loose = flags unrelated images. Start with the default preset, tune up/down.
- **Similar videos require working FFmpeg installation.** Flatpak bundles it; native installs need `ffmpeg` in PATH.
- **Similar music: by tags vs by content** are different algorithms. Tags are fast but can miss dupes with differing metadata; content-based is slower but catches real dupes.
- **The "Broken files" test may flag valid-but-unusual files** — always inspect before deleting. Some HEIC/RAW/proprietary formats are detected as broken incorrectly.
- **Bad Names check** is regex-based; what's "bad" varies by OS/FS. Reasonable defaults, but not authoritative.
- **Video Optimizer re-encodes** — lossy operation. Always test on a backup first. Options for codec + quality are limited compared to ffmpeg hand-tuning.
- **EXIF Remover is destructive.** Once you strip EXIF, it's gone. Back up first if metadata might matter.
- **CLI + GUI cache format may differ across versions.** After a major upgrade, delete `~/.cache/czkawka/` if behavior seems off.
- **No undo.** Deletions go to the trash (via the standard desktop protocol) in GUI mode; CLI deletions go directly. Check the `--delete-method` carefully before hitting enter in CLI.
- **Cedinia (Android) is experimental.** Expect rough edges. Not recommended for critical data.
- **GTK Czkawka is bugfix-only.** New features land in Krokiet (Slint). If you need something specific, check if Krokiet already has it.
- **Distro packages lag.** New features / fixes take weeks to months to land in Debian / Ubuntu. Use upstream binary or Flatpak for the latest.
- **CLI flag syntax evolved.** `--search-method`, `--delete-method`, etc. have seen renames between major versions. Stick to one version in scripts or re-check `--help` after upgrades.

## Links

- Upstream repo: <https://github.com/qarmin/czkawka>
- Releases: <https://github.com/qarmin/czkawka/releases>
- Nightly releases: <https://github.com/qarmin/czkawka/releases/tag/Nightly>
- Krokiet docs: <https://github.com/qarmin/czkawka/blob/master/krokiet/README.md>
- Czkawka GTK docs: <https://github.com/qarmin/czkawka/blob/master/czkawka_gui/README.md>
- Czkawka CLI docs: <https://github.com/qarmin/czkawka/blob/master/czkawka_cli/README.md>
- Czkawka Core library: <https://github.com/qarmin/czkawka/blob/master/czkawka_core/README.md>
- Cedinia (Android): <https://github.com/qarmin/czkawka/blob/master/cedinia/README.md>
- Changelog: <https://github.com/qarmin/czkawka/blob/master/Changelog.md>
- Flathub Krokiet: <https://flathub.org/apps/details/com.github.qarmin.Krokiet>
- Flathub Czkawka: <https://flathub.org/apps/details/com.github.qarmin.czkawka>
- Snap: <https://snapcraft.io/krokiet>
- Crates.io: <https://crates.io/crates/czkawka_cli>
