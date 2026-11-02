import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/features/merge_space/data/merge_crypto.dart';
import 'package:nearshare/features/merge_space/data/pairing_service.dart';

void main() {
  group('PairingService', () {
    final service = PairingService();

    test('creates a group with an AES-256 key', () {
      final group = service.createGroup(now: DateTime(2026, 1, 1));

      expect(group.groupId, isNotEmpty);
      expect(group.groupKey, isNotEmpty);
      expect(group.createdAt, DateTime(2026, 1, 1));
    });

    test('builds and parses a pairing link', () {
      final group = service.createGroup();
      final raw = service.buildUri(
        group: group,
        hostAddress: '192.168.1.20',
        port: 48484,
      );

      final link = service.parse(raw);

      expect(link, isNotNull);
      expect(link!.groupId, group.groupId);
      expect(link.groupKey, group.groupKey);
      expect(link.host, '192.168.1.20');
      expect(link.port, 48484);
      expect(raw, startsWith('nearshare://merge/pair?'));
    });

    test('rejects non-merge links', () {
      expect(service.parse('https://example.com/pair?groupId=x'), isNull);
      expect(service.parse('nearshare://room/join?code=123456'), isNull);
      expect(service.parse(''), isNull);
    });

    test('rejects malformed group keys', () {
      final raw = Uri(
        scheme: 'nearshare',
        host: 'merge',
        path: '/pair',
        queryParameters: {
          'groupId': 'group-1',
          'key': 'not-a-256-bit-key',
          'host': '192.168.1.20',
          'port': '8080',
        },
      ).toString();

      expect(service.parse(raw), isNull);
    });

    test('rejects an invalid port', () {
      final raw = Uri(
        scheme: 'nearshare',
        host: 'merge',
        path: '/pair',
        queryParameters: {
          'groupId': 'group-1',
          'key': MergeCrypto.generateGroupKey(),
          'host': '192.168.1.20',
          'port': '70000',
        },
      ).toString();

      expect(service.parse(raw), isNull);
    });

    test('buildUri validates empty hosts', () {
      final group = service.createGroup();
      expect(
        () => service.buildUri(group: group, hostAddress: ' ', port: 8080),
        throwsArgumentError,
      );
    });
  });
}
