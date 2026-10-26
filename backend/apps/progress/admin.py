from django.contrib import admin

from .models import DailyActivity, ExerciseAnswer, LessonAttempt, UserProgress


@admin.register(LessonAttempt)
class LessonAttemptAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "lesson", "status", "started_at", "completed_at")
    list_filter = ("status",)
    readonly_fields = tuple(f.name for f in LessonAttempt._meta.fields)

    def has_add_permission(self, request):
        return False


@admin.register(UserProgress)
class UserProgressAdmin(admin.ModelAdmin):
    list_display = ("user", "lesson", "state", "completed_at", "last_activity")
    list_filter = ("state",)
    readonly_fields = tuple(f.name for f in UserProgress._meta.fields)

    def has_add_permission(self, request):
        return False


@admin.register(DailyActivity)
class DailyActivityAdmin(admin.ModelAdmin):
    list_display = ("user", "date", "xp_earned", "lessons_completed")
    list_filter = ("date",)
    readonly_fields = tuple(f.name for f in DailyActivity._meta.fields)

    def has_add_permission(self, request):
        return False


@admin.register(ExerciseAnswer)
class ExerciseAnswerAdmin(admin.ModelAdmin):
    list_display = ("id", "attempt", "exercise", "correct", "created_at")
    list_filter = ("correct",)
    readonly_fields = tuple(f.name for f in ExerciseAnswer._meta.fields)

    def has_add_permission(self, request):
        return False
