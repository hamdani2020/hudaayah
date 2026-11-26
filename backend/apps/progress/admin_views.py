"""Staff-only return-rate page at /admin/retention/."""
from datetime import date

from django.contrib import admin
from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render

from .retention import DAYS, METRICS, retention


@staff_member_required
def retention_view(request):
    since = None
    raw = request.GET.get("since", "").strip()
    if raw:
        try:
            since = date.fromisoformat(raw)
        except ValueError:
            since = None

    tables = []
    for metric in METRICS:
        rows = []
        for row in retention(metric, since=since):
            rows.append({
                "label": row.signup_date.isoformat() if row.signup_date else "All",
                "is_total": row.signup_date is None,
                "signups": row.signups,
                "cells": [row.rates[n] for n in DAYS],
            })
        tables.append({
            "title": "Completed a lesson" if metric == "lesson" else "Opened the app",
            "note": ("Recorded since the start of the pilot."
                     if metric == "lesson"
                     else "App opens are recorded from app version 1.1.1; earlier days undercount."),
            "rows": rows,
        })

    context = {
        **admin.site.each_context(request),
        "title": "Return rates (Day 1 / 2 / 7)",
        "days": DAYS,
        "tables": tables,
        "since": raw if since else "",
    }
    return render(request, "admin/progress/retention.html", context)
