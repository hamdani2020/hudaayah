"""Seed a surah lesson from a seed/*.json file.

References QF resources by stable ID only — no Quran text is created here
(quran-content-rules). Idempotent: safe to run repeatedly.

By default the seeded lesson is left as DRAFT so it goes through the content
review workflow (R9). Pass --publish to publish it immediately for dev testing.

The seed file defaults to seed/al_fatihah.json; pass --file to load another,
e.g. `seed_al_fatihah --file al_baqarah.json --publish`.
"""
from __future__ import annotations

import json
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from apps.common.lifecycle import ContentStatus
from apps.exercises.models import Exercise
from apps.lessons.models import ContentSource, Lesson


class Command(BaseCommand):
    help = "Seed a surah lesson from a seed/*.json file (QF references only; no verse text)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--publish",
            action="store_true",
            help="Publish the lesson immediately (dev convenience).",
        )
        parser.add_argument(
            "--file",
            default="al_fatihah.json",
            help="Seed filename under backend/seed/ (default: al_fatihah.json).",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        seed_path = Path(settings.BASE_DIR) / "seed" / options["file"]
        if not seed_path.exists():
            raise CommandError(f"Seed file not found: {seed_path}")
        data = json.loads(seed_path.read_text())

        sources_by_ref: dict[str, ContentSource] = {}
        for s in data["content_sources"]:
            source, _ = ContentSource.objects.update_or_create(
                provider=s["provider"],
                resource_type=s["resource_type"],
                provider_ref=s["provider_ref"],
                defaults={
                    "language": s.get("language", ""),
                    "attribution": s.get("attribution", ""),
                    "caching_policy_ref": s.get("caching_policy_ref", "qf_max_1_week"),
                    "retrieved_at": timezone.now(),
                },
            )
            sources_by_ref[f"{s['resource_type']}:{s['provider_ref']}"] = source

        ls = data["lesson"]
        translation = sources_by_ref.get(f"translation:{ls['translation_provider_ref']}")
        recitation = sources_by_ref.get(f"recitation:{ls['recitation_provider_ref']}")

        lesson, created = Lesson.objects.update_or_create(
            surah=ls["surah"],
            ayah_start=ls["ayah_start"],
            ayah_end=ls["ayah_end"],
            defaults={
                "title": ls["title"],
                "order": ls["order"],
                "objectives": ls["objectives"],
                "translation_source": translation,
                "recitation_source": recitation,
            },
        )

        if options["publish"]:
            lesson.status = ContentStatus.PUBLISHED
            lesson.approved_at = timezone.now()
            lesson.save(update_fields=["status", "approved_at"])

        # Exercises (idempotent per lesson+position).
        ex_count = 0
        for ex in data.get("exercises", []):
            exercise, _ = Exercise.objects.update_or_create(
                lesson=lesson,
                position=ex["position"],
                defaults={
                    "type": ex["type"],
                    "config": ex.get("config", {}),
                    "content_references": ex.get("content_references", {}),
                    "answer_key": ex.get("answer_key", {}),
                },
            )
            if options["publish"]:
                exercise.status = ContentStatus.PUBLISHED
                exercise.approved_at = timezone.now()
                exercise.save(update_fields=["status", "approved_at"])
            ex_count += 1

        verb = "Created" if created else "Updated"
        self.stdout.write(self.style.SUCCESS(
            f"{verb} lesson '{lesson.title}' (id={lesson.id}, status={lesson.status}); "
            f"{len(sources_by_ref)} content source(s); {ex_count} exercise(s)."
        ))
