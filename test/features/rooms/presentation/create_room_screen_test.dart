import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/presentation/create_room_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/rooms_test_helpers.dart';

void main() {
  group('CreateRoomScreen', () {
    testWidgets('shows a QR code and the six-digit room code', (tester) async {
      useTallTestSurface(tester);
      await tester.pumpWidget(
        wrapRoomScreen(const CreateRoomScreen(), hostRoomState()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.text('Scan to join'), findsOneWidget);
      expect(find.text('Send Files'), findsOneWidget);
      expect(find.text('Close Room'), findsOneWidget);
    });

    testWidgets('shows the live list of joined members', (tester) async {
      useTallTestSurface(tester);
      final state = hostRoomState(
        room: sampleRoom(
          members: [
            sampleMember('a', name: 'Alice', platform: 'ios'),
            sampleMember('b', name: 'Bob', platform: 'windows'),
          ],
        ),
      );

      await tester.pumpWidget(
        wrapRoomScreen(const CreateRoomScreen(), state),
      );
      await tester.pumpAndSettle();

      expect(find.text('In this room'), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Waiting for devices to join...'), findsNothing);
    });
  });
}
