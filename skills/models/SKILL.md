---
name: models
description: List configured models or switch the current GrokRouter Bot to a model ID.
argument-hint: "[vendor/model]"
user-invocable: true
disable-model-invocation: true
metadata:
  author: GrokRouter
  short-description: List models or switch this Bot
---

# GrokRouter model catalog

GROKROUTER_NATIVE_CONTROL: MODELS

Use this only through its `/models` slash entry. Preserve the literal invocation and any model ID argument. GrokRouter intercepts the command before model inference and returns the authoritative catalog or switch receipt.
