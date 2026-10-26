from django.contrib import admin

from .models import ReviewItem


@admin.register(ReviewItem)
class ReviewItemAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "item_type", "content_ref", "due_at",
                    "interval_days", "repetitions", "last_result")
    list_filter = ("item_type", "last_result")
    search_fields = ("content_ref", "prompt")
    readonly_fields = ("created_at", "updated_at")
