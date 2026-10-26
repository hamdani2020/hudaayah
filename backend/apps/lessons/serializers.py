from rest_framework import serializers

from .models import Lesson


class LessonSerializer(serializers.ModelSerializer):
    """Lesson metadata + assembled QF content.

    `content` is injected by the view (fetched live from QF); it is not a model
    field. Educational fields (title, objectives) stay distinct from the QF
    content layers inside `content`.
    """

    content = serializers.DictField(read_only=True)

    class Meta:
        model = Lesson
        fields = [
            "id", "title", "order", "objectives",
            "surah", "ayah_start", "ayah_end",
            "content",
        ]
        read_only_fields = fields
