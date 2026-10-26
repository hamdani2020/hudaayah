from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.authentication import BearerTokenAuthentication
from apps.common.errors import AppError

from .models import ReviewItem
from .scheduler import apply_result, due_items
from .serializers import ReviewItemSerializer, ReviewResultRequestSerializer


class ReviewItemNotFound(AppError):
    code = "review_item_not_found"
    message = "Review item not found."
    http_status = 404


class DueReviewsView(APIView):
    """GET /reviews/due/ — the user's own due vocab review items."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        items = due_items(request.user)
        return Response({"items": ReviewItemSerializer(items, many=True).data})


class SubmitReviewView(APIView):
    """POST /reviews/{id}/review/ — record a result and reschedule (SM-2)."""

    authentication_classes = [BearerTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request, item_id: int):
        # Object-level ownership: only the item's owner may review it.
        try:
            item = ReviewItem.objects.get(pk=item_id, user=request.user)
        except ReviewItem.DoesNotExist:
            raise ReviewItemNotFound()
        req = ReviewResultRequestSerializer(data=request.data)
        req.is_valid(raise_exception=True)
        item = apply_result(item, correct=req.validated_data["correct"])
        return Response(ReviewItemSerializer(item).data)
