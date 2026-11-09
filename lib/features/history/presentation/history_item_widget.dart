import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../shared/utils/formatters.dart';
import '../domain/file_kind.dart';
import '../domain/transfer_record.dart';

/// One row in the history list.
///
/// Swipe right to resend a sent transfer, swipe left to delete it.
class HistoryItemWidget extends StatelessWidget {
  final TransferRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onResend;

  /// When false the resend affordance is hidden (received transfers).
  final bool canResend;

  const HistoryItemWidget({
    super.key,
    required this.record,
    this.onTap,
    this.onDelete,
    this.onResend,
    this.canResend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSent = record.isSent;

    return Semantics(
      button: onTap != null,
      label: _semanticLabel,
      hint: onTap == null ? null : 'Double tap for details',
      onTap: onTap,
      excludeSemantics: true,
      customSemanticsActions: {
        if (onResend != null)
          const CustomSemanticsAction(label: 'Resend'): onResend!,
        if (onDelete != null)
          const CustomSemanticsAction(label: 'Delete'): () {
            unawaited(_deleteWithConfirmation(context));
          },
      },
      child: Dismissible(
        key: ValueKey('history-${record.transferId}'),
        direction: canResend
            ? DismissDirection.horizontal
            : DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.startToEnd: 0.4},
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onResend?.call();
            return false;
          }
          return _confirmDelete(context, theme);
        },
        onDismissed: (_) => onDelete?.call(),
        background: Container(
          color: theme.colorScheme.primaryContainer,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child:
              Icon(Icons.refresh, color: theme.colorScheme.onPrimaryContainer),
        ),
        secondaryBackground: Container(
          color: theme.colorScheme.errorContainer,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.peerDeviceName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.directionLabel} · '
                          '${fileCountLabel(record.totalFiles, record.totalSizeBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_statusLabel · ${formatTimestamp(record.timestamp)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _statusColor(theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusIcon(status: record.status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    final direction = record.isSent ? 'Sent to' : 'Received from';
    return '$direction ${record.peerDeviceName}, '
        '${fileCountLabel(record.totalFiles, record.totalSizeBytes)}, '
        '$_statusLabel, ${formatTimestamp(record.timestamp)}';
  }

  Future<void> _deleteWithConfirmation(BuildContext context) async {
    final confirmed = await _confirmDelete(context, Theme.of(context));
    if (confirmed) onDelete?.call();
  }

  String get _statusLabel {
    switch (record.status) {
      case TransferRecordStatus.completed:
        return 'Completed';
      case TransferRecordStatus.failed:
        return 'Failed';
      case TransferRecordStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(ThemeData theme) {
    switch (record.status) {
      case TransferRecordStatus.completed:
        return theme.colorScheme.primary;
      case TransferRecordStatus.failed:
        return theme.colorScheme.error;
      case TransferRecordStatus.cancelled:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Future<bool> _confirmDelete(BuildContext context, ThemeData theme) async {
    final result = await showDialog<bool>(
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
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _StatusIcon extends StatelessWidget {
  final TransferRecordStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case TransferRecordStatus.completed:
        return Icon(Icons.check_circle, color: Colors.green, size: 22);
      case TransferRecordStatus.failed:
        return Icon(Icons.cancel, color: theme.colorScheme.error, size: 22);
      case TransferRecordStatus.cancelled:
        return Icon(
          Icons.remove_circle_outline,
          color: theme.colorScheme.onSurfaceVariant,
          size: 22,
        );
    }
  }
}

/// Leading glyph used on the detail screen for a single file.
IconData fileKindIcon(FileKind kind) {
  switch (kind) {
    case FileKind.image:
      return Icons.image_outlined;
    case FileKind.video:
      return Icons.videocam_outlined;
    case FileKind.audio:
      return Icons.audio_file_outlined;
    case FileKind.archive:
      return Icons.folder_zip_outlined;
    case FileKind.document:
      return Icons.description_outlined;
    case FileKind.other:
      return Icons.insert_drive_file_outlined;
  }
}
