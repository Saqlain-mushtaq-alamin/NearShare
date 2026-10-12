import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/discovery/domain/device.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/presentation/transfer_confirmation_screen.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';

void main() {
  group('TransferConfirmationScreen Widget Tests', () {
    testWidgets('Renders recipient device, files list, total size, and Send Files button', (tester) async {
      final target = Device(
        id: 'target-001',
        name: 'Alex MacBook',
        platform: 'macos',
        ipAddress: '192.168.1.10',
        port: 53317,
        discoveredAt: DateTime.now(),
      );

      const files = [
        TransferFile(
          name: 'report.docx',
          sizeInBytes: 2097152, // 2 MB
          mimeType: 'application/docx',
          localPath: '/report.docx',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(transferStateProvider.notifier).setSelectedTargetDevice(target);
                  ref.read(transferStateProvider.notifier).setSelectedFiles(files);
                });
                return const TransferConfirmationScreen();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Confirm Transfer'), findsOneWidget);
      expect(find.text('Alex MacBook'), findsOneWidget);
      expect(find.text('report.docx'), findsOneWidget);
      expect(find.text('Files to Send (1)'), findsOneWidget);
      expect(find.text('2.0 MB'), findsWidgets);
      expect(find.text('Send Files'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
