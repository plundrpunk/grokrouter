# Verification matrix

Research/build lock: 2026-08-30. Grok Bot: 0.30.0. Router candidate: 0.1.0-beta.39.

| Claim | Automated evidence | Live evidence | Status |
| --- | --- | --- | --- |
| Runtime parses real-shaped Grok messages | Node unit tests | Prototype conversation | Pass |
| OpenRouter function calls retain tool names, IDs, and arguments | Mock HTTP contract test | Previous prototype | Pass; rerun on release adapter |
| Image/tool-result conversion | Unit test with PNG tool output | Codex called outer `Screenshot` and identified the Terminal window | Pass |
| Codex structured outer-tool request | Fake SDK contract test | Same Codex thread called outer `Shell`, then `Read`, then returned the final response | Pass |
| Per-Bot provider/model state isolation | Two-Bot state test plus merge-under-lock writes; stable Bot identity outranks changing turn request IDs | Beta.38 kept Luna across normal turns in the first new Bot; a second new Bot started on installer-default Claude | Pass on beta.38 |
| Fresh-Bot forgiving model controls | Unit test proves exact, capitalized, whitespace, invalid-command, listed, and unlisted model inputs never reach inference | Beta.38 passed greeting, doctor, bare Luna switch, provider status, and a following normal inference in a genuinely new Bot after restore/reinstall | Pass on beta.38 |
| Single delivery after visible assistant response | Unit tests block a second inference and remove tools from exact-text OpenRouter requests | Beta.38 returned one settled `BETA38_FRESH_TEXT_OK` reply with no markup or duplicate | Pass on beta.38 |
| Routed model knows provider/model controls | OpenRouter request and Codex prompt contract tests | Beta.38 Luna returned `Provider=OpenRouter; Model=openai/gpt-5.6-luna` on the turn after the switch | Pass on beta.38 |
| Patch refuses unknown host | Python test | Version gate on the verified test app | Pass |
| Patch is idempotent and reversible | Python install/doctor/restore test | Exact stock SHA-256 restored and verified repeatedly during clean-room cycles | Pass |
| Full payload installs pinned SDK and management CLI | Synthetic end-to-end install | Fresh official Grok Bot 0.30.0 install completed with Codex CLI/SDK 0.151.0 | Pass |
| Native Mac installer compiles for macOS 12+ | Swift typecheck/build/code-sign verification | UI inspected on the verified test Mac | Pass |
| Windows x64 and Arm64 installers package the same guarded delivery flow | PE architecture checks, JavaScript syntax/safety suite, offline OCR/payload presence, archive checksums, and mandatory Authenticode release gate | No Windows install/restore/fresh-Bot run yet | Preview; live Windows gate required |
| Installer survives a Grok computer reconnect | Swift regression checks for chunked transfer and encoded output markers | Live reconnect occurred; installer retried and completed | Pass |
| Installer reports success across host restart | Delayed-restart shell check; transport and encoded install-marker checks | Repeated reinstall exposed a redundant acknowledgement race; after removing it, the same live reinstall completed with `Installed with OpenRouter selected` and no false retry | Pass |
| Verified stock restore and reinstall | Persistent stock-backup path, exact-hash/anchor gate, prompt reset, paced RFB transfer, stable VNC reuse, accurate OCR, and pre-restart restore sentinel assertions | Exact beta.38 installed, restored stock with an authoritative success receipt, reinstalled with OpenRouter selected, and passed a new-Bot doctor | Pass on beta.38 |
| Recovery after Grok replaces the live host | Exact-gated repair command, persistent watchdog, rate limit, XDG autostart, explicit Repair action, and bounded JPEG diagnostic screenshots | Exact beta.39 reinstalled on the replacement host; a post-install new Bot reported beta.39 and OpenRouter Claude; installer Doctor completed without the former `Message too long` failure; one-click Repair completed and `/provider` still passed after its host restart | Explicit recovery pass on beta.39; automatic future replacement still needs a live trigger |
| Codex device authorization | Pinned CLI is installed by synthetic payload test | Codex 0.151.0 displayed `Successfully logged in` | Pass |
| Codex text response through Grok chat | Runtime contract test | Returned exactly `CODEX_CLEAN_ROOM_OK` | Pass |
| Codex uses Grok computer tool | Structured adapter test | Outer `Shell` created the proof file; outer `Read` returned `COMPUTER_TOOL_OK`; audit confirms both calls | Pass |
| Codex uses Grok screenshot tool | Multimodal tool-result test | Outer `Screenshot` returned `SCREENSHOT_OK: Terminal`; audit confirms the call | Pass |
| Codex uses Grok sub-agent tool | Generic schema bridge test | `GetDynamicTools` -> `CallDynamicTool` -> separate child execution -> `SUBAGENT_PARITY_OK` | Pass |
| OpenRouter rejects placeholder credentials | Invalid-key unit test and installer guard | Recovered 28-character placeholder was identified before replacing it with a valid protected secret | Pass |
| OpenRouter Claude text response | Mock HTTP test | `/router doctor` named `anthropic/claude-sonnet-4.6`; returned exactly `OPENROUTER_CLEAN_ROOM_OK` | Pass |
| OpenRouter uses Grok Shell/Read | Function-call, permission-resume, captured textual-tool dialects, explicit-user-name/schema guards, required-first-round, named-function, and zero-host-schema regressions | On beta.32 the explicit Shell turn advertised zero actionable host tools. Guarded recovery correctly refused the model's printed pseudo-call; Grok never received Shell | Blocked on beta.32: host supplied no Shell schema |
| OpenRouter uses Grok screenshot tool | Multimodal function-call test | Beta.10 Luna called outer `Screenshot` once and correctly described the visible desktop; beta.32 stopped at the preceding zero-host-schema Shell gate | Pass on beta.10 only; beta.32 not reverified |
| OpenRouter uses Grok sub-agent tool | Generic schema bridge plus tagged-completion revival, receipt-ordering, replay, empty-result fallback, concurrent-claim, and printed-tool recovery regressions | Beta.10 reached repeated dynamic rounds but did not return the child; beta.32 stopped at the preceding zero-host-schema Shell gate | Failed on latest completed live path; beta.32 not reverified |

Do not change a Pending row to Pass from code inspection alone. Capture the exact prompt, visible result, router audit event, and provider/model status for each live proof.

## 2026-08-30 beta.39 recovery evidence

- After the beta.38 install/restore/reinstall pass, Grok later presented a new Bot on a stock host while retaining the persistent provider runner and configuration. `/provider` therefore reached stock Grok as ordinary chat, and its ad hoc inspection reported `stock-or-unknown` with no router marker.
- The previous installer Doctor reproduced a separate transport defect: the noVNC target rotated and a large nested PNG screenshot ended with `Message too long`.
- Beta.39 adds a fail-closed watchdog that can repair only an allowlisted stock host through the existing exact hash and source-anchor checks. It rate-limits repeated repairs, persists through XDG desktop autostart, and is disabled by intentional stock restore.
- The exact beta.39 artifact installed with OpenRouter selected on the current host. A genuinely new Bot created afterward greeted normally, returned `Router 0.1.0-beta.39: OK`, reported a valid protected OpenRouter credential, and deterministically returned `anthropic/claude-sonnet-4.6` from `/provider`.
- The beta.39 installer Doctor then completed across a noVNC target rotation using bounded JPEG screenshots. The prior `Message too long` failure did not recur, and diagnostic port 19222 closed afterward.
- The separate **Repair Router** action then returned its authoritative repair sentinel, enabled automatic repair, restarted the host, and the same fresh Bot immediately returned the deterministic OpenRouter Claude `/provider` receipt again.
- Automatic repair is not yet counted as a live lifecycle pass because Grok has not replaced the host again after beta.39 installation. The synthetic repair path and full automated suite pass, but the next real replacement remains the authoritative end-to-end watchdog gate.

## 2026-08-29 beta.7 fresh-Bot evidence

- Installed beta.7 with OpenRouter as the default and preserved the protected credential.
- Created a genuinely new Bot after the installer/host reconnect. `/router doctor` reported beta.7, OpenRouter Claude, Node v20.19.2, a valid-shape protected key, Codex installed, and the structured Grok-tool bridge.
- Switched that Bot with `/models openai/gpt-5.6-luna`; `/provider` confirmed `openai/gpt-5.6-luna`.
- Luna called outer `Shell` exactly once for `pwd`, returned the test machine's home directory, and did not repeat the tool after the result.
- Luna called outer `Screenshot` exactly once and correctly described the visible desktop and dock.
- The dynamic path reached `GetDynamicTools`, `CallDynamicTool`, and `CheckSubagent`, and the child finished. The finished child result did not reach the parent chat. Inspection of the stock 0.30.0 host showed that completions are injected as hidden user messages tagged with `providerOptions.cursor.sandAutomationCompletionId`; beta.7 filtered that message with ordinary internal continuations.
- Created a second genuinely new Bot. `/provider` reported the installer-default Claude model rather than the first Bot's Luna override, proving per-Bot isolation. The normal prompt returned exactly `FRESH_BOT_TEXT_OK` once, with no later duplicate or error.
- Beta.8 added the first tagged-completion path. A read-only adversarial Claude Code review then found replay, late-launch-receipt, and command near-miss blockers before it was installed live.
- Beta.9 added durable sequential/concurrent continuation claims, receipt-origin ordering, deterministic near-miss controls, merge-under-lock state writes, Codex hidden-completion filtering, installer diagnostic cleanup, and a deterministic packaged model catalog.

## 2026-08-29 beta.9 live evidence

- The exact beta.9 installer completed idempotently, preserved the protected OpenRouter key, closed loopback port 19222, and relaunched Grok without diagnostic flags.
- A genuinely new Bot reported beta.9, OpenRouter Claude, Node v20.19.2, a valid credential shape, installed Codex CLI, and the native Grok-tool bridge.
- `/models` contained only the packaged beta.9 catalog; the stale `openai/gpt-5.2` entry was gone. Pasting `openai/gpt-5.6-luna` switched the Bot and `/provider` confirmed it.
- Luna correctly answered that it was using OpenRouter and `openai/gpt-5.6-luna`.
- The next exact-text request did not complete. After about three minutes the audit recorded a `GetDynamicTools` call even though no tool was required, and Grok remained working without a resumed provider turn. Beta.9 therefore failed the fresh-Bot gate.
- The fresh Bot terminal PATH omitted `/home/box/.local/bin`, so the documented short `grokbot-router logs` command failed while the full path worked. `/usr/local/bin` was not user-writable but passwordless `sudo` was available.
- Beta.10 removed outer tool schemas from explicit exact-text OpenRouter requests and installed a second management-CLI link into `/usr/local/bin`. The later live gate passed those two fixes but failed Shell resume and returned-child delivery, documented below.

## 2026-08-29 beta.10 live evidence

- Installed the exact beta.10 artifact, closed the installer diagnostic port, and relaunched Grok normally.
- A genuinely new Bot passed `/router doctor`, the packaged `/models` catalog, a bare Luna model switch, `/provider`, routed provider/model awareness, the exact `FRESH_BOT_TEXT_OK` proof, every command near-miss, and the plural `/models <id>` alias.
- A second genuinely new Bot started on installer-default Claude rather than inheriting Luna. A fresh Bot terminal found `grokbot-router` through `/usr/local/bin`.
- Luna called Grok's outer `Screenshot` exactly once and described the visible desktop correctly.
- Luna called outer `Shell` once. Grok displayed its local-command permission UI and recorded the approval, but the routed parent never resumed. The redacted audit ended after one `turn_ok` containing `Shell`, with no provider continuation.
- The dynamic-tool test entered repeated `GetDynamicTools`/`CallDynamicTool` rounds and then emitted `turn_error: OpenRouter returned an empty response`. No finished child result appeared in the parent chat.
- Beta.10 therefore failed the fresh-Bot capability gate despite passing the text, command, screenshot, CLI, and isolation checks.
- Beta.11 adds unresolved-tool-aware delivery detection, normalized tool-result shapes, complete suppression auditing, sanitized tool-call/result pairing, one empty-completion retry, deterministic background-completion fallback, reset epochs, expiring completion latches, router-owned tool IDs, and a restricted child environment. These changes are automated only until the exact beta.11 artifact passes the live new-Bot gate.

## 2026-08-29 beta.11 live evidence

- Installed the exact beta.11 artifact, preserved the protected provider setup, closed loopback port 19222, and relaunched Grok normally.
- The first Bot created after installation failed before any user prompt: its automatic greeting exposed five outer tools, entered the dynamic-tool path, spawned a worker, and ended with `OpenRouter returned an empty response after one retry`. The generic router error appeared as the Bot's first message.
- `/router doctor` still reported beta.11, healthy OpenRouter/Codex setup, and the native tool bridge. A subsequent exact-text request returned exactly `BETA11_FRESH_TEXT_OK` once in about two seconds.
- The redacted audit and `/tmp/sand-host.log` aligned on the automatic-greeting failure. Beta.11 therefore failed the ultimate brand-new-Bot gate before Shell and returned-child retesting.
- Beta.12 treats a transcript with no visible user query, no tool result, and no tagged automation completion as the automatic greeting path. It withholds outer-tool schemas, instructs the provider to return one short greeting directly, and records host adapter exceptions as bounded `host_bridge_error` audit events. Automated closure does not replace a new beta.12 live Bot.

## 2026-08-29 beta.12 live evidence

- Installed the exact beta.12 artifact, preserved the protected OpenRouter setup, closed the temporary diagnostic port, and created a genuinely new Bot only after installation.
- The automatic greeting was one short normal greeting. `/router doctor`, `/models`, a bare Luna switch, `/provider`, routed model awareness, `BETA12_FRESH_TEXT_OK`, capitalization/whitespace/near-miss controls, the unlisted-ID receipt, and `/models <id>` all passed visibly.
- The first capability prompt asked Luna to use Grok's outer `Shell` exactly once. Instead of returning a native function call, the provider printed repeated `GetDynamicTools` markup, then printed `CallDynamicTool` and `Shell` markup, and finally claimed Shell was unavailable. No local-command permission prompt appeared because Grok never received a native call.
- Beta.12 therefore failed before Screenshot, returned-child, second-Bot, and restore/reinstall retesting. The visible transcript and redacted audit were treated as a hard release blocker rather than a near-pass.
- Beta.13 adds an explicit native-tool-only instruction and a guarded compatibility parser. It converts one printed call only when the exact named tool was offered by Grok, prefers the final actionable `CallDynamicTool`, ignores unoffered names, never overrides a real native call, and records when recovery was used. The full live gate remains pending.

## 2026-08-29 beta.13 live evidence

- Installed the exact beta.13 artifact, preserved the protected credential, closed the diagnostic port, approved the requested global Grok local-command permission, and created a genuinely new Bot after installation.
- The new Bot passed its automatic greeting, beta.13 doctor, model catalog, bare Luna switch, provider status, routed awareness, and a stable single `BETA13_FRESH_TEXT_OK` response.
- The Shell prompt returned a different printed dialect: a JSON text preface, `GetDynamicTools` without a `code:` marker, a direct unoffered `Shell` block, and the expected token in the same visible bubble. Printed markup is a release failure even if a command may have run; it was not counted as a capability pass.
- Beta.14 accepts both captured dialects. It can wrap a printed direct tool through the offered dynamic broker only when a same-response discovery names that exact tool. A mismatched or undiscovered direct name remains inert. The full beta.14 live gate remains pending.

## 2026-08-29 beta.14 live evidence

- The first two installer attempts failed closed during terminal-transport verification before payload transfer because the Bot computer changed and no terminal was focused. Opening the terminal manually before the third attempt allowed the exact beta.14 artifact to install successfully; the diagnostic port closed afterward.
- A genuinely new Bot then passed its automatic greeting, beta.14 doctor, bare Luna switch, provider status, and one stable `BETA14_FRESH_TEXT_OK` response.
- The Shell gate exposed a third dialect: two direct `to=functions.Shell` blocks marked `unknown`, with no `GetDynamicTools` discovery, followed by the expected token in the same visible bubble. That remains a failure because Grok did not receive a clean native call.
- Beta.15 forces a native call with OpenRouter `tool_choice: required` only on the first round of an explicit `use ... tool` request. After a current-turn tool result, it returns to `auto`. Its guarded fallback can broker a direct printed tool without discovery only when the visible user prompt explicitly named that exact tool.

## 2026-08-29 beta.15 installer evidence

- The exact beta.15 app was built and signed, but its live install failed closed before payload transfer when the Ctrl–Alt–T shortcut did not open a guest terminal. Repeating with a computer already open still missed the prompt, proving the manual timing workaround was not turnkey.
- Beta.16 checks the screenshot for a real Terminal/workspace prompt before typing. If the shortcut misses, it clicks the fixed terminal dock icon on the Grok Bot 0.30.0 computer surface, refocuses noVNC, verifies the prompt, and only then sends the isolated transport sentinel.
- Because beta.15 never crossed the verified transport gate, beta.14 remained installed and beta.15 capability behavior was not claimed as live evidence.

## 2026-08-29 beta.16 installer evidence

- After terminating five stale installer processes, one confirmed beta.16 instance exercised the new dock fallback. Its log proved the shortcut miss was detected and the fallback ran, but the terminal still did not open.
- The noVNC target was the small computer-preview webview. Fixed 1040×760 desktop coordinates were being sent directly into that smaller viewport, so both the initial focus click and terminal dock click missed their remote targets.
- Beta.17 maps every remote desktop point through the live noVNC canvas rectangle and intrinsic framebuffer size before dispatching the click. The fixed terminal position remains a property of the pinned Grok Bot 0.30.0 desktop, while the webview can now be preview-sized or full-screen.

## 2026-08-29 beta.17 installer evidence

- One exact beta.17 installer instance failed closed before payload transfer with `The Bot computer canvas could not be mapped for keyboard input.`
- The noVNC target did not expose the expected canvas as a direct descendant, and WebKit did not bridge the JavaScript object result into the Swift dictionary shape the installer required.
- Beta.18 maps against the stable `noVNC_container` rectangle and returns the coordinates as JSON text for explicit decoding in Swift. The installer still refuses to type anything unless it can map the surface and verify a real terminal prompt.

## 2026-08-29 beta.18 installer evidence

- The exact beta.18 artifact again failed closed before payload transfer with `The Bot computer canvas could not be mapped for keyboard input.`
- Direct inspection of the generated JavaScript expression found the immediate cause: `remoteX` and `remoteY` were emitted as JavaScript identifiers instead of Swift-interpolated numeric literals, so evaluation threw before returning its JSON string.
- Beta.19 interpolates both numbers and adds source-level installer assertions for the two expressions. The live gate remains authoritative.

## 2026-08-29 beta.19 installer evidence

- Beta.19 successfully mapped and clicked the noVNC surface, detected that Ctrl–Alt–T missed, and exercised its terminal-dock fallback without manual setup. The terminal did not open, so it again failed closed before payload transfer.
- Fullscreen inspection showed the coordinate-system mistake: Grok Bot's Mac window was 1040×760, but the guest desktop inside it was 1024×640 and began below the app toolbar. Scaling a host-window point into the guest canvas landed about 29 pixels above Terminal.
- Beta.20 reads `noVNC_canvas.width` and `.height` when available, falls back to the observed 1024×640 framebuffer, and targets Terminal at guest point 560×614. Source assertions lock both dimension reads and the pinned dock point.

## 2026-08-29 beta.20 installer evidence

- Beta.20 used guest-framebuffer geometry and reached the same dock point that opened Xfce Terminal during direct UI verification, but its five-second post-click verification window expired first.
- The terminal appeared later at a normal `box@cursor:~/workspace$` prompt without any typed install text, confirming a cold-start timing issue rather than a coordinate or transport error.
- Beta.21 extends only the screenshot-verified dock wait to 12 seconds. It remains fail-closed and will not type until OCR sees both the Terminal window and workspace/box prompt.

## 2026-08-29 beta.21 installer evidence

- Beta.21 still ended on the desktop after exercising both launch paths. The longer dock wait alone did not help.
- The observed sequence explains why: Ctrl–Alt–T can begin a slow terminal launch, the original five-second shortcut check expires, and the subsequent dock click toggles the newly arriving terminal away again.
- Beta.22 gives Ctrl–Alt–T the same 12-second screenshot-verified window before attempting the dock. Only if that full window produces no prompt does the independent dock path run.

## 2026-08-29 beta.22 installer evidence

- Beta.22 gave each launch path its full prompt-verification window, but neither produced a visible terminal when driven through the installer's nested CDP mouse path.
- Direct UI input on the same noVNC canvas could open Terminal, while the nested `Input.dispatchMouseEvent` call returned success without a guest-side effect. The remaining blocker was therefore event delivery, not geometry or startup time.
- Beta.23 dispatches the mapped `mousedown`/`mouseup` pair through noVNC's own canvas listeners, which are responsible for translating browser coordinates into guest pointer events. A missing canvas or rejected event remains an explicit installer failure.

## 2026-08-29 beta.23 installer evidence

- Beta.23's synthetic canvas events still produced no guest-side terminal. Browser event dispatch was not a sufficient substitute for noVNC's live RFB controller in this embedded build.
- Read-only inspection of the exact remote `vnc.html`, `app/ui.js`, and noVNC RFB source showed the supported object graph: the module exports `UI.rfb`, whose `sendKey` and pointer pipeline write directly to the connected VNC socket.
- Beta.24 dynamically imports Grok's pinned `app/ui.js`, requires a live `UI.rfb`, and uses its exact key and pointer methods. This remains version-gated to Grok Bot 0.30.0, and any missing controller fails before payload transfer.

## 2026-08-29 beta.24 installer evidence

- Beta.24 reached and invoked Grok's connected `UI.rfb` object, but the Terminal dock click still landed on the wrong guest point.
- The remaining mismatch was intrinsic versus displayed geometry: noVNC's 1280×800 framebuffer is scaled to a 1024×640 canvas in Grok's fullscreen computer. The visible Terminal center at about 560×614 therefore maps to intrinsic point 700×768.
- Beta.25 pins that intrinsic point and keeps the canvas/framebuffer mapper, so the same guest location is used at any displayed scale.

## 2026-08-29 beta.25 installer evidence

- From a blank guest desktop, beta.25 opened Xfce Terminal automatically and verified the real `box@cursor:~/workspace$` prompt. This closed the terminal-launch blocker.
- Its isolated transport probe then appeared unsent in Grok's chat composer rather than in Terminal. The probe was cleared without sending, and no payload transfer occurred.
- The cause was the remaining Electron `Input.insertText` call. Beta.26 sends command characters and Enter through the already verified live RFB object, eliminating the cross-renderer text path entirely.

## 2026-08-29 beta.26 live evidence

- From a blank desktop and with no manual Terminal setup, the exact beta.26 installer opened Terminal, verified isolated text transport, transferred the SHA-256-checked payload, installed the pinned runtime, observed the authoritative success marker, closed port 19222, and reopened Grok normally with OpenRouter selected.
- A genuinely new Bot created only after that install produced a normal automatic greeting and reported beta.26 in `/router doctor`. `/models`, a bare Luna switch, `/provider`, routed model awareness, and one settled exact-text reply all passed.
- The Shell gate failed visibly. Although the audit showed direct `Shell` among the offered tools, Luna printed three `GetDynamicTools` blocks followed by a `SendToUser` block and the token; `turn_ok` recorded 380 response characters, zero tool calls, and no recovery.
- Beta.27 detects the exact offered tool named in an explicit `use/call/invoke ... tool` request and sends OpenRouter a named function `tool_choice`. Generic `required` remains the fallback only when the user named an unoffered dynamic tool.

## 2026-08-29 beta.32 live evidence

- Built, ad-hoc signed, and installed the exact `0.1.0-beta.32` artifact. ZIP SHA-256: `8ed659c54950557299251e4b688196a0b22b627959ec27d27304e4d01942338f`.
- From a genuinely new Bot created after installation, `/router doctor` reported beta.32, OpenRouter Claude, Node, a valid protected credential, installed Codex CLI, and the Grok tool bridge. `/models` returned the packaged catalog.
- Pasting `openai/gpt-5.6-luna` switched the Bot. `/provider` named Luna, and the following normal inference returned exactly `Provider=OpenRouter; Model=openai/gpt-5.6-luna`. This closes the original screenshot failure: the switch now survives a new host request ID because stable Bot/conversation identity owns the state key.
- The following exact-text request returned one settled `BETA32_FRESH_TEXT_OK` response, with no printed function markup and no duplicate delivery.
- A second genuinely new Bot reported installer-default `anthropic/claude-sonnet-4.6` rather than inheriting Luna, proving per-Bot isolation on the candidate.
- The explicit Shell gate did not receive any actionable outer-tool schemas from the Grok host. The routed model printed pseudo Shell syntax, but the bounded compatibility parser correctly kept it inert because Grok had not offered Shell. There was no native host call in the audit. This is a hard capability blocker, not a near-pass and not a reason to invent permission.
- Screenshot and returned-child tests were not rerun after the zero-host-schema Shell prerequisite failed. The new-Bot model-routing demo path is proven; full OpenRouter computer/sub-agent parity is not proven on beta.32.
- The installer sent a verified stock restore successfully, but the post-restore reinstall exposed burst-truncated RFB text and a stock backup stored in Grok's replaceable live-host directory. Those installer blockers were not counted as a beta.32 pass and led to beta.33–beta.38.

## 2026-08-30 beta.38 final live evidence

- Built and ad-hoc signed the exact `0.1.0-beta.38` artifact. ZIP SHA-256: `4a0f704c96a532d7000459fbf09090d33897e9cbace5c833bf0c4d67fe117235`.
- The final installer paces RFB text in eight-character batches, cancels a dirty shell line before each attempt, reuses an existing VNC target before clicking `Open computer`, performs accurate Vision OCR, and stores the verified stock backup under persistent `sand-data` rather than the replaceable live-host directory.
- A refreshed Grok Bot 0.30.0 stock host had SHA-256 `3364e421402302f8264f961637addb3997a817fde84a91b19635a0c28ff3941f`. A read-only development dry run verified all three required anchors exactly once before that exact hash and size were added to the manifest. No wildcard or unknown-host release path was added.
- The exact beta.38 artifact installed with OpenRouter selected, emitted its authoritative install marker, closed diagnostic port 19222, and relaunched Grok normally.
- The same artifact restored the persistent verified stock backup. Its management CLI emitted `GROKBOT_ROUTER_UNINSTALL_OK` before a delayed host restart, and the installer reported `Restore command sent` instead of losing the marker during the reconnect.
- The same beta.38 artifact then reinstalled from stock with OpenRouter selected and again reported success. This is the completed install → restore → reinstall gate.
- A genuinely new Bot created only after that final reinstall greeted normally and reported `Router 0.1.0-beta.38: OK`, OpenRouter Claude, Node v20.19.2, a valid protected credential shape, installed Codex CLI, and the on-demand Grok tool bridge.
- Pasting `openai/gpt-5.6-luna` switched the Bot. `/provider` named Luna; the following normal inference returned exactly `Provider=OpenRouter; Model=openai/gpt-5.6-luna`; and the next literal request produced one assistant line `BETA38_FRESH_TEXT_OK` with no duplicate or markup.
- A second genuinely new Bot started on installer-default `anthropic/claude-sonnet-4.6`, proving per-Bot isolation on the exact post-cycle candidate.
- Grok's account was already at its 50-Bot cap. To create those final two Bots, two uniquely identified router-test Bots created during this work—the beta.32 and beta.11 transcripts—were permanently deleted. No unverified Bot was touched.
- Full OpenRouter computer/sub-agent parity remains outside this pass. The most recent explicit Shell capability gate was beta.32, where Grok advertised zero actionable host schemas and guarded recovery correctly refused provider-authored pseudo-tool markup.

## 2026-08-29 clean-room evidence

- Removed the previous local Grok Bot app/state into a recoverable backup folder, installed the notarized official 0.30.0 app from scratch, signed in, and confirmed cloud Bots/conversations resynchronized.
- Reinstalled router 0.1.0-beta.2 through the native Mac installer with no Accessibility permission.
- Reproduced a VNC target change during transfer. The final installer used short quote-free chunks, restarted the payload from an empty staging file, and accepted only encoded markers emitted by the remote shell—not marker text visible in a typed command.
- `/router doctor` reported beta.2, Codex SDK `gpt-5.6-sol`, Node v20.19.2, installed CLI, and structured Grok-tool bridging.
- OpenRouter was then enabled with the existing local key through Grok Bot's protected Secrets store. `/router doctor` reported OpenRouter `anthropic/claude-sonnet-4.6`, Node v20.19.2, a configured credential, and native Grok function calls.
- A stale 28-character placeholder from an archived backup produced a 401. The valid local credential was substituted without printing or copying it into the repository. The installer/runtime/doctor now reject or flag malformed key shapes before a network request.
- Live OpenRouter parity passed for exact text, outer `Shell` -> `Read`, outer `Screenshot`, and `GetDynamicTools` -> `CallDynamicTool` with a separate child execution.
- The final idempotent installer retest preserved the OpenRouter selection and protected credential, transferred the payload once, observed the authoritative install marker, and reported success across the host restart.
