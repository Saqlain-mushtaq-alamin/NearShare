/// Human readable byte sizes used across the UI.
String formatBytes(int bytes) {
  if (bytes < 0) return '0 B';
  if (bytes < 1024) return '$bytes B';

  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = -1;
  do {
    value /= 1024;
    unitIndex++;
  } while (value >= 1024 && unitIndex < units.length - 1);

  final formatted = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}

/// Short, locale-independent timestamp: time for today, date otherwise.
String formatTimestamp(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final local = time.toLocal();
  final sameDay = local.year == reference.year &&
      local.month == reference.month &&
      local.day == reference.day;

  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final clock = '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  if (sameDay) return clock;
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
}

/// "2 files · 5.0 MB"
String fileCountLabel(int fileCount, int totalSizeBytes) {
  final noun = fileCount == 1 ? 'file' : 'files';
  return '$fileCount $noun · ${formatBytes(totalSizeBytes)}';
}
