import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:shelf/shelf.dart';

/// Runtime limits applied to every NearShare HTTP server.
///
/// The defaults are intentionally permissive enough for parallel 1 MiB chunk
/// uploads, while still rejecting unbounded bodies and runaway clients.
class ServerSecurityConfig {
  const ServerSecurityConfig({
    this.enforceLocalNetwork = true,
    this.maxConcurrentRequests = 24,
    this.maxRequestsPerMinute = 1800,
    this.requestTimeout = const Duration(seconds: 90),
    this.maxContentLength = 64 * 1024 * 1024,
    this.allowLoopback = true,
  });

  final bool enforceLocalNetwork;
  final int maxConcurrentRequests;
  final int maxRequestsPerMinute;
  final Duration requestTimeout;
  final int maxContentLength;
  final bool allowLoopback;

  static const Map<String, String> securityHeaders = <String, String>{
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Cache-Control': 'no-store',
    'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
  };
}

/// Returns true for addresses that can only belong to the local link or LAN.
///
/// IPv4: loopback, RFC 1918, link-local, and CGNAT ranges are accepted.
/// IPv6: loopback, unique-local (`fc00::/7`), and link-local (`fe80::/10`) are
/// accepted. Public addresses are always rejected.
bool isLocalNetworkAddress(InternetAddress address) {
  if (address.isLoopback) {
    return true;
  }
  final List<int> raw = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    return _isPrivateIpv4(raw);
  }
  if (raw.length != 16) {
    return false;
  }
  final bool isMappedIpv4 = raw
          .take(10)
          .every((int value) => value == 0) &&
      raw[10] == 0xff &&
      raw[11] == 0xff;
  if (isMappedIpv4) {
    return _isPrivateIpv4(raw.sublist(12));
  }
  if ((raw[0] & 0xfe) == 0xfc) {
    return true;
  }
  if (raw[0] == 0xfe && (raw[1] & 0xc0) == 0x80) {
    return true;
  }
  return false;
}

bool _isPrivateIpv4(List<int> bytes) {
  if (bytes.length != 4) {
    return false;
  }
  final int a = bytes[0];
  final int b = bytes[1];
  final int c = bytes[2];
  if (a == 10) {
    return true;
  }
  if (a == 127) {
    return true;
  }
  if (a == 169 && b == 254) {
    return true;
  }
  if (a == 172 && b >= 16 && b <= 31) {
    return true;
  }
  if (a == 192 && b == 168) {
    return true;
  }
  if (a == 100 && b >= 64 && b <= 127) {
    return true;
  }
  return a == 0 && b == 0 && c == 0;
}

/// Sliding-window limiter keyed by peer address.
class SlidingWindowRateLimiter {
  SlidingWindowRateLimiter({
    required this.maxRequests,
    this.window = const Duration(minutes: 1),
  }) : assert(maxRequests > 0);

  final int maxRequests;
  final Duration window;
  final Map<String, Queue<DateTime>> _hits = <String, Queue<DateTime>>{};

  bool allow(String key, {DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    final Queue<DateTime> hits = _hits.putIfAbsent(
      key,
      () => Queue<DateTime>(),
    );
    final DateTime cutoff = current.subtract(window);
    while (hits.isNotEmpty && hits.first.isBefore(cutoff)) {
      hits.removeFirst();
    }
    if (hits.length >= maxRequests) {
      return false;
    }
    hits.addLast(current);
    return true;
  }

  void clear() => _hits.clear();
}

/// Bounds the number of handlers executing at the same time.
class ConcurrencyLimiter {
  ConcurrencyLimiter(this.maxConcurrent);

  final int maxConcurrent;
  int _active = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<T> run<T>(Future<T> Function() action) async {
    if (_active >= maxConcurrent) {
      final completer = Completer<void>();
      _waiters.add(completer);
      await completer.future;
    }
    _active++;
    try {
      return await action();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete();
      }
    }
  }
}

/// Wraps [inner] with local-network enforcement, rate/concurrency limits,
/// body-size limits, request timeouts, and hardening headers.
///
/// [remoteAddressOverride] exists for tests that invoke handlers directly
/// without shelf_io populating the connection context.
Handler securityMiddleware(
  Handler inner, {
  ServerSecurityConfig config = const ServerSecurityConfig(),
  InternetAddress? Function(Request request)? remoteAddressOverride,
}) {
  final SlidingWindowRateLimiter limiter = SlidingWindowRateLimiter(
    maxRequests: config.maxRequestsPerMinute,
  );
  final ConcurrencyLimiter gate = ConcurrencyLimiter(
    config.maxConcurrentRequests,
  );

  return (Request request) async {
    final InternetAddress? remote = remoteAddressOverride?.call(request) ??
        _connectionAddress(request);
    if (config.enforceLocalNetwork) {
      if (remote == null) {
        return _plain(Response.forbidden('Local network required'));
      }
      if (!isLocalNetworkAddress(remote) ||
          (!config.allowLoopback && remote.isLoopback)) {
        return _plain(Response.forbidden('Local network required'));
      }
    }

    final String rateKey = remote?.address ?? 'unknown';
    if (!limiter.allow(rateKey)) {
      return _plain(
        Response(
          429,
          body: 'Too many requests',
          headers: const <String, String>{'Retry-After': '30'},
        ),
      );
    }

    final int? contentLength = request.contentLength;
    if (contentLength != null && contentLength > config.maxContentLength) {
      return _plain(Response(413, body: 'Request body too large'));
    }

    try {
      final Response response = await gate.run<Response>(
        () => Future<Response>.sync(() => inner(request))
            .timeout(config.requestTimeout),
      );
      return _withHeaders(response);
    } on TimeoutException {
      return _plain(Response(408, body: 'Request timed out'));
    }
  };
}

InternetAddress? _connectionAddress(Request request) {
  try {
    final Object? info = request.context['shelf.io.connection_info'];
    if (info is HttpConnectionInfo) {
      return info.remoteAddress;
    }
  } catch (_) {
    return null;
  }
  return null;
}

Response _withHeaders(Response response) {
  final Map<String, String> headers = <String, String>{
    ...response.headers,
    ...ServerSecurityConfig.securityHeaders,
  };
  return response.change(headers: headers);
}

Response _plain(Response response) => _withHeaders(response);
