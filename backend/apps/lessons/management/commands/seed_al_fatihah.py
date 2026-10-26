"""Seed the Al-Fatihah lesson from seed/al_fatihah.json.

References QF resources by stable ID only — no Quran text is created here
(quran-content-rules). Idempotent: safe to run repeatedly.

By default the seeded lesson is left as DRAFT so it goes through the content
review workflow (R9). Pass --publish to publish it immediately for dev testing.
"""
from __future__ import annotations

import json
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.common.lifecycle import ContentStatus
from apps.lessons.models import ContentSource, Lesson


class Command(BaseCommand):
    help = "Seed the Al-Fatihah lesson (QF references only; no verse text)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--publish",
            action="store_true",
            help="Publish the lesson immediately (dev convenience).",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        seed_path = Path(settings.BASE_DIR) / "seed" / "al_fatihah.json"
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

        verb = "Created" if created else "Updated"
        self.stdout.write(self.style.SUCCESS(
            f"{verb} lesson '{lesson.title}' (id={lesson.id}, status={lesson.status}); "
            f"{len(sources_by_ref)} content source(s)."
        ))
