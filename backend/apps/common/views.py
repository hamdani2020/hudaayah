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


class LegalPageView(TemplateView):
    """Public, static legal pages (privacy, terms, account deletion). No auth, no DB."""

    last_updated = "November 20, 2026"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["contact_email"] = settings.CONTACT_EMAIL
        context["last_updated"] = self.last_updated
        return context
