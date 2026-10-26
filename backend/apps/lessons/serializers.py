from rest_framework import serializers

from apps.exercises.serializers import ExerciseSerializer

from .models import Lesson


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
            "content", "exercises",
        ]
        read_only_fields = fields

    def get_exercises(self, lesson) -> list:
        qs = lesson.exercises.published().order_by("position", "id")
        return ExerciseSerializer(qs, many=True).data
