from rest_framework import serializers

from .models import User


class GoogleAuthRequestSerializer(serializers.Serializer):
    id_token = serializers.CharField()


class RefreshRequestSerializer(serializers.Serializer):
    refresh_token = serializers.CharField()


class LogoutRequestSerializer(serializers.Serializer):
    # Optional: logout works from the access token's session regardless.
    refresh_token = serializers.CharField(required=False, allow_blank=True)


class PreferencesUpdateSerializer(serializers.Serializer):
    # Strict int: rejects booleans, strings and floats.
    reciter_id = serializers.IntegerField(min_value=1, required=True)

    def to_internal_value(self, data):
        raw = data.get("reciter_id") if hasattr(data, "get") else None
        if isinstance(raw, (bool, str, float)):
            raise serializers.ValidationError({"reciter_id": "Must be an integer."})
        return super().to_internal_value(data)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "provider", "display_name", "email", "avatar_url", "preferences"]
        read_only_fields = fields
