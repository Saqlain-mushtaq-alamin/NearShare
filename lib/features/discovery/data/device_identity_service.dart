import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/device.dart';

class DeviceIdentityService {
  static const String _prefDeviceIdKey = 'nearshare_device_id';
  static const String _prefDeviceNameKey = 'nearshare_device_name';
  static const String _prefDevicePortKey = 'nearshare_device_port';
  static const int defaultPort = 53317;

  final SharedPreferences? _prefs;
  final DeviceInfoPlugin _deviceInfo;
  final Uuid _uuid;

  DeviceIdentityService({
    SharedPreferences? prefs,
    DeviceInfoPlugin? deviceInfo,
    Uuid? uuid,
  })  : _prefs = prefs,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _uuid = uuid ?? const Uuid();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  String getPlatformName() {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isWindows) return 'windows';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await _getPrefs();
    String? id = prefs.getString(_prefDeviceIdKey);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await prefs.setString(_prefDeviceIdKey, id);
    }
    return id;
  }

  Future<String> getOrCreateDeviceName() async {
    final prefs = await _getPrefs();
    String? name = prefs.getString(_prefDeviceNameKey);
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    // Generate a friendly default name based on hardware
    String generatedName = 'NearShare Peer';
    try {
      generatedName = await _hardwareName();
    } catch (_) {
      generatedName = '${getPlatformName().toUpperCase()} Device';
    }

    await prefs.setString(_prefDeviceNameKey, generatedName);
    return generatedName;
  }

  Future<String> _hardwareName() async {
    if (kIsWeb) {
      final webInfo = await _deviceInfo.webBrowserInfo;
      return '${webInfo.browserName.name.toUpperCase()} Web';
    }
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.model.isNotEmpty
          ? androidInfo.model
          : (androidInfo.brand.isNotEmpty ? androidInfo.brand : 'Android Device');
    }
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.name.isNotEmpty
          ? iosInfo.name
          : (iosInfo.model.isNotEmpty ? iosInfo.model : 'iPhone');
    }
    if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      return windowsInfo.computerName.isNotEmpty
          ? windowsInfo.computerName
          : 'Windows PC';
    }
    if (Platform.isMacOS) {
      final macInfo = await _deviceInfo.macOsInfo;
      return macInfo.computerName.isNotEmpty ? macInfo.computerName : 'MacBook';
    }
    if (Platform.isLinux) {
      final linuxInfo = await _deviceInfo.linuxInfo;
      return linuxInfo.name.isNotEmpty ? linuxInfo.name : 'Linux PC';
    }
    return 'NearShare Peer';
  }

  Future<void> setDeviceName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final prefs = await _getPrefs();
    await prefs.setString(_prefDeviceNameKey, trimmed);
  }

  Future<int> getDevicePort() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_prefDevicePortKey) ?? defaultPort;
  }

  Future<void> setDevicePort(int port) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_prefDevicePortKey, port);
  }

  Future<Device> getLocalDevice({String ipAddress = '127.0.0.1'}) async {
    final id = await getOrCreateDeviceId();
    final name = await getOrCreateDeviceName();
    final port = await getDevicePort();
    final platform = getPlatformName();

    return Device(
      id: id,
      name: name,
      platform: platform,
      ipAddress: ipAddress,
      port: port,
      discoveredAt: DateTime.now(),
    );
  }
}
