from __future__ import annotations

import json
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

from django.core.paginator import Paginator
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils.dateparse import parse_date, parse_datetime
from django.utils.text import slugify
from rest_framework import status
from rest_framework.authentication import SessionAuthentication
from rest_framework.decorators import (
    api_view,
    permission_classes,
    renderer_classes,
    authentication_classes,
    parser_classes,
)
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAdminUser
from rest_framework.renderers import JSONRenderer
from rest_framework.response import Response

from core.api_helpers import serialize_category, serialize_event
from .models import Event, EventCategory
from django.conf import settings
from django.core.files.storage import default_storage


def _parse_date_value(value, field_name: str) -> date | None:
    if value in (None, ""):
        return None
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, str):
        parsed = parse_datetime(value)
        if parsed:
            return parsed.date()
        parsed = parse_date(value)
        if parsed:
            return parsed
    raise ValueError(f"Invalid {field_name} format. Use YYYY-MM-DD.")


def _parse_int(value, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _parse_category_ids(value) -> list[int]:
    if value in (None, ""):
        return []
    if isinstance(value, list):
        return [_parse_int(item) for item in value if _parse_int(item) > 0]
    if isinstance(value, str):
        raw = value.strip()
        if not raw:
            return []
        if raw.startswith("["):
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, list):
                    return [_parse_int(item) for item in parsed if _parse_int(item) > 0]
            except json.JSONDecodeError:
                pass
        return [_parse_int(item) for item in raw.split(",") if _parse_int(item) > 0]
    return []


def _validate_status(value: str | None) -> str | None:
    if not value:
        return None
    valid = {choice[0] for choice in Event.Status.choices}
    return value if value in valid else None


class CsrfExemptSessionAuthentication(SessionAuthentication):
    def enforce_csrf(self, request):
        return


def _save_banner_image(file_obj) -> str:
    upload_path = default_storage.save(f"event_banners/{file_obj.name}", file_obj)
    base_url = settings.MEDIA_URL or "/media/"
    if not base_url.endswith("/"):
        base_url = f"{base_url}/"
    if not base_url.startswith("/"):
        base_url = f"/{base_url}"
    return f"{base_url}{upload_path}"


@api_view(["GET", "POST"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def admin_events_api(request):
    if request.method == "GET":
        queryset = Event.objects.prefetch_related("categories").order_by("start_date")
        status_filter = request.GET.get("status")
        city = request.GET.get("city")
        search = request.GET.get("q") or request.GET.get("search")

        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if city:
            queryset = queryset.filter(city__icontains=city)
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) | Q(description__icontains=search)
            )

        paginator = Paginator(queryset, 20)
        page_number = request.GET.get("page") or 1
        page_obj = paginator.get_page(page_number)

        return Response(
            {
                "results": [
                    serialize_event(event, request=request)
                    for event in page_obj.object_list
                ],
                "pagination": {
                    "page": page_obj.number,
                    "pages": paginator.num_pages,
                    "has_next": page_obj.has_next(),
                    "has_previous": page_obj.has_previous(),
                    "total": paginator.count,
                },
            }
        )

    payload = request.data
    errors: dict[str, str] = {}

    title = (payload.get("title") or "").strip()
    description = (payload.get("description") or "").strip()
    city = (payload.get("city") or "").strip()
    status_value = _validate_status(payload.get("status"))
    popularity_score = max(_parse_int(payload.get("popularity_score"), default=0), 0)
    banner_image_url = (payload.get("banner_image") or "").strip()

    try:
        start_date = _parse_date_value(payload.get("start_date"), "start_date")
    except ValueError as exc:
        errors["start_date"] = str(exc)
        start_date = None
    try:
        end_date = _parse_date_value(payload.get("end_date"), "end_date")
    except ValueError as exc:
        errors["end_date"] = str(exc)
        end_date = None
    try:
        registration_deadline = _parse_date_value(
            payload.get("registration_deadline"), "registration_deadline"
        )
    except ValueError as exc:
        errors["registration_deadline"] = str(exc)
        registration_deadline = None

    if not title:
        errors["title"] = "This field is required."
    if not description:
        errors["description"] = "This field is required."
    if not city:
        errors["city"] = "This field is required."
    if not start_date:
        errors["start_date"] = errors.get("start_date") or "This field is required."
    if not registration_deadline:
        errors["registration_deadline"] = errors.get("registration_deadline") or "This field is required."
    if status_value is None:
        errors["status"] = "Select a valid status."

    if errors:
        return Response({"errors": errors}, status=status.HTTP_400_BAD_REQUEST)

    event = Event.objects.create(
        title=title,
        description=description,
        city=city,
        start_date=start_date,
        end_date=end_date,
        registration_deadline=registration_deadline,
        status=status_value or Event.Status.UPCOMING,
        popularity_score=popularity_score,
    )

    upload = request.FILES.get("banner_image")
    if upload:
        event.banner_image = _save_banner_image(upload)
    elif banner_image_url:
        event.banner_image = banner_image_url

    if event.banner_image:
        event.save(update_fields=["banner_image"])

    category_ids = _parse_category_ids(payload.get("categories"))
    if category_ids:
        categories = list(EventCategory.objects.filter(id__in=category_ids))
        event.categories.set(categories)

    return Response(serialize_event(event, request=request), status=status.HTTP_201_CREATED)


@api_view(["GET", "POST", "PUT", "PATCH"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def admin_event_detail_api(request, event_id: int):
    event = get_object_or_404(Event.objects.prefetch_related("categories"), pk=event_id)

    if request.method == "GET":
        return Response(serialize_event(event, request=request))

    payload = request.data
    errors: dict[str, str] = {}

    if "title" in payload:
        title = (payload.get("title") or "").strip()
        if not title:
            errors["title"] = "This field is required."
        else:
            event.title = title
    if "description" in payload:
        description = (payload.get("description") or "").strip()
        if not description:
            errors["description"] = "This field is required."
        else:
            event.description = description
    if "city" in payload:
        city = (payload.get("city") or "").strip()
        if not city:
            errors["city"] = "This field is required."
        else:
            event.city = city
    if "status" in payload:
        status_value = _validate_status(payload.get("status"))
        if status_value is None:
            errors["status"] = "Select a valid status."
        else:
            event.status = status_value
    if "popularity_score" in payload:
        event.popularity_score = max(_parse_int(payload.get("popularity_score"), default=0), 0)
    if "banner_image" in payload:
        banner_value = (payload.get("banner_image") or "").strip()
        if banner_value:
            event.banner_image = banner_value

    if "start_date" in payload:
        try:
            event.start_date = _parse_date_value(payload.get("start_date"), "start_date")
        except ValueError as exc:
            errors["start_date"] = str(exc)
    if "end_date" in payload:
        try:
            event.end_date = _parse_date_value(payload.get("end_date"), "end_date")
        except ValueError as exc:
            errors["end_date"] = str(exc)
    if "registration_deadline" in payload:
        try:
            event.registration_deadline = _parse_date_value(
                payload.get("registration_deadline"), "registration_deadline"
            )
        except ValueError as exc:
            errors["registration_deadline"] = str(exc)

    if errors:
        return Response({"errors": errors}, status=status.HTTP_400_BAD_REQUEST)

    upload = request.FILES.get("banner_image")
    if upload:
        event.banner_image = _save_banner_image(upload)

    event.save()

    if "categories" in payload:
        category_ids = _parse_category_ids(payload.get("categories"))
        categories = list(EventCategory.objects.filter(id__in=category_ids))
        event.categories.set(categories)

    return Response(serialize_event(event, request=request))


@api_view(["POST", "DELETE"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
def admin_event_delete_api(request, event_id: int):
    event = get_object_or_404(Event, pk=event_id)
    event.delete()
    return Response({"success": True})


@api_view(["GET", "POST"])
@permission_classes([IsAdminUser])
@authentication_classes([CsrfExemptSessionAuthentication])
@renderer_classes([JSONRenderer])
@parser_classes([JSONParser, FormParser, MultiPartParser])
def admin_event_categories_api(request):
    if request.method == "GET":
        categories = EventCategory.objects.order_by("distance_km")
        return Response(
            {"results": [serialize_category(category) for category in categories]}
        )

    payload = request.data
    display_name = (payload.get("display_name") or payload.get("name") or "").strip()
    distance_raw = payload.get("distance_km")
    if not display_name or distance_raw in (None, ""):
        return Response(
            {"errors": {"display_name": "display_name and distance_km are required."}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    name = (payload.get("name") or "").strip() or slugify(display_name)
    if not name:
        return Response(
            {"errors": {"name": "Invalid category name."}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        distance_km = Decimal(str(distance_raw))
    except (InvalidOperation, TypeError, ValueError):
        return Response(
            {"errors": {"distance_km": "distance_km must be numeric."}},
            status=status.HTTP_400_BAD_REQUEST,
        )

    existing = EventCategory.objects.filter(name=name).first()
    if not existing:
        existing = EventCategory.objects.filter(display_name=display_name).first()
    if existing:
        return Response(serialize_category(existing))

    category = EventCategory.objects.create(
        name=name,
        display_name=display_name,
        distance_km=distance_km,
    )
    return Response(serialize_category(category), status=status.HTTP_201_CREATED)
