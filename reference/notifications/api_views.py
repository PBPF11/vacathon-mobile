from django.core.paginator import Paginator
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from core.api_helpers import serialize_notification
from .models import Notification


@api_view(["GET"])
def notifications_api(request):
    """Paginated notification inbox for the authenticated user."""
    queryset = Notification.objects.filter(recipient=request.user).order_by("-created_at")
    unread_only = request.GET.get("unread")
    if unread_only in {"true", "1", "yes"}:
        queryset = queryset.filter(is_read=False)

    paginator = Paginator(queryset, 20)
    page_number = request.GET.get("page") or 1
    page_obj = paginator.get_page(page_number)

    unread_count = Notification.objects.filter(recipient=request.user, is_read=False).count()

    return Response(
        {
            "results": [serialize_notification(note) for note in page_obj.object_list],
            "total": paginator.count,
            "has_next": page_obj.has_next(),
            "unread_count": unread_count,
        }
    )


@api_view(["POST"])
def mark_notification_read_api(request, pk: int):
    """Mark a single notification as read and return the updated object."""
    note = get_object_or_404(Notification, pk=pk, recipient=request.user)
    note.mark_read()
    return Response(serialize_notification(note))


@api_view(["POST"])
def mark_all_read_api(request):
    """Bulk mark all notifications as read."""
    count = Notification.objects.filter(recipient=request.user, is_read=False).update(
        is_read=True,
        read_at=timezone.now(),
    )
    return Response({"success": True, "updated": count})
