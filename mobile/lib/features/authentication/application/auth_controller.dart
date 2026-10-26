import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
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
      return AuthState(user: me);
    } catch (_) {
      await _storage.clear();
      return const AuthState();
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
      return AuthState(user: result.user);
    });
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
