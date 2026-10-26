from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.errors import AppError

from .authentication import BearerTokenAuthentication
from .providers import verify_google
from .serializers import (
    GoogleAuthRequestSerializer,
    LogoutRequestSerializer,
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


class MeView(APIView):
    """GET /me/ — the authenticated user's own profile."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)
