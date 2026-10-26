from django.urls import path

from .views import (
    CompleteAttemptView,
    DailyActivityView,
    ProgressView,
    StartAttemptView,
    SubmitAnswerView,
)

urlpatterns = [
    path("lessons/<int:lesson_id>/attempts/", StartAttemptView.as_view(),
         name="start-attempt"),
    path("attempts/<int:attempt_id>/answers/", SubmitAnswerView.as_view(),
         name="submit-answer"),
    path("attempts/<int:attempt_id>/complete/", CompleteAttemptView.as_view(),
         name="complete-attempt"),
    path("progress/", ProgressView.as_view(), name="progress"),
    path("activity/daily/", DailyActivityView.as_view(), name="activity-daily"),
]
