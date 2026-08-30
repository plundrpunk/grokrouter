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
  <img alt="Beta 0.1.0-beta.39" src="https://img.shields.io/badge/beta-0.1.0--beta.39-ff6b2c?style=flat-square">
  <img alt="Grok Bot 0.30.0 only" src="https://img.shields.io/badge/Grok_Bot-0.30.0_only-171717?style=flat-square">
  <img alt="macOS Apple silicon" src="https://img.shields.io/badge/macOS-Apple_silicon-111111?style=flat-square&logo=apple">
  <img alt="Windows x64 and Arm64 preview" src="https://img.shields.io/badge/Windows-x64_%2B_Arm64_preview-0078d4?style=flat-square&logo=windows11">
</p>

> [!IMPORTANT]
> GrokRouter is an unofficial, reversible beta pinned to **Grok Bot 0.30.0**. It patches an implementation detail and is not affiliated with xAI, X, Anysphere, OpenAI, Anthropic, or OpenRouter. Unknown Grok Bot builds are rejected instead of guessed at.

## Download

**YouTube viewers should use the official [GrokRouter download page](https://promptadvisers.github.io/grokrouter-downloads/).** You do not need Git, source code, Terminal, or access to this private development repository.

The download page detects your computer and offers the right signed installer:

- **Mac:** download the `.dmg`, open it, and drag **GrokRouter** into **Applications**.
- **Windows:** download the `-setup.exe`, run it, and open **GrokRouter** from the Start menu. Windows builds remain preview-only until the signed release completes the real-device acceptance gate.

If macOS says the developer cannot be verified, or Windows identifies the publisher as unknown, **do not bypass the warning**. Delete that file and return to the official download page. Public builds are published only after signing, notarization, checksum, and fresh-machine verification.

## Install and use it in plain English

For the supported Grok Bot 0.30.0 build, the normal setup is: open Grok Bot, open GrokRouter, choose your model, and click **Install Router**. There are only a few details to know.

### Before you start

- Install the official **Grok Bot 0.30.0** desktop app.
- Have a Codex account, an OpenRouter API key, or both.
- Make sure you can open the Computer for at least one Bot in Grok Bot.
- Install GrokRouter from the official download page. The macOS app is currently the live-verified build; Windows x64 and Arm64 installers are previews.

### Step by step

1. **Open Grok Bot** and leave it visible.
2. **Open GrokRouter.** Find it in Applications on Mac or the Start menu on Windows.
3. **Choose what you want to use.** Turn Codex SDK and OpenRouter on or off, choose the default provider, and choose the default models.
4. **Add your OpenRouter key** if you enabled OpenRouter. The installer sends it directly to Grok Bot's protected Secrets store and clears the field.
5. **Click Install Router.** GrokRouter checks the exact app version before changing anything and saves a verified stock backup first.
6. **If GrokRouter asks for a Bot computer,** return to Grok Bot, select any Bot, and click **Open computer**. Keep Grok Bot and GrokRouter open while the installer finishes. You do not need to type terminal commands yourself.
7. **If you enabled Codex, click Codex sign-in** in GrokRouter and complete the sign-in instructions shown in the Bot terminal.
8. **Create a brand-new Bot** after installation. In its normal chat box, send `/router doctor`, then `/provider`. If both status messages look healthy, chat normally.

From then on, stay inside Grok Bot. Send `/models` to see the available models, paste one listed model ID by itself to switch that Bot, and send `/provider` whenever you want to confirm its current choice. These controls are typed into the normal message box; they are not entries in Grok Bot's slash-command menu.

> [!CAUTION]
> If GrokRouter says your copy of Grok Bot is unsupported or has changed, stop there. That refusal protects the stock app. Do not force the installation.

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
| macOS 12+, Apple silicon | `grokrouter-…-macos.dmg` | Exact beta.39 app installed successfully; a genuinely new Bot passed Doctor and provider selection. The preceding beta.38 candidate passed install → restore → reinstall. The signed public DMG still requires final Gatekeeper verification. |
| Windows x64 | `grokrouter-…-windows-x64-setup.exe` | Package builds, PE architecture is verified, offline OCR gate passes, and static/security tests pass. Real-Windows signed install → restore → reinstall → fresh-Bot acceptance is still required. |
| Windows Arm64 | `grokrouter-…-windows-arm64-setup.exe` | Same implementation and code-level gates as x64; the real-device acceptance cycle is still required. |

Windows packages are intentionally labeled **preview** until the exact signed artifacts pass the full live gate. A macOS pass is not treated as Windows evidence. The detailed claim ledger lives in the [test matrix](docs/TEST-MATRIX.md).

## Install GrokRouter

### Requirements

- Official Grok Bot **0.30.0**
- At least one Bot whose computer can be opened
- macOS 12+ on Apple silicon, or Windows x64/Arm64
- A Codex account, an OpenRouter key, or both

### From the official download page

1. Open the [GrokRouter download page](https://promptadvisers.github.io/grokrouter-downloads/).
2. On Mac, open the DMG and drag **GrokRouter** into Applications. On Windows, run the setup file.
3. Open **GrokRouter** from Applications or the Start menu.
4. Select Codex SDK, OpenRouter, or both. Choose the default provider and model.
5. Keep Grok Bot visible and click **Install Router**.
6. For Codex, click **Start Codex Sign-in** and complete the device-code flow in the Bot terminal.
7. In Grok Bot chat, send `/router doctor`, then `/provider`.

The installer transfers a small checksummed bootstrap through the Bot computer, installs pinned dependencies inside that computer, preserves a stock host backup, closes its temporary diagnostic connection, and reopens Grok Bot normally.

> [!NOTE]
> Windows users should remove an older extracted GrokRouter folder before extracting a replacement ZIP. That prevents Windows from launching stale packaged assets.

## Build the installers yourself

Authorized testers can build the complete installer from this repository. The macOS Swift app, Windows Electron app, remote bootstrap, provider runtime, patch engine, exact compatibility manifest, tests, signing workflow, and recovery path are all included. Grok Bot's proprietary host source is not included or required in the repository.

### What you need

- Git, Bash, Node.js 18 or newer, npm, Python 3, and `shasum` or `sha256sum`
- For macOS: macOS with Xcode Command Line Tools, including Swift and `codesign`
- For Windows packages: a ZIP tool; signing additionally requires Windows, PowerShell, `signtool.exe`, and your own Authenticode certificate

### Build commands

```bash
git clone https://github.com/promptadvisers/grokrouter.git
cd grokrouter
npm ci --prefix runtime --ignore-scripts --no-audit --no-fund
npm test
```

Build the macOS package on a Mac:

```bash
npm run build:macos
```

Build either or both Windows architectures from a Bash environment:

```bash
npm run build:windows -- x64
npm run build:windows -- arm64
```

Finished apps and checksum files appear in `build/`. A local macOS build is ad-hoc signed, and local Windows builds are unsigned development packages. Trusted release builds require the signing and notarization setup in [the release guide](docs/RELEASE.md).

If the packaged installer UI or delivery mechanism fails, start with these files:

| Area to change | Source |
| --- | --- |
| macOS installer | `installer/GrokBotRouterInstaller.swift` |
| Windows installer | `installer-windows/` |
| macOS and Windows packaging | `scripts/build-macos-app.sh`, `scripts/build-windows-app.sh` |
| Files delivered into the Bot computer | `scripts/build-payload.sh`, `remote/install.sh` |
| Exact supported Grok build | `patch/manifests/0.30.0.json`, `patch/router_patch.py` |
| Provider behavior | `runtime/run-provider.mjs` |
| Required proof before calling a build usable | `docs/FRESH-BOT-ACCEPTANCE.md`, `docs/TEST-MATRIX.md` |

Building the source yourself can fix packaging, signing, UI, or machine-specific delivery problems. It does **not** automatically support a different Grok Bot release. A new Grok version needs a new exact manifest, a reviewed transformation, all tests, and the complete live install → restore → reinstall → fresh-Bot acceptance cycle.

The source remains private and custom builds may not be redistributed. Official unmodified binaries may be downloaded and used under the limited public terms in [the license](LICENSE.md).

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
| Windows setup and signing | `scripts/build-windows-setup.ps1`, `scripts/sign-windows.ps1` | Builds per-user Start-menu installers, Authenticode-signs every packaged executable, and verifies the signatures |
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
grokrouter-<version>-macos.dmg
grokrouter-<version>-macos.dmg.sha256
grokrouter-<version>-windows-x64.zip
grokrouter-<version>-windows-x64.zip.sha256
grokrouter-<version>-windows-arm64.zip
grokrouter-<version>-windows-arm64.zip.sha256
grokrouter-<version>-windows-x64-setup.exe
grokrouter-<version>-windows-x64-setup.exe.sha256
grokrouter-<version>-windows-arm64-setup.exe
grokrouter-<version>-windows-arm64-setup.exe.sha256
```

Local macOS builds are ad-hoc signed. Local Windows builds are unsigned development artifacts. The public release workflow refuses to prepare a draft unless Apple Developer ID/notarization credentials, Windows Authenticode credentials, and access to the public binary repository are configured.

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
- [Public release procedure](docs/RELEASE.md)
- [OpenGrok comparison](docs/OPENGROK-COMPARISON.md)
- [YouTube demo runbook](docs/YOUTUBE-DEMO.md)
- [Editable 16:9 architecture diagram](docs/diagrams/grokbot-router-end-to-end.svg)
- [4K architecture export](docs/diagrams/grokbot-router-end-to-end-4k.png)

## Current scope

GrokRouter is deliberately narrow. Adding another Grok Bot version requires inspecting the untouched stock host, recording its exact hash and size, confirming every patch anchor exactly once, running the complete automated suite, and completing the live install → restore → reinstall → fresh-Bot gate on each platform.

Never add a wildcard hash. Never ship a development override. Never call a preview verified.

---

<p align="center">
  <strong>GrokRouter</strong> · Beta by Prompt Advisers<br>
  The official Grok Bot stays in charge. You choose the model.
</p>
