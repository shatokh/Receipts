import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/features/import/import_controller.dart';
import 'package:receipts/theme.dart';

class ImportView extends ConsumerWidget {
  const ImportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importControllerProvider);
    final controller = ref.watch(importControllerProvider.notifier);
    final entries = controller.historyEntries;

    final historyContent = importState.maybeWhen(
      data: (results) => results.isEmpty
          ? const _EmptyState()
          : _ImportHistoryList(entries: entries),
      orElse: () => entries.isEmpty
          ? const _EmptyState()
          : _ImportHistoryList(entries: entries),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import receipts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              key: const ValueKey('import_button'),
              onPressed: () => _importReceipts(context, ref),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import receipts (PDF or JSON)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Stack(
                children: [
                  historyContent,
                  if (importState.isLoading)
                    const Positioned.fill(
                      child: _LoadingOverlay(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Files are copied to app storage for reliable access.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importReceipts(BuildContext context, WidgetRef ref) async {
    try {
      final fileImportService = ref.read(fileImportServiceProvider);
      final uris = await fileImportService.pickReceiptUris();

      if (uris.isEmpty) {
        return;
      }

      await ref.read(importControllerProvider.notifier).importUris(uris);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.05),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.file_upload,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No imports yet',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Import your first receipt (PDF or JSON)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportHistoryList extends StatelessWidget {
  const _ImportHistoryList({required this.entries});

  final List<ImportHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _ImportHistoryItem(entry: entries[index]);
      },
    );
  }
}

class _ImportHistoryItem extends StatelessWidget {
  const _ImportHistoryItem({required this.entry});

  final ImportHistoryEntry entry;

  ImportResult get result => entry.result;

  @override
  Widget build(BuildContext context) {
    final fileName = _resolveFileName(result.sourceUri);
    final subtitle = _buildSubtitle(entry.timestamp, result.message);
    final badgeStyle = _badgeStyle(result.status);

    return Card(
      child: ListTile(
        title: Text(
          fileName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: _StatusBadge(
          label: badgeStyle.label,
          color: badgeStyle.color,
          outlined: badgeStyle.outlined,
        ),
      ),
    );
  }

  String _buildSubtitle(DateTime timestamp, String? message) {
    final parts = <String>[_formatTimestamp(timestamp)];
    if (message != null && message.isNotEmpty) {
      parts.add(message);
    }
    return parts.join(' • ');
  }

  _BadgeStyle _badgeStyle(ImportStatus status) {
    switch (status) {
      case ImportStatus.success:
        return const _BadgeStyle(label: 'Success', color: AppColors.success);
      case ImportStatus.duplicate:
        return const _BadgeStyle(
          label: 'Duplicate',
          color: AppColors.warning,
          outlined: true,
        );
      case ImportStatus.error:
        return const _BadgeStyle(label: 'Error', color: AppColors.error);
    }
  }

  String _resolveFileName(String? sourceUri) {
    if (sourceUri == null || sourceUri.isEmpty) {
      return 'Unknown file';
    }

    try {
      final uri = Uri.parse(sourceUri);
      if (uri.pathSegments.isNotEmpty) {
        return Uri.decodeComponent(uri.pathSegments.last);
      }
      return uri.toString();
    } catch (_) {
      final segments = sourceUri.split('/');
      return segments.isNotEmpty ? segments.last : sourceUri;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.color,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final bool outlined;
}
