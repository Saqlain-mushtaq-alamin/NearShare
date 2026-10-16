import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../discovery/presentation/discovery_provider.dart';
import '../domain/transfer_record.dart';
import '../../transfer/presentation/transfer_provider.dart';
import 'history_item_widget.dart';
import 'history_provider.dart';

/// Chronological log of everything this device has sent or received.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        scrolledUnderElevation: 2,
        actions: [
          if (state.records.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'History options',
              onSelected: (value) async {
                if (value == 'clear') await _confirmClearAll(context, ref);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep_outlined),
                    title: Text('Clear all history'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const Key('history-search-field'),
              onChanged: (value) =>
                  ref.read(historyProvider.notifier).setSearch(value),
              decoration: InputDecoration(
                hintText: 'Search device or file name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.query.hasSearch
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            ref.read(historyProvider.notifier).clearSearch(),
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final filter in HistoryFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: state.query.direction == filter,
                      onSelected: (_) =>
                          ref.read(historyProvider.notifier).setDirection(filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: state.isLoading && state.records.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.records.isEmpty
                    ? _EmptyState(query: state.query, theme: theme)
                    : ListView.separated(
                        key: const Key('history-list'),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: state.records.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = state.records[index];
                          return HistoryItemWidget(
                            key: ValueKey('item-${record.transferId}'),
                            record: record,
                            canResend: record.isSent,
                            onTap: () =>
                                context.push('/history/${record.transferId}'),
                            onResend: record.isSent
                                ? () => _resend(context, ref, record)
                                : null,
                            onDelete: () => ref
                                .read(historyProvider.notifier)
                                .deleteRecord(record.transferId),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _resend(
    BuildContext context,
    WidgetRef ref,
    TransferRecord record,
  ) async {
    final devices = ref.read(discoveryStateProvider.select((s) => s.devices));
    final outcome = await ref
        .read(transferStateProvider.notifier)
        .startResend(record, availableDevices: devices);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!outcome.canSend) {
      messenger.showSnackBar(
        SnackBar(content: Text(outcome.missingFilesMessage)),
      );
      return;
    }
    if (outcome.hasMissingFiles) {
      messenger.showSnackBar(
        SnackBar(content: Text(outcome.missingFilesMessage)),
      );
    }
    unawaited(context.push('/send/select-device'));
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
    }
  }
}

class _EmptyState extends StatelessWidget {
  final HistoryQuery query;
  final ThemeData theme;

  const _EmptyState({required this.query, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isFiltered = query.direction != HistoryFilter.all || query.hasSearch;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.search_off : Icons.history,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No matching transfers' : 'No transfer history yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try a different search or filter.'
                  : 'Files you send or receive will show up here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
