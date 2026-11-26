from datetime import date, datetime, timedelta, timezone as dt_timezone
from io import StringIO

import pytest
from django.core.management import call_command
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.progress.models import AppOpenDay, DailyActivity
from apps.progress.retention import retention

pytestmark = pytest.mark.django_db

SIGNUP = date(2026, 11, 10)
TODAY = date(2026, 11, 20)


def _user(sub, signup=SIGNUP, staff=False):
    user = User.objects.create(provider="google", provider_sub=sub, is_staff=staff)
    created = datetime(signup.year, signup.month, signup.day, 9, tzinfo=dt_timezone.utc)
    User.objects.filter(pk=user.pk).update(created_at=created)
    return user


def _client(user):
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c


def _lesson_day(user, d):
    DailyActivity.objects.create(user=user, date=d, xp_earned=10, lessons_completed=1)


def _open_day(user, d):
    AppOpenDay.objects.create(user=user, date=d)


def test_open_endpoint_requires_auth():
    assert APIClient().post("/api/v1/activity/open/").status_code == 401


def test_open_endpoint_is_idempotent_and_user_scoped():
    a, b = _user("a"), _user("b")
    client = _client(a)
    for _ in range(3):
        assert client.post("/api/v1/activity/open/").status_code == 204
    assert AppOpenDay.objects.filter(user=a, date=timezone.localdate()).count() == 1
    assert not AppOpenDay.objects.filter(user=b).exists()


def test_lesson_metric_counts_returns_per_day():
    u1, u2 = _user("u1"), _user("u2")
    _lesson_day(u1, SIGNUP + timedelta(days=1))
    _lesson_day(u1, SIGNUP + timedelta(days=7))
    _lesson_day(u2, SIGNUP + timedelta(days=2))
    rows = retention("lesson", today=TODAY)
    cohort, total = rows[0], rows[-1]
    assert cohort.signup_date == SIGNUP and cohort.signups == 2
    assert (cohort.rates[1].returned, cohort.rates[1].eligible) == (1, 2)
    assert (cohort.rates[2].returned, cohort.rates[2].eligible) == (1, 2)
    assert (cohort.rates[7].returned, cohort.rates[7].eligible) == (1, 2)
    assert total.signup_date is None and total.signups == 2
    assert cohort.rates[1].percent == 50.0


def test_open_metric_includes_opens_and_lesson_days():
    u = _user("u")
    _open_day(u, SIGNUP + timedelta(days=1))
    _lesson_day(u, SIGNUP + timedelta(days=2))
    lesson_row = retention("lesson", today=TODAY)[0]
    open_row = retention("open", today=TODAY)[0]
    assert lesson_row.rates[1].returned == 0
    assert open_row.rates[1].returned == 1
    assert open_row.rates[2].returned == 1  # a lesson implies the app was opened


def test_unfinished_days_and_staff_are_excluded():
    recent = _user("recent", signup=TODAY - timedelta(days=1))  # Day 1 is today
    _user("staff", staff=True)
    _lesson_day(recent, TODAY)
    rows = retention("lesson", today=TODAY)
    assert [r.signup_date for r in rows[:-1]] == [TODAY - timedelta(days=1)]
    assert rows[0].rates[1].eligible == 0  # not counted until the day has passed
    assert rows[-1].signups == 1  # staff not counted


def test_since_filter():
    _user("old", signup=date(2026, 11, 1))
    _user("new", signup=SIGNUP)
    rows = retention("lesson", since=SIGNUP, today=TODAY)
    assert rows[-1].signups == 1


def test_account_deletion_removes_open_days():
    u = _user("gone")
    _open_day(u, SIGNUP)
    assert _client(u).delete("/api/v1/me/").status_code == 204
    assert not AppOpenDay.objects.exists()


def test_retention_report_command_runs():
    _user("c")
    out = StringIO()
    call_command("retention_report", stdout=out)
    text = out.getvalue()
    assert "completed a lesson" in text and "opened the app" in text and "ALL" in text


def test_admin_page_is_staff_only():
    staff = _user("admin", staff=True)
    anon = APIClient()
    assert anon.get("/admin/retention/").status_code == 302  # redirected to login
    anon.force_login(staff)
    resp = anon.get("/admin/retention/")
    assert resp.status_code == 200
    assert b"Return rates" in resp.content
