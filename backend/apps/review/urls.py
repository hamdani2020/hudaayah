from django.urls import path

from .views import DueReviewsView, SubmitReviewView

urlpatterns = [
    path("reviews/due/", DueReviewsView.as_view(), name="reviews-due"),
    path("reviews/<int:item_id>/review/", SubmitReviewView.as_view(),
         name="review-submit"),
]
