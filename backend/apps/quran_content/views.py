from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.authentication import BearerTokenAuthentication
from apps.lessons.services import published_surahs

from .client import get_client
from .services import list_reciters


class ChaptersView(APIView):
    """Phase-1 exit probe: proxy QF `/chapters` through the backend adapter.

    Confirms the QF token flow + dual headers work end-to-end. No QF text is
    persisted here; the adapter enforces the ≤1-week cache.
    """

    authentication_classes: list = []
    permission_classes: list = []

    def get(self, request):
        language = request.query_params.get("language", "en")
        data = get_client().get_chapters(language=language)
        return Response(data)


class RecitersView(APIView):
    """GET /reciters/ — reciters with audio for the published lessons' surahs."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(list_reciters(published_surahs()))
