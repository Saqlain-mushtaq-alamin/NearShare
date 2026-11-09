import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../../core/security/tls_identity.dart';
import '../../discovery/domain/device.dart';
import '../domain/resume_state.dart';
import '../domain/transfer_request.dart';
import 'retry_policy.dart';

/// Error returned by the receiver that should not be retried blindly.
class TransferClientException implements Exception {
  final String message;
  final int? statusCode;
  final List<int> missingChunks;

  const TransferClientException(
    this.message, {
    this.statusCode,
    this.missingChunks = const [],
  });

  @override
  String toString() => 'TransferClientException: $message';
}

class TransferClient {
  late final Dio _dio;
  final Map<String, String> _pinnedFingerprints = <String, String>{};

  /// Backoff policy applied to chunk uploads, resume queries and finalization.
  final RetryPolicy retryPolicy;

  TransferClient({Dio? dio, RetryPolicy? retryPolicy})
      : retryPolicy = retryPolicy ?? transferRetryPolicy {
    if (dio != null) {
      _dio = dio;
      return;
    }
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(minutes: 30),
      ),
    );
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = _verifyPinnedCertificate;
        return client;
      },
    );
  }

  bool _verifyPinnedCertificate(
    X509Certificate certificate,
    String host,
    int port,
  ) {
    final expected = _pinnedFingerprints['$host:$port'];
    if (expected == null) return false;
    final actual = sha256.convert(certificate.der).toString();
    return TlsIdentityService.fingerprintMatches(actual, expected);
  }

  String _baseUrl(Device target) {
    final fingerprint = target.certFingerprint;
    if (fingerprint != null && fingerprint.isNotEmpty) {
      _pinnedFingerprints['${target.ipAddress}:${target.port}'] =
          TlsIdentityService.normalizeFingerprint(fingerprint);
      return 'https://${target.ipAddress}:${target.port}';
    }
    return 'http://${target.ipAddress}:${target.port}';
  }

  bool _shouldRetry(Object error, StackTrace stack) {
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return false;
    }
    if (error is TransferClientException) return false;
    return isConnectionError(error);
  }

  /// Sends a preparation request announcing intent to transfer files.
  /// Returns `true` if the recipient accepted, `false` if rejected.
  Future<bool> prepareTransfer(Device target, TransferRequest request) async {
    final url = '${_baseUrl(target)}/api/v1/transfer/prepare';

    try {
      final response = await _dio.post(
        url,
        data: request.toJson(),
        options: Options(
          headers: {'content-type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        return data['status'] == 'accepted';
      } else if (response.statusCode == 403) {
        return false;
      } else {
        debugPrint(
          '[TransferClient] Prepare request failed with status: ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return false;
      }
      debugPrint('[TransferClient] Dio error during prepare: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[TransferClient] Error during prepare: $e');
      rethrow;
    }
  }

  /// Asks the receiver which chunks of a single file it already holds.
  ///
  /// A receiver that does not know the transfer yields
  /// [ResumeState.unknown], which the sender treats as "send everything".
  Future<ResumeState> getResumeState(
    Device target,
    String transferId,
    int fileIndex,
  ) async {
    final url =
        '${_baseUrl(target)}/api/v1/transfer/resume/$transferId/$fileIndex';

    return retryPolicy.run(
      () async {
        final response = await _dio.get(
          url,
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          return ResumeState.fromJson(response.data as Map<String, dynamic>);
        }
        if (response.statusCode == 404) return const ResumeState.unknown();
        throw TransferClientException(
          'Resume query failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      },
      retryIf: _shouldRetry,
    );
  }

  /// Asks the receiver for the resume state of every file in a transfer.
  Future<TransferResumeState> getResumeStateForAll(
    Device target,
    String transferId,
  ) async {
    final url = '${_baseUrl(target)}/api/v1/transfer/resume/$transferId';

    return retryPolicy.run(
      () async {
        final response = await _dio.get(
          url,
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          return TransferResumeState.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
        if (response.statusCode == 404) return const TransferResumeState.unknown();
        throw TransferClientException(
          'Resume query failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      },
      retryIf: _shouldRetry,
    );
  }

  /// Uploads a single chunk of a file.
  ///
  /// Connection failures are retried with exponential backoff before the error
  /// is surfaced so the transfer can be paused instead of failing outright.
  Future<Map<String, dynamic>> uploadChunk({
    required Device target,
    required String transferId,
    required int fileIndex,
    required int chunkIndex,
    required Uint8List bytes,
    required int startByte,
    required int endByte,
    required int fileSize,
    required int totalChunks,
    CancelToken? cancelToken,
    void Function(int sentBytes, int totalBytes)? onProgress,
    RetryPolicy? retryPolicyOverride,
  }) async {
    final url =
        '${_baseUrl(target)}/api/v1/transfer/chunk/$transferId/$fileIndex';
    final policy = retryPolicyOverride ?? retryPolicy;

    return policy.run(
      () async {
        final response = await _dio.post(
          url,
          data: bytes,
          cancelToken: cancelToken,
          onSendProgress: onProgress,
          options: Options(
            headers: {
              'content-type': 'application/octet-stream',
              'x-transfer-id': transferId,
              'x-file-index': '$fileIndex',
              'x-chunk-index': '$chunkIndex',
              'x-chunk-size': '${bytes.length}',
              'x-total-chunks': '$totalChunks',
              'content-range': 'bytes $startByte-$endByte/$fileSize',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200) {
          return response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : <String, dynamic>{};
        }
        if (response.statusCode == 409) {
          throw TransferClientException(
            'Transfer was cancelled by the receiver',
            statusCode: 409,
          );
        }
        throw TransferClientException(
          'Chunk upload failed with status ${response.statusCode}: '
          '${response.data}',
          statusCode: response.statusCode,
        );
      },
      retryIf: _shouldRetry,
    );
  }

  /// Asks the receiver to verify and assemble a fully received file.
  Future<Map<String, dynamic>> finalizeFile(
    Device target,
    String transferId,
    int fileIndex,
  ) async {
    final url =
        '${_baseUrl(target)}/api/v1/transfer/finalize/$transferId/$fileIndex';

    return retryPolicy.run(
      () async {
        final response = await _dio.post(
          url,
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200) {
          return response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : <String, dynamic>{};
        }

        List<int> missing = const [];
        if (response.data is Map<String, dynamic>) {
          final raw =
              (response.data as Map<String, dynamic>)['missingChunks'];
          if (raw is List) {
            missing = raw.map((e) => e as int).toList();
          }
        }
        throw TransferClientException(
          'Finalize failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          missingChunks: missing,
        );
      },
      retryIf: _shouldRetry,
    );
  }

  /// Cancels an in-progress transfer on the recipient device.
  Future<bool> cancelTransfer(Device target, String transferId) async {
    final url = '${_baseUrl(target)}/api/v1/transfer/cancel/$transferId';

    try {
      final response = await _dio.post(
        url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[TransferClient] Cancel request error: $e');
      return false;
    }
  }

  /// Retrieves transfer status from recipient device.
  ///
  /// Returns `null` when the peer is unreachable or does not know the
  /// transfer, which is exactly what [ConnectionMonitor] needs to detect a
  /// drop.
  Future<Map<String, dynamic>?> getTransferStatus(
    Device target,
    String transferId,
  ) async {
    final url = '${_baseUrl(target)}/api/v1/transfer/status/$transferId';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[TransferClient] Get status error: $e');
      return null;
    }
  }

  /// Reads `[start, endExclusive)` of [filePath] without loading the file.
  static Future<Uint8List> readChunk(
    String filePath,
    int start,
    int endExclusive,
  ) async {
    final length = endExclusive - start;
    if (length <= 0) return Uint8List(0);

    final file = File(filePath);
    if (!await file.exists()) {
      throw TransferClientException('Local file not found: $filePath');
    }

    final raf = await file.open();
    try {
      final size = await raf.length();
      if (start < 0 || endExclusive > size) {
        throw TransferClientException(
          'Chunk range $start-$endExclusive is outside file of $size bytes',
        );
      }
      await raf.setPosition(start);
      final bytes = await raf.read(length);
      if (bytes.length != length) {
        throw TransferClientException(
          'Short read for $filePath: got ${bytes.length} of $length bytes',
        );
      }
      return bytes;
    } finally {
      await raf.close();
    }
  }
}
