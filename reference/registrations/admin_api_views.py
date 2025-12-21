from django.core.paginator import Paginator
from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.authentication import SessionAuthentication
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
    renderer_classes,
)
from rest_framework.permissions import IsAdminUser
from rest_framework.renderers import JSONRenderer
from rest_framework.response import Response

from core.api_helpers import serialize_registration
from notifications.models import Notification
from notifications.utils import send_notification
from profiles.models import UserProfile, UserRaceHistory
from .models import EventRegistration


class CsrfExemptSessionAuthentication(SessionAuthentication):
    def enforce_csrf(self, request):
        return


def _remove_history(registration: EventRegistration) -> None:
    profile, _ = UserProfile.objects.get_or_create(user=registration.user)
    distance_label = (
        registration.category.display_name
        if registration.category
        else registration.distance_label
    )
    if not distance_label:
        distance_label = "Open Category"
    UserRaceHistory.objects.filter(
        profile=profile,
        event=registration.event,
        category=distance_label,
    ).delete()


@api_view(["GET"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
def admin_registrations_api(request):
    queryset = (
        EventRegistration.objects.select_related("event", "category", "user")
        .order_by("-created_at")
    )
    status_filter = request.GET.get("status")
    event_id = request.GET.get("event")
    search = request.GET.get("q") or request.GET.get("search")

    if status_filter:
        queryset = queryset.filter(status=status_filter)
    if event_id:
        queryset = queryset.filter(event_id=event_id)
    if search:
        queryset = queryset.filter(
            Q(user__username__icontains=search)
            | Q(event__title__icontains=search)
        )

    paginator = Paginator(queryset, 20)
    page_number = request.GET.get("page") or 1
    page_obj = paginator.get_page(page_number)

    return Response(
        {
            "results": [
                serialize_registration(reg, request=request)
                for reg in page_obj.object_list
            ],
            "total": paginator.count,
            "has_next": page_obj.has_next(),
        }
    )


@api_view(["POST"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
def admin_registration_confirm_api(request, registration_id):
    registration = get_object_or_404(EventRegistration, pk=registration_id)

    if registration.status != EventRegistration.Status.CONFIRMED:
        registration.status = EventRegistration.Status.CONFIRMED
        registration.save()

    return Response(serialize_registration(registration, request=request))


@api_view(["POST", "DELETE"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
def admin_registration_delete_api(request, registration_id):
    registration = get_object_or_404(EventRegistration, pk=registration_id)

    detail_kwargs = {"reference": registration.reference_code}
    send_notification(
        recipient=registration.user,
        title=f"Registration cancelled - {registration.event.title}",
        message=(
            "Your registration has been cancelled by an administrator. "
            "Contact support for more details."
        ),
        category=Notification.Category.REGISTRATION,
        url_name="registrations:detail",
        url_kwargs=detail_kwargs,
    )
    _remove_history(registration)
    registration.delete()

    return Response({"success": True}, status=status.HTTP_200_OK)
