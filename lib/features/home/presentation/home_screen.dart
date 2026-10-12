import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../discovery/domain/device.dart';
import '../../discovery/presentation/device_list_widget.dart';
import '../../discovery/presentation/discovery_provider.dart';
import '../../transfer/presentation/transfer_provider.dart';
import '../../transfer/presentation/widgets/incoming_transfer_dialog.dart';
import '../../transfer/presentation/widgets/incomplete_transfers_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Device Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Device Name',
              hintText: 'e.g. My MacBook / Phone',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref.read(discoveryStateProvider.notifier).updateLocalDeviceName(newName);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _onDeviceTapped(BuildContext context, WidgetRef ref, Device device) {
    ref.read(transferStateProvider.notifier).setSelectedTargetDevice(device);
    context.push('/send');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discoveryState = ref.watch(discoveryStateProvider);
    final localDevice = discoveryState.localDevice;

    // Trigger server initialization & listen for incoming transfers
    ref.listen(
      transferStateProvider.select((s) => s.pendingIncomingRequest),
      (prev, next) {
        if (next != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              return IncomingTransferDialog(
                request: next,
                onAccept: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(transferStateProvider.notifier)
                      .acceptIncomingTransfer(next.transferId);
                  context.push('/send/progress/${next.transferId}');
                },
                onReject: () {
                  Navigator.of(ctx).pop();
                  ref
                      .read(transferStateProvider.notifier)
                      .rejectIncomingTransfer(next.transferId);
                },
              );
            },
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.share_location,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'NearShare',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Discovery',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(discoveryStateProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Local Device Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          Icons.devices,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'This Device',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (discoveryState.isBroadcasting)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Visible',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              localDevice?.name ?? 'Loading device name...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Platform: ${localDevice?.platform.toUpperCase() ?? 'LOCAL'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit Device Name',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: localDevice == null
                            ? null
                            : () => _showEditNameDialog(
                                  context,
                                  ref,
                                  localDevice.name,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            const IncompleteTransfersWidget(),

            // Discovered Nearby Peers
            Expanded(
              child: DeviceListWidget(
                onDeviceSelected: (device) => _onDeviceTapped(context, ref, device),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.send_rounded),
        label: const Text('Send Files'),
        onPressed: () {
          context.push('/send');
        },
      ),
    );
  }
}
