import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_client.dart';
import 'auth_models.dart';

/// Talks to the Django auth endpoints. The repository owns all network shapes;
/// controllers/widgets never touch Dio directly.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Exchanges a verified Google ID token for an app session.
  Future<AuthResult> signInWithGoogle(String idToken) async {
    final resp = await _dio.post('/auth/google/', data: {'id_token': idToken});
    return AuthResult.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  /// Fetches the authenticated user's own profile.
  Future<UserProfile> fetchMe() async {
    final resp = await _dio.get('/me/');
    return UserProfile.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  /// Revokes the current session server-side.
  Future<void> logout() async {
    await _dio.post('/auth/logout/');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
