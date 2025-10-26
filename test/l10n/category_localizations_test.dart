import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/l10n/app_localizations_en.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

void main() {
  test('every category has a localized label', () {
    final t = AppLocalizationsEn();

    for (final definition in categoryDefinitions) {
      final label = t.categoryLabel(definition.id);
      expect(label, isNotEmpty,
          reason: 'Missing localization for ${definition.id}');
    }
  });
}
