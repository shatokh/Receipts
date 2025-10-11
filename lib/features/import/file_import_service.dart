import 'dart:collection';

import 'package:file_picker/file_picker.dart';

abstract class FileImportService {
  Future<List<String>> pickReceiptUris();
}

class FilePickerFileImportService implements FileImportService {
  const FilePickerFileImportService();

  @override
  Future<List<String>> pickReceiptUris() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'json'],
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final uris = result.files
        .map((file) => file.identifier ?? file.path)
        .whereType<String>()
        .toList();

    return LinkedHashSet<String>.from(uris).toList();
  }
}
