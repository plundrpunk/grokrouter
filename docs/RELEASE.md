# Source-build release procedure

GrokRouter is distributed as public source for Apple silicon Macs. Viewers build the native app locally instead of downloading an unsigned binary. The canonical repository is <https://github.com/promptadvisers/grokrouter>.

## Viewer installation paths

The README offers two equivalent paths:

1. Paste the one-line command that downloads and runs `scripts/install-macos.sh`.
2. Download the repository ZIP and double-click `Install GrokRouter.command`.

Both paths compile the same checked-in Swift source, ad-hoc sign the resulting local app, verify it, install it to `~/Applications/GrokRouter.app`, and open it. Neither path needs `sudo`, a DMG, a distributed binary, or an Apple Developer certificate.

If Xcode Command Line Tools are missing, macOS opens Apple's installer. The viewer finishes that installation and runs the GrokRouter command again.

## Release checklist

1. Confirm the official Grok Bot version is still exactly 0.30.0.
2. Update version fields and release notes.
3. Run `npm ci --prefix runtime --ignore-scripts --no-audit --no-fund`.
4. Run `npm test`.
5. Run `npm run build:macos`.
6. Run `bash -n scripts/install-macos.sh "Install GrokRouter.command"`.
7. Test `Install GrokRouter.command` from a clean repository ZIP on an Apple silicon Mac.
8. Complete install → restore → reinstall with the exact build.
9. Create a genuinely new Bot and complete `docs/FRESH-BOT-ACCEPTANCE.md`.
10. Record the result in `docs/TEST-MATRIX.md`, commit, and wait for green CI.

## Compatibility changes

If Grok Bot updates, refusal is the expected behavior. Do not edit a version string or hash merely to get past the gate. Inspect the untouched stock host, add an exact reviewed manifest, run every automated check, and repeat the complete live gate before claiming support.

## Optional signed distribution later

A signed and notarized ZIP can be added later without changing the source installer. That is a separate release path and requires a Developer ID Application certificate, notarization credentials, checksum verification, Gatekeeper acceptance, and a fresh-machine live gate. Until those conditions are met, do not publish an unsigned downloadable app or ask viewers to bypass Gatekeeper.
