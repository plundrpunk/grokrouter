# GrokRouter 0.1.0-beta.39

Host-replacement recovery for Grok Bot 0.30.0.

- Added a persistent, rate-limited watchdog that detects when Grok replaces the live patched host with an allowlisted stock host, reapplies the existing exact hash-and-anchor-gated patch, and restarts the host.
- Added XDG desktop autostart for the watchdog. Intentional stock restore disables and removes it so Restore Stock remains authoritative.
- Added `grokbot-router repair` and a separate **Repair Router** installer action. Unknown hashes and missing anchors still fail closed.
- Doctor now completes its credential sections and emits an explicit completion sentinel even when the host check fails, instead of stopping at the first nonzero patch status.
- Installer OCR screenshots now use bounded JPEG capture, preventing a newly provisioned high-resolution noVNC target from failing with `Message too long`.
- The redesigned macOS app and release archive are now named **GrokRouter**.
- Added matching Windows x64 and Arm64 GrokRouter packages. They use the same loopback/noVNC transport, paced checksummed transfer, protected secret handoff, exact version gate, offline terminal OCR, Doctor, Repair, and verified stock restore. Windows packages remain preview-only until the exact signed artifact passes the live Windows install/restore/fresh-Bot gate.
- The exact beta.39 artifact reinstalled on the replacement host, then passed a genuinely-new-Bot beta.39 doctor and deterministic OpenRouter Claude `/provider` receipt. The installer Doctor also completed across a target rotation without the former message-size failure, and the separate one-click Repair action completed before `/provider` passed again after its restart.
- Exact current local beta.39 `grokrouter-0.1.0-beta.39-macos.zip` SHA-256: `7da4f0991a27f61ef4ff875ac7bf0a05348bb57d72a739ac559f4635a8a3f5c0`.

Beta.38 previously added fresh-Bot usability and delivery-loop hardening:

- Added a plain-English end-to-end guide plus an editable 16:9 SVG and 4K PNG for explaining the router on YouTube
- Added a repository-level coding-agent guide and exact fresh-Bot acceptance gate so a new agent cannot mistake an old Bot or mocked response for completion
- Documented that composer controls are deterministic but do not appear in Grok Bot's native slash menu, and that current OpenRouter computer/sub-agent parity remains unverified
- Long noVNC text transfers are now paced in eight-character batches; the installer no longer treats a queued RFB burst as proof that the guest terminal received the entire base64 line
- Every transfer attempt now sends Ctrl-C through the verified RFB session before typing, so an interrupted install cannot leave a partial shell line that corrupts restore or reinstall
- The verified stock backup now lives under persistent `/home/box/sand-data/grokbot-router-backup/` instead of the replaceable live-host directory; the old backup path remains a migration source
- The compatibility manifest accepts a second exact Grok Bot 0.30.0 stock-host SHA only after a read-only dry run verified every required patch anchor exactly once
- Computer discovery now reuses an existing noVNC target before clicking `Open computer`, preventing the installer from rotating a valid session between transport and payload phases
- Terminal safety checks now use accurate Vision OCR so a small computer preview is recognized before the dock fallback can toggle an already-open Terminal away
- Stock restore now prints its authoritative success sentinel before a delayed host restart, preventing a correct restore from being reported as a VNC-reconnect failure

- Remote desktop points are now interpolated into JavaScript, mapped through the live noVNC canvas bounds and 1280×800 intrinsic framebuffer dimensions, and serialized across the Swift/JavaScript bridge before clicking, so the 700×768 Terminal point lands correctly in both preview and fullscreen
- The native installer now verifies that a real terminal prompt is visible before typing; if Ctrl–Alt–T misses, it clicks Grok Bot 0.30.0's fixed terminal dock icon, refocuses the noVNC keyboard, and retries automatically
- The dock fallback now allows 12 seconds for Xfce Terminal to cold-start, while continuing to require visible `Terminal` and workspace prompt evidence before any payload text is sent
- The Ctrl–Alt–T path now gets the same verified 12-second cold-start window before the dock fallback is attempted, preventing a late-opening terminal from being immediately toggled back to the desktop
- Remote pointer and special-key input now call the connected RFB instance exported by Grok Bot's pinned noVNC UI, bypassing Electron nested-input calls and synthetic browser events that could report success without a guest-side effect
- Remote command text now also travels character-by-character through `UI.rfb.sendKey`; the installer no longer uses Electron `Input.insertText`, which could place the transport command into Grok chat instead of the Bot terminal
- Terminal-opening failures remain fail-closed before payload transfer, with a specific diagnostic instead of sending install text into the chat composer
- The first harmless terminal transport probe now uses the same fresh-webview retry loop as payload transfer, so a manual `Open computer` click can rotate Grok's DevTools session without forcing the user to restart the installer
- An explicit initial `use ... tool` request now sends OpenRouter `tool_choice: required`; resumed tool-result rounds return to `auto` so the model can deliver the final answer instead of repeating the call
- When that request explicitly names a tool Grok already offered, the first OpenRouter round now forces that exact function by name instead of allowing a discovery or delivery tool to satisfy generic `required`
- A printed direct dynamic tool can be brokered without a discovery block only when the visible user request explicitly named that exact tool; a different or unmentioned tool stays inert
- OpenRouter responses that print `to=functions...` markup instead of returning a native function call are recovered into one real Grok call only when that exact tool was offered by the host
- Textual-call recovery now tolerates the live Luna dialect's Unicode object-replacement characters and fenced JSON while keeping the search bounded to one marker-local object
- A recovered pseudo-call returns no provider-printed markup to Grok; the native host call executes first and only the resumed result round can produce the user-facing answer
- When several printed offered calls appear, an explicitly user-named offered tool outranks later provider-invented delivery syntax
- When a hard-forced, explicitly named offered tool is returned as bare JSON with no function marker, one object is recoverable only if it satisfies that exact offered tool's required schema; delivery-shaped JSON is never treated as tool arguments
- If that hard-forced object contains wire-invalid control characters, required string fields can be decoded individually only when the exact offered schema declares them as strings
- Redacted `turn_ok` audit receipts now include counts for function markers, object starts, native calls, and recovered calls on explicit tool requests, without storing provider text or user content
- The recovery path accepts the second live OpenRouter dialect where `GetDynamicTools` omits `code:` and a discovered tool such as `Shell` is printed as a direct call
- A printed direct dynamic tool is wrapped through Grok's offered `CallDynamicTool` broker only when the same response first discovered that exact tool name; mismatched or undiscovered names remain inert
- Repeated printed discovery attempts collapse to one actionable `CallDynamicTool` request, preventing a model-authored transcript from masquerading as successful computer access
- Tool-enabled OpenRouter turns now state the exact offered tool names and explicitly forbid narrating tool markup as assistant text
- Audit `turn_ok` receipts record `recoveredTextualToolCall: true` when the guarded compatibility path was required
- Automatic new-Bot greetings now receive no outer-tool schemas, preventing a greeting from wandering into dynamic-tool discovery before the user sends a message
- Host-side adapter failures now append a bounded, redacted `host_bridge_error` event to the normal router audit instead of existing only in the remote host console

- `/models <id>` now works as a forgiving alias for `/model <id>`
- A listed OpenRouter `vendor/model` ID can be pasted by itself to switch
- `/models` now prints the exact next-step instruction
- Invalid model commands are handled deterministically instead of leaking into model chat
- Routed models receive authoritative provider/model/control-plane context
- Visible assistant delivery stops repeated inference and duplicate follow-up bubbles
- Delivery completion is recorded only after Grok returns a real delivery receipt; an old greeting or earlier response can no longer suppress a later turn
- Native tool-result wrappers and ordinary hidden continuation prompts are filtered so `Shell` and dynamic-tool calls do not repeat as new user requests
- Tagged Grok background completions now revive the routed parent turn, allowing a finished sub-agent result to replace the earlier launch acknowledgement
- Automated fresh-Bot regression tests cover the exact previously failing input sequence
- Automated revival coverage proves a child completion still runs after the launch response was already delivered, then stops after the child result receipt
- Durable `sandAutomationCompletionId` signatures suppress sequential and concurrent host replays without blocking later tool-result rounds
- A late receipt for the earlier “subagent started” message can no longer suppress the finished child's continuation
- Capitalization, whitespace variants, unsupported router commands, and unlisted bare model IDs are intercepted deterministically instead of reaching inference
- State updates now merge under the per-Bot lock, so a late tool or turn write cannot revert a provider/model switch
- A stable Grok Bot/conversation identifier now outranks turn-scoped request IDs when deriving the state key; model and provider switches therefore survive the next normal message instead of forking into a default-model state file
- Snake-case Bot IDs plus chat, thread, lineage, and root IDs are accepted as stable conversation identity candidates
- Codex now receives the same cleaned background-completion transcript as OpenRouter; ordinary hidden nudges remain private
- Provider errors written to the host result are redacted, bounded, and never include a recognizable API-key token
- Installer operations close their temporary loopback diagnostic port and relaunch Grok Bot normally on both success and failure
- Upgrades replace stale model catalogs from the packaged manifest while preserving existing provider/model selections unless explicit installer flags override them
- Host child processes ignore expected stdin `EPIPE`, escalate timed-out turns to `SIGKILL`, retain only the four newest timestamped host backups, and retain only two previous runtime directories
- Compatibility manifest marker now matches the current V37 patch
- Exact-text OpenRouter turns no longer receive outer-tool schemas, preventing a literal reply from wandering into an unrelated `GetDynamicTools` call
- The management CLI is linked into `/usr/local/bin` when the Bot computer supports passwordless installation, so documented `grokbot-router` commands work in a fresh terminal
- Outstanding outer tool calls now survive assistant status text, reasoning, and Grok permission UI; only the matching result settles the call
- Known camel-case, snake-case, single-object, string-result, orphan, and dangling Grok tool wrappers are normalized into a valid provider transcript
- Every early suppression writes a redacted `turn_suppressed` receipt with a bounded reason and non-secret protocol IDs
- Empty OpenRouter continuations retry once; a completed background child deterministically falls back to its tagged result instead of disappearing
- Completion latches expire, controls bypass them, and reset epochs prevent a late Codex result from resurrecting a cleared thread
- Provider tool-call IDs are replaced with router-owned UUIDs before crossing into Grok's host protocol
- The patched host launches the adapter with an explicit environment allowlist instead of inheriting every host variable
- Added a mandatory fresh-Bot release gate and coding-agent cold-start guide

The beta.2 foundation remains:

- Native Mac installer for Codex SDK and OpenRouter
- Loopback/noVNC install with no Accessibility permission
- Exact-version/hash gate, checksummed payload, verified stock backup, and one-click restore
- Per-Bot provider, model, reasoning, and Codex thread state
- Codex structured bridge to Grok tools
- OpenRouter native function-call and multimodal tool-result bridge
- In-chat provider/model controls and a redacted doctor command
- Automated runtime, patch, rollback, end-to-end payload, and installer build tests
- Codex CLI/SDK pinned to 0.151.0 with verified ChatGPT device authorization
- Reconnect-safe, quote-free chunked payload transfer with real-output-only completion markers
- Success marker is emitted before the delayed host restart, preventing false-negative installs after a VNC reconnect
- Removed a redundant OCR acknowledgement that could be lost during a legitimate noVNC target swap
- Provider selection remains visible after an installer operation completes
- Live Codex parity verified for text, outer Shell/Read, Screenshot, and dynamic sub-agent execution
- OpenRouter key-shape validation in the installer, runtime, and doctor command
- Beta.31's audit exposed the root mismatch behind the original screenshot: the Luna switch and the following prompt used different state files because a stable Bot identifier was combined with a changing request ID. The following prompt therefore ran on default Claude. Beta.32 makes stable Bot identity authoritative.
- The exact beta.32 artifact passed live new-Bot greeting, doctor, catalog, bare Luna switching, provider/model identity on the next normal turn, exact-once text, and second-Bot isolation. This proves the deterministic install/model-switch demo path.
- Full OpenRouter tool parity remains blocked on the current live host: the beta.32 Shell turn received zero actionable native tool schemas, so guarded recovery correctly refused to execute provider-printed pseudo Shell markup. Screenshot and returned-child claims remain outside the film-ready scope until the host supplies those schemas and the full gate passes.
- The exact beta.38 artifact passed install, authoritative verified-stock restore, post-restore reinstall, a genuinely new Bot reporting beta.38, Luna persistence into the following normal inference, one `BETA38_FRESH_TEXT_OK` delivery, and second-Bot default isolation. ZIP SHA-256: `4a0f704c96a532d7000459fbf09090d33897e9cbace5c833bf0c4d67fe117235`.

Known limitations: direct Anthropic SDK support is not included; Claude models are available through OpenRouter. Composer commands are intercepted by the router but do not appear in Grok Bot's native slash-suggestion menu.
