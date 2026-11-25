from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.errors import AppError

from .authentication import BearerTokenAuthentication
from apps.quran_content.client import get_client

from .providers import verify_google
from .serializers import (
    GoogleAuthRequestSerializer,
    LogoutRequestSerializer,
    PreferencesUpdateSerializer,
    RefreshRequestSerializer,
    UserSerializer,
)
from .services import get_or_create_user, issue_session, refresh_session


class InvalidRefresh(AppError):
    code = "invalid_refresh_token"
    message = "Your session has expired. Please sign in again."
    http_status = 401


class GoogleAuthView(APIView):
    """POST /auth/google/ — verify a Google ID token, return an app session."""

    authentication_classes: list = []
    permission_classes: list = []

    def post(self, request):
        data = GoogleAuthRequestSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        identity = verify_google(data.validated_data["id_token"])
        user = get_or_create_user(identity)
        tokens = issue_session(user)
        return Response(
            {"user": UserSerializer(user).data, **tokens},
            status=status.HTTP_201_CREATED,
        )


class RefreshView(APIView):
    """POST /auth/refresh/ — rotate tokens from a valid refresh token."""

    authentication_classes: list = []
    permission_classes: list = []

    def post(self, request):
        data = RefreshRequestSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        tokens = refresh_session(data.validated_data["refresh_token"])
        if tokens is None:
            raise InvalidRefresh()
        return Response(tokens)


class LogoutView(APIView):
    """POST /auth/logout/ — revoke the current session."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        LogoutRequestSerializer(data=request.data).is_valid(raise_exception=True)
        session = getattr(request, "auth_session", None)
        if session is not None:
            session.revoke()
        return Response(status=status.HTTP_204_NO_CONTENT)


class InvalidPreferences(AppError):
    code = "invalid_preferences"
    message = "Those preferences could not be saved."
    http_status = 400


class InvalidReciter(AppError):
    code = "invalid_reciter"
    message = "That reciter is not available."
    http_status = 400


class PreferencesView(APIView):
    """PATCH /me/preferences/ — update the caller's own preferences.

    Acts only on `request.user` (no user id in the URL), so it is owner-only.
    """

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        data = PreferencesUpdateSerializer(data=request.data)
        if not data.is_valid():
            raise InvalidPreferences()
        reciter_id = data.validated_data["reciter_id"]

        # Validate against the adapter's reciter list (hidden reciters are absent).
        if reciter_id not in {r["id"] for r in get_client().get_reciters()}:
            raise InvalidReciter()

        with transaction.atomic():
            user = type(request.user).objects.select_for_update().get(pk=request.user.pk)
            prefs = dict(user.preferences or {})
            prefs["reciter_id"] = reciter_id
            user.preferences = prefs
            user.save(update_fields=["preferences"])
        return Response(UserSerializer(user).data)


class MeView(APIView):
    """GET /me/ — the authenticated user's own profile."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def delete(self, request):
        """DELETE /me/ — permanently delete the caller's account and all their data.

        Only ever acts on `request.user` (no user id in the URL), so ownership is implicit.
        Sessions, attempts, answers, progress, daily activity and review items are removed
        by ON DELETE CASCADE, atomically.
        """
        with transaction.atomic():
            request.user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
