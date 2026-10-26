from rest_framework import serializers

from .models import LessonAttempt


class StartAttemptResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = LessonAttempt
        fields = ["id", "lesson", "status", "started_at"]
        read_only_fields = fields


class SubmitAnswerRequestSerializer(serializers.Serializer):
    exercise_id = serializers.IntegerField()
    submitted = serializers.DictField()


class SubmitAnswerResponseSerializer(serializers.Serializer):
    correct = serializers.BooleanField()
    feedback = serializers.CharField()


class CompleteAttemptRequestSerializer(serializers.Serializer):
    # Client-supplied key makes completion retry-safe (no double award).
    idempotency_key = serializers.CharField(max_length=64)
