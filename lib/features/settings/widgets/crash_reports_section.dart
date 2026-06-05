import 'package:flutter/material.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/features/settings/widgets/settings_section.dart';
import 'package:receipts/theme.dart';

class CrashReportsSection extends StatelessWidget {
  const CrashReportsSection({
    super.key,
    required this.sentryEnabled,
    required this.onChanged,
  });

  final bool sentryEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SettingsSection(
      title: t.crashReportsTitle,
      children: [
        SwitchListTile(
          title: Text(
            t.enableSentryCrashReports,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            t.crashReportsDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          value: sentryEnabled,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
