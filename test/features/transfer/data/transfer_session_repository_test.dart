import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/transfer/data/transfer_session_repository.dart';
import 'package:nearshare/features/transfer/domain/transfer_file.dart';
import 'package:nearshare/features/transfer/domain/transfer_session.dart';

void main() {
  group('DriftTransferSessionRepository', () {
    late DriftTransferSessionRepository repository;

    setUp(() {
      repository = DriftTransferSessionRepository.inMemory();
    });

    tearDown(() async {
      await repository.close();
    });

    TransferSession buildSession({
      String id = 'repo-1',
      TransferSessionStatus status = TransferSessionStatus.inProgress,
      DateTime? lastActivityAt,
      TransferDirection direction = TransferDirection.sending,
    }) {
      return TransferSession(
        transferId: id,
        peerId: 'peer-1',
        peerName: 'Peer',
        peerIp: '10.0.0.4',
        peerPort: 53317,
        direction: direction,
        status: status,
        files: const [
          TransferFile(
            name: 'doc.pdf',
            sizeInBytes: 4096,
            mimeType: 'application/pdf',
            localPath: '/doc.pdf',
          ),
        ],
        chunkSize: 1024,
        localDeviceId: 'me',
        localDeviceName: 'This Device',
        startedAt: DateTime.utc(2026, 2, 1),
        lastActivityAt: lastActivityAt,
        receivedChunksPerFile: {0: [0, 2]},
        fileSavePaths: {0: '/received/doc.pdf'},
      );
    }

    test('round-trips a session with chunk bookkeeping', () async {
      final original = buildSession();
      await repository.saveSession(original);

      final loaded = await repository.getSession(original.transferId);
      expect(loaded, isNotNull);
      expect(loaded!.transferId, original.transferId);
      expect(loaded.peerIp, '10.0.0.4');
      expect(loaded.peerPort, 53317);
      expect(loaded.direction, TransferDirection.sending);
      expect(loaded.status, TransferSessionStatus.inProgress);
      expect(loaded.chunkSize, 1024);
      expect(loaded.localDeviceName, 'This Device');
      expect(loaded.receivedChunksPerFile[0], [0, 2]);
      expect(loaded.fileSavePaths[0], '/received/doc.pdf');
      expect(loaded.files.single.name, 'doc.pdf');
      expect(loaded.startedAt.toUtc(), DateTime.utc(2026, 2, 1).toUtc());
    });

    test('saveSession overwrites an existing row', () async {
      final original = buildSession();
      await repository.saveSession(original);
      await repository.saveSession(
        original.copyWith(status: TransferSessionStatus.paused),
      );

      final loaded = await repository.getSession(original.transferId);
      expect(loaded!.status, TransferSessionStatus.paused);
      expect((await repository.getAllSessions()).length, 1);
    });

    test('getSession returns null for an unknown id', () async {
      expect(await repository.getSession('nope'), isNull);
    });

    test('getIncompleteSessions excludes terminal sessions, newest first',
        () async {
      final base = DateTime.utc(2026, 3, 1);
      await repository.saveSession(
        buildSession(id: 'done', status: TransferSessionStatus.completed)
            .copyWith(lastActivityAt: base.add(const Duration(hours: 1))),
      );
      await repository.saveSession(
        buildSession(id: 'old', status: TransferSessionStatus.paused)
            .copyWith(lastActivityAt: base),
      );
      await repository.saveSession(
        buildSession(id: 'new', status: TransferSessionStatus.paused)
            .copyWith(lastActivityAt: base.add(const Duration(hours: 3))),
      );

      final incomplete = await repository.getIncompleteSessions();
      expect(incomplete.map((s) => s.transferId), ['new', 'old']);
    });

    test('deleteStaleSessions only removes rows past the cutoff', () async {
      final now = DateTime.utc(2026, 4, 1);
      await repository.saveSession(
        buildSession(id: 'fresh').copyWith(
          lastActivityAt: now.subtract(const Duration(hours: 1)),
        ),
      );
      await repository.saveSession(
        buildSession(id: 'stale').copyWith(
          lastActivityAt: now.subtract(const Duration(hours: 48)),
        ),
      );

      final removed = await repository.deleteStaleSessions(
        maxAge: const Duration(hours: 24),
        now: now,
      );

      expect(removed.map((s) => s.transferId), ['stale']);
      expect(await repository.getSession('fresh'), isNotNull);
      expect(await repository.getSession('stale'), isNull);
    });

    test('deleteStaleSessions falls back to startedAt when lastActivityAt is null',
        () async {
      final now = DateTime.utc(2026, 5, 1);
      final session = TransferSession(
        transferId: 'never-active',
        peerId: 'peer',
        peerName: 'Peer',
        direction: TransferDirection.sending,
        status: TransferSessionStatus.pending,
        files: const [
          TransferFile(
            name: 'a.txt',
            sizeInBytes: 10,
            mimeType: 'text/plain',
            localPath: '/a.txt',
          ),
        ],
        chunkSize: 1024,
        startedAt: now.subtract(const Duration(days: 3)),
      );
      await repository.saveSession(session);

      final removed = await repository.deleteStaleSessions(
        maxAge: const Duration(hours: 24),
        now: now,
      );
      expect(removed.map((s) => s.transferId), ['never-active']);
    });

    test('deleteSession removes the row', () async {
      final session = buildSession();
      await repository.saveSession(session);
      await repository.deleteSession(session.transferId);
      expect(await repository.getSession(session.transferId), isNull);
    });
  });

  group('InMemoryTransferSessionRepository', () {
    late InMemoryTransferSessionRepository repository;

    setUp(() {
      repository = InMemoryTransferSessionRepository();
    });

    test('behaves like the drift repository for the common operations',
        () async {
      final session = TransferSession(
        transferId: 'mem-1',
        peerId: 'peer',
        peerName: 'Peer',
        direction: TransferDirection.sending,
        status: TransferSessionStatus.paused,
        files: const [
          TransferFile(
            name: 'a.txt',
            sizeInBytes: 10,
            mimeType: 'text/plain',
            localPath: '/a.txt',
          ),
        ],
        chunkSize: 1024,
        startedAt: DateTime.utc(2026, 6, 1),
      );
      await repository.saveSession(session);

      expect((await repository.getSession('mem-1'))!.status,
          TransferSessionStatus.paused);
      expect(await repository.getIncompleteSessions(), hasLength(1));

      await repository.deleteSession('mem-1');
      expect(await repository.getSession('mem-1'), isNull);

      await repository.close();
      expect(await repository.getAllSessions(), isEmpty);
    });
  });
}
