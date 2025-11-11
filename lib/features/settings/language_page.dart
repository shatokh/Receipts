import 'package:flutter/material.dart';
import 'package:receipts/l10n/app_localizations.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<Locale>(
              segments: [
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(t.english),
                ),
                ButtonSegment(
                  value: const Locale('pl'),
                  label: Text(t.polish),
                ),
                ButtonSegment(
                  value: const Locale('ru'),
                  label: Text(t.russian),
                ),
              ],
              selected: {current},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  controller.setLocale(selection.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
