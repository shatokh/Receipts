import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:receipts/app/app_test_keys.dart';
import 'package:receipts/main.dart';

void main() {
  patrolTest('cancelling Android document picker returns to import', ($) async {
    await $.pumpWidgetAndSettle(buildApp());

    await $(AppTestKeys.onboardingGetStarted).tap();
    await $(AppTestKeys.navImport).tap();
    await $(AppTestKeys.importButton).tap();

    // If the system picker did not open, Back would navigate away from Import
    // and the stable in-app assertion below would fail.
    await $.platform.android.pressBack();

    await $.pumpAndSettle();
    expect($(AppTestKeys.importButton), findsOneWidget);
  });
}
