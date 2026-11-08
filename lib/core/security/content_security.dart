import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../features/transfer/domain/transfer_file.dart';
import '../../features/transfer/domain/transfer_request.dart';

class ContentValidationResult {
  const ContentValidationResult({
    required this.errors,
    required this.warnings,
  });

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;

  String get message => errors.isEmpty ? warnings.join('; ') : errors.join('; ');
}

/// Validates transfer metadata before any receiver-side chunks are accepted.
class TransferContentValidator {
  const TransferContentValidator({
    this.maxFiles = 10000,
    this.maxTotalSizeBytes = 1024 * 1024 * 1024 * 1024,
    this.maxFileSizeBytes = 1024 * 1024 * 1024 * 1024,
    this.maxChunkSize = 8 * 1024 * 1024,
    this.suspiciousExtensions = const <String>{
      'exe',
      'bat',
      'cmd',
      'com',
      'scr',
      'msi',
      'ps1',
      'vbs',
      'js',
      'jar',
      'lnk',
    },
  });

  final int maxFiles;
  final int maxTotalSizeBytes;
  final int maxFileSizeBytes;
  final int maxChunkSize;
  final Set<String> suspiciousExtensions;

  ContentValidationResult validate(TransferRequest request) {
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];

    if (request.transferId.trim().isEmpty) {
      errors.add('Missing transfer id');
    }
    if (request.senderId.trim().isEmpty) {
      errors.add('Missing sender id');
    }
    if (request.files.isEmpty) {
      errors.add('A transfer must contain at least one file');
    }
    if (request.files.length > maxFiles) {
      errors.add('Too many files (maximum $maxFiles)');
    }
    if (request.chunkSize <= 0) {
      errors.add('Invalid chunk size');
    } else if (request.chunkSize > maxChunkSize) {
      errors.add('Chunk size exceeds $maxChunkSize bytes');
    }
    if (request.totalSizeBytes < 0) {
      errors.add('Invalid total size');
    } else if (request.totalSizeBytes > maxTotalSizeBytes) {
      errors.add('Transfer exceeds the maximum total size');
    }

    int summedSize = 0;
    for (final TransferFile file in request.files) {
      final String name = file.name.trim();
      if (name.isEmpty) {
        errors.add('A file is missing its name');
      } else if (name.length > 255) {
        warnings.add('File name will be shortened: $name');
      }
      if (file.sizeInBytes < 0) {
        errors.add('File "$name" has an invalid size');
      } else if (file.sizeInBytes > maxFileSizeBytes) {
        errors.add('File "$name" exceeds the maximum file size');
      } else {
        summedSize += file.sizeInBytes;
      }
      final String extension = _extensionOf(name);
      if (suspiciousExtensions.contains(extension)) {
        warnings.add('Executable file type detected: $name');
      }
      final String? hash = file.sha256;
      if (hash != null && !_isSha256(hash)) {
        errors.add('File "$name" has an invalid sha256 checksum');
      }
    }

    if (summedSize != request.totalSizeBytes) {
      errors.add('Total size does not match the file list');
    }

    return ContentValidationResult(errors: errors, warnings: warnings);
  }

  String _extensionOf(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return '';
    }
    return name.substring(dot + 1).toLowerCase();
  }

  bool _isSha256(String value) => RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value);
}

/// Streaming SHA-256 helpers shared by senders and receivers.
class FileChecksum {
  const FileChecksum._();

  static Future<String> sha256OfFile(String path) async {
    final Digest digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }

  static Future<String> sha256OfBytes(List<int> bytes) async {
    return sha256.convert(bytes).toString();
  }
}
