import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_icons.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/transfer_request.dart';

/// Sliding sheet shown when someone sends us files.
///
/// Auto-declines after 60 untouched seconds so the sender isn't left hanging.
class IncomingTransferSheet extends StatefulWidget {
  const IncomingTransferSheet({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final TransferRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  /// Opens the sheet as a modal with the standard 60s auto-dismiss timer.
  static Future<void> show(
    BuildContext context, {
    required TransferRequest request,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) => IncomingTransferSheet(
        request: request,
        onAccept: onAccept,
        onReject: onReject,
      ),
    );
  }

  @override
  State<IncomingTransferSheet> createState() => _IncomingTransferSheetState();
}

class _IncomingTransferSheetState extends State<IncomingTransferSheet> {
  static const _timeout = Duration(seconds: 60);

  late final Timer _timer;
  late final ValueNotifier<int> _secondsLeft;
  var _resolved = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = ValueNotifier(_timeout.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _timeout.inSeconds - timer.tick;
      if (remaining <= 0) {
        timer.cancel();
        _resolve(rejected: true);
      } else {
        _secondsLeft.value = remaining;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _secondsLeft.dispose();
    super.dispose();
  }

  void _resolve({required bool rejected}) {
    if (_resolved) return;
    _resolved = true;
    _timer.cancel();
    Navigator.of(context).maybePop();
    if (rejected) {
      widget.onReject();
    } else {
      widget.onAccept();
    }
  }

  String _countdown(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = widget.request;
    final files = request.files;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resolve(rejected: true);
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.file_download_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.senderName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'wants to send you ${files.length} ${files.length == 1 ? 'file' : 'files'}',
                        style: AppTextStyles.cardSubtitle(theme),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _secondsLeft,
                  builder: (context, seconds, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Auto-declines in ${_countdown(seconds)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              fileCountLabel(files.length, request.totalSizeBytes),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.34,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, __) => const Divider(indent: 44),
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(AppIcons.fileFor(file.name), size: 22),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(theme),
                    ),
                    trailing: Text(
                      formatBytes(file.sizeInBytes),
                      style: AppTextStyles.cardSubtitle(theme),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolve(rejected: true),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _resolve(rejected: false),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
