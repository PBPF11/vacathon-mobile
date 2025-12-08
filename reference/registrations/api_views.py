from django.core.paginator import Paginator
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from core.api_helpers import serialize_registration
from events.models import Event, EventCategory
from .models import EventRegistration


@api_view(["GET", "POST"])
def registrations_api(request):
    """
    GET: list authenticated user's registrations.
    POST: create or update a registration for an event.
    """
    if request.method == "GET":
        queryset = (
            EventRegistration.objects.filter(user=request.user)
            .select_related("event", "category", "user")
            .order_by("-created_at")
        )
        paginator = Paginator(queryset, 20)
        page_number = request.GET.get("page") or 1
        page_obj = paginator.get_page(page_number)
        return Response(
            {
                "results": [
                    serialize_registration(reg) for reg in page_obj.object_list
                ],
                "total": paginator.count,
                "has_next": page_obj.has_next(),
            }
        )

    # POST branch
    payload = request.data
    event_id = payload.get("event")
    if not event_id:
        return Response({"detail": "event is required."}, status=status.HTTP_400_BAD_REQUEST)

    event = get_object_or_404(Event, pk=event_id)
    category = None
    category_id = payload.get("category")
    if category_id:
        category = get_object_or_404(EventCategory, pk=category_id)

    phone = (payload.get("phone_number") or "").strip()
    emergency_name = (payload.get("emergency_contact_name") or "").strip()
    emergency_phone = (payload.get("emergency_contact_phone") or "").strip()
    distance_label = (payload.get("distance_label") or "").strip()

    if not phone or not emergency_name or not emergency_phone:
        return Response(
            {"detail": "phone_number, emergency_contact_name, and emergency_contact_phone are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if category and category not in event.categories.all():
        return Response(
            {"detail": "Category does not belong to this event."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    registration, created = EventRegistration.objects.update_or_create(
        user=request.user,
        event=event,
        defaults={
            "category": category,
            "distance_label": category.display_name if category else distance_label,
            "phone_number": phone,
            "emergency_contact_name": emergency_name,
            "emergency_contact_phone": emergency_phone,
            "medical_notes": payload.get("medical_notes", ""),
            "status": EventRegistration.Status.PENDING,
            "form_payload": {"submitted_via": "mobile"},
        },
    )

    return Response(
        serialize_registration(registration),
        status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
    )


@api_view(["GET"])
def registration_detail_api(request, reference_code: str):
    """Get a single registration by reference code."""
    registration = get_object_or_404(
        EventRegistration.objects.select_related("event", "category", "user"),
        reference_code=reference_code,
        user=request.user,
    )
    return Response(serialize_registration(registration))
