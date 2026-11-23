import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-secure storage for session tokens (steering: never store tokens in
/// plain prefs). Keychain on iOS, EncryptedSharedPreferences on Android.
class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  // Last known profile (JSON), so a signed-in user stays signed in when the app
  // starts without a connection. Cleared together with the tokens.
  static const _profileKey = 'profile';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<String?> readProfileJson() => _storage.read(key: _profileKey);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: _accessTokenKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshTokenKey, value: refresh);
    }
  }

  Future<void> saveProfileJson(String json) =>
      _storage.write(key: _profileKey, value: json);

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _profileKey);
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  // v11 encrypts Android storage by default; defaults are the secure baseline.
  return SecureStorage(const FlutterSecureStorage());
});
