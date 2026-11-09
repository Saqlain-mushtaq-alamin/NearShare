import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/presentation/room_state.dart';
import 'package:nearshare/features/rooms/presentation/rooms_screen.dart';

import '../../../helpers/rooms_test_helpers.dart';

void main() {
  group('RoomsScreen', () {
    testWidgets('shows Create and Join entry points', (tester) async {
      useTallTestSurface(tester);
      await tester.pumpWidget(
        wrapRoomScreen(const RoomsScreen(), const RoomState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rooms'), findsOneWidget);
      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join Room'), findsOneWidget);
      expect(find.text('Share with the whole room'), findsOneWidget);
    });

    testWidgets('shows the active room card when already in a room',
        (tester) async {
      useTallTestSurface(tester);
      final state = hostRoomState(
        room: sampleRoom(members: [sampleMember('a', name: 'Alice')]),
      );

      await tester.pumpWidget(wrapRoomScreen(const RoomsScreen(), state));
      await tester.pumpAndSettle();

      expect(find.text('Your room is live'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
