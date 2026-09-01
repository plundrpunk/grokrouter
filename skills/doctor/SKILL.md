---
name: doctor
description: Check GrokRouter runtime, provider, credential, and tool-bridge health.
user-invocable: true
disable-model-invocation: true
metadata:
  author: GrokRouter
  short-description: Check GrokRouter health
---

# GrokRouter Doctor

GROKROUTER_NATIVE_CONTROL: DOCTOR

Use this only through its `/doctor` slash entry. Preserve the literal invocation. GrokRouter intercepts the command before model inference and returns the same authoritative health receipt as `/router doctor`.
