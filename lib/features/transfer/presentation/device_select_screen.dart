import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../discovery/presentation/widgets/device_card.dart';
import '../../discovery/presentation/widgets/scanning_radar_widget.dart';
import 'transfer_provider.dart';

class DeviceSelectScreen extends ConsumerWidget {
  const DeviceSelectScreen({super.key});

  void _onDeviceSelected(BuildContext context, WidgetRef ref, Device device) {
    ref.read(transferStateProvider.notifier).setSelectedTargetDevice(device);
    context.push('/send/confirm');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discoveryState = ref.watch(discoveryStateProvider);
    final devices = discoveryState.devices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Recipient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Nearby Devices',
            onPressed: () {
              ref.read(discoveryStateProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: devices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ScanningRadarWidget(size: 160),
                    const SizedBox(height: 24),
                    Text(
                      'Searching for nearby devices...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure the other device has NearShare open on the same Wi-Fi network.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
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
