import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/utils/is_test_env.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../data/qr_code_service.dart';
import 'room_provider.dart';
import 'room_state.dart';

/// Member view: scan the host's QR code or type the 6-digit code.
class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  final QrCodeService _qrCodeService = QrCodeService();
  bool _handlingScan = false;
  bool _navigated = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onScan(BarcodeCapture capture) async {
    if (_handlingScan || _navigated) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final link = _qrCodeService.parse(raw);
      if (link == null) continue;

      _handlingScan = true;
      await ref.read(roomProvider.notifier).joinRoomWithLink(link);
      if (mounted) _handlingScan = false;
      return;
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    await ref.read(roomProvider.notifier).joinRoomByCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(roomProvider);

    ref.listen<RoomState>(roomProvider, (previous, next) {
      final room = next.room;
      if (_navigated || room == null) return;
      if (next.role == RoomRole.member && room.isOpen) {
        _navigated = true;
        context.go('/rooms/active/${room.roomId}');
      }
    });

    final canJoin =
        _codeController.text.trim().length == 6 && !state.isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
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
              'Scan the host QR code',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ScannerArea(onDetect: _onScan),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'or enter the code',
                    style: AppTextStyles.cardSubtitle(theme),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('room-code-input'),
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                hintText: 'Enter 6-digit code',
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _joinByCode(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.5),
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
                        state.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            FilledButton.icon(
              key: const Key('room-join-button'),
              icon: state.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(state.isBusy ? 'Connecting...' : 'Join Room'),
              onPressed: state.isBusy || !canJoin ? null : _joinByCode,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ask the host to show their room screen. The room code is six '
              'digits and works even without a camera.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle(theme),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerArea extends StatelessWidget {
  const _ScannerArea({required this.onDetect});

  final void Function(BarcodeCapture capture) onDetect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        child: isRunningUnderTest
            ? Container(
                key: const Key('qr-scanner-placeholder'),
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
                      'Point your camera at the host QR code',
                      style: AppTextStyles.muted(theme),
                    ),
                  ],
                ),
              )
            : MobileScanner(
                onDetect: onDetect,
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
                          'Camera unavailable. Enter the code below.',
                          style: AppTextStyles.muted(theme),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
