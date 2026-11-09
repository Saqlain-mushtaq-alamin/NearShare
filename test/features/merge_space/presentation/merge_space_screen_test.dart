import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/group_credential_store.dart';
import 'package:nearshare/features/merge_space/data/merge_space_repository.dart';
import 'package:nearshare/features/merge_space/data/merge_space_storage.dart';
import 'package:nearshare/features/merge_space/data/pairing_service.dart';
import 'package:nearshare/features/merge_space/domain/merge_space_file.dart';
import 'package:nearshare/features/merge_space/domain/paired_device.dart';
import 'package:nearshare/features/merge_space/domain/sync_conflict.dart';
import 'package:nearshare/features/merge_space/presentation/merge_conflicts_screen.dart';
import 'package:nearshare/features/merge_space/presentation/merge_join_screen.dart';
import 'package:nearshare/features/merge_space/presentation/merge_space_provider.dart';
import 'package:nearshare/features/merge_space/presentation/merge_space_screen.dart';

import '../../../helpers/merge_space_test_helpers.dart';
import '../../../helpers/presentation_stubs.dart';

class _Harness {
  final InMemoryMergeSpaceRepository repository;
  final InMemoryGroupCredentialStore credentials;
  final FakeMergeDiscoveryService discovery;
  final MergeSpaceNotifier notifier;

  _Harness._({
    required this.repository,
    required this.credentials,
    required this.discovery,
    required this.notifier,
  });

  static Future<_Harness> create({
    bool active = false,
    List<MergeSpaceFile> files = const [],
    List<PairedDevice> peers = const [],
    List<SyncConflict> conflicts = const [],
  }) async {
    final repository = InMemoryMergeSpaceRepository();
    final credentials = InMemoryGroupCredentialStore();
    final discovery = FakeMergeDiscoveryService();
    final pairing = PairingService();
    final group = pairing.createGroup(now: DateTime(2026, 1, 1));
    final local = PairedDevice(
      deviceId: 'test-device-1',
      deviceName: 'NearShare Test Device',
      platform: 'android',
      groupId: group.groupId,
      pairedAt: DateTime(2026, 1, 1),
      syncStatus: SyncStatus.synced,
    );

    if (active) {
      await credentials.save(
        MergedGroupCredentials(
          groupId: group.groupId,
          groupKey: group.groupKey,
          createdAt: group.createdAt,
        ),
      );
      await repository.saveDevice(local);
      for (final peer in peers) {
        await repository.saveDevice(peer.copyWith(groupId: group.groupId));
      }
      for (final file in files) {
        await repository.saveFile(file);
      }
      for (final conflict in conflicts) {
        await repository.saveConflict(conflict);
      }
    }

    final notifier = MergeSpaceNotifier(
      repository: repository,
      storage: MergeSpaceStorage(customRootPath: 'unused-in-widget-test'),
      credentialStore: credentials,
      discovery: discovery,
      identityService: FakeDeviceIdentityService(),
      client: FakeMergeSpaceClient(),
      pairingService: pairing,
      autoStartRuntime: false,
    );

    return _Harness._(
      repository: repository,
      credentials: credentials,
      discovery: discovery,
      notifier: notifier,
    );
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        mergeSpaceProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(home: child),
    );
  }
}

MergeSpaceFile sampleFile(String path) {
  return MergeSpaceFile(
    relativePath: path,
    hash: 'hash-$path',
    baseHash: 'hash-$path',
    sizeBytes: 2048,
    modifiedAt: DateTime(2026, 1, 1),
    originDeviceId: 'peer-1',
  );
}

PairedDevice peerDevice() {
  return PairedDevice(
    deviceId: 'peer-1',
    deviceName: 'Pixel 8',
    platform: 'android',
    groupId: 'group-1',
    pairedAt: DateTime(2026, 1, 1),
    syncStatus: SyncStatus.synced,
  );
}

void main() {
  group('MergeSpaceScreen setup', () {
    testWidgets('offers create and join when inactive', (tester) async {
      final harness = await _Harness.create();

      await tester.pumpWidget(harness.wrap(const MergeSpaceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('One folder, every device'), findsOneWidget);
      expect(find.byKey(const Key('merge-create-button')), findsOneWidget);
      expect(find.byKey(const Key('merge-join-button')), findsOneWidget);
    });

    testWidgets('creating a group activates the screen', (tester) async {
      final harness = await _Harness.create();

      await tester.pumpWidget(harness.wrap(const MergeSpaceScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('merge-create-button')));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for a paired device'), findsOneWidget);
      expect(find.text('Pair another device'), findsOneWidget);
      expect(find.byKey(const Key('merge-pairing-qr')), findsNothing);
      expect(find.textContaining('Pairing code unavailable'), findsOneWidget);
      expect(harness.credentials.credentials, isNotNull);
    });
  });

  group('MergeSpaceScreen active', () {
    testWidgets('shows indexed files and paired devices', (tester) async {
      final harness = await _Harness.create(
        active: true,
        files: [sampleFile('notes/today.txt')],
        peers: [peerDevice()],
      );

      await tester.pumpWidget(harness.wrap(const MergeSpaceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('All synced'), findsOneWidget);
      expect(find.text('today.txt'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.byKey(const Key('merge-sync-button')), findsOneWidget);
      expect(
        find.byKey(const Key('file-status-notes/today.txt')),
        findsOneWidget,
      );
    });

    testWidgets('shows how many devices are still pending', (tester) async {
      final harness = await _Harness.create(
        active: true,
        peers: [
          peerDevice().copyWith(syncStatus: SyncStatus.pendingSync),
        ],
      );

      await tester.pumpWidget(harness.wrap(const MergeSpaceScreen()));
      await tester.pumpAndSettle();

      expect(find.text('1 device pending'), findsOneWidget);
      expect(find.text('Not synced yet'), findsOneWidget);
    });

    testWidgets('shows the conflict banner with a count', (tester) async {
      final harness = await _Harness.create(
        active: true,
        peers: [peerDevice()],
        conflicts: [
          SyncConflict(
            relativePath: 'notes.txt',
            localVersion: sampleFile('notes.txt'),
            remoteVersion: sampleFile('notes.txt').copyWith(hash: 'remote'),
            remoteDeviceId: 'peer-1',
            detectedAt: DateTime(2026, 1, 2),
          ),
        ],
      );

      await tester.pumpWidget(harness.wrap(const MergeSpaceScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('merge-conflicts-banner')), findsOneWidget);
      expect(find.text('1 conflict to review'), findsOneWidget);
      expect(find.textContaining('need attention'), findsOneWidget);
      expect(find.byKey(const Key('merge-conflicts-action')), findsOneWidget);
    });

    testWidgets('sync without a nearby peer reports why', (tester) async {
      final harness = await _Harness.create(
        active: true,
        peers: [peerDevice()],
      );

      await tester.pumpWidget(harness.wrap(const MergeSpaceScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('merge-sync-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No paired device is nearby'),
        findsOneWidget,
      );
    });
  });

  group('Merge space conflicts and joining', () {
    testWidgets('conflict screen offers three resolutions', (tester) async {
      final harness = await _Harness.create(
        active: true,
        peers: [peerDevice()],
        conflicts: [
          SyncConflict(
            relativePath: 'notes.txt',
            localVersion: sampleFile('notes.txt'),
            remoteVersion: sampleFile('notes.txt').copyWith(hash: 'remote'),
            remoteDeviceId: 'peer-1',
            detectedAt: DateTime(2026, 1, 2),
          ),
        ],
      );

      await tester.pumpWidget(harness.wrap(const MergeConflictsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('This device'), findsOneWidget);
      expect(find.text('Other device'), findsOneWidget);
      expect(find.textContaining('Pixel 8 · 2.0 KB'), findsNWidgets(2));
      expect(find.byKey(const Key('conflict-keep-local-0')), findsOneWidget);
      expect(find.byKey(const Key('conflict-keep-remote-0')), findsOneWidget);
      expect(find.byKey(const Key('conflict-keep-both-0')), findsOneWidget);
    });

    testWidgets('join screen enables joining only for a valid link',
        (tester) async {
      final harness = await _Harness.create();

      await tester.pumpWidget(harness.wrap(const MergeJoinScreen()));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('merge-pair-join-button'));
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      final group = PairingService().createGroup();
      final link = PairingService().buildUri(
        group: group,
        hostAddress: '192.168.1.20',
        port: 48484,
      );
      await tester.enterText(
        find.byKey(const Key('merge-pair-link-input')),
        link,
      );
      await tester.pump();

      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(
        find.byKey(const Key('merge-scanner-placeholder')),
        findsOneWidget,
      );
    });
  });
}
