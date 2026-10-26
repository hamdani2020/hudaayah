from django.contrib import admin

from .models import AuthSession, User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ("id", "provider", "display_name", "email", "is_staff", "created_at")
    list_filter = ("provider", "is_staff", "is_active")
    search_fields = ("display_name", "email", "provider_sub")
    readonly_fields = ("provider", "provider_sub", "created_at", "updated_at", "last_login")


@admin.register(AuthSession)
class AuthSessionAdmin(admin.ModelAdmin):
    # Token hashes are shown read-only; raw tokens are never stored or displayed.
    list_display = ("id", "user", "access_expires_at", "refresh_expires_at", "revoked_at")
    list_filter = ("revoked_at",)
    readonly_fields = tuple(f.name for f in AuthSession._meta.fields)

    def has_add_permission(self, request):
        return False
