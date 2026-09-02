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
    def test_released_stock_hashes_keep_their_verified_byte_counts(self):
        manifest = router_patch.load_manifest(PROJECT_ROOT / "patch" / "manifests" / "0.30.0.json")
        pairs = {item["sha256"]: item["bytes"] for item in manifest["stockHosts"]}
        self.assertEqual(
            pairs["3364e421402302f8264f961637addb3997a817fde84a91b19635a0c28ff3941f"],
            25656693,
        )

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
                    "stockHosts": [{"sha256": digest, "bytes": self.host.stat().st_size}],
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
            self.host, self.backup, self.manifest, dry_run=False
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
            self.host, self.backup, self.manifest, dry_run=False
        )
        self.assertEqual(second["status"], "already-installed")

        self.host.write_text(self.host.read_text() + "// tampered after install\n")
        tampered_doctor = router_patch.doctor(self.host, self.backup, self.manifest)
        self.assertFalse(tampered_doctor["ok"])
        self.assertFalse(tampered_doctor["hostPatchVerified"])
        repaired = router_patch.install(
            self.host, self.backup, self.manifest, dry_run=False
        )
        self.assertEqual(repaired["status"], "installed")
        self.assertTrue(router_patch.doctor(self.host, self.backup, self.manifest)["ok"])

        restored = router_patch.restore(
            self.host, self.backup, self.manifest, dry_run=False
        )
        self.assertEqual(restored["status"], "restored")
        self.assertEqual(self.host.read_text(), STOCK_SOURCE)

    def test_unknown_host_is_rejected_without_development_override(self):
        self.host.write_text(STOCK_SOURCE + "// changed\n")
        report = router_patch.inspect_host(self.host, self.manifest)
        self.assertEqual(report["patchDryRun"], "pass")
        self.assertTrue(all(len(line) < 80 for line in router_patch.compatibility_report(self.host, self.manifest).splitlines()))
        with self.assertRaisesRegex(router_patch.PatchError, "HOSTSHA1="):
            router_patch.install(
                self.host, self.backup, self.manifest, dry_run=True
            )

    def test_exact_hash_with_wrong_size_is_rejected(self):
        digest = hashlib.sha256(self.host.read_bytes()).hexdigest()
        self.manifest["stockHosts"] = [{"sha256": digest, "bytes": self.host.stat().st_size + 1}]
        with self.assertRaises(router_patch.PatchError):
            router_patch.install(
                self.host, self.backup, self.manifest, dry_run=True
            )

    def test_signed_registry_can_extend_exact_hash_and_size_pairs(self):
        self.host.write_text(STOCK_SOURCE + "// compatible variant\n")
        digest = hashlib.sha256(self.host.read_bytes()).hexdigest()
        registry_path = Path(self.temporary.name) / "registry.json"
        registry_path.write_text(json.dumps({
            "schemaVersion": 1,
            "grokBotVersion": "test",
            "stockHosts": [{"sha256": digest, "bytes": self.host.stat().st_size}],
        }))
        registry = router_patch.load_host_registry(registry_path, self.manifest)
        result = router_patch.install(
            self.host,
            self.backup,
            self.manifest,
            dry_run=True,
            registry=registry,
        )
        self.assertEqual(result["status"], "dry-run")

    def enable_anchor_verification(self, min_bytes=0, max_bytes=0):
        self.manifest["anchorVerifiedHosts"] = router_patch.validate_anchor_policy(
            {"enabled": True, "minBytes": min_bytes, "maxBytes": max_bytes}
        )

    def test_shipped_manifest_keeps_structural_inspection_diagnostic_only(self):
        manifest = router_patch.load_manifest(PROJECT_ROOT / "patch" / "manifests" / "0.30.0.json")
        policy = manifest["anchorVerifiedHosts"]
        self.assertFalse(policy["enabled"])
        self.assertLessEqual(policy["minBytes"], 25656693)
        self.assertGreaterEqual(policy["maxBytes"], 26377223)

    def test_structurally_compatible_variant_never_authorizes_mutation(self):
        self.enable_anchor_verification()
        variant = STOCK_SOURCE + "// rotated stock variant\n"
        self.host.write_text(variant)
        report = router_patch.inspect_host(self.host, self.manifest)
        self.assertEqual(report["status"], "structurally-compatible-untrusted")
        self.assertIsNone(report["hostTrust"])
        self.assertFalse(report["ok"])
        self.assertEqual(report["patchDryRun"], "pass")
        self.assertIn("HOSTTRUST=NONE", router_patch.compatibility_report(self.host, self.manifest))

        with self.assertRaisesRegex(router_patch.PatchError, "HOSTSHA1="):
            router_patch.install(
                self.host, self.backup, self.manifest, dry_run=False
            )
        self.assertEqual(self.host.read_text(), variant)
        self.assertFalse(self.backup.exists())

    def test_structural_diagnostic_does_not_write_beside_unknown_host(self):
        self.enable_anchor_verification()
        self.host.write_text(STOCK_SOURCE + "// unknown variant\n")
        before = {path.name for path in self.host.parent.iterdir()}
        verdict = router_patch.anchor_verification(self.host, self.manifest)
        after = {path.name for path in self.host.parent.iterdir()}
        self.assertTrue(verdict["ok"])
        self.assertEqual(after, before)

    def test_backup_follows_the_live_stock_variant(self):
        self.enable_anchor_verification()
        self.backup.write_text(STOCK_SOURCE + "// older variant\n")
        variant = STOCK_SOURCE + "// newer variant\n"
        self.host.write_text(variant)
        with self.assertRaises(router_patch.PatchError):
            router_patch.install(self.host, self.backup, self.manifest, dry_run=False)
        self.assertNotEqual(self.backup.read_text(), variant)

    def test_anchor_verification_rejects_foreign_router_and_size_band(self):
        self.enable_anchor_verification()
        self.host.write_text(STOCK_SOURCE + "// OpenGrok adapter installed here\n")
        verdict = router_patch.anchor_verification(self.host, self.manifest)
        self.assertFalse(verdict["ok"])
        self.assertIn("another router", verdict["reason"])
        with self.assertRaisesRegex(router_patch.PatchError, "another router"):
            router_patch.install(self.host, self.backup, self.manifest, dry_run=True)

        self.host.write_text(STOCK_SOURCE + "// tiny\n")
        self.enable_anchor_verification(min_bytes=10_000_000, max_bytes=20_000_000)
        verdict = router_patch.anchor_verification(self.host, self.manifest)
        self.assertFalse(verdict["ok"])
        self.assertIn("smaller than expected", verdict["reason"])
        self.assertEqual(verdict["patchDryRun"], "pass")
        with self.assertRaisesRegex(router_patch.PatchError, "HOSTTRUST=NONE"):
            router_patch.install(self.host, self.backup, self.manifest, dry_run=True)

    def test_anchor_verification_is_off_unless_the_manifest_enables_it(self):
        self.host.write_text(STOCK_SOURCE + "// changed\n")
        verdict = router_patch.anchor_verification(self.host, self.manifest)
        self.assertFalse(verdict["ok"])
        self.assertEqual(verdict["patchDryRun"], "pass")
        self.assertIn("disabled", verdict["reason"])
        self.assertIsNone(router_patch.host_trust(self.host, self.manifest))

    def test_missing_or_duplicate_anchor_is_rejected(self):
        self.host.write_text(STOCK_SOURCE.replace("function createMockPromptExecutor", "function wrong"))
        self.assertEqual(router_patch.inspect_host(self.host, self.manifest)["patchDryRun"], "fail")
        digest = hashlib.sha256(self.host.read_bytes()).hexdigest()
        self.manifest["stockHosts"] = [{"sha256": digest, "bytes": self.host.stat().st_size}]
        with self.assertRaises(router_patch.PatchError):
            router_patch.install(
                self.host, self.backup, self.manifest, dry_run=True
            )


if __name__ == "__main__":
    unittest.main()
