import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/secure_storage.dart';

/// Configured Dio instance pointed at the Django backend.
///
/// - Attaches the app session token when present.
/// - Normalizes backend error envelopes into [ApiException].
/// - 401 refresh/retry is added in the auth phase (Phase 2); the hook is here.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        // On 401, attempt a single refresh + retry (skip the refresh call itself).
        final isAuthEndpoint =
            e.requestOptions.path.contains('/auth/refresh/') ||
            e.requestOptions.path.contains('/auth/google/');
        final alreadyRetried = e.requestOptions.extra['__retried'] == true;

        if (e.response?.statusCode == 401 && !isAuthEndpoint && !alreadyRetried) {
          final refreshed = await _tryRefresh(dio, storage);
          if (refreshed) {
            final req = e.requestOptions;
            req.extra['__retried'] = true;
            final newToken = await storage.readAccessToken();
            if (newToken != null) {
              req.headers['Authorization'] = 'Bearer $newToken';
            }
            try {
              final clone = await dio.fetch(req);
              return handler.resolve(clone);
            } on DioException catch (retryErr) {
              return handler.next(retryErr);
            }
          } else {
            // Refresh failed — session is dead; clear local creds.
            await storage.clear();
          }
        }

        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: ApiException.fromEnvelope(data, e.response?.statusCode),
            ),
          );
          return;
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});

/// Attempts to rotate tokens using the stored refresh token. Returns true on
/// success (new tokens persisted). Uses a bare Dio to avoid interceptor recursion.
Future<bool> _tryRefresh(Dio dio, SecureStorage storage) async {
  final refresh = await storage.readRefreshToken();
  if (refresh == null || refresh.isEmpty) return false;
  try {
    final bare = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    final resp = await bare.post('/auth/refresh/', data: {'refresh_token': refresh});
    final body = (resp.data as Map).cast<String, dynamic>();
    await storage.saveTokens(
      access: body['access_token'] as String,
      refresh: body['refresh_token'] as String?,
    );
    return true;
  } on DioException {
    return false;
  }
}
