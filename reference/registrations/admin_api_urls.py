from django.urls import path

from . import admin_api_views

app_name = "registrations_admin_api"

urlpatterns = [
    path("participants/", admin_api_views.admin_registrations_api, name="participants"),
    path(
        "participants/<uuid:registration_id>/confirm/",
        admin_api_views.admin_registration_confirm_api,
        name="participant-confirm",
    ),
    path(
        "participants/<uuid:registration_id>/delete/",
        admin_api_views.admin_registration_delete_api,
        name="participant-delete",
    ),
]
