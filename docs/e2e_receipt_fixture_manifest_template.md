# E2E Receipt Fixture Manifest Template

Use this template only after a receipt fixture has been redacted and approved for repository use. The manifest must describe test intent without reproducing receipt content or user data.

## Storage

- Put approved PDFs under `assets/test/receipts/e2e/`.
- Add each approved PDF explicitly to `pubspec.yaml` only when a test needs it as a Flutter asset.
- Keep the original document outside the repository and outside build/test artifacts.
- Use a neutral fixture identifier and file name; do not use a merchant, person, address, date, order number, or source-path fragment.

## Required Privacy Review

- [ ] Original file is not staged or committed.
- [ ] Personal names, addresses, loyalty identifiers, payment fragments, NIP/tax IDs, barcodes, QR codes, order IDs, phone numbers, email addresses, and source metadata are removed or replaced.
- [ ] The file was visually reviewed page by page after redaction.
- [ ] The fixture can be shared under the repository's intended access model.
- [ ] No raw PDF text, totals, dates, line items, hashes, paths, or URIs will be used in test names, assertions, logs, screenshots, or reports.

## Fixture Entry

Copy one entry per approved fixture. Keep only opaque metadata.

```markdown
### Fixture: receipt_a

- Repository file: `assets/test/receipts/e2e/receipt_a.pdf`
- Shape: short | long | multi-page
- Redaction reviewed on: YYYY-MM-DD
- Reviewer: role or initials only
- Intended flows:
  - native picker import
  - duplicate detection
- Expected safe outcomes:
  - imports once
  - duplicate import does not create a second receipt
- Notes: no personal data or receipt content recorded here
```

## Baseline Corpus

For Phase 16e, provide exactly one approved fixture:

1. `receipt_a.pdf` — an irreversible, redacted real-format derivative used for
   native picker import and exact-duplicate detection in both frameworks.

Additional files require a new approved scenario; fixture quantity by itself
is not coverage.
