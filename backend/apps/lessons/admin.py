from django.contrib import admin

from .models import ContentSource, Lesson


@admin.action(description="Mark reviewed & publish")
def mark_reviewed_and_publish(modeladmin, request, queryset):
    """Publish selected items and stamp the audit trail (R9)."""
    count = 0
    for obj in queryset:
        obj.mark_published(by=request.user)
        count += 1
    modeladmin.message_user(request, f"Published {count} item(s).")


@admin.register(ContentSource)
class ContentSourceAdmin(admin.ModelAdmin):
    list_display = ("provider", "resource_type", "provider_ref", "language",
                    "attribution", "caching_policy_ref")
    list_filter = ("provider", "resource_type", "language")
    search_fields = ("provider_ref", "attribution")


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ("title", "order", "surah", "ayah_start", "ayah_end",
                    "status", "approved_by", "approved_at")
    list_filter = ("status", "surah")
    search_fields = ("title",)
    actions = [mark_reviewed_and_publish]
    # Audit fields are set via the publish action, never hand-edited.
    readonly_fields = ("approved_by", "approved_at", "created_at", "updated_at")
    fields = (
        "title", "order", "objectives",
        "surah", "ayah_start", "ayah_end",
        "translation_source", "recitation_source",
        "status", "approved_by", "approved_at",
        "created_at", "updated_at",
    )
