/// Shared constants for the Merge Space LAN protocol.
class MergeProtocol {
  static const String groupHeader = 'x-merge-group-id';
  static const String deviceHeader = 'x-merge-device-id';
  static const String hashHeader = 'x-merge-hash';
  static const String modifiedHeader = 'x-merge-modified-at';
  static const String originHeader = 'x-merge-origin-device-id';
  static const String deletedHeader = 'x-merge-deleted';

  static const String healthPath = '/api/v1/merge/health';
  static const String pairPath = '/api/v1/merge/pair';
  static const String indexPath = '/api/v1/merge/sync/index';
  static const String filesPath = '/api/v1/merge/files';
  static const String statusPath = '/api/v1/merge/status';

  static String baseUrl(String host, int port) => 'http://$host:$port';

  static int get maxEncryptedFileBytes => 64 * 1024 * 1024;
}

class MergeClientException implements Exception {
  final String message;
  final int? statusCode;

  const MergeClientException(this.message, {this.statusCode});

  @override
  String toString() => 'MergeClientException: $message';
}
