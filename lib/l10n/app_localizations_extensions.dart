import 'package:intl/intl.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/l10n/app_localizations.dart';

extension AppLocalizationsX on AppLocalizations {
  String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy', localeName).format(date);

  String formatMonthYearShort(DateTime date) =>
      DateFormat('MMM yyyy', localeName).format(date);

  String formatMonthAbbreviated(DateTime date) =>
      DateFormat('MMM', localeName).format(date);

  Map<String, String> get _categoryLabels => {
        CategoryIds.freshProduce: categoryFreshProduce,
        CategoryIds.dairyEggsBakery: categoryDairyEggsBakery,
        CategoryIds.packagedPantry: categoryPackagedPantry,
        CategoryIds.drinksSnacks: categoryDrinksSnacks,
        CategoryIds.householdGoods: categoryHouseholdGoods,
        CategoryIds.misc: categoryMisc,
      };

  String categoryLabel(String categoryId) =>
      _categoryLabels[categoryId] ?? _categoryLabels[CategoryIds.misc]!;
}
