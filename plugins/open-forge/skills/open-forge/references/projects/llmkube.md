# LLMKube

**Kubernetes operator for self-hosted LLM inference** — deploy llama.cpp-native models on Kubernetes with GPU scheduling, OpenAI-compatible API, Apple Silicon Metal support via an optional metal-agent, and a model catalog for one-command deployments.

**Official site:** https://llmkube.com
**Source:** https://github.com/defilantech/LLMKube
**License:** Apache-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Kubernetes cluster | Helm | Primary deployment path |
| Apple Silicon host | metal-agent binary | Out-of-cluster agent for Mac Metal GPU nodes |
| Minikube (local) | Helm | Good for development/testing |

---

## Inputs to Collect

### Phase 1 — Planning
- Kubernetes cluster type (cloud managed, bare metal, Minikube, OpenShift)
- GPU availability and type (NVIDIA, AMD, Apple Silicon Metal)
- Model(s) to deploy (GGUF format from HuggingFace or custom URL)
- Whether any Apple Silicon hosts need to be included (requires metal-agent)

### Phase 2 — Deploy
- Helm chart values (resource limits, GPU count, namespace)
- Model source URL or catalog name
- Namespace for llmkube-system

---

## Software-Layer Concerns

- **Custom Resources:** `Model` and `InferenceService` CRDs; define model source + inference config as YAML
- **Runtime backends:** llama.cpp, vLLM, TGI — operator selects based on model/config
- **Model storage:** Operator downloads and caches models in cluster persistent storage
- **OpenAI-compatible API:** Exposes `/v1/chat/completions` and compatible endpoints; works with OpenAI Python/Node/Go SDKs, LangChain, LlamaIndex
- **Metal agent:** Optional out-of-cluster process for Apple Silicon hosts; registers Endpoints back into the cluster for GPU-accelerated Mac nodes
- **CLI:** `llmkube` CLI for convenient deployment from catalog; plain `kubectl apply` also works

---

## Deployment

```bash
# Add Helm repo and install operator
helm repo add llmkube https://defilantech.github.io/LLMKube
helm install llmkube llmkube/llmkube \
  --namespace llmkube-system \
  --create-namespace

# Deploy a model from catalog (CLI)
llmkube deploy phi-4-mini

# Or with GPU acceleration
llmkube deploy llama-3.1-8b --gpu --gpu-count 1

# Query the model
kubectl port-forward svc/phi-4-mini 8080:8080 &
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello!"}],"max_tokens":100}'
```

Plain kubectl (no CLI):
```yaml
apiVersion: inference.llmkube.dev/v1alpha1
kind: Model
metadata:
  name: tinyllama
spec:
  source: https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
  format: gguf
---
apiVersion: inference.llmkube.dev/v1alpha1
kind: InferenceService
metadata:
  name: tinyllama
spec:
  modelRef: tinyllama
  replicas: 1
  resources:
    cpu: "500m"
```

---

## Upgrade Procedure

```bash
helm repo update llmkube
helm upgrade llmkube llmkube/llmkube --namespace llmkube-system
```

---

## Gotchas

- **Kubernetes required** — not for single-machine deployments; use Ollama or llama.cpp directly for simpler setups
- **Apple Silicon support requires metal-agent** — the in-cluster controller alone cannot schedule work on Mac Metal GPUs; metal-agent must run on the Mac host
- **Model download time** — large GGUF models (7B+) can take minutes to download and cache on first deploy
- **Early-stage project** — active development (v0.7.x); API/CRD schemas may change between releases
- **Air-gapped deployments** — supported; see upstream air-gapped quickstart guide

---

## Links

- Upstream README: https://github.com/defilantech/LLMKube#readme
- Minikube quickstart: https://github.com/defilantech/LLMKube/blob/main/docs/minikube-quickstart.md
- GPU setup guide: https://github.com/defilantech/LLMKube/blob/main/docs/gpu-setup-guide.md
- Air-gapped deployment: https://github.com/defilantech/LLMKube/blob/main/docs/air-gapped-quickstart.md
- Discord: https://discord.gg/Ktz85RFHDv
