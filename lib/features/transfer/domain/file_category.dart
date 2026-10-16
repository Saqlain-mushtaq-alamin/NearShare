/// Which picker tab a file belongs to.
enum FileCategory { photos, videos, documents, other }

/// Maps a file (by mime type and/or extension) to a [FileCategory].
FileCategory categorizeFile({required String name, String? mimeType}) {
  final mime = (mimeType ?? '').toLowerCase();
  final ext = _extensionOf(name);

  if (mime.startsWith('image/') || _photoExtensions.contains(ext)) {
    return FileCategory.photos;
  }
  if (mime.startsWith('video/') || _videoExtensions.contains(ext)) {
    return FileCategory.videos;
  }
  if (mime.startsWith('audio/') ||
      mime == 'application/pdf' ||
      mime.startsWith('text/') ||
      _audioExtensions.contains(ext) ||
      _documentExtensions.contains(ext)) {
    return FileCategory.documents;
  }
  return FileCategory.other;
}

String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

const Set<String> _photoExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp',
};
const Set<String> _videoExtensions = {
  'mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v',
};
const Set<String> _audioExtensions = {
  'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac',
};
const Set<String> _documentExtensions = {
  'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'xls', 'xlsx', 'ppt',
  'pptx', 'csv', 'md', 'json', 'xml',
};
