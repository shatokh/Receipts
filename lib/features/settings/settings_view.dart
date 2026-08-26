import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/core/localization/locale_controller.dart';
import 'package:receipts/features/settings/widgets/about_settings_section.dart';
import 'package:receipts/features/settings/widgets/crash_reports_section.dart';
import 'package:receipts/features/settings/widgets/debug_settings_section.dart';
import 'package:receipts/features/settings/widgets/language_settings_section.dart';
import 'package:receipts/theme.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentryEnabled = ref.watch(sentryEnabledProvider);
    final devLoggingEnabled = ref.watch(devLoggingEnabledProvider);
    final logPathAsync = ref.watch(errorLogPathProvider);
    final t = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    final languageName = switch (locale.languageCode) {
      'pl' => t.polish,
      'ru' => t.russian,
      _ => t.english,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          LanguageSettingsSection(languageName: languageName),
          const SizedBox(height: AppSpacing.lg),
          CrashReportsSection(
            sentryEnabled: sentryEnabled,
            onChanged: (value) async {
              await ref.read(sentryEnabledProvider.notifier).setEnabled(value);

              final message =
                  value ? t.crashReportingEnabled : t.crashReportingDisabled;

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const AboutSettingsSection(),
          const SizedBox(height: AppSpacing.lg),
          DebugSettingsSection(
            devLoggingEnabled: devLoggingEnabled,
            logPath: logPathAsync,
            onClearReceiptData: ref.read(receiptRepositoryProvider).clearAllReceiptData,
            onDevLoggingChanged: (value) async {
              await ref
                  .read(devLoggingEnabledProvider.notifier)
                  .setEnabled(value);

              if (context.mounted && value) {
                try {
                  final path = await ref.read(errorLogPathProvider.future);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.errorLogEnabled(path))),
                    );
                  }
                } catch (_) {
                  // Ignore path resolution errors in the dev-only logging toggle.
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
