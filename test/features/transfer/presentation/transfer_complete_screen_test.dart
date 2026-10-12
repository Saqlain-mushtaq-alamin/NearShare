import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/presentation/transfer_complete_screen.dart';

void main() {
  group('TransferCompleteScreen Widget Tests', () {
    testWidgets('Renders success state and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TransferCompleteScreen(transferId: 'complete-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Transfer Status'), findsOneWidget);
      expect(find.text('Transfer Complete!'), findsOneWidget);
      expect(find.text('Send More'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
