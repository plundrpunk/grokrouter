import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const main = await readFile(new URL("../installer-windows/main.cjs", import.meta.url), "utf8");
const preload = await readFile(new URL("../installer-windows/preload.cjs", import.meta.url), "utf8");
const renderer = await readFile(new URL("../installer-windows/renderer.js", import.meta.url), "utf8");
const html = await readFile(new URL("../installer-windows/index.html", import.meta.url), "utf8");
const build = await readFile(new URL("../scripts/build-windows-app.sh", import.meta.url), "utf8");
const payloadBuild = await readFile(new URL("../scripts/build-payload.sh", import.meta.url), "utf8");
const signing = await readFile(new URL("../scripts/sign-windows.ps1", import.meta.url), "utf8");
const setup = await readFile(new URL("../scripts/build-windows-setup.ps1", import.meta.url), "utf8");
const releaseWorkflow = await readFile(new URL("../.github/workflows/release.yml", import.meta.url), "utf8");

test("Windows installer keeps the exact compatibility and local-only gates", () => {
  assert.match(main, /SUPPORTED_GROK_VERSION = "0\.30\.0"/);
  assert.match(main, /metadata\.Status !== "Valid"/);
  assert.match(main, /127\.0\.0\.1:\$\{CDP_PORT\}/);
  assert.match(main, /--remote-debugging-address=127\.0\.0\.1/);
  assert.doesNotMatch(main, /ROUTER_ALLOW_UNKNOWN_HOST/);
  assert.doesNotMatch(main, /shell:\s*true/);
});

test("Windows installer preserves verified terminal transport and restore", () => {
  for (const marker of [
    "GROKBOT_ROUTER_TRANSPORT_OK",
    "GROKBOT_ROUTER_INSTALL_OK",
    "GROKBOT_ROUTER_DOCTOR_DONE",
    "GROKBOT_ROUTER_REPAIR_OK",
    "GROKBOT_ROUTER_UNINSTALL_OK",
  ]) assert.match(main, new RegExp(marker));
  assert.match(main, /emitted % 8 === 0/);
  assert.match(main, /format: "jpeg"/);
  assert.match(main, /quality: 55/);
  assert.match(main, /sha256sum -c -/);
  assert.match(main, /typeRemoteCommandsResilient/);
});

test("Windows renderer is isolated from Node and never stores the OpenRouter key", () => {
  assert.match(main, /contextIsolation: true/);
  assert.match(main, /nodeIntegration: false/);
  assert.match(main, /sandbox: true/);
  assert.match(preload, /contextBridge\.exposeInMainWorld/);
  assert.match(renderer, /elements\.openRouterKey\.value = ""/);
  assert.doesNotMatch(renderer, /localStorage|sessionStorage/);
  assert.match(html, /type="password"/);
  assert.match(html, /Content-Security-Policy/);
  assert.match(html, /connect-src 'none'/);
  assert.match(html, /Bring your own model\./);
  assert.doesNotMatch(html, /Bring your own brain\./);
  assert.match(html, /GROK BOT 0\.30\.0/);
  assert.doesNotMatch(html, /PRIVATE BETA/);
});

test("Windows packaging covers both official architectures", () => {
  assert.match(build, /"x64" && "\$ARCH" != "arm64"/);
  assert.match(build, /GrokRouter\.exe/);
  assert.match(build, /windows-\$\{ARCH\}\.zip/);
  assert.match(build, /data:image\/png;base64/);
  assert.match(build, /Windows mascot marker must occur exactly once/);
  assert.match(build, /windows-\$\{ARCH\}-setup\.exe/);
  assert.match(build, /ROUTER_WINDOWS_REQUIRE_SETUP/);
  assert.match(build, /command -v 7z/);
  assert.match(setup, /Inno Setup 6/);
  assert.match(setup, /DefaultDirName=\{localappdata\}\\Programs\\GrokRouter/);
  assert.match(setup, /Name: "\{autoprograms\}\\GrokRouter"/);
  assert.match(setup, /Description: "Open GrokRouter"/);
  assert.match(build, /cd "\$PROJECT_ROOT" && node -p/);
  assert.match(payloadBuild, /cd "\$PROJECT_ROOT" && node -p/);
  assert.match(build, /command -v sha256sum/);
  assert.match(payloadBuild, /command -v sha256sum/);
  assert.match(build, /basename "\$ZIP_PATH"/);
  assert.match(payloadBuild, /basename "\$ARCHIVE"/);
  assert.doesNotMatch(build, /require\('\$PROJECT_ROOT\/package\.json'\)/);
  assert.doesNotMatch(payloadBuild, /require\('\$PROJECT_ROOT\/package\.json'\)/);
});

test("public releases fail closed without Authenticode credentials", () => {
  assert.match(build, /ROUTER_WINDOWS_SIGN_PFX/);
  assert.match(signing, /signtool\.exe/);
  assert.match(signing, /\/tr "http:\/\/timestamp\.digicert\.com"/);
  assert.match(signing, /verify \/pa \/all/);
  assert.match(releaseWorkflow, /WINDOWS_CODESIGN_PFX_BASE64/);
  assert.match(releaseWorkflow, /PUBLIC_RELEASE_TOKEN/);
  assert.match(releaseWorkflow, /promptadvisers\/grokrouter-downloads/);
  assert.match(releaseWorkflow, /include_windows/);
  assert.match(releaseWorkflow, /needs: \[macos, windows\]/);
});
