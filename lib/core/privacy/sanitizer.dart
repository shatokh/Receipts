class PrivacySanitizer {
  const PrivacySanitizer._();

  static const redactedSource = 'redacted';

  static final Set<String> _allowedDetailKeys = {
    'stage',
    'status',
    'embedded',
    'stripper',
    'ocr',
    'pageCount',
    'page_count',
  };

  static String sourceMarker(String? source) {
    if (source == null || source.isEmpty) {
      return 'none';
    }
    return redactedSource;
  }

  static String errorType(Object error) => error.runtimeType.toString();

  static Map<String, dynamic> sanitizeDetails(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) {
      return const {};
    }

    final sanitized = <String, dynamic>{};
    for (final entry in details.entries) {
      if (!_allowedDetailKeys.contains(entry.key)) {
        continue;
      }
      final value = _safePrimitive(entry.value);
      if (value != null) {
        sanitized[entry.key] = value;
      }
    }
    return sanitized;
  }

  static Object? _safePrimitive(Object? value) {
    if (value == null || value is bool || value is num) {
      return value;
    }
    if (value is String) {
      if (_looksSensitive(value)) {
        return redactedSource;
      }
      return value.length > 80 ? value.substring(0, 80) : value;
    }
    return value.runtimeType.toString();
  }

  static bool _looksSensitive(String value) {
    final lower = value.toLowerCase();
    return lower.contains('content://') ||
        lower.contains('file://') ||
        lower.contains('saf://') ||
        lower.contains('uri://') ||
        value.contains('\\') ||
        RegExp(r'(^|[\s])/[^\s]').hasMatch(value) ||
        RegExp(r'\b\d{10}\b').hasMatch(value);
  }
}
