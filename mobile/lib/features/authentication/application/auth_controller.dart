import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

/// Authentication state: the signed-in user, or null when signed out.
class AuthState {
  final UserProfile? user;
  const AuthState({this.user});

  bool get isSignedIn => user != null;
}

class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  Future<AuthState> build() async {
    // Restore an existing session on startup, if any.
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) return const AuthState();
    try {
      final me = await _repo.fetchMe();
      await _cacheProfile(me);
      return AuthState(user: me);
    } catch (e) {
      if (_isSessionRejected(e)) {
        // The server says the session is no longer valid: sign out for real.
        await _storage.clear();
        return const AuthState();
      }
      // Offline, timeout or server hiccup: the session may still be fine. Keep the
      // tokens and use the last known profile so the user lands on Home.
      final cached = await _cachedProfile();
      return AuthState(user: cached);
    }
  }

  /// True only when the backend rejected the session (401/403). Network errors,
  /// timeouts and 5xx keep the user signed in.
  bool _isSessionRejected(Object e) {
    int? status;
    if (e is DioException) {
      status = e.response?.statusCode;
      final inner = e.error;
      if (status == null && inner is ApiException) status = inner.statusCode;
    } else if (e is ApiException) {
      status = e.statusCode;
    }
    return status == 401 || status == 403;
  }

  Future<void> _cacheProfile(UserProfile user) async {
    try {
      await _storage.saveProfileJson(jsonEncode(user.toJson()));
    } catch (_) {
      // Cache is best-effort; never block sign-in on it.
    }
  }

  Future<UserProfile?> _cachedProfile() async {
    try {
      final raw = await _storage.readProfileJson();
      if (raw == null || raw.isEmpty) return null;
      return UserProfile.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Full Google sign-in: provider auth -> ID token -> backend session.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final signIn = GoogleSignIn.instance;
      // serverClientId MUST be the Google *Web application* client ID so the
      // ID token's audience is intended for the Django backend. (Using the
      // Android client ID here causes Google error 28444.)
      await signIn.initialize(
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google did not return an ID token.');
      }
      final result = await _repo.signInWithGoogle(idToken);
      await _storage.saveTokens(
        access: result.accessToken,
        refresh: result.refreshToken,
      );
      await _cacheProfile(result.user);
      return AuthState(user: result.user);
    });
  }

  /// Permanently deletes the account on the server, then signs out locally.
  /// Throws if the server call fails, so the caller can show an error and the
  /// user stays signed in (nothing is cleared locally on failure).
  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    await _storage.clear();
    try {
      // Revoke the app's Google grant; fall back to a plain sign-out.
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    state = const AsyncValue.data(AuthState());
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // Even if the server call fails, clear locally.
    }
    await _storage.clear();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    state = const AsyncValue.data(AuthState());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
