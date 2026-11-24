from django.urls import path

from .views import ChaptersView, RecitersView

urlpatterns = [
    path("chapters/", ChaptersView.as_view(), name="qf-chapters"),
    path("reciters/", RecitersView.as_view(), name="reciters"),
]
