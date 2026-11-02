import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/merge_space_file.dart';
import '../domain/paired_device.dart';
import 'merge_space_provider.dart';
import 'merge_space_state.dart';

class MergeSpaceScreen extends ConsumerStatefulWidget {
  const MergeSpaceScreen({super.key});

  @override
  ConsumerState<MergeSpaceScreen> createState() => _MergeSpaceScreenState();
}

class _MergeSpaceScreenState extends ConsumerState<MergeSpaceScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(mergeSpaceProvider.notifier).syncNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mergeSpaceProvider);

    if (!state.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.hasGroup) {
      return const _MergeSpaceSetup();
    }
    return _ActiveMergeSpace(state: state);
  }
}

class _MergeSpaceSetup extends ConsumerWidget {
  const _MergeSpaceSetup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(mergeSpaceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Merge Space')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                child: Icon(
                  Icons.sync_rounded,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'One folder, every device',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pair once over Wi-Fi. Files you drop into Merge Space stay in '
              'sync across your own devices, encrypted with a group key that '
              'never leaves your devices.',
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(theme),
            ),
            const SizedBox(height: AppSpacing.xl),
            _FeatureRow(
              icon: Icons.lock_outline_rounded,
              title: 'End-to-end encrypted',
              subtitle: 'AES-256-GCM for every index and file payload.',
            ),
            _FeatureRow(
              icon: Icons.wifi_tethering_rounded,
              title: 'Works nearby',
              subtitle: 'No account, no cloud, no internet required.',
            ),
            _FeatureRow(
              icon: Icons.merge_type_rounded,
              title: 'Conflict-safe',
              subtitle: 'Both versions are kept when edits collide.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton.icon(
              key: const Key('merge-create-button'),
              icon: state.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(state.isBusy ? 'Preparing...' : 'Create Merge Space'),
              onPressed: state.isBusy
                  ? null
                  : () => ref.read(mergeSpaceProvider.notifier).createGroup(),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('merge-join-button'),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Join with pairing code'),
              onPressed:
                  state.isBusy ? null : () => context.push('/merge-space/join'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveMergeSpace extends ConsumerWidget {
  const _ActiveMergeSpace({required this.state});

  final MergeSpaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(mergeSpaceProvider.notifier);
    final group = state.group!;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('merge-add-files'),
        onPressed: state.isBusy ? null : () => notifier.addFilesToSpace(),
        icon: state.isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('Add files'),
      ),
      appBar: AppBar(
        title: const Text('Merge Space'),
        actions: [
          if (state.conflictCount > 0)
            IconButton(
              key: const Key('merge-conflicts-action'),
              tooltip: 'Conflicts',
              icon: Badge(
                label: Text('${state.conflictCount}'),
                child: const Icon(Icons.merge_type_rounded),
              ),
              onPressed: () => context.push('/merge-space/conflicts'),
            ),
          IconButton(
            key: const Key('merge-devices-action'),
            tooltip: 'Paired devices',
            icon: const Icon(Icons.devices_rounded),
            onPressed: () => context.push('/merge-space/devices'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
            await notifier.syncNow();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              _StatusCard(state: state),
              const SizedBox(height: AppSpacing.lg),
              _PairingCard(state: state),
              if (state.nearbyPeers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nearby now',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final peer in state.nearbyPeers)
                      Chip(
                        avatar: Icon(
                          AppIcons.platformFor(peer.platform),
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(peer.deviceName),
                      ),
                  ],
                ),
              ],
              if (state.conflictCount > 0) ...[
                const SizedBox(height: AppSpacing.lg),
                Card(
                  key: const Key('merge-conflicts-banner'),
                  color: theme.colorScheme.tertiaryContainer
                      .withValues(alpha: 0.55),
                  child: ListTile(
                    leading: Icon(
                      Icons.merge_type_rounded,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    title: Text(
                      '${state.conflictCount} file'
                      '${state.conflictCount == 1 ? '' : 's'} need attention',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Both devices changed the same file. Choose what to keep.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/merge-space/conflicts'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text(
                    'In this folder',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${state.fileCount} files',
                    style: AppTextStyles.cardSubtitle(theme),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: state.files.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 36,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Drop files into the Merge Space folder on any '
                              'paired device.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.muted(theme),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < state.files.length; i++) ...[
                            _FileTile(file: state.files[i]),
                            if (i < state.files.length - 1)
                              const Divider(indent: 56, endIndent: 16),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text(
                    'Paired devices',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${state.devices.length}',
                    style: AppTextStyles.cardSubtitle(theme),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: state.devices.isEmpty
                    ? ListTile(
                        leading: const Icon(Icons.devices_other_rounded),
                        title: const Text('No devices paired yet'),
                        subtitle: const Text(
                          'Show the pairing code to another device you own.',
                        ),
                        onTap: () => context.push('/merge-space/join'),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < state.devices.length; i++) ...[
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.secondaryContainer,
                                child: Icon(
                                  AppIcons.platformFor(
                                    state.devices[i].platform,
                                  ),
                                  size: 20,
                                ),
                              ),
                              title: Text(state.devices[i].deviceName),
                              subtitle: Text(
                                _syncLabel(state.devices[i].syncStatus),
                              ),
                              trailing: Icon(
                                state.nearbyPeers.any(
                                  (peer) =>
                                      peer.deviceId ==
                                      state.devices[i].deviceId,
                                )
                                    ? Icons.wifi_rounded
                                    : Icons.cloud_off_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (i < state.devices.length - 1)
                              const Divider(indent: 56, endIndent: 16),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Group ${group.groupId.substring(0, 8)}',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle(theme),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                key: const Key('merge-unpair-button'),
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Leave Merge Space'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () => _confirmUnpair(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _syncLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pendingSync:
        return 'Waiting to sync';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.error:
        return 'Sync error';
    }
  }

  Future<void> _confirmUnpair(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this Merge Space?'),
        content: const Text(
          'The paired devices and local index will be removed. Files already '
          'in the Merge Space folder stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(mergeSpaceProvider.notifier).unpair();
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.state});

  final MergeSpaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncing = state.isSyncing;
    final hasConflicts = state.conflictCount > 0;
    final details = state.lastSyncedAt == null
        ? 'Not synced yet'
        : 'Last synced ${_relativeTime(state.lastSyncedAt!)}'
            '${state.lastTransferCount > 0 ? ' · ${state.lastTransferCount} transferred' : ''}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: syncing
                        ? theme.colorScheme.tertiary
                        : hasConflicts
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _globalStatus(state),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  key: const Key('merge-sync-button'),
                  icon: syncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('Sync now'),
                  onPressed: syncing
                      ? null
                      : () => ref.read(mergeSpaceProvider.notifier).syncNow(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(details, style: AppTextStyles.cardSubtitle(theme)),
            const SizedBox(height: 4),
            Text(
              '${_formatBytes(state.totalBytes)} · ${state.fileCount} files',
              style: AppTextStyles.cardSubtitle(theme),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _ErrorBanner(message: state.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  static String _globalStatus(MergeSpaceState state) {
    if (state.isSyncing) return 'Syncing...';
    if (state.conflictCount > 0) {
      final count = state.conflictCount;
      return '$count conflict${count == 1 ? '' : 's'} to review';
    }
    if (state.devices.isEmpty) return 'Waiting for a paired device';
    final pending = state.devices
        .where((device) => device.syncStatus != SyncStatus.synced)
        .length;
    if (pending > 0) {
      return '$pending device${pending == 1 ? '' : 's'} pending';
    }
    return 'All synced';
  }

  static String _relativeTime(DateTime time) {
    final delta = DateTime.now().difference(time);
    if (delta.inSeconds < 30) return 'just now';
    if (delta.inMinutes < 1) return '${delta.inSeconds}s ago';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.state});

  final MergeSpaceState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = state.pairingUri;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pair another device',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (uri == null)
              Text(
                'Pairing code unavailable on this network. Join from another '
                'device using a pairing code shown there.',
                style: AppTextStyles.muted(theme),
              )
            else ...[
              Center(
                child: QrImageView(
                  key: const Key('merge-pairing-qr'),
                  data: uri,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SelectableText(
                uri,
                key: const Key('merge-pairing-link'),
                textAlign: TextAlign.center,
                maxLines: 3,
                style: AppTextStyles.cardSubtitle(theme),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Scan this with your other device, or paste the pairing code '
                'on its Join screen.',
                textAlign: TextAlign.center,
                style: AppTextStyles.cardSubtitle(theme),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Encrypted group · ${state.group!.groupId.substring(0, 8)}',
                      style: AppTextStyles.cardSubtitle(theme),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Copy pairing code',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: uri));
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Pairing code copied')),
                        );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file});

  final MergeSpaceFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final synced = file.baseHash != null && file.baseHash == file.hash;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.insert_drive_file_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(file.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        file.directory.isEmpty ? file.extension : file.directory,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatBytes(file.sizeBytes),
            style: AppTextStyles.cardSubtitle(theme),
          ),
          const SizedBox(height: 2),
          Icon(
            synced ? Icons.cloud_done_outlined : Icons.schedule_rounded,
            key: Key('file-status-${file.relativePath}'),
            size: 14,
            color: synced
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.muted(theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
