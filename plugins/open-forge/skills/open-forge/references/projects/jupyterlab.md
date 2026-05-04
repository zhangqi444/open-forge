# JupyterLab

Next-generation interactive computing environment for data science, scientific computing, and machine learning. Successor to Jupyter Notebook — provides notebooks, a terminal, code editor, file browser, and rich output all in one extensible web UI. BSD 3-Clause. 15K+ GitHub stars. Upstream: <https://github.com/jupyterlab/jupyterlab>. Docs: <https://jupyterlab.readthedocs.io>.

Self-hosting JupyterLab is done via the official **Jupyter Docker Stacks** — a set of maintained images on Quay.io. The server runs on port `8888` and exposes a token-secured web UI.

## Compatible install methods

Verified against upstream docs at <https://jupyter-docker-stacks.readthedocs.io>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (Jupyter Docker Stacks) | `docker run quay.io/jupyter/scipy-notebook` | ✅ | Standard self-hosted path. Multiple image flavors. |
| Docker Compose | See below | ✅ | Persistent data + easier config. |
| pip | `pip install jupyterlab && jupyter lab` | ✅ | Local dev on existing Python env. |
| conda | `conda install -c conda-forge jupyterlab` | ✅ | Python env with conda. |
| JupyterHub | <https://jupyter.org/hub> | ✅ | Multi-user deployment for teams. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| notebook_dir | "Host directory for notebooks/data (e.g. `/data/notebooks`)?" | Path | All |
| token | "Access token to secure the server? (leave blank to generate random)" | Free-text (sensitive) | Production |
| image_flavor | "Which stack image? (minimal/scipy/datascience/tensorflow/pytorch)" | Choice | Docker |

## Software-layer concerns

### Image flavors (Jupyter Docker Stacks)

All images at `quay.io/jupyter/<name>:latest`. Use a date-pinned tag for reproducibility (e.g. `:2025-12-31`).

| Image | Contents | Use case |
|---|---|---|
| `base-notebook` | Jupyter Server + JupyterLab only | Minimal — extend this |
| `minimal-notebook` | Base + git, vi, nano, tzdata | Basic notebooks |
| `scipy-notebook` | Minimal + NumPy, Pandas, Matplotlib, SciPy, Seaborn | Data science (most popular) |
| `datascience-notebook` | scipy + R kernel + Julia kernel | Multi-language science |
| `tensorflow-notebook` | scipy + TensorFlow | Deep learning with TF |
| `pytorch-notebook` | scipy + PyTorch | Deep learning with PyTorch |
| `pyspark-notebook` | scipy + Apache Spark | Big data |
| `all-spark-notebook` | pyspark + R + Scala kernels | Full Spark ecosystem |

Image hierarchy: `base` → `minimal` → `scipy` → `datascience/tensorflow/pytorch/pyspark`

### Docker Compose

```yaml
services:
  jupyterlab:
    image: quay.io/jupyter/scipy-notebook:latest
    ports:
      - "8888:8888"
    environment:
      - JUPYTER_ENABLE_LAB=yes
      - JUPYTER_TOKEN=your-secure-token-here
      # Or: JUPYTER_TOKEN="" for no token (not recommended for production)
    volumes:
      - ./notebooks:/home/jovyan/work
    restart: unless-stopped
    user: root                          # optional: run as root to install system packages
    # environment (root mode):
    #   GRANT_SUDO: "yes"
    #   NB_USER: "jovyan"
    #   CHOWN_HOME: "yes"
```

Access: `http://localhost:8888/?token=your-secure-token-here`

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `JUPYTER_TOKEN` | Token required to access the server | Random (printed on startup) |
| `JUPYTER_ENABLE_LAB` | Force JupyterLab UI (not classic Notebook) | `yes` in recent images |
| `NB_USER` | Default notebook user | `jovyan` |
| `NB_UID` | UID for `jovyan` — match to host user to avoid permission issues | `1000` |
| `NB_GID` | GID for `jovyan` | `100` |
| `GRANT_SUDO` | Give `jovyan` passwordless sudo (requires `user: root`) | `""` |
| `CHOWN_HOME` | Chown home dir to `NB_USER:NB_GID` on startup | `""` |
| `CHOWN_EXTRA` | Extra dirs to chown | `""` |
| `DOCKER_STACKS_JUPYTER_CMD` | Override startup command (`lab`, `notebook`, `server`) | `lab` |
| `RESTARTABLE` | Auto-restart kernel on crash | `""` |

### File permissions

The container default user is `jovyan` (UID 1000). When mounting host volumes:

```bash
# Option 1: Set NB_UID to match your host user
docker run -e NB_UID=$(id -u) -e NB_GID=$(id -g) -v ./notebooks:/home/jovyan/work \
  quay.io/jupyter/scipy-notebook

# Option 2: Run as root with GRANT_SUDO
docker run --user root -e GRANT_SUDO=yes -e NB_USER=jovyan \
  quay.io/jupyter/scipy-notebook
```

### Adding packages

**Temporary (inside container):**
```python
# In a notebook cell:
import subprocess
subprocess.run(["pip", "install", "package-name"])
```

**Persistent (custom Dockerfile):**
```dockerfile
FROM quay.io/jupyter/scipy-notebook:latest
RUN pip install --no-cache-dir \
    transformers \
    datasets \
    langchain
```

**Conda packages:**
```dockerfile
FROM quay.io/jupyter/scipy-notebook:latest
RUN conda install --quiet --yes \
    'biopython=1.79' && \
    conda clean --all -f -y
```

### Password-based auth (alternative to token)

```bash
# Generate hashed password
docker run --rm quay.io/jupyter/base-notebook \
  python -c "from jupyter_server.auth import passwd; print(passwd('mypassword'))"

# Use in config or env:
# JUPYTER_ENABLE_LAB=yes
# jupyter_server_config.py: c.ServerApp.password = 'argon2:...'
```

### JupyterHub (multi-user)

For teams, deploy JupyterHub to spawn individual JupyterLab servers per user:

```bash
docker pull quay.io/jupyterhub/jupyterhub:latest
```

See: <https://jupyterhub.readthedocs.io/en/stable/howto/configuration/config-docker.html>

### Data directories

| Path | Contents |
|---|---|
| `/home/jovyan/work` | Default work directory — mount notebooks/data here |
| `/home/jovyan/.jupyter` | Jupyter config files |
| `/opt/conda` | Conda environment (do not mount — image-internal) |

## Upgrade procedure

```bash
docker pull quay.io/jupyter/scipy-notebook:latest
docker compose up -d
```

For reproducible upgrades, pin to a date tag and test before switching:

```bash
# Pin to a specific date tag
image: quay.io/jupyter/scipy-notebook:2026-01-15
```

Notebooks and data are preserved in the mounted volume. No database migrations.

## Gotchas

- **Token is required for security.** If `JUPYTER_TOKEN` is not set, a random token is printed to container logs on first start — check `docker compose logs jupyterlab` to retrieve it. Without a token, the server is open to anyone who can reach port 8888.
- **Images are large.** `scipy-notebook` is ~3 GB compressed; `datascience-notebook` with R + Julia is ~5+ GB. First pull is slow.
- **UID mismatch breaks file permissions.** If mounted notebooks show as owned by wrong user, set `NB_UID=$(id -u)` to match your host user.
- **Images moved from Docker Hub to Quay.io (2023-10-20).** Older `jupyter/scipy-notebook` tags on Docker Hub are no longer updated. Use `quay.io/jupyter/scipy-notebook`.
- **JupyterLab 4 is current.** JupyterLab 3 reached end of maintenance on 2024-12-31. Use 4.x images.
- **Not a multi-user server by itself.** A single JupyterLab container serves one user. For teams, use JupyterHub.
- **HTTPS for production.** JupyterLab over plain HTTP leaks your token and notebook content. Place behind a TLS-terminating reverse proxy.
- **Kernel state is in-memory.** Restarting the container kills all running kernels. Outputs already saved to `.ipynb` files persist (if volume-mounted), but unsaved state is lost.
- **GPU support.** For CUDA/GPU access: use `pytorch-notebook` or `tensorflow-notebook` and pass `--gpus all` to Docker (requires nvidia-container-toolkit on host).

## Links

- Upstream: <https://github.com/jupyterlab/jupyterlab>
- Docs: <https://jupyterlab.readthedocs.io>
- Docker Stacks docs: <https://jupyter-docker-stacks.readthedocs.io>
- Docker Stacks repo: <https://github.com/jupyter/docker-stacks>
- Image selection guide: <https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html>
- JupyterHub (multi-user): <https://jupyterhub.readthedocs.io>
- Quay.io org: <https://quay.io/organization/jupyter>
