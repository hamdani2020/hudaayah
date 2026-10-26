"""Root URL configuration. API mounted under /api/v1/."""
from django.conf import settings
from django.contrib import admin
from django.urls import include, path

api = settings.API_PREFIX

urlpatterns = [
    path("admin/", admin.site.urls),
    path(f"{api}health/", include("apps.common.urls")),
    path(f"{api}", include("apps.accounts.urls")),
    path(f"{api}", include("apps.lessons.urls")),
    path(f"{api}", include("apps.progress.urls")),
    path(f"{api}", include("apps.quran_content.urls")),
]
