---
name: BirdNET-Analyzer
description: "AI-powered bird species identification from audio recordings. Python + Docker + GUI. birdnet-team/BirdNET-Analyzer. 6512 species, deep learning, batch processing, REST API, BirdWeather integration."
---

# BirdNET-Analyzer

**AI-powered bird species identification from audio.** Deep learning model trained on 6,512 bird species — identifies birds from audio recordings or live microphone input. Batch processes large datasets, provides confidence scores, outputs to CSV/JSON/Raven selections. REST API, GUI app, Docker container, and Python library. Used by conservation biologists, researchers, and birders worldwide.

Developed by the **K. Lisa Yang Center for Conservation Bioacoustics at Cornell Lab of Ornithology** in collaboration with **Chemnitz University of Technology**. Academic project; published in *Ecological Informatics*.

- Upstream repo: <https://github.com/birdnet-team/BirdNET-Analyzer>
- Docs: <https://birdnet-team.github.io/BirdNET-Analyzer/>
- Website: <https://birdnet.cornell.edu>
- Models: <https://zenodo.org/records/15050749>
- PyPI: <https://pypi.org/project/birdnet-analyzer/>
- Reddit: <https://www.reddit.com/r/BirdNET_Analyzer/>

## Architecture in one minute

- **Python 3.12** + TensorFlow / custom neural network inference
- Three interfaces: **GUI** (Windows/macOS installers), **CLI** (batch processing), **REST API** (server mode)
- Docker image for server/headless deployments
- Models downloaded separately from **Zenodo** (CC BY-NC-SA 4.0 — non-commercial)
- CPU inference supported; GPU (CUDA) accelerates large-batch processing
- Resource: **medium** — TensorFlow inference on CPU; GPU recommended for large datasets
- Integration: **BirdWeather** (species occurrence platform), **BirdNET-Pi** (Raspberry Pi live detection)

## Compatible install methods

| Method                 | Use when                                                              |
| ---------------------- | --------------------------------------------------------------------- |
| **Windows installer**  | Desktop GUI; researchers/birders without dev background               |
| **macOS installer**    | Same as above                                                         |
| **Python + pip**       | `pip install birdnet-analyzer`; CLI + API; Linux/macOS/Win dev        |
| **Docker**             | Headless server; batch processing pipelines; reproducible CI          |
| **From source**        | Development / customization; `git clone` + `pip install -e .`         |

## Install via pip (CLI + API)

```bash
# Python 3.12 recommended
pip install birdnet-analyzer

# Analyze a single file
birdnet_analyzer analyze --input recording.wav --output results.csv

# Start REST API server
birdnet_analyzer server --host 0.0.0.0 --port 8080
```

## Install via Docker

```bash
docker run --rm \
  -v /path/to/audio:/audio \
  -v /path/to/output:/output \
  ghcr.io/birdnet-team/birdnet-analyzer:latest \
  analyze --input /audio/recording.wav --output /output/results.csv
```

For REST API mode:

```bash
docker run -d \
  -p 8080:8080 \
  --name birdnet \
  ghcr.io/birdnet-team/birdnet-analyzer:latest \
  server --host 0.0.0.0 --port 8080
```

## Install GUI (Windows / macOS)

Download installer from: <https://github.com/birdnet-team/BirdNET-Analyzer/releases/latest>

Double-click to install; no Python knowledge required.

## Core CLI commands

```bash
# Analyze audio file
birdnet_analyzer analyze \
  --input recording.wav \
  --output results.csv \
  --lat 42.36 --lon -71.06 \      # location for species filtering
  --date 2024-05-15 \             # date for migration filtering
  --min_conf 0.25                  # minimum confidence threshold (0.0–1.0)

# Batch process directory
birdnet_analyzer analyze \
  --input /recordings/ \
  --output /results/ \
  --threads 4

# Start REST API server
birdnet_analyzer server
```

## REST API

When running in server mode, BirdNET-Analyzer exposes a REST API for:
- Submitting audio files for analysis
- Getting detection results with confidence scores
- Listing supported species

Useful for integration with home automation, acoustic monitoring stations, or custom dashboards.

## BirdWeather integration

BirdNET-Analyzer can submit detections to [BirdWeather](https://www.birdweather.com/) — a global species occurrence mapping platform. Configure your station token in the settings to contribute sightings to the community map.

## Inputs to collect (for location-aware analysis)

| Input             | Example           | Notes                                                                |
| ----------------- | ----------------- | -------------------------------------------------------------------- |
| Latitude/Longitude | `42.36 / -71.06`  | Used to filter the species list to birds plausibly in your region    |
| Date              | `2024-05-15`      | Used for seasonal migration filtering                                |
| Min confidence    | `0.25`            | Threshold for reporting; lower = more species, more false positives  |
| Language          | `en` (default)    | Species names can be output in 30+ languages                         |

## Output formats

- **CSV** — timestamps, species, confidence scores; import into spreadsheet/R/Python
- **JSON** — structured; for programmatic use
- **Raven Selection Tables** — for Cornell Lab's Raven Pro bioacoustics software
- **Audio segments** — optionally extract detected species segments as audio clips
- **SQLite** — for bulk storage of large dataset results

## Gotchas

- **Model license is CC BY-NC-SA 4.0 — non-commercial.** Source code is MIT, but the neural network models are licensed CC BY-NC-SA 4.0. This means **commercial use of the models is not permitted** without a separate license. Academic and personal/research use is explicitly allowed. Contact ccb-birdnet@cornell.edu for commercial inquiries.
- **Models are on Zenodo, not in the repo.** The pip package / Docker image downloads models on first run. Zenodo occasionally has rate limits — if you're setting up many instances, consider caching the model files.
- **Location + date filtering significantly improves accuracy.** Without `--lat/--lon/--date`, BirdNET evaluates all 6,512 species. With location + date, it filters to species plausibly present in your region and season — fewer false positives.
- **Confidence threshold tuning.** Default 0.25 is a starting point. For high-precision use cases (scientific reporting), raise to 0.5+. For exploratory detection in new areas, lower to 0.1. There's no universal right answer — depends on your use case.
- **Python 3.12 is the tested version.** Other Python 3.x versions may work but aren't guaranteed. Use a virtual environment (`python -m venv birdnet`) to isolate.
- **GPU acceleration.** CPU works but is slow for large batches (hours of audio). CUDA-enabled GPU (NVIDIA) dramatically speeds up batch processing. Docker GPU pass-through requires `--gpus all` and nvidia-container-toolkit.
- **BirdNET-Pi** is a separate project for always-on Raspberry Pi live detection (microphone → real-time species feed). This recipe covers the Analyzer (offline/batch/API), not BirdNET-Pi.
- **6,512 species but not all are equally well-represented** in training data. Common species in North America/Europe have high accuracy; rare/regional species may underperform. The model improves with each major release.
- **Audio format.** WAV is the native format; most common formats (MP3, FLAC, OGG) are supported via ffmpeg preprocessing. Very long recordings are chunked automatically.

## License split

| Component | License |
|-----------|---------|
| Source code | MIT |
| Neural network models | CC BY-NC-SA 4.0 (non-commercial) |

## Project health

Active (Cornell Lab + Chemnitz Uni), CI, Docker GHCR, PyPI, GUI installers, BirdWeather integration, academic citation, Reddit community, multiple funded by German Federal ministries + Cornell donors. Multi-institutional.

## Bird-detection-family comparison

- **BirdNET-Analyzer** — Python, 6512 species, CLI+API+GUI+Docker, Cornell-grade models
- **BirdNET-Pi** — Raspberry Pi live-detection system built on BirdNET models; complementary
- **Merlin Bird ID** — Audubon/Cornell iOS/Android app; SaaS, not self-hosted, live detection
- **Arbimon** — web-based acoustic monitoring platform (SaaS); research-grade
- **Ecosounds / Acoustic Observatory** — large-scale acoustic research platforms

**Choose BirdNET-Analyzer if:** you want state-of-the-art AI bird species identification from audio files — for a backyard recording station, a conservation survey, or an automated acoustic monitoring pipeline.

## Links

- Repo: <https://github.com/birdnet-team/BirdNET-Analyzer>
- Docs: <https://birdnet-team.github.io/BirdNET-Analyzer/>
- Models (Zenodo): <https://zenodo.org/records/15050749>
- BirdWeather: <https://www.birdweather.com>
- BirdNET-Pi: <https://github.com/mcguirepr89/BirdNET-Pi>
