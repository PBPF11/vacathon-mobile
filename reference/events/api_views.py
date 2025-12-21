from django.core.paginator import Paginator
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from core.api_helpers import serialize_event, serialize_event_detail
from .forms import EventFilterForm
from .models import Event


@api_view(["GET"])
@permission_classes([AllowAny])
def events_list_api(request):
    """
    Mobile-friendly events listing with filtering and pagination.
    Mirrors the data contract expected by the Flutter models.
    """
    queryset = Event.objects.prefetch_related("categories").order_by("start_date")
    form = EventFilterForm(request.GET or None)
    queryset = form.filter_queryset(queryset)

    # Optional distance filter (KM) for mobile clients
    distance = request.GET.get("distance")
    if distance:
        try:
            distance_value = float(distance)
            queryset = queryset.filter(categories__distance_km=distance_value)
        except ValueError:
            pass

    paginator = Paginator(queryset, 9)
    page_number = request.GET.get("page") or 1
    page_obj = paginator.get_page(page_number)

    return Response(
        {
            "results": [serialize_event(event) for event in page_obj.object_list],
            "pagination": {
                "page": page_obj.number,
                "pages": paginator.num_pages,
                "has_next": page_obj.has_next(),
                "has_previous": page_obj.has_previous(),
                "total": paginator.count,
            },
        }
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def event_summary_api(request, event_id: int):
    """Return the base event payload."""
    event = get_object_or_404(Event.objects.prefetch_related("categories"), pk=event_id)
    return Response(serialize_event(event))


@api_view(["GET"])
@permission_classes([AllowAny])
def event_detail_api(request, event_id: int):
    """
    Extended event detail (schedule, route, docs) merged with the base event.
    """
    event = get_object_or_404(
        Event.objects.prefetch_related(
            "categories",
            "route_segments",
            "aid_stations",
            "schedules",
            "documents",
        ),
        pk=event_id,
    )
    payload = serialize_event(event)
    payload.update(serialize_event_detail(event))
    return Response(payload)
