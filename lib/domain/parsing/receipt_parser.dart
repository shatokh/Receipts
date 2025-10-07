import 'dart:convert';
import 'dart:math';

import 'package:biedronka_expenses/domain/models/line_item.dart';
import 'package:biedronka_expenses/domain/models/receipt.dart';

class ReceiptParser {
  static final RegExp _dateRegex =
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})');
  static final RegExp _itemLineRegex =
      RegExp(r'^(.+?)\s{2,}(-?\d+(?:[,.]\d+)?)\s*(\S+)$');
  static final RegExp _singleLineItemRegex = RegExp(
    r'^(.+?)\s+([A-Z])\s+(\d+(?:[,.]\d+)?)'
    r'(?:\s+(?!x\s)(\S+))?\s*x\s*(-?\d+(?:[,.]\d+)?)\s+(-?\d+(?:[,.]\d+)?)$',
  );
  static final RegExp _priceLineRegex = RegExp(
      r'(-?\d+(?:[,.]\d+)?)\s*PLN(?:/\S+)?\s+(-?\d+(?:[,.]\d+)?)\s*PLN\s*([A-Z])?',
      caseSensitive: false);
  static final RegExp _discountLineRegex =
      RegExp(r'(-?\d+(?:[,.]\d+)?)\s*PLN', caseSensitive: false);
  static final Map<String, List<String>> _categoryKeywords = {
    'dairy': ['mleko', 'ser', 'jogurt', 'masło', 'śmiet', 'twaróg', 'kefir'],
    'meat': ['mięso', 'kiełb', 'szynk', 'kurczak', 'wołow', 'wieprz', 'indyk'],
    'bakery': ['chleb', 'bułk', 'pieczy', 'bagiet', 'ciasto'],
    'produce': ['jabł', 'banan', 'pomidor', 'ogór', 'warzyw', 'owoc', 'sałat'],
    'household': [
      'papier',
      'deterg',
      'mydł',
      'proszek',
      'chemia',
      'ręcz',
      'środek'
    ],
  };

  Receipt parse(String rawText) {
    final text = _normalizeText(rawText);

    if (!_isBiedronkaReceipt(text)) {
      throw const FormatException('Unsupported receipt source');
    }

    final purchaseDate = _parsePurchaseDate(text);
    if (purchaseDate == null) {
      throw const FormatException('Missing purchase date');
    }

    final totals = _parseTotals(text);
    if (totals.totalGross == null) {
      throw const FormatException('Missing total amount');
    }

    final receiptId = _generateId();
    final items = _parseItems(text, receiptId);

    return Receipt(
      id: receiptId,
      merchantId: 'biedronka',
      purchaseTimestamp: purchaseDate,
      currency: totals.currency ?? 'PLN',
      totalGross: totals.totalGross!,
      totalVat: totals.totalVat ?? 0,
      items: items,
    );
  }

  ReceiptTotals _parseTotals(String text) {
    final totalMatch =
        RegExp(r'SUMA\s+PLN\s+(-?\d+(?:[,.]\d+)?)', caseSensitive: false)
            .firstMatch(text);
    final vatMatch =
        RegExp(r'SUMA\s+VAT\s+(-?\d+(?:[,.]\d+)?)', caseSensitive: false)
            .firstMatch(text);

    double? vatTotal;
    if (vatMatch != null) {
      vatTotal = _parseAmount(vatMatch.group(1)!);
    } else {
      final vatLines = RegExp(r'VAT\s+[A-Z].*?VAT\s+(-?\d+(?:[,.]\d+)?)',
              caseSensitive: false)
          .allMatches(text);
      if (vatLines.isNotEmpty) {
        for (final match in vatLines) {
          vatTotal = (vatTotal ?? 0) + _parseAmount(match.group(1)!);
        }
      }
    }

    return ReceiptTotals(
      totalGross:
          totalMatch != null ? _parseAmount(totalMatch.group(1)!) : null,
      totalVat: vatTotal,
      currency: 'PLN',
    );
  }

  List<LineItem> _parseItems(String text, String receiptId) {
    final items = <LineItem>[];
    final lines = text.split('\n');
    var inItemsSection = false;

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i];
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      if (!inItemsSection) {
        if (_dateRegex.hasMatch(line)) {
          inItemsSection = true;
        }
        continue;
      }

      final lower = line.toLowerCase();
      if (lower.contains('niefiskalny')) {
        continue;
      }
      if (lower.startsWith('nazwa') && lower.contains('ptu')) {
        continue;
      }
      if (lower.startsWith('suma')) {
        break;
      }
      if (lower.startsWith('gotówka') || lower.startsWith('gotowka')) {
        break;
      }

      final singleLineMatch = _singleLineItemRegex.firstMatch(line);
      if (singleLineMatch != null) {
        final name = singleLineMatch.group(1)!.trim();
        final vatCode = singleLineMatch.group(2);
        final quantity = _parseAmount(singleLineMatch.group(3)!);
        final unit = _normalizeUnit(singleLineMatch.group(4));
        final unitPrice = _parseAmount(singleLineMatch.group(5)!);
        final total = _parseAmount(singleLineMatch.group(6)!);
        final vatRate = _vatRateFromCode(vatCode);

        items.add(
          LineItem(
            id: _generateId(),
            receiptId: receiptId,
            name: name,
            quantity: quantity,
            unit: unit,
            unitPrice: unitPrice,
            discount: 0,
            vatRate: vatRate,
            total: total,
            categoryId: _categorize(name),
          ),
        );
        continue;
      }

      if (lower.contains('rabat') || lower.contains('zwrot')) {
        final match = _discountLineRegex.firstMatch(line);
        if (match != null) {
          final amount = _parseAmount(match.group(1)!);
          items.add(
            LineItem(
              id: _generateId(),
              receiptId: receiptId,
              name: rawLine.trim(),
              quantity: 1,
              unit: 'szt',
              unitPrice: amount,
              discount: 0,
              vatRate: 0,
              total: amount,
              categoryId: _categorize(rawLine),
            ),
          );
        }
        continue;
      }

      if (i + 1 >= lines.length) {
        continue;
      }

      final detailsLine = lines[i + 1].trim();
      final itemMatch = _itemLineRegex.firstMatch(line);
      final priceMatch = _priceLineRegex.firstMatch(detailsLine);

      if (itemMatch == null || priceMatch == null) {
        continue;
      }

      final name = itemMatch.group(1)!.trim();
      final quantity = _parseAmount(itemMatch.group(2)!);
      final unit = itemMatch.group(3)!.trim();
      final unitPrice = _parseAmount(priceMatch.group(1)!);
      final total = _parseAmount(priceMatch.group(2)!);
      final vatRate = _vatRateFromCode(priceMatch.group(3));

      items.add(
        LineItem(
          id: _generateId(),
          receiptId: receiptId,
          name: name,
          quantity: quantity,
          unit: unit,
          unitPrice: unitPrice,
          discount: 0,
          vatRate: vatRate,
          total: total,
          categoryId: _categorize(name),
        ),
      );
      i++; // skip details line
    }

    return items;
  }

  double _parseAmount(String value) {
    final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  DateTime? _parsePurchaseDate(String text) {
    final match = _dateRegex.firstMatch(text);
    if (match == null) {
      return null;
    }

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);

    return DateTime(year, month, day, hour, minute);
  }

  String _normalizeText(String text) {
    final canonical = String.fromCharCodes(text.runes);
    return canonical
        .replaceAll('\u00AD', '')
        .replaceAll('\u200B', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  bool _isBiedronkaReceipt(String text) {
    final lower = text.toLowerCase();
    final collapsed = lower.replaceAll(RegExp(r'[\s-]'), '');

    bool containsJeronimoChain() {
      return RegExp(r'jeronimo\s+martins\s+polska', caseSensitive: false)
              .hasMatch(text) ||
          collapsed.contains('jeronimomartinspolska');
    }

    return lower.contains('biedronka') ||
        containsJeronimoChain() ||
        collapsed.contains('5261040567') ||
        collapsed.contains('7791011327') ||
        lower.contains('paragon fiskalny') ||
        lower.contains('niefiskalny');
  }

  String _categorize(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((keyword) => lower.contains(keyword))) {
        return entry.key;
      }
    }
    return 'other';
  }

  double _vatRateFromCode(String? code) {
    switch (code) {
      case 'A':
        return 0.05;
      case 'B':
        return 0.08;
      case 'C':
        return 0.23;
      default:
        return 0;
    }
  }

  String _normalizeUnit(String? value) {
    if (value == null) {
      return 'szt';
    }
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return 'szt';
    }
    final normalized = cleaned.replaceAll('.', '');
    return normalized.isEmpty ? 'szt' : normalized;
  }

  String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, 22);
  }
}

class ReceiptTotals {
  ReceiptTotals({
    required this.totalGross,
    required this.totalVat,
    this.currency,
  });

  final double? totalGross;
  final double? totalVat;
  final String? currency;
}

