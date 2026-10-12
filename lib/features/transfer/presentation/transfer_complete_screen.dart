import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/transfer_progress.dart';
import 'transfer_provider.dart';

class TransferCompleteScreen extends ConsumerWidget {
  final String transferId;

  const TransferCompleteScreen({
    super.key,
    required this.transferId,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transferState = ref.watch(transferStateProvider);
    final progress = transferState.activeProgress;
    final status = progress?.status ?? TransferStatus.completed;

    final isSuccess = status == TransferStatus.completed;
    final isRejected = status == TransferStatus.rejected;
    final isCancelled = status == TransferStatus.cancelled;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    if (isSuccess) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusTitle = 'Transfer Complete!';
      statusDescription = progress != null
          ? 'Successfully transferred ${progress.totalFiles} ${progress.totalFiles == 1 ? "file" : "files"} (${_formatBytes(progress.bytesTransferred)}).'
          : 'All files have been successfully transferred.';
    } else if (isRejected) {
      statusColor = Colors.orange;
      statusIcon = Icons.block_flipped;
      statusTitle = 'Transfer Declined';
      statusDescription = 'The recipient declined the transfer request.';
    } else if (isCancelled) {
      statusColor = Colors.grey;
      statusIcon = Icons.cancel_rounded;
      statusTitle = 'Transfer Cancelled';
      statusDescription = 'The file transfer was cancelled by user.';
    } else {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.error_outline_rounded;
      statusTitle = 'Transfer Failed';
      statusDescription = progress?.errorMessage ??
          transferState.errorMessage ??
          'An unexpected network error occurred during transfer.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Status'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Status Icon Graphic
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: 80,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                statusTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                statusDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              if (progress != null && isSuccess)
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Files',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${progress.totalFiles}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        Column(
                          children: [
                            Text(
                              'Size',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatBytes(progress.bytesTransferred),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        Column(
                          children: [
                            Text(
                              'Avg Speed',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              progress.speedFormatted,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Navigation Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ref.read(transferStateProvider.notifier).clearActiveTransfer();
                        context.go('/send');
                      },
                      child: const Text('Send More'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ref.read(transferStateProvider.notifier).clearActiveTransfer();
                        context.go('/');
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
