<p align="center">
  <img src="installer/Assets/grokbot-router-mascot-1024.png" width="176" alt="GrokRouter mascot wearing a black snapback">
</p>

<h1 align="center">GrokRouter</h1>

<p align="center">
  <strong>Bring your own model to Grok Bot.</strong><br>
  Route the official Grok Bot desktop app through the Codex SDK or OpenRouter<br>
  without giving up its chat, Bots, files, computer, or tool boundary.
</p>

<p align="center">
  <img alt="Private beta 0.1.0-beta.39" src="https://img.shields.io/badge/private_beta-0.1.0--beta.39-ff6b2c?style=flat-square">
  <img alt="Grok Bot 0.30.0 only" src="https://img.shields.io/badge/Grok_Bot-0.30.0_only-171717?style=flat-square">
  <img alt="macOS Apple silicon" src="https://img.shields.io/badge/macOS-Apple_silicon-111111?style=flat-square&logo=apple">
  <img alt="Windows x64 and Arm64 preview" src="https://img.shields.io/badge/Windows-x64_%2B_Arm64_preview-0078d4?style=flat-square&logo=windows11">
</p>

> [!IMPORTANT]
> GrokRouter is an unofficial, reversible private beta pinned to **Grok Bot 0.30.0**. It patches an implementation detail and is not affiliated with xAI, X, Anysphere, OpenAI, Anthropic, or OpenRouter. Unknown Grok Bot builds are rejected instead of guessed at.

## The short version

GrokRouter keeps Grok Bot as the product you touch and changes the model runtime behind a Bot.

| You keep | You choose |
| --- | --- |
| Grok Bot's desktop app and chat | Codex SDK or OpenRouter |
| Existing Bots and conversations | A different provider per Bot |
| Cloud computer, files, browser, and permissions | A different model and reasoning level per Bot |
| Grok's outer tool-execution boundary | Stock Grok again at any time |

Install it once, create a Bot, and type `/provider`. That Bot can use Codex while another uses Claude, Luna, or another configured OpenRouter model. Provider state is isolated per Bot and written atomically.

## How it works

![GrokRouter end-to-end architecture](docs/diagrams/grokbot-router-end-to-end.svg)

1. The platform installer verifies the exact supported Grok Bot build.
2. It opens a loopback-only diagnostic session and operates the visible Bot computer through Grok's existing noVNC connection.
3. A checksummed bootstrap installs the pinned runtime and saves a verified stock backup.
4. A deliberately small host adapter redirects inference to GrokRouter.
5. The selected provider answers—or requests one of the tools Grok actually offered.
6. Grok remains responsible for permissions, tool execution, and delivering the final response in chat.

The provider cannot invent tool authority. Printed pseudo-tool markup stays inert unless it can be mapped to the exact schema Grok offered for that turn.

For the friendly explanation, read [How it works](docs/HOW-IT-WORKS.md). For implementation details, read [Architecture](docs/ARCHITECTURE.md).

## Platform status

| Platform | Package | Current evidence |
| --- | --- | --- |
| macOS 12+, Apple silicon | `grokrouter-…-macos.zip` | Exact beta.39 artifact installed successfully; a genuinely new Bot passed Doctor and provider selection. The preceding beta.38 candidate passed install → restore → reinstall. |
| Windows x64 | `grokrouter-…-windows-x64.zip` | Package builds, PE architecture is verified, offline OCR gate passes, and static/security tests pass. Real-Windows signed install → restore → reinstall → fresh-Bot acceptance is still required. |
| Windows Arm64 | `grokrouter-…-windows-arm64.zip` | Same implementation and code-level gates as x64; the real-device acceptance cycle is still required. |

Windows packages are intentionally labeled **preview** until the exact signed artifacts pass the full live gate. A macOS pass is not treated as Windows evidence. The detailed claim ledger lives in the [test matrix](docs/TEST-MATRIX.md).

## Install GrokRouter

### Requirements

- Official Grok Bot **0.30.0**
- At least one Bot whose computer can be opened
- macOS 12+ on Apple silicon, or Windows x64/Arm64
- A Codex account, an OpenRouter key, or both

### From a private release

1. Download the package for your platform from the private GitHub prerelease.
2. Unzip it.
3. On macOS, open **GrokRouter**. On Windows, open the extracted folder and run **GrokRouter.exe**.
4. Select Codex SDK, OpenRouter, or both. Choose the default provider and model.
5. Keep Grok Bot visible and click **Install Router**.
6. For Codex, click **Start Codex Sign-in** and complete the device-code flow in the Bot terminal.
7. In Grok Bot chat, send `/router doctor`, then `/provider`.

The installer transfers a small checksummed bootstrap through the Bot computer, installs pinned dependencies inside that computer, preserves a stock host backup, closes its temporary diagnostic connection, and reopens Grok Bot normally.

> [!NOTE]
> Windows users should remove an older extracted GrokRouter folder before extracting a replacement ZIP. That prevents Windows from launching stale packaged assets.

## Prove it with a brand-new Bot

Create a Bot **after** installation and send:

```text
/router doctor
/models
openai/gpt-5.6-luna
/provider
```

The bare model ID is intentional: copy any listed OpenRouter model from `/models` and paste it directly into the composer. The final receipt must name OpenRouter and `openai/gpt-5.6-luna`.

This is the minimum proof, not the whole release gate. The authoritative sequence is [Fresh-Bot Acceptance](docs/FRESH-BOT-ACCEPTANCE.md).

## Chat controls

Type these into Grok Bot's normal composer. They are deterministic GrokRouter controls, although they do not appear in Grok Bot's native slash-suggestion menu.

| Command | What it does |
| --- | --- |
| `/provider` | Show this Bot's provider and model |
| `/provider codex` | Switch this Bot to the Codex SDK |
| `/provider openrouter` | Switch this Bot to OpenRouter |
| `/models` | Show the configured model catalog |
| `/model sol` | Select the Codex `gpt-5.6-sol` alias |
| `/model anthropic/claude-sonnet-4.6` | Select a specific OpenRouter model |
| `/models openai/gpt-5.6-luna` | Forgiving plural alias that switches models |
| `openai/gpt-5.6-luna` | Paste a listed OpenRouter model ID by itself |
| `/reasoning minimal\|low\|medium\|high\|xhigh` | Change Codex reasoning effort |
| `/router reset` | Start a fresh provider thread without deleting the Grok transcript |
| `/router doctor` | Report runtime, patch, provider, and credential health |
| `/router help` | Show the command reference |

Invalid or near-miss model controls return bounded help instead of becoming model prompts.

## Everything in the system

| Component | Source | Responsibility |
| --- | --- | --- |
| macOS installer | `installer/GrokBotRouterInstaller.swift` | Native Swift UI, app/version gate, loopback diagnostics, Vision OCR, noVNC transport, install, Doctor, repair, and restore |
| Windows installer | `installer-windows/` | Isolated Electron UI with context isolation, bundled offline terminal OCR, protected secret handoff, and the same install/repair/restore protocol |
| App identity | `installer/Info.plist`, `installer/Assets/` | GrokRouter name, mascot, macOS icon, and Windows icon resources |
| Payload builder | `scripts/build-payload.sh` | Creates the small checksummed archive sent into the Bot computer |
| Platform builders | `scripts/build-macos-app.sh`, `scripts/build-windows-app.sh` | Produce app folders, ZIPs, and SHA-256 files for macOS, Windows x64, and Windows Arm64 |
| Windows signing | `scripts/sign-windows.ps1` | Authenticode-signs and verifies both Windows architectures for private releases |
| Remote bootstrap | `remote/install.sh` | Idempotently installs pinned dependencies, config, CLI, runtime, patch, and watchdog inside the Bot computer |
| Management CLI | `remote/grokbot-router` | Status, enable, disable, repair, Doctor, and verified stock uninstall |
| Lifecycle watchdog | `remote/grokbot-router-watchdog` | Rate-limited repair when Grok replaces the live host with a known stock build; never repairs an unknown build or intentional restore |
| Compatibility manifests | `patch/manifests/` | Exact Grok version, stock-host SHA-256 allowlist, size, and required source anchors |
| Patch engine | `patch/router_patch.py` | Original transformation, syntax check, atomic activation, verified backup, dry run, and restore |
| Provider runtime | `runtime/run-provider.mjs` | Controls, stable Bot identity, per-Bot state, replay protection, Codex/OpenRouter adapters, tool conversion, and redacted audit |
| Provider defaults | `runtime/provider.default.json` | Packaged provider/model catalog and installer defaults—never credentials |
| Automated tests | `tests/` | Runtime behavior, patch/restore, payload integrity, installer contracts, Windows isolation, signing, and packaging gates |
| CI and signed release | `.github/workflows/` | Cross-platform tests/builds plus fail-closed Apple notarization and Windows Authenticode release jobs |
| Evidence and operating docs | `docs/` | Architecture, acceptance, test matrix, security/release guidance, diagrams, independent review, and demo runbook |

No proprietary Grok host source is committed or bundled. The repository contains the original transformation and exact compatibility metadata only.

## Repair, pause, or restore

The installer exposes the recovery path directly:

- **Run Doctor** checks the installed version, patch status, providers, protected credential shape, Node, and the tool bridge.
- **Repair Router** reapplies the adapter only if the live host is an exact allowlisted stock build.
- **Restore Stock Grok Bot** verifies the persistent stock backup, restores it atomically, disables automatic repair, and restarts the host.

The same controls are available inside the Bot computer:

```bash
grokbot-router status
grokbot-router doctor
grokbot-router disable
grokbot-router enable
grokbot-router repair
grokbot-router uninstall
```

`disable` keeps the adapter installed but sends new sessions through the stock inference path. `uninstall` restores the verified stock host while retaining the runtime and backup for recovery.

## Safety by construction

- **Exact compatibility:** the patch requires a supported app version, allowlisted stock-host SHA-256, expected size, and exact source anchors.
- **Fail closed:** an unknown hash, missing anchor, invalid generated host, invalid credential shape, or unverified terminal stops the operation.
- **Reversible:** verified stock and timestamped pre-change backups exist before activation.
- **Atomic:** generated JavaScript is syntax-checked and replaced atomically; failed activation restores the previous runtime.
- **Checksummed:** release ZIPs have external SHA-256 files and the payload validates every internal member.
- **Local installer bridge:** Electron diagnostics bind to `127.0.0.1` and are closed after every operation.
- **No broad OS permissions:** the installers do not request Accessibility, Screen Recording, or Full Disk Access.
- **Protected secrets:** OpenRouter keys go directly to Grok Bot Secrets and are excluded from repository files, provider state, release artifacts, and audit logs.
- **Bounded tools:** only schemas offered by Grok for the current turn can cross the tool bridge.
- **Honest evidence:** code-level capability, live verification, and blocked claims are recorded separately.

Read [Security](SECURITY.md) before distributing access.

## Development

```bash
npm ci --prefix runtime --ignore-scripts --no-audit --no-fund
npm test
npm run build:macos
npm run build:windows -- x64
npm run build:windows -- arm64
```

`npm test` covers the provider runtime, patch/restore engine, complete payload install, native installer contracts, Windows renderer isolation, cross-architecture packaging, and signing gates.

Build outputs go under `build/`:

```text
grokrouter-<version>-macos.zip
grokrouter-<version>-macos.zip.sha256
grokrouter-<version>-windows-x64.zip
grokrouter-<version>-windows-x64.zip.sha256
grokrouter-<version>-windows-arm64.zip
grokrouter-<version>-windows-arm64.zip.sha256
```

Local macOS builds are ad-hoc signed. Local Windows builds are unsigned development artifacts. The private release workflow refuses to publish unless Apple Developer ID/notarization credentials and Windows Authenticode credentials are configured.

Coding agents must begin with [AGENTS.md](AGENTS.md). It defines the authoritative files, protected safety boundaries, verification commands, and fresh-Bot acceptance gate.

## Release truth

Beta.39 fixed the lifecycle case where Grok replaced the live host while leaving the router runtime and config installed. It adds an exact-gated watchdog, explicit Repair action, bounded JPEG installer screenshots, redesigned GrokRouter apps, and Windows x64/Arm64 packages.

The exact local macOS beta.39 artifact reinstalled successfully and a genuinely new Bot passed `/router doctor` and `/provider`. Windows packages pass build and static safety checks but are not represented as live-verified. Full OpenRouter computer/sub-agent parity is also not claimed when Grok supplies no actionable outer-tool schemas.

See [Release Notes](RELEASE_NOTES.md), [Test Matrix](docs/TEST-MATRIX.md), and the dated [Independent Review](docs/INDEPENDENT-REVIEW-2026-08-29.md) for the evidence behind every claim.

## Documentation

- [How it works, without the jargon](docs/HOW-IT-WORKS.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Fresh-Bot acceptance gate](docs/FRESH-BOT-ACCEPTANCE.md)
- [Verification matrix](docs/TEST-MATRIX.md)
- [Security and trust boundary](SECURITY.md)
- [Private release procedure](docs/RELEASE.md)
- [OpenGrok comparison](docs/OPENGROK-COMPARISON.md)
- [YouTube demo runbook](docs/YOUTUBE-DEMO.md)
- [Editable 16:9 architecture diagram](docs/diagrams/grokbot-router-end-to-end.svg)
- [4K architecture export](docs/diagrams/grokbot-router-end-to-end-4k.png)

## Current scope

GrokRouter is deliberately narrow. Adding another Grok Bot version requires inspecting the untouched stock host, recording its exact hash and size, confirming every patch anchor exactly once, running the complete automated suite, and completing the live install → restore → reinstall → fresh-Bot gate on each platform.

Never add a wildcard hash. Never ship a development override. Never call a preview verified.

---

<p align="center">
  <strong>GrokRouter</strong> · Private beta by Prompt Advisers<br>
  The official Grok Bot stays in charge. You choose the brain.
</p>
