import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_client.dart';
import 'progress_models.dart';

class ProgressRepository {
  ProgressRepository(this._dio);
  final Dio _dio;

  Future<ProgressSummary> fetchSummary() async {
    final resp = await _dio.get('/progress/');
    return ProgressSummary.fromJson((resp.data as Map).cast<String, dynamic>());
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(ref.watch(dioProvider));
});

/// Progress summary for the signed-in user. Refreshable via invalidate.
final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) {
  return ref.watch(progressRepositoryProvider).fetchSummary();
});
