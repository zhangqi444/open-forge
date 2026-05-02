# Civitai Data Manager

**What it is:** A CLI tool to locally back up and manage metadata for SafeTensors AI models from Civitai. Saves model info, trigger words, usage notes, example images, and author credits. Generates interactive HTML browsing pages for your local collection. Supports smart incremental updates (only fetches new data), and works with all Civitai `.safetensors` model types (Checkpoints, LoRA, LyCORIS, etc.).

**Official URL:** https://github.com/jmsltnv/civitai-data-manager
**License:** MIT
**Stack:** Python 3.10+; CLI tool (no Docker image / no web UI)

> **Note:** This is a Python CLI tool, not a web service. No Docker image is provided.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / macOS / Windows | Python 3.10+ | pip or Poetry install |
| Any Linux | Cron / systemd timer | Schedule periodic metadata updates |

---

## Inputs to Collect

### Pre-deployment
- `Python 3.10+` — required
- Path to your local models directory (`.safetensors` files)
- Output directory path for generated HTML/metadata

### `config.json` (recommended)
```json
{
    "all": "/path/to/models/directory",
    "output": "/path/to/output/directory",
    "images": true
}
```

Config file takes precedence over CLI arguments when present in the script directory.

---

## Software-Layer Concerns

**Installation:**
```bash
git clone https://github.com/jmsltnv/civitai-data-manager.git
cd civitai-data-manager

# Using Poetry (recommended):
poetry install

# Or pip:
pip install -r requirements.txt
```

**Verify install:**
```bash
python -m civitai_manager.main --help
```

**First run (process entire models directory):**
```bash
# Edit config.json with your paths, then:
python -m civitai_manager.main
```

**Single model:**
```bash
python -m civitai_manager.main --single "path/to/model.safetensors"
```

**Incremental update (only new/changed models):**
```bash
# Use the update config from config_examples/config.update.json
python -m civitai_manager.main --config config_examples/config.update.json
```

**What gets saved per model:**
- Model metadata (name, description, version, base model)
- Trigger words / activation tags
- Usage notes
- Example images (`"images": true`)
- Author credits

**HTML browser:** Run the tool to regenerate the HTML index anytime — opens in any browser, no server needed.

**Upgrade procedure:**
```bash
git pull
poetry install  # or pip install -r requirements.txt
```

---

## Gotchas

- **No API key required** — Civitai's public metadata API is used; no authentication needed
- **No Docker image** — pure Python CLI; not designed to run as a service
- **`.safetensors` only** — does not process `.ckpt`, `.pt`, or other formats
- **Civitai-dependent** — if Civitai removes a model or its metadata, the tool cannot retrieve it; this is why local backups matter
- **Smart updates** — the tool tracks what has already been downloaded; run periodically with the update config to catch new additions without re-processing the full library

---

## Links
- GitHub: https://github.com/jmsltnv/civitai-data-manager
- Civitai: https://civitai.com
- Config examples: https://github.com/jmsltnv/civitai-data-manager/tree/main/config_examples
