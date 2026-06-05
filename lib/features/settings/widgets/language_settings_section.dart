import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/features/settings/widgets/settings_section.dart';
import 'package:receipts/theme.dart';

class LanguageSettingsSection extends StatelessWidget {
  const LanguageSettingsSection({
    super.key,
    required this.languageName,
  });

  final String languageName;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SettingsSection(
      title: t.languageTitle,
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(
            t.languageTitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            languageName,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          onTap: () => context.push('/settings/language'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
