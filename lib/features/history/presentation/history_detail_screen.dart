import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../discovery/presentation/discovery_provider.dart';
import '../../../shared/utils/file_launcher.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/file_kind.dart';
import '../domain/transfer_record.dart';
import '../../transfer/presentation/transfer_provider.dart';
import 'history_item_widget.dart';
import 'history_provider.dart';

/// Everything this device knows about a single finished transfer.
class HistoryDetailScreen extends ConsumerWidget {
  final String transferId;

  /// Injectable so widget tests never touch the real filesystem.
  final FileLauncher launcher;

  const HistoryDetailScreen({
    super.key,
    required this.transferId,
    this.launcher = const FileLauncher(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(historyRecordProvider(transferId));
    final theme = Theme.of(context);

    return recordAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Transfer')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Transfer')),
        body: Center(child: Text('Could not load transfer: $error')),
      ),
      data: (record) {
        if (record == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Transfer')),
            body: const Center(child: Text('This transfer no longer exists.')),
          );
        }
        return _DetailBody(
          record: record,
          theme: theme,
          launcher: launcher,
          onResend: () => _resend(context, ref, record),
          onDelete: () => _delete(context, ref, record),
        );
      },
    );
  }

  Future<void> _resend(
    BuildContext context,
    WidgetRef ref,
    TransferRecord record,
  ) async {
    final devices = ref.read(discoveryStateProvider.select((s) => s.devices));
    final outcome = await ref
        .read(transferStateProvider.notifier)
        .startResend(record, availableDevices: devices);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!outcome.canSend) {
      messenger.showSnackBar(
        SnackBar(content: Text(outcome.missingFilesMessage)),
      );
      return;
    }
    if (outcome.hasMissingFiles) {
      messenger.showSnackBar(
        SnackBar(content: Text(outcome.missingFilesMessage)),
      );
    }
    unawaited(context.push('/send/select-device'));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransferRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete transfer history?'),
          content: Text(
            'Remove the transfer with ${record.peerDeviceName} from history? '
            'The files themselves are not deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(historyProvider.notifier).deleteRecord(record.transferId);
    if (context.mounted) context.pop();
  }
}

class _DetailBody extends StatelessWidget {
  final TransferRecord record;
  final ThemeData theme;
  final FileLauncher launcher;
  final VoidCallback onResend;
  final VoidCallback onDelete;

  const _DetailBody({
    required this.record,
    required this.theme,
    required this.launcher,
    required this.onResend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = record.isSent;
    final completed = record.completedFiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(record.peerDeviceName),
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            tooltip: 'Delete from history',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isSent
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.tertiaryContainer,
                        child: Icon(
                          isSent ? Icons.north_east : Icons.south_west,
                          size: 20,
                          color: isSent
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${record.directionLabel} · '
                          '${fileCountLabel(record.totalFiles, record.totalSizeBytes)}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      _StatusBadge(status: record.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Started ${formatTimestamp(record.timestamp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (record.completedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Finished ${formatTimestamp(record.completedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Files',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (record.files.isEmpty)
            Text(
              'No file details were recorded.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final file in record.files) ...[
              _FileTile(file: file, launcher: launcher),
              const Divider(height: 1),
            ],
          const SizedBox(height: 20),
          if (isSent)
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Resend'),
              onPressed: record.files.isEmpty ? null : onResend,
            )
          else if (completed.isNotEmpty) ...[
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open File'),
              onPressed: () => _open(context, completed.first.localPath, false),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Folder'),
              onPressed: () => _open(context, completed.first.localPath, true),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    String? path,
    bool folder,
  ) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This file is no longer on this device.')),
      );
      return;
    }
    final ok =
        folder ? await launcher.openFolder(path) : await launcher.openFile(path);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this file.')),
      );
    }
  }
}

class _FileTile extends StatelessWidget {
  final TransferFileRecord file;
  final FileLauncher launcher;

  const _FileTile({required this.file, required this.launcher});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = FileKind.fromFileName(file.fileName);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          fileKindIcon(kind),
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        file.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${formatBytes(file.fileSizeBytes)} · ${kind.label}'
        '${file.isCompleted ? '' : ' · incomplete'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: file.isCompleted
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.error,
        ),
      ),
      trailing: file.localPath == null || file.localPath!.isEmpty
          ? null
          : IconButton(
              tooltip: 'Open file',
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () async {
                final ok = await launcher.openFile(file.localPath!);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open this file.')),
                  );
                }
              },
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransferRecordStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color, icon) = switch (status) {
      TransferRecordStatus.completed => ('Completed', Colors.green, Icons.check_circle),
      TransferRecordStatus.failed => ('Failed', theme.colorScheme.error, Icons.cancel),
      TransferRecordStatus.cancelled => (
          'Cancelled',
          theme.colorScheme.onSurfaceVariant,
          Icons.remove_circle_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
