import assert from "node:assert/strict";
import test from "node:test";

import {
  classifyRisk,
  evaluateGate,
  labelsAfterClassification,
} from "../scripts/pr_policy/policy.mjs";

const changed = (filename, additions = 1, deletions = 0) => ({ filename, additions, deletions });

test("documentation-only changes are low risk", () => {
  assert.equal(classifyRisk([changed("RELEASE_NOTES.md"), changed("docs/HOW-IT-WORKS.md")]).risk, "risk:low");
});

test("tests and skills require normal review", () => {
  assert.equal(classifyRisk([changed("tests/runtime.test.mjs")]).risk, "risk:normal");
  assert.equal(classifyRisk([changed("skills/router/SKILL.md")]).risk, "risk:normal");
});

test("runtime, installer, dependency, agent, and workflow changes are high risk", () => {
  for (const filename of [
    "runtime/run-provider.mjs",
    "installer/GrokBotRouterInstaller.swift",
    "runtime/package-lock.json",
    "AGENTS.md",
    "README.md",
    "SECURITY.md",
    "docs/RELEASE.md",
    ".github/workflows/ci.yml",
  ]) {
    assert.equal(classifyRisk([changed(filename)]).risk, "risk:high", filename);
  }
});

test("large changes are high risk even outside sensitive paths", () => {
  assert.equal(classifyRisk([changed("tests/large.test.mjs", 501)]).risk, "risk:high");
  assert.equal(
    classifyRisk(Array.from({ length: 21 }, (_, index) => changed(`tests/${index}.test.mjs`))).risk,
    "risk:high",
  );
});

test("classification replaces a manual risk downgrade", () => {
  assert.deepEqual(
    labelsAfterClassification(["bug", "risk:low", "risk:normal"], "risk:high", "labeled"),
    ["bug", "risk:high"],
  );
});

test("new commits clear both approval labels", () => {
  assert.deepEqual(
    labelsAfterClassification(
      ["risk:high", "reviewed-ok", "human-approved", "bug"],
      "risk:high",
      "synchronize",
    ),
    ["bug", "risk:high"],
  );
});

test("high-risk changes require a human-applied approval", () => {
  const base = { draft: false, labels: ["risk:high"], computedRisk: "risk:high" };
  assert.match(evaluateGate(base).errors.join(" "), /requires the human-approved label/);
  assert.match(
    evaluateGate({
      ...base,
      labels: ["risk:high", "human-approved"],
      approvalActor: { type: "Bot", login: "github-actions[bot]" },
    }).errors.join(" "),
    /must be applied by a human/,
  );
  assert.deepEqual(
    evaluateGate({
      ...base,
      labels: ["risk:high", "human-approved"],
      approvalActor: { type: "User", login: "maintainer" },
    }).errors,
    [],
  );
});

test("normal changes require reviewed-ok from a human", () => {
  assert.deepEqual(
    evaluateGate({
      draft: false,
      labels: ["risk:normal", "reviewed-ok"],
      computedRisk: "risk:normal",
      approvalActor: { type: "User", login: "maintainer" },
    }).errors,
    [],
  );
});

test("ambiguous, mismatched, and draft states stay blocked", () => {
  assert.match(
    evaluateGate({ draft: false, labels: ["risk:low", "risk:high"], computedRisk: "risk:high" }).errors.join(" "),
    /Exactly one risk label/,
  );
  assert.match(
    evaluateGate({ draft: false, labels: ["risk:low"], computedRisk: "risk:high" }).errors.join(" "),
    /does not match computed risk/,
  );
  assert.match(
    evaluateGate({ draft: true, labels: ["risk:low"], computedRisk: "risk:low" }).errors.join(" "),
    /Draft pull requests/,
  );
});
