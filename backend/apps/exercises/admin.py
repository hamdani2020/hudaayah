from django.contrib import admin

from apps.lessons.admin import mark_reviewed_and_publish

from .models import Exercise


@admin.register(Exercise)
class ExerciseAdmin(admin.ModelAdmin):
    list_display = ("id", "lesson", "type", "position", "status",
                    "approved_by", "approved_at")
    list_filter = ("status", "type", "lesson")
    search_fields = ("lesson__title",)
    actions = [mark_reviewed_and_publish]
    # answer_key is visible to staff reviewers in admin (server-side only); it is
    # never exposed by the API. Audit fields are set via the publish action.
    readonly_fields = ("approved_by", "approved_at", "created_at", "updated_at")
