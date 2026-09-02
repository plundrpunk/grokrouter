# Repository governance

The `main` branch is protected by required pull requests and required status checks. Pull requests merge by squash through GitHub's native auto-merge only after the policy below is satisfied.

## Risk labels

The `pr-risk-classifier` job owns exactly one risk label on every pull request:

- `risk:low`: documentation-only changes. No additional approval label is required.
- `risk:normal`: tests, skills, or ordinary project metadata. A human must apply `reviewed-ok`.
- `risk:high`: runtime, installer, patching, compatibility, dependency, script, or GitHub workflow changes; also changes larger than 20 files or 500 changed lines. A human must apply `human-approved`.

The classifier removes `reviewed-ok` and `human-approved` whenever new commits are pushed. The approval must be applied again after reviewing the latest commit.

## Merge behavior

The `pr-merge-gate` job verifies that the computed risk label is unambiguous and that any required approval label was applied by a human GitHub user. The `pr-automerge` job queues eligible pull requests for a squash merge. GitHub completes that merge only after all branch-rule checks pass.

The protected branch rejects deletion and force pushes, requires pull requests, and allows squash merges only. The required checks are the macOS test/build, Windows test/build, dependency audit and review, CodeQL analysis, risk classifier, and merge gate.
