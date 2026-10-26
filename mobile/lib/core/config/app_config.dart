/// App-wide configuration. Backend base URL is overridable at build time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///
/// Defaults:
/// - Android emulator reaches host via 10.0.2.2
/// - iOS simulator reaches host via localhost
class AppConfig {
  const AppConfig._();

  /// Base URL for the Django backend. All API calls go through here.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Visible Quran Foundation attribution (required by QF terms).
  static const String qfAttribution = 'Quran content provided by Quran Foundation';
}
