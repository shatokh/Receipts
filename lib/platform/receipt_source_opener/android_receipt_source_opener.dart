import 'package:flutter/services.dart';

import 'receipt_source_opener.dart';

class AndroidReceiptSourceOpener implements ReceiptSourceOpener {
  static const _channel = MethodChannel('receipt_source_opener');

  @override
  Future<void> open(String sourceUri) async {
    try {
      await _channel.invokeMethod<void>('open', sourceUri);
    } on PlatformException {
      throw const ReceiptSourceOpenException();
    } on MissingPluginException {
      throw const ReceiptSourceOpenException();
    }
  }
}
