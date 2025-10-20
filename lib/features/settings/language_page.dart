import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/core/localization/locale_controller.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider);
    final controller = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t.languageTitle)),
      body: ListView(
        children: [
          ListTile(title: Text(t.chooseLanguage)),
          const Divider(),
          RadioListTile<Locale>(
            value: const Locale('en'),
            groupValue: current,
            onChanged: (_) => controller.setLocale(const Locale('en')),
            title: Text(t.english),
          ),
          RadioListTile<Locale>(
            value: const Locale('ru'),
            groupValue: current,
            onChanged: (_) => controller.setLocale(const Locale('ru')),
            title: Text(t.russian),
          ),
        ],
      ),
    );
  }
}
