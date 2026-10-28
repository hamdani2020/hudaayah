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

  /// Published lessons as a lightweight catalog (no QF content).
  Future<List<LessonSummary>> fetchLessons() async {
    final resp = await _dio.get('/lessons/');
    final data = resp.data;
    // Tolerate either a bare list or a paginated {results: [...]} envelope.
    final list = data is List
        ? data
        : (data is Map && data['results'] is List)
            ? data['results'] as List
            : const [];
    return list
        .map((e) => LessonSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.watch(dioProvider));
});

/// Loads a single lesson by id. Loading/error states handled by the UI.
final lessonProvider = FutureProvider.family<Lesson, int>((ref, id) {
  return ref.watch(lessonRepositoryProvider).fetchLesson(id);
});

/// Loads the published lesson catalog for the surah list.
final lessonsListProvider = FutureProvider<List<LessonSummary>>((ref) {
  return ref.watch(lessonRepositoryProvider).fetchLessons();
});
