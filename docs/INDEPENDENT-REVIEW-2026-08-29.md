# Independent Claude Code review, 2026-08-29

## Method

The first beta.9 review used the installed Claude Code CLI as a restricted, read-only fallback after Claude Desktop stalled during plugin/MCP startup. It ran Fable 5 at maximum effort with safe/restricted permissions, strict MCP configuration, no session persistence, and only Read/Glob/Grep/Bash tools.

After the beta.10 live gate, Claude Desktop Code mode was run again on this repository with Fable 5 and maximum effort. It received the redacted live failure sequence and inspected the beta.10 adapter. This time it completed the review and reproduced both failure mechanisms without changing repository files. Findings were treated as hypotheses until the local runtime tests reproduced them.

## Release blockers

| Finding | Beta.9 disposition | Evidence |
| --- | --- | --- |
| Replaying one `sandAutomationCompletionId` could call the provider repeatedly because automation continuations bypassed the completed-turn fingerprint. | Fixed. A durable signature combines the completion ID with later non-delivery tool-result IDs. It is claimed under the per-Bot lock before inference, released on error, and persisted after success. | Runtime tests replay the exact transcript, replay it with an ordinary hidden nudge, and issue two concurrent calls. Concurrent replays produce one provider request. |
| A late delivery receipt for the earlier launch acknowledgement could suppress child revival. | Fixed. A receipt counts only when its originating delivery call occurred after the latest user/completion boundary. | Runtime regression covers query, launch send, completion, then late launch receipt; revival remains open until the child-result send receipt. |
| Capitalized and near-miss controls could leak to the model and trigger invented denials. | Fixed. Controls normalize case/whitespace and deterministically catch unsupported provider/router/model/reasoning commands plus unlisted bare model IDs. | Fresh-Bot tests cover `/Provider`, `/Router   Doctor`, `/router foo`, `/provider open router`, `/reasoning MAX`, and `unlisted/model-id` with an inference function that must never run. |

## Before-filming findings

| Finding | Beta.9 disposition |
| --- | --- |
| Whole-state writes under a write-only lock could revert a provider/model switch. | Fixed. Targeted mutations now re-read and merge under the per-Bot lock; late Codex thread IDs still require the provider/model to match. |
| Codex did not clean ordinary hidden messages or tagged completions like OpenRouter. | Fixed. Codex filters ordinary hidden nudges and converts a tagged completion to a clean `Grok background task completed:` transcript entry. |
| The Mac installer left Grok running with loopback diagnostic port 19222. | Fixed. Every installer operation now closes the temporary diagnostic session and relaunches Grok normally on success or failure. |
| Raw provider errors could reach stdout/host logs. | Fixed. User-facing runner errors are bounded and redact recognizable API, GitHub, and OpenRouter key shapes. |
| `/models` could retain obsolete entries such as `openai/gpt-5.2` from an older remote config. | Fixed. Install/upgrade copies the packaged catalog while preserving active selections unless explicit installer flags override them. |
| The normal user-turn fingerprint is fragile compared with a host request ID. | Partially mitigated. Completion replay now uses Grok's durable completion/tool IDs. Normal text still uses its existing fingerprint fallback; adopting a stable host request ID everywhere remains a later compatibility change. |

## Additional hardening

| Finding | Disposition |
| --- | --- |
| Compatibility manifest said V11 while the patch was V15. | Fixed in beta.9; beta.11 now uses V16 consistently. |
| Unused `shellQuote` method. | Removed. |
| Child stdin `EPIPE` and timeout escalation. | Fixed. Expected `EPIPE` is ignored; timeout sends `SIGTERM` and then `SIGKILL`. |
| Timestamped host and runtime backups could grow without bound. | Fixed. Retain four host snapshots and two previous runtime directories. The verified stock backup is separate and never pruned. |
| OpenRouter assistant content could be `null`. | Already guarded. Null text is allowed only when valid tool calls exist; an otherwise empty completion is rejected. |
| Running `install.sh` with no provider flags reset provider/model defaults. | Fixed for provider/model/provider-list preservation. Executing the installer intentionally enables routing; use `grokbot-router disable` when bypass is desired. |
| `open -na` could start a second Grok process if termination was slow. | Fixed. The installer waits, then force-terminates if needed, before relaunching. |
| Host `getModelId()` reports the configured default rather than a later per-Bot override. | Deferred. `/provider`, `/models`, the routed system context, state, and audit are authoritative per Bot. Changing synchronous host metadata would require a larger host seam and is not needed for the fresh-Bot acceptance path. |

## Beta.10 live-failure re-review

| Claude finding | Beta.11 disposition | Local evidence |
| --- | --- | --- |
| Assistant-visible status text between an outstanding tool call and its result could make delivery detection suppress the resumed turn. This matches the live Shell audit ending immediately after the first call. | Delivery detection now tracks outstanding call IDs in transcript order. Assistant text, reasoning, and permission UI do not settle a pending call. | Regression inserts a permission-bubble assistant message before the Shell result and proves one provider resume. |
| Several host wrapper variants were not normalized: snake-case types, single-object calls/results, string results, orphan results, and dangling calls. | Normalize supported variants, drop orphan results, synthesize a bounded result for dangling calls, and remove empty assistant messages before OpenRouter. | Conversion/sanitization tests cover snake-case, orphan, dangling, and string-result shapes. |
| Early returns had no audit receipt, so a host suppression and a missing provider continuation looked identical. | Every early suppression writes `turn_suppressed` with a bounded reason and non-secret tool/completion IDs. | Runtime paths share one suppression writer; the live beta.11 gate must verify real receipts. |
| OpenRouter can return an empty completion on a continuation it considers already acknowledged. The runtime threw immediately, losing a tagged child completion. | Retry an empty response once. On tagged background revival, return the exact child completion text deterministically if the retry is also empty. Ordinary empty responses still fail. | Empty-child regression records two upstream attempts and one returned completion. |
| Completion latches had no expiry and ran before controls; a late Codex result could also restore a reset thread. | Completion fingerprints expire, controls run first, reset clears the latch, and thread epochs reject late writes after reset/switch. | TTL/control-order and late-Codex-reset tests pass. |
| Provider tool IDs and the full host environment crossed the adapter boundary. | Replace tool IDs with `grokbot-router-tool-<uuid>` and launch the child with an explicit environment allowlist. | Contract and installer/patch tests assert the generated ID prefix and allowlist helper. |

## Smaller findings from the full review

These are recorded rather than silently treated as closed:

| Finding | Current disposition |
| --- | --- |
| Tool-link lookup expires after 24 hours and link/state files are not globally garbage-collected. | Not a fresh-Bot or filming-path blocker. Router-owned UUIDs remove the cross-conversation collision risk. A later maintenance release should add conservative age-based link cleanup without deleting active Bot state. |
| Stale-lock recovery uses stat then remove without an owner token. | Deferred hardening. The lock protects only short local state-file mutations, not provider calls; a two-minute stale threshold makes live overlap unlikely. An atomic rename-to-tombstone recovery can replace it later. |
| A runtime failure during a delivery-receipt invocation could show an error after a correct answer. | The normal receipt path is detected and suppressed before provider inference. The exact beta.11 live audit must still prove this on the installed host. |
| Multiple parallel visual tool results can interleave a user image message before every tool result is present. | Deferred. OpenRouter is explicitly requested with `parallel_tool_calls: false`, and the acceptance path uses one visual call. If parallel calls are enabled later, visual follow-ups must be buffered until the result batch is complete. |
| Provider text accompanying a tool call is not shown. | Intentional for this adapter. Showing it before the tool result recreates the status-text/permission suppression class; the final text after the completed tool round is authoritative. |
| The repository should be frozen, committed, CI-tested, Developer-ID signed, and notarized before filming a distributable release. | Still required for release. The current artifact is an ad-hoc-signed local acceptance candidate. Commit, push, release signing, and publication require separate user authorization. |

## Architecture conclusion

The review agreed with the current boundary: keep the provider runtime out of Grok's proprietary host and inject only a small, exact-version-gated executor. The durable IDs already present in Grok and this adapter should remain the source of truth for delivery and replay control.

Automated closure did not replace the live gate. The exact beta.10 artifact passed cleanup, doctor, catalog, command handling, bare-model switching, routed identity, exact-text single delivery, CLI discovery, screenshot, and second-Bot isolation. It failed when a Shell permission receipt did not resume the parent and when the dynamic path ended on an empty OpenRouter continuation without returning the child result.

Beta.11 implemented the smallest reproduced fixes and passed the local contract suite. Its exact installed artifact then exposed one additional cold-start blocker: a brand-new Bot's automatic greeting had no visible user query, received all outer tools, entered dynamic-tool discovery, and ended on the empty-response error before the user typed anything. Doctor and a later exact-text turn passed, but the candidate correctly failed.

Beta.12 passed its automatic greeting and fresh-Bot control/text checks, then failed on one printed dynamic/Shell dialect. Beta.13 exposed a second dialect; beta.14 exposed a third. Beta.15–beta.25 traced the installer failures through terminal launch, viewport/framebuffer geometry, nested input delivery, and cross-renderer text. The final installer uses the live noVNC RFB controller for pointer, keys, and text and fails closed before payload transfer when the terminal cannot be verified.

Beta.32 closes the original new-Bot model-switch failure. Live audit showed the switch and following prompt used different state files because the stable Bot ID had been combined with a changing request ID. Stable Bot/conversation identity now outranks turn-scoped IDs. The exact installed artifact passed new-Bot greeting, doctor, model catalog, bare Luna selection, provider/model identity on the following normal turn, exact-once text, and second-Bot isolation.

Beta.33–beta.38 then closed the restore/reinstall failures exposed by the final cycle: paced RFB typing, dirty-prompt cancellation, persistent stock-backup storage, a second exact anchor-verified 0.30.0 stock hash, reuse-before-open VNC discovery, accurate preview OCR, and a restore sentinel emitted before delayed host restart. The exact beta.38 artifact completed install → verified stock restore → reinstall, then passed new-Bot doctor, Luna selection, next-turn model identity, exact-once text, and second-Bot isolation.

The review does not mark full capability parity complete. During the latest explicit Shell gate, beta.32 received zero actionable host tools, so the guarded adapter correctly refused to execute the model's printed pseudo Shell markup. Screenshot and returned-child tests were not rerun after that prerequisite failed. The evidence supports filming the deterministic install/model-switch/new-Bot/restore path, but not claiming current OpenRouter computer or sub-agent parity.
