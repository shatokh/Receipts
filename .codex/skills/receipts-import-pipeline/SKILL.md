---
name: receipts-import-pipeline
description: Work on the Receipts app import pipeline. Use when changing PDF or JSON receipt import, PdfTextExtractor integration, ReceiptParser behavior, duplicate detection, ImportResult messages, receipt persistence, or aggregate updates after import.
---

# Receipts Import Pipeline

Use this skill for changes that touch `lib/features/import/`, `lib/domain/parsing/receipt_parser.dart`, `lib/platform/pdf_text_extractor/`, or import-related repository behavior.

## Workflow

1. Read the current flow in `ImportService.importOne`.
2. Identify which path is affected:
   - PDF text extraction through `PdfTextExtractor.extractTextPages`
   - JSON/text fallback through `readTextFile`
   - exact duplicate detection through `fileHash`
   - heuristic duplicate detection through merchant/date/total
   - persistence and aggregate updates
3. Keep all platform work behind providers/interfaces so tests can override it.
4. Avoid logging raw receipt text, file URIs, NIP, line items, totals, or source payloads.
5. Return user-safe `ImportResult.message` strings.

## Required Checks

- If parsing behavior changes, add or update tests around `ReceiptParser`.
- If import orchestration changes, update `test/import_pipeline_test.dart`.
- If `PdfTextExtractor` changes, update Android implementation and fakes together.
- Verify aggregate consistency after successful insert with `AnalyticsRepository.updateAggregatesForMonth`.
- Use `closeTo` for money assertions.

## Commands

Run focused tests while iterating:

```powershell
flutter test test/import_pipeline_test.dart
flutter test test/receipt_parser_new_format_test.dart
```

Run the full suite before finishing broad changes:

```powershell
flutter test
```
