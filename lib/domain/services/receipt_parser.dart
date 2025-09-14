import 'dart:convert';
import 'dart:math';
import 'package:biedronka_expenses/domain/models/receipt.dart';
import 'package:biedronka_expenses/domain/models/line_item.dart';
import 'package:biedronka_expenses/domain/models/merchant.dart';
import 'package:biedronka_expenses/data/repositories/category_repository.dart';

class ReceiptParseResult {
  final Receipt? receipt;
  final List<LineItem> lineItems;
  final Merchant? merchant;
  final String? error;
  final bool isSuccess;

  ReceiptParseResult({
    this.receipt,
    this.lineItems = const [],
    this.merchant,
    this.error,
    this.isSuccess = false,
  });

  factory ReceiptParseResult.success({
    required Receipt receipt,
    required List<LineItem> lineItems,
    Merchant? merchant,
  }) => ReceiptParseResult(
    receipt: receipt,
    lineItems: lineItems,
    merchant: merchant,
    isSuccess: true,
  );

  factory ReceiptParseResult.error(String error) => ReceiptParseResult(
    error: error,
    isSuccess: false,
  );
}

class ReceiptParser {
  final CategoryRepository _categoryRepository;

  ReceiptParser(this._categoryRepository);

  Future<ReceiptParseResult> parseReceiptText(
    String text, 
    String fileHash, 
    String? sourceUri
  ) async {
    try {
      final normalizedText = _normalizeText(text);
      
      if (!_isBiedronkaReceipt(normalizedText)) {
        return ReceiptParseResult.error('Not a Biedronka receipt');
      }

      final merchant = _parseMerchant(normalizedText);
      final purchaseDate = _parsePurchaseDate(normalizedText);
      final items = await _parseLineItems(normalizedText);
      final totals = _parseTotals(normalizedText);

      if (purchaseDate == null) {
        return ReceiptParseResult.error('Could not parse purchase date');
      }

      if (totals['total'] == null) {
        return ReceiptParseResult.error('Could not parse total amount');
      }

      final receiptId = _generateId();
      final receipt = Receipt(
        id: receiptId,
        merchantId: merchant?.id ?? 'biedronka',
        purchaseTimestamp: purchaseDate,
        totalGross: totals['total']!,
        totalVat: totals['vat'] ?? 0.0,
        fileHash: fileHash,
        sourceUri: sourceUri,
      );

      final lineItems = items.map((item) => item.copyWith(receiptId: receiptId)).toList();

      return ReceiptParseResult.success(
        receipt: receipt,
        lineItems: lineItems,
        merchant: merchant,
      );
    } catch (e) {
      return ReceiptParseResult.error('Parsing failed: $e');
    }
  }

  String _normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'\u00AD'), '') // Remove soft hyphens
        .replaceAll(RegExp(r'\r\n|\r|\n'), '\n') // Normalize line breaks
        .replaceAll(',', '.'); // Convert decimal comma to dot
  }

  bool _isBiedronkaReceipt(String text) {
    return text.toLowerCase().contains('biedronka') || 
           text.contains('NIP: 5261040567') ||
           text.toLowerCase().contains('paragon fiskalny');
  }

  Merchant? _parseMerchant(String text) {
    final lines = text.split('\n');
    String? name, address, city, nip;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.toLowerCase().contains('biedronka')) {
        name = 'Biedronka';
      }
      
      if (line.startsWith('ul.') && address == null) {
        address = line;
        if (i + 1 < lines.length) {
          city = lines[i + 1].trim();
        }
      }
      
      if (line.contains('NIP:')) {
        nip = line.split('NIP:').last.trim();
      }
    }

    if (name != null) {
      return Merchant(
        id: 'biedronka',
        name: name,
        nip: nip,
        address: address,
        city: city,
      );
    }
    
    return null;
  }

  DateTime? _parsePurchaseDate(String text) {
    // Look for date pattern like "14.08.2025 18:22"
    final dateRegex = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{1,2}):(\d{2})');
    final match = dateRegex.firstMatch(text);
    
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      
      return DateTime(year, month, day, hour, minute);
    }
    
    return null;
  }

  Future<List<LineItem>> _parseLineItems(String text) async {
    final items = <LineItem>[];
    final lines = text.split('\n');
    
    bool inItemSection = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Start parsing items after date/time
      if (RegExp(r'\d{1,2}\.\d{1,2}\.\d{4}\s+\d{1,2}:\d{2}').hasMatch(line)) {
        inItemSection = true;
        continue;
      }
      
      // Stop at totals section
      if (line.toLowerCase().contains('suma pln') || 
          line.toLowerCase().contains('gotówka')) {
        break;
      }
      
      if (!inItemSection) continue;
      
      // Look for item pattern: name followed by price line
      if (line.isNotEmpty && !line.contains('PLN') && i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        final itemMatch = _parseItemLine(line, nextLine);
        
        if (itemMatch != null) {
          final categoryId = await _categoryRepository.categorizeName(itemMatch['name']!);
          items.add(LineItem(
            id: _generateId(),
            receiptId: '', // Will be set later
            name: itemMatch['name']!,
            quantity: itemMatch['quantity']! as double,
            unit: itemMatch['unit']! as String,
            unitPrice: itemMatch['unitPrice']! as double,
            discount: itemMatch['discount']! as double,
            vatRate: itemMatch['vatRate']! as double,
            total: itemMatch['total']! as double,
            categoryId: categoryId,
          ));
          i++; // Skip the price line as we've already processed it
        }
      }
      
      // Handle discount lines
      if (line.toLowerCase().contains('rabat') || line.toLowerCase().contains('promocja')) {
        final discountMatch = RegExp(r'-?(\d+(?:\.\d+)?)\s*PLN').firstMatch(line);
        if (discountMatch != null) {
          final discountAmount = double.parse(discountMatch.group(1)!);
          items.add(LineItem(
            id: _generateId(),
            receiptId: '',
            name: 'RABAT promocja',
            quantity: 1.0,
            unit: 'szt',
            unitPrice: -discountAmount,
            discount: 0.0,
            vatRate: 0.0,
            total: -discountAmount,
            categoryId: 'other',
          ));
        }
      }
    }
    
    return items;
  }

  Map<String, dynamic>? _parseItemLine(String nameLine, String priceLine) {
    final name = nameLine;
    
    // Parse price line pattern: "quantity unit_price PLN/unit total PLN VAT_LETTER"
    final priceRegex = RegExp(r'(\d+(?:[,.]?\d+)?)\s*(.+?)\s*PLN/(.+?)\s+(\d+(?:[,.]?\d+)?)\s*PLN\s*([AB]?)');
    final match = priceRegex.firstMatch(priceLine);
    
    if (match != null) {
      final quantity = double.parse(match.group(1)!.replaceAll(',', '.'));
      final unitPrice = double.parse(match.group(2)!.replaceAll(',', '.'));
      final unit = match.group(3)!.trim();
      final total = double.parse(match.group(4)!.replaceAll(',', '.'));
      final vatLetter = match.group(5) ?? '';
      
      double vatRate = 0.0;
      if (vatLetter == 'A') vatRate = 0.05; // 5%
      if (vatLetter == 'B') vatRate = 0.08; // 8%
      
      return {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'discount': 0.0,
        'vatRate': vatRate,
        'total': total,
      };
    }
    
    return null;
  }

  Map<String, double?> _parseTotals(String text) {
    double? total;
    double? vat;
    
    // Parse SUMA PLN
    final totalRegex = RegExp(r'SUMA\s+PLN\s+(\d+(?:[,.]?\d+)?)', caseSensitive: false);
    final totalMatch = totalRegex.firstMatch(text);
    if (totalMatch != null) {
      total = double.parse(totalMatch.group(1)!.replaceAll(',', '.'));
    }
    
    // Parse VAT total
    final vatRegex = RegExp(r'SUMA\s+VAT\s+(\d+(?:[,.]?\d+)?)', caseSensitive: false);
    final vatMatch = vatRegex.firstMatch(text);
    if (vatMatch != null) {
      vat = double.parse(vatMatch.group(1)!.replaceAll(',', '.'));
    }
    
    return {'total': total, 'vat': vat};
  }

  String _generateId() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, 22);
  }
}