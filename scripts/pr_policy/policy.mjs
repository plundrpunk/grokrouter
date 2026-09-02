export const RISK_LABELS = ["risk:low", "risk:normal", "risk:high"];
export const APPROVAL_LABELS = ["reviewed-ok", "human-approved"];

const isHighRiskPath = (filename) =>
  filename.startsWith(".github/") ||
  filename.startsWith("compatibility/") ||
  filename.startsWith("installer/") ||
  filename.startsWith("installer-windows/") ||
  filename.startsWith("patch/") ||
  filename.startsWith("remote/") ||
  filename.startsWith("runtime/") ||
  filename.startsWith("scripts/") ||
  filename === "AGENTS.md" ||
  filename === "Install GrokRouter.command" ||
  filename === "package.json" ||
  filename.endsWith("package-lock.json");

const isDocumentationPath = (filename) =>
  filename.startsWith("docs/") ||
  filename === "README.md" ||
  filename === "RELEASE_NOTES.md" ||
  filename === "SECURITY.md" ||
  filename === "LICENSE.md";

export function classifyRisk(files) {
  const totals = files.reduce(
    (sum, file) => ({
      additions: sum.additions + file.additions,
      deletions: sum.deletions + file.deletions,
      lines: sum.lines + file.additions + file.deletions,
    }),
    { additions: 0, deletions: 0, lines: 0 },
  );
  const highRiskFiles = files.filter((file) => isHighRiskPath(file.filename));
  let risk = "risk:normal";
  const reasons = [];

  if (files.length > 20 || totals.lines > 500) {
    risk = "risk:high";
    reasons.push(`large change (${files.length} files, ${totals.lines} changed lines)`);
  }
  if (highRiskFiles.length > 0) {
    risk = "risk:high";
    reasons.push(
      `security-sensitive paths: ${highRiskFiles.slice(0, 8).map((file) => file.filename).join(", ")}`,
    );
  }
  if (risk !== "risk:high" && files.length > 0 && files.every((file) => isDocumentationPath(file.filename))) {
    risk = "risk:low";
    reasons.push("documentation-only change");
  }
  if (reasons.length === 0) reasons.push("ordinary tests, skills, or project metadata change");

  return { risk, reasons, totals };
}

export function labelsAfterClassification(currentLabels, risk, action) {
  const nextLabels = currentLabels.filter((label) => !RISK_LABELS.includes(label));
  const withoutStaleApprovals =
    action === "synchronize"
      ? nextLabels.filter((label) => !APPROVAL_LABELS.includes(label))
      : nextLabels;
  return [...withoutStaleApprovals, risk];
}

export function requiredApprovalForRisk(risk) {
  if (risk === "risk:normal") return "reviewed-ok";
  if (risk === "risk:high") return "human-approved";
  return null;
}

export function evaluateGate({ draft, labels, computedRisk, approvalActor }) {
  const appliedRiskLabels = RISK_LABELS.filter((label) => labels.includes(label));
  const errors = [];

  if (draft) errors.push("Draft pull requests cannot merge.");
  if (appliedRiskLabels.length !== 1) {
    errors.push(`Exactly one risk label is required (${RISK_LABELS.join(", ")}).`);
  }

  const risk = appliedRiskLabels[0] ?? null;
  if (risk && risk !== computedRisk) {
    errors.push(`Applied risk ${risk} does not match computed risk ${computedRisk}.`);
  }
  const requiredApproval = requiredApprovalForRisk(risk);
  if (requiredApproval && !labels.includes(requiredApproval)) {
    errors.push(`${risk} requires the ${requiredApproval} label.`);
  } else if (
    requiredApproval &&
    (!approvalActor || approvalActor.type !== "User" || approvalActor.login.endsWith("[bot]"))
  ) {
    errors.push(`${requiredApproval} must be applied by a human GitHub user.`);
  }

  return { errors, risk, requiredApproval };
}
