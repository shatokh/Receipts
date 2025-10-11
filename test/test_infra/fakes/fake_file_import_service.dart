import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:biedronka_expenses/features/import/file_import_service.dart';
import 'package:biedronka_expenses/platform/pdf_text_extractor/pdf_text_extractor.dart';

class FakeFileImportService implements FileImportService {
  FakeFileImportService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Queue<List<FakeImportRequest>> _queuedImports = Queue();
  final Map<String, FakeImportFixture> _fixtures = {};

  Map<String, FakeImportFixture> get fixtures => _fixtures;

  void queueImport(List<FakeImportRequest> requests) {
    _queuedImports.add(List.unmodifiable(requests));
  }

  void clear() {
    _queuedImports.clear();
    _fixtures.clear();
  }

  FakeImportFixture? fixtureForUri(String uri) => _fixtures[uri];

  @override
  Future<List<String>> pickReceiptUris() async {
    if (_queuedImports.isEmpty) {
      return [];
    }

    final requestGroup = _queuedImports.removeFirst();
    final uris = <String>[];

    for (final request in requestGroup) {
      final data = await _bundle.load(request.assetPath);
      final bytes = data.buffer.asUint8List();
      final fixture = FakeImportFixture(
        uri: request.uri,
        bytes: bytes,
        textPages: request.textPages,
        hash: request.hash,
        extractionError: request.extractionError,
      );
      _fixtures[request.uri] = fixture;
      uris.add(request.uri);
    }

    return uris;
  }
}

class FakeImportRequest {
  const FakeImportRequest({
    required this.assetPath,
    required this.uri,
    required this.textPages,
    required this.hash,
    this.extractionError,
  });

  final String assetPath;
  final String uri;
  final List<String> textPages;
  final String hash;
  final Object? extractionError;
}

class FakeImportFixture {
  FakeImportFixture({
    required this.uri,
    required this.bytes,
    required this.textPages,
    required this.hash,
    this.extractionError,
  });

  final String uri;
  final Uint8List bytes;
  final List<String> textPages;
  final String hash;
  final Object? extractionError;
}

class FakePdfTextExtractor implements PdfTextExtractor {
  FakePdfTextExtractor(this._fileImportService);

  final FakeFileImportService _fileImportService;

  FakeImportFixture _resolveFixture(String safUri) {
    final fixture = _fileImportService.fixtureForUri(safUri);
    if (fixture == null) {
      throw PdfTextExtractionException('No fixture registered for $safUri');
    }
    return fixture;
  }

  @override
  Future<List<String>> extractTextPages(String safUri) async {
    final fixture = _resolveFixture(safUri);
    final error = fixture.extractionError;
    if (error != null) {
      if (error is PdfTextExtractionException) {
        throw error;
      }
      throw PdfTextExtractionException(error.toString());
    }
    return fixture.textPages;
  }

  @override
  Future<int> pageCount(String safUri) async {
    final pages = await extractTextPages(safUri);
    return pages.length;
  }

  @override
  Future<String> fileHash(String safUri) async {
    final fixture = _resolveFixture(safUri);
    return fixture.hash;
  }

  @override
  Future<String> readTextFile(String safUri) async {
    final fixture = _resolveFixture(safUri);
    return utf8.decode(fixture.bytes, allowMalformed: true);
  }
}
