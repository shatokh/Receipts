import 'dart:convert';
import 'dart:math';

import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/receipt.dart';

class ReceiptParser {
  static final RegExp _dateRegex =
      RegExp(r'(\d{1,2})[.\/-](\d{1,2})[.\/-](\d{4})\s+(\d{1,2}):(\d{2})');
  static final RegExp _isoLikeDateRegex = RegExp(
    r'(\d{4})[-./](\d{1,2})[-./](\d{1,2})[T\s]+'
    r'(\d{1,2}):(\d{2})(?::\d{2})?(?:\.\d+)?Z?',
  );
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
  Receipt parse(String rawText) {
    final maybeJson = rawText.trimLeft();
    if (maybeJson.startsWith('{')) {
      final decoded = jsonDecode(maybeJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unsupported receipt JSON payload');
      }
      return _parseJsonReceipt(decoded);
    }

    final text = _normalizeText(rawText);

    if (!_isSupportedReceipt(text)) {
      throw const FormatException('Unsupported receipt source');
    }

    final merchantId = _detectMerchantIdFromText(text);

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
      merchantId: merchantId,
      purchaseTimestamp: purchaseDate,
      currency: totals.currency ?? 'PLN',
      totalGross: totals.totalGross!,
      totalVat: totals.totalVat ?? 0,
      items: items,
    );
  }

  Receipt _parseJsonReceipt(Map<String, dynamic> payload) {
    final header = payload['header'];
    final headerData = _firstNestedMap(header, 'headerData');
    final body = payload['body'];
    final sumInCurrency = _firstNestedMap(body, 'sumInCurrency');
    final vatSummary = _firstNestedMap(body, 'vatSummary');
    final fiscalFooter = _firstNestedMap(body, 'fiscalFooter');

    final dateString =
        (headerData?['date'] as String?) ?? (fiscalFooter?['date'] as String?);
    if (dateString == null) {
      final jpkReceipt = _tryParseJpkReceipt(payload);
      if (jpkReceipt != null) {
        return jpkReceipt;
      }
      throw const FormatException('Missing purchase date');
    }

    final purchaseDate = DateTime.parse(dateString).toLocal();

    final totalMinor = _asInt(sumInCurrency?['fiscalTotal']) ??
        _asInt(sumInCurrency?['totalWithPacks']);
    if (totalMinor == null) {
      final jpkReceipt = _tryParseJpkReceipt(payload);
      if (jpkReceipt != null) {
        return jpkReceipt;
      }
      throw const FormatException('Missing total amount');
    }

    final receiptId = _generateId();
    final items = _parseJsonItems(body, receiptId);

    final totalVat = _parseJsonVat(vatSummary);
    final currency = (sumInCurrency?['currency'] as String?) ?? 'PLN';

    final merchantId = _detectMerchantIdFromJson(payload);

    return Receipt(
      id: receiptId,
      merchantId: merchantId,
      purchaseTimestamp: purchaseDate,
      currency: currency,
      totalGross: _fromMinorUnits(totalMinor),
      totalVat: totalVat,
      items: items,
    );
  }

  Receipt? _tryParseJpkReceipt(Map<String, dynamic> payload) {
    final jpkPayload = _decodeCompactDataPayload(payload);
    if (jpkPayload == null) {
      return null;
    }

    final document = jpkPayload['dokument'];
    if (document is! Map<String, dynamic>) {
      return null;
    }

    final paragon = document['paragon'];
    if (paragon is! Map<String, dynamic>) {
      return null;
    }

    final dateString = paragon['zakSprzed'] as String?;
    final purchaseDate = dateString != null
        ? DateTime.parse(dateString).toLocal()
        : _parseJpkHeaderDate(document);
    if (purchaseDate == null) {
      throw const FormatException('Missing purchase date');
    }

    final podsum = paragon['podsum'];
    final total = paragon['total'];
    final totalMinor = (podsum is Map<String, dynamic>
            ? _asInt(podsum['sumaBrutto'])
            : null) ??
        (total is Map<String, dynamic> ? _asInt(total['zaplZwrot']) : null);
    if (totalMinor == null) {
      throw const FormatException('Missing total amount');
    }

    final receiptId = _generateId();
    final items = _parseJpkItems(paragon['pozycja'], receiptId);
    final currency = podsum is Map<String, dynamic>
        ? (podsum['waluta'] as String?) ?? 'PLN'
        : 'PLN';

    return Receipt(
      id: receiptId,
      merchantId: _detectMerchantIdFromJpk(document),
      purchaseTimestamp: purchaseDate,
      currency: currency,
      totalGross: _fromMinorUnits(totalMinor),
      totalVat: _parseJpkVat(podsum),
      items: items,
    );
  }

  Map<String, dynamic>? _decodeCompactDataPayload(
    Map<String, dynamic> payload,
  ) {
    final data = payload['data'];
    if (data is! String) {
      return null;
    }

    final parts = data.split('.');
    if (parts.length < 2 || parts[1].isEmpty) {
      return null;
    }

    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : null;
    } on FormatException {
      return null;
    }
  }

  DateTime? _parseJpkHeaderDate(Map<String, dynamic> document) {
    final header = document['naglowek'];
    if (header is! Map<String, dynamic>) {
      return null;
    }

    final dateString = header['dataJPK'] as String?;
    return dateString != null ? DateTime.parse(dateString).toLocal() : null;
  }

  List<LineItem> _parseJpkItems(dynamic source, String receiptId) {
    if (source is! List) {
      return const [];
    }

    final items = <LineItem>[];

    for (final entry in source) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final product = entry['towar'];
      if (product is! Map<String, dynamic> || product['oper'] == true) {
        continue;
      }

      final name = (product['nazwa'] as String?)?.trim();
      if (name == null || name.isEmpty) {
        continue;
      }

      final quantityRaw = product['ilosc']?.toString();
      final quantity = quantityRaw != null ? _parseAmount(quantityRaw) : 1.0;
      final unit = _inferUnit(quantityRaw);
      final unitPrice = _fromMinorUnits(_asInt(product['cena']));
      final total = _fromMinorUnits(_asInt(product['brutto']));
      final vatRate = _vatRateFromCode(product['idStPTU'] as String?);

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

      final discount = product['rabat'];
      if (discount is Map<String, dynamic>) {
        final amountMinor = _asInt(discount['wart']);
        if (amountMinor == null || amountMinor == 0) {
          continue;
        }

        final label = (discount['opis'] as String?)?.trim();
        final discountName = (label == null || label.isEmpty) ? 'Rabat' : label;
        final amount = _fromMinorUnits(
          amountMinor > 0 ? -amountMinor : amountMinor,
        );

        items.add(
          LineItem(
            id: _generateId(),
            receiptId: receiptId,
            name: discountName,
            quantity: 1,
            unit: 'szt',
            unitPrice: amount,
            discount: 0,
            vatRate: vatRate,
            total: amount,
            categoryId: _categorize(discountName),
          ),
        );
      }
    }

    return items;
  }

  double _parseJpkVat(dynamic podsum) {
    if (podsum is! Map<String, dynamic>) {
      return 0;
    }

    return _fromMinorUnits(_asInt(podsum['sumaPod']));
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

  List<LineItem> _parseJsonItems(dynamic body, String receiptId) {
    if (body is! List) {
      return const [];
    }

    final items = <LineItem>[];

    for (final entry in body) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final sellLine = entry['sellLine'];
      if (sellLine is Map<String, dynamic>) {
        if (sellLine['isStorno'] == true) {
          continue;
        }

        final name = (sellLine['name'] as String?)?.trim();
        if (name == null || name.isEmpty) {
          continue;
        }

        final quantityRaw = sellLine['quantity']?.toString();
        final quantity = quantityRaw != null ? _parseAmount(quantityRaw) : 1.0;
        final unit = _inferUnit(quantityRaw);
        final unitPrice = _fromMinorUnits(_asInt(sellLine['price']));
        final total = _fromMinorUnits(_asInt(sellLine['total']));
        final vatRate = _vatRateFromCode(sellLine['vatId'] as String?);

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

      final discountLine = entry['discountLine'];
      if (discountLine is Map<String, dynamic>) {
        if (discountLine['isStorno'] == true) {
          continue;
        }

        final amountMinor = _asInt(discountLine['value']);
        double? amount;
        if (discountLine['isPercent'] == true) {
          final baseMinor = _asInt(discountLine['base']);
          if (baseMinor != null && amountMinor != null) {
            amount = -_fromMinorUnits(
              ((baseMinor * amountMinor) / 100).round(),
            );
          }
        } else if (amountMinor != null) {
          amount = -_fromMinorUnits(amountMinor);
        }

        if (amount == null) {
          continue;
        }

        final label = (discountLine['name'] as String?)?.trim();
        final name = (label == null || label.isEmpty) ? 'Rabat' : label;
        final vatRate = _vatRateFromCode(discountLine['vatId'] as String?);

        items.add(
          LineItem(
            id: _generateId(),
            receiptId: receiptId,
            name: name,
            quantity: 1,
            unit: 'szt',
            unitPrice: amount,
            discount: 0,
            vatRate: vatRate,
            total: amount,
            categoryId: _categorize(name),
          ),
        );
      }
    }

    return items;
  }

  double _parseJsonVat(Map<String, dynamic>? vatSummary) {
    if (vatSummary == null) {
      return 0;
    }

    final vatRates = vatSummary['vatRatesSummary'];
    if (vatRates is! List) {
      return 0;
    }

    var total = 0.0;
    for (final entry in vatRates) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final amount = _asInt(entry['vatAmount']);
      if (amount == null) {
        continue;
      }
      total += _fromMinorUnits(amount);
    }
    return total;
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
        if (_containsPurchaseDate(line)) {
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

  Map<String, dynamic>? _firstNestedMap(dynamic source, String key) {
    if (source is! List) {
      return null;
    }
    for (final entry in source) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final value = entry[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return null;
  }

  double _fromMinorUnits(int? value) {
    if (value == null) {
      return 0;
    }
    return value / 100;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _inferUnit(String? quantityRaw) {
    if (quantityRaw == null || quantityRaw.isEmpty) {
      return 'szt';
    }
    return quantityRaw.contains(',') || quantityRaw.contains('.')
        ? 'kg'
        : 'szt';
  }

  double _parseAmount(String value) {
    final cleaned = value.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  DateTime? _parsePurchaseDate(String text) {
    final match = _dateRegex.firstMatch(text);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);

      return DateTime(year, month, day, hour, minute);
    }

    final isoLikeMatch = _isoLikeDateRegex.firstMatch(text);
    if (isoLikeMatch != null) {
      final year = int.parse(isoLikeMatch.group(1)!);
      final month = int.parse(isoLikeMatch.group(2)!);
      final day = int.parse(isoLikeMatch.group(3)!);
      final hour = int.parse(isoLikeMatch.group(4)!);
      final minute = int.parse(isoLikeMatch.group(5)!);

      return DateTime(year, month, day, hour, minute);
    }

    return null;
  }

  bool _containsPurchaseDate(String text) {
    return _dateRegex.hasMatch(text) || _isoLikeDateRegex.hasMatch(text);
  }

  String _normalizeText(String text) {
    final canonical = String.fromCharCodes(text.runes);
    return canonical
        .replaceAll('\u00AD', '')
        .replaceAll('\u200B', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  bool _isSupportedReceipt(String text) {
    final lower = text.toLowerCase();
    final collapsed = lower.replaceAll(RegExp(r'[\s-]'), '');

    return _looksLikeBiedronka(lower, collapsed) ||
        lower.contains('receipt') ||
        lower.contains('paragon fiskalny') ||
        lower.contains('paragon') ||
        lower.contains('niefiskalny');
  }

  String _detectMerchantIdFromText(String text) {
    final lower = text.toLowerCase();
    final collapsed = lower.replaceAll(RegExp(r'[\s-]'), '');

    if (_looksLikeBiedronka(lower, collapsed)) {
      return 'biedronka';
    }

    return 'receipts';
  }

  String _detectMerchantIdFromJson(Map<String, dynamic> payload) {
    final header = payload['header'];
    final headerData = _firstNestedMap(header, 'headerData');
    final body = payload['body'];
    final footer = _firstNestedMap(body, 'fiscalFooter');

    final tin = headerData?['tin']?.toString();
    final issuer = footer?['issuerName'] as String?;
    final companyName = headerData?['companyName'] as String?;
    final storeName = headerData?['storeName'] as String?;

    final normalizedTin = tin?.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedTin == '5261040567' || normalizedTin == '7791011327') {
      return 'biedronka';
    }

    final combinedText = [companyName, storeName, issuer]
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .join(' ');

    if (combinedText.isNotEmpty &&
        _looksLikeBiedronka(
          combinedText,
          combinedText.replaceAll(RegExp(r'[\s-]'), ''),
        )) {
      return 'biedronka';
    }

    return 'receipts';
  }

  String _detectMerchantIdFromJpk(Map<String, dynamic> document) {
    final seller = document['podmiot1'];
    if (seller is! Map<String, dynamic>) {
      return 'receipts';
    }

    final tin = seller['NIP']?.toString();
    final normalizedTin = tin?.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedTin == '5261040567' || normalizedTin == '7791011327') {
      return 'biedronka';
    }

    final sellerText = seller.values
        .whereType<String>()
        .map((value) => value.toLowerCase())
        .join(' ');
    if (sellerText.isNotEmpty &&
        _looksLikeBiedronka(
          sellerText,
          sellerText.replaceAll(RegExp(r'[\s-]'), ''),
        )) {
      return 'biedronka';
    }

    return 'receipts';
  }

  bool _looksLikeBiedronka(String lower, String collapsed) {
    return lower.contains('biedronka') ||
        RegExp(r'jeronimo\s+martins\s+polska').hasMatch(lower) ||
        collapsed.contains('jeronimomartinspolska') ||
        collapsed.contains('5261040567') ||
        collapsed.contains('7791011327');
  }

  String _categorize(String name) {
    return categorizeItemName(name);
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
