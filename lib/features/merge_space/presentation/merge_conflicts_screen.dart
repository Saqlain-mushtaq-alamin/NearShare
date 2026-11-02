import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../data/merge_sync_service.dart';
import '../domain/merge_space_file.dart';
import '../domain/sync_conflict.dart';
import 'merge_space_provider.dart';
import 'merge_space_state.dart';

class MergeConflictsScreen extends ConsumerWidget {
  const MergeConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mergeSpaceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Resolve conflicts')),
      body: state.conflicts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No conflicts to resolve',
                      style: AppTextStyles.muted(theme),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: state.conflicts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _ConflictCard(
                  conflict: state.conflicts[index],
                  index: index,
                );
              },
            ),
    );
  }
}

class _ConflictCard extends ConsumerWidget {
  const _ConflictCard({required this.conflict, required this.index});

  final SyncConflict conflict;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(mergeSpaceProvider);
    final notifier = ref.read(mergeSpaceProvider.notifier);
    final local = conflict.localVersion;
    final remote = conflict.remoteVersion;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.merge_type_rounded,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    local.fileName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (local.directory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  local.directory,
                  style: AppTextStyles.cardSubtitle(theme),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _VersionRow(
              label: 'This device',
              file: local,
              origin: _originName(state, local.originDeviceId),
              icon: Icons.phone_android_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _VersionRow(
              label: 'Other device',
              file: remote,
              origin: _originName(state, remote.originDeviceId),
              icon: Icons.devices_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  key: Key('conflict-keep-local-$index'),
                  onPressed: state.isBusy
                      ? null
                      : () => notifier.resolveConflict(
                            conflict,
                            MergeConflictResolution.keepLocal,
                          ),
                  child: const Text('Keep mine'),
                ),
                OutlinedButton(
                  key: Key('conflict-keep-remote-$index'),
                  onPressed: state.isBusy
                      ? null
                      : () => notifier.resolveConflict(
                            conflict,
                            MergeConflictResolution.keepRemote,
                          ),
                  child: const Text('Keep theirs'),
                ),
                FilledButton(
                  key: Key('conflict-keep-both-$index'),
                  onPressed: state.isBusy || local.isDeleted || remote.isDeleted
                      ? null
                      : () => notifier.resolveConflict(
                            conflict,
                            MergeConflictResolution.keepBoth,
                          ),
                  child: const Text('Keep both'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _originName(MergeSpaceState state, String deviceId) {
    if (deviceId.isEmpty) return 'Unknown device';
    if (deviceId == state.localDevice?.deviceId) return 'This device';
    for (final device in state.devices) {
      if (device.deviceId == deviceId) return device.deviceName;
    }
    return deviceId;
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.file,
    required this.origin,
    required this.icon,
  });

  final String label;
  final MergeSpaceFile file;
  final String origin;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = file.isDeleted
        ? 'Deleted · ${_relativeTime(file.modifiedAt)}'
        : '${_formatBytes(file.sizeBytes)} · ${_relativeTime(file.modifiedAt)}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$origin · $detail',
                  style: AppTextStyles.cardSubtitle(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime time) {
    final delta = DateTime.now().difference(time);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
