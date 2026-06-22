---
name: Bug report
about: Something isn't working
title: "[bug] "
labels: bug
---

## Describe the bug

A clear, concise description of what's wrong.

## To reproduce

Steps:
1. …
2. …

## Expected behavior

What you expected to happen.

## Diagnostics

```
# paste the output of:
make ps
make logs s=<service>   # the one that's failing (n8n | postgres | ollama | open-webui)
```

## Environment

- OS:
- Docker / Compose version:
- CPU or GPU (model):
- Models in use (`OLLAMA_MODELS`):
- Commit / version:

> ⚠️ Redact secrets, tokens, and anything from `.env`.
