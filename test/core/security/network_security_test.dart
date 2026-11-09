import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearshare/core/security/network_security.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('isLocalNetworkAddress', () {
    test('accepts loopback, RFC1918, CGNAT and IPv6 ULA', () {
      for (final address in <String>[
        '127.0.0.1',
        '10.1.2.3',
        '172.16.0.1',
        '172.31.255.254',
        '192.168.1.20',
        '169.254.10.1',
        '100.64.0.1',
        '::1',
        'fd00::1234',
        'fe80::1',
      ]) {
        expect(
          isLocalNetworkAddress(InternetAddress(address)),
          isTrue,
          reason: address,
        );
      }
    });

    test('rejects public IPv4 and IPv6 addresses', () {
      for (final address in <String>[
        '8.8.8.8',
        '172.32.0.1',
        '203.0.113.10',
        '2001:4860:4860::8888',
      ]) {
        expect(
          isLocalNetworkAddress(InternetAddress(address)),
          isFalse,
          reason: address,
        );
      }
    });
  });

  group('securityMiddleware', () {
    test('rejects a public peer before the handler runs', () async {
      var called = false;
      final handler = securityMiddleware(
        (Request request) {
          called = true;
          return Response.ok('ok');
        },
        remoteAddressOverride: (_) => InternetAddress('8.8.8.8'),
      );

      final response = await handler(Request('GET', Uri.parse('http://x/')));
      expect(response.statusCode, 403);
      expect(called, isFalse);
    });

    test('accepts a private peer and adds hardening headers', () async {
      final handler = securityMiddleware(
        (Request request) => Response.ok('ok'),
        remoteAddressOverride: (_) => InternetAddress('192.168.1.8'),
      );

      final response = await handler(Request('GET', Uri.parse('http://x/')));
      expect(response.statusCode, 200);
      expect(response.headers['x-content-type-options'], 'nosniff');
      expect(response.headers['x-frame-options'], 'DENY');
      expect(response.headers['cache-control'], 'no-store');
    });

    test('rate limits a peer', () async {
      final handler = securityMiddleware(
        (Request request) => Response.ok('ok'),
        config: const ServerSecurityConfig(maxRequestsPerMinute: 2),
        remoteAddressOverride: (_) => InternetAddress('192.168.1.8'),
      );

      final request = Request('GET', Uri.parse('http://x/'));
      expect((await handler(request)).statusCode, 200);
      expect((await handler(request)).statusCode, 200);
      expect((await handler(request)).statusCode, 429);
    });

    test('rejects oversized bodies by content length', () async {
      final handler = securityMiddleware(
        (Request request) => Response.ok('ok'),
        config: const ServerSecurityConfig(maxContentLength: 10),
        remoteAddressOverride: (_) => InternetAddress('192.168.1.8'),
      );

      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://x/'),
          body: 'this body is definitely too large',
        ),
      );
      expect(response.statusCode, 413);
    });

    test('times out slow handlers', () async {
      final handler = securityMiddleware(
        (Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Response.ok('late');
        },
        config: const ServerSecurityConfig(
          requestTimeout: Duration(milliseconds: 10),
        ),
        remoteAddressOverride: (_) => InternetAddress('192.168.1.8'),
      );

      final response = await handler(Request('GET', Uri.parse('http://x/')));
      expect(response.statusCode, 408);
    });
  });
}
