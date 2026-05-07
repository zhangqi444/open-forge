# cmyflix

**Minimalist self-hosted video streaming server** written in C. Scans your media library, fetches metadata from TMDB, generates JSON databases and static HTML pages served by any web server. Designed for NAS/SBC deployments (Raspberry Pi, Odroid, etc.).

**Source:** https://github.com/farfalleflickan/cmyflix  
**License:** AGPL-3.0

> No official Docker image. cmyflix generates static files served by any web server.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (Debian/Ubuntu/ARM) | Native binary / .deb package | Primary method |
| Any Linux | Build from source | Requires C build tools |

---

## System Requirements

- libcjson ≥ 1.7.15
- libcurl ≥ 7.68
- ImageMagick
- ffmpeg
- **TMDB API key** (free at https://www.themoviedb.org/settings/api)
- A web server (nginx, Apache, lighttpd) to serve generated static files

---

## Inputs to Collect

| Input | Description |
|-------|-------------|
| `TMDB_API_KEY` | TMDB API key for metadata and posters |
| `TV_PATH` | Path to TV shows directory |
| `MOVIES_PATH` | Path to movies directory |
| `OUTPUT_PATH` | Where to write generated HTML/JSON (must be web server docroot) |

---

## Software-layer Concerns

### Install (Debian/Ubuntu)
```bash
# Pre-compiled .deb from GitHub releases
wget https://github.com/farfalleflickan/cmyflix/releases/latest/download/cmyflix_*.deb
sudo dpkg -i cmyflix_*.deb

# Build from source
sudo apt install libbsd-dev libcjson-dev libcurl4-openssl-dev imagemagick ffmpeg
git clone https://github.com/farfalleflickan/cmyflix
cd cmyflix && make && sudo make install
```

### Config file
cmyflix looks for `cmyflix.cfg` in this order:
1. Same directory as the binary
2. `$HOME/.config/cmyflix/`
3. `/etc/cmyflix/`

Run `cmyflix --help` for all configuration options.

### How it works
1. Scans media directories
2. Fetches metadata (title, poster, description) from TMDB
3. Generates JSON databases and static HTML pages
4. You serve the output dir with nginx/Apache

### Required folder structure
**TV Shows:** `/media/tv/Show.Name/Season.1/Show.Name.S01E01.mp4`
Extras folder: `Season.Extras/`

**Movies:** `/media/movies/Movie.Name/Movie.Name.mp4`

### Supported formats
`mp4`, `mkv`, `ogv`, `webm` (HTML5 browser-playable only; no transcoding)

### nginx (serve static output)
```nginx
server {
    listen 80;
    root /path/to/cmyflix/output;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
```

### Password protection (optional)
Use [JSONlogin](https://github.com/farfalleflickan/JSONlogin) as a login layer.

---

## Upgrade Procedure

Download new `.deb` or `git pull && make && sudo make install`, then re-run cmyflix to regenerate static output.

---

## Gotchas

- **No transcoding.** Files must be in browser-compatible codecs (H.264/AAC in mp4/mkv).
- **TMDB API key required** for metadata.
- **Strict folder structure required.** Non-conforming files won't be indexed.
- **Re-run after adding media** to regenerate static pages.
- **No built-in auth.** Use JSONlogin or a reverse proxy for access control.

---

## References

- Upstream README: https://github.com/farfalleflickan/cmyflix#readme
