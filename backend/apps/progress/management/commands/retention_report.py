"""Print Day-1 / Day-2 / Day-7 return rates by signup day.

    docker compose exec web python manage.py retention_report
    docker compose exec web python manage.py retention_report --metric open --since 2026-11-20
"""
from datetime import date

from django.core.management.base import BaseCommand, CommandError

from apps.progress.retention import DAYS, METRICS, retention


class Command(BaseCommand):
    help = "Day-1/2/7 return rates by signup day (staff accounts excluded)."

    def add_arguments(self, parser):
        parser.add_argument("--metric", choices=(*METRICS, "both"), default="both",
                            help="lesson = completed a lesson; open = opened the app.")
        parser.add_argument("--since", help="Only learners who signed up on/after YYYY-MM-DD.")

    def handle(self, *args, metric, since, **options):
        try:
            since_date = date.fromisoformat(since) if since else None
        except ValueError as exc:
            raise CommandError("--since must be YYYY-MM-DD") from exc

        for m in (METRICS if metric == "both" else (metric,)):
            label = "completed a lesson" if m == "lesson" else "opened the app"
            self.stdout.write(self.style.MIGRATE_HEADING(f"\nReturned = {label}"))
            header = f"{'Signup day':<12}{'Signups':>9}" + "".join(f"{'Day ' + str(n):>16}" for n in DAYS)
            self.stdout.write(header)
            for row in retention(m, since=since_date):
                name = row.signup_date.isoformat() if row.signup_date else "ALL"
                cells = ""
                for n in DAYS:
                    r = row.rates[n]
                    cells += f"{'-' if not r.eligible else f'{r.returned}/{r.eligible} ({r.percent}%)':>16}"
                line = f"{name:<12}{row.signups:>9}{cells}"
                self.stdout.write(self.style.SUCCESS(line) if row.signup_date is None else line)
        self.stdout.write("\n'-' = that day has not passed yet for anyone in the group.")
