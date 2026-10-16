/// Coarse classification of a file, used to pick an icon or thumbnail.
enum FileKind {
  image,
  video,
  audio,
  archive,
  document,
  other;

  const FileKind();

  static const _images = {'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic'};
  static const _videos = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'};
  static const _audios = {'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'};
  static const _archives = {'zip', 'rar', '7z', 'tar', 'gz', 'bz2'};
  static const _documents = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'csv',
    'md',
  };

  /// Classifies [extension] (without the leading dot, case-insensitive).
  static FileKind fromExtension(String extension) {
    final ext = extension.toLowerCase().trim();
    if (ext.isEmpty) return other;
    if (_images.contains(ext)) return image;
    if (_videos.contains(ext)) return video;
    if (_audios.contains(ext)) return audio;
    if (_archives.contains(ext)) return archive;
    if (_documents.contains(ext)) return document;
    return other;
  }

  /// Classifies a file from its full name.
  static FileKind fromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return other;
    return fromExtension(fileName.substring(dot + 1));
  }

  /// True when the platform can render an inline preview thumbnail.
  bool get hasThumbnail => this == image || this == video;

  String get label {
    switch (this) {
      case FileKind.image:
        return 'Image';
      case FileKind.video:
        return 'Video';
      case FileKind.audio:
        return 'Audio';
      case FileKind.archive:
        return 'Archive';
      case FileKind.document:
        return 'Document';
      case FileKind.other:
        return 'File';
    }
  }
}
