#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n \
  "$PROJECT_ROOT/remote/install.sh" \
  "$PROJECT_ROOT/remote/grokbot-router" \
  "$PROJECT_ROOT/remote/grokbot-router-watchdog" \
  "$PROJECT_ROOT/scripts/build-payload.sh" \
  "$PROJECT_ROOT/scripts/build-macos-app.sh"
python3 -m py_compile "$PROJECT_ROOT/patch/router_patch.py"
node --check "$PROJECT_ROOT/runtime/run-provider.mjs"
/usr/bin/swiftc \
  -swift-version 5 \
  -target arm64-apple-macosx12.0 \
  -typecheck \
  -framework AppKit \
  -framework Vision \
  -framework CryptoKit \
  "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"

grep -q 'typeRemoteCommandsResilient' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Reuse an already open computer' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'let transportVNC = try await typeRemoteCommandsResilient' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'ensureTerminal' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'resetRemotePrompt' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
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
grep -q 'confirmationSentinel: "Welcome to Codex"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'confirmationSentinel: "GROKBOT_ROUTER_DOCTOR_DONE"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'confirmationSentinel: "GROKBOT_ROUTER_REPAIR_OK"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'private let repairButton' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Bring your own model.' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
! grep -q 'Bring your own brain.' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'labelWithString: "GROK BOT 0.30.0"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
! grep -q 'PRIVATE BETA' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -Fq 'contentRect: NSRect(x: 0, y: 0, width: 780, height: 790)' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -Fq 'NSStackView(views: [hero, modelCard, installCard, statusCard, activityLabel, scroll])' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'InstallerCardView' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'window.title = "GrokRouter"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
[[ "$(grep -c '<string>GrokRouter</string>' "$PROJECT_ROOT/installer/Info.plist")" -eq 2 ]]
grep -Fq 'APP_ROOT="$BUILD_ROOT/GrokRouter.app"' "$PROJECT_ROOT/scripts/build-macos-app.sh"
grep -Fq 'ZIP_PATH="$BUILD_ROOT/grokrouter-${VERSION}-macos.zip"' "$PROJECT_ROOT/scripts/build-macos-app.sh"
grep -q 'CFBundleIconFile' "$PROJECT_ROOT/installer/Info.plist"
[[ -f "$PROJECT_ROOT/installer/Assets/AppIcon.icns" ]]
grep -q '"format": "jpeg"' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q '"quality": 55' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'isValidOpenRouterKey' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'previousSelection' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'relaunchGrokNormallyIfNeeded' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'Closing the temporary diagnostic port' "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift"
grep -q 'completion marker before the host restart' "$PROJECT_ROOT/remote/install.sh"
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

HOST_FIXTURE="$PROJECT_ROOT/tests/fixtures/host-main.cjs"
TEST_HOST="$TEMPORARY/host-main.cjs"
TEST_BACKUP="$TEMPORARY/host-main.cjs.stock"
TEST_RUNTIME="$TEMPORARY/runtime"
TEST_BIN="$TEMPORARY/bin"
cp "$HOST_FIXTURE" "$TEST_HOST"
mkdir -p "$TEST_RUNTIME"
printf '%s\n' '{"provider":"openrouter","openRouterModels":["openai/gpt-5.2","legacy/removed-model"]}' > "$TEST_RUNTIME/provider.json"
ROUTER_PATCH_HOST="$TEST_HOST" \
ROUTER_PATCH_BACKUP="$TEST_BACKUP" \
ROUTER_ALLOW_UNKNOWN_HOST=1 \
ROUTER_BIN_DIR="$TEST_BIN" \
bash "$PAYLOAD/remote/install.sh" \
  --install-root "$TEST_RUNTIME" \
  --provider codex \
  --providers codex,openrouter \
  --no-restart \
  >/dev/null

grep -q 'GROKBOT_MODEL_ROUTER_V37' "$TEST_HOST"
grep -q 'appendGrokBotRouterHostError' "$TEST_HOST"
grep -q 'getGrokBotRouterChildEnv' "$TEST_HOST"
[[ -x "$TEST_RUNTIME/node_modules/.bin/codex" ]]
[[ -L "$TEST_BIN/grokbot-router" ]]
[[ -x "$TEST_RUNTIME/bin/grokbot-router-watchdog" ]]
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
bash "$PAYLOAD/remote/install.sh" \
  --install-root "$TEST_RUNTIME" \
  --no-restart \
  >/dev/null
"$TEST_BIN/grokbot-router" status | grep -q 'Default provider: openrouter'
"$TEST_BIN/grokbot-router" status | grep -q 'OpenRouter model: openai/gpt-5.6-luna'
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
grep -q 'GROKBOT_MODEL_ROUTER_V37' "$TEST_HOST"

printf 'Installer and payload checks passed.\n'
