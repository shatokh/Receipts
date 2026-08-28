# Phase 16a: Privacy-Reviewed E2E Receipt Fixture Corpus

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot C
- Fixture manifest: `docs/e2e_receipt_fixture_manifest_template.md`
- Status: superseded
- Last updated: 2026-08-27
- Replaced by: `phase_16e_dual_framework_redacted_pdf_pilots.md`
- Reason: its privacy gate and one-fixture scope are now executed together
  with the two comparable Patrol/Maestro scenarios, rather than as a separate
  prerequisite package.

## Scope

- Prepare a minimum safe corpus of two redacted real-format PDF fixtures: one short receipt and one longer receipt from a different month bucket.
- Record only opaque metadata and expected safe outcomes in a committed fixture manifest.
- Establish the fixture directory and asset registration only after each file passes review.
- Validate fixture readiness only on the verified local `it_api36` / `emulator-5554` baseline; do not introduce another device in this package.

## Non-goals

- Do not commit original receipts or retain a reversible mapping to the originals.
- Do not test parser fields, totals, or line-item content in device E2E.
- Do not add Patrol, Maestro, Android test code, or CI changes.

## Implementation Steps

1. The fixture owner redacts candidate documents outside the repository.
2. Review every PDF page against the manifest privacy checklist.
3. Add only approved derivatives under `assets/test/receipts/e2e/` with neutral file names.
4. Create the actual fixture manifest from the template and record structural expected outcomes.
5. Add the required `pubspec.yaml` asset entries when a selected E2E test needs them.
6. Verify Git status and test/log configuration contain no original or sensitive companion files.

## Affected Files

- `assets/test/receipts/e2e/*.pdf` only after approval
- `docs/e2e_receipt_fixture_manifest.md` created from the template
- `pubspec.yaml` only for selected Flutter asset access
- `.gitignore` if a safe local staging convention is needed

## Risks

| Risk | Mitigation |
| --- | --- |
| Redaction misses personal data. | Require page-by-page visual review before staging. |
| Tests reveal fixture details in failures. | Assert only structural outcomes and use opaque fixture IDs. |
| Too many fixtures create noise. | Require an intended scenario for each additional file. |

## Tests and Checks

- `git diff --check`
- Visual privacy review of every committed PDF page
- `flutter pub get` if `pubspec.yaml` changes
- Confirm E2E test output contains no fixture content, totals, dates, paths, or URIs

## Definition of Done

- [ ] Two approved fixtures exist: short/month_a and long/month_b.
- [ ] A non-sensitive manifest records their purpose and review status.
- [ ] Original documents and local staging copies are not tracked.
- [ ] The corpus is ready for Pilot C without adding sensitive assertions.
