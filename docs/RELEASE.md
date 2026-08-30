# Private release procedure

## Compatibility gate

1. Confirm the official Grok Bot app version on every release platform. Verify the macOS bundle and the signed Windows x64/Arm64 executable metadata.
2. Obtain the untouched host only for local verification; never commit or attach it.
3. Record its SHA-256 and confirm every required anchor occurs exactly once.
4. Run `npm ci --prefix runtime && npm test`.
5. Run the installer on a test Bot computer, verify Codex, OpenRouter, computer tool, sub-agent tool, and restore.
6. Update `docs/TEST-MATRIX.md` with evidence and date.

## Apple signing secrets

Configure these Actions secrets in the private Prompt Advisors repository:

- `APPLE_DEVELOPER_ID_P12_BASE64`
- `APPLE_DEVELOPER_ID_P12_PASSWORD`
- `APPLE_BUILD_KEYCHAIN_PASSWORD`
- `APPLE_NOTARY_APPLE_ID`
- `APPLE_NOTARY_APP_PASSWORD`
- `APPLE_TEAM_ID`

The Developer ID certificate must be an **Application** certificate exported as password-protected PKCS#12. The Apple ID needs an app-specific password for notarization.

## Windows signing secrets

Configure these Actions secrets before a Windows prerelease can be created:

- `WINDOWS_CODESIGN_PFX_BASE64`
- `WINDOWS_CODESIGN_PFX_PASSWORD`

The workflow fails closed when the Windows certificate is absent. It Authenticode-signs and timestamp-verifies both `GrokRouter.exe` architectures before archiving them. Local Windows packages remain unsigned development artifacts.

## Release

1. Update `package.json`, `runtime/package.json` if necessary, the runtime version constant, and `RELEASE_NOTES.md`.
2. Commit a clean, reviewed tree on `main` and wait for CI.
3. Run **Signed private release** in GitHub Actions.
4. Download the prerelease zips on a second Mac and real x64/Arm64 Windows machines. Confirm Gatekeeper and Windows signature verification accept them without an override.
5. On each platform, complete install → restore → reinstall and the full fresh-Bot gate, including `/router doctor`, text, computer, sub-agent, and restore tests.
6. Record each platform result in `docs/TEST-MATRIX.md`; a passing Mac run is not Windows evidence.
7. Share only the private release link. Do not distribute an ad-hoc or unsigned local build to viewers.

## A Grok Bot update

The expected behavior is refusal. Do not edit the version string/hash to get past the gate. Repeat the compatibility process, increment the router version, and ship a new signed release. Keep the previous manifest and patch tests so existing users retain a known restore path.
