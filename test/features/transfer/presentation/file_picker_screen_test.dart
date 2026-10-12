import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/presentation/file_picker_screen.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';

void main() {
  group('FilePickerScreen Widget Tests', () {
    testWidgets('Renders empty state when no files selected', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilePickerScreen(),
          ),
        ),
      );

      expect(find.text('Select Files'), findsOneWidget);
      expect(find.text('No files selected yet'), findsOneWidget);
      expect(find.text('Choose Files'), findsOneWidget);
    });

    testWidgets('Renders selected files list and total size', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                // Populate initial selected files
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(transferStateProvider.notifier).setSelectedFiles(const [
                    TransferFile(
                      name: 'presentation.pdf',
                      sizeInBytes: 1048576, // 1 MB
                      mimeType: 'application/pdf',
                      localPath: '/presentation.pdf',
                    ),
                    TransferFile(
                      name: 'photo.jpg',
                      sizeInBytes: 524288, // 512 KB
                      mimeType: 'image/jpeg',
                      localPath: '/photo.jpg',
                    ),
                  ]);
                });
                return const FilePickerScreen();
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('presentation.pdf'), findsOneWidget);
      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.text('2 files'), findsOneWidget);
      expect(find.text('1.5 MB'), findsOneWidget);
      expect(find.text('Select Device'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });
  });
}
