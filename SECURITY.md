# Security and trust boundary

This is an unofficial compatibility adapter. It modifies code inside a Grok Bot cloud computer and therefore deserves the same caution as any developer tool that can execute code and use a computer on your behalf.

Official audience downloads are published only at <https://promptadvisers.github.io/grokrouter-downloads/>. The macOS release must be signed and notarized by Prompt Advisers. The Windows release must show Prompt Advisers as its verified publisher. Do not bypass an unknown-developer or unknown-publisher warning.

## What the installer can access

The macOS installer validates `/Applications/Grok Bot.app`. The Windows installer locates the standard Grok Bot installation, verifies its exact version, and requires a valid Authenticode signature. Each restarts that app with an Electron diagnostic port bound only to `127.0.0.1` and uses the local connection to operate the already-visible noVNC Bot computer. Neither installer requests operating-system Accessibility, Screen Recording, or Full Disk Access permissions.

Inside the Bot computer, the bootstrap can write under `/home/box/sand-data/grokbot-router`, back up and atomically replace `/home/box/sand-host/host-main.cjs`, run `npm ci`, restart the Grok host process, and invoke the installed Codex login flow.

## Credentials

- Codex authentication is handled by the pinned Codex CLI/SDK device flow inside the Bot computer.
- An OpenRouter key entered in either installer is passed over the loopback-only DevTools session directly to `window.desktop.secrets.upsert` and Grok Bot's protected Secrets store. The Windows renderer clears its password field immediately after handing the value to the isolated main process.
- The runtime reads the key from the environment or Grok Bot Secrets at request time.
- Credentials are never intentionally printed, included in provider state, included in release artifacts, or sent to audit logs.
- `grokbot-router doctor` reports presence/status only and redacts account email output.

## Network destinations

Depending on selected providers, the Bot computer connects to npm during installation, OpenAI/Codex endpoints for Codex operation, and `openrouter.ai` for OpenRouter completions. The routed model receives the Grok conversation and any attachments/tool results needed for the turn. Selecting a third-party OpenRouter model means that provider may also process the request under OpenRouter's routing and privacy terms.

## Integrity and recovery

The release archive has an external SHA-256 file. Its bootstrap validates an internal `SHA256SUMS` manifest before executing. The host patch requires a known stock hash plus three exact source anchors. It saves verified stock and timestamped pre-change backups, syntax-checks the generated host, and activates it atomically. Restore also syntax-checks the verified stock backup before atomic replacement.

The installer deliberately refuses unknown Grok Bot builds. `--allow-unknown-host` exists only for synthetic tests and must never appear in distributed commands.

## Reporting

The source repository remains private. Report suspected credential exposure, unsafe patch behavior, or unintended tool access directly to Prompt Advisers; do not put secrets or private Grok transcripts in a public issue. Rotate any credential that may have been exposed and restore stock Grok Bot before further diagnosis.
