import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/transfer_progress.dart';
import 'transfer_provider.dart';

class TransferProgressScreen extends ConsumerWidget {
  final String transferId;

  const TransferProgressScreen({
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
    final targetDevice = transferState.selectedTargetDevice;

    // Listen for completion and navigate
    ref.listen(transferStateProvider.select((s) => s.activeProgress?.status),
        (prev, next) {
      if (next != null && next.isFinished) {
        // Can navigate to complete screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.go('/send/complete/${progress?.transferId ?? transferId}');
          }
        });
      }
    });

    final currentFile = progress?.currentFileName ?? 'Preparing files...';
    final percentage = progress?.percentage ?? 0.0;
    final status = progress?.status ?? TransferStatus.pending;
    final isResuming = progress?.isResuming ?? false;
    final isConnectionLost = progress?.isConnectionLost ?? false;

    final String centerLabel;
    if (status == TransferStatus.pending) {
      centerLabel = 'Waiting...';
    } else if (status == TransferStatus.rejected) {
      centerLabel = 'Rejected';
    } else if (status == TransferStatus.completed) {
      centerLabel = 'Done!';
    } else if (status == TransferStatus.cancelled) {
      centerLabel = 'Cancelled';
    } else if (status == TransferStatus.failed) {
      centerLabel = 'Failed';
    } else if (isConnectionLost) {
      centerLabel = 'Paused';
    } else if (isResuming) {
      centerLabel = 'Resuming';
    } else {
      centerLabel = 'Transferring';
    }

    String? resumeHint;
    if (isConnectionLost) {
      resumeHint = 'Connection lost — will resume when device is found';
    } else if (isResuming) {
      resumeHint = 'Resuming transfer...';
    }

    final chunkLabel = progress?.chunkLabel;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmCancel(context, ref, progress?.transferId ?? transferId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transferring'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Progress Graphic
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: status == TransferStatus.pending ? null : percentage,
                        strokeWidth: 10,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          centerLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isConnectionLost
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Target Device & Current File
                Text(
                  targetDevice != null
                      ? 'Sending to ${targetDevice.name}'
                      : 'File Transfer in Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentFile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                if (progress != null && progress.totalFiles > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'File ${(progress.currentFileIndex + 1).clamp(1, progress.totalFiles)} of ${progress.totalFiles}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                if (resumeHint != null || chunkLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        if (resumeHint != null)
                          Text(
                            resumeHint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isConnectionLost
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (resumeHint != null && chunkLabel != null)
                          const SizedBox(height: 2),
                        if (chunkLabel != null && chunkLabel != resumeHint)
                          Text(
                            chunkLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Stats Cards (Transferred, Speed, ETA)
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Transferred',
                        value: progress != null
                            ? '${_formatBytes(progress.bytesTransferred)} / ${_formatBytes(progress.totalBytes)}'
                            : '0 B',
                        icon: Icons.data_usage_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'Speed',
                        value: progress?.speedFormatted ?? '0 B/s',
                        icon: Icons.speed_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'ETA',
                        value: progress?.etaFormatted ?? '--:--',
                        icon: Icons.timer_outlined,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Cancel / Abort Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Transfer'),
                    onPressed: () {
                      _confirmCancel(context, ref, progress?.transferId ?? transferId);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel Transfer?'),
          content: const Text(
            'Are you sure you want to stop this transfer? Incomplete files will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continue Transfer'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(transferStateProvider.notifier).cancelTransfer(id);
                context.go('/send/complete/$id');
              },
              child: const Text('Cancel Transfer'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
