import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_icons.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../domain/paired_device.dart';
import 'merge_space_provider.dart';

class MergeDevicesScreen extends ConsumerWidget {
  const MergeDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mergeSpaceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Paired devices')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Every device listed here shares the same encrypted Merge Space.',
            style: AppTextStyles.muted(theme),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (state.devices.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.devices_other_rounded),
                title: const Text('No paired devices yet'),
                subtitle: const Text(
                  'Create a pairing code on the Merge Space screen and scan it '
                  'from another device.',
                ),
                onTap: () => context.push('/merge-space/join'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < state.devices.length; i++) ...[
                    _DeviceTile(
                      device: state.devices[i],
                      nearby: state.nearbyPeers.any(
                        (peer) =>
                            peer.deviceId == state.devices[i].deviceId,
                      ),
                      onRemove: () => _confirmRemove(
                        context,
                        ref,
                        state.devices[i],
                      ),
                    ),
                    if (i < state.devices.length - 1)
                      const Divider(indent: 56, endIndent: 16),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            key: const Key('merge-add-device-button'),
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Show pairing code'),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.nearby,
    required this.onRemove,
  });

  final PairedDevice device;
  final bool nearby;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(
          AppIcons.platformFor(device.platform),
          size: 20,
        ),
      ),
      title: Text(device.deviceName),
      subtitle: Text(_detail),
      trailing: IconButton(
        key: Key('merge-remove-device-${device.deviceId}'),
        tooltip: 'Remove device',
        icon: Icon(
          nearby ? Icons.wifi_rounded : Icons.cloud_off_rounded,
          color: nearby
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        onPressed: onRemove,
      ),
    );
  }

  String get _detail {
    final last = device.lastSyncedAt;
    final status = nearby ? 'Nearby · ready to sync' : 'Not nearby';
    if (last == null) return status;
    return '$status · last synced ${_relative(last)}';
  }

  static String _relative(DateTime time) {
    final delta = DateTime.now().difference(time);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes}m ago';
    if (delta.inDays < 1) return '${delta.inHours}h ago';
    return '${delta.inDays}d ago';
  }
}

Future<void> _confirmRemove(
  BuildContext context,
  WidgetRef ref,
  PairedDevice device,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove device?'),
      content: Text(
        '${device.deviceName} will stop receiving sync updates from this '
        'device. Files already in the Merge Space stay where they are.',
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
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await ref.read(mergeSpaceProvider.notifier).removeDevice(device.deviceId);
}
