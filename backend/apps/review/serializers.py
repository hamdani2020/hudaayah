from rest_framework import serializers

from .models import ReviewItem


class ReviewItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewItem
        fields = ["id", "item_type", "content_ref", "prompt", "due_at",
                  "interval_days", "repetitions"]
        read_only_fields = fields


class ReviewResultRequestSerializer(serializers.Serializer):
    correct = serializers.BooleanField()
