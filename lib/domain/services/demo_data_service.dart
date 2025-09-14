import 'package:biedronka_expenses/data/repositories/receipt_repository.dart';
import 'package:biedronka_expenses/data/demo_data.dart';

class DemoDataService {
  final ReceiptRepository _receiptRepository;

  DemoDataService(this._receiptRepository);

  Future<void> initializeDemoData() async {
    // Check if we already have demo data
    final existingReceipts = await _receiptRepository.getAllReceipts();
    if (existingReceipts.isNotEmpty) return;

    // Insert demo receipts
    final receipts = DemoData.getAugust2025Receipts();
    final lineItems = DemoData.getMaxReceiptItems();
    
    for (final receipt in receipts) {
      await _receiptRepository.insertReceipt(receipt);
    }
    
    await _receiptRepository.insertLineItems(lineItems);
    
    // Update aggregates
    await _receiptRepository.updateAggregates();
  }
}