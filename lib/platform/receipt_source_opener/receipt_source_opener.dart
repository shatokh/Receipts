abstract class ReceiptSourceOpener {
  /// Asks the operating system to open a previously imported receipt source.
  ///
  /// Implementations must not log or expose [sourceUri] in user-facing errors.
  Future<void> open(String sourceUri);
}

class ReceiptSourceOpenException implements Exception {
  const ReceiptSourceOpenException();
}
