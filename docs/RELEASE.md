# Source-build release procedure

GrokRouter is distributed as public source for Apple silicon Macs. Viewers build the native app locally instead of downloading an unsigned binary. The canonical repository is <https://github.com/promptadvisers/grokrouter>.

## Viewer installation paths

The README offers two equivalent paths from a checkout whose origin and exact commit the user has verified:

1. Run `scripts/install-macos.sh` from Terminal.
2. Download the repository ZIP and double-click `Install GrokRouter.command`.

Both paths compile the same checked-in Swift source, ad-hoc sign the resulting local app, verify it, install it to `~/Applications/GrokRouter.app`, and open it. The installer never downloads replacement source. Neither path needs `sudo`, a DMG, a distributed binary, or an Apple Developer certificate.

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

If Grok Bot updates its app version, refusal is the expected behavior. Do not edit a version string merely to get past the gate. Inspect the untouched stock host, add an exact reviewed manifest, run every automated check, and repeat the complete live gate before claiming support.

Rotating 0.30.0 host builds behind the same app version remain unsupported until their exact SHA-256 and byte count have been reviewed and added to the signed compatibility registry. Structural checks may explain why a host looks compatible, but they never authorize mutation.

## Updating the 0.30.0 signed host registry

Grok may rotate the Bot-computer host while the Mac app still reports 0.30.0. Every accepted variant requires a signed registry entry.

1. Collect the complete safe report. It must contain both SHA halves, byte count, cloud architecture, four anchor counts, and `PATCHDRYRUN=PASS`.
2. Inspect the untouched stock host through the approved read-only process. Never ask a reporter to post proprietary host source.
3. Add only the exact reviewed `{ "sha256", "bytes" }` pair to `compatibility/0.30.0-hosts.json`.
4. Sign it from the repository root:

   ```bash
   node scripts/sign-host-registry.mjs
   ```

   The private Ed25519 key lives outside the workspace at `~/.config/grokrouter/release/host-registry-private.pem` by default. Never print, copy, or commit it.
5. Run `npm test`, verify the signature and tamper-rejection tests, then complete the exact live repair and genuinely-new-Bot acceptance gate for that host before describing it as supported.
6. Commit and publish the registry JSON and signature together. Existing installations verify the signature before accepting the new exact entry.

Changing source anchors, the patch transformation, Grok Bot version, or signing key is not a registry-only update. It requires a new installer release and the full release gate.

## Optional signed distribution later

A signed and notarized ZIP can be added later without changing the source installer. That is a separate release path and requires a Developer ID Application certificate, notarization credentials, checksum verification, Gatekeeper acceptance, and a fresh-machine live gate. Until those conditions are met, do not publish an unsigned downloadable app or ask viewers to bypass Gatekeeper.
