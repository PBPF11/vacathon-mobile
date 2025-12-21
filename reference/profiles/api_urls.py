from django.urls import path

from . import api_views

app_name = "profiles_api"

urlpatterns = [
    path("", api_views.profile_api, name="profile"),
    path("achievements/", api_views.achievements_api, name="achievements"),
    path("achievements/<int:achievement_id>/", api_views.delete_achievement_api, name="achievement-delete"),
]
