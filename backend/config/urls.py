"""Root URL configuration. API mounted under /api/v1/."""
from django.conf import settings
from django.contrib import admin
from django.urls import include, path

from apps.common.views import LandingPageView, LegalPageView

api = settings.API_PREFIX

urlpatterns = [
    # Public landing page (served on app.hudaayah.xyz).
    path("", LandingPageView.as_view(), name="landing"),
    path("admin/", admin.site.urls),
    # Public legal pages (served on privacy.hudaayah.xyz; also reachable on any allowed host).
    path("privacy/", LegalPageView.as_view(template_name="legal/privacy.html"), name="legal-privacy"),
    path("terms/", LegalPageView.as_view(template_name="legal/terms.html"), name="legal-terms"),
    path(
        "delete-account/",
        LegalPageView.as_view(template_name="legal/delete_account.html"),
        name="legal-delete-account",
    ),
    path(f"{api}health/", include("apps.common.urls")),
    path(f"{api}", include("apps.accounts.urls")),
    path(f"{api}", include("apps.lessons.urls")),
    path(f"{api}", include("apps.progress.urls")),
    path(f"{api}", include("apps.review.urls")),
    path(f"{api}", include("apps.quran_content.urls")),
]
