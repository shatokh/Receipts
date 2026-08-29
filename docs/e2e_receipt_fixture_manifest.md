# E2E Receipt Fixture Manifest

This manifest records only safe test intent. It does not reproduce receipt
content, source information, real transaction data, or redaction details.

## Fixture: receipt_a

- Repository file: `assets/test/receipts/e2e/receipt_a.pdf`
- Shape: single-page
- Redaction reviewed on: 2026-08-27
- Reviewer: owner
- Derivative: newly generated synthetic PDF. Its text layer contains only
  reviewed synthetic data; no source document objects or source metadata are
  present.
- Intended flows:
  - native picker import
  - exact duplicate detection
- Expected safe outcomes:
  - imports once
  - duplicate import does not create a second receipt
- Notes: contains synthetic test-only document data; no original document or
  source-to-derivative mapping is tracked.

## Fixture: receipt_b

- Repository file: `assets/test/receipts/e2e/receipt_b.pdf`
- Shape: single-page, long
- Redaction reviewed on: 2026-08-29
- Reviewer: owner
- Derivative: newly generated document containing only owner-approved
  synthetic test data and no source document objects or source metadata.
- Intended flows:
  - native picker import in a distinct synthetic month
  - month-isolation coverage
  - parser date and category-distribution coverage
- Expected safe outcomes:
  - imports once in a month separate from `receipt_a`
  - selected Month views each contain one receipt
- Notes: contains synthetic test-only document data; no original document or
  source-to-derivative mapping is tracked.
