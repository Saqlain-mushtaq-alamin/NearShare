import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/presentation/room_active_screen.dart';

import '../../../helpers/rooms_test_helpers.dart';

void main() {
  group('RoomActiveScreen', () {
    testWidgets('host view shows the member list and file picker',
        (tester) async {
      useTallTestSurface(tester);
      final state = hostRoomState(
        room: sampleRoom(
          members: [
            sampleMember('a', name: 'Alice'),
            sampleMember('b', name: 'Bob'),
          ],
        ),
      );

      await tester.pumpWidget(
        wrapRoomScreen(const RoomActiveScreen(roomId: 'room-1'), state),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Files'), findsOneWidget);
      expect(find.text('Choose files'), findsWidgets);
      expect(find.text('Send to All'), findsOneWidget);
    });
  });
}
