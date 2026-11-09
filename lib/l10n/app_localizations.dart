import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NearShare'**
  String get appTitle;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'NearShare is locked'**
  String get appLockTitle;

  /// No description provided for @appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your device PIN, password, or biometrics.'**
  String get appLockSubtitle;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockNearShare.
  ///
  /// In en, this message translates to:
  /// **'Unlock NearShare'**
  String get unlockNearShare;

  /// No description provided for @appLockSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockSettingsTitle;

  /// No description provided for @appLockSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require your device PIN, password, or biometrics.'**
  String get appLockSettingsSubtitle;

  /// No description provided for @lockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockNow;

  /// No description provided for @lockNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock NearShare until you authenticate again.'**
  String get lockNowSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @deviceSection.
  ///
  /// In en, this message translates to:
  /// **'DEVICE'**
  String get deviceSection;

  /// No description provided for @storageSection.
  ///
  /// In en, this message translates to:
  /// **'STORAGE'**
  String get storageSection;

  /// No description provided for @transferSection.
  ///
  /// In en, this message translates to:
  /// **'TRANSFER'**
  String get transferSection;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get appSection;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get dataSection;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutSection;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @copyDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Copy device ID'**
  String get copyDeviceId;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get saveLocation;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'NearShare storage'**
  String get storageUsage;

  /// No description provided for @autoAcceptKnownDevices.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept known devices'**
  String get autoAcceptKnownDevices;

  /// No description provided for @autoAcceptKnownDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the confirmation when a trusted device sends files.'**
  String get autoAcceptKnownDevicesSubtitle;

  /// No description provided for @encryptTransfers.
  ///
  /// In en, this message translates to:
  /// **'Encrypt transfers'**
  String get encryptTransfers;

  /// No description provided for @encryptTransfersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect file data in transit between devices.'**
  String get encryptTransfersSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @replayTour.
  ///
  /// In en, this message translates to:
  /// **'Replay welcome tour'**
  String get replayTour;

  /// No description provided for @transferHistory.
  ///
  /// In en, this message translates to:
  /// **'Transfer history'**
  String get transferHistory;

  /// No description provided for @transferHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device'**
  String get transferHistorySubtitle;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear transfer history'**
  String get clearHistory;

  /// No description provided for @clearHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Files themselves are not deleted'**
  String get clearHistorySubtitle;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove temporary transfer data'**
  String get clearCacheSubtitle;

  /// No description provided for @privacyPromise.
  ///
  /// In en, this message translates to:
  /// **'We don’t collect your data. Full stop.'**
  String get privacyPromise;

  /// No description provided for @privacyPromiseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No account, no cloud, no analytics — your files never leave your Wi-Fi network.'**
  String get privacyPromiseSubtitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
