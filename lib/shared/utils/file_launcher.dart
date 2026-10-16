import 'dart:io';

import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb;
import 'package:flutter/services.dart' show MethodChannel, MissingPluginException;

/// Hands a local file or folder to the operating system's default handler.
///
/// NearShare never uploads files anywhere, so "Open" and "Open Folder" only
/// ever touch the local filesystem.
class FileLauncher {
  const FileLauncher();

  static const MethodChannel _channel = MethodChannel('nearshare/file_opener');

  /// Opens [path] with the platform default application.
  Future<bool> openFile(String path) => _launch(path);

  /// Reveals [path] inside its containing folder.
  Future<bool> openFolder(String path) {
    if (kIsWeb) return Future.value(false);

    try {
      if (Platform.isWindows) {
        return _runProcess('explorer', ['/select,', path]);
      }
      if (Platform.isMacOS) {
        return _runProcess('open', ['-R', path]);
      }
      if (Platform.isLinux) {
        return _runProcess('xdg-open', [File(path).parent.path]);
      }
    } catch (_) {
      return Future.value(false);
    }
    return Future.value(false);
  }

  Future<bool> _launch(String path) {
    if (kIsWeb) return Future.value(false);

    try {
      if (Platform.isWindows) {
        return _runProcess('cmd', ['/c', 'start', '', path], shell: true);
      }
      if (Platform.isMacOS) return _runProcess('open', [path]);
      if (Platform.isLinux) return _runProcess('xdg-open', [path]);
      if (Platform.isAndroid || Platform.isIOS) {
        return _invokePlatform('open', path);
      }
    } catch (_) {
      return Future.value(false);
    }
    return Future.value(false);
  }

  Future<bool> _runProcess(
    String executable,
    List<String> arguments, {
    bool shell = false,
  }) async {
    try {
      final result = await Process.run(
        executable,
        arguments,
        runInShell: shell,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _invokePlatform(String method, String path) async {
    try {
      final result = await _channel.invokeMethod<bool>(method, path);
      return result ?? false;
    } on MissingPluginException {
      debugPrint('[FileLauncher] No platform handler registered for $method');
      return false;
    } catch (_) {
      return false;
    }
  }
}
