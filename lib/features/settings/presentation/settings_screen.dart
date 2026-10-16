import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../history/presentation/history_provider.dart';

/// App preferences. Phase 8 fleshes this out; the history controls are live.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        scrolledUnderElevation: 2,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'TRANSFER HISTORY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Transfer history'),
            subtitle: const Text('Everything stays on this device'),
            onTap: () => context.push('/history'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_sweep_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Clear transfer history',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Files themselves are not deleted'),
            onTap: () => _confirmClearAll(context, ref),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'PRIVACY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('No cloud, no account'),
            subtitle: Text('Your files never leave your Wi-Fi network.'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Clear all history?'),
          content: const Text(
            'Every transfer record on this device will be removed. '
            'The files themselves are not deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAllHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer history cleared.')),
        );
      }
    }
  }
}
