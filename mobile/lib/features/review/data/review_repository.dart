import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_client.dart';
import 'review_models.dart';

class ReviewRepository {
  ReviewRepository(this._dio);
  final Dio _dio;

  Future<List<ReviewItem>> fetchDue() async {
    final resp = await _dio.get('/reviews/due/');
    final items = ((resp.data as Map)['items'] as List?) ?? [];
    return items
        .map((i) => ReviewItem.fromJson((i as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> submit({required int itemId, required bool correct}) async {
    await _dio.post('/reviews/$itemId/review/', data: {'correct': correct});
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(dioProvider));
});

final dueReviewsProvider = FutureProvider<List<ReviewItem>>((ref) {
  return ref.watch(reviewRepositoryProvider).fetchDue();
});
