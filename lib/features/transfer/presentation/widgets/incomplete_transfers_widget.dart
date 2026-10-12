import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../discovery/domain/device.dart';
import '../../domain/transfer_session.dart';
import '../transfer_provider.dart';

/// Lists transfers that were interrupted before finishing so the user can
/// resume or discard them.
class IncompleteTransfersWidget extends ConsumerWidget {
  const IncompleteTransfersWidget({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _statusLabel(TransferSession session) {
    if (session.status == TransferSessionStatus.paused) return 'Paused';
    if (session.status == TransferSessionStatus.pending) return 'Waiting';
    if (session.status == TransferSessionStatus.inProgress) return 'In progress';
    if (session.status == TransferSessionStatus.failed) return 'Failed';
    if (session.status == TransferSessionStatus.cancelled) return 'Cancelled';
    return 'Incomplete';
  }

  Device? _deviceFor(TransferSession session) {
    final ip = session.peerIp;
    final port = session.peerPort;
    if (ip == null || port == null) return null;
    return Device(
      id: session.peerId,
      name: session.peerName,
      platform: 'unknown',
      ipAddress: ip,
      port: port,
      discoveredAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessions = ref.watch(
      transferStateProvider.select((s) => s.resumableSessions),
    );

    if (sessions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unfinished transfers',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'These continue automatically when the other device is nearby.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final session in sessions)
            _IncompleteTile(
              session: session,
              statusLabel: _statusLabel(session),
              sizeLabel: _formatBytes(session.totalSizeBytes),
              device: _deviceFor(session),
            ),
        ],
      ),
    );
  }
}

class _IncompleteTile extends ConsumerWidget {
  final TransferSession session;
  final String statusLabel;
  final String sizeLabel;
  final Device? device;

  const _IncompleteTile({
    required this.session,
    required this.statusLabel,
    required this.sizeLabel,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canResume = device != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            session.direction == TransferDirection.sending
                ? Icons.upload_rounded
                : Icons.download_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          session.peerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${session.files.length} file(s) · $sizeLabel · $statusLabel',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: canResume ? 'Resume now' : 'Waiting for device',
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: canResume
                  ? () {
                      ref
                          .read(transferStateProvider.notifier)
                          .resumeTransfer(session, device!);
                    }
                  : null,
            ),
            IconButton(
              tooltip: 'Discard',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDiscard(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Discard transfer?'),
          content: const Text(
            'The partially transferred files will be removed from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref
          .read(transferStateProvider.notifier)
          .discardIncompleteSession(session.transferId);
    }
  }
}
