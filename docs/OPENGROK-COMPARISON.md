# OpenGrok comparison

Research lock: 2026-08-29. Upstream: [`OnlyTerp/opengrok`](https://github.com/OnlyTerp/opengrok), commit `2b356649cfe59b30afdbe00bae22591877d5f61e`.

## What OpenGrok gets right

OpenGrok presents the user journey clearly: clone, run `python setup.py`, choose models in a picker, and use `doctor.py` to identify broken files or services. Its current-only compatibility gate, health baselines, explicit failure catalog, and reminder that a direct hop probe is not proof of end-to-end routing are strong patterns. This project adopts that product discipline:

- one primary installer instead of a manual patch recipe;
- a redacted `/router doctor` receipt;
- exact host/version/hash gates that fail closed;
- a visible fresh-Bot acceptance procedure that proves the installed artifact, not merely its endpoint;
- deterministic model controls plus user-invocable descriptors that make the real commands eligible for Grok's native slash menu;
- rollback as a first-class user action.

## Why its smaller patch cannot be copied here

OpenGrok's cloud-host patch is anchored to a host that already contains an OpenAI-hop seam, including `createOpenAiHopSession`, `resolvedTopLevelModelId`, and `resolvedOpenaiBaseUrl`. Its patch adds a binding consumer and forwards configuration into that existing session.

The exact verified stock host used by this project—official Grok Bot 0.30.0 on the test Bot computer—contains none of those symbols and no `model-bindings.json` consumer. Applying OpenGrok's patch would therefore fail its own source anchors rather than create a working route. The compatible narrow seam here is one version-gated host executor that launches the external adapter. The larger provider, state, tool-conversion, audit, and recovery logic remains outside Grok's proprietary host.

That is more adapter code than OpenGrok's binding map, but it is not a Grok rewrite. Moving this logic into the host would make the patch riskier, less reversible, and harder to test.

## Capability-status difference

OpenGrok's README currently labels OpenRouter as “pattern proven, capture pending.” Its own cloud-host guide also separates picker/direct-hop success from proof that a normal Grok chat was actually routed.

This repository now has beta.38 live normal-chat proof from a genuinely new Bot for automatic greeting, doctor, catalog, bare-model selection, state persistence across host requests, routed model identity, exact-once text delivery, and second-Bot isolation. The exact artifact also completed install → verified stock restore → reinstall. The original screenshot failure was not missing slash parsing: a changing per-turn request ID was being combined with the stable Bot ID, so the next message read a different state file and silently fell back to Claude. Stable Bot/conversation identity is now authoritative.

Full OpenRouter tool parity remains a separate blocker. On the latest explicit Shell gate (beta.32), the Grok host advertised zero actionable native tool schemas. The adapter correctly refused to turn model-authored pseudo Shell markup into a privileged host call. Beta.33–beta.38 changed installer/restore reliability and version receipts, not that capability boundary. The model-switching/new-Bot video path is evidenced; computer and sub-agent claims must remain out of the recording until Grok actually offers those schemas and the full gate passes.

## Product decision

Keep the simpler upstream experience, not its incompatible patch:

1. The user installs one Mac app.
2. A new Bot runs `/router doctor` and selects a model from `/models`.
3. The recording/build is accepted only after text, state isolation, Shell resume, Screenshot, returned child result, audit receipts, and restore all pass.
4. Future Grok versions get a new compatibility manifest only after their exact host seam is inspected and live-tested.

This is the smallest design that matches the stock host actually installed on this Mac and the claims intended for the video.
