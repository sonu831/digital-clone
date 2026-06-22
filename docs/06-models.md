# 06 · Models

Inference is 100% local via **Ollama**. Models are configured in `.env` and pulled
into the `ollama_data` volume.

## Default model roles

| Role     | `.env` key             | Default        | Why                                                  |
| -------- | ---------------------- | -------------- | ---------------------------------------------------- |
| Router   | `OLLAMA_ROUTER_MODEL`  | `llama3:8b`    | Fast, reliable instruction-following + path routing. |
| Analyst  | `OLLAMA_ANALYST_MODEL` | `deepseek-r1:8b` | Stronger reasoning for P&L math & structured debriefs. |

`OLLAMA_MODELS` is the comma-separated list auto-pulled on first boot.

## Swapping a model

```bash
# 1. edit .env
OLLAMA_MODELS=llama3:8b,qwen2.5:14b
OLLAMA_ANALYST_MODEL=qwen2.5:14b
# 2. pull + restart
make pull-models
docker compose restart n8n
```

Inside n8n's Ollama nodes, set **Base URL** to `http://ollama:11434` (service name,
not `localhost`) and the model to your choice.

## Sizing guidance

| Hardware                 | Sensible default        | Notes                                  |
| ------------------------ | ----------------------- | -------------------------------------- |
| 16 GB RAM, CPU-only      | `llama3:8b` (q4)        | Expect multi-second responses.         |
| 32 GB RAM, CPU-only      | 8B–14B models           | Comfortable.                           |
| NVIDIA 8–12 GB VRAM      | 8B models on GPU        | Enable the GPU block (see config doc). |
| NVIDIA 24 GB+ VRAM       | up to ~32B quantized    | Fast, high quality.                    |

`OLLAMA_KEEP_ALIVE` (default `15m`) controls how long a model stays warm in memory
between calls — raise it for snappier responses, lower it to free RAM.

## Testing prompts before going live

Use **Open WebUI** (<http://localhost:8080>) to iterate on the system prompt against
sample `inbound-event` payloads *before* wiring it into the n8n AI Agent. Validate that
guardrails (the `deny` path) fire on trade requests and that numbers are echoed, not
invented.

## Pulling extra models manually

```bash
docker exec digital-clone-ollama ollama pull mistral:7b
docker exec digital-clone-ollama ollama list
```
