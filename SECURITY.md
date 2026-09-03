# Security and trust boundary

This is an unofficial compatibility adapter. It modifies code inside a Grok Bot cloud computer and therefore deserves the same caution as any developer tool that can execute code and use a computer on your behalf.

The official source is <https://github.com/promptadvisers/grokrouter>. The supported installer shells can be built locally from that source. GrokRouter does not ask users to bypass an unknown-developer or signature warning for a downloaded binary.

## What the installer can access

The macOS installer validates `/Applications/Grok Bot.app`, its exact bundle identifier, its Anysphere Team ID, and Grok Bot 0.30.0 before continuing. The Windows installer requires both a valid Authenticode signature and a reviewed signer-certificate thumbprint; beta.47 ships with no reviewed Windows thumbprint, so Windows installation fails closed while that platform remains a source preview. Each platform implementation uses a random Electron diagnostic port bound only to `127.0.0.1`, verifies that the listener belongs to the verified Grok Bot process, and accepts only that port's browser WebSocket path. The Mac app does not request operating-system Accessibility, Screen Recording, or Full Disk Access permissions; the Windows renderer runs with context isolation, no Node integration, and the Electron sandbox enabled.

Inside the Bot computer, the bootstrap can write under `/home/box/sand-data/grokbot-router`, back up and atomically replace `/home/box/sand-host/host-main.cjs`, run `npm ci`, restart the Grok host process, and invoke the installed Codex login flow.

## Credentials

- Codex authentication is handled by the pinned Codex CLI/SDK device flow inside the Bot computer.
- OpenAI and OpenRouter keys entered in GrokRouter are passed over the process-owned loopback DevTools session directly to `window.desktop.secrets.upsert` and Grok Bot's protected Secrets store. The installer requires a save receipt and clears each field after the protected handoff.
- The runtime reads the named key from the environment or the fixed Grok Bot Secrets path at request time. Custom secret paths are rejected.
- Credentials are never intentionally printed, included in provider state, included in release artifacts, or sent to audit logs.
- `grokbot-router doctor` reports presence/status only and redacts account email output.

## Network destinations

Depending on selected providers, the Bot computer connects to npm during a first Codex installation, OpenAI/Codex endpoints for Codex or direct OpenAI operation, and `openrouter.ai` for OpenRouter completions. Official OpenAI and OpenRouter base URLs are fixed in code. llama.cpp is restricted to an unauthenticated loopback endpoint inside the Bot computer. The routed model receives the Grok conversation and any attachments/tool results needed for the turn. Selecting a third-party OpenRouter model means that provider may also process the request under OpenRouter's routing and privacy terms.

## Integrity and recovery

The source installer builds only from the caller-selected local checkout; remote self-bootstrap is disabled. The release archive has an external SHA-256 file, and the Bot-computer bootstrap validates an internal `SHA256SUMS` manifest before executing. The host patch requires an exact signed stock SHA-256-and-byte-count pair plus exact source anchors. Structural compatibility remains diagnostic-only. It saves verified stock and timestamped pre-change backups, syntax-checks the generated host, and activates it atomically. Restore also verifies and syntax-checks the exact stock backup before atomic replacement.

The patcher deliberately refuses unknown Grok Bot builds. There is no unknown-host mutation override in the distributed payload.

## Reporting

Report suspected credential exposure, unsafe patch behavior, or unintended tool access through a private GitHub security advisory. Do not put secrets or private Grok transcripts in a public issue. Rotate any credential that may have been exposed and restore stock Grok Bot before further diagnosis.
