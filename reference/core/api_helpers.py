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


def serialize_event(event: Event) -> dict:
    """Serialize an Event into the mobile-friendly payload."""
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
            event.registration_open_date.isoformat() if event.registration_open_date else None
        ),
        "registration_deadline": event.registration_deadline.isoformat(),
        "status": event.status,
        "popularity_score": event.popularity_score,
        "participant_limit": event.participant_limit,
        "registered_count": event.registered_count,
        "featured": event.featured,
        "banner_image": event.banner_image,
        "categories": [serialize_category(cat) for cat in event.categories.all()],
        "created_at": event.created_at.isoformat() if event.created_at else timezone.now().isoformat(),
        "updated_at": event.updated_at.isoformat() if event.updated_at else timezone.now().isoformat(),
    }


def serialize_event_detail(event: Event) -> dict:
    """Serialize the extended event detail (route, schedule, documents)."""
    return {
        "schedules": [
            {
                "id": schedule.id,
                "event": schedule.event_id,
                "title": schedule.title,
                "start_time": schedule.start_time.isoformat(),
                "end_time": schedule.end_time.isoformat() if schedule.end_time else None,
                "description": schedule.description,
            }
            for schedule in event.schedules.all()
        ],
        "aid_stations": [
            {
                "id": station.id,
                "event": station.event_id,
                "name": station.name,
                "kilometer_marker": float(station.kilometer_marker),
                "supplies": station.supplies,
                "is_medical": station.is_medical,
            }
            for station in event.aid_stations.all()
        ],
        "route_segments": [
            {
                "id": segment.id,
                "event": segment.event_id,
                "order": segment.order,
                "title": segment.title,
                "description": segment.description,
                "distance_km": float(segment.distance_km),
                "elevation_gain": segment.elevation_gain,
            }
            for segment in event.route_segments.all()
        ],
        "documents": [
            {
                "id": document.id,
                "event": document.event_id,
                "title": document.title,
                "document_url": document.document_url,
                "document_type": document.document_type,
                "uploaded_by": document.uploaded_by,
                "uploaded_at": document.uploaded_at.isoformat(),
            }
            for document in event.documents.all()
        ],
    }


def serialize_history(history: UserRaceHistory) -> dict:
    """Serialize a user's race history item."""
    return {
        "id": history.id,
        "event": serialize_event(history.event),
        "category": history.category,
        "registration_date": history.registration_date.isoformat(),
        "status": history.status,
        "bib_number": history.bib_number,
        "finish_time": history.finish_time.total_seconds() if history.finish_time else None,
        "medal_awarded": history.medal_awarded,
        "certificate_url": history.certificate_url,
        "notes": history.notes,
        "updated_at": history.updated_at.isoformat(),
    }


def serialize_achievement(achievement: RunnerAchievement) -> dict:
    """Serialize a runner achievement."""
    return {
        "id": achievement.id,
        "title": achievement.title,
        "description": achievement.description,
        "achieved_on": achievement.achieved_on.isoformat() if achievement.achieved_on else None,
        "link": achievement.link,
    }


def serialize_profile(profile: UserProfile) -> dict:
    """Serialize the authenticated user's profile."""
    return {
        "id": profile.id,
        "username": profile.user.username,
        "display_name": profile.full_display_name,
        "bio": profile.bio,
        "city": profile.city,
        "country": profile.country,
        "avatar_url": profile.avatar_url,
        "favorite_distance": profile.favorite_distance,
        "emergency_contact_name": profile.emergency_contact_name,
        "emergency_contact_phone": profile.emergency_contact_phone,
        "website": profile.website,
        "instagram_handle": profile.instagram_handle,
        "strava_profile": profile.strava_profile,
        "birth_date": profile.birth_date.isoformat() if profile.birth_date else None,
        "created_at": profile.created_at.isoformat(),
        "updated_at": profile.updated_at.isoformat(),
        "history": [serialize_history(item) for item in profile.history.select_related("event")],
        "achievements": [serialize_achievement(ach) for ach in profile.achievements.all()],
    }


def serialize_registration(registration: EventRegistration) -> dict:
    """Serialize an event registration with nested event detail."""
    category_display = registration.category.display_name if registration.category else registration.distance_label
    return {
        "id": str(registration.id),
        "reference_code": registration.reference_code,
        "user": registration.user_id,
        "user_username": registration.user.username,
        "event": serialize_event(registration.event),
        "category": registration.category_id,
        "category_display_name": category_display,
        "distance_label": registration.distance_label or category_display or "Open Category",
        "phone_number": registration.phone_number,
        "emergency_contact_name": registration.emergency_contact_name,
        "emergency_contact_phone": registration.emergency_contact_phone,
        "medical_notes": registration.medical_notes,
        "status": registration.status,
        "payment_status": registration.payment_status,
        "form_payload": registration.form_payload or {},
        "decision_note": registration.decision_note,
        "created_at": registration.created_at.isoformat(),
        "updated_at": registration.updated_at.isoformat(),
        "confirmed_at": registration.confirmed_at.isoformat() if registration.confirmed_at else None,
        "cancelled_at": registration.cancelled_at.isoformat() if registration.cancelled_at else None,
    }


def serialize_thread(thread: ForumThread) -> dict:
    """Serialize a forum thread with activity metadata."""
    return {
        "id": thread.id,
        "event": thread.event_id,
        "author": thread.author_id,
        "author_username": thread.author.username,
        "title": thread.title,
        "slug": thread.slug,
        "body": thread.body,
        "created_at": thread.created_at.isoformat(),
        "updated_at": thread.updated_at.isoformat(),
        "last_activity_at": thread.last_activity_at.isoformat(),
        "is_pinned": thread.is_pinned,
        "is_locked": thread.is_locked,
        "view_count": thread.view_count,
    }


def serialize_post(post: ForumPost, *, user=None) -> dict:
    """Serialize a forum post, including like counts and user like state."""
    is_liked = False
    if user and user.is_authenticated:
        is_liked = post.likes.filter(pk=user.pk).exists()
    return {
        "id": post.id,
        "thread": post.thread_id,
        "author": post.author_id,
        "author_username": post.author.username,
        "parent": post.parent_id,
        "content": post.content,
        "created_at": post.created_at.isoformat(),
        "updated_at": post.updated_at.isoformat(),
        "likes_count": post.like_count,
        "is_liked_by_user": is_liked,
    }


def serialize_notification(note: NotificationModel) -> dict:
    """Serialize a notification payload for the app."""
    return {
        "id": note.id,
        "recipient": note.recipient_id,
        "title": note.title,
        "message": note.message,
        "category": note.category,
        "link_url": note.link_url,
        "is_read": note.is_read,
        "created_at": note.created_at.isoformat(),
        "read_at": note.read_at.isoformat() if note.read_at else None,
    }
