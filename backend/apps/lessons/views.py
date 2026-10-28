from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.authentication import BearerTokenAuthentication
from apps.common.errors import AppError

from .models import Lesson
from .serializers import LessonListItemSerializer, LessonSerializer
from .services import build_lesson_content


class LessonListView(ListAPIView):
    """GET /lessons/ — published lessons as a lightweight catalog (no QF content).

    Drives the client's surah list fully from the backend, so new published
    lessons appear with no app change.
    """

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = LessonListItemSerializer
    pagination_class = None  # small catalog; return all published lessons

    def get_queryset(self):
        return Lesson.objects.published().order_by("order", "id")


class LessonNotAvailable(AppError):
    code = "lesson_not_available"
    message = "This lesson is not available."
    http_status = 404


class LessonDetailView(RetrieveAPIView):
    """GET /lessons/{id}/ — published lessons only, with live QF content."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]
    serializer_class = LessonSerializer

    def get_queryset(self):
        # Published-only (R9): drafts/in_review/archived are never served.
        return Lesson.objects.published()

    def get_object(self):
        try:
            lesson = self.get_queryset().get(pk=self.kwargs["pk"])
        except Lesson.DoesNotExist:
            raise LessonNotAvailable()
        return lesson

    def retrieve(self, request, *args, **kwargs):
        lesson = self.get_object()
        data = self.get_serializer(lesson).data
        # Assemble QF content live (adapter enforces ≤1wk cache).
        data["content"] = build_lesson_content(lesson)
        return Response(data)
