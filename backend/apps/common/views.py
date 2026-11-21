from django.conf import settings
from django.views.generic import TemplateView
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthView(APIView):
    """Liveness probe. No auth, no DB dependency."""

    authentication_classes: list = []
    permission_classes: list = []

    def get(self, request):
        return Response({"status": "ok"})


class LandingPageView(TemplateView):
    """Public marketing page for app.hudaayah.xyz. No auth, no DB, no QF calls."""

    template_name = "landing/index.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        legal = settings.LEGAL_BASE_URL.rstrip("/")
        context.update(
            play_store_url=settings.PLAY_STORE_URL,
            contact_email=settings.CONTACT_EMAIL,
            privacy_url=f"{legal}/privacy/",
            terms_url=f"{legal}/terms/",
            delete_account_url=f"{legal}/delete-account/",
            tester_form_action=(
                f"https://docs.google.com/forms/d/e/{settings.TESTER_FORM_ID}/formResponse"
                if settings.TESTER_FORM_ID
                else ""
            ),
            tester_form_name_field=settings.TESTER_FORM_NAME_FIELD,
            tester_form_email_field=settings.TESTER_FORM_EMAIL_FIELD,
        )
        return context


class LegalPageView(TemplateView):
    """Public, static legal pages (privacy, terms, account deletion). No auth, no DB."""

    last_updated = "November 21, 2026"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["contact_email"] = settings.CONTACT_EMAIL
        context["last_updated"] = self.last_updated
        return context
