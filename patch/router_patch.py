#!/usr/bin/env python3
"""Version-gated, reversible Grok Bot host adapter patch.

This file contains only an original transformation. It never bundles or copies
Grok Bot's host source into the project or release payload.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from typing import Any


MARKER = "GROKBOT_MODEL_ROUTER_V37"
LEGACY_MARKER = re.compile(r"(?:GROK_SDK_ADAPTER_V[1-8]|GROKBOT_MODEL_ROUTER_V(?:9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31))")
DEFAULT_HOST = Path("/home/box/sand-host/host-main.cjs")
DEFAULT_BACKUP = Path("/home/box/sand-data/grokbot-router-backup/host-main.cjs.stock")
LEGACY_BACKUPS = (
    Path("/home/box/sand-host/host-main.cjs.grokbot-router.stock"),
    Path("/home/box/sand-host/host-main.cjs.grok-sdk-adapter.prepatch"),
)
DEFAULT_MANIFEST = Path(__file__).with_name("manifests") / "0.30.0.json"


EXECUTOR_CODE = r'''
// GROKBOT_MODEL_ROUTER_V37: version-gated Codex SDK and OpenRouter executor.
function loadGrokBotRouterConfig() {
  const configPath = "/home/box/sand-data/grokbot-router/provider.json";
  try {
    const config = JSON.parse(require("node:fs").readFileSync(configPath, "utf8"));
    if (!config || config.enabled !== true) return void 0;
    return config;
  } catch (error) {
    console.error("[grokbot-router] Config unavailable; using stock inference:", error?.message || error);
    return void 0;
  }
}
function serializeGrokBotRouterTools(tools) {
  const candidates = Array.isArray(tools)
    ? tools
    : tools && typeof tools === "object"
      ? Object.values(tools)
      : [];
  return candidates.slice(0, 128).flatMap((tool) => {
    if (!tool || typeof tool !== "object") return [];
    const name = typeof tool.name === "string"
      ? tool.name.trim()
      : typeof tool.function?.name === "string"
        ? tool.function.name.trim()
        : "";
    if (!name) return [];
    const rawParameters = tool.parameters?.jsonSchema
      ?? tool.inputSchema?.jsonSchema
      ?? tool.inputSchema
      ?? tool.parameters
      ?? tool.function?.parameters;
    let parameters = { type: "object", additionalProperties: true };
    if (rawParameters && typeof rawParameters === "object") {
      try {
        parameters = JSON.parse(JSON.stringify(rawParameters));
      } catch {}
    }
    const description = typeof tool.description === "string"
      ? tool.description
      : typeof tool.function?.description === "string"
        ? tool.function.description
        : "";
    return [{ name, description, parameters }];
  });
}
function getGrokBotRouterSendToolName(tools) {
  const names = serializeGrokBotRouterTools(tools).map((tool) => tool.name);
  // SendToUser is Grok Bot's canonical terminal-delivery tool. Its turn
  // runtime treats similarly named aliases as silent work and launches a
  // redundant closing nudge, which renders as an empty/ellipsis reply.
  for (const name of ["SendToUser", "SendMessage", "SendUser"]) {
    if (names.includes(name)) return name;
  }
  return "SendToUser";
}
function getGrokBotRouterChildEnv() {
  const names = [
    "PATH", "HOME", "USER", "LOGNAME", "SHELL", "LANG", "LC_ALL", "TERM",
    "XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME", "CODEX_HOME",
    "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
    "SSL_CERT_FILE", "NODE_EXTRA_CA_CERTS", "OPENROUTER_API_KEY"
  ];
  return Object.fromEntries(names.flatMap((name) => (
    typeof process.env[name] === "string" ? [[name, process.env[name]]] : []
  )));
}
function appendGrokBotRouterHostError(config, error) {
  try {
    const diagnostic = String(error?.message || error || "Unknown host bridge error")
      .replace(/sk-or-v1-[a-z0-9_-]+|sk-[a-z0-9_-]+|gh[opsu]_[a-z0-9_-]+/gi, "[REDACTED]")
      .replace(/\s+/g, " ")
      .slice(0, 500);
    const auditPath = config?.auditPath || "/home/box/sand-data/grokbot-router/audit.jsonl";
    require("node:fs").appendFileSync(auditPath, `${JSON.stringify({
      timestamp: new Date().toISOString(),
      version: "0.1.0-beta.41",
      event: "host_bridge_error",
      diagnostic
    })}\n`, { encoding: "utf8", mode: 0o600 });
  } catch {}
}
function runGrokBotRouter(config, messages, tools, sessionOptions) {
  return new Promise((resolve, reject) => {
    const runnerPath = config.runnerPath || "/home/box/sand-data/grokbot-router/run-provider.mjs";
    const nodePath = config.nodePath || "/usr/bin/node";
    const timeoutMs = Math.max(1000, Number(config.timeoutMs || 900000));
    const child = require("node:child_process").spawn(nodePath, [runnerPath], {
      cwd: config.workingDirectory || "/workspace",
      env: getGrokBotRouterChildEnv(),
      stdio: ["pipe", "pipe", "pipe"]
    });
    const stdout = [];
    const stderr = [];
    let stdoutBytes = 0;
    let stderrBytes = 0;
    let settled = false;
    let forceKillTimer;
    const finish = (callback) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      callback();
    };
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      forceKillTimer = setTimeout(() => child.kill("SIGKILL"), 2000);
      forceKillTimer.unref?.();
      finish(() => reject(new Error(`Provider exceeded ${timeoutMs}ms`)));
    }, timeoutMs);
    child.on("error", (error) => finish(() => reject(error)));
    child.stdin.on("error", (error) => {
      if (error?.code !== "EPIPE") finish(() => reject(error));
    });
    child.stdout.on("data", (chunk) => {
      stdoutBytes += chunk.length;
      if (stdoutBytes <= 20 * 1024 * 1024) stdout.push(chunk);
    });
    child.stderr.on("data", (chunk) => {
      stderrBytes += chunk.length;
      if (stderrBytes <= 2 * 1024 * 1024) stderr.push(chunk);
    });
    child.on("close", (code, signal) => {
      if (forceKillTimer) clearTimeout(forceKillTimer);
      finish(() => {
      const output = Buffer.concat(stdout).toString("utf8");
      const diagnostic = Buffer.concat(stderr).toString("utf8");
      if (code !== 0 || signal) {
        reject(new Error(`Provider exited with ${signal || `code ${code}`}: ${diagnostic.slice(-4000)}`));
        return;
      }
      let payload;
      try {
        payload = JSON.parse(output);
      } catch {
        reject(new Error(`Provider returned invalid JSON: ${output.slice(-1000)}`));
        return;
      }
      if (!payload?.ok || typeof payload.text !== "string") {
        reject(new Error(payload?.error || "Provider returned no response"));
        return;
      }
      resolve(payload);
      });
    });
    child.stdin.end(JSON.stringify({
      config,
      messages,
      tools: serializeGrokBotRouterTools(tools),
      sessionOptions
    }));
  });
}
var GrokBotRouterPromptExecutor = class extends MockPromptExecutor {
  constructor(config, sessionOptions, initialMessages) {
    super(() => ({ response: "", chunkSize: 1 }), initialMessages);
    this.config = config;
    this.sessionOptions = sessionOptions;
  }
  stream(ctx, invocationId, tools, options) {
    const messages = this.builder.getMessages();
    const resultPromise = runGrokBotRouter(this.config, messages, tools, this.sessionOptions)
      .catch((error) => {
        console.error("[grokbot-router] Provider turn failed:", error?.stack || error);
        appendGrokBotRouterHostError(this.config, error);
        return {
          text: "Model Router error. Open this Bot's computer and run grokbot-router doctor for a private diagnostic.",
          toolCalls: [],
          usage: { inputTokens: 0, outputTokens: 0, cacheReadTokens: 0, cacheWriteTokens: 0 },
          bridgeError: true
        };
      });
    const delegatedPromise = resultPromise.then((result) => {
      const providerToolCalls = Array.isArray(result.toolCalls) ? result.toolCalls : [];
      if (result.alreadyDelivered) {
        const delegate = new MockPromptExecutor(() => ({
          response: "",
          toolCalls: []
        }), messages);
        return delegate.stream(ctx, invocationId, tools, options);
      }
      const fallbackToolCalls = providerToolCalls.length > 0 ? [] : [{
        toolCallId: `grokbot-router-send-${require("node:crypto").randomUUID()}`,
        toolName: getGrokBotRouterSendToolName(tools),
        args: { type: "text", content: result.text }
      }];
      const delegate = new MockPromptExecutor(() => ({
        // A response chunk and a tool call in the same mock turn can cause Grok
        // to deliver the text and skip execution. Tool turns stay silent until
        // Grok returns the tool result and the provider produces final text.
        response: "",
        toolCalls: providerToolCalls.length > 0 ? providerToolCalls : fallbackToolCalls,
        chunkSize: 256,
        streamDelay: 0,
        usage: {
          inputTokens: Number(result.usage?.inputTokens || 0),
          outputTokens: Number(result.usage?.outputTokens || 0),
          cacheReadTokens: Number(result.usage?.cacheReadTokens || 0),
          cacheWriteTokens: Number(result.usage?.cacheWriteTokens || 0),
          maxTokens: 0
        }
      }), messages);
      return delegate.stream(ctx, invocationId, tools, options);
    });
    const fullStream = async function* () {
      const delegated = await delegatedPromise;
      for await (const part of delegated.fullStream) yield part;
    }();
    return {
      fullStream,
      response: delegatedPromise.then((delegated) => delegated.response),
      usage: delegatedPromise.then((delegated) => delegated.usage),
      extendedUsage: delegatedPromise.then((delegated) => delegated.extendedUsage),
      providerMetadata: delegatedPromise.then((delegated) => delegated.providerMetadata),
      invocationId: delegatedPromise.then((delegated) => delegated.invocationId)
    };
  }
};
function createGrokBotRouterPromptExecutor(config, sessionOptions) {
  return new GrokBotRouterPromptExecutor(config, sessionOptions, void 0);
}
'''.strip()


SESSION_CODE = r'''
      // GROKBOT_MODEL_ROUTER_V37: route enabled sessions through the provider adapter.
      const grokBotRouterConfig = loadGrokBotRouterConfig();
      if (grokBotRouterConfig) {
        const provider = grokBotRouterConfig.provider === "openrouter" ? "openrouter" : "codex";
        const modelId = provider === "openrouter"
          ? grokBotRouterConfig.openRouterModel || "anthropic/claude-sonnet-4.6"
          : grokBotRouterConfig.codexModel || "gpt-5.6-sol";
        return {
          getExecutor: () => createGrokBotRouterPromptExecutor(grokBotRouterConfig, sessionOptions),
          getModelId: () => modelId
        };
      }
'''.rstrip()


class PatchError(RuntimeError):
    """Raised for safe, user-actionable patch failures."""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        manifest = json.loads(path.read_text())
    except Exception as error:
        raise PatchError(f"Cannot read compatibility manifest {path}: {error}") from error
    expected = manifest.get("stockHostSha256")
    if not isinstance(expected, list) or not all(isinstance(item, str) for item in expected):
        raise PatchError("Compatibility manifest has no valid stockHostSha256 list")
    return manifest


def is_allowed_stock(path: Path, manifest: dict[str, Any]) -> bool:
    return path.exists() and sha256(path) in set(manifest["stockHostSha256"])


def validate_anchors(source: str, manifest: dict[str, Any]) -> None:
    for anchor in manifest.get("requiredAnchors", []):
        count = source.count(anchor)
        if count != 1:
            raise PatchError(f"Host anchor count for {anchor!r} was {count}; expected 1")


def patch_text(source: str) -> str:
    if MARKER in source:
        return source
    if LEGACY_MARKER.search(source):
        raise PatchError("Legacy adapter detected; restore the verified stock backup before patching")

    executor_pattern = re.compile(
        r"(function createMockPromptExecutor\(options2\) \{\n"
        r"\s+return new MockPromptExecutor\(\(\) => options2\(\), void 0\);\n"
        r"\})"
    )
    source, executor_count = executor_pattern.subn(
        lambda match: f"{match.group(1)}\n{EXECUTOR_CODE}", source, count=1
    )
    if executor_count != 1:
        raise PatchError(f"Executor anchor count was {executor_count}; expected 1")

    session_pattern = re.compile(
        r"(createSession\(onRequestId, sessionOptions\) \{\n\s+)"
        r"(const mockResponse = process\.env\.SAND_AGENT_MOCK_RESPONSE;)"
    )
    source, session_count = session_pattern.subn(
        lambda match: f"{match.group(1)}{SESSION_CODE.lstrip()}\n\n      {match.group(2)}",
        source,
        count=1,
    )
    if session_count != 1:
        raise PatchError(f"Session anchor count was {session_count}; expected 1")

    return source


def syntax_check(path: Path) -> None:
    result = subprocess.run(["node", "--check", str(path)], capture_output=True, text=True)
    if result.returncode:
        raise PatchError(result.stderr.strip() or result.stdout.strip() or "node --check failed")


def timestamp_backup(path: Path, label: str) -> Path:
    destination = path.with_name(f"{path.name}.grokbot-router.{label}.{int(time.time() * 1000)}.bak")
    shutil.copy2(path, destination)
    backups = sorted(
        path.parent.glob(f"{path.name}.grokbot-router.*.bak"),
        key=lambda candidate: candidate.stat().st_mtime_ns,
        reverse=True,
    )
    for stale in backups[4:]:
        stale.unlink(missing_ok=True)
    return destination


def verified_stock_source(
    host: Path,
    backup: Path,
    manifest: dict[str, Any],
    allow_unknown: bool,
) -> Path:
    if host.exists() and MARKER not in host.read_text(errors="replace") and not LEGACY_MARKER.search(host.read_text(errors="replace")):
        if allow_unknown or is_allowed_stock(host, manifest):
            return host
    for candidate in (backup, *LEGACY_BACKUPS):
        if candidate.exists() and (allow_unknown or is_allowed_stock(candidate, manifest)):
            return candidate
    host_hash = sha256(host) if host.exists() else "missing"
    raise PatchError(
        "No verified stock Grok Bot host is available. "
        f"Current host SHA-256: {host_hash}. Supported app version: {manifest.get('grokBotVersion')}."
    )


def install(
    host: Path,
    backup: Path,
    manifest: dict[str, Any],
    dry_run: bool,
    allow_unknown: bool,
) -> dict[str, Any]:
    if not host.exists():
        raise PatchError(f"Host not found: {host}")
    current = host.read_text()
    if MARKER in current:
        return {
            "ok": True,
            "status": "already-installed",
            "host": str(host),
            "hostSha256": sha256(host),
        }
    stock = verified_stock_source(host, backup, manifest, allow_unknown)
    source = stock.read_text()
    validate_anchors(source, manifest)
    patched = patch_text(source)
    if MARKER not in patched:
        raise PatchError("Patched host is missing the router marker")
    if dry_run:
        return {
            "ok": True,
            "status": "dry-run",
            "stock": str(stock),
            "stockSha256": sha256(stock),
            "stockBytes": len(source),
            "patchedBytes": len(patched),
        }

    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        shutil.copy2(stock, backup)
    previous = timestamp_backup(host, "before-install")
    temporary = host.with_name(f"{host.name}.grokbot-router.tmp.cjs")
    temporary.write_text(patched)
    os.chmod(temporary, host.stat().st_mode)
    syntax_check(temporary)
    os.replace(temporary, host)
    return {
        "ok": True,
        "status": "installed",
        "host": str(host),
        "hostSha256": sha256(host),
        "stockBackup": str(backup),
        "previousBackup": str(previous),
    }


def restore(
    host: Path,
    backup: Path,
    manifest: dict[str, Any],
    dry_run: bool,
    allow_unknown: bool,
) -> dict[str, Any]:
    if not backup.exists():
        for legacy in LEGACY_BACKUPS:
            if legacy.exists() and (allow_unknown or is_allowed_stock(legacy, manifest)):
                backup.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(legacy, backup)
                break
    if not backup.exists():
        raise PatchError(f"Verified stock backup not found: {backup}")
    if not allow_unknown and not is_allowed_stock(backup, manifest):
        raise PatchError(f"Stock backup hash is not allowed: {sha256(backup)}")
    if dry_run:
        return {"ok": True, "status": "restore-dry-run", "stockBackup": str(backup)}
    previous = timestamp_backup(host, "before-restore") if host.exists() else None
    temporary = host.with_name(f"{host.name}.grokbot-router.restore.tmp.cjs")
    shutil.copy2(backup, temporary)
    syntax_check(temporary)
    os.replace(temporary, host)
    return {
        "ok": True,
        "status": "restored",
        "host": str(host),
        "hostSha256": sha256(host),
        "previousBackup": str(previous) if previous else None,
    }


def doctor(
    host: Path,
    backup: Path,
    manifest: dict[str, Any],
    allow_unknown: bool = False,
) -> dict[str, Any]:
    host_exists = host.exists()
    backup_exists = backup.exists()
    host_text = host.read_text(errors="replace") if host_exists else ""
    return {
        "ok": bool(
            host_exists
            and MARKER in host_text
            and backup_exists
            and (allow_unknown or is_allowed_stock(backup, manifest))
        ),
        "status": "installed" if MARKER in host_text else "stock-or-unknown",
        "routerMarker": MARKER in host_text,
        "legacyMarker": bool(LEGACY_MARKER.search(host_text)),
        "host": str(host),
        "hostSha256": sha256(host) if host_exists else None,
        "stockBackup": str(backup),
        "stockBackupSha256": sha256(backup) if backup_exists else None,
        "stockBackupVerified": is_allowed_stock(backup, manifest),
        "developmentOverride": allow_unknown,
        "supportedVersion": manifest.get("grokBotVersion"),
    }


def human_print(result: dict[str, Any]) -> None:
    for key, value in result.items():
        print(f"{key}: {value}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Install or restore the GrokRouter host adapter")
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--restore", action="store_true", help="restore the verified stock host")
    action.add_argument("--doctor", action="store_true", help="inspect installation health")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--allow-unknown-host", action="store_true", help="development only")
    parser.add_argument("--host", type=Path, default=DEFAULT_HOST)
    parser.add_argument("--backup", type=Path, default=DEFAULT_BACKUP)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    if args.doctor:
        result = doctor(args.host, args.backup, manifest, args.allow_unknown_host)
    elif args.restore:
        result = restore(args.host, args.backup, manifest, args.dry_run, args.allow_unknown_host)
    else:
        result = install(args.host, args.backup, manifest, args.dry_run, args.allow_unknown_host)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        human_print(result)
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
