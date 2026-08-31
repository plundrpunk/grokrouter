---
name: reasoning
description: Show or change the reasoning effort for the current GrokRouter Bot.
argument-hint: "[minimal|low|medium|high|xhigh]"
user-invocable: true
disable-model-invocation: true
metadata:
  author: Prompt Advisers
  short-description: Change this Bot's reasoning effort
---

# GrokRouter reasoning control

GROKROUTER_NATIVE_CONTROL: REASONING

Use this only through its `/reasoning` slash entry. Preserve the literal invocation and effort argument. GrokRouter intercepts the command before model inference and returns the authoritative receipt.
