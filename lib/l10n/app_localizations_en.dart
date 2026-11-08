// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NearShare';

  @override
  String get appLockTitle => 'NearShare is locked';

  @override
  String get appLockSubtitle =>
      'Unlock with your device PIN, password, or biometrics.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockNearShare => 'Unlock NearShare';

  @override
  String get appLockSettingsTitle => 'App lock';

  @override
  String get appLockSettingsSubtitle =>
      'Require your device PIN, password, or biometrics.';

  @override
  String get lockNow => 'Lock now';

  @override
  String get lockNowSubtitle => 'Lock NearShare until you authenticate again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get deviceSection => 'DEVICE';

  @override
  String get storageSection => 'STORAGE';

  @override
  String get transferSection => 'TRANSFER';

  @override
  String get appSection => 'APP';

  @override
  String get dataSection => 'DATA';

  @override
  String get aboutSection => 'ABOUT';

  @override
  String get deviceName => 'Device name';

  @override
  String get deviceId => 'Device ID';

  @override
  String get copyDeviceId => 'Copy device ID';

  @override
  String get saveLocation => 'Save location';

  @override
  String get storageUsage => 'NearShare storage';

  @override
  String get autoAcceptKnownDevices => 'Auto-accept known devices';

  @override
  String get autoAcceptKnownDevicesSubtitle =>
      'Skip the confirmation when a trusted device sends files.';

  @override
  String get encryptTransfers => 'Encrypt transfers';

  @override
  String get encryptTransfersSubtitle =>
      'Protect file data in transit between devices.';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get replayTour => 'Replay welcome tour';

  @override
  String get transferHistory => 'Transfer history';

  @override
  String get transferHistorySubtitle => 'Everything stays on this device';

  @override
  String get clearHistory => 'Clear transfer history';

  @override
  String get clearHistorySubtitle => 'Files themselves are not deleted';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheSubtitle => 'Remove temporary transfer data';

  @override
  String get privacyPromise => 'We don’t collect your data. Full stop.';

  @override
  String get privacyPromiseSubtitle =>
      'No account, no cloud, no analytics — your files never leave your Wi-Fi network.';

  @override
  String get version => 'Version';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';
}
