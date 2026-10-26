"""Attempt + grading tests: server-side grading per type, answer_key never
leaked, object-level ownership, and idempotent completion (no double-award)."""
import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.exercises.models import Exercise, ExerciseType
from apps.lessons.models import Lesson
from apps.progress.models import DailyActivity, LessonAttempt

pytestmark = pytest.mark.django_db


def _client(sub="learner"):
    user, _ = User.objects.get_or_create(
        provider="google", provider_sub=sub, defaults={"display_name": sub}
    )
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c, user


def _lesson_with_exercises():
    lesson = Lesson.objects.create(
        title="Al-Fatihah", surah=1, ayah_start=1, ayah_end=1,
        status=ContentStatus.PUBLISHED,
    )
    mc = Exercise.objects.create(
        lesson=lesson, type=ExerciseType.MULTIPLE_CHOICE, position=1,
        status=ContentStatus.PUBLISHED,
        config={"prompt": "?", "options": [{"id": "a"}, {"id": "b"}]},
        answer_key={"correct_option_id": "a"},
    )
    wo = Exercise.objects.create(
        lesson=lesson, type=ExerciseType.WORD_ORDER, position=2,
        status=ContentStatus.PUBLISHED,
        config={"tokens": [{"id": "t1"}, {"id": "t2"}]},
        answer_key={"correct_order": ["t1", "t2"]},
    )
    lr = Exercise.objects.create(
        lesson=lesson, type=ExerciseType.LISTENING_RECALL, position=3,
        status=ContentStatus.PUBLISHED, config={"verse_key": "1:2"}, answer_key={},
    )
    return lesson, mc, wo, lr


def test_answer_key_never_serialized():
    lesson, *_ = _lesson_with_exercises()
    client, _ = _client()
    # Exercises are embedded in the lesson detail; the key must not appear.
    import json
    from apps.lessons.serializers import LessonSerializer
    data = json.dumps(LessonSerializer(lesson).data)
    assert "answer_key" not in data
    assert "correct_option_id" not in data


def test_multiple_choice_grading():
    lesson, mc, *_ = _lesson_with_exercises()
    client, _ = _client()
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    right = client.post(f"/api/v1/attempts/{aid}/answers/",
                        {"exercise_id": mc.id, "submitted": {"selected_option_id": "a"}},
                        format="json").json()
    wrong = client.post(f"/api/v1/attempts/{aid}/answers/",
                        {"exercise_id": mc.id, "submitted": {"selected_option_id": "b"}},
                        format="json").json()
    assert right["correct"] is True
    assert wrong["correct"] is False
    assert "fail" not in wrong["feedback"].lower()  # adab: no "failed" framing


def test_word_order_grading():
    lesson, _, wo, _ = _lesson_with_exercises()
    client, _ = _client()
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    ok = client.post(f"/api/v1/attempts/{aid}/answers/",
                     {"exercise_id": wo.id, "submitted": {"ordered_token_ids": ["t1", "t2"]}},
                     format="json").json()
    bad = client.post(f"/api/v1/attempts/{aid}/answers/",
                      {"exercise_id": wo.id, "submitted": {"ordered_token_ids": ["t2", "t1"]}},
                      format="json").json()
    assert ok["correct"] is True
    assert bad["correct"] is False


def test_listening_recall_is_lenient_self_mark():
    lesson, _, _, lr = _lesson_with_exercises()
    client, _ = _client()
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    r = client.post(f"/api/v1/attempts/{aid}/answers/",
                    {"exercise_id": lr.id, "submitted": {"self_marked_correct": True}},
                    format="json").json()
    assert r["correct"] is True


def test_cannot_submit_to_another_users_attempt():
    lesson, mc, *_ = _lesson_with_exercises()
    owner, _ = _client(sub="owner")
    aid = owner.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    other, _ = _client(sub="intruder")
    resp = other.post(f"/api/v1/attempts/{aid}/answers/",
                      {"exercise_id": mc.id, "submitted": {"selected_option_id": "a"}},
                      format="json")
    assert resp.status_code == 404


def test_completion_is_idempotent_no_double_award():
    lesson, mc, *_ = _lesson_with_exercises()
    client, user = _client()
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    client.post(f"/api/v1/attempts/{aid}/answers/",
                {"exercise_id": mc.id, "submitted": {"selected_option_id": "a"}},
                format="json")
    first = client.post(f"/api/v1/attempts/{aid}/complete/",
                        {"idempotency_key": "k1"}, format="json").json()
    second = client.post(f"/api/v1/attempts/{aid}/complete/",
                         {"idempotency_key": "k1"}, format="json").json()
    assert first == second
    attempt = LessonAttempt.objects.get(pk=aid)
    assert attempt.status == "completed"
    # XP counted exactly once.
    activity = DailyActivity.objects.get(user=user)
    assert activity.xp_earned == 10
    assert activity.lessons_completed == 1
