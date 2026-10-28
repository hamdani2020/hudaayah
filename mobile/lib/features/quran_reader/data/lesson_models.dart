import '../../exercises/data/exercise_models.dart';

/// DTOs for the `/lessons/{id}/` response.
///
/// Content layers are kept distinct (quran-content-rules): [arabic] is the
/// sacred text, [translation] is an attributed translation, and the two are
/// never merged in the model or the UI.
class WordPiece {
  final String? arabic;
  final String? translation;
  final String? transliteration;

  const WordPiece({this.arabic, this.translation, this.transliteration});

  factory WordPiece.fromJson(Map<String, dynamic> j) => WordPiece(
        arabic: j['arabic'] as String?,
        translation: j['translation'] as String?,
        transliteration: j['transliteration'] as String?,
      );
}

class Ayah {
  final String verseKey;
  final String? arabic;
  final String? translation;
  final String? audioUrl;
  final List<WordPiece> words;

  const Ayah({
    required this.verseKey,
    this.arabic,
    this.translation,
    this.audioUrl,
    this.words = const [],
  });

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
        verseKey: j['verse_key'] as String,
        arabic: j['arabic'] as String?,
        translation: j['translation'] as String?,
        audioUrl: j['audio_url'] as String?,
        words: ((j['words'] as List?) ?? [])
            .map((w) => WordPiece.fromJson((w as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class Lesson {
  final int id;
  final String title;
  final int surah;
  final int ayahStart;
  final int ayahEnd;
  final String surahNameEn;
  final String surahNameAr;
  final String surahMeaning;
  final int surahAyahCount;
  final String revelationPlace;
  final List<String> objectives;
  final List<Ayah> ayahs;
  final List<Exercise> exercises;
  final String attribution;

  const Lesson({
    required this.id,
    required this.title,
    required this.surah,
    required this.ayahStart,
    required this.ayahEnd,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.surahMeaning,
    required this.surahAyahCount,
    required this.revelationPlace,
    required this.objectives,
    required this.ayahs,
    required this.exercises,
    required this.attribution,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) {
    final content = (j['content'] as Map?)?.cast<String, dynamic>() ?? {};
    return Lesson(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      surah: j['surah'] as int? ?? 1,
      ayahStart: j['ayah_start'] as int? ?? 1,
      ayahEnd: j['ayah_end'] as int? ?? 1,
      surahNameEn: j['surah_name_en'] as String? ?? '',
      surahNameAr: j['surah_name_ar'] as String? ?? '',
      surahMeaning: j['surah_meaning'] as String? ?? '',
      surahAyahCount: j['surah_ayah_count'] as int? ?? 0,
      revelationPlace: j['revelation_place'] as String? ?? '',
      objectives: ((j['objectives'] as List?) ?? []).cast<String>(),
      ayahs: ((content['ayahs'] as List?) ?? [])
          .map((a) => Ayah.fromJson((a as Map).cast<String, dynamic>()))
          .toList(),
      exercises: ((j['exercises'] as List?) ?? [])
          .map((e) => Exercise.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      attribution: content['attribution'] as String? ?? '',
    );
  }

  /// Display name, preferring the seeded English surah name.
  String get displayName =>
      surahNameEn.isNotEmpty ? 'Surah $surahNameEn' : title;

  /// e.g. "Ayah 1–7" (or "Ayah 3" for a single-ayah lesson).
  String get ayahRange =>
      ayahStart == ayahEnd ? 'Ayah $ayahStart' : 'Ayah $ayahStart–$ayahEnd';
}

/// Lightweight catalog entry from `GET /lessons/` (no QF content). Drives the
/// surah list without hardcoding any surah metadata in the app.
class LessonSummary {
  final int id;
  final String title;
  final int order;
  final int surah;
  final int ayahStart;
  final int ayahEnd;
  final String surahNameEn;
  final String surahNameAr;
  final String surahMeaning;
  final int surahAyahCount;
  final String revelationPlace;

  const LessonSummary({
    required this.id,
    required this.title,
    required this.order,
    required this.surah,
    required this.ayahStart,
    required this.ayahEnd,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.surahMeaning,
    required this.surahAyahCount,
    required this.revelationPlace,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> j) => LessonSummary(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        order: j['order'] as int? ?? 0,
        surah: j['surah'] as int? ?? 0,
        ayahStart: j['ayah_start'] as int? ?? 0,
        ayahEnd: j['ayah_end'] as int? ?? 0,
        surahNameEn: j['surah_name_en'] as String? ?? '',
        surahNameAr: j['surah_name_ar'] as String? ?? '',
        surahMeaning: j['surah_meaning'] as String? ?? '',
        surahAyahCount: j['surah_ayah_count'] as int? ?? 0,
        revelationPlace: j['revelation_place'] as String? ?? '',
      );

  String get displayName =>
      surahNameEn.isNotEmpty ? 'Surah $surahNameEn' : title;

  String get ayahRange =>
      ayahStart == ayahEnd ? 'Ayah $ayahStart' : 'Ayah $ayahStart–$ayahEnd';
}
