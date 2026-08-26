import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/features/settings/widgets/settings_section.dart';
import 'package:receipts/theme.dart';

class DebugSettingsSection extends StatefulWidget {
  const DebugSettingsSection({
    super.key,
    required this.devLoggingEnabled,
    required this.logPath,
    required this.onClearReceiptData,
    required this.onDevLoggingChanged,
  });

  final bool devLoggingEnabled;
  final AsyncValue<String> logPath;
  final Future<void> Function() onClearReceiptData;
  final ValueChanged<bool> onDevLoggingChanged;

  @override
  State<DebugSettingsSection> createState() => _DebugSettingsSectionState();
}

class _DebugSettingsSectionState extends State<DebugSettingsSection> {
  var _isClearing = false;

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
              widget.logPath.when(
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
          value: widget.devLoggingEnabled,
          onChanged: widget.onDevLoggingChanged,
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
          onTap: _isClearing ? null : () => _showClearDataDialog(context),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.clearAllDataDialogTitle),
        content: Text(t.clearAllDataDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.clearAction),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    setState(() => _isClearing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onClearReceiptData();
    } catch (_) {
      if (mounted) {
        setState(() => _isClearing = false);
        messenger.showSnackBar(SnackBar(content: Text(t.clearDataFailed)));
      }
      return;
    }

    if (mounted) {
      setState(() => _isClearing = false);
      messenger.showSnackBar(SnackBar(content: Text(t.clearDataSuccess)));
    }
  }
}
