# Phase 16e: Dual-Framework Redacted PDF Pilots

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot C
- Supersedes: the execution scope of `phase_16d_selected_framework_real_receipt_pilot.md`
- Status: blocked
- Last updated: 2026-08-28

## Goal

Add the same two native E2E scenarios to Patrol and Maestro, using one
privacy-approved synthetic real-format PDF fixture:

1. import the PDF through the real Android document picker and assert only a
   safe successful outcome;
2. import the same PDF again and assert the exact-duplicate outcome without
   creating another receipt.

The exercise compares framework ergonomics on a real native boundary and a
business invariant. It is not parser validation and must not expose fixture
contents.

## Scope

- Create one fully synthetic PDF under `assets/test/receipts/e2e/receipt_a.pdf`
  only after owner approval.
- Add a short privacy manifest with opaque fixture ID `receipt_a` and safe
  structural expectations only.
- Stage the approved derivative to `it_api36` using a generic device filename.
- Add the two scenarios to both Patrol and Maestro, with identical observable
  outcomes where their frameworks allow it.
- Add only durable outcome Semantics/selectors required by Maestro; retain
  Flutter `AppTestKeys` for Patrol where appropriate.

## Non-goals

- Do not use, copy, or upload the existing fiscal-named PDFs as test inputs
  until an owner has created and approved a derivative outside the repository.
- Do not commit an original, a reversible redaction, source-to-derivative map,
  address, NIP/VAT identifier, phone number, loyalty/card data, QR/barcode,
  receipt/order/terminal number, cashier, exact time, or real transaction data.
- Do not assert merchant, date, total, VAT, items, address, source URI, or
  file path in either framework's output.
- Do not add these native scenarios to CI or the coverage gate.
- Do not add a second fixture or month-isolation scenario in this package.

## Fixture Privacy Gate

The fixture owner creates the derivative outside Git, then explicitly approves
it before it is staged. A safe derivative must:

1. replace all customer/store-specific values with synthetic equivalents while
   preserving only the visual receipt *format* needed for extraction;
2. remove or replace store address, NIP/VAT/tax IDs, phone/email/web links,
   cashier/terminal/order/receipt identifiers, payment references, loyalty or
   card fragments, timestamps, QR codes, barcodes, and any logos that encode
   a merchant identity when not essential to the format;
3. shift the date to a deliberately synthetic month and change amounts/items
   to non-sensitive test values; retain no mapping to the original;
4. generate a new PDF that contains only reviewed synthetic values, with no
   original metadata, annotations, attachments, JavaScript, or hidden objects.
   A black rectangle over an original PDF is not sufficient;
5. receive a page-by-page visual review and a structural review for residual
   metadata/text before staging.

The committed manifest must contain only fixture ID, page-count bucket,
review date, safe scenario purpose, and the fact that the derivative is
irreversible. It must not contain dates, monetary values, merchants, hashes
of an original, or redaction details that reconstruct the source.

## Fixture Evidence (2026-08-27)

- Owner approved `receipt_a.pdf`, a newly generated document that contains
  only reviewed synthetic values.
- Visual and structural review confirmed it has no source-specific store,
  transaction, payment, barcode, card, or source metadata.
- The committed fixture has a single text layer containing only approved
  synthetic test data; no original source objects or audit artifacts are
  tracked.

## Blocker Evidence (2026-08-28)

- Maestro completed each native-picker scenario twice against the approved
  fixture on headless `it_api36`.
- Patrol's native selectors also opened Documents UI, selected the fixture,
  and returned to the app. The Android `file_picker` plugin cached the selected
  file, but its Dart `pickFiles` future did not resolve under the Patrol JUnit
  runner. Therefore import orchestration never started and neither safe outcome
  state could appear.
- The issue reproduced on a fresh headless `it_api36` launch with
  `-no-snapshot -no-window -gpu host`; a bounded `tester.runAsync` handoff did
  not change it. The existing Patrol picker-cancel Pilot A still passes, so
  this specifically blocks picker *selection-result* coverage.
- Do not add a production test hook or change the import pipeline merely to
  make this framework pilot pass. A future decision may either keep native
  picker-selection coverage in Maestro or scope a separately reviewed test
  seam for Patrol.

## Implementation Steps

1. Owner prepares and approves `receipt_a.pdf` outside the repository using
   the privacy gate above.
2. Add the approved derivative and an opaque manifest; verify Git contains no
   source or staging companions.
3. Add a device-staging helper or documented command that uses only generic
   `receipt_a.pdf` names and does not print host/device paths.
4. Add Patrol Scenario 1 (safe success) and Scenario 2 (exact duplicate).
5. Add equivalent Maestro Scenario 1 and Scenario 2 with stable Semantics IDs.
6. Run each candidate's two scenarios twice on headless `it_api36` using
   `-no-snapshot -no-window -gpu host` and record redacted evidence. Stop and
   record a framework-specific blocker if the native boundary cannot complete.
7. Update the scorecard, the coordination plan, and the master tracker with
   framework-specific maintenance and diagnostic observations.

## Affected Files

- `assets/test/receipts/e2e/receipt_a.pdf` after approval only
- `docs/e2e_receipt_fixture_manifest.md` after approval only
- `patrol_test/` and `maestro/` scenario files
- focused app keys/Semantics and their tests only when a durable outcome
  selector is genuinely absent
- Phase 16 plans, architecture scorecard, and Android E2E cookbook

## Risks

| Risk | Mitigation |
| --- | --- |
| A source receipt is personally or commercially identifiable. | Never stage it; accept only a new flattened derivative after owner review. |
| Framework artifacts reveal fixture content. | Keep artifacts local/ignored; assert IDs and structural states only. |
| The native picker UI varies. | Use generic fixture filename and assert only app outcomes after selection. |
| Duplicate behavior regresses aggregates. | Assert the safe duplicate state and verify count/non-mutation through existing deterministic tests where detail is needed. |
| Patrol cannot return a selected Android document to `file_picker`. | Keep the failing probe out of the tracked suite; retain Maestro's native-picker evidence and decide separately whether Patrol gets a reviewed test seam. |

## Tests and Checks

- Maestro 2.9.0: both `receipt_a_import.yaml` and
  `receipt_a_duplicate.yaml` passed twice on headless `it_api36` /
  `emulator-5554`; the fixture was staged under its generic device filename.
- Patrol package 4.9.0: the selection-result probe reproduced the documented
  JUnit-runner blocker; its generated bundles and local diagnostic output were
  removed after the run.
- Visual and structural privacy review before `git add`.
- `flutter analyze` and relevant widget/provider tests for new selectors.
- Existing parser/import tests remain the detailed business-oracle tests.
- Each supported framework scenario passes twice on headless `it_api36`; record
  any framework-specific native-boundary blocker with reproduction evidence.
- `git diff --check` and a final scan that no originals, staging copies, paths,
  URIs, or report artifacts are tracked.

## Definition of Done

- [x] One owner-approved, synthetic real-format PDF fixture is tracked
  with an opaque manifest.
- [ ] Safe successful-import and exact-duplicate scenarios pass twice in
  Patrol (blocked: `file_picker` result does not reach Dart under the Patrol
  JUnit runner).
- [x] The equivalent two scenarios pass twice in Maestro.
- [ ] No logs, committed artifacts, test names, or assertions reveal fixture
  content or source information.
- [x] The Phase 16 scorecard records the additional comparison evidence and
  the next framework-decision checkpoint.
