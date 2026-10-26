from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.authentication import BearerTokenAuthentication
from apps.common.errors import AppError
from apps.exercises.models import Exercise
from apps.lessons.models import Lesson

from .models import AttemptStatus, LessonAttempt
from .serializers import (
    CompleteAttemptRequestSerializer,
    StartAttemptResponseSerializer,
    SubmitAnswerRequestSerializer,
    SubmitAnswerResponseSerializer,
)
from .services import complete_attempt, start_attempt, submit_answer


class NotFound(AppError):
    code = "not_found"
    message = "Not found."
    http_status = 404


class InvalidExercise(AppError):
    code = "invalid_exercise"
    message = "That exercise is not part of this lesson."
    http_status = 400


class AttemptAlreadyComplete(AppError):
    code = "attempt_completed"
    message = "This attempt is already complete."
    http_status = 409


class _OwnedAttemptMixin:
    """Fetch an attempt owned by the current user, or 404 (no cross-user access)."""

    def get_owned_attempt(self, request, attempt_id: int) -> LessonAttempt:
        try:
            return LessonAttempt.objects.select_related("lesson").get(
                pk=attempt_id, user=request.user
            )
        except LessonAttempt.DoesNotExist:
            raise NotFound(message="Attempt not found.")


class StartAttemptView(APIView):
    """POST /lessons/{id}/attempts/ — begin an attempt on a published lesson."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, lesson_id: int):
        try:
            lesson = Lesson.objects.published().get(pk=lesson_id)
        except Lesson.DoesNotExist:
            raise NotFound(message="Lesson not found.")
        attempt = start_attempt(user=request.user, lesson=lesson)
        return Response(
            StartAttemptResponseSerializer(attempt).data,
            status=status.HTTP_201_CREATED,
        )


class SubmitAnswerView(_OwnedAttemptMixin, APIView):
    """POST /attempts/{id}/answers/ — grade one answer on the server."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, attempt_id: int):
        attempt = self.get_owned_attempt(request, attempt_id)
        if attempt.status == AttemptStatus.COMPLETED:
            raise AttemptAlreadyComplete()

        req = SubmitAnswerRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)

        # Exercise must belong to this attempt's lesson and be published.
        try:
            exercise = Exercise.objects.published().get(
                pk=req.validated_data["exercise_id"], lesson=attempt.lesson
            )
        except Exercise.DoesNotExist:
            raise InvalidExercise()

        _, result = submit_answer(
            attempt=attempt, exercise=exercise,
            submitted=req.validated_data["submitted"],
        )
        return Response(
            SubmitAnswerResponseSerializer(
                {"correct": result.correct, "feedback": result.feedback}
            ).data
        )


class CompleteAttemptView(_OwnedAttemptMixin, APIView):
    """POST /attempts/{id}/complete/ — finalize, award XP, update progress."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, attempt_id: int):
        attempt = self.get_owned_attempt(request, attempt_id)
        req = CompleteAttemptRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)
        summary = complete_attempt(
            attempt=attempt, idempotency_key=req.validated_data["idempotency_key"]
        )
        return Response(summary)
