import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/device.dart';
import '../domain/discovery_state.dart';
import 'discovery_provider.dart';
import 'widgets/device_card.dart';
import 'widgets/scanning_radar_widget.dart';

class DeviceListWidget extends ConsumerWidget {
  final ValueChanged<Device>? onDeviceSelected;

  const DeviceListWidget({
    super.key,
    this.onDeviceSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discoveryState = ref.watch(discoveryStateProvider);
    final isScanning = discoveryState.status == DiscoveryStatus.scanning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Nearby Devices',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (discoveryState.devices.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${discoveryState.devices.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              // Scan Toggle Button
              TextButton.icon(
                onPressed: () {
                  final notifier = ref.read(discoveryStateProvider.notifier);
                  if (isScanning) {
                    notifier.stopScanning();
                  } else {
                    notifier.startScanning();
                  }
                },
                icon: Icon(
                  isScanning ? Icons.pause_circle_outline : Icons.refresh,
                  size: 18,
                ),
                label: Text(isScanning ? 'Pause' : 'Scan'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),

        // Error message banner if present
        if (discoveryState.errorMessage != null &&
            discoveryState.errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: MaterialBanner(
              padding: const EdgeInsets.all(12),
              leading: const Icon(Icons.error_outline, color: Colors.amber),
              content: Text(
                discoveryState.errorMessage!,
                style: theme.textTheme.bodySmall,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(discoveryStateProvider.notifier).refresh();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

        // Body: Device list or Empty / Scanning State
        if (discoveryState.devices.isEmpty)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScanningRadarWidget(
                        size: 160,
                        isScanning: isScanning,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isScanning
                            ? 'Scanning local Wi-Fi...'
                            : 'Discovery is paused',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isScanning
                            ? 'Ensure other devices are connected to the same Wi-Fi network and have NearShare open.'
                            : 'Tap "Scan" to find nearby devices on your Wi-Fi network.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: discoveryState.devices.length,
              itemBuilder: (context, index) {
                final device = discoveryState.devices[index];
                return DeviceCard(
                  device: device,
                  onTap: () {
                    onDeviceSelected?.call(device);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
