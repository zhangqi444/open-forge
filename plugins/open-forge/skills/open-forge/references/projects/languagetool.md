# LanguageTool

Open-source grammar, style, and spell checker for 25+ languages. Acts as a proofreading API server — integrates with browsers (extension), word processors (LibreOffice/Word add-in), editors, and custom apps. LGPL 2.1+. 14K+ GitHub stars. Upstream: <https://github.com/languagetool-org/languagetool>. Docs: <https://dev.languagetool.org>.

Self-hosting LanguageTool gives you an HTTP API server on port `8010` that accepts text checks and returns grammar/style errors with suggestions.

## Compatible install methods

Verified against upstream Docker community projects referenced at <https://github.com/languagetool-org/languagetool#docker>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`erikvl87/languagetool`) | Community Docker image | ❌ community | Most popular Docker path. Well-maintained. |
| Docker (`meyay/languagetool`) | Community Docker image | ❌ community | Alternative community image with n-gram support. |
| Script install (bare-metal) | `curl ... \| sudo bash` | ✅ | Non-Docker Linux install. |
| LanguageTool.org | <https://languagetool.org> | ✅ (hosted) | Cloud SaaS — free + premium tiers. |
| Browser extension (self-hosted) | Configurable to point at your server | ✅ | Point the official browser ext at your instance. |

> **Note:** LanguageTool does not publish an official Docker image. The community images (`erikvl87`, `meyay`, `silviof`) are the de-facto standard for Docker deployments.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| languages | "Which language n-gram packs to enable (e.g. `en,de,fr`)? (optional — improves detection)" | Free-text | Optional |
| max_text_length | "Max text length per API request (chars)?" | Integer | Optional |

## Software-layer concerns

### Docker Compose (community image)

```yaml
services:
  languagetool:
    image: erikvl87/languagetool:latest
    ports:
      - "8010:8010"
    environment:
      - langtool_languageModel=/ngrams   # optional: path to n-gram data
      - Java_Xms=512m
      - Java_Xmx=1g
    volumes:
      - ./ngrams:/ngrams                 # optional: mount n-gram data
    restart: unless-stopped
```

### API usage

Check a text:

```bash
curl -X POST http://localhost:8010/v2/check \
  --data "language=en-US" \
  --data-urlencode "text=This are a mistake."
```

Response:
```json
{
  "matches": [
    {
      "message": "Use 'is' instead of 'are'.",
      "offset": 5,
      "length": 3,
      "replacements": [{"value": "is"}],
      "rule": {"id": "ARE_VBZ", "description": "..."},
      "context": {"text": "This are a mistake.", "offset": 5, "length": 3}
    }
  ]
}
```

Available languages:
```bash
curl http://localhost:8010/v2/languages
```

### Key environment variables (erikvl87 image)

| Variable | Purpose |
|---|---|
| `langtool_languageModel` | Path to n-gram directory (enables low-frequency word detection) |
| `langtool_fasttextModel` | Path to fastText model for language detection |
| `Java_Xms` | JVM initial heap size (default: `256m`) |
| `Java_Xmx` | JVM max heap size (default: `512m`) — increase for heavy use |
| `langtool_maxTextLength` | Max characters per request |
| `langtool_maxTextHardLength` | Hard maximum (requests over this are rejected) |
| `langtool_requestLimit` | Max requests per requestLimitPeriodInSeconds |
| `langtool_cacheSize` | Result cache size (number of entries) |

### N-gram data (optional but recommended)

N-gram data significantly improves confusion pair detection (e.g. "their/there/they're"):

```bash
# Download English n-grams (~8 GB uncompressed)
mkdir -p ngrams/en
wget https://languagetool.org/download/ngram-data/ngrams-en-20150817.zip
unzip ngrams-en-20150817.zip -d ngrams/en/

# Set in compose:
# langtool_languageModel=/ngrams
# Mount: ./ngrams:/ngrams
```

N-gram downloads: <https://languagetool.org/download/ngram-data/>

### Browser extension setup

1. Install the LanguageTool browser extension (Chrome/Firefox)
2. Open extension settings → "Using a local server"
3. Set server URL to `http://localhost:8010/v2`

The extension will now send text to your self-hosted instance instead of the cloud API.

### LibreOffice / MS Word add-in

Point the add-in at your server URL in the plugin settings. The same HTTP API endpoint works.

### Memory requirements

| Use case | Recommended Java heap (`Xmx`) |
|---|---|
| Personal / light use | 512 MB |
| Small team | 1 GB |
| Heavy / multiple languages | 2+ GB |
| With n-gram data loaded | Add 1–2 GB per language |

## Upgrade procedure

```bash
docker pull erikvl87/languagetool:latest
docker compose up -d
```

No persistent data store — stateless API server. No migrations.

## Gotchas

- **No official Docker image.** LanguageTool is a Java app; the upstream project only publishes JARs. `erikvl87/languagetool` is the most maintained community Docker image and is safe to use.
- **Memory-intensive.** Loading multiple language rule sets takes significant RAM. With n-gram data for 2–3 languages, expect 2–4 GB heap usage.
- **N-gram files are large.** English alone is ~8 GB uncompressed. Make sure your host has disk space before downloading.
- **No authentication built-in.** The HTTP API has no auth layer. Place behind a reverse proxy with access controls if exposing publicly.
- **Premium rules not included.** LanguageTool.org offers premium grammar detection features that are not in the open-source edition (LGPL).
- **Cold start is slow.** The JVM + rule loading can take 30–60 seconds before the first request is served.
- **`/v2/check` is the primary endpoint.** The old `/api/v2/check` path (used in older browser extension versions) should still work, but `/v2/check` is current.

## Links

- Upstream: <https://github.com/languagetool-org/languagetool>
- HTTP API docs: <https://dev.languagetool.org/http-server>
- HTTP API reference (Swagger): <https://languagetool.org/http-api/swagger-ui/>
- Public API usage guide: <https://dev.languagetool.org/public-http-api>
- N-gram data downloads: <https://languagetool.org/download/ngram-data/>
- Docker community image: <https://github.com/Erikvl87/docker-languagetool>
- Docker Hub: <https://hub.docker.com/r/erikvl87/languagetool>
- Browser extension: <https://languagetool.org/browser-extensions>
