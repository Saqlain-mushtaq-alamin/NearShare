import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/room_transfer_progress.dart';
import 'room_provider.dart';

/// Per-member broadcast progress.
class RoomTransferProgressScreen extends ConsumerWidget {
  final String roomId;

  const RoomTransferProgressScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(roomProvider);
    final summary = state.transferSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Transfer'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: summary == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        state.isHost
                            ? 'Preparing the broadcast...'
                            : 'Waiting for files from the host...',
                        style: AppTextStyles.muted(theme),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverallCard(summary: summary),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Per device',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.separated(
                        itemCount: summary.members.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _MemberProgressCard(
                          progress: summary.members[index],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Back to Room'),
                      onPressed: () =>
                          context.go('/rooms/active/$roomId'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.summary});

  final RoomTransferSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final percentage = (summary.overallPercentage * 100).round();
    final finished = summary.isFinished;

    return Card(
      color: palette.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  finished
                      ? (summary.hasFailures
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded)
                      : Icons.campaign_rounded,
                  color: finished && summary.hasFailures
                      ? palette.error
                      : palette.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    finished
                        ? 'Broadcast finished'
                        : 'Sending to ${summary.totalMembers} devices',
                    style: AppTextStyles.cardTitle(theme),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                key: const Key('room-overall-progress'),
                value: summary.overallPercentage,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${summary.completedCount} complete · '
              '${summary.failedCount} failed · '
              '${summary.totalMembers} total',
              style: AppTextStyles.cardSubtitle(theme),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberProgressCard extends StatelessWidget {
  const _MemberProgressCard({required this.progress});

  final RoomMemberProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;

    final (IconData icon, Color color, String label) = switch (progress.status) {
      RoomMemberTransferStatus.completed => (
          Icons.check_circle_rounded,
          palette.primary,
          'Completed'
        ),
      RoomMemberTransferStatus.failed => (
          Icons.error_outline_rounded,
          palette.error,
          'Failed'
        ),
      RoomMemberTransferStatus.sending => (
          Icons.sync_rounded,
          palette.secondary,
          'Sending'
        ),
      RoomMemberTransferStatus.idle => (
          Icons.schedule_rounded,
          palette.onSurfaceVariant,
          'Waiting'
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    progress.deviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle(theme),
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.percentage,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              progress.errorMessage ??
                  '${formatBytes(progress.bytesTransferred)} / '
                      '${formatBytes(progress.totalBytes)}'
                      '${progress.totalFiles > 0 ? ' · ${progress.filesCompleted}/${progress.totalFiles} files' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardSubtitle(theme),
            ),
          ],
        ),
      ),
    );
  }
}
