from datetime import datetime

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from core.api_helpers import serialize_achievement, serialize_profile
from .forms import ProfileAchievementForm
from .models import RunnerAchievement, UserProfile


@api_view(["GET", "PUT"])
def profile_api(request):
    """Retrieve or update the authenticated user's profile."""
    profile, _ = UserProfile.objects.get_or_create(user=request.user)

    if request.method == "GET":
        return Response(serialize_profile(profile))

    payload = request.data
    updatable_fields = [
        "display_name",
        "bio",
        "city",
        "country",
        "avatar_url",
        "favorite_distance",
        "emergency_contact_name",
        "emergency_contact_phone",
        "website",
        "instagram_handle",
        "strava_profile",
    ]
    for field in updatable_fields:
        if field in payload:
            setattr(profile, field, payload.get(field) or "")

    if "birth_date" in payload and payload.get("birth_date"):
        try:
            profile.birth_date = datetime.fromisoformat(payload["birth_date"]).date()
        except (ValueError, TypeError):
            return Response(
                {"detail": "Invalid birth_date format. Use ISO 8601 (YYYY-MM-DD)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

    profile.save()
    return Response(serialize_profile(profile))


@api_view(["GET", "POST"])
def achievements_api(request):
    """List or create achievements for the authenticated user."""
    profile, _ = UserProfile.objects.get_or_create(user=request.user)
    if request.method == "GET":
        return Response({"results": [serialize_achievement(ach) for ach in profile.achievements.all()]})

    form = ProfileAchievementForm(request.data)
    if form.is_valid():
        achievement = form.save(commit=False)
        achievement.profile = profile
        achievement.save()
        return Response(
            serialize_achievement(achievement),
            status=status.HTTP_201_CREATED,
        )
    return Response({"errors": form.errors}, status=status.HTTP_400_BAD_REQUEST)


@api_view(["DELETE"])
def delete_achievement_api(request, achievement_id: int):
    """Delete a specific achievement."""
    profile, _ = UserProfile.objects.get_or_create(user=request.user)
    achievement = get_object_or_404(RunnerAchievement, pk=achievement_id, profile=profile)
    achievement.delete()
    return Response({"success": True})
