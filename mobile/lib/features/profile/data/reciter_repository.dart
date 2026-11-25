import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/dio_client.dart';
import '../../quran_reader/data/lesson_repository.dart';

/// The reciter the backend uses when the learner has not chosen one (mirrors
/// `DEFAULT_RECITER_ID` in the backend adapter).
const defaultReciterId = 7;

/// One entry of `GET /reciters/`.
class Reciter {
  final int id;
  final String name;
  final String style;
  final bool hasTimings;
  const Reciter({
    required this.id,
    required this.name,
    this.style = '',
    this.hasTimings = false,
  });

  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        style: j['style'] as String? ?? '',
        hasTimings: j['has_timings'] as bool? ?? false,
      );
}

/// Reciter list and the learner's saved choice. Both live on the backend so the
/// choice follows the account to other devices.
class ReciterRepository {
  ReciterRepository(this._dio);
  final Dio _dio;

  Future<List<Reciter>> fetchReciters() async {
    final resp = await _dio.get('/reciters/');
    final data = resp.data;
    final list = data is List
        ? data
        : (data is Map && data['results'] is List)
            ? data['results'] as List
            : const [];
    return [
      for (final e in list) Reciter.fromJson((e as Map).cast<String, dynamic>()),
    ];
  }

  /// The saved `reciter_id`, or null if the learner never chose one.
  Future<int?> fetchSavedReciterId() async {
    final resp = await _dio.get('/me/');
    final prefs = (resp.data as Map)['preferences'];
    final id = prefs is Map ? prefs['reciter_id'] : null;
    return id is int ? id : null;
  }

  Future<void> saveReciterId(int id) async {
    await _dio.patch('/me/preferences/', data: {'reciter_id': id});
  }
}

final reciterRepositoryProvider = Provider<ReciterRepository>((ref) {
  return ReciterRepository(ref.watch(dioProvider));
});

/// Every reciter the backend offers.
final recitersProvider = FutureProvider<List<Reciter>>((ref) {
  return ref.watch(reciterRepositoryProvider).fetchReciters();
});

/// The learner's chosen reciter id (null = default). Saving it invalidates the
/// lessons so the reader and the listening exercises reload with the new audio.
class SelectedReciterController extends AsyncNotifier<int?> {
  @override
  Future<int?> build() {
    return ref.watch(reciterRepositoryProvider).fetchSavedReciterId();
  }

  /// Throws on failure; the saved choice is unchanged in that case.
  Future<void> select(int id) async {
    await ref.read(reciterRepositoryProvider).saveReciterId(id);
    state = AsyncData(id);
    ref.invalidate(lessonProvider);
  }
}

final selectedReciterProvider =
    AsyncNotifierProvider<SelectedReciterController, int?>(
        SelectedReciterController.new);
