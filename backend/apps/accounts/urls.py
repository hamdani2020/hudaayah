from django.urls import path

from .views import GoogleAuthView, LogoutView, MeView, RefreshView

urlpatterns = [
    path("auth/google/", GoogleAuthView.as_view(), name="auth-google"),
    path("auth/refresh/", RefreshView.as_view(), name="auth-refresh"),
    path("auth/logout/", LogoutView.as_view(), name="auth-logout"),
    path("me/", MeView.as_view(), name="me"),
]
