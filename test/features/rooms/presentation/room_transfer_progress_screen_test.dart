import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/rooms/domain/room_transfer_progress.dart';
import 'package:nearshare/features/rooms/presentation/room_transfer_progress_screen.dart';

import '../../../helpers/rooms_test_helpers.dart';

void main() {
  group('RoomTransferProgressScreen', () {
    testWidgets('shows overall and per-member progress bars', (tester) async {
      useTallTestSurface(tester);
      final summary = RoomTransferSummary(
        members: [
          const RoomMemberProgress(
            deviceId: 'a',
            deviceName: 'Alice',
            status: RoomMemberTransferStatus.completed,
            bytesTransferred: 300,
            totalBytes: 300,
            filesCompleted: 2,
            totalFiles: 2,
          ),
          const RoomMemberProgress(
            deviceId: 'b',
            deviceName: 'Bob',
            status: RoomMemberTransferStatus.failed,
            bytesTransferred: 0,
            totalBytes: 300,
            totalFiles: 2,
            errorMessage: 'Connection lost',
          ),
        ],
      );

      await tester.pumpWidget(
        wrapRoomScreen(
          const RoomTransferProgressScreen(roomId: 'room-1'),
          hostRoomState(transferSummary: summary),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('room-overall-progress')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
      expect(find.text('Broadcast finished'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Connection lost'), findsOneWidget);
    });

    testWidgets('shows a waiting state before the summary arrives',
        (tester) async {
      useTallTestSurface(tester);
      await tester.pumpWidget(
        wrapRoomScreen(
          const RoomTransferProgressScreen(roomId: 'room-1'),
          hostRoomState(),
        ),
      );
      await tester.pump();

      expect(find.text('Preparing the broadcast...'), findsOneWidget);
    });
  });
}
