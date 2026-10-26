from rest_framework import serializers

from .models import User


class GoogleAuthRequestSerializer(serializers.Serializer):
    id_token = serializers.CharField()


class RefreshRequestSerializer(serializers.Serializer):
    refresh_token = serializers.CharField()


class LogoutRequestSerializer(serializers.Serializer):
    # Optional: logout works from the access token's session regardless.
    refresh_token = serializers.CharField(required=False, allow_blank=True)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "provider", "display_name", "email", "avatar_url", "preferences"]
        read_only_fields = fields
