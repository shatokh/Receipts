import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/features/settings/widgets/settings_section.dart';
import 'package:receipts/theme.dart';

class DebugSettingsSection extends StatelessWidget {
  const DebugSettingsSection({
    super.key,
    required this.devLoggingEnabled,
    required this.logPath,
    required this.onDevLoggingChanged,
  });

  final bool devLoggingEnabled;
  final AsyncValue<String> logPath;
  final ValueChanged<bool> onDevLoggingChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SettingsSection(
      title: t.debugSectionTitle,
      children: [
        SwitchListTile(
          title: Text(
            t.enableErrorLogging,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.errorLoggingDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              logPath.when(
                data: (path) => Text(
                  t.errorLogPath(path),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          value: devLoggingEnabled,
          onChanged: onDevLoggingChanged,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          title: Text(
            t.clearAllData,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.error,
            ),
          ),
          subtitle: Text(
            t.clearAllDataDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          onTap: () => _showClearDataDialog(context),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.clearAllDataDialogTitle),
        content: Text(t.clearAllDataDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.clearDataNotImplemented)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.clearAction),
          ),
        ],
      ),
    );
  }
}
