import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:biedronka_expenses/theme.dart';
import 'package:biedronka_expenses/app/providers.dart';

class ImportView extends ConsumerStatefulWidget {
  const ImportView({super.key});

  @override
  ConsumerState<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends ConsumerState<ImportView> {
  final List<ImportResult> _importHistory = [];

  @override
  Widget build(BuildContext context) {
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
              onPressed: _importPDF,
              icon: const Icon(Icons.upload_file),
              label: const Text('Import PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_importHistory.isNotEmpty) ...[
              Text(
                'Recent imports',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _ImportHistoryList()),
            ] else
              _EmptyState(),
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

  Future<void> _importPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Simulate processing
        setState(() {
          _importHistory.insert(0, ImportResult(
            fileName: file.name,
            status: ImportStatus.processing,
            timestamp: DateTime.now(),
          ));
        });

        // Simulate async processing
        await Future.delayed(const Duration(seconds: 2));
        
        setState(() {
          _importHistory[0] = _importHistory[0].copyWith(
            status: file.name.contains('sample') ? ImportStatus.success : ImportStatus.duplicate,
          );
        });

        if (mounted) {
          final message = file.name.contains('sample') 
              ? 'Receipt imported successfully!'
              : 'Receipt already exists (duplicate)';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      setState(() {
        if (_importHistory.isNotEmpty && _importHistory[0].status == ImportStatus.processing) {
          _importHistory[0] = _importHistory[0].copyWith(status: ImportStatus.error);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Widget _EmptyState() {
    return Expanded(
      child: Center(
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
              'Import your first Biedronka PDF receipt',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ImportHistoryList() {
    return ListView.builder(
      itemCount: _importHistory.length,
      itemBuilder: (context, index) {
        final result = _importHistory[index];
        return _ImportHistoryItem(result: result);
      },
    );
  }
}

class _ImportHistoryItem extends StatelessWidget {
  final ImportResult result;

  const _ImportHistoryItem({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _getStatusIcon(),
        title: Text(
          result.fileName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${result.status.displayName} • ${_formatTime(result.timestamp)}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: _getStatusBadge(),
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (result.status) {
      case ImportStatus.success:
        return const CircleAvatar(
          backgroundColor: AppColors.success,
          child: Icon(Icons.check, color: Colors.white, size: 16),
        );
      case ImportStatus.duplicate:
        return const CircleAvatar(
          backgroundColor: AppColors.warning,
          child: Icon(Icons.content_copy, color: Colors.white, size: 16),
        );
      case ImportStatus.error:
        return const CircleAvatar(
          backgroundColor: AppColors.error,
          child: Icon(Icons.error, color: Colors.white, size: 16),
        );
      case ImportStatus.processing:
        return const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
    }
  }

  Widget _getStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: result.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        result.status.displayName,
        style: AppTextStyles.labelSmall.copyWith(
          color: result.status.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
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

class ImportResult {
  final String fileName;
  final ImportStatus status;
  final DateTime timestamp;

  ImportResult({
    required this.fileName,
    required this.status,
    required this.timestamp,
  });

  ImportResult copyWith({
    String? fileName,
    ImportStatus? status,
    DateTime? timestamp,
  }) {
    return ImportResult(
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

enum ImportStatus {
  success,
  duplicate,
  error,
  processing;

  String get displayName {
    switch (this) {
      case ImportStatus.success:
        return 'Success';
      case ImportStatus.duplicate:
        return 'Duplicate';
      case ImportStatus.error:
        return 'Error';
      case ImportStatus.processing:
        return 'Processing';
    }
  }

  Color get color {
    switch (this) {
      case ImportStatus.success:
        return AppColors.success;
      case ImportStatus.duplicate:
        return AppColors.warning;
      case ImportStatus.error:
        return AppColors.error;
      case ImportStatus.processing:
        return AppColors.primary;
    }
  }
}