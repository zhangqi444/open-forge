---
name: tagspaces
description: TagSpaces recipe for open-forge. Offline-first, cross-platform file manager and organizer with tagging, note-taking, and WebDAV support (Nextcloud/ownCloud integration). Desktop + web app. Upstream: https://github.com/tagspaces/tagspaces
---

# TagSpaces

Free and open-source offline-first file manager, organizer, and note-taking app. Manages local files by adding tags directly to filenames or via JSON sidecar files. Works offline with no cloud dependency. Integrates with WebDAV servers like Nextcloud/ownCloud for cloud-synced file management.

5,105 stars · AGPL-3.0

Upstream: https://github.com/tagspaces/tagspaces
Website: https://www.tagspaces.org/
Docs: https://docs.tagspaces.org/
Releases: https://github.com/tagspaces/tagspaces/releases

## What it is

TagSpaces is a file-centric productivity tool:

- **File tagging** — Add tags to files by renaming them (`file.txt` → `file[tag1 tag2].txt`) or via JSON sidecars (`.ts` files)
- **File browsing** — Browse local directories, filter by tags and filename
- **Note-taking** — Create/edit TXT, Markdown, HTML, and rich-text notes
- **Media player** — Play audio and video formats inline
- **To-do lists** — HTML-based task management
- **Full-text search** — Search file contents
- **Web Clipper** — Browser extension to save web pages locally
- **WebDAV integration** — Connect to Nextcloud, ownCloud, or any WebDAV server as a "location"

**Note on editions**: TagSpaces Lite (the open-source version) covers the core features. TagSpaces Pro adds advanced search, geo-tagging, custom perspectives, and S3 support (paid). The open-source Lite edition is what's in this catalog.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Desktop app (recommended) | https://github.com/tagspaces/tagspaces/releases | Windows, Linux, macOS — primary use case |
| Web app (self-hosted) | https://github.com/tagspaces/tagspaces/releases | Browser-based access via WebDAV/web server |
| Browser extension | https://github.com/tagspaces/browser-extensions | Web Clipper for Firefox, Chrome, Edge |

## Desktop install

Download from releases: https://github.com/tagspaces/tagspaces/releases

### Linux

    # AppImage (universal)
    chmod +x tagspaces-*.AppImage
    ./tagspaces-*.AppImage

    # Or install .deb (Debian/Ubuntu)
    sudo dpkg -i tagspaces_*.deb

### macOS

Download the `.dmg` file from releases and drag to Applications.

### Windows

Download the `.exe` installer from releases.

## Self-hosted web app

TagSpaces can run as a static web app served from any web server. Users connect their own local or WebDAV locations from within the browser.

### Nginx static file server

    # Download and extract the web app release
    mkdir -p /var/www/tagspaces
    # Download the 'web' release variant from GitHub releases
    unzip tagspaces-web-*.zip -d /var/www/tagspaces/

    # Nginx config
    server {
        listen 80;
        server_name tagspaces.example.com;
        root /var/www/tagspaces;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }
    }

### Docker (community image)

    docker run -d \
      --name tagspaces \
      -p 5000:80 \
      -v /your/files:/files \
      tagspaces/tagspaces-web:latest

## Adding locations (connecting to files)

After opening TagSpaces, add a "location":

1. Click **Connect a Location** (or the `+` button in the sidebar)
2. Choose location type:
   - **Local** — Browse files on the local disk/mounted NFS/SAMBA
   - **Web (WebDAV)** — Connect to Nextcloud/ownCloud via WebDAV URL
   - **AWS S3** — S3-compatible storage (Pro edition)

### WebDAV / Nextcloud

In TagSpaces → Add Location → Web:
- **Location Type**: WebDAV
- **URL**: `https://nextcloud.example.com/remote.php/dav/files/username/`
- **Username**: your Nextcloud username
- **Password**: Nextcloud app password (Settings → Security → App passwords)

## Tagging system

TagSpaces offers two tagging modes:

| Mode | How it works | Pros | Cons |
|---|---|---|---|
| **Filename tags** | Renames file: `photo[vacation beach].jpg` | Works with any file sync (Syncthing, Dropbox) | Renames original file |
| **Sidecar files** | Creates `photo.jpg.json` alongside the file | Tags don't modify original files | Extra `.json` files alongside originals |

Configure the default mode in Settings → File tagging approach.

## Upgrade

Download the new release from https://github.com/tagspaces/tagspaces/releases and reinstall (replace the AppImage or install the new .deb).

## Gotchas

- **Desktop-first** — TagSpaces is primarily designed for desktop use. The web app is functional but the desktop app has better filesystem integration.
- **Filename tagging changes filenames** — If you choose filename-based tags, your files get renamed. This may break hardcoded references or scripts. Consider sidecar mode if file renaming is a concern.
- **AGPL license** — If you modify and distribute TagSpaces, you must publish the source code. The web app self-hosting is fine without triggering AGPL for private use.
- **Pro features** — Advanced features (enhanced search, geo-tagging, S3 locations, custom perspectives) require TagSpaces Pro (paid). The free Lite version covers core tagging and browsing.
- **No server-side logic** — The self-hosted web app is purely static HTML/JS. Authentication and file access is handled by the WebDAV server (Nextcloud etc.), not TagSpaces itself.
- **AppImage on Linux** — May need `libfuse2` installed: `apt install -y libfuse2`

## Links

- GitHub: https://github.com/tagspaces/tagspaces
- Website: https://www.tagspaces.org/
- Docs: https://docs.tagspaces.org/
- Releases: https://github.com/tagspaces/tagspaces/releases
- Browser extensions: https://github.com/tagspaces/browser-extensions
- Pro vs Lite: https://www.tagspaces.org/products/
