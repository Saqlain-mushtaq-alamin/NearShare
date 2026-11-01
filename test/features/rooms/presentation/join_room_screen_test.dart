import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/presentation/join_room_screen.dart';
import 'package:nearshare/features/rooms/presentation/room_state.dart';

import '../../../helpers/rooms_test_helpers.dart';

void main() {
  group('JoinRoomScreen', () {
    testWidgets('shows the scanner area and a six-digit code input',
        (tester) async {
      useTallTestSurface(tester);
      await tester.pumpWidget(
        wrapRoomScreen(const JoinRoomScreen(), const RoomState()),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qr-scanner-placeholder')), findsOneWidget);
      expect(
        find.text('Point your camera at the host QR code'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('room-code-input')), findsOneWidget);
      expect(find.text('Enter 6-digit code'), findsOneWidget);
      expect(find.text('Join Room'), findsWidgets);
    });

    testWidgets('only accepts a full six-digit code', (tester) async {
      useTallTestSurface(tester);
      await tester.pumpWidget(
        wrapRoomScreen(const JoinRoomScreen(), const RoomState()),
      );
      await tester.pumpAndSettle();

      FilledButton joinButton() => tester.widget<FilledButton>(
            find.byKey(const Key('room-join-button')),
          );

      expect(joinButton().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('room-code-input')),
        '123456',
      );
      await tester.pump();

      expect(joinButton().onPressed, isNotNull);
    });
  });
}
