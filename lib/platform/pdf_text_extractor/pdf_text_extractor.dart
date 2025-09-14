abstract class PdfTextExtractor {
  Future<List<String>> extractTextPages(String safUri);
  Future<int> pageCount(String safUri);
  Future<String> fileHash(String safUri);
}

class PdfTextExtractionException implements Exception {
  final String message;
  final String? details;
  
  PdfTextExtractionException(this.message, [this.details]);
  
  @override
  String toString() => 'PdfTextExtractionException: $message${details != null ? ' ($details)' : ''}';
}