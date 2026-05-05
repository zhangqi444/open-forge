---
name: netron
description: Netron recipe for open-forge. Covers browser-hosted (netron.app), pip/Python server, and desktop app installs. Based on upstream README at https://github.com/lutzroeder/netron.
---

# Netron

Viewer for neural network, deep learning, and machine learning models. Supports ONNX, TensorFlow Lite, PyTorch, Keras, Core ML, Caffe, Safetensors, and many more formats. Upstream: <https://github.com/lutzroeder/netron>. Live browser version: <https://netron.app>.

Netron is primarily a visualization tool — it opens model files and displays the network graph interactively. The server/self-hosted use case is running it as a local web service via Python so teams can open models in a browser without installing the desktop app on every machine.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Browser (netron.app) | https://netron.app | Yes | Quickest — no install. Open model files directly in browser. |
| Python (pip) | https://github.com/lutzroeder/netron#install | Yes | Self-hosted server or scripted model opening. pip install netron. |
| macOS desktop | https://github.com/lutzroeder/netron/releases/latest | Yes | .dmg download or brew install --cask netron |
| Linux desktop | https://github.com/lutzroeder/netron/releases/latest | Yes | .deb or .rpm download |
| Windows desktop | https://github.com/lutzroeder/netron/releases/latest | Yes | .exe installer or winget install netron |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Choose from table above | Drives which section loads |
| model | Path or URL to the model file to open? | Free-text | Python server mode |
| network | Which port to expose the web UI on? (default: 8080) | Integer | Python server mode |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Formats | ONNX, TF Lite, PyTorch, torch.export, ExecuTorch, Core ML, Keras, Caffe, Darknet, TF.js, Safetensors, NumPy, and more. Experimental: TorchScript, MLIR, TensorFlow, OpenVINO, RKNN, ncnn, MNN, PaddlePaddle, GGUF, scikit-learn. |
| Default port | 8080 (when run as Python web server) |
| No Docker image | Upstream does not publish an official Docker image. The Python pip method is the closest to a self-hosted server. |
| Python version | Python 3.x (3.8+ recommended) |
| Stateless | Netron does not store model data server-side. It opens files on demand. |

## Method — Python pip (server mode)

Source: https://github.com/lutzroeder/netron#install

    pip install netron

Open a model file in the browser:

    netron /path/to/model.onnx
    # Opens http://localhost:8080 in default browser

Start as a background server accessible to other machines:

    netron --host 0.0.0.0 --port 8080 /path/to/model.onnx

Or from Python script:

    import netron
    netron.start('/path/to/model.onnx')

## Method — Browser (no install)

Visit https://netron.app and open a model file directly. The browser loads the viewer entirely client-side — model data does not leave the browser (no server upload).

URL-based opening (for sharing):

    https://netron.app?url=https://example.com/path/to/model.onnx

The model file must be publicly accessible for URL-based sharing.

## Method — Desktop app

macOS:

    brew install --cask netron
    # or download .dmg from https://github.com/lutzroeder/netron/releases/latest

Linux:

    # Download .deb or .rpm from https://github.com/lutzroeder/netron/releases/latest
    sudo dpkg -i netron_<version>_amd64.deb  # Debian/Ubuntu
    sudo rpm -i netron-<version>.x86_64.rpm  # Fedora/RHEL

Windows:

    winget install -s winget netron
    # or download .exe from https://github.com/lutzroeder/netron/releases/latest

## Upgrade procedure

Python:

    pip install --upgrade netron

Desktop (macOS):

    brew upgrade --cask netron

Desktop (others): download latest release from https://github.com/lutzroeder/netron/releases/latest and install over existing.

## Gotchas

- No persistent server state: Netron opens files on demand. If the file moves or is deleted, the viewer shows nothing. There is no "server" that stores models.
- No official Docker image: upstream does not publish to Docker Hub or GHCR. Wrap pip install netron yourself if you want Docker deployment.
- Browser version is the same tool: the hosted version at netron.app and the pip-installed version use the same codebase. The browser version runs entirely client-side — no model data is uploaded to netron.app.
- Large models may be slow: very large model files (multi-GB) can take significant time to parse and render, particularly in the browser.
- Experimental format support: TorchScript, MLIR, TensorFlow (SavedModel/pb), and others are labeled experimental — results may be incomplete or incorrect for complex models.
- Version v9.x current as of May 2026: check https://github.com/lutzroeder/netron/releases for latest.

## Links

- GitHub: https://github.com/lutzroeder/netron
- Browser version: https://netron.app
- Releases: https://github.com/lutzroeder/netron/releases/latest
