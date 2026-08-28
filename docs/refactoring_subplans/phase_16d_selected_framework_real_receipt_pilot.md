# Phase 16d: Selected Framework Real-Format Receipt Pilot

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot C
- Fixture package: `docs/refactoring_subplans/phase_16a_e2e_receipt_fixture_corpus.md`
- Status: superseded
- Superseded on: 2026-08-27
- Replaced by: `phase_16e_dual_framework_redacted_pdf_pilots.md`
- Reason: the team explicitly chose two comparable real-PDF scenarios in both
  Patrol and Maestro before making a framework decision.

## Scope

- Use the selected native framework and the approved two-fixture corpus.
- Automate one real-picker import journey and one month-isolation or duplicate journey.
- Assert only safe structural outcomes: import state, receipt count, month separation, and duplicate non-mutation.
- Run only on the verified local headless `it_api36` / `emulator-5554` baseline; physical-device and CI proof are deferred until after this package.

## Non-goals

- Do not expose or assert raw receipt text, totals, dates, items, merchant details, paths, or URIs.
- Do not automate the content of a third-party PDF viewer.
- Do not add bulk-import coverage unless the selected picker/device behavior first proves stable.

## Implementation Steps

1. Confirm the selected framework, API image, and fixture manifest review.
2. Place the two approved fixtures on the test device through a privacy-safe setup procedure.
3. Implement native picker import for Receipt A and assert the safe list/month outcome.
4. Import Receipt B, assert month separation, then run the selected duplicate path for Receipt A.
5. Repeat the suite twice, collect redacted evidence, and run one manual CI proof if local stability is acceptable.

## Affected Files

- Selected framework test directory/configuration
- Approved `assets/test/receipts/e2e/` fixtures and manifest
- `pubspec.yaml` only if a Flutter asset registration is needed
- Existing test keys/Semantics only if a stable outcome selector is missing
- Phase 16 scorecard and tracker

## Risks

| Risk | Mitigation |
| --- | --- |
| Native extraction differs by device/API. | Record API image and assert safe high-level outcomes only. |
| Fixture privacy regresses through reports. | Redact or disable screenshots/logs that can reveal receipt content. |
| Month UI assertion is brittle. | Use stable non-content selectors and opaque fixture/month buckets. |

## Tests and Checks

- Existing `flutter analyze`, `flutter test`, and Flutter `integration_test`
- Selected native framework run twice on the same image
- Fixture/privacy review and `git diff --check`
- One manual CI proof if the selected framework has two stable local runs

## Definition of Done

- [ ] Two approved fixtures are imported through the real picker without privacy leakage.
- [ ] A month-isolation or duplicate non-mutation flow passes twice.
- [ ] Evidence is recorded without fixture content or personal data.
- [ ] Phase 16 selection and follow-up status are updated accurately.
