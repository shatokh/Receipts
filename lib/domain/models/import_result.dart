enum ImportStatus { success, duplicate, error }

class ImportResult {
  final String sourceUri;
  final ImportStatus status;
  final String? receiptId;
  final String? message;

  const ImportResult({
    required this.sourceUri,
    required this.status,
    this.receiptId,
    this.message,
  });
}
