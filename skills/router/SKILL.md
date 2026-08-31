---
name: router
description: Show GrokRouter status, help, health, or reset the provider thread.
argument-hint: "[status|help|doctor|reset]"
user-invocable: true
disable-model-invocation: true
metadata:
  author: Prompt Advisers
  short-description: GrokRouter status, help, Doctor, or reset
---

# GrokRouter control plane

GROKROUTER_NATIVE_CONTROL: ROUTER

Use this only through its `/router` slash entry. Preserve the literal invocation and subcommand. GrokRouter intercepts the command before model inference and returns the authoritative result.
