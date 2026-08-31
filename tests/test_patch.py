import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "router_patch", PROJECT_ROOT / "patch" / "router_patch.py"
)
router_patch = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(router_patch)


STOCK_SOURCE = """\
class MockPromptExecutor {
  constructor(factory, messages) {}
}
function createMockPromptExecutor(options2) {
  return new MockPromptExecutor(() => options2(), void 0);
}
class Host {
  createSession(onRequestId, sessionOptions) {
      const mockResponse = process.env.SAND_AGENT_MOCK_RESPONSE;
      return mockResponse;
  }
}
function runInference(host) {
  const boxId = host.resolveBoxId();
  const rawTranscriptText = "@Research Bot /provider";
  const mainSessionOptions = {
          modelId: host.subagentModelId,
          isSubagent: host.isSubagentRunner,
  };
  return mainSessionOptions;
}
function buildResult(host, finalAssistantText, sentMessageCount) {
  return {
    ...!host.isSubagentRunner ? { finalAssistantText } : {},
  };
}
"""


class RouterPatchTests(unittest.TestCase):
    def test_default_stock_backup_survives_host_directory_replacement(self):
        self.assertEqual(
            router_patch.DEFAULT_BACKUP,
            Path("/home/box/sand-data/grokbot-router-backup/host-main.cjs.stock"),
        )
        self.assertIn(
            Path("/home/box/sand-host/host-main.cjs.grokbot-router.stock"),
            router_patch.LEGACY_BACKUPS,
        )

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        root = Path(self.temporary.name)
        self.host = root / "host-main.cjs"
        self.backup = root / "host-main.cjs.grokbot-router.stock"
        self.manifest_path = root / "manifest.json"
        self.host.write_text(STOCK_SOURCE)
        digest = hashlib.sha256(self.host.read_bytes()).hexdigest()
        self.manifest_path.write_text(
            json.dumps(
                {
                    "grokBotVersion": "test",
                    "stockHostSha256": [digest],
                    "requiredAnchors": [
                        "function createMockPromptExecutor(options2)",
                        "createSession(onRequestId, sessionOptions)",
                        "const mockResponse = process.env.SAND_AGENT_MOCK_RESPONSE;",
                    ],
                }
            )
        )
        self.manifest = router_patch.load_manifest(self.manifest_path)

    def tearDown(self):
        self.temporary.cleanup()

    def test_install_doctor_idempotence_and_restore(self):
        result = router_patch.install(
            self.host, self.backup, self.manifest, dry_run=False, allow_unknown=False
        )
        self.assertEqual(result["status"], "installed")
        self.assertIn(router_patch.MARKER, self.host.read_text())
        self.assertNotIn("hasCompletedGrokBotRouterDelivery", self.host.read_text())
        self.assertIn('toolCallId: `grokbot-router-send-${', self.host.read_text())
        self.assertNotIn("latestGrokBotRouterUserText", self.host.read_text())
        self.assertNotIn("getGrokBotRouterTurnKey", self.host.read_text())
        self.assertNotIn("grokBotRouterCompletedTurns", self.host.read_text())
        self.assertNotIn("getGrokBotRouterSessionKey", self.host.read_text())
        self.assertNotIn("grokbot router delivery complete", self.host.read_text())
        self.assertNotIn("new SandRunAbortError", self.host.read_text())
        self.assertIn('for (const name of ["SendToUser", "SendMessage", "SendUser"])', self.host.read_text())
        self.assertIn('return "SendToUser";', self.host.read_text())
        self.assertIn('{ botId: typeof boxId === "string"', self.host.read_text())
        self.assertEqual(self.host.read_text().count('{ botId: typeof boxId === "string"'), 1)
        self.assertIn('grokBotRouterControlText: rawTranscriptText', self.host.read_text())
        self.assertNotIn('grokBotRouterReceiptReplay', self.host.read_text())
        self.assertEqual(self.backup.read_text(), STOCK_SOURCE)
        self.assertTrue(router_patch.doctor(self.host, self.backup, self.manifest)["ok"])

        second = router_patch.install(
            self.host, self.backup, self.manifest, dry_run=False, allow_unknown=False
        )
        self.assertEqual(second["status"], "already-installed")

        restored = router_patch.restore(
            self.host, self.backup, self.manifest, dry_run=False, allow_unknown=False
        )
        self.assertEqual(restored["status"], "restored")
        self.assertEqual(self.host.read_text(), STOCK_SOURCE)

    def test_unknown_host_is_rejected_without_development_override(self):
        self.host.write_text(STOCK_SOURCE + "// changed\n")
        with self.assertRaises(router_patch.PatchError):
            router_patch.install(
                self.host, self.backup, self.manifest, dry_run=True, allow_unknown=False
            )

    def test_missing_or_duplicate_anchor_is_rejected(self):
        self.host.write_text(STOCK_SOURCE.replace("function createMockPromptExecutor", "function wrong"))
        digest = hashlib.sha256(self.host.read_bytes()).hexdigest()
        self.manifest["stockHostSha256"] = [digest]
        with self.assertRaises(router_patch.PatchError):
            router_patch.install(
                self.host, self.backup, self.manifest, dry_run=True, allow_unknown=False
            )


if __name__ == "__main__":
    unittest.main()
