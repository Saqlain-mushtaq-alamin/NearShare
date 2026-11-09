import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/presentation/file_picker_screen.dart';
import 'package:nearshare/features/transfer/presentation/transfer_provider.dart';

void main() {
  group('FilePickerScreen Widget Tests', () {
    testWidgets('Renders the Photos tab empty state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilePickerScreen(),
          ),
        ),
      );

      expect(find.text('Select files'), findsOneWidget);
      expect(find.text('Nothing selected yet'), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('All files'), findsOneWidget);
    });

    testWidgets('Shows visual media on the Photos tab and files in the bar',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(transferStateProvider.notifier)
                      .setSelectedFiles(const [
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

      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.text('presentation.pdf'), findsNothing);
      expect(find.text('2 files selected'), findsOneWidget);
      expect(find.text('1.5 MB'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('media remove control has semantics and a 48dp target',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(transferStateProvider.notifier)
                      .setSelectedFiles(const [
                    TransferFile(
                      name: 'photo.jpg',
                      sizeInBytes: 524288,
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

      expect(
        find.bySemanticsLabel(RegExp(r'Remove photo\.jpg')),
        findsOneWidget,
      );
      final remove = find.byKey(const ValueKey('remove-photo.jpg'));
      expect(remove, findsOneWidget);
      expect(tester.getSize(remove).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(remove).width, greaterThanOrEqualTo(48));
      semantics.dispose();
    });

    testWidgets('Documents tab lists non-media files', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref
                      .read(transferStateProvider.notifier)
                      .setSelectedFiles(const [
                    TransferFile(
                      name: 'presentation.pdf',
                      sizeInBytes: 1048576,
                      mimeType: 'application/pdf',
                      localPath: '/presentation.pdf',
                    ),
                    TransferFile(
                      name: 'photo.jpg',
                      sizeInBytes: 524288,
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

      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      expect(find.text('presentation.pdf'), findsOneWidget);
      expect(find.text('photo.jpg'), findsNothing);
    });
  });
}
