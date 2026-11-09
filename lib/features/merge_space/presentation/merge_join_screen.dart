import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/is_test_env.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../data/pairing_service.dart';
import 'merge_space_provider.dart';

class MergeJoinScreen extends ConsumerStatefulWidget {
  const MergeJoinScreen({super.key});

  @override
  ConsumerState<MergeJoinScreen> createState() => _MergeJoinScreenState();
}

class _MergeJoinScreenState extends ConsumerState<MergeJoinScreen> {
  final TextEditingController _controller = TextEditingController();
  final PairingService _pairingService = PairingService();
  bool _handlingScan = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onScan(BarcodeCapture capture) async {
    if (_handlingScan) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || _pairingService.parse(raw) == null) continue;
      _handlingScan = true;
      await _join(raw);
      if (mounted) _handlingScan = false;
      return;
    }
  }

  Future<void> _join(String raw) async {
    final joined =
        await ref.read(mergeSpaceProvider.notifier).joinWithLink(raw);
    if (joined && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(mergeSpaceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Join Merge Space')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Scan the pairing code',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 230,
                child: isRunningUnderTest
                    ? Container(
                        key: const Key('merge-scanner-placeholder'),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 56,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Point your camera at the pairing code',
                              style: AppTextStyles.muted(theme),
                            ),
                          ],
                        ),
                      )
                    : MobileScanner(
                        onDetect: _onScan,
                        errorBuilder: (context, error, child) {
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.no_photography_outlined,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Camera unavailable. Paste the code below.',
                                  style: AppTextStyles.muted(theme),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'or paste the code',
                    style: AppTextStyles.cardSubtitle(theme),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('merge-pair-link-input'),
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              style: theme.textTheme.bodySmall,
              decoration: const InputDecoration(
                hintText: 'nearshare://merge/pair?...',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                if (_pairingService.parse(value) != null) _join(value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton.icon(
              key: const Key('merge-pair-join-button'),
              icon: state.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(state.isBusy ? 'Pairing...' : 'Join Merge Space'),
              onPressed: state.isBusy ||
                      _pairingService.parse(_controller.text.trim()) == null
                  ? null
                  : () => _join(_controller.text.trim()),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Both devices must be on the same Wi-Fi network while pairing. '
              'The group key is stored securely on this device.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle(theme),
            ),
          ],
        ),
      ),
    );
  }
}
