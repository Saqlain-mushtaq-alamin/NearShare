import 'package:flutter/material.dart';

/// One place for every icon (and platform colour) the UI needs, so a file row
/// on the picker screen looks exactly like a file row on the receive sheet.
abstract final class AppIcons {
  // ---------------------------------------------------------------------------
  // Platforms
  // ---------------------------------------------------------------------------

  static IconData platformFor(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.phone_android;
      case 'ios':
      case 'iphone':
      case 'ipad':
        return Icons.phone_iphone;
      case 'macos':
      case 'mac':
        return Icons.laptop_mac;
      case 'windows':
        return Icons.desktop_windows;
      case 'linux':
        return Icons.terminal;
      case 'web':
        return Icons.language;
      default:
        return Icons.devices_other;
    }
  }

  static Color platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return const Color(0xFF3DDC84);
      case 'ios':
      case 'macos':
      case 'mac':
      case 'iphone':
      case 'ipad':
        return const Color(0xFF8E8E93);
      case 'windows':
        return const Color(0xFF0078D4);
      case 'linux':
        return const Color(0xFFF5793A);
      case 'web':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF1A4BCF);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  static const IconData send = Icons.near_me_rounded;
  static const IconData receive = Icons.sensors_rounded;
  static const IconData scan = Icons.radar_rounded;
  static const IconData history = Icons.history_rounded;
  static const IconData settings = Icons.tune_rounded;

  // ---------------------------------------------------------------------------
  // Files
  // ---------------------------------------------------------------------------

  /// Icon for a file based on its extension and (optionally) mime type.
  static IconData fileFor(String name, {String? mimeType}) {
    final ext = _extensionOf(name);
    if (_imageExtensions.contains(ext) || (mimeType ?? '').startsWith('image/')) {
      return Icons.image_outlined;
    }
    if (_videoExtensions.contains(ext) || (mimeType ?? '').startsWith('video/')) {
      return Icons.movie_outlined;
    }
    if (_audioExtensions.contains(ext) || (mimeType ?? '').startsWith('audio/')) {
      return Icons.audio_file_outlined;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (_archiveExtensions.contains(ext)) return Icons.folder_zip_outlined;
    if (_documentExtensions.contains(ext)) return Icons.description_outlined;
    if (ext == 'apk') return Icons.android;
    return Icons.insert_drive_file_outlined;
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static const Set<String> _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp', 'svg',
  };
  static const Set<String> _videoExtensions = {
    'mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v',
  };
  static const Set<String> _audioExtensions = {
    'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac',
  };
  static const Set<String> _archiveExtensions = {
    'zip', 'rar', 'tar', 'gz', '7z', 'bz2',
  };
  static const Set<String> _documentExtensions = {
    'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt',
    'pptx', 'csv', 'md', 'json', 'xml',
  };
}
