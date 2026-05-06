---
name: matchering-project
description: Matchering recipe for open-forge. Covers the automated audio matching and mastering tool available as a Docker web app, Python library, and CLI. Upstream: https://github.com/sergree/matchering
---

# Matchering

Novel automated audio matching and mastering application. Feed it a TARGET track (your mix) and a REFERENCE track (a commercial release), and it masters your TARGET to match the RMS, frequency response, peak amplitude, and stereo width of the REFERENCE. Upstream: <https://github.com/sergree/matchering>.

> **License:** GPL-3.0.

Matchering is available in three forms:
1. **Docker Image** (`sergree/matchering-web`) — web UI, easiest self-hosting path
2. **Python library** (`pip install matchering`) — integrate into any Python project
3. **CLI** (`matchering-cli`) — command-line tool built on the library

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Image (web UI) | https://github.com/sergree/matchering/blob/master/DOCKER_LINUX.md | ✅ | Easiest — browser-based UI on port 8360 |
| Python library | https://github.com/sergree/matchering#python-library---for-developers | ✅ | Embed mastering in a Python application |
| matchering-cli | https://github.com/sergree/matchering-cli | ✅ | Command-line batch processing |
| ComfyUI Node | https://github.com/MuziekMagie/ComfyUI-Matchering | Community | Integrate into ComfyUI workflows |
| UVR5 Desktop App | https://ultimatevocalremover.com/ | Community | Desktop GUI (Ultimate Vocal Remover) |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | Options: docker / pip / cli | Drives path |
| network (Docker) | "Port to expose the web UI on?" | Default: 8360 | Docker method |
| files | "Directory to persist processed files?" | Host path | Docker method (mapped to /app/data) |

## Software-layer concerns

### Docker Image — Web UI

The Docker image `sergree/matchering-web` exposes a web interface on port 8360. Processed files are stored in a named volume `mgw-data` mounted at `/app/data`.

**Minimum requirement: 4 GB RAM.**

Run on Linux:

```bash
sudo docker run -dp 8360:8360 \
  -v mgw-data:/app/data \
  --name mgw-app \
  --restart always \
  sergree/matchering-web
```

Web UI available at: http://127.0.0.1:8360

The container restarts automatically on system boot (`--restart always`).

### Update Docker Image

```bash
# Stop and remove old container
sudo docker stop mgw-app && sudo docker rm mgw-app

# Pull latest image
sudo docker pull sergree/matchering-web

# Restart (data volume persists)
sudo docker run -dp 8360:8360 \
  -v mgw-data:/app/data \
  --name mgw-app \
  --restart always \
  sergree/matchering-web
```

Full update instructions: https://github.com/sergree/matchering/blob/master/DOCKER_UPDATING.md

### Python Library

**Minimum requirement: 4 GB RAM, Python 3.8.0+.**

System dependencies:

```bash
# libsndfile (required on Linux — Windows/macOS install it automatically)
sudo apt update && sudo apt -y install libsndfile1

# python3-pip (if not installed)
sudo apt -y install python3-pip

# (Optional) FFmpeg for MP3 input support
sudo apt -y install ffmpeg
```

Install:

```bash
# Linux / macOS
python3 -m pip install -U matchering

# Windows
python -m pip install -U matchering
```

Quick example:

```python
import matchering as mg

mg.log(print)   # optional: route log messages to print

mg.process(
    target="my_song.wav",
    reference="some_popular_song.wav",
    results=[
        mg.pcm16("my_song_master_16bit.wav"),
        mg.pcm24("my_song_master_24bit.wav"),
    ],
)
```

More examples: https://github.com/sergree/matchering/tree/master/examples

### Data directories (Docker)

| Data | Location |
|---|---|
| Processed files / uploads | Docker volume mgw-data → /app/data |

## Upgrade procedure

### Docker

See update steps above — stop old container, `docker pull`, re-run.

### Python library

```bash
python3 -m pip install -U matchering
```

## Gotchas

- **4 GB RAM minimum.** Matchering loads and processes entire audio files in memory. Machines with less than 4 GB RAM will fail or thrash swap heavily.
- **libsndfile required on Linux.** Without it the Python library import fails. Install via the package manager before pip-installing matchering.
- **MP3 input requires FFmpeg.** By default, Matchering only reads lossless formats (WAV, FLAC, AIFF). For MP3 input, install FFmpeg separately.
- **Public hosting privacy.** If hosting the web UI publicly, read the upstream "Keep the Privacy" wiki page (https://github.com/sergree/matchering/wiki/Keep-the-Privacy) before exposing port 8360 to the internet.
- **Output formats are fixed.** The library outputs 16-bit and 24-bit PCM WAV. The Docker web UI provides both for download.
- **Reference track quality matters.** Matchering's output quality depends entirely on the quality of the reference track — use a well-mastered, commercially released song.

## Upstream docs

- GitHub README: https://github.com/sergree/matchering
- Docker Linux guide: https://github.com/sergree/matchering/blob/master/DOCKER_LINUX.md
- Docker update guide: https://github.com/sergree/matchering/blob/master/DOCKER_UPDATING.md
- Log codes: https://github.com/sergree/matchering/blob/master/LOG_CODES.md
- PyPI: https://pypi.org/project/matchering
