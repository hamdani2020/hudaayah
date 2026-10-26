from django.urls import path

from .views import ChaptersView

urlpatterns = [
    path("chapters/", ChaptersView.as_view(), name="qf-chapters"),
]
