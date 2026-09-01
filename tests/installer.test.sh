#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n \
  "$PROJECT_ROOT/remote/install.sh" \
  "$PROJECT_ROOT/remote/grokbot-router" \
  "$PROJECT_ROOT/remote/grokbot-router-watchdog" \
  "$PROJECT_ROOT/scripts/build-payload.sh" \
  "$PROJECT_ROOT/scripts/build-macos-app.sh" \
  "$PROJECT_ROOT/scripts/install-macos.sh" \
  "$PROJECT_ROOT/Install GrokRouter.command"
python3 -m py_compile "$PROJECT_ROOT/patch/router_patch.py"
node --check "$PROJECT_ROOT/runtime/run-provider.mjs"

STRUCTURED_FAILURE="$(ROUTER_INSTALL_ATTEMPT=TEST1234 bash "$PROJECT_ROOT/remote/install.sh" --not-a-real-option 2>&1 || true)"
grep -q 'GROKROUTER_TEST1234_INSTALL_FAILED_OPTIONS_UNKNOWN_OPTION' <<<"$STRUCTURED_FAILURE"
PREFLIGHT_FAILURE="$(PATH=/usr/bin:/bin:/sbin ROUTER_INSTALL_ATTEMPT=PREF123 bash "$PROJECT_ROOT/remote/install.sh" --no-restart 2>&1 || true)"
grep -q 'GROKROUTER_PREF123_PHASE_PREFLIGHT' <<<"$PREFLIGHT_FAILURE"
grep -q 'GROKROUTER_PREF123_INSTALL_FAILED_PREFLIGHT_MISSING_COMMAND' <<<"$PREFLIGHT_FAILURE"
/usr/bin/swiftc \
  -swift-version 5 \
  -target arm64-apple-macosx12.0 \
  -typecheck \
  -framework AppKit \
  -framework Vision \
  -framework CryptoKit \
  "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"

grep -q 'typeRemoteCommandsResilient' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'let timeout = DispatchWorkItem' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'task.cancel(with: .goingAway' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'local diagnostic connection stopped responding' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
[[ "$(grep -c 'Target.detachFromTarget' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift")" -eq 2 ]]
grep -q 'Reuse an already open computer' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'let transportVNC = try await typeRemoteCommandsResilient' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'ensureTerminal' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'resetRemotePrompt' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'typeRemoteCommand("clear"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'key: "c", code: "KeyC"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Opening Terminal from the Bot desktop dock' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'clickRemoteDesktop' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q "import('./app/ui.js')" "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'UI.rfb._handleMouseButton' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'UI.rfb.sendKey' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'emitted % 8 === 0' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'setTimeout(resolve, 4)' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'did not accept noVNC text input' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
! grep -q 'Input.insertText' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'did not accept a noVNC pointer event' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'remoteX: 700, remoteY: 768' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'waitForTerminalPrompt(client, vncSession: vncSession, attempts: 24)' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'request.recognitionLevel = .accurate' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
[[ "$(grep -c 'waitForTerminalPrompt(client, vncSession: vncSession, attempts: 24)' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift")" -eq 2 ]]
grep -q "getElementById('noVNC_container')" "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q "getElementById('noVNC_canvas')" "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'framebufferWidth = Number(canvas?.width) || 1280' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'framebufferHeight = Number(canvas?.height) || 800' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'return JSON.stringify' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -Fq 'x: rect.left + (\(remoteX) / framebufferWidth) * rect.width' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -Fq 'y: rect.top + (\(remoteY) / framebufferHeight) * rect.height' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'payload.b64' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'only completion authority' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
! grep -q 'GROKBOT_ROUTER_COMMAND_ACCEPTED' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'installPayload.*base64EncodedString' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'installAttempt: installAttempt' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'INSTALLFAILED' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Copy safe diagnostics' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Try installation again' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Open support issue' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'installation-failure.yml' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Action needed' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'confirmationSentinel: "Welcome to Codex"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'confirmationSentinel: "GROKBOT_ROUTER_DOCTOR_DONE"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'confirmationSentinel: "GROKBOT_ROUTER_REPAIR_OK"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'native-workflow-registration' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'updateNativeWorkflows' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'GROKROUTER_NATIVE_COMMAND' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'app.workflows.install' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'app.workflows.update' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'app.workflows.remove' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'agent.id === selectedAgentId' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'waitForSelectedAgentId' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'selection can be superseded' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'workflowReadyTimeoutMs = 45_000' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'remove duplicate' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'withRetries' "$PROJECT_ROOT/installer/native-workflow-registration.js"
grep -q 'stats.unchanged' "$PROJECT_ROOT/installer/native-workflow-registration.js"
if grep -q 'Promise.all(agents' "$PROJECT_ROOT/installer/native-workflow-registration.js"; then
  echo "Native workflows must be reconciled once through Grok Bot's global library" >&2
  exit 1
fi
grep -q 'private let repairButton' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Bring your own model.' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
! grep -q 'Bring your own brain.' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'labelWithString: "GROK BOT 0.30.0"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
! grep -q 'PRIVATE BETA' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -Fq 'contentRect: NSRect(x: 0, y: 0, width: 780, height: 838)' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -Fq 'NSStackView(views: [hero, modelCard, installCard, statusCard, activityLabel, scroll])' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'InstallerCardView' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'window.title = "GrokRouter"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
[[ "$(grep -c '<string>GrokRouter</string>' "$PROJECT_ROOT/installer/Info.plist")" -eq 2 ]]
grep -Fq 'APP_ROOT="$BUILD_ROOT/GrokRouter.app"' "$PROJECT_ROOT/scripts/build-macos-app.sh"
grep -q 'grokrouter-native-skills' "$PROJECT_ROOT/scripts/build-macos-app.sh"
grep -Fq 'ZIP_PATH="$BUILD_ROOT/grokrouter-${VERSION}-macos.zip"' "$PROJECT_ROOT/scripts/build-macos-app.sh"
grep -q 'ROUTER_BUILD_APP_ONLY' "$PROJECT_ROOT/scripts/build-macos-app.sh"
! grep -q 'DMG_PATH\|hdiutil create' "$PROJECT_ROOT/scripts/build-macos-app.sh"
grep -q 'GROKROUTER_APPLICATIONS_DIR' "$PROJECT_ROOT/scripts/install-macos.sh"
grep -q 'GROKROUTER_NO_OPEN' "$PROJECT_ROOT/scripts/install-macos.sh"
grep -q 'xcode-select --install' "$PROJECT_ROOT/scripts/install-macos.sh"
grep -q 'SOURCE_REF="source-v0.1.0-beta.44"' "$PROJECT_ROOT/scripts/install-macos.sh"
grep -q 'source-v0.1.0-beta.44/scripts/install-macos.sh' "$PROJECT_ROOT/README.md"
grep -q 'codesign --verify --deep --strict' "$PROJECT_ROOT/scripts/install-macos.sh"
! grep -q 'sudo' "$PROJECT_ROOT/scripts/install-macos.sh"
grep -q 'CFBundleIconFile' "$PROJECT_ROOT/installer/Info.plist"
[[ -f "$PROJECT_ROOT/installer/Assets/AppIcon.icns" ]]
grep -q '"format": "jpeg"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q '"quality": 55' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'isValidOpenRouterKey' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'previousSelection' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'relaunchGrokNormallyIfNeeded' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Closing the temporary diagnostic port' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'completion marker before the host restart' "$PROJECT_ROOT/remote/install.sh"
grep -q 'GROKROUTER_%s_PHASE_%s' "$PROJECT_ROOT/remote/install.sh"
grep -q 'GROKROUTER_%s_INSTALL_FAILED_%s_%s' "$PROJECT_ROOT/remote/install.sh"
grep -q -- '--fetch-retries=3' "$PROJECT_ROOT/remote/install.sh"
grep -q -- '--fetch-timeout=30000' "$PROJECT_ROOT/remote/install.sh"
grep -q 'Reusing the already verified pinned Codex runtime' "$PROJECT_ROOT/remote/install.sh"
grep -q 'OpenRouter-only setup needs no dependency download' "$PROJECT_ROOT/remote/install.sh"
grep -q 'await import("@openai/codex-sdk")' "$PROJECT_ROOT/runtime/run-provider.mjs"
grep -q '"X-Title": "GrokRouter"' "$PROJECT_ROOT/runtime/run-provider.mjs"
! grep -q 'Prompt Advisers\|promptadvisers.com' "$PROJECT_ROOT/runtime/run-provider.mjs"
grep -q '<string>io.grokrouter.installer</string>' "$PROJECT_ROOT/installer/Info.plist"
grep -q 'Copyright 2026 Mark Kashef' "$PROJECT_ROOT/LICENSE.md"
! grep -q 'Prompt Advisers' "$PROJECT_ROOT/LICENSE.md" "$PROJECT_ROOT/runtime/package.json" "$PROJECT_ROOT/runtime/package-lock.json" "$PROJECT_ROOT/installer-windows/package.json" "$PROJECT_ROOT/scripts/build-windows-setup.ps1" "$PROJECT_ROOT"/skills/*/SKILL.md
[[ -f "$PROJECT_ROOT/.github/ISSUE_TEMPLATE/installation-failure.yml" ]]
grep -q 'Emit the restore sentinel before the delayed host restart' "$PROJECT_ROOT/remote/grokbot-router"
grep -q 'sleep 3; pkill -f' "$PROJECT_ROOT/remote/grokbot-router"
grep -q 'known-stock-host-repaired' "$PROJECT_ROOT/remote/grokbot-router-watchdog"
grep -q '"autoRepair": True' "$PROJECT_ROOT/remote/install.sh"
grep -q '/home/box/sand-data/grokbot-router-backup/host-main.cjs.stock' "$PROJECT_ROOT/remote/install.sh"
grep -q '/usr/local/bin/grokbot-router' "$PROJECT_ROOT/remote/install.sh"
grep -q 'sudo -n ln -sfn' "$PROJECT_ROOT/remote/install.sh"
grep -q '"@openai/codex-sdk": "0.151.0"' "$PROJECT_ROOT/runtime/package.json"

ARCHIVE="$(bash "$PROJECT_ROOT/scripts/build-payload.sh")"
[[ -f "$ARCHIVE" ]]
[[ -f "$ARCHIVE.sha256" ]]
shasum -a 256 -c "$ARCHIVE.sha256" >/dev/null

TEMPORARY="$(mktemp -d -t grokbot-router-test.XXXXXX)"
cleanup() {
  rm -rf "$TEMPORARY"
}
trap cleanup EXIT
tar -xzf "$ARCHIVE" -C "$TEMPORARY"
PAYLOAD="$TEMPORARY/grokbot-router-payload"
(cd "$PAYLOAD" && shasum -a 256 -c SHA256SUMS >/dev/null)
[[ "$(cat "$PAYLOAD/VERSION")" == "$(node -p "require('$PROJECT_ROOT/package.json').version")" ]]
PAYLOAD_VERSION="$(cat "$PAYLOAD/VERSION")"
grep -Fq "const ROUTER_VERSION = \"$PAYLOAD_VERSION\";" "$PAYLOAD/runtime/run-provider.mjs"
grep -Fq "ROUTER_VERSION=\"$PAYLOAD_VERSION\"" "$PAYLOAD/remote/install.sh"
grep -Fq "version: \"$PAYLOAD_VERSION\"" "$PAYLOAD/patch/router_patch.py"
for skill_name in provider models model reasoning router doctor; do
  [[ -f "$PAYLOAD/skills/$skill_name/SKILL.md" ]]
  grep -q '^user-invocable: true$' "$PAYLOAD/skills/$skill_name/SKILL.md"
  grep -q '^disable-model-invocation: true$' "$PAYLOAD/skills/$skill_name/SKILL.md"
  grep -q "^GROKROUTER_NATIVE_CONTROL: $(printf '%s' "$skill_name" | tr '[:lower:]' '[:upper:]')$" "$PAYLOAD/skills/$skill_name/SKILL.md"
done

HOST_FIXTURE="$PROJECT_ROOT/tests/fixtures/host-main.cjs"
TEST_HOST="$TEMPORARY/host-main.cjs"
TEST_BACKUP="$TEMPORARY/host-main.cjs.stock"
TEST_RUNTIME="$TEMPORARY/runtime"
TEST_BIN="$TEMPORARY/bin"
TEST_GROK_SKILLS="$TEMPORARY/grok-skills"
cp "$HOST_FIXTURE" "$TEST_HOST"
mkdir -p "$TEST_RUNTIME"
printf '%s\n' '{"provider":"openrouter","openRouterModels":["openai/gpt-5.2","legacy/removed-model"]}' > "$TEST_RUNTIME/provider.json"
ROUTER_PATCH_HOST="$TEST_HOST" \
ROUTER_PATCH_BACKUP="$TEST_BACKUP" \
ROUTER_ALLOW_UNKNOWN_HOST=1 \
ROUTER_BIN_DIR="$TEST_BIN" \
ROUTER_GROK_SKILLS_ROOT="$TEST_GROK_SKILLS" \
ROUTER_INSTALL_ATTEMPT=SUCCESS44 \
bash "$PAYLOAD/remote/install.sh" \
  --install-root "$TEST_RUNTIME" \
  --provider codex \
  --providers codex,openrouter \
  --no-restart \
  >"$TEMPORARY/install-success.log"

for phase in PREFLIGHT VALIDATE_PAYLOAD PREPARE_RUNTIME INSTALL_DEPENDENCIES ACTIVATE_RUNTIME APPLY_ADAPTER VERIFY_INSTALL COMPLETE; do
  grep -q "GROKROUTER_SUCCESS44_PHASE_$phase" "$TEMPORARY/install-success.log"
done

grep -q 'GROKBOT_MODEL_ROUTER_V45' "$TEST_HOST"
grep -q 'appendGrokBotRouterHostError' "$TEST_HOST"
grep -q 'getGrokBotRouterChildEnv' "$TEST_HOST"
[[ -x "$TEST_RUNTIME/node_modules/.bin/codex" ]]
[[ -L "$TEST_BIN/grokbot-router" ]]
[[ -x "$TEST_RUNTIME/bin/grokbot-router-watchdog" ]]
for skill_name in provider models model reasoning router doctor; do
  [[ ! -e "$TEST_GROK_SKILLS/$skill_name" && ! -L "$TEST_GROK_SKILLS/$skill_name" ]]
done
ln -s "$TEST_RUNTIME/skills/provider" "$TEST_GROK_SKILLS/provider"
mkdir "$TEST_GROK_SKILLS/reasoning"
printf 'user-owned\n' > "$TEST_GROK_SKILLS/reasoning/KEEP"
"$TEST_BIN/grokbot-router" status | grep -q 'Default provider: codex'
python3 - "$TEST_RUNTIME/provider.json" <<'PY'
import json
import sys

config = json.load(open(sys.argv[1]))
assert "openai/gpt-5.2" not in config["openRouterModels"]
assert "legacy/removed-model" not in config["openRouterModels"]
assert config["openRouterModels"] == [
    "anthropic/claude-sonnet-4.6",
    "openai/gpt-5.6-sol",
    "openai/gpt-5.6-terra",
    "openai/gpt-5.6-luna",
    "google/gemini-3.1-pro-preview",
    "google/gemini-3.1-flash-lite",
]
PY
python3 - "$TEST_RUNTIME/provider.json" <<'PY'
import json
import sys

path = sys.argv[1]
config = json.load(open(path))
config.update({
    "provider": "openrouter",
    "providers": ["openrouter"],
    "openRouterModel": "openai/gpt-5.6-luna",
})
with open(path, "w") as output:
    json.dump(config, output)
PY
ROUTER_PATCH_HOST="$TEST_HOST" \
ROUTER_PATCH_BACKUP="$TEST_BACKUP" \
ROUTER_ALLOW_UNKNOWN_HOST=1 \
ROUTER_BIN_DIR="$TEST_BIN" \
ROUTER_GROK_SKILLS_ROOT="$TEST_GROK_SKILLS" \
bash "$PAYLOAD/remote/install.sh" \
  --install-root "$TEST_RUNTIME" \
  --providers codex,openrouter \
  --no-restart \
  >"$TEMPORARY/install-reuse.log"
grep -q 'Reusing the already verified pinned Codex runtime' "$TEMPORARY/install-reuse.log"
"$TEST_BIN/grokbot-router" status | grep -q 'Default provider: openrouter'
"$TEST_BIN/grokbot-router" status | grep -q 'OpenRouter model: openai/gpt-5.6-luna'
grep -q 'user-owned' "$TEST_GROK_SKILLS/reasoning/KEEP"
[[ ! -e "$TEST_GROK_SKILLS/provider" && ! -L "$TEST_GROK_SKILLS/provider" ]]
python3 "$TEST_RUNTIME/patch/router_patch.py" \
  --restore \
  --allow-unknown-host \
  --host "$TEST_HOST" \
  --backup "$TEST_BACKUP" \
  --manifest "$TEST_RUNTIME/patch/manifests/0.30.0.json" \
  --json \
  >/dev/null
cmp "$HOST_FIXTURE" "$TEST_HOST"

ROUTER_PATCH_HOST="$TEST_HOST" \
ROUTER_PATCH_BACKUP="$TEST_BACKUP" \
ROUTER_ALLOW_UNKNOWN_HOST=1 \
ROUTER_WATCHDOG_ENABLED=0 \
"$TEST_BIN/grokbot-router" repair >/dev/null
grep -q 'GROKBOT_MODEL_ROUTER_V45' "$TEST_HOST"

ROUTER_PATCH_HOST="$TEST_HOST" \
ROUTER_PATCH_BACKUP="$TEST_BACKUP" \
ROUTER_ALLOW_UNKNOWN_HOST=1 \
ROUTER_WATCHDOG_ENABLED=0 \
ROUTER_GROK_SKILLS_ROOT="$TEST_GROK_SKILLS" \
"$TEST_BIN/grokbot-router" uninstall >/dev/null
cmp "$HOST_FIXTURE" "$TEST_HOST"
for skill_name in provider models model router doctor; do
  [[ ! -e "$TEST_GROK_SKILLS/$skill_name" && ! -L "$TEST_GROK_SKILLS/$skill_name" ]]
done
grep -q 'user-owned' "$TEST_GROK_SKILLS/reasoning/KEEP"

printf 'Installer and payload checks passed.\n'
