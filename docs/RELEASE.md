# Public release procedure

The implementation repository stays private. Viewer-facing binaries are published in `promptadvisers/grokrouter-downloads`, which also hosts the no-account download page at <https://promptadvisers.github.io/grokrouter-downloads/>.

The release workflow creates a **draft**, never an immediately public release. Publish only after the exact draft assets pass the clean-machine gate below.

## What viewers receive

| Platform | Primary download | User experience |
| --- | --- | --- |
| macOS 12+, Apple silicon | `grokrouter-<version>-macos.dmg` | Open DMG, drag GrokRouter to Applications, open it |
| Windows x64 | `grokrouter-<version>-windows-x64-setup.exe` | Run per-user installer, open GrokRouter from Start |
| Windows Arm64 | `grokrouter-<version>-windows-arm64-setup.exe` | Run per-user installer, open GrokRouter from Start |

ZIP files remain attached for diagnostics and advanced users. They are not the main YouTube call to action.

## Compatibility gate

1. Confirm the official Grok Bot app version on every release platform. Verify the macOS bundle and the signed Windows x64/Arm64 executable metadata.
2. Obtain the untouched host only for local verification; never commit or attach it.
3. Record its SHA-256 and confirm every required anchor occurs exactly once.
4. Run `npm ci --prefix runtime --ignore-scripts --no-audit --no-fund && npm test`.
5. Run the installer on a test Bot computer, verify the currently claimed Codex/OpenRouter behavior, and verify stock restore.
6. Update `docs/TEST-MATRIX.md` with the evidence and date.

## GitHub release access

Configure this Actions secret in the private source repository:

- `PUBLIC_RELEASE_TOKEN`

Use a fine-grained token scoped only to `promptadvisers/grokrouter-downloads` with **Contents: read and write**. It does not need access to the private source repository. The workflow uses it only to create the public repository's draft release and attach the signed artifacts.

## Apple signing secrets

Configure these Actions secrets in the private source repository:

- `APPLE_DEVELOPER_ID_P12_BASE64`
- `APPLE_DEVELOPER_ID_P12_PASSWORD`
- `APPLE_BUILD_KEYCHAIN_PASSWORD`
- `APPLE_NOTARY_APPLE_ID`
- `APPLE_NOTARY_APP_PASSWORD`
- `APPLE_TEAM_ID`

The Developer ID certificate must be a **Developer ID Application** certificate exported as password-protected PKCS#12. The Apple ID needs an app-specific password for notarization.

The macOS job signs the app, notarizes and staples it, creates a DMG containing GrokRouter plus an Applications alias, notarizes and staples the DMG, validates both tickets, and emits SHA-256 files. A missing credential fails the job before a draft can be created.

## Windows signing secrets

Configure these Actions secrets in the private source repository:

- `WINDOWS_CODESIGN_PFX_BASE64`
- `WINDOWS_CODESIGN_PFX_PASSWORD`

The Windows job signs and timestamp-verifies every packaged executable, builds the x64 and Arm64 Inno Setup installers, signs and verifies both setup files, and emits SHA-256 files. A missing certificate or setup compiler fails the job before a draft can be created.

## Prepare the draft

1. Update `package.json`, `runtime/package.json`, the runtime version constant, the patch version marker if necessary, `installer-windows/package.json`, lockfile root versions, and `RELEASE_NOTES.md`.
2. Commit a clean reviewed tree on `main` and wait for CI to pass.
3. Run **Prepare signed public release** in GitHub Actions. Leave **Include signed Windows preview installers** off for a Mac-first release. Turn it on only when both Windows signing secrets are configured and you intend to run the Windows gate.
4. Confirm a draft `v<version>` appears in `promptadvisers/grokrouter-downloads`. It should contain DMG, setup EXE, fallback ZIP, and SHA-256 files.

## Clean-machine release gate

Download the files from the draft itself. Do not substitute a local build or an Actions artifact.

On a second Apple-silicon Mac:

1. Verify the DMG checksum.
2. Confirm `spctl` accepts the DMG and app without an override.
3. Drag GrokRouter into Applications and launch it normally.
4. Complete install → restore → reinstall and the full fresh-Bot gate.

On real Windows x64 and Arm64 machines:

1. Verify each setup checksum.
2. Confirm Authenticode identifies Prompt Advisers and validates its timestamp.
3. Install without an administrator prompt, launch from Start, then uninstall and reinstall once.
4. Complete install → restore → reinstall and the full fresh-Bot gate.

Record every result in `docs/TEST-MATRIX.md`. A passing Mac run is not Windows evidence, and a portable ZIP pass is not a setup-installer pass.

## Publish

After every claim shown on the download page has passed:

1. Edit the draft release in `promptadvisers/grokrouter-downloads`.
2. Mark Windows clearly as preview if either architecture lacks its real-device gate. A Mac-first release should contain no Windows binaries at all.
3. Publish the release as the latest release.
4. Open <https://promptadvisers.github.io/grokrouter-downloads/> in a private browser window on Mac, Windows, and mobile. Confirm the primary button resolves to the expected latest asset without a GitHub account.
5. Use the download-page URL in the YouTube description. Do not link viewers to the private source repository, an Actions run, or an unsigned archive.

## A Grok Bot update

The expected behavior is refusal. Do not edit the version string or hash merely to get past the gate. Repeat the compatibility process, increment the router version, and publish a new signed release. Keep the previous manifest and patch tests so existing users retain a known restore path.
