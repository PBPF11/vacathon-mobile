from __future__ import annotations

from typing import Any

from events.models import Event, EventCategory
from registrations.models import EventRegistration


def _absolute_url(request, value: str | None) -> str | None:
    if not value:
        return value
    if value.startswith("http://") or value.startswith("https://"):
        return value
    if request is None:
        return value
    return request.build_absolute_uri(value)


def serialize_category(category: EventCategory) -> dict[str, Any]:
from typing import Optional

from django.utils import timezone

from events.models import Event, EventCategory
from event_detail.models import EventSchedule, AidStation, RouteSegment, EventDocument
from forum.models import ForumPost, ForumThread
from notifications.models import Notification as NotificationModel
from profiles.models import RunnerAchievement, UserProfile, UserRaceHistory
from registrations.models import EventRegistration


def serialize_category(category: EventCategory) -> dict:
    """Serialize an EventCategory with fields expected by the Flutter models."""
    return {
        "id": category.id,
        "name": category.name,
        "display_name": category.display_name,
        "distance_km": float(category.distance_km),
    }


def serialize_event(event: Event, request=None) -> dict[str, Any]:
    banner_image = _absolute_url(request, event.banner_image)

    return {
        "id": event.id,
        "title": event.title,
        "slug": event.slug,
        "description": event.description,
        "city": event.city,
        "country": event.country,
        "venue": event.venue,
        "start_date": event.start_date.isoformat(),
        "end_date": event.end_date.isoformat() if event.end_date else None,
        "registration_open_date": (
            event.registration_open_date.isoformat()
            if event.registration_open_date
            else None
        ),
        "registration_deadline": event.registration_deadline.isoformat(),
        "status": event.status,
        "status_display": event.get_status_display(),
        "popularity_score": event.popularity_score,
        "participant_limit": event.participant_limit,
        "registered_count": event.registered_count,
        "featured": event.featured,
        "banner_image": banner_image,
        "categories": [serialize_category(cat) for cat in event.categories.all()],
        "created_at": event.created_at.isoformat(),
        "updated_at": event.updated_at.isoformat(),
    }


def serialize_registration(
    registration: EventRegistration, request=None
) -> dict[str, Any]:
    return {
        "id": str(registration.id),
        "reference_code": registration.reference_code,
        "user_id": registration.user_id,
        "user_username": registration.user.username,
        "event": serialize_event(registration.event, request=request),
        "category": registration.category_id,
        "category_display_name": (
            registration.category.display_name if registration.category else None
        ),
        "distance_label": registration.distance_label,
        "phone_number": registration.phone_number,
        "emergency_contact_name": registration.emergency_contact_name,
        "emergency_contact_phone": registration.emergency_contact_phone,
        "medical_notes": registration.medical_notes,
        "status": registration.status,
        "payment_status": registration.payment_status,
        "form_payload": registration.form_payload,
        "decision_note": registration.decision_note,
        "bib_number": getattr(registration, "bib_number", None),
        "created_at": registration.created_at.isoformat(),
        "updated_at": registration.updated_at.isoformat(),
        "confirmed_at": (
            registration.confirmed_at.isoformat()
            if registration.confirmed_at
            else None
        ),
        "cancelled_at": (
            registration.cancelled_at.isoformat()
            if registration.cancelled_at
            else None
        ),
    }
