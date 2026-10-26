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
      onError: (DioException e, handler) {
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
