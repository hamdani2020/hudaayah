import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_client.dart';
import 'exercise_models.dart';

/// Attempt lifecycle against the backend. The server grades and owns scoring;
/// this repository only carries requests/responses.
class ExerciseRepository {
  ExerciseRepository(this._dio);

  final Dio _dio;

  Future<int> startAttempt(int lessonId) async {
    final resp = await _dio.post('/lessons/$lessonId/attempts/');
    return (resp.data as Map)['id'] as int;
  }

  Future<GradeResult> submitAnswer({
    required int attemptId,
    required int exerciseId,
    required Map<String, dynamic> submitted,
  }) async {
    final resp = await _dio.post(
      '/attempts/$attemptId/answers/',
      data: {'exercise_id': exerciseId, 'submitted': submitted},
    );
    return GradeResult.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  /// Completes the attempt. [idempotencyKey] makes a retry safe (no double award).
  Future<Map<String, dynamic>> complete({
    required int attemptId,
    required String idempotencyKey,
  }) async {
    final resp = await _dio.post(
      '/attempts/$attemptId/complete/',
      data: {'idempotency_key': idempotencyKey},
    );
    return (resp.data as Map).cast<String, dynamic>();
  }
}

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(dioProvider));
});
