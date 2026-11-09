import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/is_test_env.dart';
import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/device_list_widget.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../history/domain/transfer_record.dart';
import '../../history/presentation/history_provider.dart';
import '../../settings/application/settings_provider.dart';
import '../../transfer/presentation/transfer_provider.dart';
import '../../transfer/presentation/widgets/incoming_transfer_sheet.dart';
import '../../transfer/presentation/widgets/incomplete_transfers_widget.dart';

/// The app's home base: send, see who's around, and pick up where you left off.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _onDeviceTapped(BuildContext context, WidgetRef ref, Device device) {
    ref.read(transferStateProvider.notifier).setSelectedTargetDevice(device);
    unawaited(
      ref.read(settingsProvider.notifier).setLastUsedDevice(device),
    );
    context.push('/send');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discoveryState = ref.watch(discoveryStateProvider);
    final localDevice = discoveryState.localDevice;
    final recentHistory = ref.watch(
      historyProvider.select((s) => s.records.take(4).toList()),
    );

    ref.listen(
      transferStateProvider.select((s) => s.pendingIncomingRequest),
      (prev, next) {
        if (next == null) return;
        IncomingTransferSheet.show(
          context,
          request: next,
          onAccept: () {
            ref
                .read(transferStateProvider.notifier)
                .acceptIncomingTransfer(next.transferId);
            context.push('/send/progress/${next.transferId}');
          },
          onReject: () {
            ref
                .read(transferStateProvider.notifier)
                .rejectIncomingTransfer(next.transferId);
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(size: 30, padding: 5, background: Color(0xFF1A4BCF)),
            const SizedBox(width: 10),
            const Text(
              'NearShare',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('home-refresh-button'),
            tooltip: 'Refresh discovery',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(discoveryStateProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            96,
          ),
          children: [
            _SendCard(
              isReceiving: discoveryState.isBroadcasting,
              onSend: () => context.push('/send'),
              onToggleReceive: discoveryState.isBroadcasting
                  ? () =>
                      ref.read(discoveryStateProvider.notifier).stopBroadcast()
                  : () => ref
                      .read(discoveryStateProvider.notifier)
                      .startBroadcast(),
            ),
            if (localDevice != null) ...[
              const SizedBox(height: AppSpacing.md),
              _ThisDeviceCard(device: localDevice),
            ],
            const SizedBox(height: AppSpacing.lg),
            _IncompleteSection(theme: theme),
            DeviceListWidget(
              shrinkWrap: true,
              onDeviceSelected: (device) =>
                  _onDeviceTapped(context, ref, device),
            ),
            if (recentHistory.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _RecentTransfersSection(records: recentHistory),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(AppIcons.send),
        label: const Text('Send'),
        onPressed: () => context.push('/send'),
      ),
    );
  }
}

class _SendCard extends StatelessWidget {
  const _SendCard({
    required this.isReceiving,
    required this.onSend,
    required this.onToggleReceive,
  });

  final bool isReceiving;
  final VoidCallback onSend;
  final VoidCallback onToggleReceive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: const ValueKey('home-send-files'),
          button: true,
          label: 'Send files to a nearby device',
          hint: 'Opens the file picker',
          onTap: onSend,
          excludeSemantics: true,
          child: Material(
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isReceiving
                      ? [const Color(0xFF1A4BCF), const Color(0xFF2F6BF0)]
                      : [
                          theme.colorScheme.primary.withValues(alpha: 0.85),
                          theme.colorScheme.primary,
                        ],
                ),
              ),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          AppIcons.send,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send files',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Photos, videos, docs — straight to a nearby device',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          key: const ValueKey('home-receive-toggle'),
          button: true,
          toggled: isReceiving,
          label:
              isReceiving ? 'Receiving files is on' : 'Receiving files is off',
          hint: isReceiving ? 'Double tap to pause' : 'Double tap to resume',
          onTap: onToggleReceive,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: InkWell(
              onTap: onToggleReceive,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: _PulsingDot(active: isReceiving),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isReceiving
                            ? 'Ready to receive'
                            : 'Receiving is paused',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isReceiving
                              ? AppTheme.paletteOf(context).success
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isReceiving ? 'Tap to pause' : 'Tap to resume',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dot that breathes while the receive server is up.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.active});

  final bool active;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  /// Under `flutter test` infinite animations block pumpAndSettle, so the dot
  /// stays put and only pulses in a real app.
  static final bool _allowAnimation = !isRunningUnderTest;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active && _allowAnimation) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_allowAnimation) return;
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final color = widget.active ? palette.success : themeGrey(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45 - 0.25 * t),
                      blurRadius: 6 + 6 * t,
                      spreadRadius: 1 + 3 * t,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Color themeGrey(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}

class _ThisDeviceCard extends StatelessWidget {
  const _ThisDeviceCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            AppIcons.platformFor(device.platform),
            size: 22,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          device.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cardTitle(theme),
        ),
        subtitle: Text(
          'This device · ${device.platform.toUpperCase()}',
          style: AppTextStyles.cardSubtitle(theme),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () => context.push('/settings'),
      ),
    );
  }
}

class _IncompleteSection extends ConsumerWidget {
  const _IncompleteSection({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      transferStateProvider.select((s) => s.resumableSessions.length),
    );
    if (count == 0) return const SizedBox.shrink();

    final palette = AppTheme.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(Icons.pause_circle_outline, color: palette.warning),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'transfer' : 'transfers'} paused — '
                    'resume or discard below',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const IncompleteTransfersWidget(),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _RecentTransfersSection extends StatelessWidget {
  const _RecentTransfersSection({required this.records});

  final List<TransferRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent transfers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/history'),
              child: const Text('See all'),
            ),
          ],
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                _RecentTile(record: records[i]),
                if (i < records.length - 1)
                  const Divider(indent: 56, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.record});

  final TransferRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.paletteOf(context);
    final sent = record.isSent;
    final done = record.status == TransferRecordStatus.completed;

    final Color statusColor;
    final IconData statusIcon;
    if (done) {
      statusColor = palette.success;
      statusIcon =
          sent ? Icons.check_rounded : Icons.file_download_done_rounded;
    } else if (record.status == TransferRecordStatus.failed) {
      statusColor = palette.error;
      statusIcon = Icons.error_outline_rounded;
    } else {
      statusColor = palette.warning;
      statusIcon = Icons.timelapse_rounded;
    }

    return ListTile(
      dense: false,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.14),
        child: Icon(statusIcon, size: 20, color: statusColor),
      ),
      title: Text(
        record.peerDeviceName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.cardTitle(theme),
      ),
      subtitle: Text(
        '${sent ? 'Sent' : 'Received'} · ${fileCountLabel(record.totalFiles, record.totalSizeBytes)}',
        style: AppTextStyles.cardSubtitle(theme),
      ),
      trailing: Text(
        formatTimestamp(record.timestamp),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => context.push('/history/${record.transferId}'),
    );
  }
}
