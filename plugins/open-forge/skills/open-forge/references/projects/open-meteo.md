---
name: open-meteo
description: Open-Meteo recipe for open-forge. Self-hosted weather API with forecasts, historical data, and climate data from major national weather services. Docker Compose deploy. Upstream: https://github.com/open-meteo/open-meteo
---

# Open-Meteo

Open-source weather API with hourly forecasts up to 16 days, 80 years of historical data, and data from all major national weather services (NOAA, DWD, MeteoFrance, ECMWF, JMA, and more). Sub-10ms response times. No API key required for the hosted API; fully self-hostable.

5,265 stars · AGPLv3 (code) / CC BY 4.0 (data)

Upstream: https://github.com/open-meteo/open-meteo
Website: https://open-meteo.com/
API docs: https://open-meteo.com/en/docs
Docker image: `ghcr.io/open-meteo/open-meteo`

## What it is

Open-Meteo provides a complete weather data platform:

- **Forecast API** — Hourly/daily forecasts up to 16 days, 11 km global / 1.5 km regional models
- **Historical Weather API** — 80+ years of historical weather data
- **Multiple models** — GFS+HRRR, DWD ICON, MeteoFrance Arome/Arpege, ECMWF IFS, JMA, GEM HRDPS, MET Norway
- **Derived APIs** — Marine forecasts, air quality, geocoding, elevation, flood forecasts
- **No API key** — The hosted public API is free for non-commercial use with no registration
- **Self-hosting** — Run your own instance, sync only the weather models and variables you need

Used by Home Assistant, Breezy Weather, and hundreds of other weather apps.

**Note on self-hosting**: The self-hosted instance only includes models you explicitly sync. Each model requires downloading GBs to TBs of data. For most use cases, the free public API at `api.open-meteo.com` is the simpler choice; self-hosting makes sense for commercial use, privacy requirements, or offline environments.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (recommended) | https://github.com/open-meteo/open-meteo/blob/main/docker-compose.yml | Self-hosted instance |
| Ubuntu package | https://github.com/open-meteo/open-meteo/releases | Bare metal install |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| models | "Which weather models to sync? (e.g., dwd_icon, gfs, ecmwf)" | Self-host |
| variables | "Which variables? (e.g., temperature_2m, precipitation, wind_speed_10m)" | Self-host |
| past_days | "How many days of historical data to sync? (default: 2)" | Self-host |
| storage | "How much disk space available? (each model = 10s of GB)" | Self-host |

## Docker Compose install

Upstream: https://github.com/open-meteo/open-meteo/blob/main/docker-compose.yml

### 1. Download docker-compose.yml

    mkdir -p /opt/open-meteo && cd /opt/open-meteo
    curl -O https://raw.githubusercontent.com/open-meteo/open-meteo/main/docker-compose.yml

### 2. Review and customize sync command

The default docker-compose.yml syncs `dwd_icon` `temperature_2m` — edit to add models/variables:

    # In docker-compose.yml, update the sync command:
    command: sync dwd_icon temperature_2m precipitation wind_speed_10m --past-days 2 --repeat-interval 1 --concurrent 2

Available models: `gfs`, `dwd_icon`, `ecmwf`, `meteofrance`, `jma`, `gem`, `metno`, and more.
Full variable list: https://open-meteo.com/en/docs

### 3. Start the stack

    docker compose up -d

Two services start:
- `open-meteo-sync` — Downloads and continuously updates weather model data
- `open-meteo-api` — Serves the REST API on port 8080

### 4. Wait for initial sync

The first sync downloads weather model data. This can take minutes to hours depending on the models and variables selected. Monitor progress:

    docker compose logs -f open-meteo-sync

### 5. Test the API

    curl "http://localhost:8080/v1/forecast?latitude=47.1&longitude=8.6&hourly=temperature_2m&models=icon_global"

### 6. Docker Compose with multiple models

    services:
      open-meteo-sync:
        image: ghcr.io/open-meteo/open-meteo
        environment:
          LOG_LEVEL: info
        command: >
          sync
          dwd_icon temperature_2m precipitation wind_speed_10m
          gfs025 temperature_2m precipitation
          --past-days 7
          --repeat-interval 1
          --concurrent 2
        volumes:
          - open_meteo_database:/app/data
        restart: always

      open-meteo:
        image: ghcr.io/open-meteo/open-meteo
        volumes:
          - open_meteo_database:/app/data
        ports:
          - "8080:8080"
        command: ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
        restart: always

    volumes:
      open_meteo_database:

## API usage

The self-hosted API uses the same format as the public API:

    # Forecast
    GET /v1/forecast?latitude=52.52&longitude=13.41&hourly=temperature_2m,precipitation&forecast_days=7

    # Historical
    GET /v1/archive?latitude=52.52&longitude=13.41&start_date=2020-01-01&end_date=2020-01-31&hourly=temperature_2m

Full API reference: https://open-meteo.com/en/docs

## Disk space requirements (approximate per model)

| Model | Variables | Approximate size |
|---|---|---|
| DWD ICON (global) | temperature, precip, wind | ~50 GB |
| GFS 0.25° | temperature, precip, wind | ~30 GB |
| ECMWF IFS | temperature, precip | ~20 GB |
| All models, all variables | Everything | ~2 TB+ |

Only sync what you need.

## Upgrade

    docker compose pull
    docker compose up -d

## Gotchas

- **Data size** — Syncing multiple models with many variables consumes significant disk space (10s to 100s of GB). Plan storage accordingly.
- **Initial sync time** — First data download is slow. The API will return errors for unavailable data until the sync completes.
- **`--past-days`** — Controls how many days of historical data to keep. Larger values = more disk usage.
- **Commercial use requires self-hosting** — The public `api.open-meteo.com` is free for non-commercial use only. Commercial users must self-host.
- **Data license** — Weather data is CC BY 4.0 (attribution required). The code is AGPLv3.
- **Geocoding is separate** — The geocoding API (place name → coordinates) is a separate service: https://github.com/open-meteo/geocoding-api

## Links

- GitHub: https://github.com/open-meteo/open-meteo
- Website: https://open-meteo.com/
- API docs: https://open-meteo.com/en/docs
- Docker Compose: https://github.com/open-meteo/open-meteo/blob/main/docker-compose.yml
- Available models: https://open-meteo.com/en/docs#weather_models
- Blog: https://openmeteo.substack.com
