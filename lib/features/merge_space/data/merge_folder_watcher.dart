import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'merge_space_storage.dart';

/// Watches the Merge Space folder and reports meaningful file changes.
class MergeFolderWatcher {
  final MergeSpaceStorage _storage;
  final void Function() _onChanged;

  StreamSubscription<FileSystemEvent>? _subscription;
  bool _paused = false;

  MergeFolderWatcher({
    required MergeSpaceStorage storage,
    required void Function() onChanged,
  })  : _storage = storage,
        _onChanged = onChanged;

  bool get isWatching => _subscription != null;

  Future<void> start() async {
    if (_subscription != null) return;
    final root = await _storage.ensureRoot();
    try {
      _subscription = Directory(root)
          .watch(recursive: true, events: FileSystemEvent.all)
          .listen(
        _handleEvent,
        onError: (Object error) {
          debugPrint('[MergeFolderWatcher] Watch error: $error');
        },
      );
    } catch (error) {
      debugPrint('[MergeFolderWatcher] Could not watch folder: $error');
    }
  }

  void _handleEvent(FileSystemEvent event) {
    if (_paused) return;
    final name = p.basename(event.path);
    if (name.endsWith('.merge-tmp')) return;
    if (name.startsWith('.')) return;
    if (name.endsWith('.crdownload') || name.endsWith('.part')) return;
    _onChanged();
  }

  /// Suppresses callbacks while this device writes files during a sync pass.
  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() => stop();
}
