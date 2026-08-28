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
