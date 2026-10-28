from rest_framework import serializers

from apps.exercises.serializers import ExerciseSerializer

from .models import Lesson


class LessonListItemSerializer(serializers.ModelSerializer):
    """Lightweight catalog entry for the surah list (GET /lessons/).

    Presentational metadata only — NO QF verse content (that's fetched per-lesson
    on detail). Lets the client render the surah list fully data-driven, so new
    surahs appear with no app change.
    """

    class Meta:
        model = Lesson
        fields = [
            "id", "title", "order",
            "surah", "ayah_start", "ayah_end",
            "surah_name_en", "surah_name_ar", "surah_meaning",
            "surah_ayah_count", "revelation_place",
        ]
        read_only_fields = fields


class LessonSerializer(serializers.ModelSerializer):
    """Lesson metadata + assembled QF content + published exercises.

    `content` is injected by the view (fetched live from QF); it is not a model
    field. Educational fields (title, objectives) stay distinct from the QF
    content layers inside `content`. Exercises never include the answer key.
    """

    content = serializers.DictField(read_only=True)
    exercises = serializers.SerializerMethodField()

    class Meta:
        model = Lesson
        fields = [
            "id", "title", "order", "objectives",
            "surah", "ayah_start", "ayah_end",
            "surah_name_en", "surah_name_ar", "surah_meaning",
            "surah_ayah_count", "revelation_place",
            "content", "exercises",
        ]
        read_only_fields = fields

    def get_exercises(self, lesson) -> list:
        qs = lesson.exercises.published().order_by("position", "id")
        return ExerciseSerializer(qs, many=True).data
