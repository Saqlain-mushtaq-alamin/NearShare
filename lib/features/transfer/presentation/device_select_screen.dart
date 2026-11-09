import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_spacing.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/domain/discovery_state.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../discovery/presentation/widgets/device_card.dart';
import '../../discovery/presentation/widgets/scanning_radar_widget.dart';
import '../../settings/application/settings_provider.dart';
import 'transfer_provider.dart';

class DeviceSelectScreen extends ConsumerWidget {
  const DeviceSelectScreen({super.key});

  void _onDeviceSelected(BuildContext context, WidgetRef ref, Device device) {
    ref.read(transferStateProvider.notifier).setSelectedTargetDevice(device);
    ref.read(settingsProvider.notifier).setLastUsedDevice(device);
    context.push('/send/confirm');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discoveryState = ref.watch(discoveryStateProvider);
    final lastUsedId = ref.watch(
      settingsProvider.select((s) => s.lastUsedDeviceId),
    );
    final devices = discoveryState.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Recipient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh nearby devices',
            onPressed: () {
              ref.read(discoveryStateProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScanningRadarWidget(
                      size: 160,
                      isScanning:
                          discoveryState.status == DiscoveryStatus.scanning,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Searching for nearby devices…',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Make sure both devices are on the same Wi-Fi and have '
                      'NearShare open.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Nearby Devices (${devices.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        tag: device.id == lastUsedId ? 'Last used' : null,
                        onTap: () => _onDeviceSelected(context, ref, device),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
