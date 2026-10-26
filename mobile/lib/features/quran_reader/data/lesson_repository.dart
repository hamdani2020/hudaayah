import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_client.dart';
import 'lesson_models.dart';

/// Fetches lesson content from the backend (which proxies QF).
class LessonRepository {
  LessonRepository(this._dio);

  final Dio _dio;

  Future<Lesson> fetchLesson(int id) async {
    final resp = await _dio.get('/lessons/$id/');
    return Lesson.fromJson((resp.data as Map).cast<String, dynamic>());
  }
}

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.watch(dioProvider));
});

/// Loads a single lesson by id. Loading/error states handled by the UI.
final lessonProvider = FutureProvider.family<Lesson, int>((ref, id) {
  return ref.watch(lessonRepositoryProvider).fetchLesson(id);
});
