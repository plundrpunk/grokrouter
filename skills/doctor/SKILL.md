---
name: doctor
description: Check GrokRouter runtime, provider, credential, and tool-bridge health.
user-invocable: true
disable-model-invocation: true
metadata:
  author: Prompt Advisers
  short-description: Check GrokRouter health
---

# GrokRouter Doctor

Use this only through its `/doctor` slash entry. Preserve the literal invocation. GrokRouter intercepts the command before model inference and returns the same authoritative health receipt as `/router doctor`.
