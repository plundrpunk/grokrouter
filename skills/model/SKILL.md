---
name: model
description: Show or switch the model for the current GrokRouter Bot.
argument-hint: "[model-id]"
user-invocable: true
disable-model-invocation: true
metadata:
  author: Prompt Advisers
  short-description: Show or switch this Bot's model
---

# GrokRouter model control

GROKROUTER_NATIVE_COMMAND: /model

Use this only through its `/model` slash entry. Preserve the literal invocation and model ID argument. GrokRouter intercepts the command before model inference and returns the authoritative receipt.
