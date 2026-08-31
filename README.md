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
  <img alt="Beta 0.1.0-beta.40" src="https://img.shields.io/badge/beta-0.1.0--beta.40-ff6b2c?style=flat-square">
  <img alt="Grok Bot 0.30.0 only" src="https://img.shields.io/badge/Grok_Bot-0.30.0_only-171717?style=flat-square">
  <img alt="macOS Apple silicon" src="https://img.shields.io/badge/macOS-Apple_silicon-111111?style=flat-square&logo=apple">
  <img alt="Windows x64 and Arm64 source preview" src="https://img.shields.io/badge/Windows-x64_%7C_Arm64_preview-0078d4?style=flat-square&logo=windows11">
</p>

> [!IMPORTANT]
> GrokRouter is an unofficial, reversible beta pinned to **Grok Bot 0.30.0**. It patches an implementation detail and is not affiliated with xAI, X, Anysphere, OpenAI, Anthropic, or OpenRouter. Unknown Grok Bot builds are rejected instead of guessed at.

## Install on Mac

macOS on Apple silicon is the currently live-verified platform. The simplest install builds the small native app locally from this public repository, then puts it in your personal Applications folder. A Windows x64/Arm64 source preview is also included below, but it is not a public Windows compatibility claim until its native acceptance cycle passes.

### 1. Install Grok Bot first

Install the official **Grok Bot 0.30.0** app and make sure it is in `/Applications`. Open it once and confirm that you can select a Bot and open its Computer.

### 2. Copy this one command into Terminal

Open **Terminal**, paste the command below, and press Return:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/promptadvisers/grokrouter/source-v0.1.0-beta.40/scripts/install-macos.sh)"
```

The script downloads this public source, builds GrokRouter on your Mac, verifies the local app signature, installs it to `~/Applications/GrokRouter.app`, and opens it. It does not need Git, `sudo`, an installer package, or an Apple signing certificate.

If Apple Command Line Tools are missing, macOS will offer to install them. Finish that Apple installation, then run the same command again.

Prefer not to pipe a script into Terminal? Click **Code → Download ZIP**, unzip the repository, and double-click **Install GrokRouter.command**. The complete installer source is [here](scripts/install-macos.sh) for inspection.

### 3. Click Install Router

Keep Grok Bot visible, choose Codex SDK, OpenRouter, or both in GrokRouter, then click **Install Router**. If it asks for a Bot computer, return to Grok Bot, select any Bot, and click **Open computer**.

### 4. Check a new Bot

Create a brand-new Bot after installation. In its normal chat box, send `/router doctor`, then `/provider`. If both status messages look healthy, chat normally.

> [!NOTE]
> This source-build route is intentionally transparent: your Mac compiles the app from the exact code you can inspect here. GrokRouter never asks you to disable Gatekeeper or install an unknown downloaded binary.

## Install and use it in plain English

For the supported Grok Bot 0.30.0 build, the normal setup is: open Grok Bot, open GrokRouter, choose your model, and click **Install Router**. There are only a few details to know.

### Before you start

- Install the official **Grok Bot 0.30.0** desktop app.
- Have a Codex account, an OpenRouter API key, or both.
- Make sure you can open the Computer for at least one Bot in Grok Bot.
- Install GrokRouter from this repository using the command above.

### Step by step

1. **Open Grok Bot** and leave it visible.
2. **Open GrokRouter.** Find it in your personal Applications folder.
3. **Choose what you want to use.** Turn Codex SDK and OpenRouter on or off, choose the default provider, and choose the default models.
4. **Add your OpenRouter key** if you enabled OpenRouter. The installer sends it directly to Grok Bot's protected Secrets store and clears the field.
5. **Click Install Router.** GrokRouter checks the exact app version before changing anything and saves a verified stock backup first.
6. **If GrokRouter asks for a Bot computer,** return to Grok Bot, select any Bot, and click **Open computer**. Keep Grok Bot and GrokRouter open while the installer finishes. You do not need to type terminal commands yourself.
7. **If you enabled Codex, click Codex sign-in** in GrokRouter and complete the sign-in instructions shown in the Bot terminal.
8. **Create a brand-new Bot** after installation. In its normal chat box, send `/router doctor`, then `/provider`. If both status messages look healthy, chat normally.

From then on, stay inside Grok Bot. Send `/models` to see the available models, paste one listed model ID by itself to switch that Bot, and send `/provider` whenever you want to confirm its current choice. The installer also publishes those command families through Grok Bot's native `/` discovery menu.

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

| Platform | Current evidence |
| --- | --- |
| macOS 12+, Apple silicon | The exact beta.39 app installed successfully and a genuinely new Bot passed Doctor and provider selection. The preceding beta.38 candidate passed install → restore → reinstall. |
| Windows 11, x64 and Arm64 | Native Electron installer, exact signed-app/version gate, loopback/noVNC transport, restore path, packaging tests, and both ZIP and Inno Setup architectures build on the Windows CI runner. Native launch/install and live Grok Bot acceptance remain required before a public Windows claim. |

The detailed claim ledger lives in the [test matrix](docs/TEST-MATRIX.md). macOS is the live-verified platform; Windows is a source preview until its native acceptance cycle passes.

The installer transfers a small checksummed bootstrap through the Bot computer, installs pinned dependencies inside that computer, preserves a stock host backup, closes its temporary diagnostic connection, and reopens Grok Bot normally.

## Build the installers yourself

Anyone can inspect and build the Mac or Windows installer from this repository for personal, non-commercial use. The native platform shells, remote bootstrap, provider runtime, patch engine, exact compatibility manifest, tests, and recovery path are all included. Grok Bot's proprietary host source is not included or required in the repository.

### What you need

- For Mac: macOS 12+ on Apple silicon and Xcode Command Line Tools, including Swift and `codesign`
- For Windows: Windows 11 x64 or Arm64, Git Bash, PowerShell, Node.js 22.12+, and Inno Setup 6 for a native Setup executable
- Node.js 18 or newer and Python 3 for the shared runtime development suite

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

The app and checksum file appear in `build/`. A local source build is ad-hoc signed for your own Mac.

Build a Windows ZIP from macOS or Windows, or build the native Setup executable on Windows:

```bash
npm run test:windows
npm run build:windows -- x64
npm run build:windows -- arm64
```

The Windows CI job runs on Windows Server, requires both Inno Setup artifacts, and uploads x64 and Arm64 ZIPs plus checksums. Authenticode signing is optional for private source builds. A public release must set `ROUTER_WINDOWS_REQUIRE_SIGNING=1` with its certificate variables; that mode fails closed before packaging if either credential is missing.

If the packaged installer UI or delivery mechanism fails, start with these files:

| Area to change | Source |
| --- | --- |
| Mac installer | `installer/GrokBotRouterInstaller.swift` |
| Mac packaging | `scripts/build-macos-app.sh` |
| Windows installer | `installer-windows/` |
| Windows packaging and signing | `scripts/build-windows-app.sh`, `scripts/build-windows-setup.ps1`, `scripts/sign-windows.ps1` |
| Files delivered into the Bot computer | `scripts/build-payload.sh`, `remote/install.sh` |
| Exact supported Grok build | `patch/manifests/0.30.0.json`, `patch/router_patch.py` |
| Provider behavior | `runtime/run-provider.mjs` |
| Required proof before calling a build usable | `docs/FRESH-BOT-ACCEPTANCE.md`, `docs/TEST-MATRIX.md` |

Building the source yourself can fix packaging, signing, UI, or machine-specific delivery problems. It does **not** automatically support a different Grok Bot release. A new Grok version needs a new exact manifest, a reviewed transformation, all tests, and the complete live install → restore → reinstall → fresh-Bot acceptance cycle.

Personal, non-commercial source builds are allowed. Redistribution is not. See [the license](LICENSE.md).

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

Type these into Grok Bot's normal composer. The installer publishes user-invocable skill descriptors for `/provider`, `/models`, `/model`, `/reasoning`, `/router`, and `/doctor`, so Grok can list the real commands in its native slash-suggestion menu. The skills only provide discovery; the router runtime still handles every recognized command deterministically before model inference. If a user skill already owns one of those names, installation preserves it and Doctor reports the conflict instead of overwriting it.

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
| `/doctor` | Short alias for `/router doctor` |
| `/router help` | Show the command reference |

Invalid or near-miss model controls return bounded help instead of becoming model prompts.

## Everything in the system

| Component | Source | Responsibility |
| --- | --- | --- |
| macOS installer | `installer/GrokBotRouterInstaller.swift` | Native Swift UI, app/version gate, loopback diagnostics, Vision OCR, noVNC transport, install, Doctor, repair, and restore |
| App identity | `installer/Info.plist`, `installer/Assets/` | GrokRouter name, mascot, and macOS icon resources |
| Payload builder | `scripts/build-payload.sh` | Creates the small checksummed archive sent into the Bot computer |
| Source installer | `scripts/install-macos.sh`, `Install GrokRouter.command` | Builds locally, verifies the app, and installs it without `sudo` |
| Mac builder | `scripts/build-macos-app.sh` | Produces the native app, optional ZIP, and SHA-256 file |
| Windows installer | `installer-windows/` | Sandboxed Electron UI, signed-app/version gate, loopback diagnostics, Tesseract OCR, install, Doctor, repair, and restore |
| Windows builder | `scripts/build-windows-app.sh` | Produces x64/Arm64 apps, clean ZIPs, native Inno Setup executables on Windows, checksums, and optional Authenticode signatures |
| Remote bootstrap | `remote/install.sh` | Idempotently installs pinned dependencies, config, CLI, runtime, patch, and watchdog inside the Bot computer |
| Slash discovery skills | `skills/` | Publish the deterministic router controls through Grok's user-invocable skill menu without replacing conflicting user skills |
| Management CLI | `remote/grokbot-router` | Status, enable, disable, repair, Doctor, and verified stock uninstall |
| Lifecycle watchdog | `remote/grokbot-router-watchdog` | Rate-limited repair when Grok replaces the live host with a known stock build; never repairs an unknown build or intentional restore |
| Compatibility manifests | `patch/manifests/` | Exact Grok version, stock-host SHA-256 allowlist, size, and required source anchors |
| Patch engine | `patch/router_patch.py` | Original transformation, syntax check, atomic activation, verified backup, dry run, and restore |
| Provider runtime | `runtime/run-provider.mjs` | Controls, stable Bot identity, per-Bot state, replay protection, Codex/OpenRouter adapters, tool conversion, and redacted audit |
| Provider defaults | `runtime/provider.default.json` | Packaged provider/model catalog and installer defaults—never credentials |
| Automated tests | `tests/` | Runtime behavior, patch/restore, payload integrity, and native installer contracts |
| CI | `.github/workflows/ci.yml` | Runs the Mac suite/build and native Windows x64/Arm64 package builds on every push and pull request |
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

`npm test` covers the provider runtime, patch/restore engine, complete payload install, and native installer contracts.

Build outputs go under `build/`:

```text
grokrouter-<version>-macos.zip
grokrouter-<version>-macos.zip.sha256
grokrouter-<version>-windows-x64.zip
grokrouter-<version>-windows-x64.zip.sha256
grokrouter-<version>-windows-arm64.zip
grokrouter-<version>-windows-arm64.zip.sha256
grokrouter-<version>-windows-<arch>-setup.exe   # native Windows build
```

Local Mac builds are ad-hoc signed for the Mac that built them. Windows source and CI artifacts are unsigned unless an Authenticode certificate is supplied; explicit Windows release mode fails closed without one. GrokRouter does not ask viewers to bypass Gatekeeper or Windows signature warnings.

Coding agents must begin with [AGENTS.md](AGENTS.md). It defines the authoritative files, protected safety boundaries, verification commands, and fresh-Bot acceptance gate.

## Release truth

Beta.39 fixed the lifecycle case where Grok replaced the live host while leaving the router runtime and config installed. It adds an exact-gated watchdog, explicit Repair action, bounded JPEG installer screenshots, and the redesigned GrokRouter Mac app.

The exact local macOS beta.39 artifact reinstalled successfully and a genuinely new Bot passed `/router doctor` and `/provider`. The restored Windows x64 and Arm64 applications build and checksum successfully from current source, but have not yet passed a native Windows install → restore → reinstall → fresh-Bot cycle. Full OpenRouter computer/sub-agent parity is not claimed when Grok supplies no actionable outer-tool schemas.

See [Release Notes](RELEASE_NOTES.md), [Test Matrix](docs/TEST-MATRIX.md), and the dated [Independent Review](docs/INDEPENDENT-REVIEW-2026-08-29.md) for the evidence behind every claim.

## Documentation

- [How it works, without the jargon](docs/HOW-IT-WORKS.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Fresh-Bot acceptance gate](docs/FRESH-BOT-ACCEPTANCE.md)
- [Verification matrix](docs/TEST-MATRIX.md)
- [Security and trust boundary](SECURITY.md)
- [Source-build and release procedure](docs/RELEASE.md)
- [OpenGrok comparison](docs/OPENGROK-COMPARISON.md)
- [YouTube demo runbook](docs/YOUTUBE-DEMO.md)
- [Editable 16:9 architecture diagram](docs/diagrams/grokbot-router-end-to-end.svg)
- [4K architecture export](docs/diagrams/grokbot-router-end-to-end-4k.png)

## Current scope

GrokRouter is deliberately narrow. Adding another Grok Bot version requires inspecting the untouched stock host, recording its exact hash and size, confirming every patch anchor exactly once, running the complete automated suite, and completing the live install → restore → reinstall → fresh-Bot gate on each claimed platform.

Never add a wildcard hash. Never ship a development override. Never call a preview verified.

---

<p align="center">
  <strong>GrokRouter</strong> · Beta by Prompt Advisers<br>
  The official Grok Bot stays in charge. You choose the model.
</p>
