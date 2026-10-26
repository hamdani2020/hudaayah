from rest_framework.response import Response
from rest_framework.views import APIView

from .client import get_client


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
