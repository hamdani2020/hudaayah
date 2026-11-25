/// App-wide configuration.
///
/// Values can be overridden at build time via a dart-define file:
///   flutter run --dart-define-from-file=dart_defines/dev.json
/// The defaults below make a bare `flutter run` work on the Android emulator.
///
/// Host reachability:
/// - Android emulator reaches the host via 10.0.2.2
/// - iOS simulator reaches the host via localhost (override with the file)
class AppConfig {
  const AppConfig._();

  /// Base URL for the Django backend. All API calls go through here.
  /// Default targets the Android emulator's host alias.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Google **web/server** OAuth client ID. Passed to google_sign_in so the
  /// returned ID token is intended for our backend (its `aud`/server audience).
  /// This is a public client ID (it ships in the app), so a dev default is safe.
  /// MUST be the *Web application* client ID — using the Android client ID here
  /// causes Google error 28444 "Developer console is not set up correctly".
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '351213424423-aeicjvu1do70e17lugh4a7r597r5bbd5.apps.googleusercontent.com',
  );

  /// Public legal pages (served by Django on privacy.hudaayah.xyz).
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://privacy.hudaayah.xyz/privacy/',
  );
  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://privacy.hudaayah.xyz/terms/',
  );
  static const String deleteAccountUrl = String.fromEnvironment(
    'DELETE_ACCOUNT_URL',
    defaultValue: 'https://privacy.hudaayah.xyz/delete-account/',
  );

  /// Visible Quran Foundation attribution (required by QF terms).
  static const String qfAttribution = 'Quran content provided by Quran Foundation';

  /// Credit for the bundled Quran font (KFGQPC Uthmanic Script HAFS).
  static const String fontAttribution =
      'Quran font: KFGQPC Uthmanic Script HAFS, King Fahd Glorious Quran Printing Complex';
}
