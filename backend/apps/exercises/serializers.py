from rest_framework import serializers

from .models import Exercise


class ExerciseSerializer(serializers.ModelSerializer):
    """Client-facing exercise. CRITICAL: never expose `answer_key`."""

    class Meta:
        model = Exercise
        fields = ["id", "lesson", "type", "position", "config", "content_references"]
        read_only_fields = fields
