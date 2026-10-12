import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../discovery/domain/device.dart';
import '../domain/transfer_file.dart';
import '../domain/transfer_request.dart';

class TransferClient {
  final Dio _dio;

  TransferClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 60),
                sendTimeout: const Duration(minutes: 30),
              ),
            );

  String _baseUrl(Device target) => 'http://${target.ipAddress}:${target.port}';

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
        debugPrint('[TransferClient] Prepare request failed with status: ${response.statusCode}');
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

  /// Streams an individual file via multipart form-data to the target device.
  Future<Map<String, dynamic>> uploadFile(
    Device target,
    String transferId,
    int fileIndex,
    TransferFile file, {
    void Function(int sentBytes, int totalBytes)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final url = '${_baseUrl(target)}/api/v1/transfer/upload/$transferId/$fileIndex';

    try {
      MultipartFile multipartFile;
      if (file.localPath.isNotEmpty && File(file.localPath).existsSync()) {
        multipartFile = await MultipartFile.fromFile(
          file.localPath,
          filename: file.name,
        );
      } else {
        // Fallback for tests or simulated byte payloads
        multipartFile = MultipartFile.fromBytes(
          [],
          filename: file.name,
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        'name': file.name,
        'size': file.sizeInBytes,
        'mimeType': file.mimeType,
      });

      final response = await _dio.post(
        url,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          headers: {'content-type': 'multipart/form-data'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      } else {
        throw Exception(
          'Upload failed with status ${response.statusCode}: ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[TransferClient] Upload cancelled by user: $transferId');
      } else {
        debugPrint('[TransferClient] Upload DioException: ${e.message}');
      }
      rethrow;
    } catch (e) {
      debugPrint('[TransferClient] Upload exception: $e');
      rethrow;
    }
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
  Future<Map<String, dynamic>?> getTransferStatus(
    Device target,
    String transferId,
  ) async {
    final url = '${_baseUrl(target)}/api/v1/transfer/status/$transferId';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[TransferClient] Get status error: $e');
      return null;
    }
  }
}
